import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:triangulation/components/tower_widget.dart';
import 'package:triangulation/components/user_widget.dart';
import 'package:triangulation/models/tower_model.dart';
import 'package:triangulation/models/user_model.dart';
import 'package:triangulation/utils/lines_painter.dart';
import 'package:triangulation/errors/infinity_user_position_error.dart';
import 'package:triangulation/errors/zero_division_error.dart';

class WorldMapPage extends StatefulWidget {
  @override
  _WorldMapPageState createState() => _WorldMapPageState();
}

class _WorldMapPageState extends State<WorldMapPage> {
  List<TowerModel> towers = [];
  UserWidget? user;

  /*
  * free mode - состояние устройства, когда пользователь сам вытянул его из
  * области треангуляции.
  *
  * Переход из свободного состояния возможен только в случае если пользователь
  * поместит устройство обратно в зону треангуляции
  * */
  bool isFreeMode = false;

  /*
  * Контроллеры ввода значений новой вышки
  * */
  final TextEditingController towerXController = TextEditingController();
  final TextEditingController towerYController = TextEditingController();
  final TextEditingController signalPowerController = TextEditingController();
  final TextEditingController distanceToUserController = TextEditingController();
  final TextEditingController radiusController = TextEditingController();

  /*
  * Инициализируем начальное состояние
  * */
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome! Add towers to begin triangulation.')),
      );
    });
  }

  /*
  * Добавление вышки
  * 1. Парсит данные из контроллеров, которые подключены к полям ввода
  * 2. Очищает данные контроллеры после удаления
  * 3. Инициализирует пересчет состояния учитывая новые данные вызовом функции [checkSituationOnAddingTower]
  * 4. В случае ошибки уведомляет об этом пользователя
  * */
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

      checkSituationOnAddingTower();
    } catch (e) {
      _showSnackBar('Invalid input! Please enter valid numbers.');
    }
  }

  /*
  * Если позиция пользователя может быть рассчитана, то она рассчитывается
  * и присваивается пользователю
  * */
  void checkSituationOnAddingTower() {
    if (towers.length >= 3) {
      if (_isTriangulationPossible()) {
        user = triangulateUserPosition(towers[0].position, towers[1].position, towers[2].position,
            towers[0].distanceToUser, towers[1].distanceToUser, towers[2].distanceToUser);
      } else {
        _showSnackBar('Triangulation not possible with given distances');
      }
    }
  }

  /*
  * Проверяет возможность рассчета позиции пользователя
  * */
  bool _isTriangulationPossible() {
    double d1 = towers[0].distanceToUser;
    double d2 = towers[1].distanceToUser;
    double d3 = towers[2].distanceToUser;
    double side1 = _calculateDistance(towers[0].position, towers[1].position);
    double side2 = _calculateDistance(towers[1].position, towers[2].position);
    double side3 = _calculateDistance(towers[2].position, towers[0].position);

    return (d1 + d2 > side1) && (d2 + d3 > side2) && (d3 + d1 > side3);
  }

  /*
  * Добавляет стандартные вышки, при которых позиция пользователя может быть рассчитана
  * */
  void enterDefaultTowers() {
    setState(() {
      towers.add(
          TowerModel(
              position: Offset(50, 50),
              signalPower: 10,
              radius: 200,
              distanceToUser: 70,
          )
      );
      towers.add(
          TowerModel(
            position: Offset(200, 50),
            signalPower: 20,
            radius: 250,
            distanceToUser: 100,
          )
      );
      towers.add(
          TowerModel(
            position: Offset(100, 200),
            signalPower: 30,
            radius: 300,
            distanceToUser: 120,
          )
      );
    });
    checkSituationOnAddingTower();
  }

  /*
  * Высчитывает дистанцию между двумя точками координат с помощью Т. Пифагора
  * */
  double _calculateDistance(Offset point1, Offset point2) {
    return sqrt(pow(point2.dx - point1.dx, 2) + pow(point2.dy - point1.dy, 2));
  }

  /*
  * Рассчитывает силу сигнала исходя из дистанции
  * */
  double _calculateSignalPower(double distance) {
    return min(1000, 100 / (distance * distance));
  }

  /*
  * Обновлене позиции пользователя
  * */
  void _updateUserPosition(Offset newPosition) {
    setState(() {
      user!.data.coords = newPosition;
      /*
      * При обновлении позиции пересчитывается расстояние до каждой вышки
      * */
      for (var tower in towers) {
        tower.distanceToUser = _calculateDistance(tower.position, newPosition);
        tower.signalPower = _calculateSignalPower(tower.distanceToUser);
      }
      _checkCoverage();
    });
  }

  /*
  * Оповещение пользователя о состоянии в котором находится устройство в данный момент
  * */
  void _checkCoverage() {
    if (_isInCoverage()) {
      if (isFreeMode) {
        isFreeMode = false;
        _showSnackBar('User is back in coverage area.');
      }
    } else {
      if (!isFreeMode) {
        isFreeMode = true;
        _showSnackBar('User is out of coverage area.');
      }
    }
  }

  /*
  * Проверка нахождения устройства в пределах радиуса покрытия вышек
  * */
  bool _isInCoverage() {
    for (var tower in towers) {
      if (_calculateDistance(tower.position, user!.data.coords) > tower.radius) {
        return false;
      }
    }
    return true;
  }

  /*
  * Проверка нахождения точки в пределах радиуса покрытия вышек
  * */
  bool _isPointWithinAllTowers(Offset point) {
    for (var tower in towers) {
      if (_calculateDistance(tower.position, point) > tower.radius) {
        return false;
      }
    }
    return true;
  }

  /*
  * Высчитываение позиции пользователя
  * */
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

    double denominator = (E * A - B * D);
    if (denominator == 0) {
      throw ZeroDivisionError(message: "0 denominator");
    }

    double x = (C * E - F * B) / denominator;
    double y = (C * D - A * F) / (B * D - A * E);

    if (x.isInfinite || y.isInfinite || x.isNaN || y.isNaN) {
      throw InfinityUserPositionError(message: "Infinity exception");
    }

    return UserWidget(data: UserModel(coords: Offset(x, y)));
  }

  /*
  * Показ информации пользователю с закрытием предыдущего уведомления
  * */
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /*
  * Интерфейс
  * */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triangulation Example'),
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                children: [
                  const Text('Input Coordinates'),
                  OutlinedButton(
                    onPressed: enterDefaultTowers,
                    child: const Text(
                      "Enter default towers",
                      style: TextStyle(
                        color: Colors.black
                      ),
                    )
                  )
                ],
              ),
            ),
            if (towers.length >= 3)
              Column(
                children: [
                  const Text('User Position'),
                  Text('X: ${user?.data.coords.dx ?? 'N/A'}'),
                  Text('Y: ${user?.data.coords.dy ?? 'N/A'}'),
                ],
              ),
            ListTile(
              title: const Text('Create Tower'),
              subtitle: Column(
                children: [
                  TextField(
                    controller: towerXController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(labelText: 'X'),
                  ),
                  TextField(
                    controller: towerYController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Y'),
                  ),
                  TextField(
                    controller: signalPowerController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Signal Power'),
                  ),
                  TextField(
                    controller: radiusController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Radius'),
                  ),
                  TextField(
                    controller: distanceToUserController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
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
              trailing: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    towers.remove(tower);
                    if (towers.length < 3) {
                      user = null; // Сбрасываем позицию пользователя, если вышек меньше 3
                    }
                  });
                },
              ),
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
                  try {
                    setState(() {
                      tower.position = Offset(
                        tower.position.dx + details.delta.dx,
                        tower.position.dy + details.delta.dy,
                      );
                      tower.distanceToUser = _calculateDistance(tower.position, user!.data.coords);

                      if (tower.distanceToUser > tower.radius) {
                        tower.signalPower = 0;
                      } else {
                        tower.signalPower = _calculateSignalPower(tower.distanceToUser);
                      }

                      _checkCoverage();
                      if (towers.length >= 3) {
                        if (_isTriangulationPossible()) {
                          UserWidget newUserWidget = triangulateUserPosition(towers[0].position, towers[1].position, towers[2].position,
                              towers[0].distanceToUser, towers[1].distanceToUser, towers[2].distanceToUser);
                          if (_isPointWithinAllTowers(newUserWidget.data.coords)) {
                            user!.data.coords = newUserWidget.data.coords;
                          } else {
                            _showSnackBar('User out of coverage area, not set new position');
                          }
                        } else {
                          _showSnackBar('Triangulation not possible with given distances');
                        }
                      }
                    });
                  } on ZeroDivisionError catch (e) {
                    _showSnackBar(e.message);
                  } on InfinityUserPositionError catch(e) {
                    _showSnackBar(e.message);
                  } catch(e) {
                    _showSnackBar("Error, something went wrong, try to reload page or app");
                  }
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
                  try {
                    _updateUserPosition(Offset(
                      user!.data.coords.dx + details.delta.dx,
                      user!.data.coords.dy + details.delta.dy,
                    ));
                  } catch (e) {
                    _showSnackBar('Error, something went wrong, mb tower or device out of map');
                  }
                },
                child: UserWidget(data: user!.data),
              ),
            ),
        ],
      ),
    );
  }
}
