import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:frc_district_rank/constants.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

Color pickerColor = Colors.black;

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Theme Selection'),
          centerTitle: true,
        ),
        body: ValueListenableBuilder<Box<String>>(
            valueListenable: Hive.box<String>(ProjectConstants.settingsBoxKey)
                .listenable(keys: [ProjectConstants.colorSchemeStorageKey]),
            builder: (context, box, widget) {
              // Get current color, as defined by hive
              final currentColor = Color(int.parse(box.get(
                  ProjectConstants.colorSchemeStorageKey,
                  defaultValue: Colors.blueGrey.value.toString())!));
              return Column(children: <Widget>[
                SingleChildScrollView(
                    child: Column(children: [
                  const SizedBox(height: 10),
                  Tooltip(
                      triggerMode: TooltipTriggerMode.tap,
                      preferBelow: false,
                      showDuration: const Duration(seconds: 6),
                      message:
                          'The chosen color may not appear in the app, as the system formulates the best color scheme from the chosen color',
                      child: Text(
                        'Please choose a theme color:',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      )),
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    crossAxisCount: 5,
                    children: [
                      for (Color color in Colors.primaries)
                        IconButton(
                          icon: Icon(
                            Icons.square_rounded,
                            color: color,
                            size: (color.value == currentColor.value)
                                ? 60.0
                                : 36.0,
                          ),
                          color: Colors.black,
                          onPressed: () async {
                            if (color.value != currentColor.value) {
                              await _changeColorValue(color.value);
                              BotToast.showText(
                                  text: 'Theme successfully changed!');
                            } else {
                              BotToast.showText(
                                  text: 'Already the current theme!');
                            }
                          },
                        )
                    ],
                  ),
                  const SizedBox(height: 5.0),
                  Text(' - or - ',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10.0),
                  ElevatedButton(
                      onPressed: () {
                        showDialog<Widget>(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: const Text('Pick a color'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      labelTypes: const [
                                        ColorLabelType.rgb,
                                        ColorLabelType.hsv,
                                        ColorLabelType.hsl,
                                        ColorLabelType.hex
                                      ],
                                      paletteType: PaletteType.hueWheel,
                                      enableAlpha: false,
                                      pickerColor: Color(int.parse(box.get(
                                          ProjectConstants
                                              .colorSchemeStorageKey,
                                          defaultValue: Colors.blueGrey.value
                                              .toString())!)),
                                      onColorChanged: (Color color) {
                                        pickerColor = color;
                                      },
                                    ),
                                  ),
                                  actions: <Widget>[
                                    ElevatedButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          await _changeColorValue(
                                              pickerColor.value);
                                          BotToast.showText(
                                              text:
                                                  'Theme successfully changed!');
                                        },
                                        child: const Text('Apply'))
                                  ],
                                ));
                      },
                      child: const Text('Set Custom Color')),
                ])),
                const Spacer(),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Current Theme Color:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Icon(
                        Icons.square_rounded,
                        size: 48.0,
                        color: Color(int.parse(box.get(
                            ProjectConstants.colorSchemeStorageKey,
                            defaultValue: Colors.blueGrey.value.toString())!)),
                      ),
                      Text(
                        Color(int.parse(box.get(
                                ProjectConstants.colorSchemeStorageKey,
                                defaultValue:
                                    Colors.blueGrey.value.toString())!))
                            .toString(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ])
              ]);
            }));
  }

  Future<void> _changeColorValue(int colorValue) async {
    await Hive.box<String>(ProjectConstants.settingsBoxKey)
        .put(ProjectConstants.colorSchemeStorageKey, colorValue.toString());
  }
}
