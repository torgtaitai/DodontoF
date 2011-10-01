//--*-coding:utf-8-*--

package {
    
    public class StatusMarkerInfo {
        
        static private var instance:StatusMarkerInfo;
        
        public function StatusMarkerInfo() {
            instance = this;
        }
        
        static public function getInstance():StatusMarkerInfo {
            if( instance == null ) {
                instance = new StatusMarkerInfo();
            }
            
            return instance
        }
        
        [Embed(source='image/statusMarker/mark0.png')]
        [Bindable]
        public var marker_0:Class;
        
        [Embed(source='image/statusMarker/mark1.png')]
        [Bindable]
        private var marker_1:Class;
        
        [Embed(source='image/statusMarker/mark2.png')]
        [Bindable]
        private var marker_2:Class;
        
        [Embed(source='image/statusMarker/mark3.png')]
        [Bindable]
        private var marker_3:Class;
        
        [Embed(source='image/statusMarker/mark4.png')]
        [Bindable]
        private var marker_4:Class;
        
        [Embed(source='image/statusMarker/mark5.png')]
        [Bindable]
        private var marker_5:Class;
        
        [Embed(source='image/statusMarker/mark6.png')]
        [Bindable]
        private var marker_6:Class;
        
        [Embed(source='image/statusMarker/mark7.png')]
        [Bindable]
        private var marker_7:Class;
        
        [Embed(source='image/statusMarker/mark8.png')]
        [Bindable]
        private var marker_8:Class;
        
        [Embed(source='image/statusMarker/mark9.png')]
        [Bindable]
        private var marker_9:Class;
        
        [Embed(source='image/statusMarker/mark10.png')]
        [Bindable]
        private var marker_10:Class;
        
        [Embed(source='image/statusMarker/mark11.png')]
        [Bindable]
        private var marker_11:Class;
        
        private var markers:Array
            = [marker_0,
               marker_1,
               marker_2,
               marker_3,
               marker_4,
               marker_5,
               marker_6,
               marker_7,
               marker_8,
               marker_9,
               marker_10,
               marker_11,
               ];
        
        public function length():int {
            return markers.length;
        }
        
        public function getMarker(i:int):Class {
            return markers[i];
        }
        
        
    }
}