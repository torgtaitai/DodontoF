//--*-coding:utf-8-*--
//本ソースコードは http://onegame.bona.jp/tips/mersennetwister.html から引用しております。

package {
    
    public class MersenneTwister {
        
        private const N:int = 624;
        private const M:int = 397;
        private const UPPER_MASK:uint = 0x80000000;
        private const LOWER_MASK:uint = 0x7fffffff;
        private const MATRIX_A:uint   = 0x9908b0df;
        private var x:Array;
        private var p:int;
        private var q:int;
        private var r:int;
        
        public function MersenneTwister(s:uint) {
            x = new Array();
            seed = s;
        }
        
        public function set seed(s:uint):void {
            x[0] = s;
            for (var i:int = 1; i < N; i++) {
                x[i] = imul(1812433253, x[i - 1] ^ (x[i - 1] >>> 30)) + i;
		x[i] &= 0xffffffff;
            }
            p = 0;
            q = 1;
            r = M;
        }
        
        /**
         * [0, 1)
         */
        public function nextNumber():Number {
            return next(32) / 4294967296;
        }
        
        private function next(bits:int):uint {
            var y:uint = (x[p] & UPPER_MASK) | (x[q] & LOWER_MASK);
            x[p] = x[r] ^ (y >>> 1) ^ ((y & 1) * MATRIX_A);
            y = x[p];
            
            if (++p == N) {p = 0;}
            if (++q == N) {q = 0;}
            if (++r == N) {r = 0;}
            
            y ^= (y >>> 11);
            y ^= (y << 7) & 0x9d2c5680;
            y ^= (y << 15) & 0xefc60000;
            y ^= (y >>> 18);

            return y >>> (32 - bits);
        }

        private function imul(a:Number, b:Number):Number {
            var al:Number = a & 0xffff;
            var ah:Number = a >>> 16;
            var bl:Number = b & 0xffff;
            var bh:Number = b >>> 16;
            var ml:Number = al * bl;
            var mh:Number = ((((ml >>> 16) + al * bh) & 0xffff) + ah * bl) & 0xffff;
            
            return (mh << 16) | (ml & 0xffff);
        }
    }
}
