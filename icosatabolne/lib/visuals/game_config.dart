class GameVib3Config {
  final String system;
  final int geometry;
  final int gridDensity;
  final bool audioReactive;

  const GameVib3Config({
    this.system = 'quantum',
    this.geometry = 0,
    this.gridDensity = 32,
    this.audioReactive = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameVib3Config &&
          runtimeType == other.runtimeType &&
          system == other.system &&
          geometry == other.geometry &&
          gridDensity == other.gridDensity &&
          audioReactive == other.audioReactive;

  @override
  int get hashCode =>
      system.hashCode ^
      geometry.hashCode ^
      gridDensity.hashCode ^
      audioReactive.hashCode;
}
