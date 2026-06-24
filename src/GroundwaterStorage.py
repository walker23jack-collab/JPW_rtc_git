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


class GroundwaterStorage(ExportResultsEachPriorityMixin, PlotMixin, GoalGeneratorMixin, GoalProgrammingMixin, CSVMixin, ModelicaMixin, CollocatedIntegratedOptimizationProblem):
    csv_equidistant = False
    plot_max_rows = 5
    """
    An optimization problem for groundwater storage 
    """

    def post(self):
        results = self.extract_results()
        # parameters = self.parameters(0)
        T = self.times()
        t_datetime = np.array(self.io.datetimes)
        # print(T)
        legend_loc = 'upper left'
        plt.figure(figsize=(12, 8))
        ax = plt.subplot(4, 1, 1)
        plt.plot(t_datetime, results['GroundwaterLevel'], label='Groundwater level', linewidth=2, linestyle='-',color='blue')
        plt.plot(t_datetime, self.get_timeseries('GroundwaterLevel_min'), linewidth=0.8, linestyle='--', color='red')
        plt.plot(t_datetime, self.get_timeseries('GroundwaterLevel_max'), label='Groundwater level range', linewidth=0.8, linestyle='--', color='red')
        plt.axhline(y=0.0, color='black', linestyle='-', linewidth=0.5)
        plt.axhline(y=4.3, color='red', linestyle='--', linewidth=0.25, label='Groundwater level target')
        ax.set_ylabel("Elevation (m)")
        plt.legend(loc='lower left')
        dateFormat = mdates.DateFormatter('%d %b')
        plt.gca().xaxis.set_major_formatter(dateFormat)
        plt.grid(which='both')

        ax = plt.subplot(4, 1, 2)
        plt.plot(t_datetime, results['GroundwaterBalanceIn'], label='Groundwater balance, in', linewidth=2, linestyle='-',color='cyan')
        plt.plot(t_datetime, results['GroundwaterBalanceOut'], label='Groundwater balance, out', linewidth=2, linestyle='--',color='magenta')   
        ax.set_ylabel("Discharge (m³/s)")
        plt.legend(loc=legend_loc)
        dateFormat = mdates.DateFormatter('%d %b')
        plt.gca().xaxis.set_major_formatter(dateFormat)
        plt.grid(which='both')


        ax = plt.subplot(4, 1, 3)
        plt.plot(t_datetime, results['RiverIntakeDischarge'], label='River intake', linewidth=2, linestyle='-',color='blue')
        plt.plot(t_datetime, self.get_timeseries('RiverIntakeMax'), label='River intake max', linewidth=2, linestyle='--', color='red')
        plt.plot(t_datetime, results['GroundwaterRechargeCMS'], label='Groundwater recharge', linewidth=0.8, linestyle='-', color='green')
        plt.plot(t_datetime, results['RiverAquiferFlow'], label='River-aquifer flow', linewidth=1.5, linestyle='-', color='purple')
        plt.plot(t_datetime, self.get_timeseries('GroundwaterExtractionCMS'), label='Groundwater extraction', linewidth=2, linestyle='-',color='orange')
        plt.plot(t_datetime, self.get_timeseries('GroundwaterFlow'), label='Groundwater base flow', linewidth=1, linestyle='-',color='brown')
        plt.axhline(y=0.0, color='black', linestyle='-', linewidth=0.5)
        ax.set_ylabel("Discharge (m³/s)")
        plt.legend(loc=legend_loc)
        dateFormat = mdates.DateFormatter('%d %b')
        plt.gca().xaxis.set_major_formatter(dateFormat)
        plt.grid(which='both')

        ax = plt.subplot(4, 1, 4)
        plt.plot(t_datetime, results['RiverAquiferHeadDifference'], label='Head difference aquifer-river', linewidth=2, linestyle='-',color='black')
        plt.plot(t_datetime, self.get_timeseries('RiverStage'), label='River stage', linewidth=2, linestyle='-',color='grey')
        plt.axhline(y=0.0, color='black', linestyle='-', linewidth=0.5)
        ax.set_xlabel("Time")
        ax.set_ylabel("Elevation (m)")
        plt.legend(loc=legend_loc)
        dateFormat = mdates.DateFormatter('%d %b')
        plt.gca().xaxis.set_major_formatter(dateFormat)
        plt.grid(which='both')

        plt.tight_layout()
        plt.savefig(self._output_folder + '\\ResultsPlot.png')
        plt.close()
        super().post()


    # Run
if __name__ == "__main__":
    run_optimization_problem(GroundwaterStorage, log_level=logging.INFO, plotting_library="matplotlib")
