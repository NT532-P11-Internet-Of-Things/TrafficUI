import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(TrafficSimulationApp());

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

class _TrafficSimulationScreenState extends State<TrafficSimulationScreen> {
  int redTimer1 = 10;
  int yellowTimer1 = 3;
  int greenTimer1 = 10;

  TextEditingController controller = TextEditingController();
  int redTimer2 = 13;
  int yellowTimer2 = 3;
  int greenTimer2 = 7;

  late int currentTimer1;
  late int currentIndex1;
  late List<int> timers1;
  bool timerUpdated1 = false;

  late int currentTimer2;
  late int currentIndex2;
  late List<int> timers2;
  bool timerUpdated2 = false;

  @override
  void initState() {
    super.initState();
    currentIndex1 = 2; // Set initial index to green
    timers1 = [greenTimer1, yellowTimer1, redTimer1];
    currentTimer1 = timers1[currentIndex1];
    startTimer1();

    currentIndex2 = 0; // Set initial index to red
    timers2 = [greenTimer2, yellowTimer2, redTimer2];
    currentTimer2 = timers2[currentIndex2];
    startTimer2();
  }

  void startTimer1() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        currentTimer1--;
        if (currentTimer1 <= 0) {
          if (timerUpdated1) {
            timers1 = [greenTimer1, yellowTimer1, redTimer1];
            timerUpdated1 = false;
          }
          currentIndex1 = (currentIndex1 + 1) % 3;
          currentTimer1 = timers1[currentIndex1];
        }
      });
      startTimer1();
    });
  }

  void startTimer2() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        currentTimer2--;
        if (currentTimer2 <= 0) {
          if (timerUpdated2) {
            timers2 = [greenTimer2, yellowTimer2, redTimer2];
            timerUpdated2 = false;
          }
          currentIndex2 = (currentIndex2 + 1) % 3;
          currentTimer2 = timers2[currentIndex2];
        }
      });
      startTimer2();
    });
  }

  // void setTimer1(int red1, int yellow1, int green1) {
  //   setState(() {
  //     redTimer1 = red1;
  //     yellowTimer1 = yellow1;
  //     greenTimer1 = green1;
  //     timerUpdated1 = true;
  //   });
  // }
  //
  // void setTimer2(int red2, int yellow2, int green2) {
  //   setState(() {
  //     redTimer2 = red2;
  //     yellowTimer2 = yellow2;
  //     greenTimer2 = green2;
  //     timerUpdated2 = true;
  //   });
  // }

  void setTimer(int red1, int green1) {
    setState(() {
      redTimer1 = red1;
      greenTimer1 = green1;
      redTimer2 = greenTimer1 + 3;
      greenTimer2 = redTimer1 - 3;
      timerUpdated1 = true;
      timerUpdated2 = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg', // Đặt hình nền đã tải ở thư mục assets
              fit: BoxFit.cover,
            ),
          ),
          // Đèn giao thông 1
          Positioned(
            top: 50,
            left: 270,
            child: Column(
              children: [
                Text("Đèn 1", style: TextStyle(color: Colors.white),),
                buildTrafficLight(currentTimer1, currentIndex1),
                Text("Đèn đỏ: $redTimer1 s, Đèn xanh: $greenTimer1 s", style: TextStyle(color: Colors.white),),
              ],
            ),
          ),
          // Đèn giao thông 2
          Positioned(
            top: 50,
            right: 270,
            child: Column(
              children: [
                Text("Đèn 2", style: TextStyle(color: Colors.white),),
                buildTrafficLight(currentTimer2, currentIndex2),
                Text("Đèn đỏ: $redTimer2 s, Đèn xanh: $greenTimer2 s", style: TextStyle(color: Colors.white),),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            right: 270,
            child: Column(
              children: [
                Text("Đèn 3", style: TextStyle(color: Colors.white),),
                buildTrafficLight(currentTimer1, currentIndex1),
                Text("Đèn đỏ: $redTimer1 s, Đèn xanh: $greenTimer1 s", style: TextStyle(color: Colors.white),),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 270,
            child: Column(
              children: [
                Text("Đèn 4", style: TextStyle(color: Colors.white),),
                buildTrafficLight(currentTimer2, currentIndex2),
                Text("Đèn đỏ: $redTimer2 s, Đèn xanh: $greenTimer2 s", style: TextStyle(color: Colors.white),),
              ],
            ),
          ),

          Positioned(
            top: 50,
            left: 200,
            child: SizedBox(
              width: 300,
              height: 50,
              child: TextField(
              decoration: InputDecoration(
                labelText: "Nhập thời gian đèn đỏ và xanh",
                hintText: "Ví dụ: 10 20",
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    List<String> values = (controller.text).split(" ");
                    setTimer(int.parse(values[0]), int.parse(values[1]));
                  },
                ),
              ),
              controller: controller,
                        ),
            ),
          ),
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
              child: Center(child: Text('$currentTimer', style: TextStyle(fontSize: 30, color: Colors.white),))),
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
}