import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import 'pro_subscription_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              l10n.settings,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Pro banner
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ProSubscriptionPage()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF00E5CC)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.proTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.freeTrial,
                        style: const TextStyle(
                          color: Color(0xFF00BCD4),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Response Frequency
            _SettingsCard(
              onTap: () => _showFrequencyPicker(context, settings),
              child: Row(
                children: [
                  Text(
                    l10n.responseFrequency,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    '${l10n.slow} ${settings.responseFrequencyMs}ms',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Auto Record
            _SettingsCard(
              child: Row(
                children: [
                  Text(
                    l10n.autoRecord,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  Switch(
                    value: settings.autoRecord,
                    onChanged: (val) => settings.setAutoRecord(val),
                    activeColor: const Color(0xFF4CD964),
                    // activeTrackColor: const Color(0xFF4CD964),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // About Us
            _SettingsCard(
              onTap: () => _showAboutDialog(context),
              child: Row(
                children: [
                  Text(
                    l10n.aboutUs,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Language selector
            _SettingsCard(
              onTap: () => _showLanguagePicker(context, settings),
              child: Row(
                children: [
                  const Text(
                    'Language / \u8bed\u8a00',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    _getLanguageLabel(settings.locale),
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageLabel(Locale locale) {
    if (locale.languageCode == 'en') return 'English';
    if (locale.countryCode == 'TW') return '\u7e41\u9ad4\u4e2d\u6587';
    return '\u7b80\u4f53\u4e2d\u6587';
  }

  void _showFrequencyPicker(
      BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Response Frequency',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _FrequencyOption(
                label: 'Fast 125ms',
                value: 125,
                selected: settings.responseFrequencyMs == 125,
                onTap: () {
                  settings.setResponseFrequencyMs(125);
                  Navigator.pop(context);
                },
              ),
              _FrequencyOption(
                label: 'Slow 500ms',
                value: 500,
                selected: settings.responseFrequencyMs == 500,
                onTap: () {
                  settings.setResponseFrequencyMs(500);
                  Navigator.pop(context);
                },
              ),
              _FrequencyOption(
                label: 'Slow 1000ms',
                value: 1000,
                selected: settings.responseFrequencyMs == 1000,
                onTap: () {
                  settings.setResponseFrequencyMs(1000);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker(
      BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Language / \u8bed\u8a00',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                label: 'English',
                locale: const Locale('en'),
                selected: settings.locale.languageCode == 'en',
                onTap: () {
                  settings.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              _LanguageOption(
                label: '\u7b80\u4f53\u4e2d\u6587',
                locale: const Locale('zh', 'CN'),
                selected: settings.locale.languageCode == 'zh' &&
                    settings.locale.countryCode != 'TW',
                onTap: () {
                  settings.setLocale(const Locale('zh', 'CN'));
                  Navigator.pop(context);
                },
              ),
              _LanguageOption(
                label: '\u7e41\u9ad4\u4e2d\u6587',
                locale: const Locale('zh', 'TW'),
                selected: settings.locale.countryCode == 'TW',
                onTap: () {
                  settings.setLocale(const Locale('zh', 'TW'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(l10n.aboutUsTitle,
            style: TextStyle(color: Colors.white)),
        content: Text(
          l10n.aboutUsContent,
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.aboutUsOk,
                style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SettingsCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _FrequencyOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF00BCD4) : Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFF00BCD4))
          : null,
      onTap: onTap,
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final Locale locale;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF00BCD4) : Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFF00BCD4))
          : null,
      onTap: onTap,
    );
  }
}
