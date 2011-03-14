#--*-coding:utf-8-*--

require 'test/unit'
require 'diceRoll'
require 'kconv'
require 'logger'

$debug = true

def getLogMessageProc(obj, *options)
  message = obj.inspect.tosjis
  if( obj.instance_of?(String) )
    message = obj
  end
  return message = "#{options.join(',')}:#{message}"
end

def logging(obj, *options)
  $log ||= Logger.new("log.txt", 3)
  $log.level = ( $debug ? Logger::DEBUG : Logger::ERROR )

  $log.debug() do 
    getLogMessageProc(obj, *options)
  end
end



class RandMax < Rand
  
  def getRand(max)
    max - 1
  end
  
end

class TestDiceRoll < Test::Unit::TestCase
 
  def setup
    @diceRollMax = DiceRoll.new
    @diceRollMax.setRand(RandMax.new)
  end
  
  def test_randMax
    assert_equal( "ダイス合計：6 (1D6 = 6 [6])", @diceRollMax.swapDiceRollText("D6") )
    assert_equal( "ダイス合計：12 (2D6 = 12 [6 6])", @diceRollMax.swapDiceRollText("2D6") )
    assert_equal( "ダイス合計：1 (1D1 = 1 [1])", @diceRollMax.swapDiceRollText("1D1") )
    assert_equal( "ダイス合計：81 (9D9 = 81 [9 9 9 9 9 9 9 9 9])", @diceRollMax.swapDiceRollText("9D9") )
    assert_equal( "ダイス合計：200 (10D20 = 200 [20 20 20 20 20 20 20 20 20 20])", @diceRollMax.swapDiceRollText("10D20") )
  end
  
  def test_JapaneaseString
    assert_equal( "ダイス合計：6 (1D6 = 6 [6])", @diceRollMax.swapDiceRollText("１Ｄ６") )
    assert_equal( "ダイス合計：6 (1D6 = 6 [6])",  @diceRollMax.swapDiceRollText("1Ｄ６") )
    assert_equal( "ダイス合計：6 (1D6 = 6 [6])",  @diceRollMax.swapDiceRollText("１D６") )
    assert_equal( "ダイス合計：6 (1D6 = 6 [6])",  @diceRollMax.swapDiceRollText("１Ｄ6") )
    assert_equal( "ダイス合計：6 (1D6 = 6 [6])",  @diceRollMax.swapDiceRollText("１ｄ６") )
    assert_equal( "ダイス合計：6 (1D6 = 6 [6])",  @diceRollMax.swapDiceRollText("１d６") )
    assert_equal( "ダイス合計：81 (9D9 = 81 [9 9 9 9 9 9 9 9 9])", @diceRollMax.swapDiceRollText("９Ｄ９") )
  end
 
  def test_invalidDiceString
    assert_equal( "このメッセージは不正なダイスロール結果の可能性があります=>ダイス合計：6 (1D6 = 6 [6])",
                  @diceRollMax.swapDiceRollText("ダイス合計：6 (1D6 = 6 [6])") )
  end
  
  def test_notDiceString
    assert_equal( "mokeke", @diceRollMax.swapDiceRollText("mokeke") )
    assert_equal( "あぁあ", @diceRollMax.swapDiceRollText("あぁあ") )
    assert_equal( "", @diceRollMax.swapDiceRollText("") )
    assert_equal( "1D6a", @diceRollMax.swapDiceRollText("1D6a") )
  end
 
  def test_tooLarge
    @diceRollMax.setDiceTypeMax(100)
    @diceRollMax.setDiceCountMax(10)
    
    assert_equal( "ダイス合計：100 (1D100 = 100 [100])", @diceRollMax.swapDiceRollText("1D100") )
    assert_equal( "1D101 = too large dice type. [diceType:101]", @diceRollMax.swapDiceRollText("1D101") )
    
    assert_equal( "ダイス合計：60 (10D6 = 60 [6 6 6 6 6 6 6 6 6 6])", @diceRollMax.swapDiceRollText("10D6") )
    assert_equal( "11D6 = too large dice count. [diceCount:11]", @diceRollMax.swapDiceRollText("11D6") )
  end
  
  def test_modifyValue
    assert_equal( "ダイス合計：7 (1D6 + 1 = 7 [6])", @diceRollMax.swapDiceRollText("1D6 + 1") )
    assert_equal( "ダイス合計：7 (1D6 + 1 = 7 [6])", @diceRollMax.swapDiceRollText("1D6　+ 1") )
    assert_equal( "ダイス合計：8 (1D6 + 2 = 8 [6])", @diceRollMax.swapDiceRollText("1D6+2") )
    assert_equal( "ダイス合計：9 (1D6 + 3 = 9 [6])", @diceRollMax.swapDiceRollText("１D６＋３") )
    assert_equal( "ダイス合計：5 (1D6 - 1 = 5 [6])", @diceRollMax.swapDiceRollText("1D6 - 1") )
    assert_equal( "ダイス合計：5 (1D6 - 1 = 5 [6])", @diceRollMax.swapDiceRollText("1D6　-　1") )
    assert_equal( "ダイス合計：4 (1D6 - 2 = 4 [6])", @diceRollMax.swapDiceRollText("1D6-2") )
    assert_equal( "ダイス合計：3 (1D6 - 3 = 3 [6])", @diceRollMax.swapDiceRollText("１D６−３") )
    assert_equal( "ダイス合計：2 (1D6 - 4 = 2 [6])", @diceRollMax.swapDiceRollText("１D６ー４") )
    
    assert_equal( "ダイス合計：13 (2D6 + 1 = 13 [6 6])", @diceRollMax.swapDiceRollText("2D6 + 1") )
  end
 
end
