//=============================================================================
// Afk Checker
// Determine if player is AFK - Warn and then kick
// Adapted from Marco's Hard Mode Boss mutator
//=============================================================================
class AfkChecker extends Info;

struct PrevState
{
	var Vector prevLocation;
	var Rotator prevRotation;
};

var Controller PlayerOwner;
var PlayerController PCOwner;
var PrevState pState;
var transient float endTime;
const timeout = 10.f; // Seconds of AFK before kick

function PostBeginPlay()
{
	`log("AFK Checker");
	PlayerOwner = Controller(Owner);
	PCOwner = PlayerController(Owner);
	if (PlayerOwner == None)
	{
		`log("AFK Checker Destroy");
		Destroy();
	}
	else
	{
		pState.prevLocation = PCOwner.Pawn.Location;
		pState.prevRotation = PCOwner.Pawn.Rotation;
		`log("Init " $ pState.prevLocation $ " " $ pState.prevRotation);
	}
}

auto state CheckAFK
{
	// A player is considered AFK if they are not moving or looking around
	final function bool isAFK()
	{
		return (PlayerOwner.Pawn.Location == pState.prevLocation
			|| PlayerOwner.Pawn.Rotation == pState.prevRotation);
	}

	final function updateState()
	{
		pState.prevLocation = PlayerOwner.Pawn.Location;
		pState.prevRotation = PlayerOwner.Pawn.Rotation;
	}

Begin:
	// Wait a little when the player first spawns in
	Sleep(10.f+FRand()*15.f);
	if (PlayerOwner == None)
		Destroy();
Loop:
	// Pause AFK checks while players cant play
	if (PlayerOwner.Pawn != None && 
		PlayerOwner.Pawn.IsAliveAndWell() && 
		!PlayerOwner.Pawn.IsA('KFPawn_Monster') && 
		!KFGameInfo(WorldInfo.Game).MyKFGRI.bTraderIsOpen && 
		KFGameInfo(WorldInfo.Game).MyKFGRI.bMatchHasBegun && 
		!KFGameInfo(WorldInfo.Game).MyKFGRI.bMatchIsOver)
	{
		if (isAFK())
		{
			endTime = WorldInfo.TimeSeconds + timeout;
			KFPlayerController(PCOwner).MyGFxHUD.DisplayPriorityMessage("You are AFK", "", 4.f);
			while (isAFK())
			{
				updateState();
				// PCOwner.ClientMessage((endTime - WorldInfo.TimeSeconds)  $ " seconds till kick", 'LowCriticalEvent');
				KFPlayerController(PCOwner).MyGFxHUD.ShowNonCriticalMessage(Round(endTime - WorldInfo.TimeSeconds)  $ " seconds till kick");
				if (endTime - WorldInfo.TimeSeconds <= 0)
				{
					WorldInfo.Game.KickIdler(PCOwner);
					break;
				}
				Sleep(1.f);
			}
		}

	updateState();
	}
	Sleep(1.f);
	GoTo'Loop';
}
