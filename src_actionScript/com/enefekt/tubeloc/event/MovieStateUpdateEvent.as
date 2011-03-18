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
	 * Movie State Update Event
	 *
	 * @author Ben Longoria enefekt@gmail.com
	 */
	public class MovieStateUpdateEvent extends Event {
		public static const MOVIE_STATE_UPDATE:String = "onMovieStateUpdate";

		public var videoBytesLoaded:Number;
		public var videoBytesTotal:Number;
		public var videoStartBytes:Number;
		public var muted:Boolean;
		public var volume:Number;
		public var playerState:Number;
		public var currentTime:Number;
		public var duration:Number;
		public var videoUrl:String;
		public var videoEmbedCode:String;

		public function MovieStateUpdateEvent(bubbles_p:Boolean = true, cancelable_p:Boolean = false) {
			super(MOVIE_STATE_UPDATE, bubbles_p, cancelable_p);
		}
		
		public override function clone():Event {
			var cloned:MovieStateUpdateEvent = new MovieStateUpdateEvent(bubbles, cancelable);
			cloned.videoBytesLoaded = videoBytesLoaded;
			cloned.videoBytesTotal = videoBytesTotal;
			cloned.videoStartBytes = videoStartBytes;
			cloned.muted = muted;
			cloned.volume = volume;
			cloned.playerState = playerState;
			cloned.currentTime = currentTime;
			cloned.duration = duration;
			cloned.videoUrl = videoUrl;
			cloned.videoEmbedCode = videoEmbedCode;
			return cloned;
		}
	}
}