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
	 * PlayerReadyEvent
	 *
	 * @author Ben Longoria enefekt@gmail.com
	 */
	public class PlayerReadyEvent extends Event {
		public static const PLAYER_READY:String = "onPlayerReady";

		public function PlayerReadyEvent(bubbles_p:Boolean = true, cancelable_p:Boolean = false) {
			super(PLAYER_READY, bubbles_p, cancelable_p);
		}
		
		public override function clone():Event {
			var cloned:PlayerReadyEvent = new PlayerReadyEvent(bubbles, cancelable);
			return cloned;
		}
	}
}