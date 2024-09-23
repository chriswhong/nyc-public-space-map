import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:flutter_futz/map_handler.dart';
import 'package:flutter_futz/panel_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late final MapHandler _mapHandler;
  final PanelController _pc = PanelController();
  late final PanelHandler _panelHandler;

  @override
  void initState() {
    super.initState();

    // initialize panel handler, specify a function to run when the content is updated
    _panelHandler = PanelHandler(
      onPanelContentUpdated:
          _updatePanel, // Pass callback to handle state updates
    );

    _mapHandler = MapHandler(context);
    // Initialize map handler with panel handler functions if needed
    _mapHandler.init(_pc, _panelHandler.updatePanelContent);
  }

  // Callback to trigger a rebuild when content changes
  void _updatePanel() {
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();

    return MaterialApp(
        title: 'Flutter Demo',
        home: Scaffold(
          body: Stack(children: <Widget>[
            SlidingUpPanel(
              controller: _pc,
              panel: _panelHandler.buildPanel(),
              onPanelSlide: _panelHandler.onPanelSlide,
              body: _mapHandler.buildMap(),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18.0)),
              minHeight: 100, // The height of the collapsed panel
              maxHeight: 300, // The height of the expanded panel
            ),
            _panelHandler.buildFloatingButton(),
          ]),
          // body:
        ));
  }
}