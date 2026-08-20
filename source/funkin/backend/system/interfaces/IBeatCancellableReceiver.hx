package funkin.backend.system.interfaces;

interface IBeatCancellableReceiver extends IBeatReceiver
{
	/**
	 * A conductor that defaults to `Conductor.instance` if null
	 */
	public var conductor(get, set):Conductor;

	public var cancelConductorUpdate:Bool;
}
