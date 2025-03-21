import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';

import 'package:fitness_ui_kit/data/latest_workout.dart';
import 'package:fitness_ui_kit/theme/colors.dart';
import 'package:fitness_ui_kit/widget/chart_activity_status.dart';
import 'package:fitness_ui_kit/widget/chart_sleep.dart';
import 'package:fitness_ui_kit/widget/chart_workout_progress.dart';
import 'package:fitness_ui_kit/widget/water_intake_progressbar.dart';
import 'package:fitness_ui_kit/widget/water_intake_timeline.dart';
import '../pages/activity_display_widget.dart';
import '../pages/sensor_chart_card.dart';
import '../services/bluetooth_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<FlSpot> _accX = [], _accY = [], _accZ = [];
  List<FlSpot> _gravityX = [], _gravityY = [], _gravityZ = [];
  List<FlSpot> _linearX = [], _linearY = [], _linearZ = [];
  List<FlSpot> _gyroX = [], _gyroY = [], _gyroZ = [];
  double _latestElapsedTime = 0;
  late StreamSubscription<List<int>> _sensorSub;
  Timer? _chartTimer;
  int _startTime = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _setupSensorListener();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getBody(),
    );
  }

  @override
  void dispose() {
    _bluetoothService.dispose(); // 确保释放资源
    _sensorSub.cancel();
    _chartTimer?.cancel();
    super.dispose();
  }

  void _setupSensorListener() {
    _sensorSub = _bluetoothService.sensorDataStream.listen((data) {
      if (data.length >= 52) {
        final byteData = Uint8List.fromList(data).buffer.asByteData();
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = (now - _startTime) / 1000;

        setState(() {
          _latestElapsedTime = elapsed;

          // 加速度数据
          _accX.add(FlSpot(elapsed, byteData.getFloat32(4, Endian.little)));
          _accY.add(FlSpot(elapsed, byteData.getFloat32(8, Endian.little)));
          _accZ.add(FlSpot(elapsed, byteData.getFloat32(12, Endian.little)));

          // 重力数据
          _gravityX.add(FlSpot(elapsed, byteData.getFloat32(16, Endian.little)));
          _gravityY.add(FlSpot(elapsed, byteData.getFloat32(20, Endian.little)));
          _gravityZ.add(FlSpot(elapsed, byteData.getFloat32(24, Endian.little)));

          // 线性加速度
          _linearX.add(FlSpot(elapsed, byteData.getFloat32(28, Endian.little)));
          _linearY.add(FlSpot(elapsed, byteData.getFloat32(32, Endian.little)));
          _linearZ.add(FlSpot(elapsed, byteData.getFloat32(36, Endian.little)));

          // 陀螺仪
          _gyroX.add(FlSpot(elapsed, byteData.getFloat32(40, Endian.little)));
          _gyroY.add(FlSpot(elapsed, byteData.getFloat32(44, Endian.little)));
          _gyroZ.add(FlSpot(elapsed, byteData.getFloat32(48, Endian.little)));

          // 保持数据长度
          _trimData(_accX, _accY, _accZ);
          _trimData(_gravityX, _gravityY, _gravityZ);
          _trimData(_linearX, _linearY, _linearZ);
          _trimData(_gyroX, _gyroY, _gyroZ);
        });
      }
    });
  }

  void _trimData(List<FlSpot> x, List<FlSpot> y, List<FlSpot> z) {
    const maxPoints = 100;
    while (x.length > maxPoints) x.removeAt(0);
    while (y.length > maxPoints) y.removeAt(0);
    while (z.length > maxPoints) z.removeAt(0);
  }

  Widget _buildSensorChart(String title, List<FlSpot> x, List<FlSpot> y, List<FlSpot> z,
      {required double minY, required double maxY}) {
    return Container(
      width: double.infinity,
      height: 220,
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.05),
            spreadRadius: 5,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: black,
                  ),
                ),
                Row(
                  children: [
                    _buildChartLegend("X", Colors.redAccent),
                    SizedBox(width: 12),
                    _buildChartLegend("Y", Colors.green),
                    SizedBox(width: 12),
                    _buildChartLegend("Z", Colors.blue),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getInterval(maxY),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _getInterval(maxY),
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _buildLineData(x, Colors.redAccent.withOpacity(0.8)),
                    _buildLineData(y, Colors.green.withOpacity(0.8)),
                    _buildLineData(z, Colors.blue.withOpacity(0.8)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  double _getInterval(double max) {
    if (max <= 5) return 1;
    if (max <= 20) return 5;
    return 10;
  }

  LineChartBarData _buildLineData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      shadow: Shadow(
        color: color.withOpacity(0.2),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
      dotData: FlDotData(show: false),
    );
  }



  Widget getBody() {
    var size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back",
                        style: TextStyle(fontSize: 14, color: black),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "Sopheamen",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: black),
                      ),
                    ],
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Icon(LineIcons.bell),
                    ),
                  )
                ],
              ),
              // 新增活动组件
              SizedBox(
                height: 30,
              ),
              ActivityDisplayWidget(bluetoothService: _bluetoothService),
              SizedBox(
                  height: 20
              ),
              Container(
                width: double.infinity,
                height: 145,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(colors: [secondary, primary]),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          width: (size.width),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "BMI (Body Mass Index)",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: white),
                              ),
                              Text(
                                "You have a normal weight",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: white),
                              ),
                              Container(
                                width: 95,
                                height: 35,
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        colors: [fourthColor, thirdColor]),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Center(
                                  child: Text(
                                    "View More",
                                    style:
                                        TextStyle(fontSize: 13, color: white),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient:
                              LinearGradient(colors: [fourthColor, thirdColor]),
                        ),
                        child: Center(
                          child: Text(
                            "20,3",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: white),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                    color: secondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today Target",
                        style: TextStyle(
                            fontSize: 17,
                            color: black,
                            fontWeight: FontWeight.w600),
                      ),
                      InkWell(
                        onTap: (){
                          Navigator.pushNamed(context, "/today_target_detail");
                        },
                        child: Container(
                          width: 70,
                          height: 35,
                          decoration: BoxDecoration(
                              gradient:
                                  LinearGradient(colors: [secondary, primary]),
                              borderRadius: BorderRadius.circular(20)),
                          child: Center(
                            child: Text(
                              "Check",
                              style: TextStyle(fontSize: 13, color: white),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                "Activity Status",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: black),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                    color: secondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30)),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      child: LineChart(activityData()),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Heart Rate",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                children: [
                  Container(
                    width: (size.width - 80) / 2,
                    height: 320,
                    decoration: BoxDecoration(
                        color: white,
                        boxShadow: [
                          BoxShadow(
                              color: black.withOpacity(0.01),
                              spreadRadius: 20,
                              blurRadius: 10,
                              offset: Offset(0, 10))
                        ],
                        borderRadius: BorderRadius.circular(30)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          WateIntakeProgressBar(),
                          SizedBox(
                            width: 15,
                          ),
                          Flexible(
                            child: Column(
                              children: [
                                Text(
                                  "Water Intake",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                Spacer(),
                                Column(
                                  children: [
                                    Text(
                                      "Real time updates",
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: black.withOpacity(0.5)),
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    WaterIntakeTimeLine()
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Column(
                    children: [
                      Container(
                        width: (size.width - 80) / 2,
                        height: 150,
                        decoration: BoxDecoration(
                            color: white,
                            boxShadow: [
                              BoxShadow(
                                  color: black.withOpacity(0.01),
                                  spreadRadius: 20,
                                  blurRadius: 10,
                                  offset: Offset(0, 10))
                            ],
                            borderRadius: BorderRadius.circular(30)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Sleep",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Spacer(),
                              Flexible(
                                child: LineChart(sleepData()),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                          width: (size.width - 80) / 2,
                          height: 150,
                          decoration: BoxDecoration(
                              color: white,
                              boxShadow: [
                                BoxShadow(
                                    color: black.withOpacity(0.01),
                                    spreadRadius: 20,
                                    blurRadius: 10,
                                    offset: Offset(0, 10))
                              ],
                              borderRadius: BorderRadius.circular(30)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Calories",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                Spacer(),
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          colors: [
                                            fourthColor,
                                            primary.withOpacity(0.5)
                                          ]),
                                      shape: BoxShape.circle),
                                  child: Center(
                                      child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle, color: primary),
                                    child: Center(
                                      child: Text(
                                        "230 Cal",
                                        style: TextStyle(
                                            fontSize: 10, color: white),
                                      ),
                                    ),
                                  )),
                                )
                              ],
                            ),
                          ))
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Workout Progress",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: black),
                  ),
                  Container(
                    width: 95,
                    height: 35,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [secondary, primary]),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Weekly",
                          style: TextStyle(fontSize: 13, color: white),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: white,
                        )
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(
                  height: 30
              ),
              _buildSensorChart("Acceleration", _accX, _accY, _accZ,
                  minY: -30.0, maxY: 30.0),
              SizedBox(
                  height: 10
              ),
              _buildSensorChart("Gravity", _gravityX, _gravityY, _gravityZ,
                  minY: -30.0, maxY: 30.0),
              SizedBox(
                  height: 10
              ),
              _buildSensorChart("Linear Acceleration", _linearX, _linearY, _linearZ,
                  minY: -30.0, maxY: 30.0),
              SizedBox(
                  height: 10
              ),
              _buildSensorChart("Gyroscope", _gyroX, _gyroY, _gyroZ,
                  minY: -30.0, maxY: 30.0),
              SizedBox(
                height: 20,
              ),
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                    color: white,
                    boxShadow: [
                      BoxShadow(
                          color: black.withOpacity(0.01),
                          spreadRadius: 20,
                          blurRadius: 10,
                          offset: Offset(0, 10))
                    ],
                    borderRadius: BorderRadius.circular(30)),
                child: LineChart(
                  workoutProgressData(),
                ),
              ),
              SizedBox(
                height: 30,
              ),
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Latest Workout",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: black),
                  ),
                   Text(
                          "See more",
                          style: TextStyle(fontSize: 15, color: black.withOpacity(0.5)),
                        ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Column(
                children: List.generate(latestWorkoutJson.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: white,
                    boxShadow: [
                      BoxShadow(
                        color: black.withOpacity(0.01),
                        spreadRadius: 20,
                        blurRadius: 10,
                        offset:Offset(0, 10)
                      )
                    ],
                    borderRadius: BorderRadius.circular(12)
                ),
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            image: DecorationImage(image: AssetImage(latestWorkoutJson[index]['img']))
                          ),
                        ),
                        SizedBox(width: 15,),
                        Flexible(
                          child: Container(
                            height: 55,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(latestWorkoutJson[index]['title'],style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:FontWeight.bold
                                ),),
                                Text(latestWorkoutJson[index]['description'],style: TextStyle(
                                  fontSize: 13,
                                  color: black.withOpacity(0.5)
                                ),),
                                Stack(
                                  children:[
                                    Container(
                                      width: size.width,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: bgTextField
                                      ),
                                    ),
                                    Container(
                                      width: size.width*(latestWorkoutJson[index]['progressBar']),
                                      height: 10,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        gradient: LinearGradient(colors: [
                                          primary, secondary
                                        ])
                                      ),
                                    )
                                  ]
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 15,),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primary
                            )
                          ),
                          child: Center(
                            child: Icon(Icons.arrow_forward_ios,size:11,color:primary),
                          ),
                        ),

                      ],
                    ),
                ),
              ),
                  );
                }),
              )
            ],
          ),
        ),
      ),
    );
  }
  // Widget _buildSensorChartSection(Size size) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.only(bottom: 15),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text("Sensor Charts",
  //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //             Row(
  //               children: [
  //                 _buildChartLegend("X", Colors.red),
  //                 SizedBox(width: 12),
  //                 _buildChartLegend("Y", Colors.green),
  //                 SizedBox(width: 12),
  //                 _buildChartLegend("Z", Colors.blue),
  //               ],
  //             )
  //           ],
  //         ),
  //       ),
  //       SensorChartCard(
  //         title: "Acceleration",
  //         dataX: _accX,
  //         dataY: _accY,
  //         dataZ: _accZ,
  //         minY: -15,
  //         maxY: 15,
  //         latestTime: _latestElapsedTime,
  //       ),
  //     ],
  //   );
  // }
  // // 新增图例组件 ========
  // Widget _buildChartLegend(String text, Color color) {
  //   return Row(
  //     children: [
  //       Container(
  //         width: 12,
  //         height: 12,
  //         decoration: BoxDecoration(
  //           color: color,
  //           borderRadius: BorderRadius.circular(3),
  //         ),
  //       ),
  //       SizedBox(width: 4),
  //       Text(  // 修正点：位置参数在前，命名参数在后
  //         text,  // 位置参数
  //         style: TextStyle(  // 命名参数
  //           fontSize: 12,
  //           color: Colors.grey.shade600,
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
