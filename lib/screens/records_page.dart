import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/records_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/record_card.dart';
import 'record_detail_page.dart';
import 'pro_subscription_page.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final records = context.read<RecordsProvider>();
      if (!records.isLoaded) {
        records.loadRecords();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final records = context.watch<RecordsProvider>();
    final settings = context.watch<SettingsProvider>();
    final isPro = settings.isPro;
    final allRecords = records.records;

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  l10n.records,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: allRecords.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined,
                            color: Colors.grey, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noRecords,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    physics: !isPro && allRecords.length > 3 ?
                    NeverScrollableScrollPhysics():AlwaysScrollableScrollPhysics(),
                    itemCount: allRecords.length,
                    //allRecords.length + (!isPro && allRecords.length > 3 ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show unlock banner after 3rd item for non-pro
                      // if (!isPro && index == allRecords.length &&
                      //     allRecords.length >= 3) {
                      //   return _buildUnlockBanner(context, l10n);
                      // }

                      // if (!isPro && allRecords.length > 3 && index >= 3) {
                      //   // For items beyond 3, show locked state
                      //   if (index < allRecords.length) {
                      //     return Stack(
                      //       children: [
                      //         RecordCard(
                      //           record: allRecords[index],
                      //           isLocked: true,
                      //         ),
                      //         if (index == 3)
                      //           Positioned.fill(
                      //             child: Center(
                      //               child: Column(
                      //                 mainAxisAlignment:
                      //                     MainAxisAlignment.center,
                      //                 children: [
                      //                   Text(
                      //                     l10n.nonProLimit,
                      //                     style: const TextStyle(
                      //                       color: Colors.white,
                      //                       fontSize: 14,
                      //                       fontWeight: FontWeight.w500,
                      //                     ),
                      //                   ),
                      //                   const SizedBox(height: 12),
                      //                   ElevatedButton(
                      //                     onPressed: () =>
                      //                         _openProPage(context),
                      //                     style: ElevatedButton.styleFrom(
                      //                       backgroundColor:
                      //                           const Color(0xFF00E5CC),
                      //                       foregroundColor: Colors.black,
                      //                       shape: RoundedRectangleBorder(
                      //                         borderRadius:
                      //                             BorderRadius.circular(24),
                      //                       ),
                      //                       padding: const EdgeInsets
                      //                           .symmetric(
                      //                           horizontal: 32,
                      //                           vertical: 12),
                      //                     ),
                      //                     child: Text(
                      //                       l10n.unlockFree,
                      //                       style: const TextStyle(
                      //                         fontWeight: FontWeight.w600,
                      //                       ),
                      //                     ),
                      //                   ),
                      //                 ],
                      //               ),
                      //             ),
                      //           ),
                      //       ],
                      //     );
                      //   }
                      //   return const SizedBox.shrink();
                      // }

                      final record = allRecords[index];
                      return Dismissible(
                        key: Key(record.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) {
                          records.deleteRecord(record.id);
                        },
                        child: RecordCard(
                          record: record,
                          onTap: () {
                            if(!isPro && index >= 3) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecordDetailPage(record: record),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
              left: 0,
              right: 0,
              child: Visibility(
              visible: !isPro && allRecords.length > 3,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF00E5CC).withOpacity(0.5),
                        ]
                    )
                ),
                child: _buildUnlockBanner(context, l10n),
              )
          ))
        ],
      ),
    );
  }

  Widget _buildUnlockBanner(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _openProPage(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5CC),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
              ),
              child: Text(
                l10n.unlockFree,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.nonProLimit,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _openProPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProSubscriptionPage()),
    );
  }
}
