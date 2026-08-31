# JPW_rtc
This github includes JPW's model files for the StrategicHeart project
# Description
The project assesses the capacity for addition of an ASR well to the Dutch water supply. Water is extracted from the IJssel river (**Qint**), brought to a processing basin, then to a treatment plant (**Qtreatment**). From the plant, water will either be distributed to the network (**Qdis**) or infiltrated at an ASR well (**QASRinfiltration**) for future extraction (**QASRExtracted**)
# Goals
- Use ASR infiltration/extraction to absorb peak demands
- Make Qtreatment as constant as possible
- Meet demand without exceeding physical capacities

# How to use
1. Download RTC-Tools software. Instructions here: https://github.com/rtc-tools/rtc-tools
2. Download model files:
    - .mo modelica file
    - py script
    - input timeseries (must rename to "timeseries_import"
    - goal table
    - plot table
3. Run RTC-Tools using batch command located within RTC tools download, ensuring that command has proper paths for the above files
4. Further instruction located here: https://rtc-tools.readthedocs.io/en/stable/

# Documentation
More information about project and its goals can be found in /documentation folder
