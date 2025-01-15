import 'dart:ui';

class TowerModel {
  Offset position;
  double signalPower;
  double radius;
  double distanceToUser;

  TowerModel({required this.position, required this.signalPower, required this.distanceToUser, required this.radius});
}