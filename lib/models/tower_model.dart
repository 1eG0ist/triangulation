import 'dart:ui';

/*
* Модель данных вышки
* */
class TowerModel {
  /*
  * Позиция вышки на общей карте координат
  * */
  Offset position;
  double signalPower;
  double radius;
  double distanceToUser;

  TowerModel({required this.position, required this.signalPower, required this.distanceToUser, required this.radius});
}