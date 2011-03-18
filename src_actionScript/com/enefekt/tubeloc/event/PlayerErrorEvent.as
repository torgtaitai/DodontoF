/**
 Copyright 2009 Ben Longoria
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
package com.enefekt.tubeloc.event {
	import flash.events.Event;

	/**
	 * PlayerErrorEvent
	 *
	 * @author Ben Longoria enefekt@gmail.com
	 */
	public class PlayerErrorEvent extends Event {
		public static const ON_ERROR:String = "onError";
		public static const VIDEO_NOT_FOUND:Number = 100;
		public static const VIDEO_NO_EMBED:Number = 101;
		public static const PLAYER_WRAPPER_NOT_FOUND:Number = 300;
		public static const PLAYER_LOAD_ERROR:Number = 301;

		public var errorCode:Number;
		public var detail:String;

		public function PlayerErrorEvent(bubbles_p:Boolean = true, cancelable_p:Boolean = false) {
			super(ON_ERROR, bubbles_p, cancelable_p);
		}
		
		public override function clone():Event {
			var cloned:PlayerErrorEvent = new PlayerErrorEvent(bubbles, cancelable);
			cloned.errorCode = errorCode;
			return cloned;
		}
	}
}