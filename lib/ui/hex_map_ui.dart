import 'package:flutter/material.dart';

import '../web_gpu/map.dart';

class HexMapUi extends StatefulWidget {
  const HexMapUi({Key? key}) : super(key: key);

  @override
  State<HexMapUi> createState() => _HexMapUiState();
}

class _HexMapUiState extends State<HexMapUi> {
  final webGPUMap = WebGPUMap();

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await webGPUMap.init();
      webGPUMap.configure();
      webGPUMap.drawTriangle();
    });
  }
}
