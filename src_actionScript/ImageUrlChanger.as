package {

    public class ImageUrlChanger {
        
        private var imageDir:String = "__LOCAL__";
        private var localString:String = "(local)";
        
        public function setImageDir(imageDir_:String):void {
            imageDir = imageDir_;
        }
        
        public function getShort(imageUrl:String):String {
            return imageUrl.replace(imageDir, localString);
        }
        
        public function getLong(imageUrl:String):String {
            var url:String = imageUrl.replace(localString, imageDir);
            url = Config.getInstance().getUrlString(url);
            return url;
        }
    }
}

