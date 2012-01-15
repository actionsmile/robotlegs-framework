//------------------------------------------------------------------------------
//  Copyright (c) 2011 the original author or authors. All Rights Reserved. 
// 
//  NOTICE: You are permitted to use, modify, and distribute this file 
//  in accordance with the terms of the license agreement accompanying it. 
//------------------------------------------------------------------------------

package robotlegs.bender.core.object.processor.impl
{
	import org.hamcrest.Description;
	import org.hamcrest.Matcher;
	import robotlegs.bender.core.async.safelyCallBack;
	import robotlegs.bender.core.message.dispatcher.api.IMessageDispatcher;
	import robotlegs.bender.core.message.dispatcher.impl.MessageDispatcher;
	import robotlegs.bender.core.object.processor.api.IObjectProcessor;

	public class ObjectProcessor implements IObjectProcessor
	{

		/*============================================================================*/
		/* Private Properties                                                         */
		/*============================================================================*/

		private const _handlers:Array = [];

		private var _messageDispatcher:IMessageDispatcher;

		/*============================================================================*/
		/* Constructor                                                                */
		/*============================================================================*/

		public function ObjectProcessor(messageDispatcher:IMessageDispatcher = null)
		{
			_messageDispatcher = messageDispatcher || new MessageDispatcher();
		}

		/*============================================================================*/
		/* Public Functions                                                           */
		/*============================================================================*/

		public function addObjectHandler(matcher:Matcher, handler:Function):void
		{
			_handlers.push(new ObjectHandler(matcher, handler));
		}

		public function addObject(object:Object, callback:Function = null):void
		{
			const matchingHandlers:Array = [];

			for each (var handler:ObjectHandler in _handlers)
			{
				if (handler.matcher.matches(object))
				{
					matchingHandlers.push(handler);
					_messageDispatcher.addMessageHandler(object, handler.closure);
				}
			}

			_messageDispatcher.dispatchMessage(object, function(error:Object):void {
				// even with oneShot handlers we would have to clean up here as
				// a handler may have terminated the dispatch with an error
				// and we don't want to leave any handlers lying around
				for each (var matchingHandler:ObjectHandler in matchingHandlers)
				{
					_messageDispatcher.removeMessageHandler(object, matchingHandler.closure);
				}
				callback && safelyCallBack(callback, error, object);
			});
		}

		public function matches(object:Object):Boolean
		{
			for each (var handler:ObjectHandler in _handlers)
			{
				if (handler.matcher.matches(object))
				{
					return true;
				}
			}
			return false;
		}

		public function describeTo(description:Description):void
		{
			description.appendText("object processor");
		}

		public function describeMismatch(item:Object, mismatchDescription:Description):void
		{
			mismatchDescription.appendText("was ").appendValue(item);
		}
	}
}
