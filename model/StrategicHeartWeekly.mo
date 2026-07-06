model StrategicHeartWeekly
  import SI = Modelica.Units.SI;

  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Inflow RiverIntake annotation(
    Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Inflow AdditionalWater annotation(
    Placement(visible = true, transformation(origin = {-88, 66}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.Nodes.Node Processbasinnode(nin = 2, nout = 1) annotation(
    Placement(visible = true, transformation(origin = {-58, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.Storage.Storage processbasin(
    V(start = 0, fixed = true)
  ) annotation(
    Placement(visible = true, transformation(origin = {-22, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.Nodes.Node TreatmentPlant(nin = 1, nout = 3) annotation(
    Placement(visible = true, transformation(origin = {10, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.Storage.Storage ASRwell(
    V(start = 0, fixed = true)) annotation(Placement(visible = true, transformation(origin = {46, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.Nodes.Node DistributionNetwork(nin = 2, nout = 1) annotation(
    Placement(visible = true, transformation(origin = {62, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Terminal WaterDemand annotation(
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Terminal QTreatmentLossBoundary annotation(
  Placement(visible = true, transformation(origin = {26, 38}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

// Inputs
  input SI.VolumeFlowRate Qdem(fixed = true);
  input SI.VolumeFlowRate Qint(fixed = false, min = 0);
  input SI.VolumeFlowRate Qadd(fixed = false, min = 0, max =0.1585);

// Outputs
  output SI.Volume ProcessBasinVolume;
  output SI.Volume ASRVolume;
  output SI.VolumeFlowRate QTreatment(min = 0, max = 1.585);
  output SI.VolumeFlowRate QDistribution(min = 0);
  output SI.VolumeFlowRate QASRInjection(min = 0);
  output SI.VolumeFlowRate QASRExtracted(min = 0);
  output SI.VolumeFlowRate QTreatmentDistributed(min = 0);
  output SI.VolumeFlowRate QTreatmentRaw(min = 0);
  output SI.VolumeFlowRate QTreatmentLossFlow(min = 0);
  output SI.VolumeFlowRate QShortage(min = 0);
  output SI.VolumeFlowRate QDemand;

  parameter Real treatment_efficiency = 0.8;
  
  equation
  RiverIntake.Q = Qint;
  AdditionalWater.Q = Qadd;
  QShortage = Qdem - QDistribution;
  ProcessBasinVolume = processbasin.V;
  ASRVolume = ASRwell.V;
// Raw water entering treatment from the process basin
  QTreatmentRaw = TreatmentPlant.QIn[1].Q;
// Treatment plant outlet flows
  QASRInjection = TreatmentPlant.QOut[1].Q;
  QTreatmentDistributed = TreatmentPlant.QOut[2].Q;
  QTreatmentLossFlow = TreatmentPlant.QOut[3].Q;
// Usable treated water
  QTreatment = QTreatmentDistributed + QASRInjection;
// Treatment efficiency split
  QTreatment = treatment_efficiency * QTreatmentRaw;
  QTreatmentLossFlow = (1 - treatment_efficiency) * QTreatmentRaw;
// ASR extraction and distribution
  QASRExtracted = ASRwell.Q_release;
  QDistribution = QTreatmentDistributed + QASRExtracted;
// Demand terminal receives actual delivered water, not forced demand
  WaterDemand.Q = QDistribution;
  // Making Qdem available for the plotting
  QDemand = Qdem;

  connect(RiverIntake.QOut, Processbasinnode.QIn[1]) annotation(
    Line(points = {{-82, 0}, {-66, 0}}));

  connect(AdditionalWater.QOut, Processbasinnode.QIn[2]) annotation(
    Line(points = {{-80, 66}, {-66, 66}, {-66, 0}}));

  connect(Processbasinnode.QOut[1], processbasin.QIn) annotation(
    Line(points = {{-50, 0}, {-30, 0}}));

  connect(processbasin.QOut, TreatmentPlant.QIn[1]) annotation(
    Line(points = {{-14, 0}, {2, 0}}));

  connect(TreatmentPlant.QOut[1], ASRwell.QIn) annotation(
    Line(points = {{18, 0}, {30, 0}, {30, -40}, {38, -40}}));

  connect(TreatmentPlant.QOut[2], DistributionNetwork.QIn[1]) annotation(
    Line(points = {{18, 0}, {54, 0}}, thickness = 0.5));

  connect(ASRwell.QOut, DistributionNetwork.QIn[2]) annotation(
    Line(points = {{54, -40}, {54, 0}}));

  connect(DistributionNetwork.QOut[1], WaterDemand.QIn) annotation(
    Line(points = {{70, 0}, {82, 0}}));
  connect(TreatmentPlant.QOut[3], QTreatmentLossBoundary.QIn) annotation(
    Line(points = {{18, 0}, {18, 38}}));
annotation(
    Diagram(graphics = {Text(origin = {-84, 62}, extent = {{-12, 0}, {12, -16}}, textString = "Qadd"), Text(origin = {-87, -4}, extent = {{-11, 0}, {11, -18}}, textString = "Qint"), Text(origin = {-21, 38}, extent = {{-15, 0}, {15, -30}}, textString = "Process
basin"), Text(origin = {33, 56}, extent = {{-25, 0}, {25, -20}}, textString = "TreatmentLosses"), Text(origin = {10, -4}, extent = {{-22, 0}, {22, -20}}, textString = "Treatment
Plant"), Text(origin = {90, -4}, extent = {{-8, 0}, {8, -12}}, textString = "Qdem"), Text(origin = {54, -44}, extent = {{-14, 0}, {14, -22}}, textString = "ASRwell")}));
end StrategicHeartWeekly;
