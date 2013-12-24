
[How to make a language file]

You can make a language file in this directory,
file name "(language name).txt"
 ex.) English.txt

But if file name start with "_", it is ignored. just like this README text.

(language name) must be in English. otherway it occure character code problem.
Language display name can be written in language file ownself.

The language file format is this.

language = English
title = DodontoF
loginWindowTitle = Login

Left hand is keyword for what text be changed.
Right hand is displayed characters.
For example, the first line means language display name.
second line is browser's title

The line start with "#" is passed becoase it's a comment line.

When you wanto to change Dice Bot Name
define like this

DiceBotName_ArsMagica = Ars Magica

it's means

DiceBotName_(Game Type) = (Name want to changed)

Game Type was defined in
 src_ruby/diceBotInfos.rb
 params "gameType"
please look it.


If you make a any language text, please send it to http://www.dodontof.com/
BBS, Mail, or Twitter, anyway!

Best Regard.
