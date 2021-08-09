import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:frc_district_rank/constants.dart';
import 'package:frc_district_rank/notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:workmanager/workmanager.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({Key? key}) : super(key: key);

  @override
  _SettingsWidgetState createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  final TextEditingController _teamSelectTextController =
      TextEditingController();
  final _teamSelectFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _settingsUI(),
    );
  }

  Widget _settingsUI() {
    return SettingsList(
      sections: [
        SettingsSection(
          title: 'General',
          tiles: [
            SettingsTile.switchTile(
              title: 'Use Dark Theme',
              subtitle: 'Will restart app!',
              onToggle: (bool value) {
                GetStorage().write(Constants.darkModeNotifStorageKey, value);
                Phoenix.rebirth(context);
              },
              switchValue:
                  GetStorage().read(Constants.darkModeNotifStorageKey) ??
                      Theme.of(context).brightness == Brightness.dark,
            )
          ],
        ),
        SettingsSection(
          titlePadding: const EdgeInsets.only(
            top: 16.0,
            left: 15.0,
            right: 15.0,
            bottom: 6.0,
          ),
          title: 'Notifications',
          subtitle: const Text(
              'If you change the team, you must re-enable notifications.'),
          tiles: [
            SettingsTile(
              title: 'Change Team',
              subtitle: 'FRC team for notifications',
              trailing: Text(
                'Currently ${GetStorage().read(Constants.teamNotifStorageKey) ?? 'not set'}',
                style: const TextStyle(fontSize: 18),
              ),
              onPressed: (context) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => _teamAskDialog(),
                );
              },
            ),
            SettingsTile.switchTile(
              title: 'District Rank Notifications',
              subtitle: 'Alert when district rank changes',
              onToggle: (bool value) async {
                if (value) {
                  if (GetStorage().read(Constants.teamNotifStorageKey) ==
                      null) {
                    showDialog(
                        context: context, builder: (_) => _teamAskDialog());
                  } else {
                    await notifCreate();
                  }
                } else {
                  Workmanager().cancelAll();
                }
                setState(() {
                  if (value) {
                    GetStorage().read(Constants.shoudNotifStorageKey) ??
                        GetStorage()
                            .write(Constants.shoudNotifStorageKey, false);
                  } else {
                    GetStorage().write(Constants.shoudNotifStorageKey, false);
                  }
                });
              },
              switchValue:
                  GetStorage().read(Constants.shoudNotifStorageKey) ?? false,
            ),
          ],
        ),
        CustomSection(
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
    );
  }


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
