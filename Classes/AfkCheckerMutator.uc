Class AfkCheckerMutator extends KFMutator;

function AddMutator(Mutator m)
{
	if (m.Class == Class)
	{
		if (m != Self)
		{
			m.Destroy();
		}
	}
	else
	{
		Super.AddMutator(m);
	}
}

function NotifyLogin(Controller newPlayer)
{
	Spawn(class 'AfkChecker', newPlayer);
	if (NextMutator != None)
	{
		NextMutator.NotifyLogin(newPlayer);
	}
}