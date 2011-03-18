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
	import mx.core.UIComponent;
	import flash.events.*;
	import mx.events.*;
	import com.enefekt.tubeloc.MovieSprite;
	import com.enefekt.tubeloc.event.*;
	
	/**
	 * @see com.enefekt.tubeloc.MovieSprite#event:onError
	 */
	[Event(name="onError", type="com.enefekt.tubeloc.event.PlayerErrorEvent")]
	
	/**
	 * @see com.enefekt.tubeloc.MovieSprite#event:onStateChange
	 */
	[Event(name="onStateChange", type="com.enefekt.tubeloc.event.MovieStateChangeEvent")]
	
	/**
	 * @see com.enefekt.tubeloc.MovieSprite#event:onMovieStateUpdate
	 */
	[Event(name="onMovieStateUpdate", type="com.enefekt.tubeloc.event.MovieStateUpdateEvent")]
	
	/**
	 * @see com.enefekt.tubeloc.MovieSprite#event:onMovieProgress
	 */
	[Event(name="onMovieProgress", type="com.enefekt.tubeloc.event.MovieProgressEvent")]
	
	/**
	 * @see com.enefekt.tubeloc.MovieSprite#event:onPlayerReady
	 */
	[Event(name="onPlayerReady", type="com.enefekt.tubeloc.event.PlayerReadyEvent")]
	
	/**
	 * @see com.enefekt.tubeloc.MovieSprite#event:onPlayerUnload
	 */
	[Event(name="onPlayerUnload", type="com.enefekt.tubeloc.event.PlayerUnloadEvent")]
	
	/**
	 * Movie - Flex wrapper for YouTube Player API
	 * 
	 * @author Ben Longoria enefekt@gmail.com
	 */
	public class Movie extends UIComponent {
		
		private var _videoId:String;
		private var youtubeMovie:MovieSprite;
		
		private var _stateDescription:String;
		private var _currentTime:Number;
		private var _duration:Number;
		private var _videoUrl:String;
		private var _videoEmbedCode:String;
		
		/**
		 * True if player is ready, false otherwise.
		 */
		[Bindable] public var playerReady:Boolean = false;
		
		/**
		 * The url or path where the AS2 proxy SWF resides
		 *
		 * @default ./as2_tubeloc.swf
		 */
		public var playerWrapperUrl:String;
		
		/**
		 * Full-Chrome YouTube Player API url endpoint
		 *
		 * @default http://www.youtube.com/v/
		 */
		public var playerAPIUrl:String;
		
		/**
		 * Chromeless YouTube Player API url endpoint
		 *
		 * @default http://www.youtube.com/apiplayer
		 */
		public var chromelessPlayerAPIUrl:String;
		
		/**
		 * True if no chrome or video controls are desired, false otherwise
		 *
		 * @default false
		 */
		public var chromeless:Boolean = false;
		
		/*
		 * Constructor
		 */
		public function Movie() {
			super();
			
			width = 320;
			height = 240;
			addEventListener(FlexEvent.CREATION_COMPLETE, onComplete);
		}
		
		/**
		 * Video ID for the player to play
		 */
		[Bindable] public function get videoId():String {
			return _videoId;
		}
		public function set videoId(id_p:String):void {
			_videoId = id_p;
			if(_videoId && playerReady) {
				youtubeMovie.loadVideoById(_videoId);
			}
		}
		
		/**
		 * @param	height_p
		 */
		[Bindable] override public function get height():Number {
			return super.height;
		}
		override public function set height(height_p:Number):void {
			super.height = (!chromeless) ? height_p + MovieSprite.CHROME_HEIGHT : height_p;
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#getStateDescription()
		 */
		[Bindable(event="stateDescriptionChanged")]
		public function get stateDescription():String {
			return youtubeMovie.getStateDescription();
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#getCurrentTime()
		 */
		[Bindable(event="currentTimeChanged")]
		public function get currentTime():Number {
			return youtubeMovie.getCurrentTime();
		}
		public function set currentTime(time_p:Number):void {
			youtubeMovie.seekTo(time_p);
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#getDuration()
		 */
		[Bindable(event="durationChanged")]
		public function get duration():Number {
			return youtubeMovie.getDuration();
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#getVideoUrl()
		 */
		[Bindable(event="videoUrlChanged")]
		public function get videoUrl():String {
			return youtubeMovie.getVideoUrl();
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#getVideoEmbedCode()
		 */
		[Bindable(event="videoEmbedCodeChanged")]
		public function get videoEmbedCode():String {
			return youtubeMovie.getVideoEmbedCode();
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#getVolume()
		 */
		[Bindable] public function get volume():Number {
			return youtubeMovie.getVolume();
		}
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#setVolume()
		 */
		public function set volume(volume_p:Number):void {
			youtubeMovie.setVolume(volume_p);
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#seekTo()
		 */
		public function seekTo(seconds_p:Number, allowSeekAhead_p:Boolean=true):void {
			if(playerReady) {
				youtubeMovie.seekTo(seconds_p, allowSeekAhead_p);
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#setVolume()
		 */
		public function setVolume(volume_p:Number):void {
			if(playerReady) {
				youtubeMovie.setVolume(volume_p);
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#getVolume()
		 */
		public function getVolume():Number {
			if(playerReady) {
				return youtubeMovie.getVolume();
			} else {
				return 100;
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#unMute()
		 */
		public function unMute():void {
			if(playerReady) {
				youtubeMovie.unMute();
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#mute()
		 */
		public function mute():void {
			if(playerReady) {
				youtubeMovie.mute();
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#clearVideo()
		 */
		public function clearVideo():void {
			if(playerReady) {
				youtubeMovie.clearVideo();
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#setSize()
		 */
		public function setSize(width_p:Number, height_p:Number):void {
			if(playerReady) {
				setMovieSize(width_p, height_p);
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#loadVideoById()
		 */
		public function loadVideoById(videoId_p:String, startSeconds_p:Number = 0):void {
			if(playerReady) {
				youtubeMovie.loadVideoById(videoId_p, startSeconds_p);
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#cueVideoById()
		 */
		public function cueVideoById(videoId_p:String, startSeconds_p:Number = 0):void {
			if(playerReady) {
				youtubeMovie.cueVideoById(videoId_p, startSeconds_p);
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#stopVideo()
		 */
		public function stopVideo():void {
			if(playerReady) {
				youtubeMovie.stopVideo();
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#playVideo()
		 */
		public function playVideo():void {
			if(playerReady) {
				youtubeMovie.playVideo();
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#pauseVideo()
		 */
		public function pauseVideo():void {
			if(playerReady) {
				youtubeMovie.pauseVideo();
			}
		}
		
		/**
		 * @see	com.enefekt.tubeloc.MovieSprite#destroy()
		 */
		public function destroy():void {
			if(playerReady) {
				playerReady = false;
				youtubeMovie.destroy();
			}
		}
		
		/*
		 * Catches event once interface has been initialized
		 *
		 * @param	event_p	FlexEvent once all UI is init'd
		 */
		private function onComplete(event_p:FlexEvent):void {
			//init MovieSprite
			youtubeMovie = new MovieSprite(videoId, chromeless, playerAPIUrl, chromelessPlayerAPIUrl, playerWrapperUrl);
			youtubeMovie.addEventListener(PlayerReadyEvent.PLAYER_READY, onPlayerReady);
			youtubeMovie.addEventListener(MovieStateChangeEvent.ON_STATE_CHANGE, onPlayerStateChange);
			youtubeMovie.addEventListener(MovieStateUpdateEvent.MOVIE_STATE_UPDATE, onMovieStateUpdate);
			youtubeMovie.addEventListener(MovieProgressEvent.MOVIE_PROGRESS, onMovieProgress);
			addChild(youtubeMovie);
			
			addEventListener(ResizeEvent.RESIZE, onResize);
		}
		
		private function onResize(event_p:ResizeEvent):void {
			setMovieSize(width, height);
		}
		
		private function setMovieSize(width_p:Number, height_p:Number):void {
			youtubeMovie.width = width_p;
			youtubeMovie.height = height_p;
		}
		
		private function onPlayerReady(event_p:PlayerReadyEvent):void {
			playerReady = true;
			setMovieSize(width, height);
			if(videoId && chromeless) {
				youtubeMovie.loadVideoById(videoId);
			}
			
			//trigger prop changes
			triggerCurrentTimeChange();
			triggerPropertyChanges();
		}
		
		private function onPlayerStateChange(event_p:MovieStateChangeEvent):void {
			//check bindable property
			if(youtubeMovie.getStateDescription() != _stateDescription) {
				_stateDescription = youtubeMovie.getStateDescription();
				dispatchEvent(new Event("stateDescriptionChanged"));
			}
		}
		
		private function onMovieStateUpdate(event_p:MovieStateUpdateEvent):void {
			triggerCurrentTimeChange();
			triggerPropertyChanges();
		}
		
		private function onMovieProgress(event_p:MovieProgressEvent):void {
			triggerCurrentTimeChange();
		}
		
		private function triggerCurrentTimeChange():void {
			if(youtubeMovie.getCurrentTime() != _currentTime) {
				_currentTime = youtubeMovie.getCurrentTime();
				dispatchEvent(new Event("currentTimeChanged"));
			}
		}
		
		private function triggerPropertyChanges():void {
			if(youtubeMovie.getStateDescription() != _stateDescription) {
				_stateDescription = youtubeMovie.getStateDescription();
				dispatchEvent(new Event("stateDescriptionChanged"));
			}
			if(youtubeMovie.getDuration() != _duration) {
				_duration = youtubeMovie.getDuration();
				dispatchEvent(new Event("durationChanged"));
			}
			if(youtubeMovie.getVideoUrl() != _videoUrl) {
				_videoUrl = youtubeMovie.getVideoUrl();
				dispatchEvent(new Event("videoUrlChanged"));
			}
			if(youtubeMovie.getVideoEmbedCode() != _videoEmbedCode) {
				_videoEmbedCode = youtubeMovie.getVideoEmbedCode();
				dispatchEvent(new Event("videoEmbedCodeChanged"));
			}
		}
		
	}
}