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

const timeout = 15.f; // Seconds of AFK before kick
const warnTime = 10.f; // Seconds of AFK before warning

function PostBeginPlay()
{
	PlayerOwner = Controller(Owner);
	PCOwner = PlayerController(Owner);
	if (PlayerOwner == None)
	{
		Destroy();
	}
	else
	{
		pState.prevLocation = PCOwner.Pawn.Location;
		pState.prevRotation = PCOwner.Pawn.Rotation;
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

	final function bool playerShouldBeActive()
	{
		return PlayerOwner.Pawn != None && 
		PlayerOwner.Pawn.IsAliveAndWell() && 
		!PlayerOwner.Pawn.IsA('KFPawn_Monster') && 
		!KFGameInfo(WorldInfo.Game).MyKFGRI.bTraderIsOpen && 
		KFGameInfo(WorldInfo.Game).MyKFGRI.bMatchHasBegun && 
		!KFGameInfo(WorldInfo.Game).MyKFGRI.bMatchIsOver;
	}

Begin:
	// Wait a little when the player first spawns in
	Sleep(10.f+FRand()*15.f);
	if (PlayerOwner == None)
		Destroy();
Loop:
	// Pause AFK checks while players cant play
	if (playerShouldBeActive())
	{
		if (isAFK())
		{
			endTime = WorldInfo.TimeSeconds + timeout;
			while (isAFK() && playerShouldBeActive())
			{
				updateState();
				if (Round(endTime - WorldInfo.TimeSeconds) == Round(warnTime))
				{
					// Display big AFK notice when appropriate time left in AFK countdown
					KFPlayerController(PCOwner).MyGFxHUD.DisplayPriorityMessage("You are AFK", "", 4.f);
				}
				else if (endTime - WorldInfo.TimeSeconds < warnTime && endTime - WorldInfo.TimeSeconds > 0)
				{
					// Display countdown ticker after big flashy warning has appeared
					KFPlayerController(PCOwner).MyGFxHUD.ShowNonCriticalMessage(Round(endTime - WorldInfo.TimeSeconds)  $ " seconds till kick");
				}
				else if (endTime - WorldInfo.TimeSeconds <= 0)
				{
					// When time has run out, kick player
					WorldInfo.Game.KickIdler(PCOwner);
					// If normal kick method does not work consider having the client run the disconnect console command
					// ConsoleCommand("disconnect");
					break;
				}
				else
				{
					// Do nothing
				}
				Sleep(1.f);
			}
		}

		updateState();
	}
	Sleep(1.f);
	GoTo'Loop';
}
