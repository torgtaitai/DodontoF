#--*-coding:utf-8-*--

require 'yaml'

class GardenOrder < DiceBot
  
  def gameName
    'ガーデンオーダー'
  end
  
  def gameType
    "GardenOrder"
  end
  
  def prefixs
    [
      'C:\d+(@\d+)?',
      'C:\d+\/\d+(@\d+)?',
      'DC(SL|BL|IM|BR|RF|EL).+',
    ]
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
・基本判定
　X = 成功率として判定を行ない、結果を表示する。（クリティカル／ファンブルも自動判別）
　　　C:X
　　例１）
　　　C:100
　　　GardenOrder : D100 → 98 (≦ 100／20) ⇒ 〔成功！〕
　　例２）
　　　C:300
　　　GardenOrder : D100 → 28 (≦ 300／60) ⇒ Critical!! 〔効果的成功！！〕
　Y = クリティカル値として末尾に @Y を付加すると、明示的にクリティカル値を指定できる。
　　例３）
　　　C:70@10
　　　GardenOrder : D100 → 25 (≦ 70／60) ⇒ Critical!! 〔効果的成功！！〕

・連続攻撃
　X = 割る前の成功率， Y = 連続攻撃の回数として命中判定を行ない、結果を表示する。
　　　C:X/Y
　　例）
　　　C:100/2
　　　GardenOrder : D100 → 12 (≦ 50／20) ⇒ Critical!! 〔効果的成功！！〕

・負傷表
　XX=属性，Y=ダメージ
　（属性の表記は　切断：SL，銃弾：BL，衝撃：IM，灼熱：BR，冷却：RF，電撃：EL ）
　　　DCXX=Y
　　例）
　　　DCSL=7
　　　GardenOrder : 負傷表：切断［7］ => 軽傷２／マヒ ｜ 脚部負傷 … 足が切り裂かれ、思わずひざまずく。
INFO_MESSAGE_TEXT
  end
  
  def rollDiceCommand(command)
    case command
    when /C\:\d+\/\d(\@\d+)?/i
      text = check_GO_repeat_attack(extract_succsess_rate(command), extract_repeat_count(command), extract_critical_border(command))
    when /C\:\d+(\@\d+)?/i
      text = check_GO(extract_succsess_rate(command), extract_critical_border(command))
     when /^DC(SL|BL|IM|BR|RF|EL)\=\d+/i
      text = look_up_damage_chart(extract_attribute(command), extract_damage(command))
    end
    
    return text
  end
  
  def extract_succsess_rate source
    source.scan(/^C\:(\d+)/i)[0][0].to_i
  end
  
  def extract_repeat_count source
    source.scan(/^C\:\d+\/(\d+)/i)[0][0].to_i
  end
  
  def extract_critical_border source
    regexp = /\@(\d+)/i
    if source =~ regexp then
      source.scan(regexp)[0][0].to_i
    else
      nil
    end
  end
  
  def extract_attribute source
    case source.scan(/^DC(SL|BL|IM|BR|RF|EL)\=.+/i)[0][0].upcase
    when "SL"
      "切断"
    when "BL"
      "銃弾"
    when "IM"
      "衝撃"
    when "BR"
      "灼熱"
    when "RF"
      "冷却"
    when "EL"
      "電撃"
    else
      "-"
    end
  end
  
  def extract_damage source
    source.scan(/^DC(SL|BL|IM|BR|RF|EL)\=(\d+)/i)[0][1].to_i
  end
  
  def check_GO(success_rate, critical_border = nil, fumble_border = nil)
    critical_border = [success_rate / 5, 1].max if critical_border.nil?
    
    if fumble_border.nil? then
      if success_rate < 100 then
        fumble_border = 96
      else
        fumble_border = 99
      end
    end
    
    dice_value, = roll(1, 100)
    
    make_d100_text(
      dice_value,
      success_rate,
      critical_border,
      compute_check_result(dice_value, success_rate, critical_border, fumble_border)
    )
  end
  
  def compute_check_result(dice_value, success_rate, critical_border, fumble_border)
    if dice_value <= critical_border then
      "Critical!! 〔効果的成功！！〕"
    elsif dice_value >= fumble_border then
      "fumble... 〔致命的失敗…〕"
    elsif dice_value <= success_rate then
      "〔成功！〕"
    else
      "〔失敗〕"
    end
  end
  
  def check_GO_repeat_attack(success_rate, repeat_count, critical_border = nil, fumble_border = nil)
    critical_border = success_rate / 5 if critical_border.nil?
    
    check_GO(
      success_rate / repeat_count,
      critical_border,
      fumble_border
    )
  end
  
  def make_d100_text(dice_value, success_rate, critical_border, result_message)
    "D100 → #{dice_value} (≦ #{success_rate}／#{critical_border}) ⇒ #{result_message}"
  end
  
  def  look_up_damage_chart attribute, damage_value
    row = find_matched_row(damage_value, get_damage_chart_by_attribute(attribute))
    
    "負傷表：#{attribute}［#{damage_value}］ => #{row[:damage]} ｜ #{row[:name]} … #{row[:text]}"
  end
  
  def get_damage_chart_by_attribute attribute
    load_damage_chart()[attribute]
  end
  
  def find_matched_row damage_value, chart
    for row in chart do
      range = row[:range]
      
      if range[:min] <= damage_value && damage_value <= range[:max] then
        return row
      end
    end
  end
  
  def load_damage_chart
    chart_yaml = <<EOS
---
切断:
- :range:
    :min: 1
    :max: 5
  :name: 切り傷
  :text: 皮膚が切り裂かれる。
  :damage: 軽傷1
- :range:
    :min: 6
    :max: 10
  :name: 脚部負傷
  :text: 足が切り裂かれ、思わずひざまずく。
  :damage: 軽傷２／マヒ
- :range:
    :min: 11
    :max: 13
  :name: 出血
  :text: 斬り裂かれた傷から出血が続く。
  :damage: 軽傷３／ＤＯＴ：軽傷1
- :range:
    :min: 14
    :max: 16
  :name: 胴部負傷
  :text: 胴部に大きな傷を受ける。
  :damage: 軽傷４
- :range:
    :min: 17
    :max: 19
  :name: 腕部負傷
  :text: 腕に大きな傷を受ける。
  :damage: 重傷1／ＤＯＴ：軽傷1
- :range:
    :min: 20
    :max: 22
  :name: 腹部負傷
  :text: 腹部を深く切り裂かれる。
  :damage: 重傷２
- :range:
    :min: 23
    :max: 25
  :name: 大量出血
  :text: 傷は深く、そこから大量に出血する。
  :damage: 重傷２／ＤＯＴ：軽傷２
- :range:
    :min: 26
    :max: 28
  :name: 裂傷
  :text: 治りにくい傷をつけられる。
  :damage: 重傷３
- :range:
    :min: 29
    :max: 31
  :name: 視界不良
  :text: 頭部に受けた傷から血が流れ、視界がふさがれる。
  :damage: 重傷３／スタン
- :range:
    :min: 32
    :max: 34
  :name: 胸部負傷
  :text: 胸から腰にかけて大きく切り裂かれる。
  :damage: 致命傷1
- :range:
    :min: 35
    :max: 37
  :name: 動脈切断
  :text: 動脈が切り裂かれ、噴き出るように出血する。
  :damage: 致命傷1／ＤＯＴ：軽傷３
- :range:
    :min: 38
    :max: 39
  :name: 胸部切断
  :text: 傷が肺にまで達し、喀血する。
  :damage: 致命傷２
- :range:
    :min: 40
    :max: 1000
  :name: 脊髄損傷
  :text: 脊髄が損傷する。
  :damage: 致命傷２／放心、スタン、マヒ
銃弾:
- :range:
    :min: 1
    :max: 5
  :name: 腕部損傷
  :text: 銃弾が腕をかすめた。
  :damage: 軽傷２
- :range:
    :min: 6
    :max: 10
  :name: 腕部貫通
  :text: 銃弾が腕を貫く。痛みはあるが動作に支障はない。
  :damage: 軽傷３
- :range:
    :min: 11
    :max: 13
  :name: 胴部負傷
  :text: 胴部に銃弾をくらう。痛みで動きが鈍くなる。
  :damage: 軽傷４／スロウ：－３
- :range:
    :min: 14
    :max: 16
  :name: 肩負傷
  :text: 肩を貫かれる。骨が砕けたようだ。
  :damage: 重傷1
- :range:
    :min: 17
    :max: 19
  :name: 腹部負傷
  :text: 腹部が貫かれる。かろうじて内臓にダメージはないようだ。
  :damage: 重傷２
- :range:
    :min: 20
    :max: 22
  :name: 脚部貫通
  :text: 脚を銃弾に貫かれ、その場でひざまずく。
  :damage: 重傷２／マヒ
- :range:
    :min: 23
    :max: 25
  :name: 消化器系損傷
  :text: 胃などの消化器官にダメージを受ける。
  :damage: 重傷３
- :range:
    :min: 26
    :max: 28
  :name: 盲管銃弾
  :text: 身体に弾丸が深々と刺さる。激痛が走る。
  :damage: 重傷３／スロウ：－5
- :range:
    :min: 29
    :max: 31
  :name: 内臓損傷
  :text: いくつかの内臓にダメージを受ける。
  :damage: 致命傷1／スタン
- :range:
    :min: 32
    :max: 34
  :name: 胴部貫通
  :text: 腹部への攻撃が貫通し、出血する。
  :damage: 致命傷1／ＤＯＴ：軽傷1
- :range:
    :min: 35
    :max: 37
  :name: 胸部負傷
  :text: 銃弾で肺を貫かれる。
  :damage: 致命傷２
- :range:
    :min: 38
    :max: 39
  :name: 致命的な一撃
  :text: 銃弾が頭部に命中。ショックで意識を飛ばされる。
  :damage: 致命傷２／放心
- :range:
    :min: 40
    :max: 1000
  :name: 必殺の一撃
  :text: 銃弾が心臓の近くを貫く。動脈にダメージを受けたようだ。
  :damage: 致命傷２／ＤＯＴ：重傷1
衝撃:
- :range:
    :min: 1
    :max: 5
  :name: 打撲
  :text: 攻撃を受けた箇所がどす黒く腫れ上がる。
  :damage: 軽傷1
- :range:
    :min: 6
    :max: 10
  :name: 転倒
  :text: 衝撃で転倒する。
  :damage: 軽傷1／マヒ
- :range:
    :min: 11
    :max: 13
  :name: 平衡感覚喪失
  :text: 衝撃で三半規管にダメージを受ける。
  :damage: 軽傷２、疲労２
- :range:
    :min: 14
    :max: 16
  :name: ボディーブロー
  :text: 腹部に直撃。痛みが継続し、体力を奪う。
  :damage: 軽傷３／ＤＯＴ：疲労３
- :range:
    :min: 17
    :max: 19
  :name: 痛打
  :text: 胴部や脚部などに打撃を受ける。
  :damage: 軽傷４／スタン
- :range:
    :min: 20
    :max: 22
  :name: 頭部痛打
  :text: 頭部にクリーンヒット。意識がもうろうとする。
  :damage: 軽傷5／放心
- :range:
    :min: 23
    :max: 25
  :name: 脚部骨折
  :text: 攻撃が足に命中し、骨折する。
  :damage: 重傷1／スロウ：－5
- :range:
    :min: 26
    :max: 28
  :name: 大転倒
  :text: 激しい衝撃によって、負傷すると共に大きく体勢を崩す。
  :damage: 重傷1／マヒ、スタン
- :range:
    :min: 29
    :max: 31
  :name: 脳震盪
  :text: 脳が大きく揺さぶられ、意識が飛びそうになる。
  :damage: 重傷２／放心
- :range:
    :min: 32
    :max: 34
  :name: 複雑骨折
  :text: 攻撃を受けた部分が大きくひしゃげ、複雑骨折したようだ。
  :damage: 重傷３／放心、スタン
- :range:
    :min: 35
    :max: 37
  :name: 頭部裂傷
  :text: 頭部に命中。皮膚が大きく裂ける。
  :damage: 致命傷1、疲労３
- :range:
    :min: 38
    :max: 39
  :name: 肋骨負傷
  :text: 折れた肋骨が肺に突き刺さり、まともに呼吸を行なうことができない。
  :damage: 致命傷1／放心、スタン
- :range:
    :min: 40
    :max: 1000
  :name: 内臓損傷
  :text: 衝撃が身体の芯まで届き、内臓がいくつか傷ついたようだ。
  :damage: 致命傷２／ＤＯＴ：重傷1
灼熱:
- :range:
    :min: 1
    :max: 5
  :name: 火傷
  :text: 皮膚に小さな火傷を負う。
  :damage: 軽傷1
- :range:
    :min: 6
    :max: 10
  :name: 温度上昇
  :text: 熱によって、怪我だけではなく体力も奪われる。
  :damage: 軽傷２、疲労1
- :range:
    :min: 11
    :max: 13
  :name: 恐怖
  :text: 燃え上がる炎に恐怖を感じ、身体がすくんで動きが止まる。
  :damage: 軽傷３／放心
- :range:
    :min: 14
    :max: 16
  :name: 発火
  :text: 衣服や身体の一部に火が燃え移る。
  :damage: 軽傷３／ＤＯＴ：軽傷1
- :range:
    :min: 17
    :max: 19
  :name: 爆発
  :text: 爆発により吹き飛ばされ、転倒する。
  :damage: 重傷1／マヒ
- :range:
    :min: 20
    :max: 22
  :name: 大火傷
  :text: 痕が残るほどの大きな火傷を負う。
  :damage: 重傷２
- :range:
    :min: 23
    :max: 25
  :name: 熱波
  :text: 火傷と強力な熱により意識がもうろうとする。
  :damage: 重傷２／スタン
- :range:
    :min: 26
    :max: 28
  :name: 大爆発
  :text: 激しい爆発で吹き飛ばされ、ダメージと共に転倒する。
  :damage: 重傷３／マヒ
- :range:
    :min: 29
    :max: 31
  :name: 大発火
  :text: 広範囲に火が燃え移る。
  :damage: 重傷３／ＤＯＴ：軽傷1
- :range:
    :min: 32
    :max: 34
  :name: 炭化
  :text: 高熱のあまり、焼けた部分が炭化してしまう。
  :damage: 致命傷1
- :range:
    :min: 35
    :max: 37
  :name: 内臓火傷
  :text: 高温の空気を吸い込む、気道にも火傷を負ってしまう。
  :damage: 致命傷1／ＤＯＴ：軽傷1
- :range:
    :min: 38
    :max: 39
  :name: 全身火傷
  :text: 身体の各所に深い火傷を負う。
  :damage: 致命傷２
- :range:
    :min: 40
    :max: 1000
  :name: 致命的火傷
  :text: 身体の大部分に焼けどを負う。
  :damage: 致命傷２／スタン
冷却:
- :range:
    :min: 1
    :max: 5
  :name: 冷気
  :text: 軽い凍傷を受ける。
  :damage: 軽傷1
- :range:
    :min: 6
    :max: 10
  :name: 霜の衣
  :text: 身体が薄い氷で覆われ、動きが鈍る。
  :damage: 軽傷1／疲労1
- :range:
    :min: 11
    :max: 13
  :name: 凍傷
  :text: 凍傷により身体が傷つけられる。
  :damage: 軽傷２
- :range:
    :min: 14
    :max: 16
  :name: 体温低下
  :text: 冷気によって体温を奪われる。
  :damage: 軽傷３／ＤＯＴ：疲労1
- :range:
    :min: 17
    :max: 19
  :name: 氷の枷
  :text: 肘や膝などが氷で覆われ、動きが取りにくくなる。
  :damage: 重傷1／マヒ
- :range:
    :min: 20
    :max: 22
  :name: 大凍傷
  :text: 身体の各所に凍傷を受ける。
  :damage: 重傷1／ＤＯＴ：疲労２
- :range:
    :min: 23
    :max: 25
  :name: 氷の束縛
  :text: 下半身が凍りつき、動くことができない。
  :damage: 重傷２／マヒ
- :range:
    :min: 26
    :max: 28
  :name: 視界不良
  :text: 頭部にも氷が張り、視界がふさがれる。
  :damage: 重傷２／スタン
- :range:
    :min: 29
    :max: 31
  :name: 腕部凍結
  :text: 腕が凍りづけになり、動かすことができない。
  :damage: 重傷３／放心
- :range:
    :min: 32
    :max: 34
  :name: 重度凍傷
  :text: さらに体温が低下し、深刻な凍傷を受ける。
  :damage: 致命傷1
- :range:
    :min: 35
    :max: 37
  :name: 全身凍結
  :text: 全身が凍りづけになる。
  :damage: 致命傷1／ＤＯＴ：疲労２
- :range:
    :min: 38
    :max: 39
  :name: 致命的凍傷
  :text: 身体全身に凍傷を受ける。
  :damage: 致命傷２
- :range:
    :min: 40
    :max: 1000
  :name: 氷の棺
  :text: 完全に氷に閉じ込められる。
  :damage: 致命傷２／スタン、マヒ
電撃:
- :range:
    :min: 1
    :max: 5
  :name: 静電気
  :text: 全身の毛が逆立つ。
  :damage: 疲労３
- :range:
    :min: 6
    :max: 10
  :name: 電熱傷
  :text: 電流によって傷つく。
  :damage: 疲労1、軽傷1
- :range:
    :min: 11
    :max: 13
  :name: 感電
  :text: 電流で傷つくと共に、身体が軽くしびれる。
  :damage: 疲労２、軽傷２
- :range:
    :min: 14
    :max: 16
  :name: 閃光
  :text: 激しい電光により、一時的に視界がふさがれる。
  :damage: 軽傷３／スタン
- :range:
    :min: 17
    :max: 19
  :name: 脚部感電
  :text: 電流により脚がしびれ、動けなくなる。
  :damage: 重傷1／マヒ
- :range:
    :min: 20
    :max: 22
  :name: 大電熱傷
  :text: 身体の各所が電流によって傷つく。
  :damage: 疲労２、重傷２
- :range:
    :min: 23
    :max: 25
  :name: 腕部負傷
  :text: 電流で腕がしびれ、動けなくなる。
  :damage: 軽傷1、重傷２／放心
- :range:
    :min: 26
    :max: 28
  :name: 大感電
  :text: 電流によって身体中がしびれ、動けなくなる。
  :damage: 重傷２／スタン、マヒ
- :range:
    :min: 29
    :max: 31
  :name: 一時心停止
  :text: 強力な電撃のショックにより、心臓がほんの一瞬だけ止まる。
  :damage: 疲労３、重傷３
- :range:
    :min: 32
    :max: 34
  :name: 大電流
  :text: 全身に電流が駆け巡る。
  :damage: 重傷３／放心、マヒ
- :range:
    :min: 35
    :max: 37
  :name: 致命電熱傷
  :text: 全身が電流によって傷つく。
  :damage: 重傷1、致命傷1
- :range:
    :min: 38
    :max: 39
  :name: 心停止
  :text: 強力な電撃のショックにより、心臓が一時的に止まる。死の淵が見える。
  :damage: 疲労３、重傷1、致命傷1
- :range:
    :min: 40
    :max: 1000
  :name: 組織炭化
  :text: 全身が電流で焼かれ、あちこちの組織が炭化する。
  :damage: 致命傷２／スタン
EOS

    YAML.load chart_yaml
  end
  
end
