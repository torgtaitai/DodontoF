
語言套件的製作方法

語言套件請放在以下這個資料夾裡

English.txt

像這個樣子，製作一個「言語名稱.txt」的純文字檔案來製作。
不過，像這個README檔案一樣，名稱前面「_」字頭的檔案將會被無視。

語言名稱請必定要使用中文，否則會出現編碼問題。
畫面內表示的語言名稱則記載於純文字文件內部

純文字文件的內容裡，

language = English
title = DodontoF
loginWindowTitle = Login

會有這樣的格式。
左邊是代表要改變什麼地方的文字的關鍵字。
右邊是改變之後的文字
例如最開始的language 是語言顯示出來的名字。
title就是顯示在瀏覽器上的標題了

「#」 起始的是標注行，會被無視。

要變更DiceBot名稱的場合

DiceBotName_ArsMagica = アルス☆マギカ

就像這樣子

DiceBotName_(DiceBot的類型） = 想變更的名字

像這樣追加定義就可以了。
DiceBot類型並沒有顯示在畫面上
src_ruby/diceBotInfos.rb
請到這個檔案
gameType
以這個定義來尋找參考

若是製作了多國語言套件檔案，請一定要傳到どどんとふ官方網站去
留言板或是電子郵件或是Twitter皆可

以上。