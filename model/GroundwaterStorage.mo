model GroundwaterStorage
  import SI = Modelica.Units.SI;
  // Ghe groundwater body is modelled as a storage node.
  Deltares.ChannelFlow.SimpleRouting.Storage.Storage GroundwaterBody(n_QForcing = 0, V(min = 0, max = 90000000, nominal = 17500000)) annotation(
    Placement(visible = true, transformation(origin = {8, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  // Nodes and boundary condition objects
  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Inflow GroundwaterRecharge annotation(
    Placement(transformation(origin = {-58, 50}, extent = {{-10, -10}, {10, 10}})));
  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Inflow RiverIntake annotation(
    Placement(transformation(origin = {-76, 20}, extent = {{-10, -10}, {10, 10}})));
  Deltares.ChannelFlow.SimpleRouting.Nodes.Node Inflow(nin = 3, nout = 1) annotation(
    Placement(visible = true, transformation(origin = {-22, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Terminal RiverAquiferInteraction annotation(
    Placement(transformation(origin = {76, 44}, extent = {{-10, -10}, {10, 10}})));
  Deltares.ChannelFlow.SimpleRouting.Nodes.Node Outflow(nin = 1, nout = 2) annotation(
    Placement(visible = true, transformation(origin = {34, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Terminal GroundwaterExtraction annotation(
    Placement(transformation(origin = {76, 20}, extent = {{-10, -10}, {10, 10}})));
  Deltares.ChannelFlow.SimpleRouting.BoundaryConditions.Inflow GroundwaterInflow annotation(
    Placement(transformation(origin = {-72, 0}, extent = {{-10, -10}, {10, 10}})));
  // Time series
  input Real GroundwaterRechargeMMS(fixed = true);
  // groundwater recharge in mm per second
  input SI.VolumeFlowRate RiverIntakeDischarge(fixed = false, min = 0, max = 100, nominal = 8);
  input SI.Length RiverStage(fixed = true);
  input SI.VolumeFlowRate GroundwaterExtractionCMS(fixed = true);
  input SI.VolumeFlowRate GroundwaterFlow(fixed = true);
  output SI.VolumeFlowRate GroundwaterRechargeCMS;
  output SI.VolumeFlowRate RiverAquiferFlow(min = -10, max = 10, nominal = 0.1);
  output SI.Volume GroundwaterVolume;
  output SI.Length GroundwaterLevel(min = -10, max = 20, nominal = 2);
  output SI.Length RiverAquiferHeadDifference;
  output SI.VolumeFlowRate GroundwaterBalanceIn;
  output SI.VolumeFlowRate GroundwaterBalanceOut;
  // Scalars
  Real GroundwaterBodyArea;
  // paramters
  parameter Real cL = 4E-5;
  parameter SI.Length L = 10000;
  parameter SI.Length B = 5000;
  parameter Real Porosity = 0.25;
equation
// boundary conditions
  GroundwaterRecharge.Q = GroundwaterRechargeCMS;
  GroundwaterInflow.Q = GroundwaterFlow;
  GroundwaterRechargeCMS = GroundwaterRechargeMMS*GroundwaterBodyArea/1000;
  RiverIntake.Q = RiverIntakeDischarge;
  RiverAquiferInteraction.Q = -RiverAquiferFlow;
  GroundwaterExtraction.Q = GroundwaterExtractionCMS;
// groundwater level
  GroundwaterBodyArea = L*B;
  GroundwaterVolume = GroundwaterBodyArea*GroundwaterLevel*Porosity;
  GroundwaterVolume = GroundwaterBody.V;
// River-aquifer interaction according to Darcy's leakage concept
  RiverAquiferHeadDifference = -RiverStage + GroundwaterLevel;
  RiverAquiferFlow = RiverAquiferHeadDifference*cL*L*1.0;
  GroundwaterBalanceIn = GroundwaterRechargeCMS + RiverIntakeDischarge + GroundwaterFlow;
  GroundwaterBalanceOut = GroundwaterExtractionCMS - RiverAquiferFlow;
  connect(Inflow.QOut[1], GroundwaterBody.QIn) annotation(
    Line(points = {{-14, 20}, {0, 20}}));
  connect(RiverIntake.QOut, Inflow.QIn[1]) annotation(
    Line(points = {{-68, 20}, {-30, 20}}));
  connect(GroundwaterRecharge.QOut, Inflow.QIn[2]) annotation(
    Line(points = {{-50, 50}, {-50, 20}, {-30, 20}}));
  connect(GroundwaterBody.QOut, Outflow.QIn[1]) annotation(
    Line(points = {{16, 20}, {26, 20}}));
  connect(Outflow.QOut[1], RiverAquiferInteraction.QIn) annotation(
    Line(points = {{42, 20}, {42, 44}, {68, 44}}));
  connect(Outflow.QOut[2], GroundwaterExtraction.QIn) annotation(
    Line(points = {{42, 20}, {68, 20}}));
  connect(GroundwaterInflow.QOut, Inflow.QIn[3]) annotation(
    Line(points = {{-64, 0}, {-30, 0}, {-30, 20}}));
  annotation(
    Diagram(graphics = {Text(origin = {-67, -24}, extent = {{1, 0}, {-1, 0}}, textString = "River intake"), Text(origin = {-75, 34}, extent = {{-15, 6}, {15, -6}}, textString = "River intake"), Text(origin = {-27, 65}, extent = {{-33, 11}, {33, -11}}, textString = "Natural groundwater recharge"), Text(origin = {72, 5}, extent = {{-20, 11}, {20, -11}}, textString = "River aquifer interaction"), Text(origin = {68, 59}, extent = {{-20, 11}, {20, -11}}, textString = "Groundwater extraction"), Text(origin = {113, 13}, extent = {{-199, -35}, {-145, -21}}, textString = "Groundwater base flow")}, coordinateSystem(extent = {{-100, -100}, {100, 100}})));
end GroundwaterStorage;
