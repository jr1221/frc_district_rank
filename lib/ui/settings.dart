import 'package:bot_toast/bot_toast.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../cache_manager.dart';
import '../constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<String>>(
        // listen to changes in all settings
        valueListenable:
            Hive.box<String>(ProjectConstants.settingsBoxKey).listenable(),
        builder: (
          context,
          box,
          widget,
        ) {
          List<Widget> generalSettings = [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: 24,
                      end: 24,
                      bottom: 19 * MediaQuery.of(context).textScaleFactor,
                      top: 19 * MediaQuery.of(context).textScaleFactor,
                    ),
                    child: Text(
                      'Use System Dark Mode',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 16,
                    end: 8,
                  ),
                  child: Switch(
                    value:
                        !box.containsKey(ProjectConstants.darkModeStorageKey),
                    onChanged: (bool value) {
                      if (value) {
                        // remove preference from hive
                        box.delete(ProjectConstants.darkModeStorageKey);
                      } else {
                        // put current platform mode into hive darkMode
                        box.put(
                          ProjectConstants.darkModeStorageKey,
                          (View.of(context)
                                      .platformDispatcher
                                      .platformBrightness ==
                                  Brightness.dark)
                              .toString(),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            if (box.containsKey(ProjectConstants.darkModeStorageKey))
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 24,
                        end: 24,
                        bottom: 19 * MediaQuery.of(context).textScaleFactor,
                        top: 19 * MediaQuery.of(context).textScaleFactor,
                      ),
                      child: Text(
                        'Use Dark Mode',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      end: 8,
                    ),
                    child: Switch(
                      value: box.get(ProjectConstants.darkModeStorageKey) ==
                          'true',
                      onChanged: (bool value) {
                        box.put(
                          ProjectConstants.darkModeStorageKey,
                          value.toString(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            InkWell(
              onTap: () async => await ColorPicker(
                color: Color(
                  int.parse(box.get(
                    ProjectConstants.colorSchemeStorageKey,
                    defaultValue: Colors.blueGrey.value.toString(),
                  )!),
                ),
                onColorChanged: (Color color) {},
                onColorChangeEnd: (Color color) =>
                    _changeColorValue(color.value),
                heading: Text(
                  'Select color',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                wheelSubheading: Text(
                  'Selected color and its shades',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                showMaterialName: true,
                showColorName: true,
                showColorCode: true,
                enableShadesSelection: false,
                enableTonalPalette: false,
                copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                  copyFormat: ColorPickerCopyFormat.hexRRGGBB,
                  longPressMenu: true,
                ),
                pickersEnabled: const <ColorPickerType, bool>{
                  ColorPickerType.both: true,
                  ColorPickerType.primary: false,
                  ColorPickerType.accent: false,
                  ColorPickerType.bw: false,
                  ColorPickerType.custom: false,
                  ColorPickerType.wheel: true,
                },
              ).showPickerDialog(context),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 24,
                        end: 24,
                        bottom: 19 * MediaQuery.of(context).textScaleFactor,
                        top: 19 * MediaQuery.of(context).textScaleFactor,
                      ),
                      child: Text(
                        'Change Color Theme',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ColorIndicator(
                      color: Color(
                        int.parse(box.get(
                          ProjectConstants.colorSchemeStorageKey,
                          defaultValue: Colors.blueGrey.value.toString(),
                        )!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
          List<Widget> advancedSettings = [
            InkWell(
              onTap: () async {
                try {
                  CacheManager.hiveCacheStore!.clean();
                  BotToast.showText(text: 'Successfully cleared cache!');
                } catch (e) {
                  BotToast.showText(text: 'Error: $e');
                }
              },
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: 24,
                  end: 24,
                  bottom: 19 * MediaQuery.of(context).textScaleFactor,
                  top: 19 * MediaQuery.of(context).textScaleFactor,
                ),
                child: Text(
                  'Clear cache',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                try {
                  await Hive.box<String>(ProjectConstants.settingsBoxKey)
                      .clear();
                  BotToast.showText(text: 'Successfully cleared preferences!');
                } catch (e) {
                  BotToast.showText(text: 'Error: $e');
                }
              },
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: 24,
                  end: 24,
                  bottom: 19 * MediaQuery.of(context).textScaleFactor,
                  top: 19 * MediaQuery.of(context).textScaleFactor,
                ),
                child: Text(
                  'Clear preferences',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ];

          return Container(
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 810),
              child: ListView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 65 * MediaQuery.of(context).textScaleFactor,
                        padding: EdgeInsetsDirectional.only(
                          bottom: 5 * MediaQuery.of(context).textScaleFactor,
                          start: 6,
                          top: 40 * MediaQuery.of(context).textScaleFactor,
                        ),
                        child: Text(
                          'General',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Card(
                        elevation: 4,
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: generalSettings.length,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (
                            BuildContext context,
                            int index,
                          ) {
                            return generalSettings[index];
                          },
                          separatorBuilder: (
                            BuildContext context,
                            int index,
                          ) {
                            return const Divider(
                              height: 0,
                              thickness: 1,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 65 * MediaQuery.of(context).textScaleFactor,
                        padding: EdgeInsetsDirectional.only(
                          bottom: 5 * MediaQuery.of(context).textScaleFactor,
                          start: 6,
                          top: 40 * MediaQuery.of(context).textScaleFactor,
                        ),
                        child: Text(
                          'Advanced',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Card(
                        elevation: 4,
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: advancedSettings.length,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (
                            BuildContext context,
                            int index,
                          ) {
                            return advancedSettings[index];
                          },
                          separatorBuilder: (
                            BuildContext context,
                            int index,
                          ) {
                            return const Divider(
                              height: 0,
                              thickness: 1,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const Column(
                    children: [
                      SizedBox(height: 16),
                      Text('Version: 1.2.2'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changeColorValue(int colorValue) async {
    await Hive.box<String>(ProjectConstants.settingsBoxKey).put(
      ProjectConstants.colorSchemeStorageKey,
      colorValue.toString(),
    );
  }
}
