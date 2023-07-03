import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_joystick/flutter_joystick.dart' as joystick;
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

import '../components/enable.dart';
import '../components/joystick/joystick.dart';
import '../components/model_viewer/model_viewer_stub.dart' // Stub implementation
    if (dart.library.io) '../components/model_viewer/model_viewer_native.dart' // dart:io implementation
    if (dart.library.html) '../components/model_viewer/model_viewer_web.dart'; // dart:html implementation
import '../components/status.dart';
import '../components/telemetry_table.dart';
import '../domain/connection.dart';
import '../domain/dtos/telemetry_message.dart';
import '../models/connection_model.dart';
import '../models/telemetry_model.dart';

class JoystickPage extends StatefulWidget {
  const JoystickPage({Key? key}) : super(key: key);

  @override
  JoystickPageState createState() => JoystickPageState();
}

class JoystickPageState extends State<JoystickPage> {
  joystick.StickDragDetails? _stickDragDetails;

  TelemetryMessage? _telemetryMessage;
  bool _isEnabled = false;
  double _pitch = 0;

  // constructor
  JoystickPageState() {
    TelemetryModel().addListener(() {
      setState(() {
        _telemetryMessage = TelemetryModel().telemetryMessage;
        _pitch = TelemetryModel().telemetryMessage?.pitch ?? 0;
        _isEnabled = TelemetryModel().telemetryMessage?.enabled ?? false;
      });
    });
  }

  Widget getPrimaryBox(
    bool showModelViewer,
    ConnectionStatus connectionStatus,
  ) {
    if (showModelViewer) {
      return DefaultTabController(
        length: 2,
        child: TabBarView(
          children: [
            AbsorbPointer(
              child: ModelViewer(
                yaw: connectionStatus == ConnectionStatus.connected
                    ? (_stickDragDetails?.x ?? 0) * 45
                    : 0,
                pitch: connectionStatus == ConnectionStatus.connected
                    ? -_pitch
                    : 0,
              ),
            ),
            TelemetryTable(telemetryMessage: _telemetryMessage),
          ],
        ),
      );
    } else {
      return TelemetryTable(telemetryMessage: _telemetryMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ModelViewer is not supported on desktop (yet)
    bool showModelViewer = UniversalPlatform.isAndroid || UniversalPlatform.isIOS || UniversalPlatform.isWeb;
    // bool showModelViewer = false;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Open settings',
            onPressed: () {
              // navigate to config_page
              Navigator.pushNamed(context, '/config-auth');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Consumer<ConnectionModel>(
            builder: (context, value, child) {
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            StatusIndicator(
                              connectionStatus: value.status,
                              enabled: _isEnabled,
                            ),
                            const SizedBox(height: 10),
                            SlideToEnable(
                              enabled: _isEnabled,
                              onStateChange: (value) {
                                setEnabledCommand(value);
                              },
                            ),
                          ],
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: getPrimaryBox(showModelViewer, value.status),
                        ),
                        Joystick(
                          listener: (joystick.StickDragDetails details) {
                            setState(() {
                              _stickDragDetails = details;
                            });

                            setJoystickCommand(details);
                          },
                        ),
                      ],
                    );
                  } else {
                    // return desktop view
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            StatusIndicator(
                              connectionStatus: value.status,
                              enabled: _isEnabled,
                            ),
                            const SizedBox(height: 10),
                            SlideToEnable(
                              height: clampDouble(
                                constraints.maxHeight / 4,
                                50,
                                70,
                              ),
                              enabled: _isEnabled,
                              onStateChange: (value) {
                                setEnabledCommand(value);
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth * 0.4,
                              child:
                                  getPrimaryBox(showModelViewer, value.status),
                            ),
                            Joystick(
                              size: min(constraints.maxHeight / 2, 200),
                              listener: (joystick.StickDragDetails details) {
                                setState(() {
                                  _stickDragDetails = details;
                                });

                                setJoystickCommand(details);
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
