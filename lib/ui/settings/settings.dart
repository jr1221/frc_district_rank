import 'package:bot_toast/bot_toast.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../cache_manager.dart';
import '../../constants.dart';

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
            builder: (context, box, widget) {
              return SettingsList(
                sections: [
                  SettingsSection(
                    title: const Text('General'),
                    tiles: <SettingsTile>[
                      SettingsTile.switchTile(
                          title: const Text('Use System Dark Mode'),
                          // true if no preference set in settings
                          initialValue: !box
                              .containsKey(ProjectConstants.darkModeStorageKey),
                          onToggle: (bool value) {
                            if (value) {
                              // remove preference from hive
                              box.delete(ProjectConstants.darkModeStorageKey);
                            } else {
                              // put current platform mode into hive darkMode
                              box.put(
                                  ProjectConstants.darkModeStorageKey,
                                  ((SchedulerBinding.instance.window
                                              .platformBrightness ==
                                          Brightness.dark)
                                      .toString()));
                            }
                          }),
                      // if user preference set, show dark theme switch
                      if (box.containsKey(ProjectConstants.darkModeStorageKey))
                        SettingsTile.switchTile(
                          title: const Text('Use Dark Mode'),
                          // current theme preference
                          initialValue:
                              box.get(ProjectConstants.darkModeStorageKey) ==
                                  'true',
                          onToggle: (bool value) {
                            // put preference into hive darkMode
                            box.put(ProjectConstants.darkModeStorageKey,
                                value.toString());
                          },
                        ),
                      SettingsTile.navigation(
                        title: const Text('Color Theme'),
                        description: const Text('Change the color theming'),
                        // current colorScheme for theme in hive
                        trailing: Icon(Icons.square_rounded,
                            color: Color(int.parse(box.get(
                                ProjectConstants.colorSchemeStorageKey,
                                defaultValue:
                                    Colors.blueGrey.value.toString())!))),
                        onPressed: (context) {
                          Navigator.pushNamed(context, '/settings/theme');
                        },
                      )
                    ],
                  ),
                  /*       SettingsSection(
                    title: const Text('Notifications'),
                    tiles: [
                      SettingsTile(
                        title: const Text('Change Team'),
                        onPressed: (context) {},
                      ),
                      SettingsTile.switchTile(
                        title: const Text('District Rank Notifications'),
                        onToggle: (bool value) async {},
                        initialValue: false,
                      ),
                    ],
                  ), */
                  SettingsSection(
                    title: const Text('Advanced'),
                    tiles: <SettingsTile>[
                      SettingsTile(
                        title: const Text('Clear cache'),
                        onPressed: (context) async {
                          try {
                            await (await Hive.openLazyBox<CacheResponse>(
                                    CacheManager.hiveCacheStore!.hiveBoxName))
                                .clear();
                            BotToast.showText(
                                text: 'Successfully cleared cache!');
                          } catch (e) {
                            BotToast.showText(text: 'Error: $e');
                          }
                        },
                      ),
                      SettingsTile(
                          title: const Text('Clear preferences'),
                          onPressed: (context) async {
                            try {
                              await Hive.box<String>(
                                      ProjectConstants.settingsBoxKey)
                                  .clear();
                              BotToast.showText(
                                  text: 'Successfully cleared preferences!');
                            } catch (e) {
                              BotToast.showText(text: 'Error: $e');
                            }
                          })
                    ],
                  ),
                  CustomSettingsSection(
                    child: Column(
                      children: const [
                        SizedBox(
                          height: 16,
                        ),
                        Text(
                          'Version: 1.1.0',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }));
  }
}

/*
    Widget _teamAskDialog() {
      return AlertDialog(
        title: const Text(
          'Enter Team Number',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Form(
              key: _teamSelectFormKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    controller: _teamSelectTextController,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null) {
                        return 'Empty or incorrect team number';
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) async {
                      if (_teamSelectFormKey.currentState!.validate()) {
                        await notifCreate();
                        setState(() {
                          GetStorage().write(Constants.teamNotifStorageKey,
                              int.parse(_teamSelectTextController.text));
                          GetStorage().read(Constants.shoudNotifStorageKey) ??
                              GetStorage()
                                  .write(Constants.shoudNotifStorageKey, false);
                          Workmanager().cancelAll();
                        });
                        Navigator.pop(context);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Team # from last 7 years',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_teamSelectFormKey.currentState!.validate()) {
                      await notifCreate();
                      setState(() {
                        GetStorage().write(Constants.teamNotifStorageKey,
                            int.parse(_teamSelectTextController.text));
                        GetStorage().read(Constants.shoudNotifStorageKey) ??
                            GetStorage()
                                .write(Constants.shoudNotifStorageKey, false);
                        Workmanager().cancelAll();
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }
    );
  }
} */
