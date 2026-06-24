model CopyGroundwaterStorage
  import SI = Modelica.Units.SI;
  //ASR modeled as storage
  Deltares.ChannelFlow.SimpleRouting.Storage.Storage ASRwell(
  V(start = 0, min = 0, max = 5000000, nominal = 2500000)
) annotation(
    Placement(visible = true, transformation(origin = {40, -15}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  // Boundary condition objects
  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Inflow QintBoundary annotation(
    Placement(visible = true, transformation(origin = {-78, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Inflow QaddBoundary annotation(
    Placement(visible = true, transformation(origin = {-78, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Terminal QdemBoundary annotation(
    Placement(visible = true, transformation(origin = {90, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  // Time series input from timeseries_import.csv
  input SI.VolumeFlowRate Qdem(fixed = true);
  // Optimized control variables
  input SI.VolumeFlowRate Qint(fixed = false, min = 0, max = 100, nominal = 8);
  input SI.VolumeFlowRate Qadd(fixed = false, min = 0, max = 0, nominal = 1);
  // Outputs
  output SI.Volume ProcessBasinVolume;
  output SI.Volume ASRVolume;
  output SI.VolumeFlowRate QTreatment(min=0, max=2, nominal =1.6);
  output SI.VolumeFlowRate QDistribution(min=0, max=3, nominal =2);
  output SI.VolumeFlowRate QASRInjection(min = 0, nominal = 1);
  output SI.VolumeFlowRate QASRRecovery(min = 0, nominal = 1);
  // Scalars
  SI.VolumeFlowRate ProcessBasinIn;
  SI.VolumeFlowRate ProcessBasinOut;
  SI.VolumeFlowRate DistributionIn;
  SI.VolumeFlowRate DistributionOut;
  SI.VolumeFlowRate QDirectToDistribution;
  SI.VolumeFlowRate ASRIn;
  SI.VolumeFlowRate ASROut;
  // Parameters
  
  
  // Nodes and storage objects
  Deltares.ChannelFlow.SimpleRouting.Storage.Storage ProcessBasin(
  V(start = 0, min = 0, max = 3000000, nominal = 1500000)
) annotation(
    Placement(visible = true, transformation(origin = {-25, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Deltares.ChannelFlow.SimpleRouting.Nodes.Node Qtreatment(nin = 1, nout = 2) annotation(
    Placement(visible = true, transformation(origin = {15, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Deltares.ChannelFlow.SimpleRouting.Nodes.Node DistributionNetwork(nin = 2, nout = 1) annotation(
    Placement(visible = true, transformation(origin = {60, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
// Boundary conditions
  QintBoundary.Q = Qint;
  QaddBoundary.Q = Qadd;
  QdemBoundary.Q = Qdem;
// Bookkeeping
  ProcessBasinIn = Qint + Qadd;
  ProcessBasinOut = QTreatment;
  QTreatment = QDirectToDistribution + QASRInjection;
// Output variables
  ProcessBasinVolume = ProcessBasin.V;
  ASRVolume = ASRwell.V;
  ASRIn = QASRInjection;
  ASROut = QASRRecovery;
  DistributionIn = QDirectToDistribution + QASRRecovery;
  DistributionOut = Qdem;
  QDistribution = Qdem;
// Connections
  // Connections
  connect(QintBoundary.QOut, ProcessBasin.QIn) annotation(
    Line(points = {{-70, 20}, {-33, 20}}));

  connect(QaddBoundary.QOut, ProcessBasin.QIn) annotation(
    Line(points = {{-70, -20}, {-40, -20}, {-40, 20}, {-33, 20}}));

  connect(ProcessBasin.QOut, Qtreatment.QIn[1]) annotation(
    Line(points = {{-17, 20}, {7, 20}}));

  connect(Qtreatment.QOut[1], DistributionNetwork.QIn[1]) annotation(
    Line(points = {{23, 20}, {52, 20}}));

  connect(Qtreatment.QOut[2], ASRwell.QIn) annotation(
    Line(points = {{23, 20}, {32, 20}, {32, -15}}));

  connect(ASRwell.QOut, DistributionNetwork.QIn[2]) annotation(
    Line(points = {{48, -15}, {52, -15}, {52, 20}}));

  connect(DistributionNetwork.QOut[1], QdemBoundary.QIn) annotation(
    Line(points = {{68, 20}, {82, 20}}));

    annotation(
    Diagram(
      graphics = {
        Text(origin = {-78, 34}, extent = {{-15, 6}, {15, -6}}, textString = "Qint"),
        Text(origin = {-78, -34}, extent = {{-15, 6}, {15, -6}}, textString = "Qadd"),
        Text(origin = {-45, 57}, extent = {{-30, 6}, {30, -6}}, textString = "Processbekken"),
        Text(origin = {11, 47}, extent = {{-30, 6}, {30, -6}}, textString = "Treatment plant"),
        Text(origin = {40, -32}, extent = {{-25, 6}, {25, -6}}, textString = "ASR well"),
        Text(origin = {62, 37}, extent = {{-35, 6}, {35, -6}}, textString = "Distribution network"),
        Text(origin = {90, 6}, extent = {{-15, 6}, {15, -6}}, textString = "Qdem")
      },
      coordinateSystem(extent = {{-100, -100}, {100, 100}})
    )
  );

end CopyGroundwaterStorage;
