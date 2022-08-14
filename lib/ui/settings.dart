import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settings_ui/settings_ui.dart';

import '../constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<String>>(
        valueListenable:
            Hive.box<String>(ProjectConstants.settingsBoxKey).listenable(),
        builder: (context, box, widget) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Settings'),
                centerTitle: true,
              ),
              body: SettingsList(
                sections: [
                  SettingsSection(
                    title: const Text('General'),
                    tiles: <SettingsTile>[
                      SettingsTile.switchTile(
                          initialValue: !box
                              .containsKey(ProjectConstants.darkModeStorageKey),
                          onToggle: (bool value) {
                            if (value) {
                              box.delete(ProjectConstants.darkModeStorageKey);
                            } else {
                              box.put(
                                  ProjectConstants.darkModeStorageKey,
                                  ((SchedulerBinding.instance.window
                                              .platformBrightness ==
                                          Brightness.dark)
                                      .toString()));
                            }
                          },
                          title: const Text('Use System Theme')),
                      if (box.containsKey(ProjectConstants.darkModeStorageKey))
                        SettingsTile.switchTile(
                          title: const Text('Use Dark Theme'),
                          onToggle: (bool value) {
                            box.put(ProjectConstants.darkModeStorageKey,
                                value.toString());
                          },
                          initialValue:
                              box.get(ProjectConstants.darkModeStorageKey) ==
                                  'true',
                        )
                    ],
                  ),
                  /*     SettingsSection(
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
                  CustomSettingsSection(
                    child: Column(
                      children: const [
                        SizedBox(
                          height: 16,
                        ),
                        Text(
                          'Version: 2.0.0',
                        ),
                      ],
                    ),
                  ),
                ],
              ));
        });
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
