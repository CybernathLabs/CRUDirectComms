package org.cybernath.cru.services
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	
	[Event(name="cruMessageReceived", type="org.cybernath.cru.services.CommEvent")]
	public class CRUClient extends EventDispatcher
	{
		private var _socket:Socket;
		private static var _instance:CRUClient;
		
		public function CRUClient(caller:Function)
		{
			super();
			if (caller != preventCreation) {
				throw new Error("Creation of CRUClient without calling getInstance() is not valid");
			}
			init();
		}
		
		private static function preventCreation():void{};
		
		public static function getInstance():CRUClient
		{
			if(!_instance)
			{
				_instance = new CRUClient(preventCreation);
			}
			
			return _instance;
		}
		
		private function init():void{
			_socket = new Socket();
			_socket.timeout = 5000;
		}
		
		public function connect(host:String,port:int):void{
			if(_socket.connected){
				_socket.close();
			}
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			_socket.addEventListener(IOErrorEvent.IO_ERROR,onSocketFail);
			_socket.addEventListener(Event.CLOSE,onSocketFail);
			_socket.addEventListener(Event.CONNECT,onSocketConnect);
			_socket.connect(host,port);
		}
		
		private function onSocketConnect(event:Event):void
		{
			var evt:CommEvent = new CommEvent(CommEvent.CRU_COMMS_UP);
			this.dispatchEvent(evt);
		}
		
		private function onSocketFail(event:Event):void
		{
			var evt:CommEvent = new CommEvent(CommEvent.CRU_COMMS_DOWN);
			this.dispatchEvent(evt);
		}
		
		private function onSocketData(evt:ProgressEvent):void
		{
			var msg:CRUMessage = new CRUMessage(_socket.readObject());
			switch(msg.type){
				case CRUMessage.CRU_CONNECTED:
					trace("CRUClient - Connected to server.");
					break;
				default:
					trace("Client Message Received:" + msg.type + " - " + msg.value);
					var event:CommEvent = new CommEvent(CommEvent.CRU_MESSAGE_RECEIVED);
					event.message = msg
					dispatchEvent(event);
					break;
			}
			
		}
		
		public function postMessage(msg:CRUMessage):void{
				_socket.writeObject(msg.messageObject);
				_socket.flush();
		}
		
		public function sendString(txt:String):void{
			var msg:CRUMessage = new CRUMessage();
			msg.type = CRUMessage.CRU_EVENT;
			msg.value = txt;
			postMessage(msg);
		}
		
		public function get connected():Boolean{
			return _socket.connected;
		}
	}
}