class NoiseRecord {
  final String id;
  String name;
  final DateTime createdAt;
  final int durationSeconds;
  final String deviceInfo;
  final String location;
  String notes;
  final String frequencyWeighting;
  final int responseTimeMs;
  final double calibration;
  final double maxDecibel;
  final double minDecibel;
  final double avgDecibel;
  final double peakValue;
  final List<double> waveformData;
  final String? audioFilePath;

  NoiseRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.durationSeconds,
    this.deviceInfo = '',
    this.location = '',
    this.notes = '',
    this.frequencyWeighting = 'A',
    this.responseTimeMs = 500,
    this.calibration = 0.0,
    required this.maxDecibel,
    required this.minDecibel,
    required this.avgDecibel,
    required this.peakValue,
    required this.waveformData,
    this.audioFilePath,
  });

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return '${createdAt.year}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}:${createdAt.second.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'deviceInfo': deviceInfo,
      'location': location,
      'notes': notes,
      'frequencyWeighting': frequencyWeighting,
      'responseTimeMs': responseTimeMs,
      'calibration': calibration,
      'maxDecibel': maxDecibel,
      'minDecibel': minDecibel,
      'avgDecibel': avgDecibel,
      'peakValue': peakValue,
      'waveformData': waveformData.join(','),
      'audioFilePath': audioFilePath,
    };
  }

  factory NoiseRecord.fromMap(Map<String, dynamic> map) {
    return NoiseRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      durationSeconds: map['durationSeconds'] as int,
      deviceInfo: map['deviceInfo'] as String? ?? '',
      location: map['location'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      frequencyWeighting: map['frequencyWeighting'] as String? ?? 'A',
      responseTimeMs: map['responseTimeMs'] as int? ?? 500,
      calibration: (map['calibration'] as num?)?.toDouble() ?? 0.0,
      maxDecibel: (map['maxDecibel'] as num).toDouble(),
      minDecibel: (map['minDecibel'] as num).toDouble(),
      avgDecibel: (map['avgDecibel'] as num).toDouble(),
      peakValue: (map['peakValue'] as num).toDouble(),
      waveformData: (map['waveformData'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => double.parse(s))
          .toList(),
      audioFilePath: map['audioFilePath'] as String?,
    );
  }
}
