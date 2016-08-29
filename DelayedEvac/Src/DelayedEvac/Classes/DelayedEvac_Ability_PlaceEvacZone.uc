
class DelayedEvac_Ability_PlaceEvacZone extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(PlaceEvacZone());
	`log("DelayedEvac :: Load PlaceEvacZone");
	return Templates;
}

static function X2AbilityTemplate PlaceEvacZone()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityCooldown_Global          Cooldown;
	local X2AbilityTarget_Cursor            CursorTarget;
	local X2AbilityMultiTarget_Radius RadiusMultiTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PlaceEvacZone');

	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); // Do not allow "Evac Zone Placement" in MP!

	Template.Hostility = eHostility_Neutral;
	Template.bCommanderAbility = true;
	Template.ConcealmentRule = eConceal_Never;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PLACE_EVAC_PRIORITY;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_evac";
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	if (class'DelayedEvac_GameState_EvacZoneSpawner'.default.ExclusionRadius > 0)
	{
		RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
		RadiusMultiTarget.fTargetRadius = class'DelayedEvac_GameState_EvacZoneSpawner'.default.ExclusionRadius * 1.5; // convert tiles to meters
		RadiusMultiTarget.bIgnoreBlockingCover = true;
		RadiusMultiTarget.bExcludeSelfAsTargetIfWithinRadius = true;
		Template.AbilityMultiTargetStyle = RadiusMultiTarget;
	}

	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;
	Template.TargetingMethod = class'DelayedEvac_X2TargetingMethod_EvacZone';

	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_Global';
	Cooldown.iNumTurns = class'DelayedEvac_GameState_EvacZoneSpawner'.default.EvacCallCooldownTurns;
	Template.AbilityCooldown = Cooldown;

	Template.BuildNewGameStateFn = PlaceEvacZone_BuildGameState;
	Template.BuildVisualizationFn = PlaceEvacZone_BuildVisualization;

	return Template;
}


simulated function XComGameState PlaceEvacZone_BuildGameState( XComGameStateContext Context )
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;	
	local XComGameState_Ability AbilityState;	
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameStateHistory History;


	History = `XCOMHISTORY;
	//Build the new game state frame
	NewGameState = History.CreateNewGameState(true, Context);	

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());	
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID, eReturnType_Reference));	
	AbilityTemplate = AbilityState.GetMyTemplate();

	UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));
	//Apply the cost of the ability
	AbilityTemplate.ApplyCost(AbilityContext, AbilityState, UnitState, none, NewGameState);
	NewGameState.AddStateObject(UnitState);

	`assert(AbilityContext.InputContext.TargetLocations.Length == 1);
	class'DelayedEvac_GameState_EvacZoneSpawner'.static.PlaceEvacZoneSpawner(
		NewGameState, AbilityContext.InputContext.TargetLocations[0], UnitState.GetTeam()
	);

	//Return the game state we have created
	return NewGameState;	
}

simulated function PlaceEvacZone_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack Track;
	local DelayedEvac_GameState_EvacZoneSpawner EvacState;
	local X2Action_CameraLookAt CameraAction;

	foreach VisualizeGameState.IterateByClassType(class'DelayedEvac_GameState_EvacZoneSpawner', EvacState)
	{
		break;
	}
	`assert(EvacState != none);

	CameraAction = class'WorldInfo'.static.GetWorldInfo().Spawn(class'X2Action_CameraLookAt');

	Track.StateObject_NewState = EvacState;
	Track.StateObject_OldState = EvacState;
	Track.TrackActor = `BATTLE;
	class'X2Action_CameraLookAt'.static.AddActionToVisualizationTrack(CameraAction, Track, VisualizeGameState.GetContext());
	CameraAction.LookAtLocation = EvacState.CenterLocationV;
	CameraAction.LookAtDuration = 1.0;
	CameraAction.SnapToFloor = true;

	OutVisualizationTracks.AddItem(Track);
	EvacState.BuildVisualizationForSpawnerCreation(VisualizeGameState, OutVisualizationTracks);
}