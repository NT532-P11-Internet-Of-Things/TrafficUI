import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:traffic/traffic_light.dart';
import 'firebase_options.dart';
import 'traffic_chart.dart';

void main() async {
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

class _TrafficSimulationScreenState extends State<TrafficSimulationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  double _panelWidth = 250.0;
  bool _isPanelVisible = true;
  final double _minPanelWidth = 150.0;
  bool isAuto = true;

  Color primary100 = Color.fromARGB(255, 247,244,234);
  Color primary700 = Color.fromARGB(255, 77,77,55);

  @override
  void initState() {
    super.initState();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 0),
                width: _isPanelVisible ? _panelWidth + 20 : 0,
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
                          width: _panelWidth,
                          color: primary100,
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              const SizedBox(height: 50),
                              Text(
                                'Bảng điều khiển',
                                style: TextStyle(
                                  color: primary700,
                                  fontSize: 24,
                                ),
                              ),
                              ListView(
                                shrinkWrap: true,
                                children: [
                                  _panelWidth < 700
                                      ? Column(
                                    children: [
                                      const SizedBox(
                                          width: 400,
                                          child: TrafficLineChart()
                                      ),
                                      SizedBox(
                                          width: 300,
                                          child: buildControlPanel()
                                      ),
                                    ],
                                  )
                                      : Row(
                                    children: [
                                      const SizedBox(
                                          width: 400,
                                          child: TrafficLineChart()
                                      ),
                                      SizedBox(
                                          width: 300,
                                          child: buildControlPanel()
                                      ),
                                    ],
                                  )
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
                    TrafficLightSystem(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                  onPressed: () {
                    _toggleDrawer();
                  },
                  icon: Icon(Icons.menu, color: Color.fromARGB(255, 77,77,55), size: 30)
              )
          ),
        ],
      ),
    );
  }

  Widget buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [

          TextField(
            decoration: InputDecoration(
              labelText: "Đèn 1 và 3",
              suffixIcon: IconButton(
                icon: Icon(Icons.check),
                onPressed: () {

                },
              ),
            ),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: "Đèn 2 và 4",
              suffixIcon: IconButton(
                icon: Icon(Icons.check),
                onPressed: () {

                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tự động"),
              Switch(
                  value: isAuto,
                  onChanged: (value) {
                    setState(() {
                      // setAuto(value);
                    });
                  }),
            ],
          ),
          ],
      ),
    );
  }
}