class RideScores {
  final double price;
  final double eta;
  final double duration;
  final double safety;
  final double comfort;
  final double reliability;

  const RideScores({
    required this.price,
    required this.eta,
    required this.duration,
    required this.safety,
    required this.comfort,
    required this.reliability,
  });

  Map<String, dynamic> toJson() => {
    'price': price,
    'eta': eta,
    'duration': duration,
    'safety': safety,
    'comfort': comfort,
    'reliability': reliability,
  };

  factory RideScores.fromJson(Map<String, dynamic> json) {
    return RideScores(
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      eta: (json['eta'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      safety: (json['safety'] as num?)?.toDouble() ?? 0.0,
      comfort: (json['comfort'] as num?)?.toDouble() ?? 0.0,
      reliability: (json['reliability'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RideScoreWeights {
  final double price;
  final double eta;
  final double duration;
  final double safety;
  final double comfort;
  final double reliability;

  const RideScoreWeights({
    required this.price,
    required this.eta,
    required this.duration,
    required this.safety,
    required this.comfort,
    required this.reliability,
  });

  Map<String, dynamic> toJson() => {
    'price': price,
    'eta': eta,
    'duration': duration,
    'safety': safety,
    'comfort': comfort,
    'reliability': reliability,
  };

  factory RideScoreWeights.fromJson(Map<String, dynamic> json) {
    return RideScoreWeights(
      price: (json['price'] as num?)?.toDouble() ?? 0.25,
      eta: (json['eta'] as num?)?.toDouble() ?? 0.20,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.15,
      safety: (json['safety'] as num?)?.toDouble() ?? 0.15,
      comfort: (json['comfort'] as num?)?.toDouble() ?? 0.15,
      reliability: (json['reliability'] as num?)?.toDouble() ?? 0.10,
    );
  }
}

class ScoreExplanationFactor {
  final String name;
  final double score;
  final double weight;
  final double contribution;

  const ScoreExplanationFactor({
    required this.name,
    required this.score,
    required this.weight,
    required this.contribution,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'weight': weight,
    'contribution': contribution,
  };
}

class ScoreExplanation {
  final String summary;
  final String strongestFactor;
  final double strongestFactorScore;
  final Map<String, ScoreExplanationFactor> factors;

  const ScoreExplanation({
    required this.summary,
    required this.strongestFactor,
    required this.strongestFactorScore,
    required this.factors,
  });

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'strongestFactor': strongestFactor,
    'strongestFactorScore': strongestFactorScore,
    'factors': factors.map((k, v) => MapEntry(k, v.toJson())),
  };
}

class Ride {
  final String id;
  final String provider; // 'Uber' | 'Ola'
  final String category; // 'Auto' | 'Mini' | 'Sedan' | 'XL'
  final String vehicleCategory;
  final int capacity;
  final double fare;
  final int eta;
  final int duration;
  final double comfort;
  final double reliability;
  final double safety;
  final double karoScore;
  final String dataSource; // 'real_api' | 'demo_estimate'
  final RideScores? scores;
  final RideScoreWeights? scoreWeights;
  final ScoreExplanation? explanation;
  final List<String> highlights;

  const Ride({
    required this.id,
    required this.provider,
    required this.category,
    this.vehicleCategory = 'Mini',
    this.capacity = 4,
    required this.fare,
    required this.eta,
    required this.duration,
    required this.comfort,
    required this.reliability,
    required this.safety,
    required this.karoScore,
    this.dataSource = 'demo_estimate',
    this.scores,
    this.scoreWeights,
    this.explanation,
    this.highlights = const [],
  });

  Ride copyWith({
    double? karoScore,
    RideScores? scores,
    RideScoreWeights? scoreWeights,
    ScoreExplanation? explanation,
    List<String>? highlights,
  }) {
    return Ride(
      id: id,
      provider: provider,
      category: category,
      vehicleCategory: vehicleCategory,
      capacity: capacity,
      fare: fare,
      eta: eta,
      duration: duration,
      comfort: comfort,
      reliability: reliability,
      safety: safety,
      karoScore: karoScore ?? this.karoScore,
      dataSource: dataSource,
      scores: scores ?? this.scores,
      scoreWeights: scoreWeights ?? this.scoreWeights,
      explanation: explanation ?? this.explanation,
      highlights: highlights ?? this.highlights,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider,
    'category': category,
    'vehicleCategory': vehicleCategory,
    'capacity': capacity,
    'fare': fare,
    'eta': eta,
    'duration': duration,
    'comfort': comfort,
    'reliability': reliability,
    'safety': safety,
    'karoScore': karoScore,
    'dataSource': dataSource,
    'scores': scores?.toJson(),
    'scoreWeights': scoreWeights?.toJson(),
    'explanation': explanation?.toJson(),
    'highlights': highlights,
  };

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String? ?? 'ride-${DateTime.now().millisecondsSinceEpoch}',
      provider: json['provider'] as String? ?? 'Uber',
      category: json['category'] as String? ?? 'Mini',
      vehicleCategory: json['vehicleCategory'] as String? ?? 'Mini',
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      eta: (json['eta'] as num?)?.toInt() ?? 5,
      duration: (json['duration'] as num?)?.toInt() ?? 15,
      comfort: (json['comfort'] as num?)?.toDouble() ?? 75.0,
      reliability: (json['reliability'] as num?)?.toDouble() ?? 80.0,
      safety: (json['safety'] as num?)?.toDouble() ?? 85.0,
      karoScore: (json['karoScore'] as num?)?.toDouble() ?? 0.0,
      dataSource: json['dataSource'] as String? ?? 'demo_estimate',
      scores: json['scores'] != null ? RideScores.fromJson(json['scores']) : null,
      scoreWeights: json['scoreWeights'] != null ? RideScoreWeights.fromJson(json['scoreWeights']) : null,
      highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
