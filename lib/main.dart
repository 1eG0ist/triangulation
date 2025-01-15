import 'package:flutter/material.dart';
import 'package:triangulation/models/user_model.dart';
import 'package:triangulation/utils/lines_painter.dart';
import 'dart:math';
import 'dart:ui';

import 'components/tower_widget.dart';
import 'components/user_widget.dart';
import 'models/tower_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TriangulationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TriangulationScreen extends StatefulWidget {
  @override
  _TriangulationScreenState createState() => _TriangulationScreenState();
}

class _TriangulationScreenState extends State<TriangulationScreen> {
  List<TowerModel> towers = [];
  UserWidget? user;
  bool isFreeMode = false;

  final TextEditingController towerXController = TextEditingController();
  final TextEditingController towerYController = TextEditingController();
  final TextEditingController signalPowerController = TextEditingController();
  final TextEditingController distanceToUserController = TextEditingController();
  final TextEditingController radiusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome! Add towers to begin triangulation.')),
      );
    });
  }

  void _addTower() {
    try {
      final double x = double.parse(towerXController.text);
      final double y = double.parse(towerYController.text);
      final double power = double.parse(signalPowerController.text);
      final double distance = double.parse(distanceToUserController.text);
      final double radius = double.parse(radiusController.text);

      setState(() {
        towers.add(
          TowerModel(
            position: Offset(x, y),
            signalPower: power,
            distanceToUser: distance,
            radius: radius
          )
        );
        towerXController.clear();
        towerYController.clear();
        signalPowerController.clear();
        distanceToUserController.clear();
        radiusController.clear();
      });

      if (towers.length >= 3) {
        if (_isTriangulationPossible()) {
          user = triangulateUserPosition(towers[0].position, towers[1].position, towers[2].position,
              towers[0].distanceToUser, towers[1].distanceToUser, towers[2].distanceToUser);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Triangulation not possible with given distances')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid input! Please enter valid numbers.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Triangulation Example'),
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Input Coordinates'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            if (towers.length >= 3)
              Column(
                children: [
                  Text('User Position'),
                  Text('X: ${user?.data.coords.dx ?? 'N/A'}'),
                  Text('Y: ${user?.data.coords.dy ?? 'N/A'}'),
                ],
              ),
            ListTile(
              title: Text('Create Tower'),
              subtitle: Column(
                children: [
                  TextField(
                    controller: towerXController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'X'),
                  ),
                  TextField(
                    controller: towerYController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Y'),
                  ),
                  TextField(
                    controller: signalPowerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Signal Power'),
                  ),
                  TextField(
                    controller: radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Radius'),
                  ),
                  TextField(
                    controller: distanceToUserController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Distance to User'),
                  ),
                  ElevatedButton(
                    onPressed: _addTower,
                    child: const Text('Add Tower'),
                  ),
                ],
              ),
            ),
            ...towers.map((tower) => ListTile(
              title: Text('Tower at (${tower.position.dx}, ${tower.position.dy})'),
              subtitle: Text('Signal Power: ${tower.signalPower}, Distance to User: ${tower.distanceToUser}'),
            )).toList(),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.5),
                    Colors.purple.withOpacity(0.5),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
          ),
          if (towers.length >= 3 && user != null)
            CustomPaint(
              painter: LinesPainter(towers[0].position, towers[1].position, towers[2].position, user!.data.coords),
              child: Container(),
            ),
          ...towers.map((tower) {
            return Positioned(
              left: tower.position.dx - tower.radius,
              top: tower.position.dy - tower.radius,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    tower.position = Offset(
                      tower.position.dx + details.delta.dx,
                      tower.position.dy + details.delta.dy,
                    );
                    if (towers.length >= 3) {
                      if (_isTriangulationPossible()) {
                        user = triangulateUserPosition(towers[0].position, towers[1].position, towers[2].position,
                            towers[0].distanceToUser, towers[1].distanceToUser, towers[2].distanceToUser);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Triangulation not possible with given distances')),
                        );
                      }
                    }
                  });
                },
                child: TowerWidget(data: tower),
              ),
            );
          }).toList(),
          if (user != null)
            Positioned(
              left: user!.data.coords.dx - 10,
              top: user!.data.coords.dy - 10,
              child: GestureDetector(
                onPanUpdate: (details) {
                  _updateUserPosition(Offset(
                    user!.data.coords.dx + details.delta.dx,
                    user!.data.coords.dy + details.delta.dy,
                  ));
                },
                child: UserWidget(data: user!.data),
              ),
            ),
        ],
      ),
    );
  }

  bool _isTriangulationPossible() {
    double d1 = towers[0].distanceToUser;
    double d2 = towers[1].distanceToUser;
    double d3 = towers[2].distanceToUser;
    double side1 = _calculateDistance(towers[0].position, towers[1].position);
    double side2 = _calculateDistance(towers[1].position, towers[2].position);
    double side3 = _calculateDistance(towers[2].position, towers[0].position);

    return (d1 + d2 > side1) && (d2 + d3 > side2) && (d3 + d1 > side3);
  }

  double _calculateDistance(Offset point1, Offset point2) {
    return sqrt(pow(point2.dx - point1.dx, 2) + pow(point2.dy - point1.dy, 2));
  }

  void _updateUserPosition(Offset newPosition) {
    setState(() {
      user!.data.coords = newPosition;
      for (var tower in towers) {
        tower.distanceToUser = _calculateDistance(tower.position, newPosition);
      }
      if (_isInCoverage()) {
        if (isFreeMode) {
          isFreeMode = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User is back in coverage area.')),
          );
        }
      } else {
        if (!isFreeMode) {
          isFreeMode = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User is out of coverage area.')),
          );
        }
      }
    });
  }

  bool _isInCoverage() {
    for (var tower in towers) {
      if (_calculateDistance(tower.position, user!.data.coords) > tower.radius) {
        return false;
      }
    }
    return true;
  }

  UserWidget triangulateUserPosition(Offset tower1, Offset tower2, Offset tower3, double distance1, double distance2, double distance3) {
    double x1 = tower1.dx;
    double y1 = tower1.dy;
    double x2 = tower2.dx;
    double y2 = tower2.dy;
    double x3 = tower3.dx;
    double y3 = tower3.dy;

    double A = 2 * (x2 - x1);
    double B = 2 * (y2 - y1);
    double C = distance1 * distance1 - distance2 * distance2 - x1 * x1 - y1 * y1 + x2 * x2 + y2 * y2;
    double D = 2 * (x3 - x2);
    double E = 2 * (y3 - y2);
    double F = distance2 * distance2 - distance3 * distance3 - x2 * x2 - y2 * y2 + x3 * x3 + y3 * y3;

    double x = (C * E - F * B) / (E * A - B * D);
    double y = (C * D - A * F) / (B * D - A * E);

    return UserWidget(data: UserModel(coords: Offset(x, y)));
  }
}
