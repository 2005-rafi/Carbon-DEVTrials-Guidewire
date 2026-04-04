import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/theme/theme_provider.dart';
import 'package:carbon/features/settings/data/settings_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsFormState {
  const SettingsFormState({
    required this.profileName,
    required this.email,
    required this.phone,
    required this.notificationsEnabled,
    required this.darkMode,
    required this.autoSync,
    required this.language,
    required this.themePreference,
    required this.appVersion,
  });

  final String profileName;
  final String email;
  final String phone;
  final bool notificationsEnabled;
  final bool darkMode;
  final bool autoSync;
  final String language;
  final String themePreference;
  final String appVersion;

  factory SettingsFormState.fromData(SettingsData data) {
    return SettingsFormState(
      profileName: data.profileName,
      email: data.email,
      phone: data.phone,
      notificationsEnabled: data.notificationsEnabled,
      darkMode: data.darkTheme,
      autoSync: data.autoSync,
      language: data.language,
      themePreference: data.themePreference,
      appVersion: data.appVersion,
    );
  }

  SettingsData toData() {
    return SettingsData(
      profileName: profileName,
      email: email,
      phone: phone,
      notificationsEnabled: notificationsEnabled,
      darkTheme: darkMode,
      autoSync: autoSync,
      language: language,
      themePreference: themePreference,
      appVersion: appVersion,
    );
  }

  SettingsFormState copyWith({
    String? profileName,
    String? email,
    String? phone,
    bool? notificationsEnabled,
    bool? darkMode,
    bool? autoSync,
    String? language,
    String? themePreference,
    String? appVersion,
  }) {
    return SettingsFormState(
      profileName: profileName ?? this.profileName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      autoSync: autoSync ?? this.autoSync,
      language: language ?? this.language,
      themePreference: themePreference ?? this.themePreference,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

final settingsErrorProvider = StateProvider<String?>((ref) => null);
final settingsActionErrorProvider = StateProvider<String?>((ref) => null);
final settingsActionLoadingProvider = StateProvider<bool>((ref) => false);
final settingsInitializedProvider = StateProvider<bool>((ref) => false);

final settingsFormProvider = StateProvider<SettingsFormState>((ref) {
  return SettingsFormState.fromData(SettingsData.fallback());
});

final settingsAsyncProvider = FutureProvider<SettingsData>((ref) async {
  ref.read(settingsErrorProvider.notifier).state = null;
  try {
    return await ref.read(settingsApiProvider).fetchSettings();
  } catch (error) {
    ref.read(settingsErrorProvider.notifier).state = error.toString();
    return SettingsData.fallback();
  }
});

final settingsActionProvider = Provider<SettingsAction>((ref) {
  return SettingsAction(ref);
});

final isDarkModeEnabledProvider = Provider<bool>((ref) {
  return ref.watch(themeModeProvider) == ThemeMode.dark;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsFormProvider).notificationsEnabled;
});

class SettingsAction {
  SettingsAction(this._ref);

  final Ref _ref;

  void clearError() {
    _ref.read(settingsActionErrorProvider.notifier).state = null;
  }

  void initializeFromRemote(SettingsData data) {
    _ref.read(settingsFormProvider.notifier).state = SettingsFormState.fromData(
      data,
    );
    _ref.read(settingsInitializedProvider.notifier).state = true;

    final preference = data.themePreference.trim().toLowerCase();
    if (preference == 'dark' || data.darkTheme) {
      _ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
    } else if (preference == 'light') {
      _ref.read(themeModeProvider.notifier).state = ThemeMode.light;
    } else {
      _ref.read(themeModeProvider.notifier).state = ThemeMode.system;
    }
  }

  void updateProfileName(String value) {
    _ref.read(settingsFormProvider.notifier).state = _ref
        .read(settingsFormProvider)
        .copyWith(profileName: value);
  }

  void updateEmail(String value) {
    _ref.read(settingsFormProvider.notifier).state = _ref
        .read(settingsFormProvider)
        .copyWith(email: value);
  }

  void updatePhone(String value) {
    _ref.read(settingsFormProvider.notifier).state = _ref
        .read(settingsFormProvider)
        .copyWith(phone: value);
  }

  void setNotifications(bool enabled) {
    _ref.read(settingsFormProvider.notifier).state = _ref
        .read(settingsFormProvider)
        .copyWith(notificationsEnabled: enabled);
  }

  void setAutoSync(bool enabled) {
    _ref.read(settingsFormProvider.notifier).state = _ref
        .read(settingsFormProvider)
        .copyWith(autoSync: enabled);
  }

  void setLanguage(String language) {
    _ref.read(settingsFormProvider.notifier).state = _ref
        .read(settingsFormProvider)
        .copyWith(language: language);
  }

  void setThemePreference(String preference) {
    final normalized = preference.trim().toLowerCase();
    _ref.read(settingsFormProvider.notifier).state = _ref
        .read(settingsFormProvider)
        .copyWith(themePreference: preference, darkMode: normalized == 'dark');

    if (normalized == 'dark') {
      _ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
    } else if (normalized == 'light') {
      _ref.read(themeModeProvider.notifier).state = ThemeMode.light;
    } else {
      _ref.read(themeModeProvider.notifier).state = ThemeMode.system;
    }
  }

  void setDarkMode(bool enabled) {
    _ref.read(settingsFormProvider.notifier).state = _ref
        .read(settingsFormProvider)
        .copyWith(
          darkMode: enabled,
          themePreference: enabled ? 'Dark' : 'Light',
        );

    _ref.read(themeModeProvider.notifier).state = enabled
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  void resetToDefault() {
    final fallback = SettingsData.fallback();
    _ref.read(settingsFormProvider.notifier).state = SettingsFormState.fromData(
      fallback,
    );
    _ref.read(themeModeProvider.notifier).state = ThemeMode.system;
    clearError();
  }

  Future<bool> saveSettings() async {
    _ref.read(settingsActionLoadingProvider.notifier).state = true;
    _ref.read(settingsActionErrorProvider.notifier).state = null;

    try {
      final data = _ref.read(settingsFormProvider).toData();
      await _ref.read(settingsApiProvider).updateSettings(data);
      return true;
    } on ApiException catch (error) {
      _ref.read(settingsActionErrorProvider.notifier).state = error.message;
      return false;
    } catch (_) {
      _ref.read(settingsActionErrorProvider.notifier).state =
          'Unable to save settings right now. Please try again.';
      return false;
    } finally {
      _ref.read(settingsActionLoadingProvider.notifier).state = false;
    }
  }
}
