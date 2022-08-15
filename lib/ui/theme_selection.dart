import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:frc_district_rank/constants.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Theme Selection'),
        ),
        body: ValueListenableBuilder<Box<String>>(
            valueListenable: Hive.box<String>(ProjectConstants.settingsBoxKey)
                .listenable(keys: [ProjectConstants.colorSchemeStorageKey]),
            builder: (context, box, widget) {
              final currentColor = Color(int.parse(
                  Hive.box<String>(ProjectConstants.settingsBoxKey).get(
                      ProjectConstants.colorSchemeStorageKey,
                      defaultValue: Colors.blueGrey.value.toString())!));
              return GridView.count(
                crossAxisCount: 5,
                children: [
                  for (Color color in Colors.primaries)
                    IconButton(
                      icon: Icon(
                        Icons.square_rounded,
                        color: color,
                        size: (color.value == currentColor.value) ? 60.0 : 36.0,
                      ),
                      color: Colors.black,
                      onPressed: () {
                        if (color.value != currentColor.value) {
                          _changeColor(color.value);
                          BotToast.showText(
                              text: 'Theme successfully changed!');
                        } else {
                          BotToast.showText(text: 'Already the current theme!');
                        }
                      },
                    )
                ],
              );
            }));
  }

  void _changeColor(int colorValue) {
    Hive.box<String>(ProjectConstants.settingsBoxKey)
        .put(ProjectConstants.colorSchemeStorageKey, colorValue.toString());
  }
}
