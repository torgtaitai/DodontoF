//--*-coding:utf-8-*--

//本ソースコードは以下から流用させていただいております。
//この場を借りてお礼申し上げます
//http://koharubiyori-n.cocolog-nifty.com/blog/2008/05/flex_fd4a.html

package
{
	import flash.display.Shape;
	
	import mx.core.UIComponent;
	import mx.effects.Tween;

	public class RubberBand extends UIComponent
	{
		private var m_shape:Shape;
		private var m_first:Boolean = true;
		
		public function RubberBand()
		{
			super();
			
		}
		override protected function createChildren():void{
			super.createChildren();

			if(!m_shape){
				m_shape = new Shape();
				m_shape.alpha = 0;
			    m_shape.graphics.lineStyle(0,0x0000FF,0.2);
			    m_shape.graphics.beginFill(0x0000FF,0.1);
			    m_shape.graphics.drawRect(0,0,3,3);
				m_shape.graphics.endFill();
				this.addChild(m_shape);
			}	
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			
			m_shape.width = unscaledWidth;
			m_shape.height = unscaledHeight;
			if(m_first){
				var tween:Tween = new Tween(m_shape,[0],[1],120);
				tween.setTweenHandlers(updateTween,endTween);				
				m_first = false;
			}
			
		}
		private function updateTween(value:Array):void{
			m_shape.alpha = value[0];
		}
		private function endTween(value:Array):void{
			m_shape.alpha = value[0];
		}
		
		
		
	}
}