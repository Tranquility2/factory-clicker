import 'resource_type.dart';

enum BuildingCategory {
  mining,
  smelting,
  assembling,
  researchLab,
  rocketSilo;
}

enum BuildingType {
  burnerMiner(
    id: 'burner_miner',
    name: 'Burner Mining Drill',
    description: 'Drills raw ore deposits using coal fuel.',
    category: BuildingCategory.mining,
    baseCost: {ResourceType.ironPlate: 5, ResourceType.stone: 5},
    costMultiplier: 1.15,
    craftSpeed: 0.5,
    icon: '⛏️',
  ),
  electricMiner(
    id: 'electric_miner',
    name: 'Electric Mining Drill',
    description: 'High-speed automated mining drill.',
    category: BuildingCategory.mining,
    baseCost: {ResourceType.ironPlate: 15, ResourceType.ironGear: 5, ResourceType.electronicCircuit: 3},
    costMultiplier: 1.2,
    craftSpeed: 1.5,
    icon: '⚡',
  ),
  stoneFurnace(
    id: 'stone_furnace',
    name: 'Stone Furnace',
    description: 'Smelts ores into plates using coal.',
    category: BuildingCategory.smelting,
    baseCost: {ResourceType.stone: 10},
    costMultiplier: 1.15,
    craftSpeed: 1.0,
    icon: '🔥',
  ),
  steelFurnace(
    id: 'steel_furnace',
    name: 'Steel Furnace',
    description: 'High-temperature industrial smelting unit.',
    category: BuildingCategory.smelting,
    baseCost: {ResourceType.steelPlate: 10, ResourceType.stone: 20},
    costMultiplier: 1.2,
    craftSpeed: 2.0,
    icon: '🏭',
  ),
  assembler1(
    id: 'assembler_1',
    name: 'Assembling Machine 1',
    description: 'Automates component crafting recipes.',
    category: BuildingCategory.assembling,
    baseCost: {ResourceType.ironPlate: 10, ResourceType.ironGear: 5, ResourceType.electronicCircuit: 3},
    costMultiplier: 1.18,
    craftSpeed: 0.75,
    icon: '🛠️',
  ),
  assembler2(
    id: 'assembler_2',
    name: 'Assembling Machine 2',
    description: 'Advanced fast automated manufacturing.',
    category: BuildingCategory.assembling,
    baseCost: {ResourceType.steelPlate: 10, ResourceType.ironGear: 10, ResourceType.electronicCircuit: 10},
    costMultiplier: 1.25,
    craftSpeed: 1.5,
    icon: '⚙️',
  ),
  researchLab(
    id: 'research_lab',
    name: 'Research Lab',
    description: 'Consumes science packs to unlock new technologies.',
    category: BuildingCategory.researchLab,
    baseCost: {ResourceType.ironPlate: 10, ResourceType.ironGear: 10, ResourceType.electronicCircuit: 5},
    costMultiplier: 1.25,
    craftSpeed: 1.0,
    icon: '🔬',
  ),
  rocketSilo(
    id: 'rocket_silo',
    name: 'Rocket Silo',
    description: 'Builds and launches orbital rockets for prestige Space Science.',
    category: BuildingCategory.rocketSilo,
    baseCost: {ResourceType.steelPlate: 200, ResourceType.electronicCircuit: 200, ResourceType.stone: 500},
    costMultiplier: 2.0,
    craftSpeed: 1.0,
    icon: '🚀',
  );

  final String id;
  final String name;
  final String description;
  final BuildingCategory category;
  final Map<ResourceType, int> baseCost;
  final double costMultiplier;
  final double craftSpeed;
  final String icon;

  const BuildingType({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.baseCost,
    required this.costMultiplier,
    required this.craftSpeed,
    required this.icon,
  });

  Map<ResourceType, int> costForCount(int currentCount) {
    final factor = currentCount > 0 ? (costMultiplier == 1.0 ? 1.0 : (costMultiplier * currentCount)) : 1.0;
    
    return baseCost.map((resource, baseAmount) {
      final calculated = (baseAmount * (currentCount == 0 ? 1.0 : (factor * 1.1))).round();
      return MapEntry(resource, calculated < baseAmount ? baseAmount : calculated);
    });
  }
}

class BuildingState {
  final BuildingType type;
  int count;
  String? activeRecipeId;
  ResourceType? targetResource; // For miners: coal, ironOre, copperOre, stone
  double currentProgressTicks;

  BuildingState({
    required this.type,
    this.count = 0,
    this.activeRecipeId,
    this.targetResource,
    this.currentProgressTicks = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'count': count,
    'activeRecipeId': activeRecipeId,
    'targetResource': targetResource?.name,
    'currentProgressTicks': currentProgressTicks,
  };

  factory BuildingState.fromJson(Map<String, dynamic> json) {
    final type = BuildingType.values.firstWhere(
      (b) => b.name == json['type'],
      orElse: () => BuildingType.burnerMiner,
    );
    return BuildingState(
      type: type,
      count: json['count'] as int? ?? 0,
      activeRecipeId: json['activeRecipeId'] as String?,
      targetResource: json['targetResource'] != null
          ? ResourceType.fromName(json['targetResource'] as String)
          : null,
      currentProgressTicks: (json['currentProgressTicks'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
