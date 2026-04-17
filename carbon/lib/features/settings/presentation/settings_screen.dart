import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/settings/provider/settings_provider.dart';
import 'package:carbon/shared/widgets/app_loader.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:carbon/shared/widgets/core_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _matchesQuery(List<String> values) {
    if (_searchQuery.trim().isEmpty) {
      return true;
    }
    final query = _searchQuery.trim().toLowerCase();
    return values.any((value) => value.toLowerCase().contains(query));
  }

  Future<void> _showEditProfileDialog(SettingsFormState form) async {
    final nameController = TextEditingController(text: form.profileName);
    final emailController = TextEditingController(text: form.email);
    final phoneController = TextEditingController(text: form.phone);
    String? validationError;

    final shouldSave =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return AlertDialog(
                  title: const Text('Edit Profile'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                        if (validationError != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            validationError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final email = emailController.text.trim();
                        final phone = phoneController.text.trim();
                        if (name.isEmpty || email.isEmpty || phone.isEmpty) {
                          setDialogState(() {
                            validationError =
                                'Name, email, and phone are required.';
                          });
                          return;
                        }
                        if (!email.contains('@') || !email.contains('.')) {
                          setDialogState(() {
                            validationError = 'Enter a valid email address.';
                          });
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Update'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!shouldSave) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      return;
    }

    final action = ref.read(settingsActionProvider);
    action.updateProfileName(nameController.text.trim());
    action.updateEmail(emailController.text.trim());
    action.updatePhone(phoneController.text.trim());

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    if (!mounted) {
      return;
    }
    AppSnackbar.show(context, 'Profile details updated locally.');
  }

  Future<void> _confirmReset() async {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldReset =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Reset Settings'),
              content: const Text(
                'Are you sure you want to reset all settings to default values?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldReset) {
      return;
    }

    ref.read(settingsActionProvider).resetToDefault();
    if (!mounted) {
      return;
    }
    AppSnackbar.show(context, 'Settings reset to default values.');
  }

  Future<void> _saveSettings() async {
    final ok = await ref.read(settingsActionProvider).saveSettings();
    if (!mounted) {
      return;
    }

    if (!ok) {
      final message =
          ref.read(settingsActionErrorProvider) ??
          'Unable to save settings right now.';
      AppSnackbar.show(context, message, isError: true);
      return;
    }

    AppSnackbar.show(context, 'Settings saved successfully.');
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsAsyncProvider);
    final isInitialized = ref.watch(settingsInitializedProvider);
    final form = ref.watch(settingsFormProvider);

    settingsAsync.whenData((data) {
      if (!isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ref.read(settingsActionProvider).initializeFromRemote(data);
        });
      }
    });

    final isDarkMode = ref.watch(isDarkModeEnabledProvider);
    final backendError = ref.watch(settingsErrorProvider);
    final actionError = ref.watch(settingsActionErrorProvider);
    final actionLoading = ref.watch(settingsActionLoadingProvider);

    final action = ref.read(settingsActionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CoreScaffold(
      currentRoute: RouteNames.settings,
      title: 'Settings',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(settingsAsyncProvider);
          ref.read(settingsInitializedProvider.notifier).state = false;
          ref.read(settingsActionProvider).clearError();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (settingsAsync.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: SizedBox(height: 30, child: AppLoader()),
              ),
            if (backendError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  backendError,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _sectionTitle(context, 'Search Settings'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search settings, labels, or values',
                      suffixIcon: _searchQuery.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _sectionTitle(context, 'Account Settings'),
                  const SizedBox(height: 8),
                  if (_matchesQuery(<String>['profile', form.profileName]))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Profile'),
                      subtitle: Text(form.profileName),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditProfileDialog(form),
                      ),
                    ),
                  const Divider(height: 1),
                  if (_matchesQuery(<String>[
                    'email',
                    form.email,
                    'phone',
                    form.phone,
                  ]))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.contact_mail_outlined),
                      title: const Text('Email / Phone'),
                      subtitle: Text('${form.email}\n${form.phone}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_note_outlined),
                        onPressed: () => _showEditProfileDialog(form),
                      ),
                    ),
                  const Divider(height: 1),
                  if (_matchesQuery(<String>['password', 'security']))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Password'),
                      subtitle: const Text('Last changed recently'),
                      trailing: TextButton(
                        onPressed: () {
                          AppSnackbar.show(
                            context,
                            'Password management opens in security flow.',
                          );
                        },
                        child: const Text('Change'),
                      ),
                    ),
                ],
              ),
            ),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _sectionTitle(context, 'Preferences'),
                  const SizedBox(height: 8),
                  if (_matchesQuery(<String>['dark mode', 'theme']))
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark mode'),
                      subtitle: const Text(
                        'Use dark appearance across the app.',
                      ),
                      value: isDarkMode,
                      onChanged: action.setDarkMode,
                    ),
                  if (_matchesQuery(<String>['notifications']))
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      subtitle: const Text(
                        'Get claims, payout, and event alerts.',
                      ),
                      value: form.notificationsEnabled,
                      onChanged: action.setNotifications,
                    ),
                  if (_matchesQuery(<String>['auto sync', 'sync']))
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.sync_outlined),
                      title: const Text('Auto-sync'),
                      subtitle: const Text(
                        'Sync data automatically in background.',
                      ),
                      value: form.autoSync,
                      onChanged: action.setAutoSync,
                    ),
                  const SizedBox(height: 8),
                  if (_matchesQuery(<String>['language', form.language]))
                    DropdownButtonFormField<String>(
                      initialValue: form.language,
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        prefixIcon: Icon(Icons.language_outlined),
                      ),
                      items:
                          const <String>['English', 'Hindi', 'Tamil', 'Telugu']
                              .map((item) {
                                return DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                );
                              })
                              .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        action.setLanguage(value);
                      },
                    ),
                  const SizedBox(height: 10),
                  if (_matchesQuery(<String>[
                    'theme preference',
                    form.themePreference,
                  ]))
                    DropdownButtonFormField<String>(
                      initialValue: form.themePreference,
                      decoration: const InputDecoration(
                        labelText: 'Theme preference',
                        prefixIcon: Icon(Icons.palette_outlined),
                      ),
                      items: const <String>['System', 'Light', 'Dark']
                          .map((item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            );
                          })
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        action.setThemePreference(value);
                      },
                    ),
                ],
              ),
            ),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _sectionTitle(context, 'Privacy & Security'),
                  const SizedBox(height: 8),
                  if (_matchesQuery(<String>['permissions']))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: const Text('Permissions'),
                      subtitle: const Text(
                        'Manage location and notification permissions.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        AppSnackbar.show(
                          context,
                          'Permissions settings open in system preferences.',
                        );
                      },
                    ),
                  const Divider(height: 1),
                  if (_matchesQuery(<String>['data usage']))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.data_usage_outlined),
                      title: const Text('Data usage'),
                      subtitle: const Text(
                        'Control background sync and network usage.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        AppSnackbar.show(
                          context,
                          'Data usage controls will be available soon.',
                        );
                      },
                    ),
                  const Divider(height: 1),
                  if (_matchesQuery(<String>['security']))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.security_outlined),
                      title: const Text('Security settings'),
                      subtitle: const Text(
                        'Review account security and sessions.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        AppSnackbar.show(
                          context,
                          'Security module opens in the next step.',
                        );
                      },
                    ),
                ],
              ),
            ),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _sectionTitle(context, 'App Settings'),
                  const SizedBox(height: 8),
                  if (_matchesQuery(<String>['about app']))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About app'),
                      subtitle: const Text(
                        'Carbon parametric insurance platform.',
                      ),
                    ),
                  const Divider(height: 1),
                  if (_matchesQuery(<String>['version', form.appVersion]))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.new_releases_outlined),
                      title: const Text('Version'),
                      subtitle: Text(form.appVersion),
                    ),
                  const Divider(height: 1),
                  if (_matchesQuery(<String>['help', 'support']))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.support_agent_outlined),
                      title: const Text('Help & support'),
                      subtitle: const Text(
                        'Get assistance for account and policy issues.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        AppSnackbar.show(
                          context,
                          'Help center integration will be available in the next release.',
                        );
                      },
                    ),
                ],
              ),
            ),
            if (actionError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionError,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: actionLoading ? null : _saveSettings,
                    icon: actionLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(actionLoading ? 'Saving...' : 'Save Settings'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: actionLoading ? null : _confirmReset,
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('Reset to Default'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.secondary,
                      side: BorderSide(color: colorScheme.secondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
