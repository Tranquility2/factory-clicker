enum ResourceType {
  coal('Coal', 'Raw fuel source', '⬛', true),
  ironOre('Iron Ore', 'Raw metal deposit', '🩶', true),
  copperOre('Copper Ore', 'Raw conductive copper deposit', '🟤', true),
  stone('Stone', 'Basic mineral rock foundation', '🪨', true),
  ironPlate('Iron Plate', 'Smelted structural iron plate', '⬜', false),
  copperPlate('Copper Plate', 'Smelted electrical copper plate', '🟧', false),
  ironGear('Iron Gear', 'Mechanical component for machines', '⚙️', false),
  copperWire('Copper Wire', 'Fine conductive cabling', '🧵', false),
  electronicCircuit('Electronic Circuit', 'Basic logic controller board', '💾', false),
  steelPlate('Steel Plate', 'Reinforced hardened alloy', '🔩', false),
  automationScience('Automation Science', 'Red research data pack', '🧪', false),
  logisticScience('Logistic Science', 'Green research data pack', '⚗️', false),
  rocketPart('Rocket Part', 'High-density composite rocket stage', '🛰️', false),
  spaceScience('Space Science', 'Interplanetary research artifact', '🌌', false);

  final String label;
  final String description;
  final String icon;
  final bool isRaw;

  const ResourceType(this.label, this.description, this.icon, this.isRaw);

  static ResourceType fromName(String name) {
    return ResourceType.values.firstWhere(
      (r) => r.name == name,
      orElse: () => ResourceType.ironOre,
    );
  }
}
