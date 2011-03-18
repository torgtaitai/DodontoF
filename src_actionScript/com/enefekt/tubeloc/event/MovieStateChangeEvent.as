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
	 * State Change Event
	 *
	 * @author Ben Longoria enefekt@gmail.com
	 */
	public class MovieStateChangeEvent extends Event {
		public static const ON_STATE_CHANGE:String = "onStateChange";
		public static const UNSTARTED:Number = -1;
		public static const ENDED:Number = 0;
		public static const PLAYING:Number = 1;
		public static const PAUSED:Number = 2;
		public static const BUFFERING:Number = 3;
		public static const QUEUED:Number = 5;

		public var stateCode:Number;

		public function MovieStateChangeEvent(bubbles_p:Boolean = true, cancelable_p:Boolean = false) {
			super(ON_STATE_CHANGE, bubbles_p, cancelable_p);
		}
		
		public override function clone():Event {
			var cloned:MovieStateChangeEvent = new MovieStateChangeEvent(bubbles, cancelable);
			cloned.stateCode = stateCode;
			return cloned;
		}
	}
}