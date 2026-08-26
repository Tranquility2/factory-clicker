import 'resource_type.dart';

enum CraftingCategory {
  handCrafting,
  smelting,
  assembling,
  chemical,
  silo;
}

class Recipe {
  final String id;
  final String name;
  final String description;
  final CraftingCategory category;
  final Map<ResourceType, int> inputs;
  final Map<ResourceType, int> outputs;
  final int durationTicks; // 20 ticks = 1 second
  final String? requiredTechId;

  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.inputs,
    required this.outputs,
    required this.durationTicks,
    this.requiredTechId,
  });

  static const List<Recipe> all = [
    // Smelting
    Recipe(
      id: 'smelt_iron',
      name: 'Iron Plate',
      description: 'Smelts Iron Ore into usable Iron Plates.',
      category: CraftingCategory.smelting,
      inputs: {ResourceType.ironOre: 1, ResourceType.coal: 1},
      outputs: {ResourceType.ironPlate: 1},
      durationTicks: 20, // 1s
    ),
    Recipe(
      id: 'smelt_copper',
      name: 'Copper Plate',
      description: 'Smelts Copper Ore into Copper Plates.',
      category: CraftingCategory.smelting,
      inputs: {ResourceType.copperOre: 1, ResourceType.coal: 1},
      outputs: {ResourceType.copperPlate: 1},
      durationTicks: 20,
    ),
    Recipe(
      id: 'smelt_steel',
      name: 'Steel Plate',
      description: 'Refines Iron Plates into hardened Steel.',
      category: CraftingCategory.smelting,
      inputs: {ResourceType.ironPlate: 5, ResourceType.coal: 2},
      outputs: {ResourceType.steelPlate: 1},
      durationTicks: 60, // 3s
      requiredTechId: 'steel_processing',
    ),

    // Components & Assembling
    Recipe(
      id: 'craft_copper_wire',
      name: 'Copper Wire',
      description: 'Extrudes Copper Plates into cables.',
      category: CraftingCategory.assembling,
      inputs: {ResourceType.copperPlate: 1},
      outputs: {ResourceType.copperWire: 2},
      durationTicks: 10, // 0.5s
    ),
    Recipe(
      id: 'craft_iron_gear',
      name: 'Iron Gear Wheel',
      description: 'Cuts mechanical gear teeth from Iron Plates.',
      category: CraftingCategory.assembling,
      inputs: {ResourceType.ironPlate: 2},
      outputs: {ResourceType.ironGear: 1},
      durationTicks: 10,
    ),
    Recipe(
      id: 'craft_electronic_circuit',
      name: 'Electronic Circuit',
      description: 'Assembles basic logic micro-boards.',
      category: CraftingCategory.assembling,
      inputs: {ResourceType.ironPlate: 1, ResourceType.copperWire: 3},
      outputs: {ResourceType.electronicCircuit: 1},
      durationTicks: 20,
      requiredTechId: 'electronics',
    ),

    // Science Packs
    Recipe(
      id: 'craft_automation_science',
      name: 'Automation Science Pack',
      description: 'Red research pack synthesized from gears and copper.',
      category: CraftingCategory.assembling,
      inputs: {ResourceType.copperPlate: 1, ResourceType.ironGear: 1},
      outputs: {ResourceType.automationScience: 1},
      durationTicks: 40, // 2s
      requiredTechId: 'automation_1',
    ),
    Recipe(
      id: 'craft_logistic_science',
      name: 'Logistic Science Pack',
      description: 'Green research pack synthesized from circuits and gears.',
      category: CraftingCategory.assembling,
      inputs: {ResourceType.electronicCircuit: 1, ResourceType.ironGear: 1},
      outputs: {ResourceType.logisticScience: 1},
      durationTicks: 60, // 3s
      requiredTechId: 'logistic_science_tech',
    ),

    // Rocketry
    Recipe(
      id: 'craft_rocket_part',
      name: 'Rocket Part',
      description: 'Heavy structural rocket stage composite.',
      category: CraftingCategory.silo,
      inputs: {
        ResourceType.steelPlate: 10,
        ResourceType.electronicCircuit: 20,
        ResourceType.ironGear: 10,
      },
      outputs: {ResourceType.rocketPart: 1},
      durationTicks: 100, // 5s
      requiredTechId: 'rocketry',
    ),
  ];

  static Recipe? getById(String id) {
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
