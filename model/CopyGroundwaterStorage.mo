model CopyGroundwaterStorage
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

  Deltares.ChannelFlow.SimpleRouting.Nodes.Node TreatmentPlant(nin = 1, nout = 2) annotation(
    Placement(visible = true, transformation(origin = {18, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.Storage.Storage ASRwell(
    V(start = 0, fixed = true)) annotation(Placement(visible = true, transformation(origin = {38, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.Nodes.Node DistributionNetwork(nin = 2, nout = 1) annotation(
    Placement(visible = true, transformation(origin = {60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Terminal WaterDemand annotation(
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  // Inputs
  input SI.VolumeFlowRate Qdem(fixed = true);
  input SI.VolumeFlowRate Qint(fixed = false, min = 0);
  input SI.VolumeFlowRate Qadd(fixed = false, min = 0, max =0.1);

  // Outputs
  output SI.Volume ProcessBasinVolume;
  output SI.Volume ASRVolume;
  output SI.VolumeFlowRate QTreatment(min = 0, max = 1.585);
  output SI.VolumeFlowRate QDistribution(min = 0);
  output SI.VolumeFlowRate QASRInjection(min = 0);
  output SI.VolumeFlowRate QASRExtracted(min = 0);
  output SI.VolumeFlowRate QTreatmentDistributed(min = 0);

equation
  RiverIntake.Q = Qint;
  AdditionalWater.Q = Qadd;
  // WaterDemand.Q = Qdem;

  ProcessBasinVolume = processbasin.V;
  ASRVolume = ASRwell.V;
  QTreatmentDistributed = TreatmentPlant.QOut[2].Q;
  QASRInjection = TreatmentPlant.QOut[1].Q;
  QTreatment = QTreatmentDistributed + QASRInjection;

  QASRExtracted = ASRwell.Q_release;
  QDistribution = QTreatmentDistributed + QASRExtracted;
  WaterDemand.Q = QDistribution;

  connect(RiverIntake.QOut, Processbasinnode.QIn[1]) annotation(
    Line(points = {{-82, 0}, {-66, 0}}));

  connect(AdditionalWater.QOut, Processbasinnode.QIn[2]) annotation(
    Line(points = {{-80, 66}, {-66, 66}, {-66, 0}}));

  connect(Processbasinnode.QOut[1], processbasin.QIn) annotation(
    Line(points = {{-50, 0}, {-30, 0}}));

  connect(processbasin.QOut, TreatmentPlant.QIn[1]) annotation(
    Line(points = {{-14, 0}, {10, 0}}));

  connect(TreatmentPlant.QOut[1], ASRwell.QIn) annotation(
    Line(points = {{26, 0}, {30, 0}, {30, -40}}));

  connect(TreatmentPlant.QOut[2], DistributionNetwork.QIn[1]) annotation(
    Line(points = {{26, 0}, {52, 0}}, thickness = 0.5));

  connect(ASRwell.QOut, DistributionNetwork.QIn[2]) annotation(
    Line(points = {{46, -40}, {52, -40}, {52, 0}}));

  connect(DistributionNetwork.QOut[1], WaterDemand.QIn) annotation(
    Line(points = {{68, 0}, {82, 0}}));

end CopyGroundwaterStorage;