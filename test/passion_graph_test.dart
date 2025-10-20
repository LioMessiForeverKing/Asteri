import 'package:flutter_test/flutter_test.dart';
import 'package:takeapp/models/passion_graph.dart';

void main() {
  test('node radius scales with weight bounds', () {
    final n1 = PassionNode(
      id: 'a',
      label: 'AI',
      weight: 0,
      colorSeed: 10,
      x: 0,
      y: 0,
    );
    final n2 = PassionNode(
      id: 'b',
      label: 'Music',
      weight: 1,
      colorSeed: 20,
      x: 0,
      y: 0,
    );
    expect(n1.radius < n2.radius, true);
  });

  test('snapshot serialization roundtrip', () {
    final snap = GraphSnapshot(
      nodes: [
        PassionNode(
          id: 'a',
          label: 'Tech',
          weight: 0.7,
          colorSeed: 1,
          x: 10,
          y: 20,
        ),
        PassionNode(
          id: 'b',
          label: 'Art',
          weight: 0.4,
          colorSeed: 2,
          x: -10,
          y: -5,
        ),
      ],
      edges: [GraphEdge(sourceId: 'a', targetId: 'b', weight: 0.5)],
    );
    final json = snap.toJson();
    final back = GraphSnapshot.fromJson(json);
    expect(back.nodes.length, 2);
    expect(back.edges.length, 1);
  });
}
