import 'package:flutter/material.dart';
import 'package:triangulation/models/tower_model.dart';

class TowerWidget extends StatelessWidget {
  final TowerModel data;

  TowerWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: data.radius * 2,
          height: data.radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.red,
              width: 1,
            ),
            color: Colors.red.withOpacity(0.1), // Лёгкая красноватая заливка
          ),
        ),
        // Центральная башня (пример)
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
        ),
        Positioned(
            top: data.radius / 2,
            left: data.radius / 2,
            child: Text(
                "P = ${data.signalPower}|R = ${data.radius}\n"
                    "X = ${data.position.dx.round()}|Y = ${data.position.dy.round()}",
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w100
                )
            )
        )
      ],
    );
  }
}
