import 'resource_type.dart';

class Technology {
  final String id;
  final String name;
  final String description;
  final Map<ResourceType, int> cost;
  final int researchDurationTicks;
  final List<String> prerequisites;
  final List<String> unlockedRecipeIds;
  final List<String> unlockedBuildingIds;
  final String icon;

  const Technology({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.researchDurationTicks,
    this.prerequisites = const [],
    this.unlockedRecipeIds = const [],
    this.unlockedBuildingIds = const [],
    required this.icon,
  });

  static const List<Technology> all = [
    Technology(
      id: 'automation_1',
      name: 'Automation I',
      description: 'Enables automated component assembly and red science synthesis.',
      cost: {ResourceType.ironPlate: 10, ResourceType.copperPlate: 10},
      researchDurationTicks: 100, // 5s
      unlockedRecipeIds: ['craft_copper_wire', 'craft_iron_gear', 'craft_automation_science'],
      unlockedBuildingIds: ['assembler_1', 'iron_chest'],
      icon: '⚙️',
    ),
    Technology(
      id: 'electronics',
      name: 'Electronics',
      description: 'Unlocks micro-circuit fabrication for complex machinery.',
      cost: {ResourceType.automationScience: 10},
      researchDurationTicks: 200, // 10s
      prerequisites: ['automation_1'],
      unlockedRecipeIds: ['craft_electronic_circuit'],
      unlockedBuildingIds: ['electric_miner'],
      icon: '💾',
    ),
    Technology(
      id: 'steel_processing',
      name: 'Steel Processing',
      description: 'Enables high-temperature smelting of purified iron into structural steel.',
      cost: {ResourceType.automationScience: 20},
      researchDurationTicks: 300,
      prerequisites: ['automation_1'],
      unlockedRecipeIds: ['smelt_steel'],
      unlockedBuildingIds: ['steel_furnace', 'steel_chest'],
      icon: '🔩',
    ),
    Technology(
      id: 'logistic_science_tech',
      name: 'Logistic Science',
      description: 'Unlocks green research data packs for mid-tier automation.',
      cost: {ResourceType.automationScience: 30},
      researchDurationTicks: 400,
      prerequisites: ['electronics', 'steel_processing'],
      unlockedRecipeIds: ['craft_logistic_science'],
      unlockedBuildingIds: ['assembler_2'],
      icon: '⚗️',
    ),
    Technology(
      id: 'rocketry',
      name: 'Rocketry & Space Silo',
      description: 'Allows constructing the Rocket Silo to launch orbital satellites and harvest Space Science.',
      cost: {
        ResourceType.automationScience: 50,
        ResourceType.logisticScience: 50,
      },
      researchDurationTicks: 600,
      prerequisites: ['logistic_science_tech'],
      unlockedRecipeIds: ['craft_rocket_part'],
      unlockedBuildingIds: ['rocket_silo'],
      icon: '🚀',
    ),
  ];

  static Technology? getById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
