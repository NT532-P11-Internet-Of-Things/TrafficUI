import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'green_light_chart.dart';
import 'traffic_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: "assets/.env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(TrafficSimulationApp());
}

class TrafficSimulationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mô phỏng giao thông',
      home: TrafficSimulationScreen(),
    );
  }
}

class TrafficSimulationScreen extends StatefulWidget {
  @override
  _TrafficSimulationScreenState createState() => _TrafficSimulationScreenState();
}

class _TrafficSimulationScreenState extends State<TrafficSimulationScreen> with SingleTickerProviderStateMixin{
  late DatabaseReference greenTime1Ref;
  late DatabaseReference greenTime2Ref;
  late DatabaseReference greenTime3Ref;
  late DatabaseReference greenTime4Ref;
  late DatabaseReference lane1Ref;
  late DatabaseReference lane2Ref;
  late DatabaseReference lane3Ref;
  late DatabaseReference lane4Ref;
  late DatabaseReference autoRef;
  late DatabaseReference remainingTime1Ref;
  late DatabaseReference remainingTime2Ref;
  late DatabaseReference remainingTime3Ref;
  late DatabaseReference remainingTime4Ref;


  late DatabaseReference isGreen1Ref;
  late DatabaseReference isGreen2Ref;
  late DatabaseReference isGreen3Ref;
  late DatabaseReference isGreen4Ref;
  late DatabaseReference needSyncRef;

  late DatabaseReference light1Color;
  late DatabaseReference light2Color;

  late DatabaseReference syncWithRealDeviceRef;
  late DatabaseReference syncWithFirebaseRemainingTimeRef;

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  double _panelWidth = 300.0;
  bool _isPanelVisible = true;
  final double _minPanelWidth = 150.0;

  int redTimer1 = 10;
  int yellowTimer1 = 3;
  int greenTimer1 = 10;
  int greenChangeCounter = 0;

  TextEditingController controller = TextEditingController();
  TextEditingController controller2 = TextEditingController();
  TextEditingController controller3 = TextEditingController();
  int redTimer2 = 13;
  int yellowTimer2 = 3;
  int greenTimer2 = 7;

  bool isAuto = true;
  bool isShowAll = true;
  bool isShowInfo = true;
  bool isShowTrafficLightLine = true;
  bool isShowLaneCount = true;
  bool syncWithRealDevice = false;
  bool syncWithFirebaseRemainingTimeToggleValue = true;
  bool syncWithFirebaseRemainingTimeVariableInFirebase = true;
  String syncWithFirebaseRemainingTimeText = "Đồng bộ với thời gian còn lại";

  Offset controlPanelPosition = const Offset(10, 10);
  late int currentTimer1; // 0 - Green, 1 - Yellow, 2 - Red
  late int currentIndex1;
  late List<int> timers1;
  bool timerUpdated1 = false;

  late int currentTimer2;
  late int currentIndex2;
  late List<int> timers2;
  bool timerUpdated2 = false;

  int lane1 = 0;
  int lane2 = 0;
  int lane3 = 0;
  int lane4 = 0;

  bool isGreen1 = false;
  // bool isGreen2 = false;

  late List<double> laneData = [0, 0, 0, 0];
  Color primary100 = Color.fromARGB(255, 247,244,234);
  Color primary700 = Color.fromARGB(255, 77,77,55);

  @override
  void initState() {
    super.initState();
    initializeRefs();
    currentIndex1 = 2; // Set initial index to red
    timers1 = [greenTimer1, yellowTimer1, redTimer1];
    currentTimer1 = timers1[currentIndex1];


    currentIndex2 = 0; // Set initial index to green
    timers2 = [greenTimer2, yellowTimer2, redTimer2];
    currentTimer2 = timers2[currentIndex2];

    syncWithFirebaseRemainingTimeRef.set(true);

    startTimers();

    fetchTrafficLight();
    listenToIsGreenRef();

    remainingTime1Ref.get().then((value) async => {
      if (value.value != null) {
        isGreen1 = await isGreen1Ref.get().then((value) => value.value as bool),
        updateState(isGreen1 == true ? 0 : 2,isGreen1 == true ? value.value as int : (value.value as int) - 3)
      }
    });



    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(_controller);
  }

  void _toggleDrawer() {
    if (_controller.isDismissed) {
      _controller.forward();
      _isPanelVisible = true;
    } else {
      _controller.reverse();
      _isPanelVisible = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  void initializeRefs() {
    const basePath = "traffic_system/intersections/main_intersection";
    greenTime1Ref = FirebaseDatabase.instance.ref("$basePath/lanes/1/green_time");
    greenTime2Ref = FirebaseDatabase.instance.ref("$basePath/lanes/2/green_time");
    greenTime3Ref = FirebaseDatabase.instance.ref("$basePath/lanes/3/green_time");
    greenTime4Ref = FirebaseDatabase.instance.ref("$basePath/lanes/4/green_time");

    lane1Ref = FirebaseDatabase.instance.ref("$basePath/lanes/1/vehicle_count");
    lane2Ref = FirebaseDatabase.instance.ref("$basePath/lanes/2/vehicle_count");
    lane3Ref = FirebaseDatabase.instance.ref("$basePath/lanes/3/vehicle_count");
    lane4Ref = FirebaseDatabase.instance.ref("$basePath/lanes/4/vehicle_count");

    autoRef = FirebaseDatabase.instance.ref("$basePath/isAuto");
    remainingTime1Ref = FirebaseDatabase.instance.ref("$basePath/lanes/1/remaining_time");
    remainingTime2Ref = FirebaseDatabase.instance.ref("$basePath/lanes/2/remaining_time");
    remainingTime3Ref = FirebaseDatabase.instance.ref("$basePath/lanes/3/remaining_time");
    remainingTime4Ref = FirebaseDatabase.instance.ref("$basePath/lanes/4/remaining_time");
    isGreen1Ref = FirebaseDatabase.instance.ref("$basePath/lanes/1/is_green");
    isGreen2Ref = FirebaseDatabase.instance.ref("$basePath/lanes/2/is_green");
    isGreen3Ref = FirebaseDatabase.instance.ref("$basePath/lanes/3/is_green");
    isGreen4Ref = FirebaseDatabase.instance.ref("$basePath/lanes/4/is_green");
    needSyncRef = FirebaseDatabase.instance.ref("$basePath/needSync");

    light1Color = FirebaseDatabase.instance.ref("$basePath/color/1/light_color");
    light2Color = FirebaseDatabase.instance.ref("$basePath/color/2/light_color");

    syncWithRealDeviceRef = FirebaseDatabase.instance.ref("$basePath/syncWithRealDevice");
    syncWithFirebaseRemainingTimeRef = FirebaseDatabase.instance.ref("$basePath/syncWithFirebaseRemainingTime");

  }

  void listenToIsGreenRef() {
  //   greenTime1Ref.onValue.listen((DatabaseEvent event) {
  //     if (isGreen1) {
  //       print("Set timer 1 green");
  //       setTimer1Green(greenTimer1);
  //     }
  //     else
  //     {
  //       print("Not Set timer 1 green");
  //     }
  //   });
  //   greenTime2Ref.onValue.listen((DatabaseEvent event) {
  //     if (isGreen2) {
  //       print("Set timer 2 green");
  //       setTimer2Green(greenTimer2);
  //     }
  //     else
  //     {
  //       print("Not Set timer 2 green");
  //     }
  //   });

    isGreen1Ref.onValue.listen((DatabaseEvent event) async {
      bool temp = event.snapshot.value as bool;
      print("wait");
      await Future.delayed(const Duration(seconds: 2));
      print("wait done ");
      int greenTimer = await greenTime1Ref.get().then((value) => value.value as int);
      if (temp == true) {
        setTimer1Green(greenTimer);
      } else {
        setTimer2Green(greenTimer);
      }
    });

    // isGreen2Ref.onValue.listen((DatabaseEvent event) async {
    //   isGreen2 = event.snapshot.value as bool;
    //   if (isGreen2 == true)
    //     greenTimer2 = await greenTime2Ref.get().then((value) => value.value as int);
    // });

    // isGreen1Ref.onValue.listen((DatabaseEvent event) async {
    //   if (!isAuto) {
    //     return;
    //   }
    //   bool isGreen = event.snapshot.value as bool;
    //   int remainingTime = await remainingTime1Ref.get().then((value) => value.value as int);
    //   if (isGreen) {
    //     // greenChangeCounter++;
    //     // if (greenChangeCounter >= 3) {
    //     //   updateState(0, remainingTime);
    //     //   greenChangeCounter = 0;
    //     // }
    //     setTimer1Green(greenTimer1);
    //   }
    // });

    // isGreen2Ref.onValue.listen((DatabaseEvent event) async {
    //   if (!isAuto) {
    //     return;
    //   }
    //   bool isGreen = event.snapshot.value as bool;
    //   int remainingTime = await remainingTime2Ref.get().then((value) => value.value as int);
    //   if (isGreen) {
    //     // greenChangeCounter++;
    //     // if (greenChangeCounter >= 3) {
    //     //   updateState(0, remainingTime);
    //     //   greenChangeCounter = 0;
    //     // }
    //     print("Set timer 2 green");
    //     setTimer2Green(greenTimer2);
    //   }
    //   else
    //   {
    //     print("Not Set timer 2 red");
    //   }
    // });

    needSyncRef.onValue.listen((DatabaseEvent event) async {
      bool needSync = event.snapshot.value as bool;
      if (needSync) {
        if (currentIndex1 == 0) {
          updateState(1, 4);
        }
        else {
          updateState(2, 4);
        }
        // bool isGreen = await isGreen1Ref.get().then((value) => value.value as bool);
        // int remainingTime = await remainingTime1Ref.get().then((value) => value.value as int);
        // updateState(isGreen ? 1 : 2, isGreen? 3 : remainingTime);
        needSyncRef.set(false);
      }
    });

    remainingTime1Ref.onValue.listen((DatabaseEvent event) async {
      if (!syncWithFirebaseRemainingTimeToggleValue) {
        return;
      }
      int remainingTime = event.snapshot.value as int;
      bool isGreen = await isGreen1Ref.get().then((value) => value.value as bool);

      if (isGreen) {
        updateState(0, remainingTime);
        syncWithFirebaseRemainingTimeToggleValue = false;
        syncWithFirebaseRemainingTimeText = "Đồng bộ xong";
        setState(() {});
        Timer(const Duration(seconds: 3), () {
          syncWithFirebaseRemainingTimeText = "Đồng bộ với thời gian còn lại";
          setState(() {});
          syncWithFirebaseRemainingTimeRef.set(false);
        });
      }
      else {
        syncWithFirebaseRemainingTimeText = "Đang đồng bộ";
        setState(() {});
      }

    });

    syncWithFirebaseRemainingTimeRef.onValue.listen((DatabaseEvent event) {
      syncWithFirebaseRemainingTimeVariableInFirebase = event.snapshot.value as bool;
      if (syncWithFirebaseRemainingTimeVariableInFirebase && !syncWithFirebaseRemainingTimeToggleValue) {
        setState(() {
          syncWithFirebaseRemainingTimeToggleValue = true;
          print("Set syncWithFirebaseRemainingTimeToggleValue to true");
        });
      }
    });
  }


  void startTimers() {
    Future.wait([
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          currentTimer1--;
          if (currentTimer1 < 0) {
            if (timerUpdated1) {
              timers1 = [greenTimer1, yellowTimer1, redTimer1];
              timerUpdated1 = false;
            }
            int tempCurrentIndex = currentIndex1;
            currentIndex1 = (currentIndex1 + 1) % 3;
            currentTimer1 = timers1[currentIndex1];
            if (tempCurrentIndex != currentIndex1) {
              setFirebaseColor();
            }
          }
        });
      }),
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          currentTimer2--;
          if (currentTimer2 < 0) {
            if (timerUpdated2) {
              timers2 = [greenTimer2, yellowTimer2, redTimer2];
              timerUpdated2 = false;
            }
            int tempCurrentIndex2 = currentIndex2;
            currentIndex2 = (currentIndex2 + 1) % 3;
            currentTimer2 = timers2[currentIndex2];
            if (tempCurrentIndex2 != currentIndex2) {
              setFirebaseColor();
            }
          }
        });
      }),
    ]).then((_) {
      // Gọi lại cả hai hàm sau khi hoàn thành vòng lặp hiện tại
      startTimers();
    });
  }


  void setFirebaseColor() {
    if (!syncWithRealDevice) {
      return;
    }
    light1Color.set(indexToText(currentIndex1));
    light2Color.set(indexToText(currentIndex2));
  }

  void nextCycle() {
    setState(() {
      needSyncRef.set(true);
      //
      //   if (currentIndex1 == 0) {
      //     // Green to Yellow
      //     currentIndex1 = 1;
      //     currentTimer1 = yellowTimer1;
      //   } else if (currentIndex1 == 1) {
      //     // Yellow stays Yellow
      //     currentIndex1 = 1;
      //     currentTimer1 = yellowTimer1;
      //   } else if (currentIndex1 == 2) {
      //     // Red to 3 seconds Red
      //     currentIndex1 = 2;
      //     currentTimer1 = 3;
      //   }
      //
      //   if (currentIndex2 == 0) {
      //     // Green to Yellow
      //     currentIndex2 = 1;
      //     currentTimer2 = yellowTimer2;
      //   } else if (currentIndex2 == 1) {
      //     // Yellow stays Yellow
      //     currentIndex2 = 1;
      //     currentTimer2 = yellowTimer2;
      //   } else if (currentIndex2 == 2) {
      //     // Red to 3 seconds Red
      //     currentIndex2 = 2;
      //     currentTimer2 = 3;
      //   }
      // });
      // isGreen1Ref.set(currentIndex1 == 0);
      // isGreen2Ref.set(currentIndex2 == 0);
      // isGreen3Ref.set(currentIndex1 == 0);
      // isGreen4Ref.set(currentIndex2 == 0);
    });
  }

  void updateState(int index, int timer) {
    setState(() {
      // nếu chuyển sang đèn xanh, còn lớn hơn 3 thì đèn kia chuyển sang đỏ, thòi gian còn của đèn kia bằng đèn này cộng thêm 3, còn nếu ít hơn 3s thì đèn kia thành vàng, thòi gian còn lại bằng thời gian của đèn này
      // nếu chuyển sang đỏ, thời gian còn ít hơn 3s thì đèn kia chuyển sang vàng, thời gian còn bằng thời gian đèn này, còn nếu lớn hơn 3s đèn kia chuyển sang xanh, thời gian còn lại bằng thời gian của đèn này - 3
      if (index == 0) { // Đèn xanh
        currentIndex1 = index;
        currentIndex2 = 2; // Đèn đỏ
        currentTimer2 = timer + 4;
      } else if (index == 1) { // Đèn vàng
        currentIndex1 = index;
        currentIndex2 = 2; // Đèn đỏ
        currentTimer1 = timer;
        currentTimer2 = timer;
      } else { // Đèn đỏ
        currentIndex1 = index;
        if (timer > 3) {
          currentIndex2 = 0; // Đèn xanh
          currentTimer2 = timer - 4;
        } else {
          currentIndex2 = 1; // Đèn vàng
          currentTimer2 = timer;
        }
      }
      currentTimer1 = timer;
      setFirebaseColor();
    });
  }

  String indexToText(int index) {
    if (index == 0) {
      return "Green";
    } else if (index == 1) {
      return "Yellow";
    } else {
      return "Red";
    }
  }


  void setTimer1(int green1, int red1) {
    setState(() {
      redTimer1 = red1;
      greenTimer1 = green1;
      redTimer2 = greenTimer1 + 4;
      greenTimer2 = redTimer1 - 4;
      timerUpdated1 = true;
      timerUpdated2 = true;
    });
  }

  void setTimer2(int green2, int red2) {
    setState(() {
      redTimer2 = red2;
      greenTimer2 = green2;
      redTimer1 = greenTimer2 + 4;
      greenTimer1 = redTimer2 - 4;
      timerUpdated2 = true;
      timerUpdated1 = true;
    });
  }

  void setTimer1Green(int green1) {
    print("Set timer 1 green");
    setState(() {
      greenTimer1 = green1;
      redTimer2 = greenTimer1 + 4;
      timerUpdated1 = true;
      timerUpdated2 = true;
    });
  }

  void setTimer2Green(int green2) {
    setState(() {
      print("Set timer 2 green");
      greenTimer2 = green2;
      redTimer1 = greenTimer2 + 4;
      timerUpdated2 = true;
      timerUpdated1 = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 0), // Duration for smooth animation
                width: _isPanelVisible ? _panelWidth + 20 : 0, //
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        if (!_isPanelVisible) {
                          _controller.forward();
                          _isPanelVisible = true;
                        } else {
                          _panelWidth += details.primaryDelta!;
                          if (_panelWidth < _minPanelWidth) {
                            _panelWidth = _minPanelWidth;
                            _controller.reverse();
                            _isPanelVisible = false;
                          } else if (_panelWidth > MediaQuery.of(context).size.width) {
                            _panelWidth = MediaQuery.of(context).size.width;
                          }
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 10, left: 10
                          ),
                          width: _panelWidth,
                          color: primary100,
                          child: ListView(
                            padding: EdgeInsets.all(10),
                            children: [
                              const SizedBox(height: 50),
                              Text(
                                'Bảng điều khiển',
                                style: TextStyle(
                                  color: primary700,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                             const SizedBox(height: 20),
                             ListView(
                                shrinkWrap: true,
                                children: [
                                  _panelWidth < 700 ?
                                      Column(
                                        children: [
                                          const SizedBox(
                                              width: 400,
                                              child: TrafficLineChart()),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                              width: 400,
                                              child: GreenTimerChart(greenTimer1: greenTimer1.toDouble(), greenTimer2: greenTimer2.toDouble())),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                              width: 400,
                                              child: buildControlPanel()
                                          )
                                        ],
                                      )
                                      : Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const SizedBox(
                                                width: 400,
                                                child: TrafficLineChart()),
                                            const SizedBox(height: 20),
                                            SizedBox(
                                                width: 400,
                                                child: GreenTimerChart(greenTimer1: greenTimer1.toDouble(), greenTimer2: greenTimer2.toDouble())),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: buildControlPanel(),
                                      )
                                    ],)
                                ],
                             )

                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleDrawer,
                          child: Container(
                            width: 20,
                            height: double.infinity,
                            color: primary100,
                            child: Center(
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: primary700,
                                  size: 15
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Background
                    Positioned.fill(
                      child: Image.asset(
                        'assets/background3.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),

                    Center(
                      child: Visibility(
                        visible: isShowTrafficLightLine,
                        child: Stack(
                          children: [
                            // Các widget khác trong Stack
                            Visibility(
                              visible: isShowTrafficLightLine,
                              child: Center( // Giữ widget ở giữa màn hình
                                child: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: Stack(
                                    children: [
                                      // Thanh trên
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Container(
                                          width: 120,
                                          height: 20,
                                          color: currentIndex1 == 0 ? Colors.green : currentIndex1 == 1 ? Colors.yellow : Colors.red,
                                        ),
                                      ),
                                      // Thanh dưới
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          width: 120,
                                          height: 20,
                                          color: currentIndex1 == 0 ? Colors.green : currentIndex1 == 1 ? Colors.yellow : Colors.red,
                                        ),
                                      ),
                                      // Thanh trái
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          width: 20,
                                          height: 120,
                                          color: currentIndex2 == 0 ? Colors.green : currentIndex2 == 1 ? Colors.yellow : Colors.red,
                                        ),
                                      ),
                                      // Thanh phải
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          width: 20,
                                          height: 120,
                                          color: currentIndex2 == 0 ? Colors.green : currentIndex2 == 1 ? Colors.yellow : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          buildLane(1, lane1),
                          const SizedBox(height: 200),
                          buildLane(3, lane3),
                        ],
                      ),
                    ),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          buildLane(4, lane4),
                          const SizedBox(width: 200),
                          buildLane(2, lane2),
                        ],
                      ),
                    ),

                    // Đèn giao thông 1
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    "Đèn 1",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  buildTrafficLight(currentTimer1, currentIndex1),
                                  Visibility(visible: isShowInfo, child: buildTimer(true, isShowAll)),
                                ],
                              ),
                              // Center(
                              //     child: Container(
                              //       decoration: BoxDecoration(
                              //         color: Colors.white,
                              //         borderRadius: BorderRadius.circular(10),
                              //       ),
                              //       child: Column(
                              //         children: [
                              //           const Text(
                              //             "Làn 1:",
                              //             style: TextStyle(color: Colors.white),
                              //           ),
                              //           Text("Số xe: $lane1", style: TextStyle(color: Colors.black)),
                              //         ],
                              //       ),
                              //     )),
                              // Đèn giao thông 2
                              Column(
                                children: [
                                  const Text(
                                    "Đèn 2",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  buildTrafficLight(currentTimer2, currentIndex2),
                                  Visibility(visible: isShowInfo, child: buildTimer(false, isShowAll)),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    "Đèn 4",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  buildTrafficLight(currentTimer2, currentIndex2),
                                  Visibility(visible: isShowInfo, child: buildTimer(false, isShowAll)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    "Đèn 3",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  buildTrafficLight(currentTimer1, currentIndex1),
                                  Visibility(visible: isShowInfo, child: buildTimer(true, isShowAll)),
                                ],
                              ),

                            ],
                          ),
                        ],
                      ),
                    ),

                    // Thanh đèn giao thông


                  ],
                ),
              ),
            ],
          ),
          Positioned(top: 10, left: 10, child:
          IconButton(onPressed: () {
            _toggleDrawer();
          }, icon: Icon(Icons.menu, color: Color.fromARGB(255, 77,77,55), size: 30))),
        ],
      ),
    );
  }

  Widget buildTrafficLight(int currentTimer, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          buildLight("Red", Colors.red, currentIndex == 2),
          buildLight("Yellow", Colors.yellow, currentIndex == 1),
          buildLight("Green", Colors.green, currentIndex == 0),
          SizedBox(
              height: 50,
              width: 70,
              child: Center(
                  child: Text(
                '$currentTimer',
                style: const TextStyle(fontSize: 30, color: Colors.white),
              ))),
        ],
      ),
    );
  }

  Widget buildLight(String label, Color color, bool isActive) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  void fetchTrafficLight() {
    // greenTime1Ref.onValue.listen((DatabaseEvent event) async {
    //   int newTimer1 = event.snapshot.value as int;
    //   DataSnapshot snapshot2 = await greenTime2Ref.get();
    //   int newTimer2 = snapshot2.value as int;
    //   setTimer1(newTimer1, newTimer2);
    // });
    //
    // greenTime2Ref.onValue.listen((DatabaseEvent event) async {
    //   int newTimer2 = event.snapshot.value as int;
    //   DataSnapshot snapshot1 = await greenTime1Ref.get();
    //   int newTimer1 = snapshot1.value as int;
    //   setTimer2(newTimer2, newTimer1);
    // });
    setTimer1Green(10);
    setTimer2Green(10);

    lane1Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane1 = event.snapshot.value as int;
        laneData[0] = lane1.toDouble();
      });
    });

    lane2Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane2 = event.snapshot.value as int;
        laneData[1] = lane2.toDouble();
      });
    });

    lane3Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane3 = event.snapshot.value as int;
        laneData[2] = lane3.toDouble();
      });
    });

    lane4Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane4 = event.snapshot.value as int;
        laneData[3] = lane4.toDouble();
      });
    });

    autoRef.onValue.listen((DatabaseEvent event) {

        bool tempIsAuto = event.snapshot.value as bool;
        if (tempIsAuto != isAuto) {
          setState(() {
            isAuto = tempIsAuto;
          });
        }
    });
  }

  Widget buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Thông số', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hiện thông tin đèn"),
              Switch(
                  activeTrackColor: primary700,
                  inactiveTrackColor: primary100,
                  value: isShowInfo,
                  onChanged: (value) {
                    setState(() {
                      isShowInfo = value;
                    });
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hiện tất cả thông tin đèn"),
              Switch(
                  activeTrackColor: primary700,
                  inactiveTrackColor: primary100,
                  value: isShowAll,
                  onChanged: (value) {
                    setState(() {
                      isShowAll = value;
                    });
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hiện thanh đèn"),
              Switch(
                  activeTrackColor: primary700,
                  inactiveTrackColor: primary100,
                  value: isShowTrafficLightLine,
                  onChanged: (value) {
                    setState(() {
                      isShowTrafficLightLine = value;
                    });
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hiện số xe"),
              Switch(
                  activeTrackColor: primary700,
                  inactiveTrackColor: primary100,
                  value: isShowLaneCount,
                  onChanged: (value) {
                    setState(() {
                      isShowLaneCount = value;
                    });
                  }),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Điều khiển', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tự động"),
              Switch(
                  activeTrackColor: primary700,
                  inactiveTrackColor: primary100,
                  value: isAuto,
                  onChanged: (value) {
                    setState(() {
                      setAuto(value);
                    });
                  }),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Đồng bộ với thiết bị thực"),
              Switch(
                  activeTrackColor: primary700,
                  inactiveTrackColor: primary100,
                  value: syncWithRealDevice,
                  onChanged: (value) {
                    setState(() {
                      syncWithRealDevice = value;
                      syncWithRealDeviceRef.set(value);
                    });
                  }),
            ],
          ),
          const SizedBox(height: 10),
          // Animated opacity
          AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: syncWithRealDevice ? 1 : 0.5,
            child: AbsorbPointer(
              absorbing: !syncWithRealDevice,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Visibility(
                    visible: !syncWithRealDevice,
                    child: Text("Đồng bộ với thiết bị để sử dụng chức năng này", style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 10),
                  (currentIndex1 != 1 && currentIndex2 != 1) ?
                  FilledButton(
                      onPressed: () {
                        nextCycle();
                        // fetchTrafficLight();
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(primary700),
                      ),
                      child: const Text("Chuyển đèn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'))
                  )
                      :
                  TextButton(
                      onPressed: () {
                        // fetchTrafficLight();
                      },
                      child: const Text("Chuyển đèn", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'))
                  ),
                  const SizedBox(height: 10),
                  const Text('Cập nhật thời gian đèn xanh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                  TextFieldCustom(
                      labelText: "Đèn 1 và 3",
                      controller: controller,
                      onPressed: () async {
                        // greenTime1Ref.set(int.parse(controller.text));
                        // greenTime3Ref.set(int.parse(controller.text));
                        setTimer1Green(int.parse(controller.text));
                        greenTime1Ref.set(int.parse(controller.text));
                        greenTime3Ref.set(int.parse(controller.text));
                        // bool temp = (await isGreen1Ref.get()).value as bool;
                        // await isGreen1Ref.set(!temp);
                        // await isGreen1Ref.set(temp);


                        setAuto(false);
                      },
                  ),
                  TextFieldCustom(
                      labelText: "Đèn 2 và 4",
                    controller: controller2,
                        onPressed: () async {
                          // greenTime4Ref.set(int.parse(controller2.text));
                          // greenTime2Ref.set(int.parse(controller2.text));
                          setTimer2Green(int.parse(controller2.text));
                          greenTime4Ref.set(int.parse(controller2.text));
                          greenTime2Ref.set(int.parse(controller2.text));
                          // bool temp = (await isGreen1Ref.get()).value as bool;
                          // await isGreen1Ref.set(!temp);
                          // await isGreen1Ref.set(temp);
                          setAuto(false);
                        },
                      ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),




          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text(syncWithFirebaseRemainingTimeText),
          //     Switch(
          //         activeTrackColor: primary700,
          //         inactiveTrackColor: primary100,
          //         value: syncWithFirebaseRemainingTimeToggleValue,
          //         onChanged: (value) {
          //           setState(() {
          //             syncWithFirebaseRemainingTimeToggleValue = value;
          //           });
          //         }),
          //   ],
          // ),

        ],
      ),
    );
  }

  Widget buildTimer(bool isOdd, bool isShowAll) {
    int redTimer;
    int greenTimer;
    String text;
    if (isOdd)
    {
      redTimer = redTimer1;
      greenTimer = greenTimer1;
      if (currentIndex1 == 0)
      {
        text = "Đèn xanh: $greenTimer1 s";
      }
      else if (currentIndex1 == 1)
      {
        text = "Đèn vàng: $yellowTimer1 s";
      }
      else
      {
        text = "Đèn đỏ: $redTimer1 s";
      }
    }
    else
    {
      redTimer = redTimer2;
      greenTimer = greenTimer2;
      if (currentIndex2 == 0)
      {
        text = "Đèn xanh: $greenTimer2 s";
      }
      else if (currentIndex2 == 1)
      {
        text = "Đèn vàng: $yellowTimer2 s";
      }
      else
      {
        text = "Đèn đỏ: $redTimer2 s";
      }
    }

    if (isShowAll) {
        if (isOdd){
          text = "Đèn xanh: ${greenTimer1}s | Đèn đỏ: ${redTimer1}s";
        }
        else {
          text = "Đèn xanh: ${greenTimer2}s | Đèn đỏ: ${redTimer2}s";
        }
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(color: Colors.black)),
    );
  }

  Widget buildLane(int lane, int count) {
    return Visibility(
      visible: isShowLaneCount,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text("Làn $lane:\nSố xe: $count", style: TextStyle(color: Colors.black)),
      ),
    );
  }

  void setAuto(bool value) {
    isAuto = value;
    autoRef.set(value);
  }
}

class TextFieldCustom extends StatelessWidget {
  const TextFieldCustom({super.key, required this.labelText, required this.controller, required this.onPressed});

  final String labelText;
  final TextEditingController controller;
  final Future<Null> Function() onPressed;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Color.fromARGB(255, 247,244,234)),
            ),
            onPressed: onPressed,
            child: const Text("Cập nhật", style: TextStyle(color: Color.fromARGB(255, 77,77,55), fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
          ),
        ],
      ),
    );
  }
}




