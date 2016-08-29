
class DelayedEvac_X2TargetingMethod_EvacZone extends X2TargetingMethod_EvacZone;

static function bool ValidateEvacArea( const out TTile EvacCenterLoc, bool IncludeSoldiers )
{
	local TTile EvacMin, EvacMax, TestTile;
	local int NumTiles, NumValidTiles;
	local int IsOnFloor;

	class'XComGameState_EvacZone'.static.GetEvacMinMax2D( EvacCenterLoc, EvacMin, EvacMax );

	if( IncludeSoldiers && EvacZoneContainsXComUnit(EvacMin, EvacMax) )
	{
		return false;
	}

	NumTiles = (EvacMax.X - EvacMin.X + 1) * (EvacMax.Y - EvacMin.Y + 1);

	TestTile = EvacMin;
	while (TestTile.X <= EvacMax.X)
	{
		while (TestTile.Y <= EvacMax.Y)
		{
			if (ValidateEvacTile( TestTile, IsOnFloor ))
			{
				NumValidTiles++;
			}
			else if(IsOnFloor == 0)
			{
				return false; // we can't have the evac zone floating in the air
			}

			TestTile.Y++;
		}

		TestTile.Y = EvacMin.Y;
		TestTile.X++;
	}

	return (NumValidTiles / float( NumTiles )) >= default.NeededValidTileCoverage;
}


function Update(float DeltaTime)
{
	local vector LastTargetLocation;
	local array<Actor> CurrentlyMarkedTargets;
	local array<TTile> Tiles;

	LastTargetLocation = CachedTargetLocation;
	super.Update(DeltaTime);

	if(LastTargetLocation != CachedTargetLocation)
	{
		GetTargetedActors(CachedTargetLocation, CurrentlyMarkedTargets, Tiles);
		DrawAOETiles(Tiles);
	}
}

function Canceled()
{
	super.Canceled();
	AOEMeshActor.Destroy();
}
