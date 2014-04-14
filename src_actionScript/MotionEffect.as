//--*-coding:utf-8-*--

package {
    
    import mx.controls.Image;
    import mx.core.UIComponent;
    import mx.effects.Effect;
    import mx.effects.Move;
    import mx.effects.Sequence;
    import mx.effects.Zoom;
    
    
    public class MotionEffect {
        
    /**
     * 立ち絵用のモーションエフェクト設定項目。立ち絵をゆらゆら揺らしたりします。
     */
        [Bindable]
        static public var motionInfos:Array = 
            [{label:Language.s.MotionEffectNone},
             {label:Language.s.MotionEffectZoom, data:"zoom", method:"getMotionEffectZoom"},
             {label:Language.s.MotionEffectShake, data:"shake", method:"getMotionEffectShake"},
             {label:Language.s.MotionEffectWalk, data:"walk", method:"getMotionEffectWalk"}];
        
        public function getMotionEffect(target:UIComponent,
                                        height:int, width:int,
                                        motionName:String):Effect {
            
            if( motionName == null ) {
                return null;
            }
            
            var params:Object = {
                "target": target,
                "height": height,
                "width": width };
            
            for each(var info:Object in motionInfos) {

                if( motionName != info.data ) {
                    continue;
                }
                
                return this[info.method](params);
            }
            
            return null;
        }
        
        private function getMotionEffectWalk(params:Object):Effect {
            var duration:int = 500;
            
            var positionInfos:Array = [
                                       [0, 4, duration], [4, 0, duration/2],
                                       [4, 4, duration], [8, 0, duration/2],
                                       [8, 4, duration], [4, 0, duration/2],
                                       [4, 4, duration], [0, 0, duration/2],
                                ];
            return getMoveEffectsSequence(params.target, positionInfos);
        }
        
        private function getMoveEffectsSequence(target:UIComponent, 
                                                positionInfos:Array):Effect {
            
            var sequence:Sequence = new mx.effects.Sequence();
            sequence.repeatCount = 0;
            
            for(var i:int = 0 ; i < positionInfos.length ; i++) {
                var move:Move = getMove(target, i, positionInfos);
                sequence.addChild( move );
            }
            
            return sequence;
        }
        
        private function getMove(target:UIComponent,
                                       fromIndex:int, positionInfos:Array):Move {
            var toIndex:int = fromIndex + 1;
            if( toIndex >= positionInfos.length ) {
                toIndex -= positionInfos.length;
            }
            
            var toInfo:Array = positionInfos[toIndex];
            var fromInfo:Array = positionInfos[fromIndex];
            
            var move:Move = new Move(target);
            move.duration = fromInfo[2];
            move.yBy = 1;
            move.xFrom = fromInfo[0];
            move.yFrom = fromInfo[1];
            move.xTo = toInfo[0];
            move.yTo = toInfo[1];
            
            return move;
        }
        
        
        private function getMotionEffectShake(params:Object):Effect {
            var duration:int = 150;
            var positionInfos:Array = [
                                [0, -1, duration],  [0, 1, duration]
                                ];
            return getMoveEffectsSequence(params.target, positionInfos);
        }
        
        
        private function getMotionEffectZoom(params:Object):Effect {
            
            var duration:int = 3000;
            var zoomInfos:Array = [
                                   [1, 0.97, duration],  [0.97, 1, duration],
                                   ];
            
            var sequence:Sequence = new mx.effects.Sequence();
            sequence.repeatCount = 0;
            
            for(var i:int = 0 ; i < zoomInfos.length ; i++) {
                sequence.addChild( getZoom(params, zoomInfos[i]) );
            }
            
            return sequence;
        }
        
        private function getZoom(params:Object, zoomInfo:Array):Zoom {
            
            var zoom:Zoom = new Zoom(params.target);
            
            zoom.duration = zoomInfo[2];
            
            zoom.zoomWidthFrom = zoomInfo[0];
            zoom.zoomHeightFrom = zoomInfo[0];
            zoom.zoomWidthTo = zoomInfo[1];
            zoom.zoomHeightTo = zoomInfo[1];
            
            zoom.originX = params.width;
            zoom.originY = params.height;
            
            return zoom;
        }
        
    }
}
