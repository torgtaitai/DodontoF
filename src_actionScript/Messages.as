//--*-coding:utf-8-*--

package {
    
    import mx.controls.Alert;
    import mx.utils.StringUtil;
    
    public class Messages {
        
        static private var instance:Messages;
        
        
        static public function getInstance():Messages {
            if( instance == null ) {
                instance = new Messages();
            }
            
            return instance;
        }
        
        static public function getMessageFromWarningInfo(warning:Object):String {
            if( warning == null ) {
                return "";
            }
            
            var key:String = warning["key"];
            var params:Array = warning["params"];
            
            return getMessage(key, params);
        }
        
        static public function getMessage(key:String, params:Array = null):String {
            var messageBase:String = getInstance().messageBaseList[key];
            
            if( messageBase == null ) {
                //return "Messages.getMessage key:" + key + " has no message";
                //return key;
            }
            
            if( params == null ) {
                params = new Array();
            }
            
            var message:String= StringUtil.substitute(messageBase, params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8], params[9]);
            
            return message;
        }
        
        private var messageBaseList:Object = 
{
    "noSmallImageDir" : "サムネイル画像格納用ディレクトリ「{0}」がありません。マニュアルの「設置方法」の「imageUploadSpace/smallImages」についての記載を参照しディレクトリの作成を実施して下さい。",
    "canNotLoginBecauseMentenanceNow" : "現在メンテナンス作業中のためログインすることが出来ません。しばらくお待ち下さい。",
    "canNotRefreshBecauseMentenanceNow" : "メンテナンス作業が発生したためサーバ接続が途絶しました。\nしばらく待ったうえで、再度ログインしてください。",
    //
    "dragMeForFloorTile" : "ドラッグ＆ドロップするとマップにタイルを貼り付けることが出来ます。",
    "dragMeForChit" : "チットを配置したいところにドラッグしてください",
    "unremovablePlayRoomNumber" : "指定されたプレイルームはシステム管理者によって削除不可に指定されています。",
    "unloadablePlayRoomNumber" : "このプレイルームはシステム管理者によってロード不可に指定されています。ロードを行いたい場合は他のプレイルームを作成してください。",
    "noPasswordPlayRoomNumber" : "このプレイルームはシステム管理者によってパスワード設定不可に指定されています。パスワードは空にしてください。",
    
    "9999" : "dummy"
};
        
    }
}
