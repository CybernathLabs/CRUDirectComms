package org.cybernath.cru.services
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	
	[Event(name="cruMessageReceived", type="org.cybernath.cru.services.CommEvent")]
	public class CRUServer extends EventDispatcher
	{
		private static var _instance:CRUServer;
		private var _socket:ServerSocket;
		private var _clients:Array = [];
		
		public function CRUServer(caller:Function)
		{
			super();
			if (caller != preventCreation) {
				throw new Error("Creation of CRUServer without calling getInstance() is not valid");
			}
			init();
		}
		
		private static function preventCreation():void{};
		
		public static function getInstance():CRUServer
		{
			if(!_instance)
			{
				_instance = new CRUServer(preventCreation);
			}
			
			return _instance;
		}
		
		
		public function init():void{
			if(!ServerSocket.isSupported){
				trace("ServerSocket not supported.");
				return;
			}
			
			_socket = new ServerSocket();
			_socket.addEventListener(ServerSocketConnectEvent.CONNECT,onConnect);
			_socket.addEventListener(Event.CLOSE,onSocketClose);
			
			_socket.bind(8888);
			_socket.listen();
			trace("listening on " + _socket.localAddress + ":" + _socket.localPort);
			
		}
		
		private function onSocketClose(event:Event):void
		{
			trace("socket closed");
			
		}
		
		private function onConnect(event:ServerSocketConnectEvent):void
		{
			var sock:Socket = event.socket;
			_clients.push(sock);
			trace("socket connection from " + sock.remoteAddress + ":" + sock.remotePort);
			sock.addEventListener( ProgressEvent.SOCKET_DATA, onSocketData );
			sock.addEventListener( Event.CLOSE,onClientClose);
			sock.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
			
			var msg:CRUMessage = new CRUMessage();
			msg.type = CRUMessage.CRU_CONNECTED;
			msg.value = "Welcome!";
			postMessage(msg);
			
			var evt:CommEvent = new CommEvent(CommEvent.CRU_COMMS_EVENT);
			evt.value = _clients.length + " Clients Connected";
			dispatchEvent(evt);
		}		
		
		private function onIOError(event:IOErrorEvent):void
		{
			trace("IOError:" + event.text);		
			var evt:CommEvent = new CommEvent(CommEvent.CRU_COMMS_EVENT);
			evt.value = _clients.length + " Clients Connected";
			dispatchEvent(evt);
		}
		
		private function onClientClose(event:Event):void
		{
			var s:Socket = event.target as Socket;
			trace("closing connection from " + s.remoteAddress + ":" + s.remotePort);
			s.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			s.removeEventListener( Event.CLOSE,onClientClose);
			s.removeEventListener(IOErrorEvent.IO_ERROR, onIOError );
			_clients.splice(_clients.indexOf(s),1);
			
			var evt:CommEvent = new CommEvent(CommEvent.CRU_COMMS_EVENT);
			evt.value = _clients.length + " Clients Connected";
			dispatchEvent(evt);
		}
		
		private function onSocketData(evt:ProgressEvent):void
		{
			var s:Socket = evt.currentTarget as Socket;
			
			var msg:CRUMessage = new CRUMessage(s.readObject());
			
			trace("SocketData (" + s.bytesAvailable + "): "+ msg.type + " - " + msg.value);
			
			var event:CommEvent = new CommEvent(CommEvent.CRU_MESSAGE_RECEIVED);
			event.message = msg; 
			dispatchEvent(event);
			
		}
		
		public function postMessage(msg:CRUMessage):void{
			for each(var s:Socket in _clients){
				s.writeObject(msg.messageObject);
				s.flush();
			}
		}
		
		public function sendString(txt:String):void{
			var msg:CRUMessage = new CRUMessage();
			msg.type = CRUMessage.CRU_EVENT;
			msg.value = txt;
			postMessage(msg);
		}
		
	}
}