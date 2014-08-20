package org.cybernath.cru.services
{
	import flash.events.Event;
	
	public class CommEvent extends Event
	{
		public static const CRU_MESSAGE_RECEIVED:String = 'cruMessageReceived';
		public static const CRU_COMMS_UP:String = 'cruCommsUp';
		public static const CRU_COMMS_DOWN:String = 'cruCommsDown';
		public static const CRU_COMMS_EVENT:String = 'cruCommsEvent';
		
		
		public var message:CRUMessage;
		
		public var value:String;
		
		
		
		public function CommEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}