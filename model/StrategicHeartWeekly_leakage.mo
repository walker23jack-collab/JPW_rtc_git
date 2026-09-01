model StrategicHeartWeekly
  import SI = Modelica.Units.SI;

  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Inflow RiverIntake annotation(
    Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Inflow AdditionalWater annotation(
    Placement(visible = true, transformation(origin = {-88, 66}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.Nodes.Node Processbasinnode(nin = 2, nout = 1) annotation(
    Placement(visible = true, transformation(origin = {-64, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.Storage.Storage processbasin(
    V(start = 0, fixed = true)
  ) annotation(
    Placement(visible = true, transformation(origin = {-32, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.Nodes.Node TreatmentPlant(nin = 1, nout = 3) annotation(
    Placement(visible = true, transformation(origin = {-4, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  
  Deltares.ChannelFlow.SimpleRouting.Storage.Storage ASRwell (V(start=0))  annotation(
    Placement(visible = true, transformation(origin = {18, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  
  Deltares.ChannelFlow.SimpleRouting.Nodes.Node DistributionNetwork(nin = 2, nout = 1) annotation(
    Placement(visible = true, transformation(origin = {68, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Terminal WaterDemand annotation(
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Terminal QTreatmentLossBoundary annotation(
  Placement(visible = true, transformation(origin = {12, 38}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  // Added: splits ASR discharge between the distribution network and the river.
  
  Deltares.ChannelFlow.SimpleRouting.Nodes.Node ASRwellOutflow(nin = 1, nout = 2)  annotation(
    Placement(visible = true, transformation(origin = {46, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  
  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Terminal RiverAquiferInteraction annotation(
    Placement(visible = true, transformation(origin = {82, -66}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  // Inputs
  input SI.VolumeFlowRate Qdem(fixed = true);
  input SI.VolumeFlowRate Qint(fixed = false, min = 0);
  input SI.VolumeFlowRate Qadd(fixed = false, min = 0);
  input SI.VolumeFlowRate QaddMax(fixed = true);
  input SI.Length RiverStage(fixed = true);

// Outputs
  output SI.Volume ProcessBasinVolume;
  output SI.Volume ASRVolume;
  output SI.VolumeFlowRate QTreatment(min = 0);
  output SI.VolumeFlowRate QDistribution(min = 0);
  output SI.VolumeFlowRate QASRInjection(min = 0);
  output SI.VolumeFlowRate QASRExtracted(min = 0);
  output SI.VolumeFlowRate QTreatmentDistributed(min = 0);
  output SI.VolumeFlowRate QTreatmentRaw(min = 0);
  output SI.VolumeFlowRate QTreatmentLossFlow(min = 0);
  output SI.VolumeFlowRate QShortage(min = 0);
  output SI.VolumeFlowRate QDemand;
  output SI.VolumeFlowRate QASRThroughput(min = 0);
  output SI.VolumeFlowRate RiverAquiferFlow;
  output SI.Length ASRGroundwaterLevel;
  output SI.Length RiverAquiferHeadDifference;

  parameter Real treatment_efficiency = 0.8;
  // ASR equivalent aquifer geometry and leakage coefficient
  parameter Real cL = 1E-6;
  parameter SI.Length L = 10000;
  parameter SI.Length B = 416;
  parameter Real Porosity = 0.25;
  Real ASRAquiferArea;
  Real QTreatmentChange;
  
  equation
//boundary conditions
  RiverIntake.Q = Qint;
  AdditionalWater.Q = Qadd;
  QShortage = Qdem - QDistribution;
  ProcessBasinVolume = processbasin.V;
  WaterDemand.Q = QDistribution;
  RiverAquiferInteraction.Q = RiverAquiferFlow;
// Raw water entering treatment from the process basin
  QTreatmentRaw = TreatmentPlant.QIn[1].Q;
// Treatment plant outlet flows
  QASRInjection = TreatmentPlant.QOut[1].Q;
  QTreatmentDistributed = TreatmentPlant.QOut[2].Q;
  QTreatmentLossFlow = TreatmentPlant.QOut[3].Q;
// Usable treated water
  QTreatment = QTreatmentDistributed + QASRInjection;
// Treatment efficiency split
  QTreatment = QTreatmentRaw * treatment_efficiency;
  QTreatmentLossFlow = (1 - treatment_efficiency) * QTreatmentRaw;
// ASR extraction and distribution. Only the distribution branch is delivered.
  QASRExtracted = ASRwellOutflow.QOut[1].Q;
  QDistribution = QTreatmentDistributed + QASRExtracted;
//GW Level
  ASRAquiferArea = L*B;
  ASRVolume = ASRAquiferArea*Porosity*ASRGroundwaterLevel;
  ASRVolume = ASRwell.V;
// River-aquifer interaction according to Darcy's leakage concept
  RiverAquiferHeadDifference = -RiverStage + ASRGroundwaterLevel;
  RiverAquiferFlow = RiverAquiferHeadDifference*cL*L*1.0;
// Making Qdem available for the plotting
  QDemand = Qdem;
  QASRThroughput = QASRInjection + QASRExtracted;
  connect(RiverIntake.QOut, Processbasinnode.QIn[1]) annotation(
    Line(points = {{-82, 0}, {-72, 0}}));
  connect(AdditionalWater.QOut, Processbasinnode.QIn[2]) annotation(
    Line(points = {{-80, 66}, {-66, 66}, {-66, 0}, {-72, 0}}));
  connect(Processbasinnode.QOut[1], processbasin.QIn) annotation(
    Line(points = {{-56, 0}, {-40, 0}}));
  connect(processbasin.QOut, TreatmentPlant.QIn[1]) annotation(
    Line(points = {{-24, 0}, {-12, 0}}));
  connect(TreatmentPlant.QOut[2], DistributionNetwork.QIn[1]) annotation(
    Line(points = {{4, 0}, {60, 0}}, thickness = 0.5));
  connect(DistributionNetwork.QOut[1], WaterDemand.QIn) annotation(
    Line(points = {{76, 0}, {82, 0}}));
  connect(TreatmentPlant.QOut[3], QTreatmentLossBoundary.QIn) annotation(
    Line(points = {{4, 0}, {4, 38}}));
  connect(ASRwellOutflow.QOut[1], DistributionNetwork.QIn[2]) annotation(
    Line(points = {{54, -40}, {54, -20}, {60, -20}, {60, 0}}, thickness = 0.5));
  connect(ASRwellOutflow.QOut[2], RiverAquiferInteraction.QIn) annotation(
    Line(points = {{54, -40}, {72, -40}, {72, -66}, {74, -66}}));
  connect(TreatmentPlant.QOut[1], ASRwell.QIn) annotation(
    Line(points = {{4, 0}, {10, 0}, {10, -40}}));
  connect(ASRwell.QOut, ASRwellOutflow.QIn[1]) annotation(
    Line(points = {{26, -40}, {38, -40}}));
  annotation(
    Diagram(graphics = {Text(origin = {-84, 62}, extent = {{-12, 0}, {12, -16}}, textString = "Qadd"), Text(origin = {-87, -4}, extent = {{-11, 0}, {11, -18}}, textString = "Qint"), Text(origin = {-31, 38}, extent = {{-15, 0}, {15, -30}}, textString = "Process
basin"), Text(origin = {11, 56}, extent = {{-25, 0}, {25, -20}}, textString = "TreatmentLosses"), Text(origin = {-2, -4}, extent = {{-22, 0}, {22, -20}}, textString = "Treatment
Plant"), Text(origin = {90, -4}, extent = {{-8, 0}, {8, -12}}, textString = "Qdem"), Text(origin = {18, -40}, extent = {{-14, 0}, {14, -22}}, textString = "ASRwell")}, coordinateSystem(extent = {{-100, -100}, {100, 100}})));
end StrategicHeartWeekly;
