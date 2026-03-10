import 'package:flutter/material.dart';
import 'l10n_en.dart';
import 'l10n_zh_cn.dart';
import 'l10n_zh_tw.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': l10nEn,
    'zh_CN': l10nZhCN,
    'zh_TW': l10nZhTW,
  };

  String _key() {
    if (locale.languageCode == 'zh') {
      if (locale.scriptCode == 'Hant' || locale.countryCode == 'TW' || locale.countryCode == 'HK') {
        return 'zh_TW';
      }
      return 'zh_CN';
    }
    return locale.languageCode;
  }

  String translate(String key) {
    final k = _key();
    return _localizedValues[k]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  // Navigation
  String get tabMeter => translate('tab_meter');
  String get tabCamera => translate('tab_camera');
  String get tabRecords => translate('tab_records');
  String get tabSettings => translate('tab_settings');

  // Meter
  String get meterTitle => translate('meter_title');
  String get average => translate('average');
  String get maximum => translate('maximum');
  String get minimum => translate('minimum');
  String get duration => translate('duration');
  String get levelVerySilent => translate('level_very_silent');
  String get levelSilent => translate('level_silent');
  String get levelNormal => translate('level_normal');
  String get levelNoisy => translate('level_noisy');
  String get levelVeryNoisy => translate('level_very_noisy');
  String get levelExtreme => translate('level_extreme');
  String get dbUnit => translate('db_unit');
  String get decibelStandard => translate('decibel_standard');
  String get noise_20 => translate('noise_20');
  String get noise_40 => translate('noise_40');
  String get noise_60 => translate('noise_60');
  String get noise_70 => translate('noise_70');
  String get noise_90 => translate('noise_90');
  String get noise_100 => translate('noise_100');
  String get noise_110 => translate('noise_110');
  String get noise_120 => translate('noise_120');

  // Camera
  String get photo => translate('photo');
  String get video => translate('video');
  String get relocate => translate('relocate');
  String get flip => translate('flip');
  String get maxLabel => translate('max_label');
  String get minLabel => translate('min_label');
  String get avgLabel => translate('avg_label');
  String get durationLabel => translate('duration_label');

  // Records
  String get records => translate('records');
  String get noRecords => translate('no_records');
  String get nonProLimit => translate('non_pro_limit');
  String get unlockFree => translate('unlock_free');
  String get limitTimeTitle => translate('limit_time_title');
  String get limitTimeContent => translate('limit_time_content');
  String get limitTimeFree => translate('limit_time_free');
  String get limitTimeLast20s => translate('limit_time_last30s');
  String get limitTimeClose => translate('limit_time_close');
  String get editRecordName => translate('edit_record_name');
  String get editRecordNameCancel => translate('edit_record_name_cancel');
  String get editRecordNameSave => translate('edit_record_name_save');

  // Record Detail
  String get basicInfo => translate('basic_info');
  String get measurementInfo => translate('measurement_info');
  String get nameLabel => translate('name_label');
  String get timeLabel => translate('time_label');
  String get recordDuration => translate('record_duration');
  String get device => translate('device');
  String get location => translate('location');
  String get notes => translate('notes');
  String get frequencyWeighting => translate('frequency_weighting');
  String get responseTime => translate('response_time');
  String get calibration => translate('calibration');
  String get maxDecibel => translate('max_decibel');
  String get minDecibel => translate('min_decibel');
  String get avgDecibel => translate('avg_decibel');
  String get peakValue => translate('peak_value');
  String get editNotes => translate('edit_notes');
  String get editNotesCancel => translate('edit_notes_cancel');
  String get editNotesSave => translate('edit_notes_save');

  // Settings
  String get settings => translate('settings');
  String get proTitle => translate('pro_title');
  String get freeTrial => translate('free_trial');
  String get responseFrequency => translate('response_frequency');
  String get autoRecord => translate('auto_record');
  String get aboutUs => translate('about_us');
  String get aboutUsTitle => translate('about_us_title');
  String get aboutUsContent => translate('about_us_content');
  String get aboutUsOk => translate('about_us_ok');
  String get slow => translate('slow');

  // Pro Subscription
  String get freeTrialTitle => translate('free_trial_title');
  String get proSubtitle => translate('pro_subtitle');
  String get featureUnlimitedRecording => translate('feature_unlimited_recording');
  String get featureUnlimitedPhotos => translate('feature_unlimited_photos');
  String get featureAllWatermarks => translate('feature_all_watermarks');
  String get featureExtendedVideo => translate('feature_extended_video');
  String get featureAllHistory => translate('feature_all_history');
  String get featureFutureFeatures => translate('feature_future_features');
  String get trialDescription => translate('trial_description');
  String get trialButton => translate('trial_button');
  String get trialPrice => translate('trial_price');
  String get privacyPolicy => translate('privacy_policy');
  String get userAgreement => translate('user_agreement');
  String get restorePurchases => translate('restore_purchases');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
