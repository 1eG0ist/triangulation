import 'package:flutter/material.dart';

/*
* Модель данных пользователя
* */
class UserModel {
  /*
  * Позиция пользователя на общей карте координат
  * */
  Offset coords;

  UserModel({required this.coords});
}