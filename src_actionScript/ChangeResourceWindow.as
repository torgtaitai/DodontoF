//--*-coding:utf-8-*--

package {
    
    public class ChangeResourceWindow extends AddResourceWindow {
        
        private var target:Object;
        
        public function init(data:Object):void {
            target = data;
            
            resourceName.text = target.name;
            resourceCount.value = target.value;
            resourceUnit.text = target.unit;
        }
        
        override public function execute():void {
            
            var data:Object = {
                "name": resourceName.text,
                "value": resourceCount.value,
                "unit": resourceUnit.text,
                "resourceId": target.resourceId };
            
            var guiInputSender:GuiInputSender = DodontoF_Main.getInstance().getGuiInputSender();
            guiInputSender.getSender().changeResource(data);
            
            closeAction();
        }
        
    }
}


