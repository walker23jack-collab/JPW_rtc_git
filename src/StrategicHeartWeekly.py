from rtctools.optimization.collocated_integrated_optimization_problem import CollocatedIntegratedOptimizationProblem
from rtctools.optimization.modelica_mixin import ModelicaMixin
from rtctools.optimization.goal_programming_mixin import GoalProgrammingMixin, Goal, StateGoal
from rtctools_interface.optimization.goal_generator_mixin import GoalGeneratorMixin
from rtctools_interface.optimization.plot_goals_mixin import PlotMixin
from rtctools.optimization.csv_mixin import CSVMixin
from rtctools_diagnostics.export_results import ExportResultsEachPriorityMixin
from rtctools.util import run_optimization_problem 
import logging
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import numpy as np

logger = logging.getLogger("rtctools")


class StrategicHeartWeekly(
    ExportResultsEachPriorityMixin,
    GoalGeneratorMixin,
    PlotMixin,
    GoalProgrammingMixin,
    CSVMixin,
    ModelicaMixin,
    CollocatedIntegratedOptimizationProblem,
):
    csv_equidistant = False
    plot_max_rows = 3

    def compiler_options(self):
        options = super().compiler_options()
        options["cache"] = False
        return options

    """
    Optimization problem for the Strategic Heart process basin, treatment plant,
    ASR well, and distribution network.
    """

    def post(self):
        results = self.extract_results()

        # ==========================================================
        # Reliability metrics
        # ==========================================================

        Qdem = self.get_timeseries("Qdem").values
        Qsup = results["QDistribution"]

        # Prevent tiny numerical negatives
        shortage = np.maximum(Qdem - Qsup, 0.0)

        # ---------- Volumetric reliability ----------

        cum_demand = np.cumsum(Qdem)
        cum_supplied = np.cumsum(Qsup)

        volume_reliability = (
            cum_supplied /
            np.maximum(cum_demand, 1e-12)
        )

        volume_unmet_pct = 100 * (1 - volume_reliability)

         # -------------------------
        # Temporal reliability
        # -------------------------
        
        # failure if supply is less than 99% of demand
        
        failure = shortage / np.maximum(Qdem,1e-12) > 0.01

        time_unmet_pct = (
            100 *
            np.cumsum(failure) /
            np.arange(1, len(failure) + 1)
        )

        # ---------- Instantaneous shortage ----------

        instantaneous_unmet_pct = np.where(
            Qdem > 1e-12,
            100 * shortage / Qdem,
            0.0
        )

        # Store for plotting

        results["VolumeUnmetPct"] = volume_unmet_pct
        results["TimeUnmetPct"] = time_unmet_pct
        results["InstantaneousUnmetPct"] = instantaneous_unmet_pct
        results["QShortage"] = shortage

       # rate of change 
        roc_pct = np.zeros(len(results["QTreatment"]))
        roc_pct[1:] = (
            np.diff(results["QTreatment"])
            / np.maximum(results["QTreatment"][:-1], 1e-12)
        ) * 100

        results["QTreatmentRateChangePct"] = roc_pct


        # ==========================================================
        # Reliability by year and 5-year period
        # ==========================================================

        annual = {}

        for i, dt in enumerate(self.io.datetimes):
            year = dt.year

            if year not in annual:
                annual[year] = {
                    "Demand": 0.0,
                    "Delivered": 0.0,
                    "Shortage": 0.0,
                }

            annual[year]["Demand"] += results["Qdem"][i]
            annual[year]["Delivered"] += results["QDistribution"][i]
            annual[year]["Shortage"] += results["QShortage"][i]

        print("\n" + "=" * 55)
        print("ANNUAL VOLUMETRIC RELIABILITY")
        print("=" * 55)

        for year in sorted(annual):
            demand = annual[year]["Demand"]
            delivered = annual[year]["Delivered"]
            annual_shortage = annual[year]["Shortage"]

            reliability = delivered / max(demand, 1e-12)

            print(
                f"{year}: "
                f"{reliability * 100:8.3f}%  "
                f"(Demand = {demand:.3f}, "
                f"Delivered = {delivered:.3f}, "
                f"Shortage = {annual_shortage:.3f})"
            )

        first_5_demand = 0.0
        first_5_delivered = 0.0

        second_5_demand = 0.0
        second_5_delivered = 0.0

        for year in sorted(annual):
            if year <= 2004:
                first_5_demand += annual[year]["Demand"]
                first_5_delivered += annual[year]["Delivered"]
            elif year >= 2005:
                second_5_demand += annual[year]["Demand"]
                second_5_delivered += annual[year]["Delivered"]

        first_5_reliability = (
            first_5_delivered / max(first_5_demand, 1e-12)
        )

        second_5_reliability = (
            second_5_delivered / max(second_5_demand, 1e-12)
        )

        total_demand = first_5_demand + second_5_demand
        total_delivered = first_5_delivered + second_5_delivered

        total_reliability = (
            total_delivered / max(total_demand, 1e-12)
        )

        print("\n" + "=" * 55)
        print("FIVE-YEAR COMPARISON")
        print("=" * 55)

        print(f"Years 1-5 reliability   : {first_5_reliability * 100:8.3f}%")
        print(f"Years 6-10 reliability  : {second_5_reliability * 100:8.3f}%")
        print(f"Full 10-year reliability: {total_reliability * 100:8.3f}%")


        t_datetime = np.array(self.io.datetimes)
        
        legend_loc = "upper left"

        plt.figure(figsize=(12, 13))

        # 1. Storage volumes
        ax = plt.subplot(5, 1, 1)
        plt.plot(
            t_datetime,
            results["ProcessBasinVolume"],
            label="Process basin volume",
            linewidth=2,
        )
        plt.plot(
            t_datetime,
            results["ASRVolume"],
            label="ASR volume",
            linewidth=2,
        )
        ax.set_ylabel("Volume (m³)")
        plt.legend(loc=legend_loc)
        ax.xaxis.set_major_locator(mdates.MonthLocator(bymonth=[1, 7]))
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
        plt.setp(ax.get_xticklabels(), rotation=45, ha="right")
        plt.grid(which="both")

        # 2. External inflows
        ax = plt.subplot(5, 1, 2)
        plt.plot(
            t_datetime,
            results["Qint"],
            label="Qint / river intake",
            linewidth=2,
        )
        plt.plot(
            t_datetime,
            results["Qadd"],
            label="Qadd",
            linewidth=2,
        )

        ax.set_ylabel("Discharge (m³/s)")
        plt.legend(loc=legend_loc)
        ax.xaxis.set_major_locator(mdates.MonthLocator(bymonth=[1, 7]))
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
        plt.setp(ax.get_xticklabels(), rotation=45, ha="right")         
        plt.grid(which="both")

        # 3. Treatment and distribution
        ax = plt.subplot(5, 1, 3)

        q_treat_plot = np.round(results["QTreatment"], 6)
        q_dist_plot = np.round(results["QDistribution"], 6)

        plt.plot(
            t_datetime,
            q_treat_plot,
            label="Treatment flow",
            linewidth=2,
        )

        plt.plot(
            t_datetime,
            q_dist_plot,
            label="Distribution flow",
            linewidth=2,
        )

        plt.plot(
            t_datetime,
            self.get_timeseries("Qdem"),
            label="Demand",
            linewidth=1,
            linestyle="--",
        )

        ax.set_ylabel("Discharge (m³/s)")
        plt.legend(loc=legend_loc)
        ax.xaxis.set_major_locator(mdates.MonthLocator(bymonth=[1, 7]))
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
        plt.setp(ax.get_xticklabels(), rotation=45, ha="right")
        plt.grid(which="both")

        # 4. ASR flows
        ax = plt.subplot(5, 1, 4)
        plt.plot(
            t_datetime,
            results["QASRInjection"],
            label="ASR injection",
            linewidth=2,
        )
        plt.plot(
            t_datetime,
            results["QASRExtracted"],
            label="ASR extraction",
            linewidth=2,
        )
        ax.set_ylabel("Discharge (m³/s)")
        plt.legend(loc=legend_loc)
        ax.xaxis.set_major_locator(mdates.MonthLocator(bymonth=[1, 7]))
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
        plt.setp(ax.get_xticklabels(), rotation=45, ha="right")
        plt.grid(which="both")

        # ==========================================================
        # 5. Water supply reliability
        # ==========================================================

        ax = plt.subplot(5,1,5)
        ax.set_title("Water Supply Reliability")
       
        ax.plot(
            t_datetime,
            results["VolumeUnmetPct"],
            linewidth=2,
            label="Cumulative volumetric unmet"
        )

        ax.plot(
            t_datetime,
            results["TimeUnmetPct"],
            linewidth=2,
            label="Percentage of weeks with >1% shortage"
        )

        ax.set_ylabel("Cumulative (%)")
        ax.set_ylim(0,100)
        ax.set_xlabel("Date")
        ax2 = ax.twinx()

        ax2.plot(
            t_datetime,
            results["InstantaneousUnmetPct"],
            "--",
            linewidth=1,
            alpha=0.5,
            label="Weekly unmet (%)"
        )

        ax2.set_ylabel("Weekly (%)")
        ax2.set_ylim(0,100)

        lines = ax.get_lines() + ax2.get_lines()
        labels = [l.get_label() for l in lines]

        ax.legend(lines, labels, loc=legend_loc, fontsize=8)

        ax.grid(which="both")

        ax.xaxis.set_major_locator(
            mdates.MonthLocator(bymonth=[1,7])
        )

        ax.xaxis.set_major_formatter(
            mdates.DateFormatter("%b %Y")
        )

        plt.setp(
            ax.get_xticklabels(),
            rotation=45,
            ha="right"
        )

        plt.tight_layout()
        plt.savefig(self._output_folder + "\\ResultsPlot.png")
        plt.close()

        # ----------------------------------------
        # Mass balance diagnostics
        # ----------------------------------------

        n = len(results["ASRVolume"])

        asr_error = np.zeros(n)
        pb_error = np.zeros(n)

        dt = 7 * 24 * 3600  # seconds

        for i in range(1, n):

            asr_error[i] = (
                results["ASRVolume"][i]
                - results["ASRVolume"][i - 1]
                - (
                    results["QASRInjection"][i]
                    - results["QASRExtracted"][i]
                ) * dt
            )

            # Process basin loses raw treatment intake, not usable treated output
            pb_error[i] = (
                results["ProcessBasinVolume"][i]
                - results["ProcessBasinVolume"][i - 1]
                - (
                    results["Qint"][i]
                    + results["Qadd"][i]
                    - results["QTreatmentRaw"][i]
                ) * dt
            )

        # Treatment loss should equal 20% of raw treatment intake
        treatment_loss_error = (
            results["QTreatmentLossFlow"]
            - 0.2 * results["QTreatmentRaw"]
        )
         # Total ASR water supplied over the simulation

        dt_seconds = 7 * 24 * 3600  # seconds per weekly timestep
        total_asr_supplied = np.sum(results["QASRExtracted"]) * dt_seconds


        # ==========================================================
        # ASR / summer diagnostic
        # ==========================================================

        # ASR is considered active when extraction is greater than
        # a very small numerical tolerance.
        asr_active = results["QASRExtracted"] > 1e-9

        # Identify the years in which ASR was used during summer (June-August).
        summer_asr_years = set()

        for i, timestamp in enumerate(self.io.datetimes):
            if asr_active[i] and timestamp.month in [6, 7, 8]:
                summer_asr_years.add(timestamp.year)

        number_of_active_summers = len(summer_asr_years)

        # Average ASR volume supplied during summers when ASR was active.
        average_asr_per_active_summer = (
            total_asr_supplied / number_of_active_summers
            if number_of_active_summers > 0
            else 0.0
        )

        # Approximate additional population supported by ASR per active summer.
        per_person_daily_demand = 0.125  # m³/person/day = 125 L/person/day
        summer_days = 90

        additional_people_per_summer = (
            average_asr_per_active_summer
            / (per_person_daily_demand * summer_days)
        )

        # Total water supplied and ASR contribution.
        total_water_supplied = np.sum(results["QDistribution"]) * dt_seconds
        asr_percentage = (
            100 * total_asr_supplied / total_water_supplied
            if total_water_supplied > 0
            else 0.0
        )

        print("\nWater Supply Reliability")
        print("-" * 55)
        print(f"Total ASR water supplied : {total_asr_supplied / 1e6:8.3f} Mm³")
        print(f"Maximum unmet demand     : {np.max(shortage):8.3f} m³/s")
        print(f"Average unmet demand     : {np.mean(shortage):8.4f} m³/s")
        print(f"Volumetric reliability   : {100-results['VolumeUnmetPct'][-1]:8.2f} %")
        print(f"Percentage of weeks with >1% shortage : {results['TimeUnmetPct'][-1]:8.2f} %")
        print(f"Years 1-5 reliability    : {first_5_reliability * 100:8.3f}%")
        print(f"Years 6-10 reliability   : {second_5_reliability * 100:8.3f}%")
        print(f"Summers with ASR supplied : {number_of_active_summers:8d}")
        print(f"Average ASR per active summer : {average_asr_per_active_summer / 1e6:8.3f} Mm³/summer")
        print(f"Additional people per active summer : {additional_people_per_summer:8.0f} people")
        print(f"Total water supplied      : {total_water_supplied / 1e6:8.3f} Mm³")
        print(f"Percentage supplied by ASR: {asr_percentage:8.2f} %")



        print("\nTreatment Plant")
        print("-" * 55)
        print(f"Mean treatment flow      : {np.mean(results['QTreatment']):8.3f} m³/s")
        print(f"Minimum treatment flow   : {np.min(results['QTreatment']):8.3f} m³/s")
        print(f"Maximum treatment flow   : {np.max(results['QTreatment']):8.3f} m³/s")
        print(f"Treatment range          : {np.ptp(results['QTreatment']):8.3f} m³/s")

        
        # ==========================================================
        # MASS BALANCE CHECK
        # ==========================================================

        print("\n" + "=" * 55)
        print("MASS BALANCE CHECK")
        print("=" * 55)

        print(f"Maximum ASR storage error     : {np.max(np.abs(asr_error)):10.3e} m³")
        print(f"Maximum process basin error   : {np.max(np.abs(pb_error)):10.3e} m³")
        print(f"Maximum treatment loss error  : {np.max(np.abs(treatment_loss_error)):10.3e} m³/s")

        print("=" * 55)

        super().post()


if __name__ == "__main__":
    run_optimization_problem(
        StrategicHeartWeekly,
        log_level=logging.INFO,
        plotting_library="matplotlib",
    )