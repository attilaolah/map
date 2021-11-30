import 'package:flutter/material.dart';

class MapUI extends StatefulWidget {
  const MapUI({Key? key}) : super(key: key);

  @override
  State<MapUI> createState() => _MapUIState();
}

class _MapUIState extends State<MapUI> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: SizedBox.shrink(),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                semanticLabel: 'Settings',
              ),
              iconSize: 24,
              splashRadius: 24,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
