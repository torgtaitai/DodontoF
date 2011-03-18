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
package com.enefekt.tubeloc {
		
	import flash.net.LocalConnection;
	import flash.events.*;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.display.Sprite;

	import flash.system.Security;

	import com.enefekt.tubeloc.event.*;
	
	/**
	 * Dispatched when there is a player error.
	 *
	 * @eventType com.enefekt.tubeloc.event.PlayerErrorEvent.ON_ERROR
	 */
	[Event(name="onError", type="com.enefekt.tubeloc.event.PlayerErrorEvent")]
	
	/**
	 * Dispatched when the player state changes
	 *
	 * @eventType com.enefekt.tubeloc.event.MovieStateChangeEvent.ON_STATE_CHANGE
	 */
	[Event(name="onStateChange", type="com.enefekt.tubeloc.event.MovieStateChangeEvent")]
	
	/**
	 * Dispatched when the movie content changes as a result from loading a new movie
	 *
	 * @eventType com.enefekt.tubeloc.event.MovieStateUpdateEvent.MOVIE_STATE_UPDATE
	 */
	[Event(name="onMovieStateUpdate", type="com.enefekt.tubeloc.event.MovieStateUpdateEvent")]
	
	/**
	 * Dispatched as movie playback makes progress, can get updates of current playback time
	 *
	 * @eventType com.enefekt.tubeloc.event.MovieProgressEvent.MOVIE_PROGRESS
	 */
	[Event(name="onMovieProgress", type="com.enefekt.tubeloc.event.MovieProgressEvent")]
	
	/**
	 * Dispatched when the player is ready to load videos and receive commands.
	 *
	 * @eventType com.enefekt.tubeloc.event.PlayerReadyEvent.PLAYER_READY
	 */
	[Event(name="onPlayerReady", type="com.enefekt.tubeloc.event.PlayerReadyEvent")]
	
	/**
	 * Dispatched when the player is unloaded, and safe to remove from stage.
	 *
	 * @eventType com.enefekt.tubeloc.event.PlayerUnloadEvent.PLAYER_UNLOAD
	 */
	[Event(name="onPlayerUnload", type="com.enefekt.tubeloc.event.PlayerUnloadEvent")]

	/**
	 * MovieSprite - AS3 wrapper for YouTube Player API
	 * 
	 * @author Ben Longoria enefekt@gmail.com
	 */
	public class MovieSprite extends Sprite {
		public static const CHROME_HEIGHT:Number = 25;
		public static const PLAYER_WRAPPER_URL:String = "as2_tubeloc.swf";
		public static const PLAYER_API_URL:String = "http://www.youtube.com/v/";
		public static const PLAYER_CHROMELESS_URL:String = "http://www.youtube.com/apiplayer";
		
		private static const LOCAL_CONNECTION_EVENT:String = "onLocalConnectionEvent";
		private static const ON_YT_MOVIE_COMPLETE:String = "onYouTubeMovieComplete";

		private var lastMovieUpdate:MovieStateUpdateEvent;
		private var lastStateUpdate:MovieStateChangeEvent;
		private var lastProgress:MovieProgressEvent;
		
		private var as3Id:String;
		private var as2Id:String;
		private var receivingConnection:LocalConnection;
		private var sendingConnection:LocalConnection;
		private var tubeLocLoader:Loader;

		private var ytWidth:Number;
		private var ytHeight:Number;

		private var idIncrementer:Number = 0;
		private var concatenatedUrl:String;
		private var lastVolumeSet:Number = 100;
		private var waitingForUnload:Boolean = false;
		private var waitingForLoad:Boolean = false;
		private var readyForLoad:Boolean = true;
		private var playerWrapperUrl:String = PLAYER_WRAPPER_URL;
		private var playerAPIUrl:String = PLAYER_API_URL;		
		private var chromelessPlayerAPIUrl:String = PLAYER_CHROMELESS_URL;
		private var apiUrl:String;
		private var chromeless:Boolean = false;
		
		/**
		 * Constructor
		 *
		 * @param	videoId_p					ID of video to play if chromed player
		 * @param	chromeless_p				True if the player should be in chromeless mode
		 * @param	playerAPIUrl_p				The YouTube API Url for the player API
		 * @param	chromelessPlayerAPIUrl_p	The YouTube API Url for the chromeless player API
		 * @param	wrapperUrl_p				The AS2 SWF that wraps the AS2 Player API
		 */
		public function MovieSprite(videoId_p:String = null,
									chromeless_p:Boolean = false,
									playerAPIUrl_p:String = null,
									chromelessPlayerAPIUrl_p:String = null,
									wrapperUrl_p:String = null) {
			super();
			
			chromeless = chromeless_p;
			
			if(chromelessPlayerAPIUrl_p) {
				chromelessPlayerAPIUrl = chromelessPlayerAPIUrl_p;
			}

			if(playerAPIUrl_p) {
				playerAPIUrl = playerAPIUrl_p;
			}
			if(wrapperUrl_p) {
				playerWrapperUrl = wrapperUrl_p;
			}

			ytWidth = width;
			ytHeight = height;
			
			if(chromeless) {
				apiUrl = chromelessPlayerAPIUrl;
			} else {
				apiUrl = playerAPIUrl + videoId_p;
			}
			
			initPlayer();
		}

		/**
		 * swf loaded
		 */
		private function onComplete(event_p:Event):void {
			// setup a new localconnection object for receiving info
			receivingConnection = new LocalConnection();
			receivingConnection.client = this;
			receivingConnection.allowDomain("*");
			receivingConnection.allowInsecureDomain("*");
			receivingConnection.connect(as3Id);    

			// setup a new localconnection object for sending info
			sendingConnection = new LocalConnection();
			sendingConnection.allowDomain("*");
			sendingConnection.allowInsecureDomain("*");
			
		}

		private function onIOError(event_p:IOErrorEvent):void {
			var playerError:PlayerErrorEvent = new PlayerErrorEvent();
			playerError.errorCode = PlayerErrorEvent.PLAYER_WRAPPER_NOT_FOUND;
			playerError.detail = event_p.toString();
			dispatchEvent(playerError);
		}

		private function onUnload(event_p:Event):void {			
			tubeLocLoader.contentLoaderInfo.removeEventListener(Event.UNLOAD, onUnload);

			readyForLoad = true;

			var unloadEvent:PlayerUnloadEvent = new PlayerUnloadEvent();
			dispatchEvent(unloadEvent);

			if(waitingForLoad) {
				waitingForLoad = false;
				initLoader();
			}

			dispatchEvent(event_p);
		}

		/**
		 * Calls method on as2 youtube movie
		 */
		private function callAS2Method(methodName_p:String, data_p:Object=null):void {
			if(sendingConnection) {
				sendingConnection.send(as2Id, methodName_p, data_p);
			} else {
				throw new Error("Sending LocalConnection not intialized");
			}
		}

		/**
		 * Loads and initializes the YouTube Player and ActionScript 2 Player Wrapper
		 */
		private function initPlayer():void {
			//only do if wrapper Url has been set
			if(playerWrapperUrl) {
				//new uid for as3
				as3Id = "as3Id_" + new Date().time.toString() + (idIncrementer++).toString();

				//new uid for as2
				as2Id = "as2Id_" + new Date().time.toString() + (idIncrementer++).toString();
								
				//append params
				concatenatedUrl = playerWrapperUrl + "?as3Id=" + as3Id + "&as2Id=" + as2Id + "&as3Listener=" + LOCAL_CONNECTION_EVENT + "&playerAPIUrl=" + escape(apiUrl);
				if(!readyForLoad) {
					waitingForLoad = true;
					//destroy old instance
					destroy();
				} else {
					//init loader
					initLoader();
				}
			} else {
				throw new Error("You need to set playerWrapperUrl before init'n the player");
			}
		}

		/**
		 * init's the loader
		 */
		private function initLoader():void {
			readyForLoad = false;
			//if is a child still, remove, add new later
			if(tubeLocLoader) {
				if(contains(tubeLocLoader)) {
					removeChild(tubeLocLoader);
				}
			}
			tubeLocLoader = new Loader();
			tubeLocLoader.x = 0;
			tubeLocLoader.y = 0;
			tubeLocLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
			tubeLocLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			tubeLocLoader.contentLoaderInfo.addEventListener(Event.UNLOAD, onUnload);
			var request:URLRequest = new URLRequest(concatenatedUrl);
			tubeLocLoader.load(request);
		}
		
		/**
		 * @param	width_p
		 */
		override public function set width(width_p:Number):void {
			ytWidth = width_p;
			setSize(width, height);
		}
		override public function get width():Number {
			return ytWidth;
		}

		/**
		 * @param	height_p
		 */
		override public function set height(height_p:Number):void {
			ytHeight = height_p;
			setSize(width, height);
		}
		override public function get height():Number {
			return ytHeight;
		}

		/**
		 * Handles single event point of entry for as2 clip
		 *
		 * @param	object_p	The connection object
		 */
		public function onLocalConnectionEvent(object_p:Object):void {
			//When the SWF is first loaded, it will broadcast an unstarted (-1) event. 
			//When the video is cued and ready to play, it will broadcast a video cued event (5).

			//determine which kind of event it is, then dispatch it
			switch(object_p.eventName) {
				case ON_YT_MOVIE_COMPLETE:
					addChild(tubeLocLoader);
					var readyEvent:PlayerReadyEvent = new PlayerReadyEvent();
					dispatchEvent(readyEvent);
					break;
				case PlayerErrorEvent.ON_ERROR:
					var errorEvent:PlayerErrorEvent = new PlayerErrorEvent();
					errorEvent.errorCode = object_p.value;
					dispatchEvent(errorEvent);
					break;
				case MovieStateChangeEvent.ON_STATE_CHANGE:
					if(object_p.value == MovieStateChangeEvent.ENDED && waitingForUnload) {
						waitingForUnload = false;
						unloadPlayerSWF();
					} else {
						var stateChangeEvent:MovieStateChangeEvent = new MovieStateChangeEvent();
						stateChangeEvent.stateCode = object_p.value;
						lastStateUpdate = stateChangeEvent;
						dispatchEvent(stateChangeEvent);
					}
					break;
				case MovieProgressEvent.MOVIE_PROGRESS:
					var movieProgressEvent:MovieProgressEvent = new MovieProgressEvent();
					movieProgressEvent.currentTime = object_p.currentTime;
					lastProgress = movieProgressEvent;
					dispatchEvent(movieProgressEvent);
					break;
				case MovieStateUpdateEvent.MOVIE_STATE_UPDATE:
					var movieUpdateEvent:MovieStateUpdateEvent = new MovieStateUpdateEvent();
					movieUpdateEvent.videoBytesLoaded = object_p.videoBytesLoaded;
					movieUpdateEvent.videoBytesTotal = object_p.videoBytesTotal;
					movieUpdateEvent.videoStartBytes = object_p.videoStartBytes;
					movieUpdateEvent.muted = object_p.muted;
					movieUpdateEvent.volume = object_p.volume;
					movieUpdateEvent.playerState = object_p.playerState;
					movieUpdateEvent.currentTime = object_p.currentTime;
					movieUpdateEvent.duration = object_p.duration;
					movieUpdateEvent.videoUrl = object_p.videoUrl;
					movieUpdateEvent.videoEmbedCode = object_p.videoEmbedCode;
					lastMovieUpdate = movieUpdateEvent;
					dispatchEvent(movieUpdateEvent);
					break;
				default:
					//nada
					break;
			}
		}

		/**
		 * seek into a movie
		 *
		 * @param	seconds_p			The seconds to seek
		 * @param	allowSeekAhead_p	To make a new call to the server if those seconds haven't been loaded yet
		 */
		public function seekTo(seconds_p:Number, allowSeekAhead_p:Boolean=true):void {
			var lcData:Object = {
				seconds:seconds_p,
				allowSeekAhead:allowSeekAhead_p
			};
			callAS2Method("seekTo", lcData);
		}

		/**
		 * set volume of movie
		 *
		 * @param	volume_p	Number between 1-100
		 */
		public function setVolume(volume_p:Number):void {
			var lcData:Object = {
				volume:volume_p
			};
			lastVolumeSet = volume_p
			callAS2Method("setVolume", lcData);
		}

		/**
		 * @return	Last volume set, 1-100
		 */
		public function getVolume():Number {
			return lastVolumeSet;
		}

		/**
		 * un-mutes the movie
		 */
		public function unMute():void {
			callAS2Method("unMute");
		}

		/**
		 * mutes the movie
		 */
		public function mute():void {
			callAS2Method("mute");
		}

		/**
		 * clears the video display, useful to clear any video remnants after stopVideo
		 */
		public function clearVideo():void {
			callAS2Method("clearVideo");
		}

		/**
		 * sizes the youtube movie
		 */
		public function setSize(width_p:Number, height_p:Number):void {
			var lcData:Object = {
				width:width_p,
				height:height_p
			};
			callAS2Method("setSize", lcData);
		}

		/**
		 * loads a particular video by id
		 *
		 * @param	videoId_p		Id of an existing youtube movie
		 * @param	startSeconds_p	Seconds in to start playing
		 */
		public function loadVideoById(videoId_p:String, startSeconds_p:Number = 0):void {
			var lcData:Object = {
				videoId:videoId_p,
				startSeconds:(!startSeconds_p) ? null : startSeconds_p
			};
			callAS2Method("loadVideoById", lcData);
		}

		/**
		 * prepares a particular video by id, won't play until playVideo or seekTo
		 *
		 * @param	videoId_p		Id to an existing youtube movie
		 * @param	startSeconds_p	Seconds in to cue to
		 */
		public function cueVideoById(videoId_p:String, startSeconds_p:Number = 0):void {
			var lcData:Object = {
				videoId:videoId_p,
				startSeconds:(!startSeconds_p) ? null : startSeconds_p
			};
			callAS2Method("cueVideoById", lcData);
		}

		/**
		 * stops the video
		 */
		public function stopVideo():void {
			callAS2Method("stopVideo");
		}

		/**
		 * plays the video
		 */
		public function playVideo():void {
			callAS2Method("playVideo");
		}

		/**
		 * pauses the video
		 */
		public function pauseVideo():void {
			callAS2Method("pauseVideo");
		}

		/**
		 * @return description of state
		 */
		public function getStateDescription():String {
			var desc:String;

			if(!lastStateUpdate) {
				return "No state reported yet";
			}

			switch(lastStateUpdate.stateCode) {
				case MovieStateChangeEvent.UNSTARTED:
					desc = "Unstarted";
					break;
				case MovieStateChangeEvent.ENDED:
					desc = "Ended";
					break;
				case MovieStateChangeEvent.PLAYING:
					desc = "Playing";
					break;
				case MovieStateChangeEvent.PAUSED:
					desc = "Paused";
					break;
				case MovieStateChangeEvent.BUFFERING:
					desc = "Buffering";
					break;
				case MovieStateChangeEvent.QUEUED:
					desc = "Queued";
					break;
				default:
					desc = "No state reported yet";
					break;
			}

			return desc;
		}

		/**
		 * @return current time
		 */
		public function getCurrentTime():Number {
			return (lastProgress) ? lastProgress.currentTime : -1;
		}

		/**
		 * @return video duration
		 */
		public function getDuration():Number {
			return (lastMovieUpdate) ? lastMovieUpdate.duration : -1;
		}

		/**
		 * @return video duration
		 */
		public function getVideoUrl():String {
			return (lastMovieUpdate) ? lastMovieUpdate.videoUrl : "http://www.youtube.com";
		}

		/**
		 * @return video embed code
		 */
		public function getVideoEmbedCode():String {
			return (lastMovieUpdate) ? lastMovieUpdate.videoEmbedCode : "";
		}

		/**
		 * destroys the player instance. This should be called before unloading the player SWF
		 */
		public function destroy():void {
			if(!lastStateUpdate || lastStateUpdate.stateCode == MovieStateChangeEvent.ENDED) {
				unloadPlayerSWF();
			} else {
				waitingForUnload = true;
				stopVideo();
			}
		}

		private function unloadPlayerSWF():void {
			callAS2Method("destroy");
			if(tubeLocLoader) {
				tubeLocLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onComplete);
				tubeLocLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				try {
					sendingConnection.close();
				} catch(e_p:Error) {
					//
				}
				receivingConnection.close();

				tubeLocLoader.unload();
			}
		}
	}
}