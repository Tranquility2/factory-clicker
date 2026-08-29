# Game overview

Factory Clicker is an incremental automation game inspired by factory-building
and clicker games. The player begins by gathering resources manually and
gradually replaces manual work with connected production lines.

## Progression

The production chain advances through five stages:

1. **Extraction** - Coal, Iron Ore, Copper Ore, and Stone.
2. **Smelting** - Iron Plates, Copper Plates, and Steel Plates.
3. **Components** - Copper Wire, Iron Gears, and Electronic Circuits.
4. **Science** - Automation Science, Logistic Science, and technologies.
5. **Launch** - Rocket Parts, rocket launches, and Space Science.

## Manual extraction

Coal, Iron Ore, Copper Ore, and Stone can always be gathered manually. Each
click grants one unit and displays impact, particle, and floating-gain
feedback.

Manual crafting turns early resources into the parts required to buy the first
machines and Research Lab.

## Machine allocation

Owned machines are allocated rather than configured as one indivisible group.
For example, ten Burner Mining Drills can be divided between Coal and Iron Ore.
Furnaces and assemblers can likewise be divided between their unlocked
recipes.

An allocation cannot exceed the number of owned machines. Unassigned machines
remain idle.

Burner Mining Drills consume Coal as fuel. A sustainable early Iron Plate line
therefore needs both:

- miners allocated to Coal and Iron Ore; and
- furnaces allocated to the Iron Plate recipe.

Machine cards report current throughput and identify missing inputs. In the
factory topology, active belts glow and carry resource packets. Belts connected
to idle or starved machines remain dim and static.

## Research

A Research Lab can be built before any technology is unlocked. Select one
technology at a time from the Research screen. Labs consume the listed
materials over the duration of the research.

Research pauses when a required resource is missing and resumes automatically
when the resource becomes available. The interface identifies the missing
resource and preserves progress.

The technology path is:

1. Automation I
2. Electronics and Steel Processing
3. Logistic Science
4. Rocketry and Space Silo

## Rocket prestige

The Rocket Silo converts Steel Plates, Electronic Circuits, and Iron Gears into
Rocket Parts. Production stops at 100 parts to avoid wasting materials.

Launching a completed rocket:

- plays an ignition and launch sequence;
- resets terrestrial inventory and machines;
- preserves unlocked technologies and lifetime clicks;
- grants 50 Space Science; and
- increases the permanent global production multiplier.

## Saves

The game saves automatically every ten seconds using local platform storage.
The Settings screen can save immediately, copy a JSON backup, import a backup,
or permanently reset all progress after confirmation.
