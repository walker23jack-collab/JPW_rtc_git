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


class StrategicHeartHourly(
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

    """
    Optimization problem for the Strategic Heart process basin, treatment plant,
    ASR well, and distribution network.
    """

    def post(self):
        results = self.extract_results()
        print("QTreatment min:", np.min(results["QTreatment"]))
        print("QTreatment max:", np.max(results["QTreatment"]))
        print("QTreatment range:", np.max(results["QTreatment"]) - np.min(results["QTreatment"]))
        t_datetime = np.array(self.io.datetimes)
        legend_loc = "upper left"

        plt.figure(figsize=(12, 10))

        # 1. Storage volumes
        ax = plt.subplot(4, 1, 1)
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
        dateFormat = mdates.DateFormatter("%d %b")
        plt.gca().xaxis.set_major_formatter(dateFormat)
        plt.grid(which="both")

        # 2. External inflows
        ax = plt.subplot(4, 1, 2)
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
        plt.gca().xaxis.set_major_formatter(dateFormat)
        plt.grid(which="both")

        # 3. Treatment and distribution
        ax = plt.subplot(4, 1, 3)

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
        plt.gca().xaxis.set_major_formatter(dateFormat)
        plt.grid(which="both")

        # 4. ASR flows
        ax = plt.subplot(4, 1, 4)
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
        plt.gca().xaxis.set_major_formatter(dateFormat)
        plt.grid(which="both")

        plt.tight_layout()
        plt.savefig(self._output_folder + "\\ResultsPlot.png")
        plt.close()
        
        # ----------------------------------------
        # Mass balance diagnostics
        # ----------------------------------------

        n = len(results["ASRVolume"])

        asr_error = np.zeros(n)
        pb_error = np.zeros(n)

        dt = 6 * 3600  # seconds

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

        print("\n--- Mass Balance Check ---")
        print("Max ASR error:", np.max(np.abs(asr_error)), "m³")
        print("Max PB error :", np.max(np.abs(pb_error)), "m³")
        print(
            "Max treatment-loss error:",
            np.max(np.abs(treatment_loss_error)),
            "m³/s",
        )

        shortage = (
            self.get_timeseries("Qdem").values
            - results["QDistribution"]
        )

        print("Maximum unmet demand:", np.max(shortage), "m³/s")
        print("Maximum oversupply:", -np.min(shortage), "m³/s")

 # Total ASR water supplied over the simulation

        dt_seconds = 6 * 3600  # seconds per weekly timestep
        total_asr_supplied = np.sum(results["QASRExtracted"]) * dt_seconds

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

 # ---------- Instantaneous shortage ----------

        instantaneous_unmet_pct = np.where(
            Qdem > 1e-12,
            100 * shortage / Qdem,
            0.0
        )

        # Store for plotting

        results["VolumeUnmetPct"] = volume_unmet_pct
        results["InstantaneousUnmetPct"] = instantaneous_unmet_pct
        results["QShortage"] = shortage

       # rate of change 
        roc_pct = np.zeros(len(results["QTreatment"]))
        roc_pct[1:] = (
            np.diff(results["QTreatment"])
            / np.maximum(results["QTreatment"][:-1], 1e-12)
        ) * 100

        results["QTreatmentRateChangePct"] = roc_pct

         # -------------------------
        # Temporal reliability
        # -------------------------
        
        # failure if supply is less than 99% of demand
        
        failure = shortage / np.maximum(Qdem,1e-12) > 0.01

       

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
        print(f"Total water supplied      : {total_water_supplied / 1e6:8.3f} Mm³")
        print(f"Percentage supplied by ASR: {asr_percentage:8.2f} %")



        print("\nTreatment Plant")
        print("-" * 55)
        print(f"Mean treatment flow      : {np.mean(results['QTreatment']):8.3f} m³/s")
        print(f"Minimum treatment flow   : {np.min(results['QTreatment']):8.3f} m³/s")
        print(f"Maximum treatment flow   : {np.max(results['QTreatment']):8.3f} m³/s")
        print(f"Treatment range          : {np.ptp(results['QTreatment']):8.3f} m³/s")
        

        super().post()


if __name__ == "__main__":
    run_optimization_problem(
        StrategicHeartHourly,
        log_level=logging.INFO,
        plotting_library="matplotlib",
    )