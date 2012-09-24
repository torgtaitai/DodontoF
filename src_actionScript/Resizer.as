//--*-coding:utf-8-*--

//本ソースコードは以下から流用させていただいております。
//この場を借りてお礼申し上げます
//http://koharubiyori-n.cocolog-nifty.com/blog/2008/05/flex_fd4a.html

package
{

	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.FlexMouseEvent;
	import mx.managers.CursorManager;
	
	
	public class Resizer{
		
		private static var resizeCursor:Class;
		[Embed(source="image/cursor/cur_vertical.png")]
		private static const CONST_CUR_VERTICAL:Class;
		[Embed(source="image/cursor/cur_horizontal.png")]
		private static const CONST_CUR_HORIZONTAL:Class;
		[Embed(source="image/cursor/cur_left_oblique.png")]
		private static const CONST_CUR_LEFT_OBLIQUE:Class;
		[Embed(source="image/cursor/cur_right_oblique.png")]
		private static const CONST_CUR_RIGHT_OBLIQUE:Class;
        
		private static const CONST_MODE_NONE:Number = 0;
		private static const CONST_MODE_LEFT:Number = 1;
		private static const CONST_MODE_RIGHT:Number = 2;
		private static const CONST_MODE_TOP:Number = 4;
		private static const CONST_MODE_BOTTOM:Number = 8;
		private static const CONST_MODE_MOVE:Number = 11;		
		
		private static var resizeTarget:UIComponent;
		private static var resizeMode:Number = 0;
		private static var _isResizing:Boolean = false;
		private static var _resizeAreaMargin:Number = 6;

		private static var resizeRect:Rectangle;		
		private static var oldRect:Rectangle;
		private static var oldPoint:Point;
		
		private static var rubberBand:RubberBand;
        
		public static function addResize(target:UIComponent, minSize:Point):void{
            
			target.setStyle("resizer_minSize", minSize);
			target.setStyle("resizer_isPopUp", target.isPopUp);
            
			target.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			target.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			target.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			target.addEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, onMouseOutSide);			
		}
        
		public static function removeResize(target:UIComponent):void{
			target.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			target.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			target.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		}
		
		public static function get isResizing():Boolean{
			return _isResizing;
		}
        
		public static function set resizeAreaMargin(value:Number):void{
			_resizeAreaMargin = value;
		}
        
		public static function get resizeAreaMargin():Number{
			return _resizeAreaMargin;
		}
        
		private static function onMouseOutSide(event:FlexMouseEvent):void{
		}
        
		private static function onMouseDown(event:MouseEvent):void{
			
			if(resizeMode == CONST_MODE_NONE) {
                return;
            }
            
            
            resizeTarget = UIComponent(event.currentTarget);
            resizeTarget.parent.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            resizeTarget.parent.addEventListener(MouseEvent.MOUSE_MOVE, resize);
            
            resizeRect = new Rectangle(resizeTarget.x,
                                       resizeTarget.y,
                                       resizeTarget.width,
                                       resizeTarget.height);
            
			
			
            oldRect = resizeRect.clone();
            oldPoint = new Point(resizeTarget.parent.mouseX,resizeTarget.parent.mouseY); 
            if(rubberBand) {
                resizeTarget.parent.removeChild(rubberBand);
            }
            rubberBand = new RubberBand();				
            
            resizeTarget.parent.addChild(rubberBand);
            drawRubberBand(rubberBand,resizeTarget,resizeRect);
		}
        
		private static function onMouseUp(event:MouseEvent):void{
            
			resizeTarget.parent.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			resizeTarget.parent.removeEventListener(MouseEvent.MOUSE_MOVE, resize);
            
			if(resizeTarget) {
				resizeTarget.x = resizeRect.x;
				resizeTarget.y = resizeRect.y;
				resizeTarget.width = resizeRect.width;
				resizeTarget.height = resizeRect.height;
				resizeTarget.parent.removeChild(rubberBand);
                
                var resizableWindow:ResizableWindow = resizeTarget as ResizableWindow;
                if( resizableWindow != null ) {
                    resizableWindow.resizeEvent();
                }
                var window:CommonPopupWindow = resizeTarget as CommonPopupWindow;
                if( window != null ) {
                    window.resizeEvent();
                }
			}
			rubberBand = null;
			resizeTarget = null;
		}
        
        private static function isVerticalResizable(target:UIComponent):Boolean {
            var window:ResizableWindow = target as ResizableWindow;
            if( window == null ) {
                return true;
            }
            
            return window.isVerticalResizable();
            
        }
        private static function setResizeModeWhenCanNotVerticalResize(target:UIComponent):void {
            if( isVerticalResizable(target) ) {
                return;
            }
            
            if( (resizeMode & CONST_MODE_BOTTOM) != 0 ) {
                resizeMode -= CONST_MODE_BOTTOM;
            }
            if( (resizeMode & CONST_MODE_TOP) != 0 ) {
                resizeMode -= CONST_MODE_TOP;
            }
        }
		
		private static function onMouseMove(event:MouseEvent):void {
			var target:UIComponent = UIComponent(event.currentTarget);
            setCursorOnMouseMove(target);
            setPopUpMode(target);
        }
			
		private static function setCursorOnMouseMove(target:UIComponent):void {
			var point:Point = new Point(target.x,target.y);
			
			_isResizing = true;
			
			if( resizeTarget != null ) {
                return;
            }
            
            var posX:Number = target.parent.mouseX;
            var posY:Number = target.parent.mouseY;
            
            if(posX >= (point.x + target.width - _resizeAreaMargin) && 
               posY >= (point.y + target.height - _resizeAreaMargin)) {
                changeCursor(CONST_CUR_LEFT_OBLIQUE, -6, -6); 
                resizeMode = CONST_MODE_RIGHT | CONST_MODE_BOTTOM;
                
                setResizeModeWhenCanNotVerticalResize(target);
                
            }else if(posX <= (point.x + _resizeAreaMargin) && 
                     posY <= (point.y + _resizeAreaMargin)) {
                
                changeCursor(CONST_CUR_LEFT_OBLIQUE, -6, -6);
                resizeMode = CONST_MODE_LEFT | CONST_MODE_TOP;
                
                setResizeModeWhenCanNotVerticalResize(target);
                
            }else if(posX <= (point.x + _resizeAreaMargin) &&
                     posY >= (point.y + target.height - _resizeAreaMargin)) {
                
                changeCursor(CONST_CUR_RIGHT_OBLIQUE, -6, -6);
                resizeMode = CONST_MODE_LEFT | CONST_MODE_BOTTOM;
                
                setResizeModeWhenCanNotVerticalResize(target);
                
            }else if(posX >= (point.x + target.width - _resizeAreaMargin) &&
                     posY <= (point.y + _resizeAreaMargin)) {
                
                changeCursor(CONST_CUR_RIGHT_OBLIQUE, -6, -6);
                resizeMode = CONST_MODE_RIGHT | CONST_MODE_TOP;
                
                setResizeModeWhenCanNotVerticalResize(target);
                
            }else if(posX >= (point.x + target.width - _resizeAreaMargin)) {
                
                changeCursor(CONST_CUR_HORIZONTAL, -9, -9);
                resizeMode = CONST_MODE_RIGHT;
                
            }else if(posX <= (point.x + _resizeAreaMargin)) {
                
                changeCursor(CONST_CUR_HORIZONTAL, -9, -9);
                resizeMode = CONST_MODE_LEFT;
                
            }else if(posY >= (point.y + target.height - _resizeAreaMargin)) {
                if( isVerticalResizable(target) ) {
                    changeCursor(CONST_CUR_VERTICAL, -9, -9);
                    resizeMode = CONST_MODE_BOTTOM;
                }
                
            }else if(posY <= (point.y + _resizeAreaMargin)) {
                if( isVerticalResizable(target) ) {
                    changeCursor(CONST_CUR_VERTICAL, -9, -9);
                    resizeMode = CONST_MODE_TOP;
                }
                
            } else {
                resetCursor();
            }
        }
        
		private static function setPopUpMode(target:UIComponent):void {
            if( target.getStyle("resizer_isPopUp") == null ) {
                return;
            }
            
            target.isPopUp = (resizeMode == CONST_MODE_NONE);
		}
		
		private static function resetCursor():void {
            changeCursor(null, 0, 0);
            resizeMode = CONST_MODE_NONE;
            _isResizing = false;
        }
        
		private static function onMouseOut(event:MouseEvent):void{
			if( ! resizeTarget) {
                resetCursor();
			}
		}
		
		private static function resize(event:MouseEvent):void{
			
			if(resizeTarget) {
				
				var sizeX:Number = resizeTarget.parent.mouseX - oldPoint.x;
				var sizeY:Number = resizeTarget.parent.mouseY - oldPoint.y;
				
				var minSize:Point = Point(resizeTarget.getStyle("resizer_minSize"));

			    switch(resizeMode) {
			    	case CONST_MODE_RIGHT | CONST_MODE_BOTTOM:
			    		resizeRect.width = oldRect.width + sizeX > minSize.x ? oldRect.width + sizeX : minSize.x;
		    			resizeRect.height = oldRect.height + sizeY > minSize.y ? oldRect.height + sizeY : minSize.y;
			    		break;
			    	case CONST_MODE_LEFT | CONST_MODE_TOP:
			    		resizeRect.width = oldRect.width - sizeX > minSize.x ? oldRect.width - sizeX : minSize.x;
		    			resizeRect.height = oldRect.height - sizeY > minSize.y ? oldRect.height - sizeY : minSize.y;
		    			resizeRect.x = oldRect.x + oldRect.width - resizeRect.width;
			    		resizeRect.y = oldRect.y + oldRect.height - resizeRect.height;
			    		break;
			    	case CONST_MODE_LEFT | CONST_MODE_BOTTOM:
			    		resizeRect.width = oldRect.width - sizeX > minSize.x ? oldRect.width - sizeX : minSize.x;
		    			resizeRect.height = oldRect.height + sizeY > minSize.y ? oldRect.height + sizeY : minSize.y;
			    		resizeRect.x = oldRect.x + oldRect.width - resizeRect.width;
			    		break;
			    	case CONST_MODE_RIGHT | CONST_MODE_TOP:
			    		resizeRect.width = oldRect.width + sizeX > minSize.x ? oldRect.width + sizeX : minSize.x;
		    			resizeRect.height = oldRect.height - sizeY > minSize.y ? oldRect.height - sizeY : minSize.y;
			    		resizeRect.y = oldRect.y + oldRect.height - resizeRect.height;
			    		break;
			    	case CONST_MODE_RIGHT:
			    		resizeRect.width = oldRect.width + sizeX > minSize.x ? oldRect.width + sizeX : minSize.x;
			    		break;
			    	case CONST_MODE_LEFT:
			    		resizeRect.width = oldRect.width - sizeX > minSize.x ? oldRect.width - sizeX : minSize.x;
			    		resizeRect.x = oldRect.x + oldRect.width - resizeRect.width;
			    		break;
			    	case CONST_MODE_BOTTOM:
			    		resizeRect.height = oldRect.height + sizeY > minSize.y ? oldRect.height + sizeY : minSize.y;
			    		break;
			    	case CONST_MODE_TOP:
			    		resizeRect.height = oldRect.height - sizeY > minSize.y ? oldRect.height - sizeY : minSize.y;
			    		resizeRect.y = oldRect.y + oldRect.height - resizeRect.height;
			    		break;
			    }

				drawRubberBand(rubberBand,resizeTarget,resizeRect);
			    event.updateAfterEvent();
			    
			}
			
		}

		private static function changeCursor(curClass:Class, offX:Number, offY:Number):void{
			
			if(resizeCursor == curClass) {
                return;
            }
            
            CursorManager.removeCursor(CursorManager.currentCursorID);
            if(curClass) {
                CursorManager.setCursor(curClass,2, offX, offY);
            }
            resizeCursor = curClass;
		}
        
		private static function drawRubberBand(rubberBandObj:UIComponent,baseObj:UIComponent,rect:Rectangle):void{
            
			rubberBandObj.x = rect.x;
			rubberBandObj.y = rect.y;
			rubberBandObj.width = rect.width;
			rubberBandObj.height = rect.height;
		}
		
		
	}
	

}