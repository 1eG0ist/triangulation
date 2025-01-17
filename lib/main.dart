import 'package:flutter/material.dart';
import 'package:triangulation/pages/world_map.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WorldMapPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
