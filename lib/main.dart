import 'package:flutter/material.dart';

void main() {
  runApp(const Map());
}

class Map extends StatelessWidget {
  const Map({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MapUI(),
      // Hide the annoying debug ribbon, it covers the settings icon.
      debugShowCheckedModeBanner: false,
    );
  }
}

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
			  onPressed: () {
                print('Settings pressed.');
			  },
			),
          ),
        ],
      ),
    );
  }
}
