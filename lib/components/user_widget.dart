import 'package:flutter/material.dart';
import 'package:triangulation/models/user_model.dart';

class UserWidget extends StatelessWidget {
  const UserWidget({super.key, required this.data});

  final UserModel data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
    );
  }
}