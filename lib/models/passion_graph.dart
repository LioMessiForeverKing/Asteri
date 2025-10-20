import 'dart:math' as math;

class PassionNode {
  final String id;
  final String label;
  final double weight; // normalized 0..1
  final String? clusterTag;
  final int colorSeed;

  // Layout state
  double x;
  double y;
  double vx;
  double vy;

  PassionNode({
    required this.id,
    required this.label,
    required this.weight,
    this.clusterTag,
    required this.colorSeed,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
  });

  double get radius {
    final double minR = 10;
    final double maxR = 28;
    return minR + (maxR - minR) * weight.clamp(0, 1);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'weight': weight,
    'clusterTag': clusterTag,
    'colorSeed': colorSeed,
    'x': x,
    'y': y,
  };

  static PassionNode fromJson(Map<String, dynamic> json) {
    return PassionNode(
      id: json['id']?.toString() ?? 'n-${math.Random().nextInt(100000)}',
      label: json['label']?.toString() ?? 'Unknown',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
      clusterTag: json['clusterTag']?.toString(),
      colorSeed:
          (json['colorSeed'] as num?)?.toInt() ??
          math.Random().nextInt(1 << 31),
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GraphEdge {
  final String sourceId;
  final String targetId;
  final double weight; // similarity 0..1

  GraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.weight,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sourceId': sourceId,
    'targetId': targetId,
    'weight': weight,
  };

  static GraphEdge fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      sourceId: json['sourceId']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.3,
    );
  }
}

class GraphSnapshot {
  final List<PassionNode> nodes;
  final List<GraphEdge> edges;
  final DateTime createdAt;

  GraphSnapshot({required this.nodes, required this.edges, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => <String, dynamic>{
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  static GraphSnapshot fromJson(Map<String, dynamic> json) {
    final List<dynamic> nodeList =
        (json['nodes'] as List<dynamic>? ?? <dynamic>[]);
    final List<dynamic> edgeList =
        (json['edges'] as List<dynamic>? ?? <dynamic>[]);
    return GraphSnapshot(
      nodes: nodeList
          .map((e) => PassionNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      edges: edgeList
          .map((e) => GraphEdge.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
