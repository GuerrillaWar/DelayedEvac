# Delayed Evac

Extracted from the Guerrilla War mod, this mod changes Evac Zones to be a little more risky.

First off, they have a delay to them, so you'll have to plan ahead. By default it takes two
turns for Firebrand to arrive.

Secondly, a change not preset in Guerrilla War, now the Evac Zone has an Exclusion Zone which
makes it possible for the enemy to block your Evac. If any enemies within that exclusion zone when
Firebrand arrives the Evac will be cancelled and you'll have to call it again.

The mod is entirely configurable so if you're not big on the Exclusion Zone, or think it's too big,
go ahead and change it. The config is as follows:

```
[DelayedEvac.DelayedEvac_GameState_EvacZoneSpawner]
EvacCountdownTurns=2
EvacCallCooldownTurns=5

; set ExclusionRadius to 0 to disable it
ExclusionRadius=10
```