<h1 id="manualTitle">「どどんとふ」マニュアル</h1>
<!-- <p align="right">d(odonto)f - a tool of online session..</p> -->
<p align="right">ALL YOU NEED IS THIS, on online TRPG session.</p>
<p align="right">presented by たいたい竹流(taitai takeru)　from <a href="http://www.dodontof.com">http://www.dodontof.com</a><br>-- modified BSD licenses
</p>
<hr/>
<br/>

<p><b id="forBegining">【注：どどんとふを初めて使う方へ】</b></p>

どどんとふはWEBツールですので、<b>使用するためにダウンロードは必要ありません</b>。<br/>
<a href="http://www.dodontof.com/">「どどんとふ＠えくすとり〜む」TOPページ</a>から<br/>
<br/>
<img src="./image/transparent.gif" height="20" width="16" align="left"/>
<img src="./image/clover.gif" align="left"/>
<img src="./image/transparent.gif" height="20" width="16" align="left"/>
クローバーのアイコンを選択して、好きなどどんとふサーバを開いて下さい。<br/>
それだけで どどんとふを動かすことが出来ます<br/>
<br/>

<br/><hr/><br/>

<h2 id="howtobook">どどんとふ解説書</h2>
<p align="left">
どどんとふの使用方法については<br>
<!-- howtoBookUrl -->　　<a href="http://www.melonbooks.com/index.php?main_page=maker_affiliate_go&affiliate_id=AF0000028347">
<img src="./image/DManual201708.jpg" /><br>
こちらの解説書を参照下さい。</a><br>
</p>

<br/><hr/><br/>

<p>
このマニュアルではどどんとふの<a href="#howToSetting">自前サーバの設置方法</a>や技術的な観点について記載しています。</br>
</p>

<br/><hr/><br/>

<h2 id="index">目次</h2>
<!-- INDEX-AREA -->
<ul class="index-list">
  <li><a href='#howtobook'>どどんとふ解説書</a></li>
  <li><a href='#aboutDodontoF'>「どどんとふ」って何？</a></li>
  <li><a href='#execteEnviroment'>実行環境</a></li>
  <li><a href='#howToUse'>使用方法</a></li>
  <li>
    <a href='#howToSetting'>設置方法</a>
    <ul>
      <li>
        <a href='#cgiServerSetting'>CGIサーバの用意</a>
        <ul>
          <li><a href='#cgiServerSettingOnCommonRentalServer'>レンタルサーバを用意する場合の注意事項</a></li>
        </ul>
      </li>
      <li><a href='#forOwnServerAdmin'>自前サーバ運営者へのアドバイス</a></li>
      <li><a href='#download'>実行ファイル一式のダウンロード</a></li>
      <li><a href='#dodontoFSettingMySQL'>設置方法その２：MySQLサーバ編</a></li>
      <li><a href='#howToCheckSetting'>動作確認方法</a></li>
      <li><a href='#othersSetting'>お知らせメッセージの変更</a></li>
      <li><a href='#howToVersionUp'>バージョンアップ方法</a></li>
    </ul>
  </li>
  <li>
    <a href='#forDevelopment'>開発向けの詳細</a>
    <ul>
      <li>
        <a href='#aboutCompile'>コンパイル方法について</a>
        <ul>
          <li><a href='#getAdobeFlexSdk'>Adobe Flex SDKの準備</a></li>
          <li><a href='#compileUsingRake'>Rakeを使用したコンパイル</a></li>
          <li><a href='#compileManually'>手動コンパイル</a></li>
        </ul>
      </li>
      <li><a href='#aboutDiceBot'>ダイスボットの実装について</a></li>
    </ul>
  </li>
  <li>
    <a href='#aboutWebIf'>WEB IFについて</a>
    <ul>
      <li><a href='#whatIsWebIf'>WEB IFとは？</a></li>
      <li><a href='#webIfBasicFormat'>基本フォーマット</a></li>
      <li><a href='#webIf_getBusyInfo'>getBusyInfo：サーバ負荷情報の取得</a></li>
      <li><a href='#webIf_getServerInfo'>getServerInfo：サーバの各種情報取得</a></li>
      <li><a href='#webIf_getRoomList'>getRoomList：部屋情報一覧の取得</a></li>
      <li><a href='#webIf_getLoginInfo'>getLoginInfo：初期ログイン用データ取得</a></li>
      <li><a href='#webIf_getLoginUserInfo'>getLoginUserInfo：ログインユーザーの情報取得・更新</a></li>
      <li><a href='#webIf_chat'>chat：チャットデータの取得</a></li>
      <li><a href='#webIf_talk'>talk：チャットへの発言</a></li>
      <li><a href='#webIf_getChatColor'>getChatColor：文字色取得</a></li>
      <li><a href='#webIf_addCharacter'>addCharacter：キャラクター追加</a></li>
      <li><a href='#webIf_changeCharacter'>changeCharacter：キャラクターの変更</a></li>
      <li><a href='#webIf_getRoomInfo'>getRoomInfo：プレイルーム情報取得</a></li>
      <li><a href='#webIf_setRoomInfo'>setRoomInfo：プレイルームの情報設定</a></li>
      <li><a href='#webIf_addMemo'>addMemo：共有メモ追加</a></li>
      <li><a href='#webIf_changeMemo'>changeMemo：共有メモ追加</a></li>
      <li><a href='#webIf_addMessageCard'>addMessageCard：メッセージカード追加</a></li>
      <li><a href='#webIf_refresh'>refresh：各種情報取得</a></li>
      <li><a href='#webIf_uploadImageData'>uploadImageData：画像ファイルアップロード</a></li>
    </ul>
  </li>
  <li>
    <a href='#aboutLicense'>ライセンスについて</a>
    <ul>
      <li><a href='#fileConstraction'>ファイル構成</a></li>
      <li>
        <a href='#aboutLibrary'>ライブラリ・画像データ等について</a>
        <ul>
          <li><a href='#characterImage'>キャラクター画像</a></li>
          <li><a href='#imageUploadSpace'>立ち絵画像</a></li>
          <li><a href='#tubeloc'>tubeloc</a></li>
          <li><a href='#Hi-ReS-Stats'>Hi-ReS-Stats</a></li>
          <li><a href='#corelib'>corelib</a></li>
          <li><a href='#Archive_Tar_Minitar'>Archive::Tar::Minitar</a></li>
          <li><a href='#as3-msgpack'>as3-msgpack</a></li>
          <li><a href='#msgpack-pure'>msgpack-pure</a></li>
          <li><a href='#msgpack-pure-ruby'>msgpack-pure-ruby</a></li>
          <li><a href='#simple-color-picker'>simple-color-picker</a></li>
          <li><a href='#icons'>各種アイコン用画像集</a></li>
          <li><a href='#standingGraphics'>サンプル用立ち絵</a></li>
          <li><a href='#jsonPerser'>jsonParser.rb</a></li>
          <li><a href='#flexlib'>flexlib</a></li>
          <li><a href='#otherLibrary'>その他</a></li>
        </ul>
      </li>
    </ul>
  </li>
  <li>
    <a href='#others'>その他</a>
    <ul>
      <li><a href='#aboutNaming'>名前の由来について</a></li>
    </ul>
  </li>
  <li><a href='#caution'>注意事項</a></li>
  <li><a href='#history'>履歴</a></li>
</ul>
<!-- INDEX-AREA-END -->

<h2 id="aboutDodontoF">「どどんとふ」って何？</h2>
「どどんとふ」はTRPGのオンラインセッションをお手軽＆楽しく遊ぶために作られたツールです。<br>
ブラウザだけで全ての操作が可能。<br>
マップ表示もキャラクター配置もチャットもイニシアティブ管理も、さらには動画や音楽の共有まで楽しめます。<br>
OSをほとんど気にせず動作します。WindowsでもMacでもUNIXでもOK。<br>
<br>
マップは四角形で区切られたいわゆる「スクウェアマップ」タイプです。D＆D4版などが代表例ですね。<br>
とりあえず使ってみたい人は冒頭の<a href="#forBegining">【注：どどんとふを初めて使う方へ】</a>と「<a href="#howtobook">どどんとふ解説書</a>」を確認ください。<br>
<br>
自分で「どどんとふ」を設置してみたい！と思った方は「<a href="#howToSetting">設置方法</a>」を参照してください。<br>
<br>

<h2 id="execteEnviroment">実行環境</h2>
「どどんとふ」を使用するには、インターネットに接続可能なPCとブラウザ、そしてブラウザへのAdobe Flash Playerのインストールが必須になります。<br>
Windows版だと下記が最新のはず。<br>
<a href="http://www.adobe.com/shockwave/download/index.cgi?Lang=Japanese&P1_Prod_Version=ShockwaveFlash">http://www.adobe.com/shockwave/download/index.cgi?Lang=Japanese&P1_Prod_Version=ShockwaveFlash</a><br>
Flashって何？という方はすでに入っている可能性もありますので、<br>
とりあえず「どどんとふ」のトップページ<br>
<a href="http://www.dodontof.com/DodontoF/DodontoF.swf">http://www.dodontof.com/DodontoF/DodontoF.swf</a><br>
にアクセスしてみてください。<br>
何も画面が表示されないなど不具合があった場合に上記のリンクからFlash Playerをインストールして再度接続してみてください。<br>

<br>
<h2 id="howToUse">使用方法</h2>
<a href="#howtobook">使用方法の詳細については、どどんとふ解説書を参照下さい</a>。</br>
<br>

<br><hr />
<h2 id="howToSetting">設置方法</h2>

「どどんとふ」は公開されているサーバを使う事で誰でも利用が可能ですが、<br>
大抵の場合、公開サーバは多数の人が使用しているため重いです。<br>
この対策として、自分たち専用のサーバを用意することで快適な環境を作製する事ができます。<br>
<b>定期的にオンセを実施する方は自前サーバの設置を検討してください。　是　非　。</b><br>
<br>
<br>
<font size= "5">　　<a href="http://www.dodontof.com/Download/howToInstall/index.html">サ　ー　バ　の　設　置　手　順　は　こ　ち　ら</a></font>
<br>
<br>
上記の手順が一番分かりやすいですが、それ以外の場所や方法でサーバを設置したい方や詳細な手順については以下を参照ください。<br>
<br>
<h3 id="cgiServerSetting">CGIサーバの用意</h3>
<p>まず、Rubyの動くCGIサーバが必要です。<br>
サポートバージョンは以下の通り。</p>
<p>「どどんとふ」を動かすために必要なRubyのバージョン：1.8.7 以上</p>
<ul>
  <li>Ruby 1.9を使用する場合は、CGIライブラリのバグが修正された1.9.3</li>
</ul>
<p>この条件を満たさないと正常に動作させることはできません。</p>
<h4 id="cgiServerSettingOnCommonRentalServer">レンタルサーバを用意する場合の注意事項</h4>
レンタルサーバーを使用する場合、そのレンタルサーバがCGIチャットの設置を許容しているかの確認が必要です。<br>
以下、どどんとふに利用可能なレンタルサーバ、利用不可なレンタルサーバについて。<br>
<br>
<b>○利用可能なレンタルサーバ</b><br>
<ul>
<li><a href="http://www.sakura.ad.jp/">さくらインターネット</a>（<a href="http://sakura.cb-faq.com/faq/public/app/servlet/qadoc?QID=000487">参照</a>）7人程度までは負荷に問題なし。</li>
<li><a href="http://www.xserver.ne.jp/">エックスサーバー</a>（<a href="http://dfes.blog129.fc2.com/blog-entry-80.html">参照</a>：10人未満での運用は問題なし。負荷が高すぎる場合は運営から通達があります）<br>
→Rubyのバージョンを変えるために、CGIのパスは「#!/usr/bin/ruby2.0.0」に変更願います。</li>
<br>
</ul>

<b>×利用不可なレンタルサーバ</b><br>
<ul>
<li><a href="http://land.to/">land.to</a>（<a href="http://www.land.to/kiyaku_m.php">参照</a>）</li>
<li><a href="http://moover.jp/">Mover（<a href="http://moover.jp/faq/view_faq.php">参照</a>）</li>
<li><a href="http://www.wisnet.ne.jp/">WISNET</a>（Rubyが無いため動作不可）</li>
<li><a href="http://www.fsv.jp/">ファーストサーバー</a>（Rubyが無いため動作不可）</li>
<li><a href="http://atpages.jp/">@PAGES</a>（CGIに制限が掛かったりと問題が多発したため非推奨）</li>
<li><a href="http://www.extrem.jp/">エクストリムレンタルサーバー</a>（Rubyのバージョンが1.8.5と古いためサポート対象外に）</li>
</ul>
<br>
利用不可なサーバに現状で設置されている方は移設をお願いいたします。<br>
<br>
<br>
どどんとふではこれらのレンタルサーバを借りてのCGI設置を大前提としています。<br>
<br>
もちろん、自分のPCをサーバにして開放することも出来ますが、それ相応の知識と手間、セキュリティー意識が必要となりますので、あくまで自己責任でお願いいたします。<br>
作者はサーバ側は詳しくないのでそこを質問されても回答できませんので。<br>
<br>
<br>
<h3 id="forOwnServerAdmin">自前サーバ運営者へのアドバイス</h3>
<br>
もしもレンタルサーバではなく自前でサーバを構築している場合は、<br>
　gem install msgpack<br>
を行ったうえで、src_ruby/config.rb の $isMessagePackInstalled を true にすると処理精度の向上が期待できます。<br>
<br>
<br>
以下、外部のCGIサーバサービスを使用する場合についての設定手順解説を述べます。<br>
<br>

<h3 id="download">実行ファイル一式のダウンロード</h3>
「どどんとふ」本体を以下からダウンロードしてください。<br>
<a href="http://www.dodontof.com/ja/home/dodontofdownload.html">http://www.dodontof.com/ja/home/dodontofdownload.html</a><br>
慣れないうちは上記から「安定版」と書かれたバージョンを使用してください。
チャレンジャーな貴方は以下から「最新版」をご利用ください。<br>
<a href="http://www.dodontof.com/DodontoF/newestVersion.html">http://www.dodontof.com/DodontoF/newestVersion.html</a><br>
DodontoF_xx_xx_xx.zipを展開します。<br>
<br>
展開した中身が以下のようなディレクトリ構成になっていることを確認します。<br>
<br>
DodontoF_WebSet<br>
　｜<br>
　＋public_html<br>
　｜　｜<br>
　｜　＋DodontoF<br>
　｜　｜<br>
　｜　＋imageUploadSpace<br>
　｜<br>
　＋saveData<br>
<br>
構成を確認したらその中のファイル<br>
<br>
　DodontoF_WebSet/public_html/DodontoF/DodontoFServer.rb<br>
<br>
の先頭行に Ruby へのパスを記載してください。<br>
パスの情報は使用するCGIサーバの指示に従ってください<br>
<ul>
<li>「さくらインターネット」なら「<a href="http://support.sakura.ad.jp/manual/rs/tech_cgi.html">2.2. プログラムのコマンドパス</a>」</li>
<li>「エックスサーバー」なら「<a href="http://www.xserver.ne.jp/man_program_cgi.php">CGI関連の仕様一覧</a>」</li>
<li>「エクストリムレンタルサーバー」なら「<a href="http://www.extrem.jp/guide_cgi.php">CGIのパス・パーミッションについて</a>」（perlのパスをrubyに読み替えて下さい）</li>
<!--<li>「お名前.com」なら「<a href="">CGIのパスを教えてください</a>」</li>-->
</ul>
を確認してください。<br>
＃と言いつつ、上記レンタルサーバなら変更は不要です。<br>
<br>
このファイルは文字コードがUTF-8、改行コードはUNIX方式になります。<br>
このためサクラエディタ等のそれ相応のエディタで編集するよう、またパス編集時にRubyのスクリプトのコマンド引数を変更しないように注意してください。<br>
具体的には、デフォルトの<br>
<br>
#!/usr/local/bin/ruby -Ku<br>
<br>
を変更するのであれば、<br>
<br>
#!/usr/sbin/ruby -Ku<br>
<br>
のように -Ku は変えないでおいてください。<br>
<br>
パスの編集が完了したら、CGIサーバにファイルの転送を行います。<br>
　注：ファイルの転送は必ず全ファイルともバイナリモードで行ってください。<br>
　　上述の文字コードの関係上、アスキーモードで転送してしまうとサーバの処理が失敗することになります。。<br>
　　WinddowsではFFFTPという転送ツールが実績もありお勧めです。「B」マークのアイコンを押してバイナリ転送してください。<br>
<br>
一般的にはCGIサーバのディレクトリは<br>
<br>
/ （＜ルートディレクトリ<br>
　｜<br>
　＋public_html（＜ディレクトリ。この下に公開用のファイルを置く）<br>
　｜<br>
　＋その他ディレクトリ<br>
<br>
という構成になっています。<br>
<br>
＃　もしも使用しているサーバに pubilc_html が存在しない場合は…<br>
＃　しょうがないのでCGIサーバのどこかに DodontoF_WebSet をそのままゴロっと置いてください。<br>
＃　例えば、 /anyDirecory の下におくとすれば<br>
＃　/anyDirecory<br>
＃　　｜<br>
＃　　＋DodontoF_WebSet<br>
＃　　　　｜<br>
＃　　　　＋public_html<br>
＃　　　　｜<br>
＃　　　　：<br>
＃　　こんな感じですね。<br>
＃　後は / を /anyDirecory と読み替えてください。<br>
<br>
<br>
構成を確認できたら、どどんとふ展開した時に出来る<br>
<br>
　DodontoF_WebSet/public_html<br>
<br>
の中身を、CGIサーバの<br>
<br>
　/public_html<br>
<br>
の下に転送してください。<br>
<br>
また、どどんとふ展開時の<br>
 DodontoF_WebSet/saveData<br>
は、CGIサーバの public_html と同じ階層においてください。<br>
つまり、置いた後のCGIサーバの状態は<br>
<br>
/<br>
　｜<br>
　＋public_html<br>
　｜　｜<br>
　｜　＋DodontoF<br>
　｜　｜<br>
　｜　＋imageUploadSpace<br>
　｜<br>
　＋saveData<br>
<br>
になります。どどんとふ展開時の DodontoF_WebSet の中身をそのままCGIサーバに突っ込む感じですね。<br>
<br>
転送が完了したら、以下の記載のとおりファイル・ディレクトリの権限(属性)を変更します。<br>
<br>
/<br>
　｜<br>
　＋public_html<br>
　｜　｜<br>
　｜　＋DodontoF -> 705(実行権限あり)<br>
　｜　｜　｜<br>
　｜　｜　＋DodontoFServer.rb -> 700(実行権限あり)<br>
　｜　｜　｜<br>
　｜　｜　＋log.txt -> 600(書き込み権限あり)<br>
　｜　｜　｜<br>
　｜　｜　＋log.txt.0 -> 600(書き込み権限あり)<br>
　｜　｜　｜<br>
　｜　｜　＋saveDataTempSpace -> 705(実行権限あり)<br>
　｜　｜　｜<br>
　｜　｜　＋fileUploadSpace -> 705(実行権限あり)<br>
　｜　｜　｜<br>
　｜　｜　＋replayDataUploadSpace -> 705(実行権限あり)<br>
　｜　｜<br>
　｜　＋imageUploadSpace -> 705(実行権限あり)<br>
　｜　　　｜<br>
　｜　　　＋smallImages -> 705(実行権限あり)<br>
　｜<br>
　＋saveData -> 705(実行権限あり)<br>
<br>
<br>
上記の設定で大低のレンタルサーバの指定通りになると思います。<br>
参考までに、各レンタルサーバの設定については<br>
<ul>
<li>「さくらインターネット」なら「<a href="http://support.sakura.ad.jp/manual/rs/tech_cgi.html">2.1. ファイル、ディレクトリの設定</a>」</li>
<li>「エックスサーバー」なら「<a href="http://www.xserver.ne.jp/man_program_cgi.php">CGI関連の仕様一覧</a>」</li>
<li>「エクストリムレンタルサーバー」なら「<a href="http://www.extrem.jp/guide_cgi.php">CGIのパス・パーミッションについて</a>」
<!--<li>「お名前.com」なら「<a href=""></a>」</li>-->
</ul>
を参照下さい。<br>
<br>
以上で設置作業は完了です。<br>
<br>
<a href="#howToCheckSetting">動作確認</a>を行いましょう。
問題があるようであれば、もう一度設定を見直してみて下さい。<br>
<br>
<br>
また、余力があるようであれば<a href="#othersSetting">お知らせメッセージの変更</a>も行っておきましょう。<br>
自分専用スペースであることをアピールできるとステキですねっ！<br>
<br>
ここまで完了すれば運用環境は完了です。<br>
お疲れ様でした。<br>
<br>
<br>
よりコダワリの設定を行いたい方は次の項も確認ください。。<br>
<br>
<h3 id="dodontoFSettingMySQL">設置方法その２：MySQLサーバ編</h3>
次に、MySQLというデータベースを使用してセーブデータの管理を行う場合について。<br>
「MySQLって何？データベースって聞いたことあるようなないような」<br>
と言う方はググって調べるか、あるいは諦めましょう。<br>
<br>
この設定を行うと「どどんとふ」の動作が軽くなる場合があります。<br>
逆に言えば、軽くならない場合もあります。<br>
そもそも、設定しなくても従来通りに使用は可能ですのでそこまで問題にはなりません。<br>
<br>
ですので、初めてサーバを立てるのであればこの設定は無理して実施する必要はありません。<br>
判っている人が、より快適さを追求するのであれば、こちらにTryしましょう。<br>
そして不具合があるようなら戻しましょう。<br>
＃遊べればいいんですよ遊べれば！<br>
<br>
<br>
では設定方法について。<br>
ファイル<br>
<br>
　src_ruby/config.rb<br>
の
<pre><code>
#MySQLを使用する場合のDB設定。
$databaseHostName = "127.0.0.1"
$databaseName = "databaseName"
$databaseUserName = "user"
$databasePassword = "password"
</code></pre>
の部分を上から順番に接続先ホスト名、データベース名、DBユーザー名、DBパスワードに設定します。
接続先ホスト名はデフォルトの localhost で問題ないと思いますが、Windowsサーバの場合は 127.0.0.1 にする必要があります。<br>
その他の設定値も含めて、使用しているサーバの設定に従うようにして下さい。<br>
<br>
同様に、同じファイルの
<pre><code>
#セーブデータの管理方法(nil/"mysql")
$dbType = nil
</code></pre>
の部分を
<pre><code>
#セーブデータの管理方法(nil/"mysql")
$dbType = "mysql"
</code></pre>
に変更して下さい。<br>
<br>
以上で設置作業は完了です。<br>
<br>
<a href="#howToCheckSetting">動作確認</a>を行ってください。<br>
<br>
<br>
<h3 id="howToCheckSetting">動作確認方法</h3>
ブラウザをを立ち上げて、アップロードしたCGIサーバの<br>
 DodontoFServer.rb<br>
を開いてください。<br>
設置が正しく行われている場合は、<br>
<br>
「どどんとふ」の動作環境は正常に起動しています。<br>
<br>
のメッセージが、あるいはMySQLの設定を行っている場合は<br>
<br>
「どどんとふ（MySQL）」の動作環境は正常に起動しています。<br>
<br>
のメッセージが画面に表示されます。<br>
表示されない場合は、 DodontoFServer.rb のファイル先頭のRubyのパス指定が間違っている可能性があります。<br>
「<a href='#howToSetting'>設置方法</a>」をよく読んでもう一度確認してみてください。<br>
<br>
メッセージ表示が確認できたら、次は<br>
 DodontoF.swf<br>
を開いてください。<br>
「どどんとふ」のログイン画面が表示されれば成功です。<br>
<br>
<br>
<h3 id="othersSetting">お知らせメッセージの変更</h3>
ログイン画面にに表示される「お知らせ」は loginMessage.html を書き換えることで変更可能です。<br>
身内だけの使用なのか、他の人も使っていいのか、サーバのメンテナンス時期やサークルのPR等をここに記述するとわかりやすいでしょう。<br>
変更後にログイン画面を表示して内容を確認するのを忘れないようにね！<br>
<br>
以上で設置に必要な作業は完了です。<br>
お疲れ様でした。<br>
<br>
<br>
<h3 id="howToVersionUp">バージョンアップ方法</h3>
上記の手順をすべて実施した上で、最新版の「どどんとふ」へバージョンをあげる場合。<br>
<br>
構築済みの既存「どどんとふ」環境から<br>
　/pubilc_html/DodontoF/src_ruby/config.rb<br>
だけを取り出しておきましょう。<br>
<br>
そしてここからがポイントなのですが、config.rbの中で書き換えている箇所を<br>
config_local.rb というファイルに別出ししましょう。<br>
（すでに config_local.rb ファイルを作ったことがある人はこの手順はパスして下さい。）<br>
<br>
注意点は config_local.rb の文字コードはUTF-8、改行コードはUNIX系のLF（つまり\nのみ）にするという事。<br>
多分何を言っているか分からない人が大半だと思いますので、<br>
既存の config.rb をコピーして、config_local.rb という名前にして、変更していない行を削る形でファイルを作成してやってください<br>
<br>
こんな感じです。<br>
<pre>
<code>
<i>###config_local.rb の記述例##</i>
#サーバにログインする事のできる限界人数。
$limitLoginCount = 10

#プレイルームの最大数
$saveDataMaxCount = 5

#チャットの過去ログ大量保管を許可するかの設定
$IS_SAVE_LONG_CHAT_LOG = false
</code>
</pre>
もう一度繰り返しますが、 config.rb をコピーして config_local.rb を作製してください。<br>
新規ファイルで作製して「上手く動かないよー」なんて言わないように。この点だけは要注意。<br>
<br>
作製できたら、config_local.rb を config.rb と同じく src_ruby ディレクトリに置きます。<br>
<br>
config_local.rb の設置ができたら、後は<br>
<a href="http://www.dodontof.com/ja/home/dodontofdownload.html">http://www.dodontof.com/ja/home/dodontofdownload.html</a><br>
からDodontoF.zip を入手し、圧縮ファイルを展開。<br>
展開した中身の<br>
<br>
　DodontoF_WebSet/pubilc_html/DodontoF<br>
<br>
を既存環境の<br>
<br>
　/pubilc_html/DodontoF<br>
<br>
にディレクトリ毎全て上書きを行ってください。<br>
<br>
後は<a href="#howToCheckSetting">動作確認方法</a>を参考に動作チェックを行ってください。<br>
<br>
以後、設定値を変更したい場合は config.rb ではなく config_local.rb を書き換えるようしてください。<br>
こうする事で展開した圧縮媒体を直接上書きするだけで設定を保持したままバージョンアップができるようになります。<br>
<br>
<br>
追記：<br>
MySQLデータベース機能はお試し版のため従来の機能と両立する方法もあります。<br>
その場合は、<br>
１．<br>
src_ruby/config.rbの$dbTypeを<br>
$dbType = nil<br>
に戻す。<br>
２．<br>
DodontoFServerMySql.rb<br>
に他の.rbファイルと同じように実行権限を与えて、Rubyへのファイルパスを先頭行に記述する。<br>
これで<br>
DodontoF.swf?mode=mysql<br>
にアクセスするとMySQL機能を使い、普通に<br>
DodontoF.swf<br>
にアクセスすると普段のファイル機能を使うようになります。<br>
<br>
<br>
<h2 id="forDevelopment">開発向けの詳細</h2>
<br>
以下はソースコードの中身に興味がある人用の情報です。<br>
単純に利用するだけであれば読まなくでも問題ありません。<br>
<br>
<h3 id="aboutCompile">コンパイル方法について</h3>
<p>
  「どどんとふ」でコンパイルして作成する必要があるのはFlex（ActionScript）の生成ファイル<br>
  DodontoF.swf<br>
  のみです。
</p>
<p>以下、コンパイル方法について述べます。</p>

<h4 id="getAdobeFlexSdk">Adobe Flex SDKの準備</h4>
<p>
  コンパイルにはAdobe Flex SDKが必要です。<br>
  <a href="http://sourceforge.net/adobe/flexsdk/wiki/Download%20Flex%203/">http://sourceforge.net/adobe/flexsdk/wiki/Download%20Flex%203/</a><br>
  から 3.6.0.16995A の Adobe Flex SDK をダウンロードします。<br>
  <!--
  http://opensource.adobe.com/wiki/display/flexsdk/Download+Flex+4<br>
  から Latest Milestone Release Builds の一番新しいリリースの Open Source Flex SDK をダウンロードします。<br>
  -->
  ダウンロードファイルを展開後、binディレクトリへパスを通しておきます。
</p>
<p>
  またJavaも必要なため、<br>
  <a href="http://www.oracle.com/technetwork/java/javase/downloads/index.html">http://www.oracle.com/technetwork/java/javase/downloads/index.html</a><br>
  から「JDK」（Java SE Development Kit）をダウンロードし、インストールしておきます。
</p>

<h4 id="compileUsingRake">Rakeを使用したコンパイル</h4>
<p>
  Ruby 1.9以降がインストールされていて正しくパスが通されている場合は、Rubyに標準で添付されているビルドツールRakeを使用して簡単にコンパイルすることができます。<br>
  DodontoF ディレクトリで以下を実行すると、DodontoF.swf が DodontoF ディレクトリに生成されます。
</p>
<pre><code>rake swf</code></pre>

<h4 id="compileManually">手動コンパイル</h4>
<p>上記のRakeが使えない場合は、手動でコンパイルを行ってください。</p>
<p>
  DodontoF/src_actionScript ディレクトリで以下を実行します。<br>
  LinuxやOSXのようなUNIX環境では、<code>mxmlc.exe</code> を <code>mxmlc</code> に変えてください。
</p>
<pre><code>mxmlc.exe -target-player=10.0.12 -define=TEST::isTest,false -define=COMPILE::isReplayer,false -define=COMPILE::isMySql,false -include-libraries+=./corelib/bin/corelib.swc  -o ../DodontoF.swf DodontoF.mxml</code></pre>

<p>
  これで DodontoF.swf が作成されるはずです。<br>
  作成された DodontoF.swf を DodontoF 直下に移動してください。
</p>
<p>コンパイル方法は以上です。</p>
<p>
  上記以外はRubyのコードになりますのでファイルを直接編集してもらえれば反映されます。<br>
  ソースコードの内、〜Testで終わるファイルはUnitTest用ですので通常の運用では変更する必要はありません。
</p>

<h3 id="aboutDiceBot">ダイスボットの実装について</h3>
どどんとふには標準で大量のダイスボットが付いていますが、それでも不足していたり、新しい機能を追加したくなる場合があるでしょう。<br>
そんな場合にはRubyのスクリプトを書き換えることで対応が可能です。<br>
<br>
ダイスボットの自作方法については、<br>
　<a href="src_bcdice/test/README.html">src_bcdice/test/README.html</a><br>
を参照してください。<br>
<br>
（注意：以前はここで createDiceInfos.rb というコマンドを叩きましたが、不要になりました。代わりに以下の手順が必要です。）<br>
<br>
ダイスボットのテスト確認ができたら、どどんとふで動かす最後の準備をしましょう。<br>
src_ruby/config.rb を開いて、$diceBotOrder に追加したいダイスボットの名前を追加します。<br>
ここに記載されていないダイスボットはどどんとふで選択できませんので注意してください。<br>
<br>
後は、どどんとふで正しく動くことを確認できたら完成です。<br>
<br>
完成したダイスボットは作者に送付するとどどんとふに取り込んでもらえるかもしれませんよ！<br>
送付時にはテストデータも添えて頂けるとモアベター。<br>
<br>
<br>
<h2 id="aboutWebIf">WEB IFについて</h2>

<h3 id="whatIsWebIf">WEB IFとは？</h3>
プログラマな人向けの機能の説明です。大半の方は読み飛ばしてOKです。<br>
<br>
WEB IF、いわゆるWEB APIですね。<br>
Google Maps APIやTwitterなどのWEBサービスで、特定のURLにパラメータを渡してデータを取得する手法とか聞いた事ありませんか？<br>
それがWEB API。<br>
どどんとふにはこの機能が実装されています。<br>
使用可能な機能とその使い方についてここで解説します。<br>
<br>
なお、具体的なWEB IFの実装例は まさしげさんさ作製されている以下のサイトが参考になるかと思います。<br>
http://character-sheets.appspot.com/sample/dodontofsample.html<br>
<br>
<h3 id="webIfBasicFormat">基本フォーマット</h3>
どどんとふのサイトは大抵は<br>
　〜/DodontoF.swf<br>
というURLになっています。<br>
このURLを<br>
　〜/DodontoFServer.rb<br>
とする<br>
と、CGIそのものに対してアクセスできます。<br>
通常は正常動作を示すメッセージが表示されますね。<br>
<br>
ここで<br>
　DodontoFServer.rb?webif=(コマンド)&(パラメータ１)=(値１)&(パラメータ２)=(値２)&...<br>
というURLを指定することで、どどんとふサーバからのデータ取得や各種設定を行う事ができるわけです。<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=chat&room=0&password=himitsu&time=1339209851.85239<br>
<br>
webif=chat が指定しているWEB IFのコマンドで、上記の例では chat コマンドを指定し、その他パラメータを与えています。<br>
コマンド実行後の応答データは以下のようになります。<br>
<br>
応答データ例）<br>
{"result":"OK","chatMessageDataLog":[[1342087310.18487,{"senderName":"エルフ\t笑顔","uniqueId":"1339209851.85239\tD331AC4E-7935-553E-E958-7AA2F2CA5F82","color":"000000","channel":0,"message":"発言１"}],[1342087318.92488,{"senderName":"どどんとふ\t","uniqueId":"dummy","color":"00aa00","channel":0,"message":"「ゴスロリ娘」がログインしました。"}]]}<br>
<br>
応答書式はコマンド毎に異なりますが、基本フォーマットは<br>
　・JSONフォーマットであること<br>
　・コマンド実行の成否が "result"パラメータとして戻る。"OK"であれば成功。それ以外の場合は失敗理由が記載される。<br>
となります。<br>
<br>
以上が、WEB IFの基本的動作です。<br>
<br>
<br>
では、各種操作コマンドおよびパラメータに付いて<br>
<br>
<h3 id="webIf_getBusyInfo">getBusyInfo：サーバ負荷情報の取得</h3>
サーバの負荷およびバージョン情報一式を取得します。<br>
<br>
指定可能パラメータ：<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=getBusyInfo&callback=responseFunction<br>
<br>
応答データ例）<br>
　responseFunction({"maxLoginCount":30,"result":"OK","loginCount":0,"version":"Ver.1.xx.xx(20xx/xx/xx)"});<br>
<br>
maxLoginCount：推奨最大ログイン人数<br>
loginCount：現在ログインしている人数（これが上記の最大人数を超えるとログイン画面に警告が表示されます）<br>
version：サーバで使用しているどどんとふのバージョン（リリース日）<br>
<br>
<br>
<h3 id="webIf_getServerInfo">getServerInfo：サーバの各種情報取得</h3>
サーバの各種情報を一括取得します。<br>
<br>
指定可能パラメータ：<br>
　dice：trueならダイス情報を取得（省略時：false）<br>
　card：trueならカード情報を取得（省略時：false）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=getServerInfo&dice=true&card=true&callback=responseFunction<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK","maxRoom":9,"isNeedCreatePassword":false,"diceBotInfos":[{"info":"...","gameType":"DiceBot","name":"ダイスボット(指定無し)","prefixs":["\\d+D\\d+",...]},...],"cardInfos":[{"title":"トランプ","type":"trump_swf"},...]});<br>
<br>
maxRoom：作製可能な最大部屋数<br>
isNeedCreatePassword：部屋作成時にパスワードが必要かのフラグ<br>
diceBotInfos：ダイスボットの詳細な情報（の配列）(dice=true指定時のみ）<br>
　info：説明文<br>
　gameType：ダイスボット識別名<br>
　name：ダイスボットの日本語名<br>
　prefixs：チャットでダイスロールか判定するための正規表現用プレフィックス文字列<br>
cardInfos：カードの詳細な情報（の配列）(card=true指定時のみ）<br>
　title：カードの日本語名<br>
　type：カードの識別名<br>
<br>
<br>
<h3 id="webIf_getRoomList">getRoomList：部屋情報一覧の取得</h3>
部屋の状態についての情報を一括取得します。<br>
<br>
指定可能パラメータ：<br>
　minRoom：取得する最小部屋番号（省略時：0）<br>
　maxRoom：取得する最大部屋番号（省略時：作製可能な最大部屋番号）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=getRoomList&minRoom=3&maxRoom=5&callback=responseFunction<br>
<br>
応答データ例）<br>
　responseFunction({"playRoomStates":[{"loginUsers":[],"passwordLockState":false,"lastUpdateTime":"2011\/09\/05 13:32:58","index":"  3","playRoomName":"仮プレイルーム（削除可能）","canVisit":false,"gameType":"diceBot"},{"loginUsers":[],"passwordLockState":false,"lastUpdateTime":"2011\/09\/05 13:32:58","index":"  4","playRoomName":"TORG用の部屋","canVisit":false,"gameType":"TORG"},{"loginUsers":[],"passwordLockState":false,"lastUpdateTime":"","index":"  5","playRoomName":"（空き部屋）","canVisit":false,"gameType":""}],"result":"OK"});<br>
<br>
playRoomStates：各部屋の情報の配列。以下、その内容<br>
　index：部屋番号<br>
　playRoomName：部屋名<br>
　lastUpdateTime：最終更新時間を示す文字列<br>
　canVisit：見学の可否。true：見学許可、false：見学不可<br>
　gameType：部屋で指定しているダイスボット識別名<br>
　loginUsers：現在ログインしているユーザー名のリスト<br>
　passwordLockState：パスワードの有無。true：パスワード有り、true：パスワード無し<br>
<br>
<br>
<h3 id="webIf_getLoginInfo">getLoginInfo：初期ログイン用データ取得</h3>
初期ログイン用データ取得。現状はユーザーIDの uniqueId を取得するためのもの。<br>
一番最初に一度だけ実行してください。<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=getLoginInfo<br>
<br>
応答データ例）<br>
　{"uniqueId":"hl3bim0y"}<br>
<br>
<br>
<h3 id="webIf_getLoginUserInfo">getLoginUserInfo：ログインユーザーの情報取得・更新</h3>
ログインしているユーザーの情報の取得・更新を行います。<br>
このコマンドを定期的に実行することでWEB IFでもログインしている状態に見せることができます。<br>
定期間隔は src_ruby/config.rb に定義されている $loginTimeOut 秒です。（デフォルトでは13秒）<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は getLoginUserInfo を指定すること。<br>
　room：コマンドを実行するプレイルーム番号<br>
　password：コマンドを実行するプレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　uniqueId：getLoginInfoで取得できる uniqueId を指定。<br>
　name：ログインしているユーザーの名前<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=getLoginUserInfo&room=1&password=himitsu&uniqueId=hl3bim0y&name=boo<br>
<br>
応答データ例）<br>
　[{"userName":"boo","userId":"hl3bim0y"}]<br>
<br>
<br>
<h3 id="webIf_chat">chat：チャットデータの取得</h3>
チャットの発言データを取得します。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は chat を指定すること。<br>
　room：コマンドを実行するプレイルーム番号<br>
　password：コマンドを実行するプレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
以下の sec/time パラメータはどちらかの指定が必須です。またsecとtimeがではtimeの指定が優先されます。<br>
　time:何時以降のチャットを取得するかの時間をUNIX積算時間で指定。<br>
　　　指定時間移行のチャットのみを取得します。<br>
　　　（Flashからの定期取得処理と同一の動作）<br>
　sec：何秒前までのチャットを取得するかの指定。allなら全取得、省略なら過去180秒（$oldMessageTimeoutで指定）<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=chat&room=0&password=himitsu&time=1339209851.85239&callback=responseFunction<br>
<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK","chatMessageDataLog":[[1342087310.18487,{"senderName":"エルフ\t笑顔","uniqueId":"1339209851.85239\tD331AC4E-7935-553E-E958-7AA2F2CA5F82","color":"000000","channel":0,"message":"発言１"}],[1342087318.92488,{"senderName":"どどんとふ\t","uniqueId":"dummy","color":"00aa00","channel":0,"message":"「ゴスロリ娘」がログインしました。"}]]})<br>
<br>
chatMessageDataLog にチャットの発言が古い順で配列で格納されています。<br>
各発言は<br>
<br>
[＜発言のUNIX積算時間＞,<br>
 {"senderName":＜発言者名\t立ち絵(空文字なら指定なし)＞,<br>
　"uniqueId":＜発言者のログイン時に付与されるID番号＞,<br>
　"color":＜発言文字色の16進数文字列＞,<br>
　"channel":＜発言先のチャットタブ番号（メイン：0 として、以降右を 1,2,3...と数えます）＞,<br>
　"message":＜発言内容＞}]<br>
<br>
という書式になります。<br>
<br>
<h3 id="webIf_talk">talk：チャットへの発言</h3>
チャットへ発言を行います。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は talk を指定すること。<br>
　room：コマンドを実行するプレイルーム番号<br>
　password：コマンドを実行するプレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　name：発言者名（省略の場合は名前が空になります）<br>
　message：発言内容<br>
　color：発言文字の色を 00000〜FFFFFF の16進数で指定可能。省略時は 000000（黒色）<br>
　channel：発言先のタブ番号（メイン：0 として、以降右を 1,2,3...と数えます）省略時は0（メイン）に。<br>
　bot：ダイスボットを使用する場合に使用するゲーム種別を指定（指定しない場合は「ダイスボット（指定なし）」がデフォルト指定に）。<br>
　　　　ゲーム種別名の詳細については BCDice2.x のREADME.html<br>
https://github.com/torgtaitai/BCDice<br>
の「・ゲーム設定」を参照。<br>
　callback: JSONP取得用。省略可<br>
<br>
注意：<br>
長いメッセージを投げる場合はURLパラメータのGET送信ではなくPOST送信を行ってください。<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=talk&room=0&password=himitsu&name=taitai&message=hello&color=00AA00&bot=SwordWorld&callback=responseFunction<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK"});<br>
<br>
コマンド実行結果だけを返すため特に応答データはありません。<br>
<br>
<h3 id="webIf_getChatColor">getChatColor：文字色取得</h3>
指定ユーザーの最後の発言の文字色を取得できます。<br>
比較的重い処理なので毎回呼ばずに最初に1度だけ読んで結果を保持するようにしてください。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は getChatColor を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　name：文字色取得対象の発言者名<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=getChatColor&room=0&password=himitsu&name=taitai&callback=responseFunction<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK","color":"00aa00"});<br>
<br>
応答データは color で文字色だけが戻ります。表記は16進数の文字列表示です。<br>
<br>
<h3 id="webIf_addCharacter">addCharacter：キャラクター追加</h3>
マップ上にキャラクターを追加することが出来ます。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は addCharacter を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　name：追加するキャラクター名<br>
　counters：イニシアティブに表示するカウンター値 名1:値1,名2:値2,.... というフォーマットで指定。省略可<br>
　info：その他情報。省略可<br>
　x：x座標。省略可<br>
　y：y座標。省略可<br>
　size：キャラクターのサイズ。省略可<br>
　initiative：イニシアティブ値。省略可<br>
　rotation：回転角度。0〜360 の度数指定。省略時はデフォルトの0に。<br>
　image：画像。省略時はデフォルトの画像を設定。<br>
　statusAlias：イニシアティブに表示するカウンター値がチェックボックスの場合に付けることの出来る別名の指定 名1:別名1,名2:別名2,.... というフォーマットで指定。省略可<br>
　dogTag：複数キャラクター作成時に付与される「１」のような番号表示用のパラメータ。通常は雑魚的の場合にしか使わない固定数値ですが、WEB IFでは任意に設定可能とします。省略可<br>
　draggable：ドラッグ移動の是非。trueで移動可能(true,false)。省略可<br>
　isHide：マップマスクの下にキャラクターを隠すかの指定。trueで隠す(true,false)。省略可<br>
　url：キャラクターデータの参照先URLの指定。省略可<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=addCharacter&room=1&password=himitsu&name=abc&counters=HP:1,MP:1,*check:0,*check:1&info=foo&x=0&y=1&size=2&initiative=9&rotation=30&statusAlias=check:abc,check2:def&dogTag=1&draggable=true&isHide=false&url=http%3a%2f%2fwww%2edodontof%2ecom%2f&callback=responseFunction<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK"});<br>
<br>
コマンド実行結果だけを返すため特に応答データはありません。<br>
<br>
<h3 id="webIf_changeCharacter">changeCharacter：キャラクターの変更</h3>
マップに追加済みのキャラクターの設定値を変更することが出来ます。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は changeCharacter を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　targetName：変更対象とするキャラクターの名前<br>
　name：キャラクター名を変更する場合にはこのパラメータを指定。省略可<br>
　counters：イニシアティブに表示するカウンター値 名1:値1,名2:値2,.... というフォーマットで指定。省略可<br>
　info：その他情報。省略可<br>
　x：x座標。省略可<br>
　y：y座標。省略可<br>
　size：キャラクターのサイズ。省略可<br>
　initiative：イニシアティブ値。省略可<br>
　rotation：回転角度。0〜360 の度数指定。省略時はデフォルトの0に。<br>
　image：画像。省略時はデフォルトの画像を設定。<br>
　statusAlias：イニシアティブに表示するカウンター値がチェックボックスの場合に付けることの出来る別名の指定 名1:別名1,名2:別名2,.... というフォーマットで指定。省略可<br>
　dogTag：複数キャラクター作成時に付与される「１」のような番号表示用のパラメータ。実は任意の文字が使えます。省略可<br>
　draggable：ドラッグ移動の是非。trueで移動可能(true,false)。省略可<br>
　isHide：マップマスクの下にキャラクターを隠すかの指定。trueで隠す(true,false)。省略可<br>
　<br>
コマンド例）<br>
　DodontoFServer.rb?webif=changeCharacter&room=1&password=himitsu&targetName=abc&name=def&counters=HP:1,MP:1,*check:0,*check:1&info=foo&x=0&y=1&size=2&initiative=9&rotation=30&statusAlias=check:abc,check2:def&dogTag=1&draggable=true&isHide=false&callback=responseFunction<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK"});<br>
<br>
コマンド実行結果だけを返すため特に応答データはありません。<br>
<br>
<h3 id="webIf_getRoomInfo">getRoomInfo：プレイルーム情報取得</h3>
プレイルームの状態を取得することが出来ます。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は getRoomInfo を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=getRoomInfo&room=1&password=himitsu&callback=responseFunction<br>
<br>
応答データ例）<br>
responseFunction({"chatTab":["メイン","雑談"],"outerImage":true,"game":"ShinobiGami","result":"OK","visit":false,"roomName":"仮プレイルーム（削除可能）","counter":["HP","*転倒","夢","MP"]});<br>
<br>
chatTab：チャットのタブ名のリスト<br>
counter：イニシアティブ表で使われているカウンター値のリスト<br>
game：ダイスボット種別<br>
outerImage：外部URLの許可の有無(true：外部URL許可、false：不可）<br>
roomName：プレイルーム名<br>
visit：見学の可否(true：見学可、false：不可）<br>
<br>
<h3 id="webIf_setRoomInfo">setRoomInfo：プレイルームの情報設定</h3>
プレイルームの情報を一括設定することが出来ます。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は setRoomInfo を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　counter：イニシアティブに表示するカウンター名。名1,名2,.... というフォーマットで指定。省略可<br>
　chatTab：チャットウィンドウで使用するタブの名前。タブ名1,タブ名2,.... というフォーマットで指定。省略可<br>
　roomName：プレイルーム名。省略可<br>
　outerImage：外部画像の使用の可否(true,false)。省略可<br>
　visit：見学者の可否(true,false)。省略可<br>
　game：デフォルトでサポートするゲーム名（ダイスボットと同様の定義名を使用）。種別名の詳細は src_ruby/diceInfo.rb を参照。省略可<br>
<br>
コマンド例）<br>
DodontoFServer.rb?webif=setRoomInfo&room=1&password=himitsu&counter=HP,MP,PPP&chatTab=aiu,eo&roomName=mokekeRoom&outerImage=true&visit=true&game=TORG&callback=responseFunction<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK"});<br>
<br>
<h3 id="webIf_addMemo">addMemo：共有メモ追加</h3>
共有メモを追加することが出来ます。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は addMemo を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　message：メモに記述する文字列<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=addMemo&room=1&password=himitsu&callback=responseFunction&message=qwerty<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK"});<br>
<br>
<h3 id="webIf_changeMemo">changeMemo：共有メモ追加</h3>
共有メモを変更することができます。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は changeMemo を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　targetId：メッセージを変更したいメモの imgId を指定<br>
　message：変更後のメモ文字列<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=changeMemo&room=1&password=himitsu&callback=responseFunction&targetId=character_1435785110.1314_0004&message=asdf<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK"});<br>
<br>
<h3 id="webIf_addMessageCard">addMessageCard：メッセージカード追加</h3>
メッセージカードを追加することが出来ます。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は addMessageCard を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　text：メッセージカードに表示する文字列<br>
　back：メッセージカードの裏面に表示する文字列<br>
　fontSize：メッセージカードのフォントサイズ。デフォルト20。省略可<br>
<br>
コマンド例）<br>
　DodontoFServer.rb?webif=addMessageCard&room=1&password=himitsu&callback=responseFunction&message=qwerty&text=cardText&back=backText&fontSize=40<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK"});<br>
<br>
<h3 id="webIf_refresh">refresh：各種情報取得</h3>
部屋の各種情報を一括して取得できます。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は refresh を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　characters：キャラクター情報。省略時は一切取得されません。データを取得したい場合、初期値に0を指定してください。<br>
　　応答データlastUpdateTimesの'characters'要素（lastUpdateTime['characters']）には更新時刻がUNIX積算時間のミリ秒で記録されます。<br>
　　2回目以降の取得ではこの値を設定すると、前回から変更のあったデータが取得できます。<br>
　map：マップ情報。他はcharactersに同じ。lastUpdateTimeの要素名は'map'<br>
　time：イニシアティブラウンド情報。他はcharactersに同じ。lastUpdateTimeの要素名は'time'<br>
　effects：立ち絵／カットイン情報。他はcharactersに同じ。lastUpdateTimeの要素名は'effects'<br>
　roomInfo：部屋情報。他はcharactersに同じ。lastUpdateTimeの要素名は'playRoomInfo'<br>
　chat：チャット情報。他はcharactersに同じ。lastUpdateTimeの要素名は'chatMesageDatalog'<br>
　chatLastTime：チャットの最終更新時間。チャットは実装上の都合でchatとchatLastTimeの2種類の更新時間を持ちます。こちらのチャット更新時刻は、応答データchatMessageDataLogの各配列要素の0番目の要素で取得できます。この値を設定しない場合、チャット情報が重複して取得される場合があります。<br>
<br>
詳しくは以下の具体例(を参照ください。<br>
<br>
コマンド例その１）<br>
　DodontoFServer.rb?webif=refresh&room=0&chat=0&map=0&characters=0&time=0&effects=0&roomInfo=1344134257000&callback=responseFunction<br>
<br>
応答データ例）<br>
　responseFunction({"result":"OK","mapData":{"yMax":22,"mapMarks":[],"mapType":"imageGraphic","imageSource":"","xMax":22,"gridColor":0},"chatMessageDataLog":[[1262834775.781,{"senderName":"エルフさん","uniqueId":"1262834746.718","color":"000000","message":"発言テスト","channel":0}],[1426397778.75118,{"senderName":"エルフさん","uniqueId":"1262834746.718","color":"000000","message":"あなたはそこにいますか。","channel":0}]],"characters":[{"name":"sample","size":1,"imgId":"character_1260575421.171_1","x":8,"y":3,"draggable":true,"info":"","isHide":false,"type":"characterData","imageName":".\/imageUploadSpace\/chara01_a5_24_2.png","direction":0,"initiative":0,"rotation":0}],"graveyard":[],"effects":[{"position":"center","soundSource":"","isSoundLoop":false,"cutInTag":"","effectId":"1228488734.998","isTail":true,"volume":0.1,"height":0,"displaySeconds":0.3,"message":"驚愕","source":".\/movie\/shout.flv","width":0}{"name":"スポーツ娘","effectId":"1228825137.001","type":"standingGraphicInfos","source":"image\/stand\/sports_normal.png","state":"通常"}],"roomInfo":{"playRoomChangedPassword":null,"canUseExternalImage":false,"viewStateInfo":{"isCutInVisible":true,"isPositionVisible":true,"isDiceVisible":true,"isStandingGraphicVisible":true,"isGridVisible":true,"isAdjustImageSize":true,"isButtonBoxVisible":false,"isChatPaletteVisible":true,"isInitiativeListVisible":true,"isChatVisible":true,"isCardPickUpVisible":false,"isSnapMovablePiece":true,"key":"1344134257.60825"},"chatChannelNames":["メイン","雑談"],"playRoomName":"お試しプレイルーム（消さないでね）","canVisit":false,"gameType":"GehennaAn"}"lastUpdateTimes":{"characters":1330171325000,"recordIndex":0,"time":1344179443000,"chatMessageDataLog":1353655077000,"effects":1344179573000,"map":1330171325000,"playRoomInfo":1344134257000,"record":0}});<br>
<br>
mapData：マップ情報<br>
chatMessageDataLog：チャット情報<br>
characters：キャラクター情報<br>
graveyard：墓場に入れられたキャラクターの情報<br>
effects：カットインと立ち絵の情報<br>
roomInfo：部屋の情報<br>
lastUpdateTimes：各セーブデータの更新日時情報。2回目以降のrefreshではここで取得した値を指定パラメータに入れて実行します。<br>
<br>
コマンド例その２）<br>
上記の応答を受けた場合、以下のように指定します。<br>
<br>
chat,map,characters,time,effects,roomInfo,callback は前述の通り lastUpdateTimes の各要素から最終更新時刻（UNIX積算ミリ秒）を取得。<br>
chatLastTime、チャットの更新時刻の2種類目、は chatMessageDataLog の２個目の先頭要素、 1426397778.75118 になります。<br>
これより指定は、<br>
　DodontoFServer.rb?webif=refresh&room=0&chat=1353655077000&map=1330171325000&characters=1330171325000&time=1344179443000&effects=1344179573000&roomInfo=1344134257000&chatLastTime=1262834781.571&callback=responseFunction<br>
<br>
となります。<br>
<br>
<h3 id="webIf_uploadImageData">uploadImageData：画像ファイルアップロード</h3>
画像ファイルをアップロードすることが出来ます。<br>
★このコマンドのみPOST指定で投げる必要があるため、他のコマンドのようにURLでコマンド指定はできません。<br>
<br>
指定可能パラメータ：<br>
　webif：コマンド名。この場合は uploadImageData を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用の関数名設定用。省略可<br>
　<br>
　fileData：アップロード対象の画像データ。<br>
　tags：画像タグ。空白で区切ることで複数指定が可能です。<br>
　smallImageData：縮小画像のBase64エンコードデータ。（省略可）<br>
　<br>
詳細な実例は同梱の chat.html の uploadImageData() を参照願います。<br>
動作検証時には chat.html から部屋にログインして「画像」と書かれたリンクを押してください。<br>
以下、該当箇所を抜粋。<br>
<pre><code>
例）
HTML側：form部分から必須箇所のみ抜粋

        &lt;form id=&quot;fileUpload&quot;&gt;
          &lt;canvas id=&quot;smallImageCanvas&quot; &gt;&lt;/canvas&gt;
          &lt;input type=&quot;file&quot; id=&quot;fileData&quot; name=&quot;fileData&quot; accept=&quot;image/*&quot; capture &gt;&lt;br&gt;
          &lt;input id=&quot;tags&quot; placeholder=&quot;tags&quot; /&gt;
          &lt;button type=&quot;button&quot; onclick=&quot;uploadImage()&quot;&gt;画像アップロード&lt;/button&gt;&lt;br&gt;
        &lt;/form&gt;

javascript側： 必須箇所のみ抜粋。

function uploadImage() {
    
    //jqueryを導入していることが前提です。
    // フォームデータを取得
    var formData = new FormData( $('form#fileUpload')[0] );//アップロードする画像の指定
    
    //縮小画像を取得。縮小画像をアップロード時に送信すると
    //「どどんとふ」本体の画像一覧に縮小画像が利用されるので動作が軽くなりユーザーに親切です。
    //ただ設定は手間なのも事実なので、指定を省略することも可能です。
    var canvas = document.querySelector('#smallImageCanvas');
    var base64Data = canvas.toDataURL('image/png');
    smallImageData = base64Data.replace('data:image/png;base64,', '');
    formData.append( 'smallImageData', smallImageData ); //縮小画像の指定（省略可能）
    
    formData.append( 'webif', "uploadImageData" ); //webifの指定
    formData.append( 'room', roomNo ); //部屋番号の指定
    if(roomPass != "" || roomPass == null){
        formData.append( 'password', roomPass ); //パスワードの指定
    }
    
    formData.append( 'tags', $('#tags').val() ); //タグ名の指定
    //formData.append( 'imagePassword', "パスワード" ); //絵のパスワードも指定できます（ここでは未使用）

    for(item of formData) {
        console.log(item);
    };
    
    
    var url = getServerUrl();

    // POSTでアップロード
    $.ajax({
        url  : url,
        type : "POST",
        data : formData,
        async: false,
        cache       : false,
        contentType : false,
        processData : false
    })
        .done(function(data, textStatus, jqXHR){
            $('#fileUploadResult').text( "result : " + data.result + ", fileName:" + data.fileName );
        })
        .fail(function(jqXHR, textStatus, errorThrown){
            alert("fail");
            console.log( 'ERROR', jqXHR, textStatus, errorThrown );
        });
}

</code></pre>
<br>
<br>
<h2 id="aboutLicense">ライセンスについて</h2>
以下、各種同根ファイルを含めたライセンスについて。<br>
<br>
・使用許諾について<br>
「どどんとふ」のライセンスは修正BSDライセンスとします。<br>
URL： http://www.dodontof.com<br>
配下の関連ページが開発元として参照できさえすれば、任意に使用していただいてかまいません。<br>
（そのまま使用していただければ、ヘルプからURLが参照可能ですので問題ありません）<br>
<br>
ただし、以下に述べる本ツールに付属のライブラリ・画像データについては、それぞれのライセンスに従ってください。<br>
こちらも、通常の公開・使用については特に問題ないはずです。<br>

<h3 id="fileConstraction">ファイル構成</h3>
ファイル構成は以下のとおりです。<br>
<br>
DodontoF : 「どどんとふ」の展開元ディレクトリ<br>
|<br>
+---:as2_tubeloc.swf:tubeloc、Youtube動画再生用ライブラリ(後述)<br>
|<br>
+--+:saveData：各種データの保存先ディレクトリ。<br>
|　+--:characterImages：キャラクターの画像はここに保管されます。(後述)<br>
|　+--:data_x：プレイルーム用データはここに保管されます。xにはプレイルーム番号が付与されます。<br>
|　+--:mapImages：マップの画像はここに保管されます。<br>
|<br>
|--:cards：カード用データ(後述)<br>
+--:saveDataDefault：新規作成時のプレイルーム用データ<br>
|<br>
+--+:src_ruby：サーバCGI側、Ruby用のソースコード<br>
|　+--json : サーバ・クライアント間データ転送用ライブラリ「jsonParser.rb」が含まれています。(後述)<br>
|<br>
+--+:src_actionScript：クライアントGUI側、Flex(Flash)用のソースコード<br>
　 +--:com：tubeloc、Youtube動画再生用ライブラリ(後述)<br>
 　+--:corelib：Json変換用Flexライブラリ(後述)<br>
 　+--:diceImage：DiceInfo.asで使用しているダイス画像ファイル(コンパイル時組み込み)<br>
 　+-+:imageUploadSpace：画像データ置き場（後述）<br>
 　+-+:image：画像データ置き場（内部処理用）<br>
 　| +--:icons：各種アイコン用画像集(後述)<br>
 　| +--:stand：サンプル用立ち絵(後述)<br>
 　+--:sound：Flex用音データ(コンパイル時組み込み)<br>


<h3 id="aboutLibrary">ライブラリ・画像データ等について</h3>
本ツールでは、以下のライブラリ、データを使用しています。<br>
各作者の方々に心から感謝。<br>
以下、順不同です。<br>

<h4 id="characterImage">キャラクター画像</h4>
　<a href="http://www.tekepon.net/fsm/">http://www.tekepon.net/fsm/</a><br>
　＝＞First Seed Material, REFMAPより画像を流用しています。<br>

<h4 id="imageUploadSpace">立ち絵画像</h4>
　＝＞「ど＠えむ」掲示板にて、Ragiさん、PLEさんよりご提供いただきました。ありがとうございます！<br>
　　　「どどんとふ」での利用に限り流用可能とのことですので、皆さんガンガン使いましょう！<br>
　　　結城ユキさんのドワーフ娘も追加！にぎやかになっていい感じですね！！<br>

<h4 id="tubeloc">tubeloc</h4>
　<a href="http://code.google.com/p/tubeloc/">tubeloc[http://code.google.com/p/tubeloc/]</a><br>
 　＝＞FlashでYoutubeの動画を再生するためのライブラリ。Apache License 2.0ライセンス。<br>

<h4 id="Hi-ReS-Stats">Hi-ReS-Stats</h4>
　<a href="https://github.com/mrdoob/Hi-ReS-Stats">Hi-ReS-Stats[https://github.com/mrdoob/Hi-ReS-Stats]</a><br>
 　＝＞Flashのパフォーマンスを測定するためのライブラリ。MITライセンス。<br>
　　　src_ruby/config.rbの $isPaformanceMonitor を true にすることで有効化<br>

<h4 id="corelib">corelib</h4>
　<a href="http://code.google.com/p/as3corelib/">http://groups.google.com/group/webos-goodies/</a><br>
 　＝＞RubyでJsonデータを変換するためのライブラリ。Public domainライセンス。<br>

<h4 id="Archive_Tar_Minitar">Archive::Tar::Minitar</h4>
　<a href="http://rubyforge.org/projects/ruwiki/">http://rubyforge.org/projects/ruwiki/</a><br>
 　＝＞Rubyでtar.gzファイルを解凍するためのライブラリ。GPL, Rubyデュアルライセンス。<br>
　　　どどんとふ付属のライブラリは改造版のため、オリジナルは上記サイトから取得願います。<br>

<h4 id="as3-msgpack">as3-msgpack</h4>
　<a href="https://github.com/loteixeira/as3-msgpack">https://github.com/loteixeira/as3-msgpack</a><br>
 　＝＞ActionScript3用のMessagePackライブラリ。Apache License 2.0ライセンス。<br>

<h4 id="msgpack-pure">msgpack-pure</h4>
　<a href="https://github.com/nayutaya/msgpack-pure">https://github.com/nayutaya/msgpack-pure</a><br>
 　＝＞Ruby用のMessagePackライブラリ。ライセンス不明記。<br>

<h4 id="msgpack-pure-ruby">msgpack-pure-ruby</h4>
　<a href="https://github.com/iconara/msgpack-pure-ruby">https://github.com/iconara/msgpack-pure-ruby</a><br>
 　＝＞Ruby1.9用のMessagePackライブラリ。Apache License 2.0ライセンス。<br>

<h4 id="simple-color-picker">simple-color-picker</h4>
　<a href="https://github.com/rachel-carvalho/simple-color-picker"></a>https://github.com/rachel-carvalho/sim 　＝＞javascript用のカラーピッカーライブラリ。MITライセンス。<br>

<h4 id="icons">各種アイコン用画像集</h4>
　<a href="http://www.famfamfam.com/lab/icons/silk/">Mark James[http://www.famfamfam.com/lab/icons/silk/]</a><br>
　＝＞アイコン用画像集<br>
　<a href="http://raindropmemory.deviantart.com/">Raindropmemory[http://raindropmemory.deviantart.com/]</a><br>
　＝＞アイコン用画像の一部（参照：<a href="http://findicons.com/icon/41229/note">http://findicons.com/icon/41229/note</a>）<br>

<h4 id="standingGraphics">サンプル用立ち絵</h4>
　<a href="http://www.vector.co.jp/soft/win95/game/se250013.html">http://www.vector.co.jp/soft/win95/game/se250013.html</a><br>
　＝＞Vectorの「ゲーム製作用立ち絵素材集〜女の子編〜」から入手。<br>

<h4 id="jsonPerser">jsonParser.rb</h4>
　<a href="http://groups.google.com/group/webos-goodies/">http://groups.google.com/group/webos-goodies/</a><br>
 　＝＞RubyでJsonデータを変換するためのライブラリ。Public domainライセンス。<br>

<h4 id="flexlib">flexlib</h4>
　<a href="https://code.google.com/archive/p/flexlib/">https://code.google.com/archive/p/flexlib/</a><br>
 　＝＞ActionScriptの各種ライブラリ。主にタブ機能を利用。MITライセンス。<br>
 　　　なお使用ファイルは<br>
 　　　　flexlib/containers/SuperTabNavigator.as<br>
 　　　　flexlib/controls/SuperTabBar.as<br>
 　　　を一部機能変更しています。<br>

<h4 id="otherLibrary">その他</h4>
　Dice.asの作成には<br>
　<a href="http://realtimemachine.sakura.ne.jp/collisions/works/web/dice.html">http://realtimemachine.sakura.ne.jp/collisions/works/web/dice.html</a><br>
　を参照させていただきました。この場を借りてお礼申し上げます。<br>

<h2 id="others">その他</h2>
<h3 id="aboutNaming">名前の由来について</h3>
「どどんとふ」には、ほぼ同様の機能をRuby+Javascript(いわゆるAjax)で実装したD&amp;D3.5版用マップ管理ソフト「どどんと（Dangeons and Dragons Map Tool=>DDMT=>どどんと）」がありました。
ただJavaScriptの表現の限界を感じていたため、4th発売を記念してGUI側Flashで再構成し、高速化と快適化を目指すこととしました。
そこで名前には末尾にFlashのFを付けて「DDMTF」->「どどんとふ」となりました。
あとは「どどんと」で懲りたので、検索でHITしやすい新単語を作りたかったというのもあります。


<h2 id="caution">注意事項</h2>
本ツールを使用・流用して起きた不具合によるあらゆる損害に対して、当方では一切保証いたしかねます。<br>
あらかじめご了承ください。<br>


<h2 id="history">履歴</h2>
2017/11/19 Ver.1.48.32.1<br>
Ver.1.48.32 の媒体がうまくアップロードできていなかったため差し替え<br>
<br>
2017/11/19 Ver.1.48.32<br>
・手書き機能に描き込み内容を画像として確定して処理を軽量化する「確定」ボタンを追加。<br>
・ダイスボットの表を拡張する extratable ディレクトリのデフォルトの内容を全てダイスボット自体に反映。既存の extratable は廃止となりました（削除すると容量を削減できますが、別に削除しなくても動作に問題はありません）。独自拡張したダイスボット表を配置していた方は新しく extratable2 が存在しますので、そちらにダイスボット表のtxtファイルを置いてください。独自拡張を特にしていない方は何もしなくて問題ありません。<br>
<br>
2017/10/12 Ver.1.48.31.2<br>
・再ログイン時にすでに存在しない人のログイン名が「???」となってしまう不具合を修正。サクさん、おむぎりさん、指摘ありがとうっ！<br>
<br>
2017/10/11 Ver.1.48.31.1<br>
・Ver.1.48.31で他人の秘話も再ログイン時に表示されてしまう不具合を修正。 <br>
<br>
2017/10/09 Ver.1.48.31<br>
・秘話機能で会話したあと、再ログインした場合に前回までの秘話が消えてしまう問題を解消。<br>
・任意のコマンドを実行できてしまう脆弱性を修正。kittさん指摘ありがとうっ！<br>
・chat.htmlの一部処理不具合を修正。AVAnillaさん指摘ありがとうっ！<br>
・トーキョーN◎VA The Axleration『オルタナティブサイト』のマイナスナンバーに対応。ほぎーさんありがとうっ！<br>
<br>
2017/08/17 Ver.1.48.30<br>
・ダイスボットをボーンズ＆カーズVer2.02.73対応へ変更。<br>
・ダイスボットに「初音ミクTRPG ココロダンジョン」を追加。<br>
・「神話創世RPGアマデウス」のダイスボットを「神話創世RPGアマデウスEX 放課後ミソロギア」に対応。よっしーさんありがとうっ！<br>
<br>
2017/08/06 Ver.1.48.29<br>
・ダイスボットをボーンズ＆カーズVer2.02.72対応へ変更。<br>
・ダイスボットに「ダークデイズドライブ」を追加。あかうささんありがとうっ！<br>
・ダイスボットに「ヤンキー＆ヨグ＝ソトース」を追加。たこすけさんありがとうっ！<br>
<br>
2017/07/17 Ver.1.48.28<br>
・ダイスボットをボーンズ＆カーズVer2.02.71対応へ変更。<br>
・ダイスボットの定義を変更。 prefixs メソッドではなく setPrefixes でコマンド名を定義するようになりました。ochaさんありがとうっ！！！<br>
　詳細については<u><a href="src_bcdice/test/README.html">「■自作ダイスボットの作り方：その４　そして実装」</a></u>を参照。<br>
　（従来のコマンドも動きますが、テスト実行時には非推奨の警告が表示されます）<br>
・他言語のダイスボットを設定した状態でログインした際に、正しいダイスボットが選択されない問題を修正。Nanasuさんありがとうっ！<br>
・ダイスボットのロール結果に「！」が含まれる場合にダイスの画像が巨大になる不具合を修正。「2D6 ロール！」のように付与メッセージでのみダイス画像が大きくなるように。<br>
・WEBIFに画像アップロードコマンドのuploadFileを追加。詳細はREADME.htmlの「<u><a href="#webIf_uploadImageData">uploadImageData：画像ファイルアップロード</a></u>」を参照。<br>
・画像選択時にパスワードの一致しない画像のタグは表示しないように機能変更。<br>
<br>
2017/06/22 Ver.1.48.27<br>
・ダイスボットをボーンズ＆カーズVer2.02.70対応へ変更。<br>
・ドラクルージュのダイスボットを更新。「ノブレスストーリア」に対応。<br>
<br>
2017/06/09 Ver.1.48.26<br>
・ダイスボットをボーンズ＆カーズVer2.02.69対応へ変更。<br>
・ビギニングアイドルをビギニングロードに対応。かすかさんありがとうっ！<br>
・ダイスボットに「ダークソウルTRPG」を追加。anony403さんありがとうっ！<br>
<br>
2017/05/14 Ver.1.48.25<br>
・ダイスボットをボーンズ＆カーズVer2.02.67対応へ変更。<br>
・ナイトウィザードのダイスボットでファンブル時には常時以外のボーナスを適用しないように修正。Azさん指摘ありがとうっ！<br>
・ナイトウィザードのダイスボットを2版と3版に分割。ファンブル時の判定処理のみ異なります。<br>
・ナイトウィザードのダイスボットを元にセブン＝フォートレスメビウスのダイスボットを作成。<br>
・ダイスボットに「メタルヘッドエクストリーム」を追加。anony403さんありがとうっ！<br>
・固定したマップマーカーにマウスカーソルを当てた場合にマーカーが展開される問題を修正。Amidaさん指摘ありがとうっ！<br>
<br>
2017/04/18 Ver.1.48.24<br>
・ダイスボットをボーンズ＆カーズVer2.02.66対応へ変更。<br>
・ダイスボットにデッドラインヒーローズを追加。りえなさんありがとうっ！<br>
・コード：レイヤードの判定出力を変更。クリティカル値を明示へ。<br>
<br>
2017/01/15 Ver.1.48.23<br>
・ダイスボットをボーンズ＆カーズVer2.02.65対応へ変更。<br>
・ダイスボットに「ガンドッグ・リヴァイズド」を追加。anony403さんありがとうっ！<br>
・ダイスボットに「碧空のストレイヴ」を追加。anony403さんありがとうっ！<br>
・ダイスボットに「青春疾患セラフィザイン」を追加。anony403さんありがとうっ！<br>
・ダイスボットに「犯罪活劇RPGバッドライフ」を追加。anony403さんありがとうっ！<br>
<br>
2016/12/31 Ver.1.48.22<br>
・ダイスボットをボーンズ＆カーズVer2.02.64対応へ変更。<br>
・コロッサルハンターの判定でクリティカル／ファンブルが同時発動時にファンブルを優先に。<br>
<br>
2016/12/20 Ver.1.48.21<br>
・ダイスボットをボーンズ＆カーズVer2.02.63対応へ変更。<br>
・ダイスボットにコロッサルハンターを追加。<br>
・片道勇者に各種コマンドを追加。<br>
・SW2.0にファンブル表と絡み表を追加。NKudryavkaさんありがとうっ！<br>
・クトゥルフのダイスボットに中文版を追加。zeteticlさんありがとうっ！<br>
<br>
2016/11/30 Ver.1.48.20<br>
・WEBIFにメッセージカード追加コマンドaddMessageCardを追加。詳細はREADME.htmlを参照。<br>
・ロストロイヤルのダイスボットのファンブル時の判定誤りを修正。EthanEricさん、酒田シンジさん、ありがとうっ！<br>
・中国語メッセージを修正。zeteticlさんありがとうっ！<br>
<br>
2016/10/20 Ver.1.48.19<br>
・チャットパレットのタブをドラッグした後に変更画面が正しく動かなくなる不具合を修正。<br>
・ダイスボットをボーンズ＆カーズVer2.02.62対応へ変更。<br>
・ドラクルージュのダイスボットを更新。「ヘレティカノワール」に対応。<br>
<br>
2016/09/28 Ver.1.48.18<br>
・チャットパレットのボタン名が表示されないされない不具合を修正。<br>
・ダイスボットをボーンズ＆カーズVer2.02.61対応へ変更。<br>
・エクリプスフェイズのエクセレント／シビア判定の誤りを修正。くまかばさんありがとうっ！<br>
<br>
2016/09/22 Ver.1.48.17<br>
・画面のフォントサイズの変更時にツールチップのフォントサイズも変更されるように改良。<br>
・チャットパレットのタブ削除復旧処理の不具合を修正。<br>
・チャットパレットのタブ削除をタブ上のボタンではなく画面のボタンで実施するように仕様変更。<br>
・ダイスボットをボーンズ＆カーズVer2.02.60対応へ変更。<br>
・エクリプスフェイズの用語を日本語版表記に。ARHMさんありがとうっ！<br>
・エースキラージーンを追加。くまかばさんありがとうっ！<br>
・コード：レイヤードを追加。くまかばさん、erina-alxさん、ありがとうっ！<br>
・ロストロイヤルを追加。erina-alxさん、ありがとうっ！<br>
・歯車の塔の探空士(スカイノーツ)を追加。sucRoさんありがとうっ！<br>
・剣の街の異邦人TRPGを追加。saronpasuさんありがとうっ！<br>
・ソードワールド2.0に成長ロールを追加。erina-alxさんありがとうっ！<br>
<br>
2016/09/01 Ver.1.48.16<br>
・メモの複数タブ機能を改良。<br>
・メモ画面に合わせて、チャットパレットのタブ機能を改良。<br>
<br>
2016/08/24 Ver.1.48.15<br>
・画像アップロードで「全体」を選べるかをコンフィグで制御可能に。src_ruby/config.rbの $canUploadImageOnPublic で指定できます。<br>
・メモを複数タブで管理可能に。<br>
・「黒絢のアヴァンドナー」のダイスボットを修正。anony403さんありがとうっ！<br>
<br>
2016/07/20 Ver.1.48.14<br>
・キャラクターをマップの下に隠した場合にチャットの名前爛に表示しないように改良。<br>
・wordCheckerのスペルミスを修正。<br>
・ダイスボットをボーンズ＆カーズVer2.02.58対応へ変更。<br>
・アマデウスを「神話創世RPG アマデウス03 絶界九龍」に対応。よっしーさんありがとうっ！<br>
・同人TRPG「黒絢のアヴァンドナー」に対応。anony403さんありがとうっ！<br>
・ソードワールド2.0の超越判定を修正。やしろさん指摘ありがとうっ！<br>
<br>
2016/07/14 Ver.1.48.13<br>
・部屋名を後から「削除可能」と名付けた場合に警告を出すように機能追加。 src_ruby/config.rb の $wordChecker で定義を変更可能<br>
・カードに紫縞のリヴラドールのリヴラデッキを追加。<br>
・ダイスボットの説明文を別ウィンドウで表示するボタンを追加。チャットウィンドウの「？」アイコンを押すと表示されます。くまかばさんありがとうっ！<br>
・チャットパレットのタブを左右に移動できるように右クリックメニューを追加。<br>
・config_local.rb 処理にエラーがあった場合の処理を改良。<br>
<br>
2016/07/04 Ver.1.48.12<br>
・ダイスボットをボーンズ＆カーズVer2.02.57対応へ変更。<br>
・モノトーンミュージアムをトレイメントに対応。Dahlia*さんありがとうっ！<br>
<br>
2016/06/30 Ver.1.48.11.01<br>
・メタルヘッドのダイスボットを修正。<br>
<br>
2016/06/29 Ver.1.48.11<br>
・ダイスボットをボーンズ＆カーズVer2.02.55対応へ変更。<br>
・片道勇者の誤字を修正。<br>
・ダイスボットにPathfinder、アルシャード、イサー・ウェン＝アー、ダンジョンズ＆ドラゴンズ、トーキョーＮ◎ＶＡ、パラノイア、フルメタル・パニック！、メタリックガーディアン、メタルヘッド、ゆうやけこやけ、ワースブレイド、世界樹の迷宮SRS、そしてStandard RPG System（SRS用の汎用）を追加。ダイスボットにシステム名を表示させるために形だけ追加しているものが多いです。くまかばさんありがとうっ！<br>
・エクリプス・フェイズの名称を日本語版発売に合わせてEclipse Phaseから日本語へ。<br>
<br>
2016/06/23 Ver.1.48.10<br>
・ダイスボットをボーンズ＆カーズVer2.02.54対応へ変更。<br>
・片道勇者を修正。判定処理で3Dに対応。クリティカルをスペシャルに表記修正。<br>
・シークレットダイスの結果が自分自身のチャットログには記録されるように機能が追加（過去バージョンでされていましたが記載が抜けていたためここで明記）<br>
<br>
2016/06/18 Ver.1.48.09<br>
・ダイスボットをボーンズ＆カーズVer2.02.53対応へ変更。<br>
・片道勇者を追加。<br>
・ブレイドオブアルカナを追加。かすかさんARHMさんありがとうっ！<br>
<br>
2016/06/14 Ver.1.48.08.01<br>
・ダイスボットの文字コードの誤りを修正。<br>
<br>
2016/06/13 Ver.1.48.08<br>
・ダイスシンボルを変更した際の結果を表示するように機能変更。<br>
・ビギニングアイドルのダイスボットを修正。かすかさんありがとうっ！<br>
　・パフォーマンスで取り除く出目が無いときは、出目を重複して表示しないように変更
　・マイスキル名決定表の使用は任意のため、マイスキル効果表を個別に振れるように変更
・韓国語データを更新。また、以下のダイスボットに韓国語対応版を追加。HunterHallの人たちありがとうっ！<br>
　・韓国対応タイトル：アマデウス、ビギニングアイドル、クトゥルフ、クトゥルフ7版、でたとこサーガ、ドラグルージュ、インセイン、神我狩、キルデスビジネス、ログホライズン、モノトーンミュージアム、ネクロニカ<br>
・ダイスオブザデットのダイスボットを追加。神武来さんありがとうっ！<br>
・紫縞のリヴラドールのダイスボットを追加。anony403さんありがとうっ！<br>
・ダイスシンボルがD20の場合に削除メニューが表示されない問題を修正。<br>
<br>
2016/05/31 Ver.1.48.07<br>
・ビギニングアイドルのダイスボットを大幅に更新。かすかさんありがとうっ！<br>
　・『フォーチュンスターズ』に対応<br>
　・バーストタイムで出目変更効果を介入可能とするために、バースト表を個別に振れるように変更<br>
　・仕事表を振りなおす要素が追加されたため、仕事表のランダムで決定する指定特技を自動的に決めないように変更<br>
<br>
2016/05/27 Ver.1.48.06<br>
・カードを山札から抜き出す／N枚引く処理に失敗する不具合を修正。HALさん指摘ありがとうっ！<br>
・これに伴い、カード情報の取得タイミングをログイン直後に差し戻し（こちらは実装だけの話で、使用方法には影響ないです）<br>
・フォントサイズを変更した場合にキャラクター置き場の配置が崩れる問題を修正。<br>
・言語ファイルを更新。日隠さんありがとうっ！<br>
・ダイスシンボルのD20に0の出目を追加。<br>
<br>
2016/05/20 Ver.1.48.05<br>
・イニシアティブ表で最小値を指定した場合に値が自動調整されない不具合を修正。よっしーさん指摘ありがとうっ！<br>
・カードに特定書式で独自定義を追加した場合に正しく処理されない不具合を修正。日隠さん指摘ありがとうっ！<br>
<br>
2016/05/17 Ver.1.48.04<br>
・イニシアティブ表で最大／最小値を？で指定して値が０の場合に正しく動作しない不具合を修正。メタボルタさん指摘ありがとうっ！<br>
・コマにマウスカーソルを合わせた場合に、最前面に表示されるように機能改善。<br>
<br>
2016/05/14 Ver.1.48.03<br>
・イニシアティブ表で最大／最小値を設定している場合に、コマの上にカウンターを示すバーを表示する機能を試作。<br>
・キャラクター変更画面でカウンターを変更した場合に、最大・最小値が狂う不具合を修正。<br>
・チャットパレットでイニシアティブ表の値を入れ子で参照している場合に正しく値が展開されない不具合を修正。<br>
・タグ名の表示文字数に上限を設定。<br>
・エラーメッセージ(Language:versionMismuch)を改善。<br>
<br>
2016/05/08 Ver.1.48.02<br>
・最大・最小値を設定した場合にカウンターリモコンで値の変更が正しく動かない問題を修正。<br>
・画像選択時のタグ名の順序をソート。<br>
<br>
2016/05/07 Ver.1.48.01<br>
・カードの管理方法を変更。ダイスボットと同じように、cardsディレクトリに必要な .txt ファイル（必要であれば画像ファイル）を置くするだけで任意のカードが追加可能に。<br>
　これにともない、カードの表記が変更。1行目に title=カード名, を追加する必要があります。<br>
　カードの表示順序は src_ruby/config.rb の $cardOrder で定義。<br>
　詳細は <u><a href="cards/_README.txt">cards/_README.txt</a></u> を参照。<br>
　あと、バージョンアップ時に上書きでファイル転送をする場合には、既存のファイルから card/structureCard.txt の削除をお願いします。<br>
・イニシアティブ表で上下限を指定可能に。（最小）＜カウンター名＜（最大）で値を指定。「？」を指定すると個別に設定も可能です。<br>
・上記変更に伴い、LanguageファイルにinitiativeColumnMaxFormat, initiativeColumnMinFormatそしてinputerCounterNamesInfo_4 が追加。<br>
・どどんとふのサーバ側のファイル構成を変更。（設置／バージョンアップ／使用方法には変更ありません）<br>
<br>
2016/04/21 Ver.1.48.00<br>
・安定版を「sugar chocolate waffle」としてリリース。<br>
　以下の変更が含まれます。<br>
・マルチ言語対応時にリプレイ再生でログが流れない問題に対応。<br>
・マルチ言語対応のダイスボットでビジュアルダイスのバルーン表示に言語名がつく問題を修正。<br>
・ダイスボットの標準としてD66を有効に。「D66」あるいは「D66N」なら入れ替え無し、「D66S」なら入れ替えあり（[5,3]が35となる）をサポート。「D66」は基本D66Nですが、D66Sのみ使用するシステムはSとして振る舞います（つまり従来通りの挙動）。<br>
<br>
<!-- RELEASE_LINE -->
<br>
2016/04/07 Ver.1.47.24<br>
・ダイスボットをボーンズ＆カーズVer2.02.51対応へ変更。<br>
・ガーデンオーダーに対応。りえなさん、ありがとうっ！<br>
・アマデウス02 旋血ラグナロクに対応。よっしーさん、ありがとうっ！<br>
・詩片のアルセットのダイスボットを更新。anony403さん、ありがとうっ！<br>
・CGIのコマンド処理を効率化。NKMR6194さんありがとうっ！<br>
<br>
2016/03/24 Ver.1.47.23<br>
・ダイスボットをボーンズ＆カーズVer2.02.50対応へ変更。<br>
・ドラクルージュの反応表でダストハイムが変換できない問題を修正。解凍いかさん指摘ありがとうっ！<br>
・メッセージカードを複製した際に、所持権もコピーするように機能追加。<br>
・他言語対応のダイスボットでコマンドが有効にならない問題に対応。광제아さん指摘ありがとうっ！<br>
・チャットパレットでチェック項目を｛＊転倒｝のように＊大文字でも指定できるように機能改良。<br>
<br>
2016/03/19 Ver.1.47.22<br>
・ダイスボットをボーンズ＆カーズVer2.02.49対応へ変更。<br>
・常夜国騎士譚RPG ドラクルージュに対応。<br>
・中国語表記を更新。日隠さんありがとうっ！<br>
<br>
2016/03/08 Ver.1.47.21.01<br>
・チャットパレットの変換ルールを ｛キー名＠タブ名｝に変更。<br>
<br>
2016/03/07 Ver.1.47.21<br>
・ダイスボットをボーンズ＆カーズVer2.02.48対応へ変更。<br>
・同人TRPGの「詩片のアルセット」の不具合を修正。かすかさんありがとうっ！<br>
・チャットパレットで、他のタブの値を ｛タブ名＃キー名｝で参照できるように機能拡張。<br>
<br>
2016/02/24 Ver.1.47.20<br>
・カウンターリモコンでのリソースウィンドの値を編集する場合に値が指定できない不具合を修正。<br>
・また、イニシアティブリモコンの説明文を追記。（Language の counterRemoconCounterNameTips）<br>
・ダイスシンボルを変更した場合に、変更が通知されるように機能改良。<br>
・ダイスボットをボーンズ＆カーズVer2.02.47対応へ変更。<br>
・ビギニングアイドルのダイスボットを大幅に更新。かすかさんありがとうっ！<br>
・ダイスボットに同人TRPGの「詩片のアルセット」を追加。anony403さん、かすかさん、ありがとうっ！<br>
<br>
2016/02/20 Ver.1.47.19<br>
・ダイスボットをボーンズ＆カーズVer2.02.46対応へ変更。<br>
・クトゥルフ第7版を追加。ニャル提督さんありがとうっ！<br>
・鵺鏡の誤字を修正。<br>
・リプレイ再生時に音が鳴らない問題を修正。ororoさん指摘ありがとうっ！<br>
・上記に合わせ、リプレイ編集時に音声のあり／なしを選択可能へ。<br>
・＠での末尾発動が再ログイン時に表示されてしまう不具合を修正。<br>
・秘話中に点呼／投票を行うと全員に結果が反映されない不具合を修正。<br>
・カウンターリモコンでリソースウィンドの値も編集できるように機能追加。<br>
<br>
2016/02/09 Ver.1.47.18<br>
・ダイスボットをボーンズ＆カーズVer2.02.45対応へ変更。<br>
・アマデウスのダイスボットを更新（誤字修正）。よっしーさんありがとうっ！<br>
・ビギニングアイドルのダイスボットを大幅に更新。かすかさんありがとうっ！<br>
・鵺鏡のダイスボットを追加。<br>
・チャットで末尾に「セリフ＠名前」のように記載すると「名前：セリフ」のように＠で指定したキャラで話せるように機能拡張。「セリフ＠名前＠表情」のように記載することで、名前も表情もチャットパレット等で決めうちで打ち込むことができるようになります。<br>
・マプマーカーの変更画面に、マーカーを動かないように固定するためのチェック項目を追加。<br>
・chat.html を更新。きりだるまさんありがとうっ！<br>
<br>
2016/01/27 Ver.1.47.17<br>
・ダイスボットをボーンズ＆カーズVer2.02.45対応へ変更。<br>
・アマデウスのダイスボットを更新。よっしーさんありがとうっ！<br>
・カードにアマデウスの脅威カードを追加。今野さんありがとうっ！<br>
・chat.html を更新。きりだるまさんありがとうっ！<br>
<br>
2016/01/23 Ver.1.47.16<br>
・欠番<br>
<br>
2016/01/14 Ver.1.47.15<br>
・64Bit版Chromeの最新版で全セーブ機能が正しく動かない不具合に対処。くまかばさんありがとうっ！<br>
<br>
2016/01/07 Ver.1.47.14<br>
・クトゥルフのダイスボットの判定方法を大幅に変更。仕様策定はこーちゃKPさん！<br>
<br>
2016/01/06 Ver.1.47.13<br>
・ログイン画面の「古いプレイルームを削除」ボタンがうまく動作しなくなっていた不具合を修正。大ちゃ指摘ありがとうっ！！<br>
<br>
2016/01/03 Ver.1.47.12<br>
・ダイスボットをボーンズ＆カーズVer2.02.44対応へ変更。<br>
・アマデウスのダイスボットを更新。よっしーさんありがとうっ！<br>
・中国語表記を更新。日隠さんありがとうっ！<br>
・立ち絵設定画面のプレビューサイズを拡大。<br>
・部屋ローカルでアップロードした画像のタグ名編集がうまくできない不具合を修正。Mikisatoさん指摘ありがとぅっ！<br>
・プレイルームの設定で表示対象を変更した場合に、変更画面を開きなおしても設定が反映されない不具合を修正。はる○さん、ゆかりさん指摘ありがとぅっ！<br>
<br>
2015/12/17 Ver.1.47.11<br>
・韓国語対応ファイルの名前誤りを修正。前バージョンをインストールされた方は language/Korea.txt を削除願います。(Korean.txt に修正してあります)<br>
・ダイスボットを多言語対応へ。ダイスボットのファイル名・class名を(クラス名)_(言語名)（例： LogHorizon_Korean.rb）、gameType を "（ダイスボット名）:（言語名）"（例："LogHorizon:Korean"）のように設定しておくと、言語が一致する方のダイスボットが表示されるようになります。具体例として src_bcdice/diceBot/LogHorizon_Korean.rb を参照。<br>
・言語選択時にメッセージを表示できるように機能追加。<br>
・ログアウトのチェック項目の文字列が多言語対応してなかった問題を修正。<br>
・部屋作成時のダイスボット一覧に不要な種別が表示されていた不具合を修正。<br>
・外部URL使用時に、見学可の部屋では発言が常に見学タブになってしまっていた不具合を修正。ひのたちさん指摘ありがとうっ！<br>
・カードの右クリックメニューに「カードを山札に戻す」を追加。<br>
・山札の右クリックメニューに「山札をシャッフルする」を追加。<br>
<br>
2015/12/08 Ver.1.47.10<br>
・多言語対応で韓国語に対応。광제아さん、アディンさん、ありがとうございますっ！<br>
・ダイスボットをボーンズ＆カーズVer2.02.43対応へ変更。<br>
・ジェームズ・ボンド007に対応。loveichiさんありがとうっ！<br>
・CHILL第３版に対応。Facelessさんありがとうっ！<br>
・コマの「画像切り替え設定」操作時に画像が勝手に差し変わってしまう問題を修正。らーいさん指摘ありがとうっ！<br>
・ログイン画面の一覧で2番目以降の部屋のタブで「削除」ボタンを押した場合に、正しく削除できない問題を修正。にょぼろさん指摘ありがとうっ！<br>
・見学者の場合にダイスボットの説明が正しく表示されない問題を修正。。にょぼろさん指摘ありがとうっ！<br>
・ログアウト時の部屋削除の質問の有無をsrc_ruby/config.rb の $isAskRemoveRoomWhenLogout で変更できるように。<br>
<br>
2015/11/22 Ver.1.47.09<br>
・チャットの音声OFF時にカットインもミュートされるように仕様変更。<br>
・外部画像URL無効の場合、各種画像のURLが入力出来ないように、また有効時には全ての画像選択画面でURLが表示されるように機能／画面構成を変更。<br>
・ログイン画面に、各部屋の削除ボタンを追加。<br>
・ログアウト時にログイン人数が１人なら、部屋の削除を促すように機能追加。<br>
<br>
2015/11/07 Ver.1.47.08<br>
・中国語表記を更新。日隠さんありがとうっ！<br>
・ログインパスワード時にEnterで入室可能に。<br>
・chat.htmlで見学可能時にパスワードを入力しても見学者になってしまう不具合を修正。ピロロさん指摘ありがとうっ！<br>
・ダイスボットをボーンズ＆カーズVer2.02.42対応へ変更。<br>
・ナイトウィザードのダイスボットを更新。kaiさんありがとうっ！！<br>
・アマデウスのダイスボットを更新。<br>
<br>
2015/10/12 Ver.1.47.07<br>
・chat.htmlのチャット表示にチャットタブ名を追加。<br>
・chat.htmlでログイン先がパスワード付きの見学有効の場合、チャットの発言が見学タブに書き込まれるように改善。<br>
・ダイスボットをボーンズ＆カーズVer2.02.41対応へ変更。<br>
・ログホライズンのダイスボットにゴブリン財宝表(GTRSx)を追加。クロさんありがとうっ！<br>
<br>
2015/09/17 Ver.1.47.06<br>
・カード一覧に花札を追加。メタボルタさんありがとうっ！<br>
・カードの削除メニューが使用できなくなっていた不具合を修正。<br>
・トランプのミニ版の名前が誤っていたため修正。<br>
<br>
2015/09/05 Ver.1.47.05<br>
・ダイスボットをボーンズ＆カーズVer2.02.40対応へ変更。<br>
・ダイスボットにアマデウスを追加。<br>
・SW2.0に、超越判定用として、2d6ロールに 2D6@10 書式でクリティカル値付与を機能追加。<br>
<br>
2015/08/27 Ver.1.47.04<br>
・ダイスボットをボーンズ＆カーズVer2.02.39対応へ変更。<br>
・ダイスボットに同人TRPGの少女展爛会を追加。サークルSimple Craftsさんありがとうございます！<br>
<br>
2015/08/23 Ver.1.47.03<br>
・カードの右クリックメニューに「カードの譲渡」を追加。カード置き場がある場合にカードを送ることができるようになります。<br>
<br>
2015/08/21 Ver.1.47.02<br>
・ダイスボットをボーンズ＆カーズVer2.02.38対応へ変更。<br>
・ルーンクエストのダイスボットで成長ロールを振った場合に正しくロールできない不具合を修正。<br>
・迷宮キングダムの表の誤字を修正。抹茶おむぎりさん指摘ありがとうっ！<br>
・トワイライトガンスモークの表の誤字を修正。クロキさん指摘ありがとうっ！<br>
<br>
2015/08/08 Ver.1.47.01.01<br>
・Ruby1.8.5環境でダイスボットの四則演算が上手く動かない不具合を修正。<br>
<br>
2015/08/06 Ver.1.47.01<br>
・ダイスボットをボーンズ＆カーズVer2.02.37対応へ変更。<br>
・ダイスボットにビギニングアイドルを追加。松吉さんありがとうっ！<br>
・神我狩に感情表(ET)を追加。松吉さんありがとうっ！<br>
・トワイライト・ガンスモークの表誤りを修正。ARHMさんありがとうっ！<br>
<br>
2015/07/05 Ver.1.47.00<br>
・Ver.1.46.20をベースに安定版を「Out of Control」としてリリース。<br>
<!-- RELEASE_LINE -->
<br>
2015/07/04 Ver.1.46.20<br>
・ダイスボットをボーンズ＆カーズVer2.02.36対応へ変更。<br>
・同人TRPGの「朱の孤塔のエアゲトラム」を追加。anony403さんありがとうっ！<br>
・ダイスボットをボーンズ＆カーズVer2.02.36対応へ変更。<br>
・D66でSD66とシークレッドダイスが振れない不具合を修正。わっぱーさん指摘ありがとうっ！<br>
・ゴリラTRPGでGコマンドをシークレットダイスにできない不具合を修正。わっぱーさん指摘ありがとうっ！<br>
・T＆Tの説明文を修正。<br>
・WEB IFにメモ変更用のchangeMemoを追加。詳細はREADME.htmlの記述参照。<br>
・「2 2d6」のような複数ダイス一括ロール時に立ち絵情報が重複する内部不具合を修正。ゆかりさん指摘ありがとうっ！<br>
<br>
2015/05/26 Ver.1.46.19<br>
・ダイスボットをボーンズ＆カーズVer2.02.35対応へ変更。<br>
・秘話モードで文頭に（１）のようにかっこ文字を書くとダイスロールと判断されて発言が公開されてしまう不具合を修正。<br>
・ダイスボットの達成値がマイナスになった場合に正しく判定が行われない問題を修正。<br>
・艦これダイスボットにコマンド追加（大規模部隊表、艦隊敗北表、艦隊勝利表）。<br>
・アースドーン4版に複数ステップ同時ロールを対応。<br>
<br>
2015/04/15 Ver.1.46.18<br>
・ダイスボットをボーンズ＆カーズVer2.02.34対応へ変更。<br>
・ダイスボットにアースドーン4版を追加。<br>
<br>
2015/04/07 Ver.1.46.17<br>
・ダイスボットをボーンズ＆カーズVer2.02.33対応へ変更。<br>
・ガラコと破界の塔の誤字を修正。Amidaさん指摘ありがとうっ！<br>
<br>
2015/03/30 Ver.1.46.16<br>
・C(-1*-1)や(2--1)のようなマイナス値の場合に正しく計算できない不具合を修正。<br>
・カード操作ログ表示をOFFにした場合に設定が保存されない不具合を修正。はるまるさん指摘ありがとうっ！<br>
<br>
2015/03/18 Ver.1.46.15.01<br>
・モノトーンミュージアムの誤字を修正。cocodahliaさん指摘ありがとうっ！<br>
<br>
2015/03/15 Ver.1.46.15<br>
・ダイスボットをボーンズ＆カーズVer2.02.32対応へ変更。<br>
・ガープスのダイスボットにコマンドを追加。ハスキーさんありがとうっ！！<br>
・WEB IFのrefreshのコマンドを修正。使用法方法の詳細をREADMEに追記。<br>
・送信エラー時の再送ウィンドウにキャンセルボタンを追加。<br>
<br>
2015/03/05 Ver.1.46.14<br>
・ダイスボットをボーンズ＆カーズVer2.02.31対応へ変更。<br>
・ダイスボットにでたとこサーガを追加。神武来さんありがとうっ！！<br>
・ダイスボットにShared†Fantasiaを追加。くまかばさんありがとうっ！！<br>
<br>
2015/02/11 Ver.1.46.13<br>
・ダイスのロール音を変更（ボリューム小さく）。いろはりうむさんありがとうっ！<br>
・カードのマスカレードスタイル修正版に改版。NowRiverさんありがとうっ！<br>
・ダイスボットをボーンズ＆カーズVer2.02.30対応へ変更。<br>
・ログホライズンにイースタル探索表を追加。pueriusさんありがとうっ！<br>
<br>
2015/01/25 Ver.1.46.12<br>
・ダイスのロール音を変更。いろはりうむさんありがとうっ！<br>
・カードのマスカレードスタイルを改定β版に変更。<br>
・チット作成画面の画像一覧に表示される画像枚数が8～10枚の場合にFlashが落ちる不具合を修正。alshさん指摘ありがとうっ！<br>
・立ち絵設定画面でソート順を変えた場合に選択している立ち絵が正しく選ばれない問題を修正。ひのたちさんありがとうっ！<br>
・キャラクター待合室で画像削除したキャラクターが移動しにくくなる問題を修正。ひのたちさんありがとうっ！<br>
・WEBチャット機能のファイル名を diceChat.html から chat.html に変更。（上書きインストールされる方はdiceChat.htmlを削除願います）。＋が入力できない不具合を修正。その他、文字色を設定できるようにしたり自動更新するようにしたり、色々改善。今野博臣さん、ASBさん、指摘ありがとうっ！<br><br>
<br>
2015/01/17 Ver.1.46.11<br>
・全データセーブ／ロードを行った場合に画像データのタグ情報が正しく表示されない問題に対応。<br>
・HTML上のチャット専用機能を追加。いつも DodontoF.swf としているところを diceChat.html にすると使用できます。現状、部屋の作成／削除は未対応なのでそちらはどどんとふ本体にてお願いします。<br>
・マップの下に隠しているキャラクターをカウンターリモコンの一覧に表示しないように改良。がうさん提案ありがとうっ！<br>
<br>
2015/01/03 Ver.1.46.10.01<br>
・ダイスボットをボーンズ＆カーズVer2.02.29.01対応へ変更。<br>
・ガラコと破界の塔の誤字を修正。<br>
<br>
2015/01/03 Ver.1.46.10<br>
・全データセーブ／ロードを行った場合にローカルに削除できない画像データが残ってしまう問題に対応。<br>
・ダイスボットをボーンズ＆カーズVer2.02.29対応へ変更。<br>
・ダイスボットに同人ゲームのガラコと破界の塔にサプリメントの表を追加。ワイエスさんありがとうっ！！<br>
<br>
2015/01/02 Ver.1.46.09<br>
・リプレイ再生後にチャットウィンドウのフォントサイズが変更されてしまう不具合を修正。笹の葉さん指摘ありがとうございますっ！！！<br>
・チャットフォントサイズが保存されなくなっていた不具合を修正。ひのたちさん指摘ありがとうございますっ！<br>
・ダイスボットをボーンズ＆カーズVer2.02.28対応へ変更。<br>
・ダイスボットに同人ゲームのガラコと破界の塔を追加。anony403さん、ブラフマンさんありがとうっ！！<br>
<br>
2015/01/01 Ver.1.46.08<br>
・チャットウィンドウの色分けに連動してチャットパレットも色分けするように機能追加。<br>
・メッセージカードの右クリックメニューに「カード複製」を追加。<br>
・チャットパレットにタブ名を付ける用の「タブ名」項目を追加。<br>
<br>
2014/12/24 Ver.1.46.07<br>
・ダイスボットをボーンズ＆カーズVer2.02.27対応へ変更。<br>
・ダイスボットのテストデータ構成を改良。ochaさんありがとうっ！！！<br>
　テスト方法の変更詳細については、<u><a href="src_bcdice/test/README.html#aboutTestChanged">テスト方式の変更について</a></u>を参照。<br>
・クトゥルフの呼び声のCRBコマンドで部分的成功を表示するように改良。<br>
・ログホラに楽器種別表、特殊消耗表等の表を追加。<br>
・フィルトウィズの誤字を修正。<br>
・ダイスロール時のメッセージの末尾に「２ｄ６　ロール！」のように「！」を付けると、<br>
　つけた数だけダイスのサイズとロールの勢いが大きくなる機能を追加。<br>
・チャットウィンドウをタブ毎にウィンドウ色が変わるように機能追加。チャットウィンドウの「A」アイコンから設定変更できます。<br>
<br>
2014/11/27 Ver.1.46.06<br>
・ダイスボットをボーンズ＆カーズVer2.02.26対応へ変更。<br>
・ログ・ホライズンTRPGにチャート追加。サロンパスさんありがとうっ！<br>
・部屋削除時にローカル（デフォルトの「専用」指定）でアップロードした画像を削除するように機能追加。<br>
・画像を共有でアップロードし、新規作成した別の部屋から削除するとエラーが発生する不具合を修正。Sarlaさん指摘ありがとうっ！<br>
<br>
2014/11/15 Ver.1.46.05<br>
・Ver.1.46.01の imageInfo.json 分轄後、対象外の部屋画像が全て表示されてしまう問題を対処。<br>
　これに伴い、 imageUploadSpace に手動でファイルを追加した場合に自動的に画像一覧にも追加される仕様は変更になります。<br>
　今後は画像の手動追加時には imageUploadSpace/public ディレクトリに（無い場合はディレクトリを作成して）画像を置くようにしてください。<br>
<br>
2014/11/12 Ver.1.46.04<br>
・キャラクターの移動が上手く動かなくなっていた不具合を修正。今野博臣さんありがとうっ！<br>
・マギカロギアの誤記を修正。woreyさん指摘ありがとうっ！<br>
・カードの縦横サイズを src_ruby/card.rbで変更できるように改良。<br>
<br>
2014/11/11 Ver.1.46.03<br>
・Ver.1.46.01でリリースした、imageInfo.json変換用ツール<br>
　　src_ruby/splitImageTagInfo.rb<br>
　の不具合を修正。大ちゃ指摘ありがとうっ！<br>
・カットイン設定画面の説明文が正しく表示されるように修正。日隠さん指摘ありがとうっ！<br>
・カードピックアップがカードの真上の場合に表示／非表示を繰り返さないように改良。<br>
<br>
2014/11/08 Ver.1.46.02<br>
・前回の imageInfo.json 分轄処理で、画像アップロードに失敗するパターンがあったため不具合修正。<br>
・Rubyソースコード上の文法警告を修正。<br>
・ダイスボットをボーンズ＆カーズVer2.02.25対応へ変更。<br>
　・トワイライトガンスモークのダイスボットを追加。ARHMさんありがとうっ！<br>
　・モノトーンミュージアムのダイスボットに感情表／感情表2.0／歪み表ver2.0を追加。ARHMさんありがとうっ！<br>
　・艦これの説明文を修正。その３さんありがとうっ！<br>
<br>
<br>
2014/11/06 Ver.1.46.01<br>
・画像情報ファイル imageInfo.json ファイルを今までの全部屋共通保持から部屋毎の個別保持へ変更。<br>
　画像を共有アップロードした場合は従来通り、部屋専用アップロードした場合は部屋毎のファイルへ保持へ。<br>
　大量アクセスでファイルが破損する場合の対策用に。<br>
　また既存の imageInfo.json の変換用に src_ruby/splitImageTagInfo.rb を追加。<br>
　どどんとふのバージョンアップ後、コマンドラインで<br>
　　src_ruby/splitImageTagInfo.rb<br>
　とスクリプトを実行すると imageInfo.json ファイルを今回の部屋毎の分轄方式へ変換します。<br>
・試作機能として、MySQLのDB保持方法を改良したバージョンを作成。<br>
　試作のため今までのDBは引き継がれず、完全に新規作成のみ対応。<br>
　バグも大量に含まれると思います。<br>
　つまり★完全人柱用★<br>
　現状、以下の手順を実行した場合のみ使用できます。<br>
　逆に言えば、以下の（特に(2)）を実施しなければ特に問題ありません。<br>
　(1)どどんとふを MySQL版で環境構築する<br>
　(2)DodontoFServerMySqlKai.rb ファイルに実行権限を与える。<br>
　(3)どどんとふに DodontoF.swf?mode=mysqlkai のようにオプションを付けてアクセスする。<br>
<br>
2014/10/31 Ver.1.46.00<br>
・Ver.1.45.12をベースに安定版を「MASTERPIECE」としてリリース。<br>
<br>
2014/10/31 Ver.1.45.12<br>
・リプレイ投稿機能が正しく動かなくなっていた不具合を修正。ひのたちさんありがとうっ！<br>
<br>
2014/10/26 Ver.1.45.11<br>
・ダイスボットをボーンズ＆カーズVer2.02.24対応へ変更。<br>
・ログ・ホライズンにコマンド追加、コマンド改良。Nanasuさんありがとうっ！<br>
・インセインの表、カードの誤字を大量に修正。ARHMさんありがとうっ！<br>
・ダイスボットに同人ゲームのフィルトウィズオンラインを追加。ハスキーさんありがとぅっ！詳細はこちら。<a href="http://projectfw.web.fc2.com/index.html">http://projectfw.web.fc2.com/index.html</a><br>
<br>
2014/10/22 Ver.1.45.10<br>
・ダイスボットをボーンズ＆カーズVer2.02.23対応へ変更。<br>
・インセインの誤字を修正。<br>
・中国語を修正対応。<br>
・チャットログ保存時に別タブのメッセージが含まれないように修正。<br>
　逆に、全タブのメッセージを保存できるように、チャットログ保存画面に「全タブ」ボタンを追加。<br>
<br>
2014/10/18 Ver.1.45.09<br>
・チャットで別のタブのメッセージを参照できるように機能追加。チャットウィンドウの「A」アイコンから「チャット文字設定」を開き、「別タブメッセージ表示」にチェックを入れると機能が有効となります。<br>
・同一名キャラクター追加時のエラーメッセージを修正。ひいんさん指摘ありがとうっ！<br>
・ダイスボットをボーンズ＆カーズVer2.02.22対応へ変更。<br>
・艦これBOTに敵指定個性用のBT10-BT12を追加。DD雪野さんありがとうっ！<br>
<br>
2014/09/17 Ver.1.45.08.01<br>
・ダイスボットの指定で「ダイスボット(指定無し)」を先頭以外に配置した場合に、先頭のダイスボットのみ専用コマンドが動かなくなる不具合を修正。とむさんその３さんありがとぅっ！<br>
<br>
2014/09/16 Ver.1.45.08<br>
・インセインのカード誤記を修正。にょぼろさんありがとぅっ！<br>
・カットイン管理画面と立ち絵管理画面で複数データの一括削除機能できるように機能追加。<br>
・ダイスボットの指定から「ダイスボット(指定無し)」の順番を入れ替えたり抜いてもダイスボットの動作に問題が無いように機能改善。
　これに伴いLanguageファイルからdiceBotOtherInfomation1とdiceBotOtherInfomation2を削除。<br>
<br>
2014/09/12 Ver.1.45.07.01<br>
・インセインのカード誤記を修正。あんでぃさんありがとぅっ！<br>
<br>
2014/09/11 Ver.1.45.07<br>
・インセインのデッドループ用に狂気カード追加。能代銀華さんありがとうっ！<br>
　また各種の専用狂気を一目で識別できるようにカード背景を色分け。（山札面には色は付いていません）<br>
・ダイスボットをボーンズ＆カーズVer2.02.21対応へ変更。<br>
・シノビガミ　忍秘伝・改のシーン表の追加<br>
・キルデスビジネス　サプリメント追加シーン表の追加<br>
・インセイン　サプリメント追加シーンの追加<br>
・神我狩　追加サプリメントのシーン表の追加<br>
・マギカロギア幻惑のノスタルジアシーン表のコマンド反映されていない部分を修正<br>
　上記すべて、能代銀華さんありがとうっ！<br>
・アースドーン3版の難易度表を追加。<br>
<br>
2014/08/29 Ver.1.45.06<br>
・ダイスボットをボーンズ＆カーズVer2.02.20対応へ変更。<br>
・ダイスボットにトーグ1.5版を追加。<br>
・ダイスボットにアースドーン3版を追加。<br>
・カードランカーのコマンドに特定カード抽出用の「CM」コマンドを追加。<br>
<br>
2014/08/12 Ver.1.45.05<br>
・ダイスボットの作成方法を詳細記載。（<u><a href="src_bcdice/test/README.html">src_bcdice/test/README.html</a></u>参照）<br>
・ダイスボットをボーンズ＆カーズVer2.02.19対応へ変更。<br>
　・文字コードなどRuby1.9対応で不具合となっていた箇所を数か所修正。ochaさんありがとうっ！<br>
　・消耗表／財宝表でダイスの出目を表示するよう改善。ハスキーさんありがとうっ！<br>
<br>
2014/07/25 Ver.1.45.04<br>
・どどんとふをRuby1.9対応に。<br>
・ダイスボットをボーンズ＆カーズVer2.02.18対応へ変更。<br>
　・ダイスボットに蓬莱学園を追加。飛松志樹さんありがとうっ！<br>
　・ソードワールドのレーティングコマンドを「SK20@10」の様にシークレットモードでクリティカル指定した場合にダイスがロールされない不具合を修正。たもーれさん指摘ありがとうっ！<br>
　・インセインの誤字を修正。<br>
　・艦これRPGダイスボットを建造ノ書弐に対応。八神のぞみさん、能代銀華さん、ほか皆さんありがとうっ！<br>
・録画停止／キャンセルしてもログアウト出来ない不具合を修正。その３さん指摘ありがとうっ！<br>
・リソースウィンドウにチェック欄を追加。資源管理にご利用ください。<br>
・外部URL画像が有効な状態で外部URL画像のコマを作り全セーブロードをするとFlashがクラッシュする問題に対応。くまかばさん、ふぇいさん、指摘ありがとうっ！！<br>
・インセインの狂気カードの誤字を修正。瑠璃駒さん指摘ありがとうっ！<br>
・空き部屋のゲーム種別が空欄にならない不具合を修正。にょぼろさん指摘ありがとうっ！<br>
・デフォルトのイメージデータのフォーマットが間違っていた問題を修正。らぁさん指摘ありがとうっ！<br>
・メンテナンスモードで見学可の部屋にログインできない問題を修正。日隠さん指摘ありがとうっ！<br>
・チャット欄追加時に文字フォントサイズが反映されない問題を修正。くまかばさん、リネノンさん指摘ありがとうっ！<br>
・ロード対象にリソース表を追加。<br>
<br>
2014/06/22 Ver.1.45.03<br>
・ダイスボットをボーンズ＆カーズVer2.02.17.01対応へ変更。<br>
　・ダイスボットにグランクレストの国特徴修正を反映。偉荒弘武さん指摘ありがとうっ！<br>
・キャラクター作成／変更画面でカウンター値を999以上に出来ない不具合を修正。ハスキーさん指摘ありがとうっ！<br>
<br>
2014/06/22 Ver.1.45.02<br>
・録画中にブラウザを落としても、再ログイン時に前回の録画状態を引きついで再開できるように改良。<br>
　録画終了してファイル保存するまで録画状態が維持されます。またこれに伴い録画のキャンセルも実装。<br>
・ダイスボットをボーンズ＆カーズVer2.02.17対応へ変更。<br>
　・ダイスボットにグランクレストを追加。偉荒弘武さんありがとうっ！<br>
<br>
2014/06/18 Ver.1.45.01<br>
・ダイスボットをボーンズ＆カーズVer2.02.16対応へ変更。<br>
　・ブラッドムーンのID2Tコマンドの誤記を修正。爆弾パンチ郎さんありがとうっ！<br>
　・ブラッドムーンのコマンド追加。今野博臣さんありがとうっ！<br>
　・まよキンのMKコマンドの気力判定不具合を修正。今野博臣さんありがとうっ！<br>
　・艦これダイスボット表に建造ノ書　壱分を追加。敵深海棲艦の装備決定も追加。能代銀華さん、熊野さん、ありがとうっ！<br>
　・ダブルクロスのダイスボットでクリティカル値１の場合をエラー処理に修正。<br>
　・エリュシオンのダイスボットにコマンド追加。能代銀華さんありがとうっ！<br>
　・テストがLinux環境でも通るように修正。風柳さんありがとうっ！<br>
・簡易マップ作成画面からマス色を半透明に設定できるように機能追加。<br>
・カード置き場が置けなくなっていた不具合を修正。arhmさん指摘ありがとうっ！<br>
・指定したダイスボットだけを表示するようにするコンフィグを src_ruby/config.rb の $isDisplayAllDice として追加。<br>
<br>
2014/05/30 Ver.1.45.00<br>
・Ver.1.43.07をベースに安定版を「database」としてリリース。<br>
<br>
2014/05/29 Ver.1.44.07<br>
・ダイスボットをボーンズ＆カーズVer2.02.15対応へ変更。<br>
・ブラッドムーンのIDTコマンドの誤記を修正。爆弾パンチ郎さんありがとうっ！<br>
<br>
2014/05/25 Ver.1.44.06<br>
・ロード画面のダイスボット表の表示名を修正。<br>
・キャラクターのツールチップ（カーソル合わせた時の表示）の文字数制限をコンフィグ指定に。<br>
src_ruby/config.rb の $characterInfoToolTipMaxWidth, $characterInfoToolTipMaxHeight で指定。<br>
またデフォルトは上限無しに変更。<br>
・カードの右クリックメニューにカードを捨て山に捨てることのできる「カード捨て」を追加。<br>
・デフォルト画像の不足分を追加。くるみさん指摘ありがとうっ！<br>
・古いリプレイを再生するとチャットが表示されない不具合を修正。くまかばさん指摘ありがとうっ！<br>
・サーバへのデータ送信時のContent-Typeを"application/x-msgpack"に修正。FaviusTyさん指摘ありがとうっ！<br>
<br>
2014/05/20 Ver.1.44.05<br>
・セーブ／ロードの対象にダイスボット表を追加。<br>
・ダイスボット表にゲームシステムを指定可能に。指定したゲームでのみ表コマンドが有効になります。ダイスボット指定なしの場合は全てのシステムで表が有効となります。<br>
<br>
2014/05/16 Ver.1.44.04<br>
・「範囲」のマス目サイズをマップのマス目に合わせて拡大するように改良。<br>
・「範囲」のマス目線を削除。<br>
・ログホラ用範囲に中心マーカーを表示するように追加。<br>
・ロード対象にフロアタイルを追加。<br>
・新規プレイルーム作成時に回転マーカー／リソースウィンドウ／カウンターリモコンの表示設定が反映されない不具合を修正。薄雪さん、今野博臣さん指摘ありがとうっ！<br>
・キャラクターのツールチップ（カーソル合わせた時の表示）に文字数上限を設定。Dさん指摘ありがとうっ！<br>
・フロアタイル画面のタグ名が表示しきらない不具合を修正。リネノンさん指摘ありがとうっ！<br>
・WEB IFのchatで時間指定時に完全一致する日時のデータを取得する不具合を修正。ヴィアスさん指摘ありがとうっ！<br>
・管理モードではパスワード付の部屋を削除する場合でもパスワードを求められないように機能変更。<br>
・サーバ接続時間上限指定時にログインすると表示されるメッセージから「実プレイには向きませんのでご注意下さい」という表記を削除。（実プレイ環境でもログイン時間状態を指定したいとの要望に対応するため）<br>
<br>
2014/04/24 Ver.1.44.03<br>
・ログホライズン用の範囲を追加。メニューの「コマ」→「範囲追加」→「ログホライズン用範囲」、あるいはマップの右クリックメニューから追加可能。<br>
<br>
2014/04/22 Ver.1.44.02.01<br>
・ダイスボットのヘルプメッセージ体裁修正。(記載内容自体には変更なし)<br>
<br>
2014/04/21 Ver.1.44.02<br>
・ダイスボットをボーンズ＆カーズVer2.02.14対応へ変更。<br>
　・ログホライズンTRPGを正式対応。ハスキーさんありがとうっ！<br>
・エリュシオンのDATEコマンドを二回打った場合に、デートコマンドの結果表示が動かなくなっていた不具合を修正。今野博臣さん指摘ありがとぅっ！<br>
・イニシアティブ表でカウンター値を変更した場合にダブルクリック扱いとなってキャラクターが画面中央にならないように改良。名前をダブルクリックすると画面中央に表示されます。<br>
・リソース変更画面のタイトルを修正。くまかばさん指摘ありがとうっ！<br>
<br>
2014/04/15 Ver.1.44.01<br>
・ログ保存画面のデフォルト文字が正しく表示されない不具合を修正。<br>
・プレイルームの作成／変更時にウィンドウ関連のメニューの表示／非表示設定が出来なくなっていた不具合を修正。くまかばさん指摘ありがとうっ！<br>
・ダイスシンボルで0の出目を6面体だけに限定（ダイスプロットは現状6面でしか使わないので）。黒D6にも0を追加。<br>
・ダイスボットをボーンズ＆カーズVer2.02.13対応へ変更。<br>
　・ログホライズンTRPGを仮対応。ハスキーさんありがとうっ！<br>
<br>
2014/04/11 Ver.1.44.00<br>
・Ver.1.43.20をベースに安定版を「No pain, No game」としてリリース。<br>
・読み上げ機能の、talkProxy.php に一部固有名詞を追加。<br>
<br>
2014/04/11 Ver.1.43.20<br>
・ダイスボットをボーンズ＆カーズVer2.02.12対応へ変更。<br>
　・艦これRPGの機能を拡張。みやさんありがとうっ！<br>
・読み上げ機能を改良し、talkProxy.phpで固有名詞の拡張ができるように改良。くまかばさんありがとうっ！<br>
・画像の外部URL許可を src_ruby/config.rb の $canUseExternalImageModeOn で設定できるように改良。<br>
　falseに設定すると部屋の設定が出来なくなり、常に外部URL無効となります。<br>
・ダイスシンボルのD6での0プロットを全てのゲームで設置可能に。ダイスプロットで速度０が今後出た時様に汎用にしておきました。<br>
<br>
2014/04/07 Ver.1.43.19.01<br>
・一部エラーメッセージの出力不具合を修正。日隠さん指摘ありがとうっ！<br>
<br>
2014/04/06 Ver.1.43.19<br>
・「資源管理画面」の名前を「リソース」に変更。<br>
・リソース画面の変更や順番のソートをできるように改良。<br>
・メッセージカード更新時に変更したとチャットに表示するように改良。<br>
・アップロードファイルの拡張子が大文字だとエラーとなる不具合を修正。ヴィアスさん指摘ありがとうっ！！<br>
・メッセージカードや魔法範囲などをマップの右クリックから配置する場合に座標が右下にズレてしまう不具合に対応。あおりんごさん指摘ありがとうっ！<br>
・シークレットダイス表記や一部エラーの多言語化対応。日隠さん指摘ありがとうっ！<br>
・FlexSDKへのリンクを修正。らぁさん指摘ありがとうっ！<br>
<br>
2014/03/31 Ver.1.43.18<br>
・メッセージカードで3行以上のメッセージが編集できない不具合を修正。みやさん今野博臣さん指摘ありがとぅっ！<br>
・ログイン／ログアウトを繰り返すとウィンドウ情報などが初期化されてしまう不具合を修正。みやさん指摘ありがとうっ！<br>
<br>
2014/03/26 Ver.1.43.17<br>
・メッセージカードで複数行のテキストを書くと編集画面でタグが見えてしまう問題を修正。今野博臣さん指摘ありがとうっ！<br>
・ダイスボット表追加機能で表が追加できなくなっていた不具合を修正。今野博臣さん指摘ありがとうっ！<br>
・文字に色を付けていない人の色が、見ている人の文字色に引きずられてしまう不具合を修正。ハスキーさん指摘ありがとうっ！<br>
<br>
2014/03/23 Ver.1.43.16<br>
・ダイスボットをボーンズ＆カーズVer2.02.10対応へ変更。<br>
　・艦これRPGに対応。<br>
　・エンドブレイカーをダイス目の数を出すように改良。ハスキーさんありがとうっ！<br>
・表示メニューのウィンドウ関連を「ウィンドウ」サブメニューに移動。<br>
・共有資源管理表に「資源管理」ウィンドウを追加。表示->ウィンドウ->資源管理表示、で表示できます。カナヤゴさん提案ありがとうっ！<br>
・カードを「自分にだけ公開」の状態から「非公開」に遷移できるように変更。<br>
・メッセージカードを公開したときに、メッセージ内容をログに出力するように変更。<br>
・ダイスボットを自前で追加／変更する時の createDiceInfos.rb コマンドの実行を不要に。<br>
　代わりに手順が変更になっているので <a href="#aboutDiceBot">README</a>を確認してください。<br>
・マルチ言語対応での不具合に対応。日隠さんありがとうっ！<br>
<br>
2014/03/21 Ver.1.43.15<br>
・ダイスボットをボーンズ＆カーズVer2.02.09対応へ変更。<br>
　・マギカロギアの事件表の記述ミスを修正。九鳥さん指摘ありがとうっ！<br>
・チャットの日時表示チェックを入れても反映されない不具合を修正。薄雪さん指摘ありがとうっ！<br>
・立ち絵にエフェクトを付けて発言するとエラーが発生する不具合を修正。薄雪さん指摘ありがとうっ！<br>
・メッセージカードを変更できるように、メッセージカードの右クリックメニューに「カードの変更」を追加。<br>
<br>
2014/03/16 Ver.1.43.14<br>
・チャットログ保存時の設定を記憶するように改良。<br>
・チャットログ保存画面で保存ボタンを押しても画面が閉じないように改良。<br>
・チャットのフォントサイズデフォルトを変更（少し大きく）。<br>
・チャットのフォントサイズと時刻表示有無を変更した場合、その変更が部屋だけでなくどどんとふ全体で保持されるように変更。（この２つの変更は全部屋共通の方が便利だという観点から）<br>
・チャットのフォントサイズ変更時にメイン以外のタブのログでフォントサイズが変更されない不具合を修正。飯綱さん指摘ありがとうっ！<br>
・コマ画像からの立ち絵の表示座標が常に左端になってしまう不具合を修正。飯綱さん指摘ありがとうっ！<br>
・フォント拡大時にダイスシンボルが置けない不具合を解消。メタボルタさん指摘ありがとうっ！<br>
・キャラクター選択状態からドラッグでキャラクターがコピーできる機能を削除。キャラクターのコピーは右クリックメニューからのみとなります。<br>
・立ち絵編集画面／カットイン編集画面で並び順をドラッグ操作で入れ替える際に複数選択できるように改良。<br>
<br>
2014/03/08 Ver.1.43.13<br>
・インセインの狂気カードでフォントサイズの間違いを修正<br>
・トーキョーN◎VAのカードを改良。クロガネを追加。arhmさんありがとうっ！<br>
・ダイスボットをボーンズ＆カーズVer2.02.08対応へ変更。<br>
　・アースドーンのダイスボットで目標値を省略してもロール出来るように改良<br>
<br>
2014/03/06 Ver.1.43.12<br>
・画像アップロード時に「専用」「全体」を選べるようにし、「専用」ならログインしている部屋だけ、「全体」ならサーバ全体で画像が参照できるようになります（従来の動作は「全体」のみでした）。<br>
・画像の一覧表示時に選択タグ以外の画像が読み込まれないように機能軽量化。<br>
・フォントサイズ変更時にイニシアティブ表のその他欄の文字が複数行あると全行表示されてしまう問題を修正。日隠さん指摘ありがとうっ！<br>
<br>
2014/02/25 Ver.1.43.11<br>
・ダイスボットをボーンズ＆カーズVer2.02.07.01対応へ変更。<br>
　・ゴリラTRPGが正しく動かない不具合を修正。<br>
・立ち絵が反転している場合に正しく縮小されない不具合を修正。<br>
・中国語対応を追加。日隠さんありがとうっ！<br>
<br>
2014/02/25 Ver.1.43.10<br>
・チャットのHTML保存時にフォントサイズや行高さを指定できるように改良。ひらなりさんありがとうっ！！<br>
・画面全体のフォントサイズを変更できるように表示メニューに「フォント変更」項目追加。イニシアティブウィンドウのフォント設定もそちらに統合。<br>
・立ち絵がある場合にチャットが上手く動かない問題に対応。今野博臣さんありがとうっ！<br>
・メッセージの中国語対応。日隠さんありがとうっ！<br>
・ダイスボットをボーンズ＆カーズVer2.02.07対応へ変更。<br>
　・ゴリラTRPG(http://www55.atwiki.jp/gorillatrpg/)に対応。くまかばさんありがとうっ！<br>
<br>
2014/02/18 Ver.1.43.09<br>
・ダイスロール文字列のの後ろに”「」”や”、”を書いても ”[]”や”,”に変更しないように改良。熊坂トーマさん指摘ありがとうっ！<br>
・コマ／立ち絵画像を縮小状態でも滑らかに表示されるよう改良。<br>
・立ち絵に歩行などを表現する上下揺らしエフェクトを追加。立ち絵追加／変更画面から設定できます。<br>
・カットイン管理画面に「並べ替え許可」チェックボックスを追加。チェックを入れない限り並び替えはされないのでウッカリ操作の防止に。くまかばさん提案ありがとうっ！<br>
・マップの右クリックメニューに「ウィンドウ配置初期化」を追加。<br>
・チャットのHTMLログ保存時のフォーマットを改良。ひらなりさんありがとうっ！<br>
・WEB IFからのダイスロールでビジュアルダイスが転がるように改良。カヅサツさん提案ありがとうっ！<br>
・初期インストール自のプレイルームNo.0の不具合を修正。大ちゃ指摘ありがとうっ！<br>
・バージョン表記をconfig.rbからDodontoF.rbに移動（使用上は特に影響なし）<br>
・不要なファイルを削除。その他ソースコード整理。<br>
<br>
2014/02/13 Ver.1.43.08<br>
・ダイスボットをボーンズ＆カーズVer2.02.06対応へ変更。<br>
　・ダイスボットのビーストバインド トリニティーを大幅変更。倉坂悠さんありがとうっ<br>
　・キルデスビジネスにサブプロット追加。今野博臣さんありがとうっ<br>
<br>
2014/02/08 Ver.1.43.07<br>
・Ruby1.9でもMessagePack処理がエラーなく行えるようにライブラリ追加。<br>
・MessagePackのgem installが不足している場合のエラー表示処理を追加。<br>
・チャットパレットの ｛値｝ 形式の記述にイニシアティブ表のカウンター値が使えるように改良。チャットパレットの「名前」を元に適用するカウンター値を決定。名前が空ならチャット欄の名前を元に決めます。<br>
・ダイスボット表追加機能で表を追加するとエラーが出ていた不具合を修正。<br>
<br>
2014/02/05 Ver.1.43.06<br>
・カウンターリモコンでもビジュアルダイスがロールされるように機能拡張。<br>
・カウンターリモコンでD66が使えるように改良。<br>
　D66の出目が[6,3]の場合に「36」のように昇順にD66を扱いたい場合には 「D66S」とD66の後ろにSを加えてください。 <br>
・カード操作ログ表示のチェックを外しても常にログが出力されてしまう不具合を修正。<br>
・Ruby1.9に対応できるよう一部修正。READMEのコメント追記。<br>
<br>
2014/01/30 Ver.1.43.05<br>
・キャラクターをCtrlキーを押しながら選択した状態でチャットを送ると、名前がチャットの末尾に「＞名前」の様に羅列されるように機能拡張。<br>
・ダイスボットをボーンズ＆カーズVer2.02.05対応へ変更。<br>
　・エンドブレイカーのコードを修正（機能に変更なし）（くまかばさんありがとうっ！）<br>
　・ハンターズムーンの説明文の誤記修正。（今野博臣さんありがとうっ！）<br>
　・ブラッド・クルセイドに時間経過表（10代～60代、反吸血鬼）TD1T～TD6T、TDHT を追加。（今野博臣さんありがとうっ！）<br>
<br>
2014/01/22 Ver.1.43.04<br>
・ダイスボットをボーンズ＆カーズVer2.02.04対応へ変更。<br>
　・エンドブレイカーを追加。（ハスキーさんありがとうっ！）<br>
　・ウタカゼを追加。（くまかばさんありがとうっ！）<br>
・ダイスボットの表追加が失敗する問題を修正。（今野博臣さんありがとうっ！）<br>
・ログファイルをパス指摘できるように src_ruby/config.rb に $logFileName/$logFileMaxSize/$logFileMaxCount を追加。<br>
・イニシアティブ表のカウンター名で一部中国語が文字化けする問題に対応。（日隠さんありがとうっ！）<br>
<br>
2014/01/11 Ver.1.43.03<br>
・ダイスボットをボーンズ＆カーズVer2.02.03対応へ変更。<br>
　・ブラッドムーンを仮追加。（今野博臣さんありがとうっ！）<br>
　・ブラッドクルセイドに表を追加。（今野博臣さんありがとうっ！）<br>
　　戦場シーン表 BDST／夢シーン表 DMST／田舎シーン表 CYST／学校シーン表 SLST／館シーン表 MNST<br>
<br>
2014/01/10 Ver.1.43.02.01<br>
・ダイスボットをボーンズ＆カーズVer2.02.02.01対応へ変更。<br>
　・シノビガミの表追加を削除。<br>
<br>
2014/01/10 Ver.1.43.02<br>
・ダイスボットをボーンズ＆カーズVer2.02.02対応へ変更。<br>
　・ダイスボットで「3D6/2」のように出目の割り算に対応。<br>
　　/nでn割り切り捨て、/nUとUをつけると切り上げ、/nRとRつけると四捨五入。（永関さんありがとうっ！）<br>
　・インセインに表追加。（能代銀華さんありがとうっ！）<br>
会話ホラースケープ表(CHT)／街中ホラースケープ表(VHT)／不意訪問ホラースケープ表(IHT)／廃墟遭遇ホラースケープ表(RHT)／野外遭遇ホラースケープ表(MHT)／情報潜在ホラースケープ表(LHT)<br>
　・シノビガミに表追加。（能代銀華さんありがとうっ！）<br>
　　一夏のシーン表　IST/セクシーシーン表 EST／ラッキースケベシーン表 RST/屈服表 XST<br>
　・Ｔ＆Ｔダイスボットの経験値計算を修正（くまかばさんありがとうっ！）<br>
・Ruby1.9でうまく動かない問題を修正（らぁさんありがとうっ！）<br>
<br>
<br>
2013/12/26 Ver.1.43.01<br>
・ダイスボットをボーンズ＆カーズVer2.02.01対応へ変更。<br>
　・ダイスボットにビーストバインド トリニティーを追加。倉坂悠さんありがとうっ！<br>
　・Cコマンドで 「C(10+1) 足し算」 の様にメッセージを追加すると計算が実行できない不具合を修正。リネノンさん指摘ありがとうっ！<br>
<br>
2013/12/24 Ver.1.43.00<br>
・Ver.1.42.18をベースに安定版を開発コード「Timeless time」としてリリース。<br>
<br>
2013/12/24 Ver.1.42.18<br>
・ハンターズムーンに代償表、異形化表追加。<br>
<br>
2013/12/22 Ver.1.42.17<br>
・アラーム音が鳴らない不具合を修正。今野博臣さんありがとう！<br>
・カットイン編集画面で一覧をヘッダーからソートすると選択したカットインが正しく選ばれない不具合を修正。リネノンさん指摘ありがとう！<br>
・ユーザー名のデフォルトがマルチ言語対応していない不具合を修正。日隠さん指摘ありがとう！<br>
<br>
2013/12/16 Ver.1.42.16<br>
・ダイスボットをボーンズ＆カーズVer2.01.61対応へ変更。<br>
　・ハンターズムーンの表を12個追加。今野博臣さんありがとう！<br>
・ログイン画面で言語を変更すると、部屋状態も正しく更新されるように機能改良。<br>
<br>
2013/12/14 Ver.1.42.15<br>
・ダイスボットをボーンズ＆カーズVer2.01.60対応へ変更。<br>
　・キルデスビジネスに蘇生副作用表と一週間表を追加。能代銀華さんありがとう！<br>
　・ピーカブーに日中ブラブラ表を追加。こちらも能代銀華さんありがとう！<br>
・マルチ言語化の不具合修正。<br>
　・ログイン画面にゲーム名が正しく表示されない問題を修正。能代銀華さん指摘ありがとう！<br>
　・日本語以外で見学者ログインしたときに、チャットで名前の後ろに改行がついてしまう問題を修正。日隠さん指摘ありがとう！<br>
<br>
2013/12/12 Ver.1.42.14<br>
・マルチ言語化対応を完全化。これで全画面が完全に多言語対応に。<br>
・対応言語に中国語を追加。日隠さんありがとうっっっ！！！<br>
・ダイスボットをボーンズ＆カーズVer2.01.59対応へ変更。<br>
　・央華封神ダイスボットコマンド出力を一部改良。あずさんありがとう！<br>
　・パラサイトブラッドのコマンドを整理。あるたさんありがとう！<br>
　・ダブルクロスの説明分文字化けを修正。今野さんありがとう！<br>
<br>
2013/11/30 Ver.1.42.13<br>
・ログイン画面から言語を選択できるように機能追加。<br>
　　src_ruby/config.rb の $isMultilingualizationから抑止可能。<br>
　languages ディレクトリにファイルを置くと任意に追加もできます。<br>
・フロアタイル変更モードでタイルが動かせない不具合を修正。ハルキさん指摘ありがとうっ！<br>
<br>
2013/11/28 Ver.1.42.12<br>
・ダイスボットをボーンズ＆カーズVer2.01.58対応へ変更。<br>
　・ダイスボットにガープスフィルトウィズを追加。ハスキーさんありがとうっ！<br>
　・ハンターズムーンに異形アビリティ表２コマンド(SA2T)を追加。今野博臣さんありがとうっ！<br>
　・サタスペのNPCTコマンドの出力を改善。<br>
　・カードランカーのSDTコマンドをGDTに変更。<br>
・点呼／投票機能で表示するウィンドウを目立つように変更。<br>
・カウンターリモコンで自PCの名前が2回表示されてしまう問題を修正。<br>
・TORGのドラマデッキに英語版追加。日本語版の誤字修正。<br>
・ダイスボットの自作表でのダイスロール結果表示を「1D6（=>3）」の様に矢印記号を変更。<br>
・ダイスボット表追加機能でのコマンド追加時に、他の表と名前が重複していると正しくコマンドが実行できない不具合を修正。<br>
<br>
2013/11/11 Ver.1.42.11<br>
・ダイスボットをボーンズ＆カーズVer2.01.57対応へ変更。<br>
　・ダイスボットに央華封神RPG 第三版追加。あずさんありがとうっ！<br>
　・キルデスビジネスのエキストラ表を追加。ハスキーさんありがとうっ！<br>
・ダイスボットの自作表での結果文字列に「1D6」のようなダイス表記があった場合は、
　「1D6（→3）」の用にダイスロールした結果が表示されるように改良。<br>
　また表のロール結果表示を「＊＊表(6[1,5])」の用にダイス目が表示されるように改良<br>
・全データロード時に自作したダイスボットの表データが読み込まれるように修正。<br>
<br>
2013/11/04 Ver.1.42.10<br>
・ダイスボットをボーンズ＆カーズVer2.01.56対応へ変更。<br>
　・一部ダイスボットでダイスコマンドの後ろにメッセージを書いた場合にロールが実行されなくなっていた問題に対応。<br>
　・ダイス種別の過不足を修正<br>
<br>
2013/10/26 Ver.1.42.09<br>
・ダイスボットをボーンズ＆カーズVer2.01.55対応へ変更。<br>
　・サタスペのロールコマンドに必殺発動でロールを止める S オプションを追加。ハスキーさんありがとう！<br>
<br>
2013/10/22 Ver.1.42.08<br>
・ダイスボットをボーンズ＆カーズVer2.01.54対応へ変更。<br>
　・Uコマンドで 1U6 のようにダイス数１の場合に合計が計算されない問題を修正。牧山さん指摘ありがとう！<br>
・カットインを複数立ち上げた場合に正しくカットインが終了しない問題を修正。<br>
・カットインと立ち絵の管理画面で順番入れ替えを可能に（ただし順番は全員で共有となります）。<br>
・隠し画像のパスワードを保持するように機能改善。林直孝さん上記3点全て指摘ありがとう！<br>
・config.rb の $isMentenanceNow を true にしてもログイン中メンバーが強制遮断されない不具合を修正。くまかばさんありがとうっ！<br>
<br>
2013/10/02 Ver.1.42.07<br>
・ダイスボットのソースコードをリファクタリング。<br>
・<a href="#aboutDiceBot">ダイスボットの実装について</a>にダイスボットのテスト方法について追記。<br>
<br>
2013/09/29 Ver.1.42.06<br>
・ダイスボットをボーンズ＆カーズVer2.01.53対応へ変更。<br>
　・キルデスビジネスのダイスボットにファンブル判定も含めた判定用コマンド（JD）を追加。<br>
　　ヘルスタイリスト罵倒表に前後の修飾語句を追加。神武来さんありがとうっ！<br>
　　一部文字化けを修正。くまかばさんありがとうっ！<br>
　・サタスペのダイスボットを大量更新。<br>
　　性業値コマンド追加。<br>
　　判定コマンドに必殺値追加。<br>
　　情報イベント／ハプニング表に値補正追加。<br>
　　臭い飯表、バッドトリップ表、報酬表追加。<br>
　　神武来さんありがとうっ！<br>
　・ダイスボットにRecord of Steamを追加。らぁさんありがとうっ！<br>
<br>
2013/09/22 Ver.1.42.05<br>
・ダイスボットをボーンズ＆カーズVer2.01.52対応へ変更。<br>
　・キルデスビジネスに指定特技ランダム決定表 (SKLT)を追加。ハスキーさんありがとうっ！<br>
　・キルデスビジネスのコマンド名を一部変更。能代銀華さんありがとうっ！<br>
　・ダイスボットに神我狩追加。能代銀華さんありがとうっ！<br>
・CGI対象サーバからロリポップを削除。今後は非推奨とします。<br>
<br>
2013/09/14 Ver.1.42.04.01<br>
・キルデスビジネスの解説テキストを修正。<br>
・ダイスボット一覧表にキルデスビジネスが抜けていたため修正。<br>
<br>
2013/09/13 Ver.1.42.04<br>
・ダイスボットをボーンズ＆カーズVer2.01.51対応へ変更。<br>
　・キルデスビジネスのダイスボット追加。ハスキーさん、犬のようなものさん、ありがとうっ！<br>
・カードにインセインの狂気カード追加。みやさんありがとうっ！<br>
・カード初期化画面の順序を五十音順に。（未訳ゲームは下に）<br>
・カード置き場が表示出来なくなっていた問題を修正。まどみさん指摘ありがとうっ！<br>
<br>
2013/09/12 Ver.1.42.03<br>
・ダイスボットをボーンズ＆カーズVer2.01.50対応へ変更。<br>
　・インセインのダイスボット追加。犬のようなものさんありがとうっ！<br>
・ダイスボット用表追加機能で、コマンド名が小文字の場合も正しく動くように修正。仕様として、コマンド名で大文字と小文字は区別されないこととなります。<br>
<br>
2013/09/08 Ver.1.42.02<br>
・WEB IFのaddCharacterに以下のパラメータを追加。<br>
　url：キャラクターデータの参照先URLの指定。省略可<br>
・WEB IFに以下のコマンドを追加。詳細は本マニュアルの記述参照<br>
　getLoginInfo<br>
　getLoginUserInfo</h3>
・カードのドロー、オープン時にログを表示するように機能追加。<br>
・カード操作関連のログの表示／非表示を選択出来るように、メインメニューの「カード」→「カード操作ログ」にチェック欄を追加。（部屋設定から部屋のデフォルト設定も変更できます）<br>
・カットイン機能が無効の場合にダイスボットコマンドでのビジュアルダイス表示やエリュシオンのDATEコマンドが正しく動かなかった問題を修正。すたっどさん指摘ありがとうっ！<br>
<br>
2013/08/18 Ver.1.42.01<br>
・ダイスボットをボーンズ＆カーズVer2.01.49対応へ変更。<br>
・GURPSでダイス目が17の場合に自動失敗するように修正。<br>
・シノビガミでRTTコマンドが無効になっていた不具合を修正。<br>
・トランプに１×１サイズの縮小カードを追加。カード初期化画面で「１×１サイズ」にチェック入れてみてください。<br>
<br>
2013/06/22 Ver.1.42.00<br>
・Ver.1.41.17をベースに安定版を開発コード「SMILEY」としてリリース。<br>
<br>
2013/06/22 Ver.1.41.17<br>
・デフォルト添付の画像データを修正。<br>
・更新時のFlash読み込み失敗時のエラーメッセージを改良。<br>
<br>
2013/06/19 Ver.1.41.16<br>
・キャラクター待合室で、一覧の途中への挿入や一覧の入れ替えが出来るように機能改良。<br>
<br>
2013/06/15 Ver.1.41.15<br>
・どどんとふ標準添付の画像詰め合わせを削減（ダウンロードサイズ削減のため）。<br>
　<u><a href="http://www.dodontof.com/index.php?option=com_content&view=article&id=246&Itemid=126#DodontoF_images">既存の画像は別途ここから入手できます</a></u>ので、画像アップロードしてご利用ください。<br>
・ダイスボットをボーンズ＆カーズVer2.01.48対応へ変更。ハーンマスターのコマンドを変更。鈴木康次郎さん指摘ありがとうっ！<br>
<br>
2013/06/14 Ver.1.41.14<br>
・カウンターリモコンで値を空文字で指定すると、ボタンを押したときに任意の値を選択可能に機能拡張。<br>
・カウンターリモコンのボタン右クリックで複製、左右移動が出来るように機能拡張<br>
・画面キャプチャ機能を追加。画面上部のカメラアイコンをクリックで実行。残念ながら現状チャットなどのウィンドウは対象外で盤面のキャプチャ専用です。<br>
<br>
2013/06/11 Ver.1.41.13<br>
・ダイスボットをボーンズ＆カーズVer2.01.47対応へ変更。<br>
・ダイスボットにハーンマスターを追加。<br>
・ダイスボットの記述をリファクタリング。<br>
<br>
2013/06/08 Ver.1.41.12<br>
・カウンターリモコンにセーブ・ロード機能を追加。<br>
・カウンターリモコンのキャラクター名マウスオーバー時にコマとイニシアティブ項目を光らせるように機能改良。<br>
・カウンターリモコン変更画面に出力サンプルを追加。<br>
<br>
2013/06/05 Ver.1.41.11<br>
・D66ダイスでも四則演算ができるようダイスボット機能拡張。使用時は必ず「1D6+1D66」のようにD66の前に個数を明記してください。<br>
・外部URLイメージ使用時に、キャラクター待合室にドラッグできない問題を修正。カヅサツさん指摘ありがとうっ！<br>
・外部URLイメージ使用時に、Ctrlキー＋クリックで選択状態にならない問題を修正。<br>
・WEBIFでエラーが発生する問題に対応。くまかばさんマジありがとうございます！<br>
<br>
2013/06/02 Ver.1.41.10<br>
・ダイスボットの表追加機能で「\n」と書くと改行が表示されるように機能追加。<br>
・チャットで「3d6 台詞（改行）台詞」のようにの改行含むメッセージを書くと改行以降が無視されてしまう問題を修正。<br>
・黒D6のダイスシンボルをダブルクリックしたときに黒D6が表示されるように修正。<br>
<br>
2013/06/01 Ver.1.41.09<br>
・Fiasco用に6面ダイスに黒バージョンを追加。いヴさんArleさんありがとうっ！<br>
・ダイスシンボルはゲーム種別を「エリュシオン」に変えた場合は出目０を指定できるが、既に設置済みのダイスシンボルではこの指定変更が行われない不具合を修正。<br>
・見学者でもビジュアルダイスを使うと見学タブ以外のタブでダイスロールできてしまう障害を修正。くまかばさんありがとうっ！<br>
・独自ダイスボットへの変更が部屋情報の変更画面には反映されない不具合を修正。<br>
<br>
2013/05/31 Ver.1.41.08<br>
・チャットパレットで「\n」と書くと改行が表示されるように機能追加。<br>
・部屋作成／変更時のゲーム指定で任意のタイトルが入力できなかった問題を修正。カヅサツさんありがとうっ！<br>
・インストール後の正常性確認処理にディレクトリチェックを追加。くまかばさんありがとうっ！<br>
・一部カードの文字コードがShift-JISだったのをUTF-8 に修正。<br>
・全データセーブを行うとログにエラーが発生する問題を修正。<br>
<br>
2013/05/21 Ver.1.41.07<br>
・ダイスボットをボーンズ＆カーズVer2.01.44対応へ変更。<br>
・エリュシオンでのELコマンドでの判定で、ゾロ目の場合にベース能力値が計算式に表示されない障害を修正。青林檎さん、くまかばさんありがとうっ！<br>
・ガープスのダイスボットに恐怖表／反応判定表を追加。ハスキーさんありがとうっ！<br>
<br>
2013/05/06 Ver.1.41.06<br>
・ダイスボットをボーンズ＆カーズVer2.01.43対応へ変更。<br>
　ガープスに対応。ハスキーさんありがとうっ！<br>
・全データセーブ／ロード時にチャットパレットの読み込みが正しく実行されない問題を修正<br>
<br>
2013/04/29 Ver.1.41.05.01<br>
・ダイスボットで全角の「＃」が半角に自動変換されていなかったので修正。くまかばさん指摘ありがとうっ！<br>
<br>
2013/04/29 Ver.1.41.05<br>
・ダイスボットをボーンズ＆カーズVer2.01.42対応へ変更。<br>
　ゲイシャ・ガール・ウィズ・カタナを追加。らぁさんありがとうっ！<br>
　あとたいたい竹流さんもお疲れ（自画自賛）<br>
　どんなルールか知りたい人は http://www.game-writer.com/konogoro/trpg/ggwk/ を参照ください。<br>
<br>
2013/04/11 Ver.1.41.04<br>
・メタリックガーディアン用の「攻撃範囲」を追加。「コマ」->「範囲」->「攻撃範囲」で設置できます。回転マーカーか右クリックメニューで左右に回転。<br>
・メニューの魔法範囲／攻撃範囲追加を「範囲追加」として集約。<br>
・タグ編集画面、画像削除画面で動画が選択できなかった問題を修正。カヅサツさん指摘ありがとうございます！<br>
・ログアウト時に飛ぶ先を src_ruby/config.rb の $logoutUrl で指定できるように。カヅサツさん提案ありがとうございます！<br>
<br>
2013/03/29 Ver.1.41.03<br>
・カードにPathfinderのHarrow Deckを追加。位坂さんありがとうっ！！<br>
<br>
2013/03/24 Ver.1.41.02.02<br>
・config_local.rbの差し替えで $SAVE_DATA_DIR の差し替えが失敗する問題を修正。
  → この修正が上手くできていなかったので再度修正。<br>
<br>
2013/03/19 Ver.1.41.02.01<br>
・config_local.rbの差し替えで $SAVE_DATA_DIR の差し替えが失敗する問題を修正。<br>
<br>
2013/03/17 Ver.1.41.02<br>
・バージョンアップ手順を更新。 config.rb の書き換え手順が楽に。詳しくは「バージョンアップ方法」参照。Anonymousさん提案ありがとうございます！<br>
・ダイスボットをボーンズ＆カーズVer2.01.40対応へ変更。<br>
　・Rコマンドの不具合修正。くまかばさん指摘ありがとうっ！<br>
・ソースコードの整理（機能的には変更無し）<br>
<br>
2013/03/09 Ver.1.41.01<br>
・カードランカーで「RM」コマンド実行時にカードが出現するように機能追加。<br>
　カード画像は cards/cardRanker にあるものを差し替えることで任意に変更可能です。<br>
・ダイスボットをボーンズ＆カーズVer2.01.39対応へ変更。<br>
　・エリュシオンにNPCランダム表を追加。<br>
<br>
2013/03/05 Ver.1.41.00.01<br>
・エリュシオンのD66判定が数値入れ替えになっていなかったため修正。<br>
<br>
2013/03/04 Ver.1.41.00<br>
・Ver.1.40.12をベースに安定版を開発コード「ENERGY」としてリリース。<br>
<br>
2013/02/28 Ver.1.40.12<br>
・エリュシオンダイスボットを修正。D66に対応。くまかばさん超ありがとうございます！！<br>
<br>
2013/02/24 Ver.1.40.11<br>
・ダイスボットをボーンズ＆カーズVer2.01.37対応へ変更。<br>
　・エリュシオンに各種表を追加。<br>
　・サタスペダイスボットの恋愛ハプニング表の誤記を修正。<br>
　・アルスマギカでArs3+1のようにボーナスをつけると正しく動かない不具合を修正。<br>
<br>
2013/02/19 Ver.1.40.10<br>
・デモンパラサイトのダイスボットで文字化けしていた問題に対応。らぁさんありがとうっ！<br>
<br>
2013/02/16 Ver.1.40.09.02<br>
・エリュシオンのコマンドに以下を追加。<br>
　date[PC名,PC名２]：この書式で記述すると一回の書き込みでデート表を振ることができます。<br>
<br>
2013/02/15 Ver.1.40.09.01<br>
・エリュシオンでD6のダイスシンボルを出目０で設定できるように改良。<br>
<br>
2013/02/14 Ver.1.40.09<br>
・ダイスボットをボーンズ＆カーズVer2.01.36対応へ変更。<br>
　・ダイスボットにエリュシオンを追加。
・簡易マップ編集での塗りつぶしがマップマス目の交互表示で正しく塗られない問題を修正。<br>
・読み上げ機能をチャンネルごとに有効／無効に<br>
・マップへの書き込み量の上限を src_ruby/config.rb の $drawLineCountLimit で指定可能に機能拡張。<br>
　上限に達すると書き込みできなくなります。<br>
・リプレイ再生時にログイン画面に戻れるよう右上にボタン追加。<br>
<br>
2013/01/23 Ver.1.40.08<br>
・ゲヘナアナスタシスのダイスボットで、プラス修正をつけた場合に失敗数が正しくカウントされない問題を修正。今野博臣さんありがとうっ！<br>
<br>
2013/01/06 Ver.1.40.07<br>
・こまの回転マーカーを抑止可能に。メニューの「コマ」->「回転マーカーを表示する」で変更可能。<br>
・キャラクターコマのダブルクリックによる「画像切替設定」の変更が、他のプレイヤーには反映されない不具合を修正。くまかばさん指摘ありがとうっ！<br>
<br>
2013/01/05 Ver.1.40.06<br>
・WEB IFのchatとrefreshコマンドをで秘話が見えてしまう問題に対応。木耳空旭さん指摘ありがとうっ！<br>
<br>
2013/01/05 Ver.1.40.05<br>
・キャラクター作製／変更画面に「画像切替設定」ボタンを追加。キャラクターのコマ画像の差し替えが可能に。マップ上のキャラクターのコマをダブルクリックすることで画像の切替が可能<br>
・カードの全削除用項目をメニューの「カード」->「カード配置の初期化」に追加。<br>
・TORGドラマデッキの修正（No.160以降のカードの修正、サイドストーリーカードの着色、段階的行動の配置調整等）<br>
・TORGのボーナス表が20,25,30と区切り目の値で値が誤っていたのを修正。<br>
・ダイスシンボルをオープンした時にチャットに出目を表示するように機能追加。<br>
・ダイスボットをボーンズ＆カーズVer2.01.33.02対応へ変更。<br>
　バトルテックの命中判定を１発ごと１行ずつ表示に。<br>
　　部位の命中回数を表示に。<br>
　　合計ダメージも表示に。<br>
　ゲヘナアナスタシスのダイスボットを修正。nGtコマンドで連撃増加値と闘技チットが抑止されていないのを修正。<br>
　　成功度と失敗度を表示するように改善。<br>
・WEB IFにrefreshコマンドを追加。詳しくはマニュアル参照。<br>
<br>
2012/12/27 Ver.1.40.04.01<br>
・ダイスボットをボーンズ＆カーズVer2.01.33.01対応へ変更。<br>
　バトルテックダイスボットのSRMとLRMの判定誤りを修正。<br>
<br>
2012/12/27 Ver.1.40.04<br>
・ダイスボットをボーンズ＆カーズVer2.01.33対応へ変更。<br>
　ダイスボットにバトルテックを追加。<br>
　@Gunzo777さん@anony403さんありがとうっ！<br>
<br>
2012/12/18 Ver.1.40.03<br>
・カードにItras Byのチャンスカードと解決カードを追加。<br>
・src_ruby/config.rb の $skinImage が無効になっていたのを有効に。<br>
<br>
2012/12/08 Ver.1.40.02<br>
・魔法範囲変更画面のタイトル／ボタン名の修正<br>
・カットインの画像にYoutube URLを指定していて外部URLが有効でない場合にエラーを表示するように機能改善。<br>
<br>
2012/12/02 Ver.1.40.01<br>
・パスワードの掛かったプレイルームを削除する際にパスワード入力を促すように機能変更。<br>
　src_ruby/config.rb の isPasswordNeedFroDeletePlayRoom を false に変更することでパスワード無しでも削除できるように変更できます。<br>
・MySQLのDBクローズを改善。くまかばさん情報ありがとうっ！<br>
<br>
2012/11/18 Ver.1.40.00.03<br>
・読み上げ機能が動作しなかった不具合を修正。ほぎーさん指摘ありがとうっ！<br>
<br>
2012/11/17 Ver.1.40.00.02<br>
・マギカロギアのダイスボット追加が正しく動いていなかった問題に対応。<br>
・WEB IFのtalkで改行文字送信時に改行が2行になって見える問題を修正。<br>
・読み上げ機能のセキュリティー強化<br>
<br>
2012/11/07 Ver.1.40.00.01<br>
・README.htmlのレンタルサーバのCGIについての記述を修正。エックスサーバーとエクストリムサーバーもOK出ました。（くるみさん、ほいさっささんありがとうっ！）<br>
・ついでにfaviconも変更。<br>
<br>
2012/11/06 Ver.1.40.00<br>
・Ver.1.39.12.01をベースに安定版を開発コード「manamoon」としてリリース。<br>
・README.htmlのレンタルサーバのロリポップについての記述を修正。（如月 翔也さんありがとうっ！）<br>
<br>
2012/11/04 Ver.1.39.12.01<br>
・README.htmlのレンタルサーバのCGIについての記述を修正。<br>
・ダイスボットをボーンズ＆カーズVer2.01.32.01対応へ変更。<br>
　マギカロギアダイスボットの判定が一部誤っていたのを修正。<br>
<br>
2012/11/03 Ver.1.39.12<br>
・README.htmlのレンタルサーバのCGIについての記述を修正。c<br>
・ダイスボットをボーンズ＆カーズVer2.01.32対応へ変更。<br>
　マギカロギアに追加ルールブック2巻3巻の表を追加。みけさんありがとうっ！<br>
<br>
2012/10/29 Ver.1.39.11<br>
・さくらインターネットで新規プレイルームの作成／プレイルームの削除に失敗する問題を修正。(くまかばさん指摘ありがとうっ！)<br>
・ウィッチタローのカード名を「ウィッチ・タロー」に修正。<br>
・index.htmlの変更(DodotntoF.swf の代わりに index.html でアクセスしても動作可能に。ページタイトルややファビコンも定義できます。)<br>
・デフォルトのファビコンを更新。<br>
・一部不要ファイルの削除。<br>
<br>
2012/10/27 Ver.1.39.10<br>
・ダイスボット、カードにウィッチクエスト追加。WQn でチャレンジ判定、SETn でストラクチャー遭遇表がのコマンド追加。詳細はツールチップ参照。<br>
・ウィッチクエストのストラクチャーカードの右クリックメニューから遭遇表が振れます。<br>
・リプレイ編集で新規に環境設定を行うとエラーが発生していた不具合に対応。<br>
・キャラクターやカードが複数積まれた上でホイールを回すとマップの拡大縮小でなく展開順序が変わるが、キャラクター1体カード1枚の場合はマップが拡大縮小されるように改善<br>
<br>
2012/10/21 Ver.1.39.09<br>
・リプレイ投稿機能での再生時にダイスのロール速度が遅くなる問題を修正。<br>
・リプレイ編集で、現状の環境設定を引き継いで編集できるように改良。<br>
・リプレイ編集の環境設定で立ち絵の自動サイズ調整をOFFにできるように機能追加。<br>
・カード初期化画面の構成を改善。<br>
<br>
2012/10/13 Ver.1.39.08<br>
・ダイスボットをボーンズ＆カーズVer2.01.30.01対応へ変更。<br>
　・墜落世界の判定が正しく動いていなかった障害を修正。<br>
・WEBIFでPOST送信時に正しく処理できていなかった問題を修正。<br>
・ログイン画面でパスワードの有無表示が逆になっていたのを修正。<br>
・チャットウィンドウから起動できる「ファイルアップローダー」の名前を「簡易ファイルアップローダー」に変更。<br>
・簡易ファイルアップローダーが正常に動作できなかった不具合を修正。<br>
・末尾＠指定での立ち絵差し替えが動作しなかった不具合を修正。<br>
・カットイン編集画面でSWFファイル音声のループ問題が残っていたので修正。<br>
・マップ変更画面のデフォルトのタグを「（未選択）」に変更。<br>
<br>
2012/10/10 Ver.1.39.07<br>
・ダイスボットをボーンズ＆カーズVer2.01.30対応へ変更。<br>
　・ダイスボットに墜落世界を追加。<br>
　・ブラッドクルセイドへ以下を追加。<br>
　　行為判定などのために、ランダムに特技を選ぶ表の追加<br>
　　3巻で追加された狂気ルール用のペナルティアビリティ表の追加<br>
　　スペシャル/ファンブル時の追加文の表現を修正<br>
　　退路幸福表のtypo修正<br>
　・迷宮キングダム アイテムカテゴリ決定表 (#2)の修正。<br>
・ログイン画面の表示を軽量化。<br>
・ユーザー名が「ななしさん」なら設定したしているデフォルト名に差し替えるように機能変更。<br>
・ログイン人数が指定数を超えている場合にはログイン出来ないように src_ruby/config.rb の $limitLoginCount を追加。<br>
・リプレイ編集時の環境設定画面の誤字を修正<br>
・リプレイ録画再生が出来なくなっていた不具合を修正。<br>
・リプレイ再生時にダイスロールで音が鳴らなかった不具合を修正。<br>
・リプレイ再生時にダイスが画面に残り続ける不具合を修正。<br>
・ダイステーブル追加機能が反映されない不具合を修正。ひのたちさん、末尾上記5点指摘ありがとうっ！<br>
<br>
2012/10/05 Ver.1.39.06<br>
・定期更新処理での日時判定処理の修正。（内部時間の保持方法をUNIX積算秒(小数点）のからUNIX積算ミリ秒（整数）に変更）<br>
・立ち絵の画像を左右反転にした場合、チャットの末尾に＠立ち絵 書式で指定すると表示が狂う問題を修正。<br>
・一部データだけのロードが正しく動かなかった問題を修正。<br>
・カットインが削除が出来なかった問題を修正。<br>
・サーバの処理を軽量化（不要なデータ読み込みを削除）<br>
・ファイルアップロード等でSWFファイル読み込んだ場合に音が鳴り続けるのを、鳴らないように改善。<br>
・シノビガミのダイスボットのコマンド記述誤りを修正。（秋空に雪舞えばシーン表　KST→AKST）<br>
・初回ログインジに表示されるデフォルトユーザー名を「ななしさん」固定から src_ruby/config.rb の $defaultUserNames で可変に変更。<br>
<br>
2012/10/01 Ver.1.39.05<br>
・README.htmlを大幅改定<br>
・サーバのインストール手順を追加。りこりすさんありがとうっ！<br>
・キャラクターが削除できない不具合を修正。<br>
・ダイスボット表追加機能が全く動かなくなっていたので修正。<br>
・ダイスボット表追加機能で追加したばかりのダイスボットが他のプレイヤーから見えない不具合を修正。<br>
・立ち絵指定時に、立ち絵を指定していないキャラクターのコマ絵が立ち絵として使われなくなる障害を修正。<br>
・新規部屋作成時にカウンターリモコンを有効に出来ない不具合を修正。<br>
・イニシアティブ表のカウンター最大・最小値を10桁に。<br>
<br>
2012/09/29 Ver.1.39.04<br>
・クライアント->サーバのデータ送信をJONからMessagePackに変更。全体をリファクタリング。<br>
　-> レンタルサーバではなく自前サーバの人は、 src_ruby/config.rb の $isMessagePackInstalled の設定を変えることで高速化が期待できます。<br>
・index.htmlを追加。<br>
<br>
2012/09/25 Ver.1.39.03<br>
・WEB IFにgetBuyInfo、getServerInfo、getRoomList を追加。READMEに記述追加。<br>
・イニシアティブ表の値が10までしか設定できない不具合を解除(99999〜-99999に変更)<br>
<br>
2012/09/25 Ver.1.39.02<br>
・ダイスボットでネクロニカのNC等、数値と共に入力するコマンドが全て無効化されていた障害を修正（一つ前のバージョンのバグでした）<br>
・キャラクターをCtrlで増やした後、カードの山札から任意の抜き出しが出来なくなる障害を修正。<br>
・Alrtキーを押しながらキャラクターを移動／回転することでマス目に沿わない任意の座標／角度にコマを移動／回転できます。（以前のバージョンではCtrlキーだったののが変更になりました）<br>
・イニシアティブ表の最大桁数制限を解除。<br>
・手描きのペン操作のショートカットを変更。
　Altキーでただの直線、Shitキーで45度刻みの直線、Ctrlでマス目の交点が始点／終点となります。<br>
　また、Ctrl+Zでアンドゥ、Ctrl+Yでリドゥも可能になりました。<br>
・アップロード時のタグ名に「モンスター」を追加。<br>
<br>
2012/09/22 Ver.1.39.01<br>
・ダイスボットをボーンズ＆カーズVer2.01.29対応へ変更。<br>
　ダイスボットに真空学園追加。<br>
　迷宮キングダムの表に　捜索後休憩表（ABT）、全体休憩表（WBT）、カップル休憩表（LBT）を追加。@sillygoさんありがとうっ！<br>
　カードランカーのスペシャル時のランダムモンスター選択の表示を変更。
・ダイスボットの並び順を src_ruby/config.rb の $diceBotOrder で変更可能に。<br>
・ダイスボットを任意に増減できるように機能拡張。<br>
　上記と同じく src_ruby/config.rb の $diceBotOrder を削れば削減でき、<br>
　またダイスボットの新規追加の場合には src_bcdice/diceBot ディレクトリにダイスボット用の.rb ファイルを置けばOKです。<br>
<br>
2012/09/14 Ver.1.39.00<br>
・Ver.1.38.11をベースに安定版を開発コード「運命のジョーカー」としてリリース。<br>
<br>
2012/09/13 Ver.1.38.11<br>
・ダイスボットを振ったときに雑談タブにエラーログが表示される問題を修正。<br>
・デフォルトの画像セットにカードランカー用マップ画像を追加。あどあきくん画像提供ありがとぅっ！<br>
<br>
2012/09/12 Ver.1.38.10<br>
・ダイスボットをボーンズ＆カーズVer2.01.28対応へ変更。<br>
　クトゥルフダイスボットに組み合わせ判定の CBR(x,y) を追加。技能レベルxと技能レベルyでの組み合わせ判定をこの書式で実行可能。<br>
・リプレイ編集時にビジュアルダイスの表示／非表示が設定できるように環境設定に項目追加。デフォルトはダイス表示あり。<br>
・シークレットダイス（S1d6など）が振れなくなっていた問題を修正。<br>
　またシークレットダイス確認画面を、複数の結果保存できるように拡張。<br>
・手書き機能を拡張<br>
　ペンの形を表示するように機能拡張<br>
　Shiftキーを押しながらペンを開始すると直線が引けるように、Ctrlキーを押しながらならマス目の交点が始点になる直線が引けるように機能拡張。<br>
　アンドゥ／リドゥのボタンの追加。<br>
・ロード時の選択対象にイニシアティブ表を追加。<br>
<br>
2012/09/07 Ver.1.38.09<br>
・ダイスボットをボーンズ＆カーズVer2.01.27対応へ変更。<br>
・カードランカー対応を追加。<br>
・りゅうたまダイスボットで「R810＋1-2>=10」のように修正値を複数付けられるように改良。<br>
<br>
2012/09/06 Ver.1.38.08.01<br>
・ダイスボットに「3d6+1」や「3d6>=1」のように条件追加するとダイスロールされない障害を修正。<br>
・「(回数)(空白)(ダイスロール文字列)」指定でN回繰り返した場合に区別しやすいように、メッセージの末尾に「#(回数)」と表記を追加。<br>
<br>
2012/09/06 Ver.1.38.08<br>
・複数重なったキャラクターにマウスカーソルを合わせ展開した状態で、マウスホイールを上下すると重なり順序が入れ替わるように機能追加。<br>
・ダイスボットの表追加機能の結果出力で、誤ってダイス目が先頭に出力されていたため修正。<br>
・ダイスロール時に「3 3d6」のように「(回数)(空白)(ダイスロール文字列)」 と書くことで指定回数分ダイスロールを一括で実施します。<br>
・プレイルーム作製時に認証パスワードを要求できるように機能追加。<br>
　src_ruby/config.rb の $createPlayRoomPassword を設定することで、<br>
　認証パスワードが一致しない限り新規プレイルームの作製が出来なくなります。<br>
・システム管理者用の全プレイルームへの一斉発言機能を追加。<br>
　src_ruby/config.rb の $mentenanceModePassword を設定することで、<br>
　DodontoF.swf?mode=admin からのログイン画面表示がメンテナンスモードに変わり、<br>
　「管理用パスワード」に設定したパスワードを入力することで、一斉発言やパスワード部屋へのログインができるようなります。<br>
<br>
2012/09/04 Ver.1.38.07<br>
・マップへの手書き機能を改善。ボタンをアイコン追加したり、描き込み量を可視化したり、ペンと消しゴムでサイズを別管理にしてみたり、消しゴムの後にペン描き込み出来るようにしてみたり。<br>
・ダイスシンボルが12面の場合に20まで値を設定できるようになっていた問題を修正。<br>
<br>
2012/09/01 Ver.1.38.06<br>
・マップへの手書き書き込み機能を追加。画面上部メニューの「共有メモ」右の「手書き」ボタンを押して実行してください。<br>
<br>
2012/08/28 Ver.1.38.05<br>
・ダイスボットをボーンズ＆カーズVer2.01.26対応へ変更。<br>
　ソードワールドのダイスボットを整理（リファクタリング）<br>
　ソードワールドのレーティング表が修正値をつけない場合にダメージ合計を表示しない問題を修正。<br>
　ソードワールド2.0の首切り刀用に r10 でのレートアップ指定を追加。<br>
　ソードワールド2.0のグレイテストフォーチュン用に末尾に gf の指定を追加。<br>
　アリアンロッドのダイスボットが2D6の場合にクリティカル／ファンブルが表示されない問題を修正。<br>
・シークレットダイスの公開時に立ち絵の状態文字が誤って表示される問題を修正。<br>
・ダイスシンボルのD20で11以上の目を指定できるように機能拡張。<br>
<br>
2012/08/24 Ver.1.38.04<br>
・ダイスボットをボーンズ＆カーズVer2.01.25対応へ変更。<br>
　りゅうたまのダイスボットで R810＋1>=10 のように修正を付けられるように改善<br>
　ダイスボットにd2,d20を追加（例：R202）<br>
・キャラクターを右クリックメニューの「キャラクターの複製」から既存キャラクターのコピーができるように機能追加。<br>
　Ctrlキーを押しながらキャラクタードラッグでもコピー可能です。<br>
・デフォルトの画像にシノビガミキャラクターを追加。（嵐堂さんありがとうっ！）<br>
・src_ruby/config.rb の $noPasswordPlayRoomNumbers でのパスワード変更抑止をプレイルーム作成時にも適用するように変更。<br>
<br>
2012/08/08 Ver.1.38.03<br>
・キャラクター情報の管理方法を運用負荷で選択できるように src_ruby/config.rb に $isUseRecord を追加。<br>
　詳細はコメント参照。<br>
・サーバのソースコードをリファクタリング。動作には変更なし。<br>
<br>
2012/08/07 Ver.1.38.02<br>
・キャラクター登録／変更画面の構成を変更。イニシアティブ値をパラメータ一覧に集約とか。<br>
・ダイスボットをボーンズ＆カーズVer2.01.24対応へ変更。<br>
　りゅうたまのダイスロールを例えば「R810」のように「,」区切りも「>=t」の目標値設定も無しでも動くように改良<br>
・魔法範囲をイニシアティブ表に表示する／しないを選択できるように項目追加。<br>
・カットイン追加／変更画面でプレビューが表示できない障害を修正。<br>
・カットインで0.1秒単位での時間指定が出来ない障害を修正。<br>
・チャットパレットの文字表示枠の背景色をチャットウィンドうの背景色と同期するように改善。<br>
・録画エディターでの環境設定でチャットウィンドうの背景色も指摘できるように機能追加。<br>
・イニシアティブ表の文字の並びを左揃えに変更（値変更時に数値が見えるように）<br>
<br>
2012/08/03 Ver.1.38.01<br>
・ダイスボットをボーンズ＆カーズVer2.01.22対応へ変更。りゅうたまに対応<br>
<br>
2012/07/21 Ver.1.38.00<br>
・Ver.1.37.13をベースに安定版を開発コード「救済の技法」としてリリース。<br>
・READMEにWEB IFについての記述を追記。<br>
・READMEの媒体のimageUploadSpace置き場所についての記述を修正。<br>
・プレイルームの最大数のデフォルトを10部屋に抑止<br>
<br>
2012/07/14 Ver.1.37.13<br>
・シークレットダイスで何のダイスを振ったのか見えないように変更。<br>
・ダイスロールとカットインが同時発動できるように修正。<br>
・ダイスシンボルを一度公開してから再度伏せることが出来るように機能改善。<br>
・カットイン変更画面で表示位置が常に「中央」になっていた問題を修正。てんななさんありがとうっ！<br>
・WEB IFのchatにtimeパラメータ追加。time=1339209851.85239 のようにUNIX積算時間を指定することで、その時間移行のチャットログを取得できます。<br>
　timeを指定した場合は、新しいチャットが書き込まれるまで応答を待ちます。<br>
　最初は time=0 を指定し、移行は取得したログからUNIX時間を指定するとKOOLなTOOLが作れると思います。<br>
　結果、現状は以下の通り。(timeの追加以外は変更なし)<br>
 URLで DodontoFServer.rb?webif=chat&room=0&password=himitsu&time=1339209851.85239 のように指定することで指定したデータをJSON形式で取得可能。<br>
　各パラメータの意味は以下の通り<br>
　webif：取得するデータの種別（現状 chat のみサポート）<br>
　room：データを取得するプレイルーム番号<br>
　password：データを取得するプレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　time:UNIX積算時間を指定。指定時間移行のチャットのみを取得します。また新規チャットが書き込まれるまで待機もします（Flashからの定期取得処理と同一の動作）secとtimeがではtimeの指定が優先されます。<br>
　sec：何秒前までのチャットを取得するかの指定。allなら全取得、省略なら180秒（$oldMessageTimeoutで指定）<br>
　marker：基本不要。trueを設定することで、JSONの前後に #D@EM&lt;#(JSON)#&gt;D@EM# とマーカーを付与（CGI広告埋め込み対策）<br>
<br>
2012/07/07 Ver.1.37.12<br>
・秘話機能が正しく動いていなかった問題を修正。超小兎さん指摘ありがとうっ！<br>
・立ち絵画像が消えなくなる場合がある不具合を修正。ひのたちさん指摘ありがとうっ！<br>
<br>
2012/07/05 Ver.1.37.11<br>
・文字読み上げ時に【3D6 命中判定「当たれぇっ」】のように「」でメッセージが存在すると、<br>
　その部分だけを読み上げる（上記の例なら「命中判定」は読み上げされない）ように機能改良。<br>
・ダイスシンボルの画像を新版に差し替え<br>
・ログイン画面からの古いプレイルームの一括削除をサポート。src_ruby/config.rb の $removeOldPlayRoomLimitDays で日数を指定できます。<br>
<br>
2012/07/04 Ver.1.37.10<br>
・ダイスボットからのビジュアルダイスロールの結果吹き出しが、表結果だと横長すぎるのを改行するように改善。<br>
　また、一部表のロールなどで結果の吹き出しが表示されない問題を修正。<br>
・魔法範囲の変更時に自分の環境で変更が反映されない問題を修正。<br>
・ダイスボットでの大量ダイスロール時にエラーメッセージが表示されてしまう問題を修正。<br>
<br>
2012/07/02 Ver.1.37.09<br>
・チャットログ削除機能を追加。チャットウィンドウの左から3番目のアイコンをクリックで実行。<br>
・ビジュアルダイスの画像を一新。いヴさん、Arleさんありがとう！そしてありがとうっっ！！<br>
・ダイスボットのビジュアルダイス連携時の結果表示にエフェクトを追加。<br>
　1D100の10ロール時にダイスが表示されない障害を修正。雉ねこさん指摘ありがとうっ！<br>
・ダイスボットでのシークレットダイス指定時にビジュアルダイス表示される不具合を修正。ひのたちさん指摘ありがとうっ！<br>
・チャットパレットでのチャット送信時に立ち絵が正しく表示されない問題を修正。まどみさん指摘ありがとうっ！<br>
・イニシアティブ表のチェックボックス変更時に自分のコマの状態マーカーが更新されない問題を修正。超小兎さんいつもありがとうっ！<br>
<br>
2012/06/30 Ver.1.37.08<br>
・ダイスボットからのビジュアルダイスロール時にD20が表示されないバグの修正。<br>
　ロール結果をバルーン表示するよう機能追加。<br>
・ビジュアルダイスのD6画像を変更。いヴさん、Arleさんありがとうっ！<br>
・マップマーカーの設定変更後、自分の画面だけ更新されない不具合を修正。<br>
・チャット文字読み上げ時に音声が重複しないように改良。<br>
　ダイスロール時にダイス目／追記／結果のみを読み上げるように改良。<br>
・ダイスロール時に転がす音が鳴るように機能改良（前回の記載漏れ）。イザークさんありがとう！<br>
<br>
2012/06/27 Ver.1.37.07<br>
・イニシアティブ表のカラム幅が2回ログインするとデフォルトに戻ってしまう不具合を修正。<br>
・コマンド入力でのダイスロール時にビジュアルダイスが転がるように機能追加。<br>
　-> チャット書き込みでロール済みのダイスは消えるようになりました。<br>
・ビジュアルダイスのロール中に表示されるダイス目をランダムで変更するように改良。<br>
・深淵の運命カードの誤字を修正。<br>
<br>
2012/06/23 Ver.1.37.06<br>
・ログイン画面に表示されるルームの数と最大ルーム数のデフォルト設定を変更<br>
　以前の値に戻したい人は src_ruby/config.rb の $saveDataMaxCount と $playRoomGetRangeMax を変えてやってください。<br>
・ログイン制限時間がデフォルトで定義されていたため修正。<br>
・深淵の運命カードを改版。一天地六さんありがとうっ！<br>
・ビジュアルダイスにロール音を追加。イザークさんありがとうっ！<br>
・HTML／テキストでのログ保存時にい改行が正しく処理されない問題を修正。まぼろしいたけさんありがとうっ！<br>
<br>
2012/06/18 Ver.1.37.05<br>
・メモ帳の画像を少し薄めに変更。メタボルタさんありがとうっ！<br>
・ダイスボットをボーンズ＆カーズVer2.01.19に対応。<br>
　真・女神転生TRPG　覚醒編 対応を追加。<br>
　判定時にスワップ／通常／逆スワップの結果を表示します。<br>
　威力ダイスは nU6[6] (nはダイス個数)でロール可能です。<br>
　上方無限ロール　(xUn)で 3U6+5 の様に修正値を追加できるように機能拡張。<br>
・src_ruby/config.rb の $loginTimeLimitSecond を設定することで、ログイン時間を制限することが可能に（開発都合での機能追加）<br>
<br>
2012/06/15 Ver.1.37.04<br>
・ダイスボットをボーンズ＆カーズVer2.01.18対応へ変更。<br>
　-> ダイスボットのコマンド誤字修正：choise -> choice<br>
　-> Uコマンドの出力に最大／合計値を表示するように修正。<br>
　　例）4U6[6]<br>
　　　 (4U6[6]) ＞ 5,2,11[6,5],23[6,6,6,5] ＞ 23/41(最大/合計)<br>
・カウンターリモコンでの数値操作に「2D6+1」形式でのダイスロールをサポート。<br>
・カウンターリモコンでイニシアティブ値を[#INI]として編集可能に。<br>
・カウンターリモコン編集画面から「対象」項目を削除（以前の変更漏れ）<br>
・サーバのデフォルトを擬似コメット方式に差し戻し(常時応答返却型は負荷が高すぎたため)<br>
<br>
2012/06/08 Ver.1.37.03<br>
・リプレイ再生時に立ち絵が表示されない問題を修正。<br>
・HTML形式でのログ保存時にタイトルにチャンネル名を追加。<br>
・デフォルト添付のキャラクター画像を一部削除。<br>
<br>
2012/06/07 Ver.1.37.02<br>
・ダイスボットで一部ゲーム（まよキン、マギカロギア、NJSLYRBATTLE）のポイント付与が表示されない問題を修正。<br>
・カウンターリモコン編集時の「対象」項目を削除。常に対象選択に。<br>
<br>
2012/06/04 Ver.1.37.01<br>
・カウンターリモコンの追加。メニューの「表示」→「カウンターリモコン表示」から表示可能。<br>
・一人でブラウザを複数開いてログインした場合に、それぞれをログイン人数としてカウントするように仕様変更。<br>
・「新規プレイルーム作成」でエラーが出る障害に対応。<br>
　Uさん、他たくさんの皆さん指摘ありがとうっ！<br>
・ダイスボットにニンジャスレーヤーオフィシャルオンライントレカ「NJSLYRBATTLE」を追加。ワッショイ！<br>
　もはやTRPGとは毛ほども関係ないけど気にしない！実際遊べる。<br>
　NJSLYRBATTLEについては <a href="http://d.hatena.ne.jp/NinjaHeads/00460403">http://d.hatena.ne.jp/NinjaHeads/00460403</a>参照<br>
　ニンジャスレイヤーについての解説は省略。<br>
<br>
2012/05/14 Ver.1.37.00<br>
・Ver.1.36.15をベースに安定版を開発コード「命のうたが聞こえる」としてリリース。<br>
<br>
2012/05/13 Ver.1.36.15<br>
・ログインメッセージや録画通知が自分にだけ見えなくなっていた問題を修正。四季さん指摘ありがとうっ！<br>
<br>
2012/05/13 Ver.1.36.14<br>
・全データセーブを繰り返し実施時すると古い全セーブが残っているため容量が増えてしまう問題に対処（古いデータを削除するように改善）てんななさんありがとうっ！<br>
・READMEにエックスサーバについての記載を追加。たぐっちゃんさん情報ありがとうっ！<br>
<br>
2012/05/12 Ver.1.36.13<br>
・カットインでプレビューが表示できなくなっていた問題を修正。りおねすさん指摘ありがとうっ！<br>
・リリース媒体のディレクトリ構成を改善。<br>
　saveData, imageUploadSpace を DodontoF ディレクトリの上になる構成を媒体に固め、 config.rb の手動変更を不要に。<br>
　またこれに伴いインストール手順とバージョンアップ手順も更新。<br>
<br>
2012/05/07 Ver.1.36.12<br>
・ダイスボットの表追加をどどんとふ側から出来るように機能追加。チャットウィンドウのダイスボット指定の右隣のアイコンから実行可能。<br>
・ログイン時のユーザー名表示が常に「どどんとふ」になっていた問題を修正。<br>
・メニューの「シナリオデータ作成」を「全データセーブ」に変更<br>
　「シナリオデータ読み込み」を「全データロード(旧：シナリオデータ読み込み)」に変更<br>
・セーブ・全データセーブの画面構成を変更。<br>
・ログイン画面のログイン状況として、現在ログインしている人のいるルームを表示する機能を追加。<br>
・ログイン画面のルーム削除ボタンの位置を変更。（拡張機能から標準へ）<br>
<br>
2012/04/24 Ver.1.36.11<br>
・extratablesディレクトリへの表追加で、ゲーム指定しない場合の処理に対応。<br>
・choiseコマンド追加。<br>
　choise[a,b,c]　で、列挙した要素から一つを選択して表示。ランダム攻撃対象決定などに。<br>
　例１）choise[PC1,PC2,PC3]<br>
　　　diceBot : (CHOISE[PC1,PC2,PC3]) → PC3<br>
　例２）CHOISE「PC1、PC2、PC3、PC4」<br>
　　　diceBot : (CHOISE[PC1,PC2,PC3,PC4]) → PC4<br>
・クトゥルフのダイスボット説明文を整理。<br>
<br>
2012/04/21 Ver.1.36.10<br>
・ダイスボットをボーンズ＆カーズVer2.01.15対応へ変更。<br>
　シノビガミの表として<br>
　　　　　・怪ファンブル表　　　　　KFT<br>
　　　　　・怪変調表　　　　　　　　KWT<br>
　　　　　・異形表　　　　　　　　　MT<br>
　　　　　・ランダム特技決定表　　　RTT<br>
　　　　　・秋空に雪舞えばシーン表　KST<br>
　　　　　・災厄シーン表　　　　　　CLST<br>
　　　　　・出島EXシーン表　　　　　DXST<br>
　　　　　・斜歯ラボシーン表　　　　HLST<br>
　　　　　・夏の終わりシーン表　　　NTST<br>
　　　　　・培養プラントシーン表　　PLST<br>
　を追加。<br>
・extratablesディレクトリに追加したい表データを入れればゲーム中に使用できるようになりました。<br>
つまり、自前サーバの人しか今は使えない機能です。<br>
詳しくはB＆CのREADME.txtの「７．オリジナルの表追加」を参照願います。<br>
ただし現状、特定のゲームへの表の追加しかサポートしていません。<br>
<br>
2012/04/21 Ver.1.36.09<br>
・日本語ファイル名の場合に画像アップロードが上手く動かない問題に対応。九龍さんありがとうっ！<br>
<br>
2012/04/18 Ver.1.36.08<br>
・チャット送信失敗時に内部で再送を行うように変更。再送回数は src_ruby/config.rb の $retryCountLimit に定義。<br>
・再送も全て失敗したなら、チャットウィンドウ右上に送信失敗通知アイコンを出し、そこから再送信用ができるように機能追加。<br>
<br>
2012/04/15 Ver.1.36.07<br>
・キャラクター削除時に削除者以外の環境では内部的にキャラクターが残ってしまう（イニシアティブ表やマップの残滓として）障害を対応。<br>
・試作機能の射線測定モードが紛れ込んでいたので削除。<br>
<br>
2012/04/14 Ver.1.36.06.01<br>
・秘話機能でコンボボックスが押せない問題を修正。四季さん指摘ありがとうっ！<br>
<br>
2012/04/14 Ver.1.36.06<br>
・接続処理の改善(TKさんありがとうっ！)<br>
・ダイスボットをボーンズ＆カーズVer2.01.13対応へ変更。<br>
・シャドウラン4版で1B6の場合のグリッチ判定が誤っていたため修正。Uさん指摘ありがとうっ！<br>
・マップからはみ出す座標表示文字を表示しないように改善。<br>
・マップからはみ出す座標分割線を表示しないように改善。<br>
・ログイン人数が設定上限を超えた場合にログイン画面に警告を表示するように。<br>
<br>
2012/04/04 Ver.1.36.05.02<br>
・接続処理の再修正版。3度目の正直！？<br>
<br>
2012/04/03 Ver.1.36.05.01<br>
・接続のタイムアウトに問題があったため処理修正。こんどこそっ！<br>
<br>
2012/04/03 Ver.1.36.05<br>
・サーバの更新チェック方式を変更。TKさんありがとうっ！<br>
　従来に戻す場合は src_ruby/config.rb の $isCommet を true に変更してください。<br>
<br>
2012/03/28 Ver.1.36.04<br>
・ダイスボットをボーンズ＆カーズVer2.01.11対応へ変更。<br>
　・カオスフレアの失敗時に差分値の表示を追加。<br>
　・モノトーンミュージアムのクリティカル／ファンブル処理の誤りを修正。<br>
　　　まどみさんありがとうっ！<br>
・マップのマス目を交互にずらせるように（スクエアマップでの擬似ヘクス用に）<br>
・山からのカード抜き出しが出来ない問題を修正。<br>
・リプレイデータ編集でキャラクターの移動等が編集できなくなっていた問題を修正。<br>
・リプレイデータ編集で複数項目の一括削除を出来るように改善。<br>
・リプレイデータ編集でチャットチャンネルを変更できるように改善。<br>
・フロアタイルがマップをはみ出している場合に動かせる問題を修正。<br>
・拡大／縮小時に回転マーカーの位置／大きさが不正になる問題を修正<br>
・チャットのメインタグで発言数のカウントが出来ない問題を修正。<br>
・メモを変更しても更新されない問題を修正。<br>
・チャットのカットイン／立ち絵末尾マッチングを1行目以外の文末でも行うように改良。<br>
・チットの枠の色を水色に変更。<br>
・カットインを「表示」メニューと部屋設定から有効／無効 設定可能に。<br>
・カットインの表示位置をの表記方法を変更（上部右->右上、のように）<br>
・カットイン追加・変更・選択画面に有効／無効のチェックボックスを追加。<br>
・カットイン選択画面の構成を変更。<br>
・部屋作成時のカットインにファンブルボイスを追加（デフォルトでは無効）<br>
　tawさんありがとうっ！<br>
<br>
2012/03/24 Ver.1.36.03<br>
・キャラクター画像が縦長の場合に左端に寄って表示される問題に対応。<br>
・カウンターなどの管理用にコマの一種として「チット」を作成可能に。画像のみで回転など機能は一切ありません。<br>
・マップのグリッドを任意のマス数で飛ばして欠けるように機能拡張。<br>
・シナリオデータ読み込み後にシナリオデータ作成を実行すると画像が消えてしまう問題に対応。<br>
・キャラクター待合室へ出し入れした際にイニシアティブ表の一覧が更新されない問題を修正。<br>
・見学者モード時にチャットパレットで文字を別タブに入力できてしまう問題に対応。<br>
・カード捨て時の「Xが「Y」のカードを捨てました。」というメッセージが煩雑なので<br>
　「Xがカードを捨てました。」に変更。<br>
<br>
2012/03/22 Ver.1.36.02<br>
・カードをマップに直接置くように機能変更<br>
・手札置き場の表記を改善<br>
・カード重ねた場合に展開した端のカードをピックアップ・回転しにくい問題を修正。<br>
・チャット表示で「時：分」を表示可能に。チャットウィンドウの「A」アイコンクリックで設定可能。<br>
・ビジュアルダイスが高速回転してしまう問題を修正。<br>
・チャット文字設定変更時にタブの未読カウントが増えてしまう問題を修正。<br>
・前回の動作処理改善でカード捨て等の基本操作が失敗する問題を修正。<br>
<br>
2012/03/16 Ver.1.36.01<br>
・テキスト読み上げ機能を追加。PHP環境必須かつ重い処理なのでsrc_ruby/config.rbの $canTalk で抑止可能。チャットウィンドウの右端スマイリーボタンを押すと有効化。<br>
・キャラクターの追加・移動・削除処理の処理を変更。連続した操作でも自分の操作が手戻ったりしないように改善。<br>
・画像ディレクトリに放り込んだだけのファイルも（全て）で表示されるように改善。<br>
・シナリオデータ読み込み時にチャットパレットが読み込まれない問題を修正。<br>
・シナリオデータ読み込み時のディレクトリ権限を修正。<br>
<br>
2012/03/05 Ver.1.36.00.01<br>
・シナリオデータ作成が出来ない障害を修正。(九龍さん指摘ありがとう！）<br>
<br>
2012/03/05 Ver.1.36.00<br>
・Ver.1.35.13.02をベースに安定版を開発コード「NEW FRONTIER」としてリリース<br>
<br>
2012/03/02 Ver.1.35.13.02<br>
・セーブ処理が出来ない不具合に対応(九龍さん指摘ありがとう！）<br>
・README.htmlにバージョンアップの場合の記述を追加。<br>
・仮機能のテキスト読み上げ機能を差し戻し。（また今度正式リリースするねっ）<br>
<br>
2012/03/02 Ver.1.35.12<br>
・簡易マップ作成画面で画像が左右反転しない障害を修正。<br>
・マップ画像の初期読み込み表示で左右反転が正しく表示されない障害を修正。<br>
<br>
2012/02/28 Ver.1.35.11<br>
・立ち絵画像データのキャッシュが正しく動作していなかった問題に対応。<br>
・キャラクターとマップと立ち絵の画像を左右反転できるように機能追加。<br>
・チャットで立ち絵キャラクターが発言した状態だとチャットパレットからの立ち絵表示が失敗する問題を修正。<br>
・REAME.html のWEB IF getChatColorの記述を修正。<br>
・WEB IFでプレイルーム番号や必須パラメータの指定がない場合のチェック処理を追加。<br>
・前バージョンがmode=mysql指定での起動に失敗する問題を修正。<br>
・インストール手順に@PAGEの場合のパーミッション指定を追記。<br>
・メニューのログ出力項目を削除。<br>
<br>
2012/02/22 Ver.1.35.10<br>
・カウンター名設定で末尾に空白を入れると正しく表示されない問題に対応。<br>
・サーバの負荷を測定するための getInfo.rb ファイルを削除し、 DodontoFServer.rb で計測できるように改良。READMEからも記載を削除。<br>
<br>
2012/02/19 Ver.1.35.09<br>
・プレイルーム作成・変更時の設定処理が正しく行われない障害を修正。<br>
・B＆C1.0系時の用の不要な環境設定値を削除。<br>
<br>
2012/02/18 Ver.1.35.08<br>
・マニュアルの customBot.pl（旧ダイスボット） 関連の記述を削除。<br>
・WEBカメラアップロード機能を改善。CGIから WebCameraCaptureImageUploader.rb を削除。マニュアルの記述も修正。<br>
<br>
2012/02/17 Ver.1.35.07<br>
・WEB IF に getChatColor を追加。指定したユーザーの最新の発言時の文字色が取得できます。<br>
実行例）　DodontoFServer.rb?webif=getChatColor&room=0&password=himitsu&name=taitai&callback=responseFunction<br>
各パラメータの意味は以下の通り<br>
　webif：チャットの文字色を取得する場合は getChatColor を指定<br>
　room：対象プレイルーム番号<br>
　password：対象プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　name：対象ユーザー名<br>
　callback: JSONP取得用。省略可<br>
重い処理なので毎回呼ばずに最初に1度だけ読んで結果を保持してやってください<br>
<br>
2012/02/17 Ver.1.35.06<br>
・WEB IFのtalkにパラメータcolorを追加。<br>
　文字の色を 00000〜FFFFFF の16進数で指定可能。<br>
いろいろややこしくなってきたのでここでtalkについて再度記載。<br>
<br>
WEB IF の talk について。<br>
実行例）　DodontoFServer.rb?webif=talk&room=0&password=himitsu&name=taitai&message=hello&color=00AA00&bot=SwordWorld&callback=responseFunction<br>
各パラメータの意味は以下の通り<br>
　webif：チャットを投げる場合は talk を指定<br>
　room：チャットを投げるプレイルーム番号<br>
　password：データを投げるプレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　name：チャットを投げるユーザー名（省略の場合は名前が空になります）<br>
　message：チャットに投げる文字列<br>
　color：文字の色を 00000〜FFFFFF の16進数で指定可能。省略時は 000000（黒色）<br>
　bot：ダイスボットを使用する場合に使用するゲーム種別を指定（指定しない場合は「ダイスボット（指定なし）」に）。種別名の詳細は src_ruby/diceInfo.rb を参照<br>
　channel：チャットを投げるタブ番号（メイン：0 として、以降右を 1,2,3...と数えます）省略時は0（メイン）に。<br>
　callback: JSONP取得用。省略可<br>
長すぎるメッセージを投げる場合はURLパラメータのGET送信をやめて適宜POSTしてやってください。<br>
またWebIF使用時の応答データフォーマットを {"result"=>"OK", ...} というJSONに統一。成功時には result に "OK" が書き込まれますのでそれで判定してください。<br>
<br>
2012/02/04 Ver.1.35.05<br>
・シナリオデータ作成機能が一部環境で正常に動作しなかった問題を修正。<br>
<br>
2012/01/28 Ver.1.35.04<br>
・MySQL使用時にログイン画面の表示が止まってしまう障害に対応。<br>
・イニシアティブ表のカウンター数を30まで拡張。<br>
・キャラクターの情報としてデータ参照先URLを設定可能へ。キャラクター作成・変更画面にURLの設定項目を追加。キャラクターの右クリックから設定したURLを開くことができます。<br>
<br>
2012/01/11 Ver.1.35.03<br>
・ダイスボットをボーンズ＆カーズVer2.01.10対応へ変更。ブラッドクルセイドに対応。<br>
・イニシアティブ表の「手番」の文字を「順番」に変更<br>
・イニシアティブ表の文字サイズを「設定」ボタンから変更できるように機能追加。<br>
<br>
2012/01/07 Ver.1.35.02<br>
・★超重要：キャラクターデータの変更に失敗する重大なバグがあったため修正。（チゲさん指摘ありがとう！！）<br>
・サーバの負荷確認方法を修正（外部ドメインに対応できていなかったため）<br>
　★重要：getInfo.rb というファイルが追加されていますので、rubyパスと実行権限の変更お願いします。負荷率を収集させる必要が無いのであれば特になにもしなくてもOKです。<br>
　ログイン情報の表示は getInfo/dodontofInfo.html を参考にしてください。<br>
　あ、あと負荷状況管理ファイル(loginCount.txt)の置き場所はTOPディレクトリから saveData ディレクトリに変更になりましたので、古いファイルは.lockとセットで削除してやってください。<br>
<br>
<br>
2012/01/02 Ver.1.35.01<br>
・墓場の中身を削除できるように機能追加。墓場画面から削除ボタンを押してください。<br>
・チャットログをテキスト保存時に改行コードが正しく保存されない障害に対応（流さん指摘ありがとうっ！）<br>
・チャットパレットでの変数定義に以下のような多重定義を可能に<br>
//A = 1
//B = 2
//AB = {A}+{B}
・特定のプレイルームへのパスワード設定・ロード実行を禁止できるように src_ruby/config.rb に $unloadablePlayRoomNumbers, $noPasswordPlayRoomNumbers を追加。公式サーバ用の機能なので一般用途では特に必要ないかと思います。<br>
・サーバのログイン人数からの負荷率を保存し、外部参照できるように機能追加。<br>
　上限ログイン人数の目安を src_ruby/cofig.rb の $aboutMaxLoginCount に定義してください。<br>
　またログイン状況は loginCount.txt に保存されます。<br>
　WEB上での表示には <a href="http://www.dodontof.com/torgtaitai/dodontofBusy.html">http://www.dodontof.com/torgtaitai/dodontofBusy.html</a>が参考になるでしょう。<br>
<br>
・WEB IFのキャラクター追加コマンドにパラメーターを追加。<br>
DodontoFServer.rb?webif=addCharacter&room=1&password=himitsu&name=abc&counters=HP:1,MP:1,*check:0,*check:1&info=foo&x=0&y=1&size=2&initiative=9&rotation=30&statusAlias=check:abc,check2:def&dogTag=1&draggable=true&isHide=false<br>
のように指定することで実行可能。<br>
各パラメータの意味は以下の通り<br>
　webif：キャラクター追加時は addCharacter を指定<br>
　room：プレイルーム番号<br>
　password：プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　name：キャラクター名<br>
　counters：イニシアティブに表示するカウンター値 名1:値1,名2:値2,.... というフォーマットで指定。省略可<br>
　info：その他情報。省略可<br>
　x：x座標。省略可<br>
　y：y座標。省略可<br>
　size：キャラクターのサイズ。省略可<br>
　initiative：イニシアティブ値。省略可<br>
　rotation：回転角度。省略可<br>
　image：画像。省略時はデフォルトに。<br>
　callback: JSONP取得用。省略可<br>
★ここから追加分
　statusAlias：イニシアティブに表示するカウンター値がチェックボックスの場合に付けることの出来る別名の指定 名1:別名1,名2:別名2,.... というフォーマットで指定。省略可<br>
　dogTag：複数キャラクター作成時に付与される「１」のような番号表示用のパラメータ。実は任意の文字が使えます。省略可<br>
　draggable：ドラッグ移動の是非。trueで移動可能(true,false)。省略可<br>
　isHide：マップマスクの下にキャラクターを隠すかの指定。trueで隠す(true,false)。省略可<br>
<br>
<br>
・WEB IFにキャラクター変更コマンドを追加。<br>
DodontoFServer.rb?webif=changeCharacter&room=1&password=himitsu&targetName=abc&name=def&counters=HP:1,MP:1,*check:0,*check:1&info=foo&x=0&y=1&size=2&initiative=9&rotation=30&statusAlias=check:abc,check2:def&dogTag=1&draggable=true&isHide=false<br>
のように指定することで実行可能。<br>
各パラメータの意味は以下の通り<br>
　webif：キャラクター追加時は changeCharacter を指定<br>
　room：プレイルーム番号<br>
　password：プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　targetName：変更対象とするキャラクターの名前<br>
　name：キャラクター名。省略可<br>
　counters：イニシアティブに表示するカウンター値 名1:値1,名2:値2,.... というフォーマットで指定。省略可<br>
　info：その他情報。省略可<br>
　x：x座標。省略可<br>
　y：y座標。省略可<br>
　size：キャラクターのサイズ。省略可<br>
　initiative：イニシアティブ値。省略可<br>
　rotation：回転角度。省略可<br>
　image：画像。省略時はデフォルトに。<br>
　callback: JSONP取得用。省略可<br>
　statusAlias：イニシアティブに表示するカウンター値がチェックボックスの場合に付けることの出来る別名の指定 名1:別名1,名2:別名2,.... というフォーマットで指定。省略可<br>
　dogTag：複数キャラクター作成時に付与される「１」のような番号表示用のパラメータ。実は任意の文字が使えます。省略可<br>
　draggable：ドラッグ移動の是非。trueで移動可能(true,false)。省略可<br>
　isHide：マップマスクの下にキャラクターを隠すかの指定。trueで隠す(true,false)。省略可<br>
　callback: JSONP取得用。省略可<br>
<br>
<br>
2011/12/18 Ver.1.35.00<br>
・Ver.1.34.04をベースに安定版を開発コード「sunlight」としてリリース<br>
<br>
2011/12/15 Ver.1.34.04<br>
・WEB IFにキャラクター追加コマンドを追加。<br>
DodontoFServer.rb?webif=addCharacter&room=1&password=himitsu&name=abc&counters=HP:1,MP:1&info=foo&x=0&y=1&size=2&initiative=9&rotation=30<br>
のように指定することで実行可能。<br>
各パラメータの意味は以下の通り<br>
　webif：キャラクター追加時は addCharacter を指定<br>
　room：プレイルーム番号<br>
　password：プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　name：キャラクター名<br>
　counters：イニシアティブに表示するカウンター値 名1:値1,名2:値2,.... というフォーマットで指定。省略可<br>
　info：その他情報。省略可<br>
　x：x座標。省略可<br>
　y：y座標。省略可<br>
　size：キャラクターのサイズ。省略可<br>
　initiative：イニシアティブ値。省略可<br>
　rotation：回転角度。省略可<br>
　image：画像。省略時はデフォルトに。<br>
　callback: JSONP取得用。省略可<br>
<br>
・WEB IFにプレイルーム情報取得コマンドを追加。<br>
DodontoFServer.rb?webif=getRoomInfo&room=1&password=himitsu&callback=responseFunction<br>
のように指定することで実行可能。<br>
各パラメータの意味は以下の通り<br>
　webif：プレイルーム情報取得時は getRoomInfo を指定<br>
　room：プレイルーム番号<br>
　password：プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　callback: JSONP取得用。省略可<br>
<br>
・WEB IFにプレイルーム設定コマンドを追加。<br>
DodontoFServer.rb?webif=setRoomInfo&room=1&password=himitsu&counter=HP,MP,PPP&chatTab=aiu,eo&roomName=mokekeRoom&outerImage=true&visit=true&game=TORG<br>
のように指定することで実行可能。<br>
各パラメータの意味は以下の通り<br>
　webif：プレイルーム設定時は setRoomInfo を指定<br>
　room：プレイルーム番号<br>
　password：プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　counter：イニシアティブに表示するカウンター名。名1,名2,.... というフォーマットで指定。省略可<br>
　chatTab：チャットウィンドウで使用するタブの名前。タブ名1,タブ名2,.... というフォーマットで指定。省略可<br>
　roomName：プレイルーム名。省略可<br>
　outerImage：外部画像の使用の可否(true,false)。省略可<br>
　visit：見学者の可否(true,false)。省略可<br>
　game：デフォルトでサポートするゲーム名（ダイスボットと同様の定義名を使用）。種別名の詳細は src_ruby/diceInfo.rb を参照。省略可<br>
　callback: JSONP取得用。省略可<br>
<br>
・WEB IFにメモ追加コマンドを追加。<br>
DodontoFServer.rb?webif=addMemo&room=1&password=himitsu&callback=responseFunction&message=qwerty<br>
のように指定することで実行可能。<br>
各パラメータの意味は以下の通り<br>
　webif：プレイルーム情報取得時は getRoomInfo を指定<br>
　room：プレイルーム番号<br>
　password：プレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　message：メモに記述する文字列<br>
　callback: JSONP取得用。省略可<br>
<br>
<br>
2011/12/11 Ver.1.34.03<br>
・ダイスボットをボーンズ＆カーズVer2.01.09対応へ変更。<br>
　マギカロギアのコマンドがシークレットモードに設定されてしまう問題に対処。<br>
・シナリオ読み込み機能をmod_rubyでも動作するように修正。<br>
<br>
2011/12/05 Ver.1.34.02.01<br>
・リリースファイルが誤っていたため再度リリース<br>
<br>
2011/12/05 Ver.1.34.02<br>
・イニシアティブ修正値にマイナス値を-9まで値を入力可能に（逆に上限は90になります）<br>
<br>
2011/11/30 Ver.1.34.01<br>
・シナリオ集用のデータ読み込み動作用に「ファイル」メニューに「シナリオデータ読み込み」メニューを追加。<br>
・カードにファー・ローズ・トゥ・ロードの地縁・霊縁カードを追加。犬山ぽち丸さんありがとうっ！<br>
・カットインに「カットインタグ名」を追加。カットインタグ名が同一のカットインが開かれている状態で新しいカットインを開くと、自動的に古いほうが閉じて切り替わる形になります。<br>
・ダイスボットをボーンズ＆カーズVer2.01.08対応へ変更。<br>
　「1D20+0」のように +0 の修正を加えた場合にダイスロールが行われない問題に対処。<br>
・メッセージカードを復旧可能に<br>
・TORGのドラマデッキで一部カードのドラマチック行動解決欄が表示されていなかった障害を修正。law-ninさん指摘ありがとうっ！<br>
・正位置・逆位置の無いカードのテキストをチャットに引用するときには、「正位置」「逆位置」を記述しないように修正。<br>
・マップの最大縦横幅を src_ruby/config.rb で設定できるように変更。<br>
<br>
2011/10/31 Ver.1.34.00.01<br>
・mod_ruby利用時にWEB IFでの操作が出来ない不具合が合ったため修正版リリース。<br>
　このため、ダイスボットをボーンズ＆カーズVer2.01.07対応へ変更（機能的な変更は無し）<br>
<br>
2011/10/25 Ver.1.34.00<br>
・Ver.1.33.09をベースに安定版を開発コード「born Legend」としてリリース<br>
<br>
2011/10/22 Ver.1.33.09<br>
・どどんとふ の設置方法に「さくらVPSを使用する場合」として<u><b><a href="./howToSetupOnSakuraVPS.html">どどんとふ設置メモ (さくらVPS Ubuntu10.04)</a></b></u><br>を追加。 ぜっぱちさんありがとうっ！<br>
・カットインのBGMを無限ループ再生できるように機能追加。<br>
・迷宮キングダムのダイスボットのエキゾチック名前表(NAMEEX),ファンタジック名前表(NAMEFA)のコマンド記載誤りを修正。<br>
・WEB IFに共通パラメータとしてJSONP取得用の callback=xx を追加。
　URLで DodontoFServer.rb?webif=chat&room=0&password=himitsu&sec=all&callback=responseFunction
　や　　DodontoFServer.rb?webif=talk&room=0&password=himitsu&name=taitai&message=hello&bot=SwordWorld&callback=responseFunction
　のように指定することで指定したデータをJSONP形式で取得可能。<br>
<br>
2011/10/15 Ver.1.33.08<br>
・ダイスボットをボーンズ＆カーズVer2.01.03対応へ変更。<br>
　迷宮キングダムのダイスボットに　王国名決定表１〜４(KNT1〜KNT4）、単語表１〜４(WORD1〜4)、名前表A(NAMEA),名前表B(NAMEB),エキゾチック名前表(NAMEEX),ファンタジック名前表(NAMEFA)　を追加。あきさんありがとうっ！<br>
　迷宮キングダムの判定結果に6が出た場合の気力取得結果を追加。同じくあきさんありがとうっ！<br>
　迷宮キングダムのコマンドで1MKとした場合に正しく計算されない不具合を修正。あきさん指摘ありがとうっ！<br>
　サタスペで2d6のような通常のダイスロールが出来ない障害を修正。とくめいさんありがとうっ！<br>
　カウンター操作時の不具合を修正。@sillygoさんありがとうっ！<br>
・「表示」->「ウィンドウ配置初期化」メニューを追加。再ログインしなくてもウィンドウの配置を戻せます。<br>
・「2D6あいうえお」のようにダイス文字の後に空白を開けないで文字を書いた場合にダイスボットが不用意に動く障害を修正。<br>
・ログイン画面にプレイルームのゲームシステム名を表示するように機能追加。<br>
・WEB IFの talk にパラメータを追加。<br>
　bot：ダイスボットを使用する場合に使用するゲーム種別を指定（指定しない場合は「ダイスボット（指定なし）」に）。種別名の詳細は src_ruby/diceInfo.rb を参照<br>
<br>
2011/10/02 Ver.1.33.07<br>
・ダイスボットをボーンズ＆カーズVer2.01.01対応へ変更。Eclipse Phaseに対応。<br>
<br>
2011/10/02 Ver.1.33.06<br>
・ダイスボットをボーンズ＆カーズVer2.01対応へ変更。D66がロールできない障害に対応。<br>
・ログイン画面の「新規プレイルーム作成」ボタンでのルーム作成時にダイスボットが選択できない問題を修正。<br>
<br>
2011/10/01 Ver.1.33.05<br>
・ダイスボットを従来のボーンズ＆カーズ準拠からVer2.0準拠へ変更(使用バージョンはVer2.00.02)。これによりダイスボット処理を高速化。<br>
・上記に伴い、ダイスボットを「絶対隷奴」に対応。<br>
・キャラクター追加時にイニシアティブ修正値が反映されない障害を修正。やかんつかいのリュートさん指摘ありがとうっ！<br>
・カードのランダム・ダンジョン用トランプ画像を差し替え。超小兎さん指摘ありがとうっ！<br>
・WEB IFを実装。URLで DodontoFServer.rb?webif=talk&room=0&password=himitsu&name=taitai&message=hello のように指定することでチャットにメッセージを投げることが出来ます。<br>
　各パラメータの意味は以下の通り<br>
　webif：チャットを投げる場合は talk を指定<br>
　room：チャットを投げるプレイルーム番号<br>
　password：データを投げるプレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　name：チャットを投げるユーザー名（省略の場合は名前が空になります）<br>
　message：チャットに投げる文字列<br>
　channel：チャットを投げるタブ番号（メイン：0 として、以降右を 1,2,3...と数えます）省略時は0（メイン）に。<br>
長すぎるメッセージを投げる場合はURLパラメータのGET送信をやめて適宜POSTしてやってください。<br>
またWebIF使用時の応答データフォーマットを {"result"=>"OK", ...} というJSONに統一。成功時には result に "OK" が書き込まれますのでそれで判定してください。<br>
<br>
2011/09/14 Ver.1.33.04<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.45準拠へ。ネクロニカ製品版に「パーツ損傷」ルールを対応。<br>
・TORGダイスボット選択時にチャット文字の「」や、が[],に変化してしまう障害を修正。<br>
・プレイルームの設定でダイスボットを設定可能に。<br>
・WEB IFを実装。URLで DodontoFServer.rb?webif=chat&room=0&password=himitsu&sec=all のように指定することで指定したデータをJSON形式で取得可能。<br>
　各パラメータの意味は以下の通り<br>
　webif：取得するデータの種別（現状 chat のみサポート）<br>
　room：データを取得するプレイルーム番号<br>
　password：データを取得するプレイルームのパスワード（パスワードが無い、あるいは見学可の場合は省略可能）<br>
　sec：何秒前までのチャットを取得するかの指定。allなら全取得、省略なら180秒（$oldMessageTimeoutで指定）<br>
　marker：基本不要。trueを設定することで、JSONの前後に #D@EM&lt;#(JSON)#&gt;D@EM# とマーカーを付与（CGI広告埋め込み対策）<br>
<br>
2011/09/05 Ver.1.33.03<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.43準拠へ。モノトーンミュージアムに対応。あと誤字修正とか。<br>
・イニシアティブ表示でチェックボックスに名前を付与できるように機能追加。キャラクター追加・変更画面の右側の「■」ボタンから設定できます。<br>
　神業や身体部位欠損管理にどうぞ。<br>
・カードを一括で複数枚引けるように機能追加。山札の右クリックメニューの「カードをN枚引く」から実行可能。<br>
・キャラクターの一括削除に対応。Ctrlキー押しながら選択、右クリックメニューから削除で選択対象を全削除。<br>
<br>
2011/08/27 Ver.1.33.02<br>
・SWFのカットインを閉じた場合でも音がなり続ける不具合に対応。だいふくさんありがとうっ！<br>
・ログアウトボタンにラベルを追加。<br>
・ルーム設定の表示状態が正しく反映されない障害を修正。<br>
・ログイン画面の「あなたの名前」が初回ログイン時に反映されない障害を修正。<br>
・ログイン直後に選択されているキャラクターの立ち絵選択肢が表示されない障害を修正。<br>
・キャラクター表示を軽量化。<br>
・性能測定用機能追加。src_ruby/config.rbの $isPaformanceMonitor参照。<br>
・画面更新速度を変更可能に。src_ruby/config.rbの $fps参照。<br>
<br>
2011/08/24 Ver.1.33.01<br>
・マップ表示を軽量化。TKさんありがとうぅぅぅ！！！<br>
<br>
2011/08/11 Ver.1.33.00<br>
Ver.1.32.07をベースに安定版を開発コード「Jackpot」としてリリース<br>
<br>
2011/08/11 Ver.1.32.07<br>
・ログイン画面で2タブ目以降のプレイルームを削除できない障害を修正。<br>
<br>
2011/07/31 Ver.1.32.06<br>
・トランプの画像を綺麗に表示できるように改善(JPGからSWFへ変更)。超小兎さんいつも超ありがとうっ！！<br>
<br>
2011/07/22 Ver.1.32.05<br>
・ノベルゲーム風表示モードの「メイン」タブが表示されない問題を修正。<br>
<br>
2011/07/18 Ver.1.32.04<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.42準拠へ。六門世界2nd.Editionに対応、ネクロニカの大失敗判定を修正、パラサイトブラッドに誤作動表を追加。<br>
<br>
2011/07/12 Ver.1.32.03<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.39準拠へ。マギカロギアのランダム特技決定表の追加とダークブレイズDBコマンド修正。<br>
・ダイスボットでまよきんDFTのように複数行出力の場合にダイスボット名称が繰り返し表示される問題を修正。<br>
<br>
2011/07/04 Ver.1.32.02<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.37準拠へ。まよきんのアイテム特性表を修正。<br>
・まよきんのLIT/RIT/SIT/RWIT/RUITコマンドが動かない障害を修正。sillygoさんありがとぅっ！<br>
<br>
2011/07/01 Ver.1.32.01<br>
・墓場からの共有メモ等の復活時に名前が正しく表示されない問題を修正。<br>
・カード操作時のチャットログ表示でカード名称が一部正しく表示されていなかった点を修正。<br>
・リプレイ録画データ投稿所の画面構成を変更。<br>
<br>
2011/06/25 Ver.1.32.00<br>
Ver.1.31.05をベースに安定版を開発コード「NiNa」としてリリース<br>
<br>
2011/06/24 Ver.1.31.05<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.36準拠へ。ゲヘナ・アナスタシスの「幸運の助け」処理を修正。<br>
・カードに上海退魔行の陰陽カードを追加。@KTR_WHさんぱとぱとりんさんありがとうっ！<br>
<br>
2011/06/24 Ver.1.31.04<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.35準拠へ。まよきんの相場表のダイス誤りと、迷宮デイズのカーネル停止表の誤字を修正<br>
・ログイン画面で複数プレイルームの一括削除を可能に。<br>
<br>
2011/06/14 Ver.1.31.03<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.34準拠へ。ダイスボットのTORGでボーナス計算が20以上の場合に1少ない値になる障害を修正。<br>
・TORGドラマデッキのアドレナリン等に増加する能力値を明記修正。（上記と合わせて、しゃあみさん指摘ありがとぅ！）<br>
<br>
2011/06/12 Ver.1.31.02<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.33準拠へ。バルナ・クロニカに対応。迷宮キングダムの表を追加。サタスペの一部コマンドがシークレット表示されるバグの修正。<br>
・リプレイ録画時に自分の発言が録画されない障害を修正。<br>
・ログイン時にエラーメッセージが表示される障害を修正。<br>
<br>
2011/06/01 Ver.1.31.00.02<br>
Ver1.31.01を元に「AGATA」再リリース<br>
（障害の不具合報告が散見されるため）<br>
<br>
2011/06/01 Ver.1.31.01<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.30.1準拠へ。 迷宮デイズに対応、シノビガミ・マギカロギア・迷宮キングダムを拡張。<br>
・再ログイン時に前回までの自分のメッセージが表示されない不具合を修正。<br>
・マップ画像のタグ名に「縦NN横MM」書式のタグを追加するとマップ画像の変更時のデフォルトサイズを指定可能に。<br>
<br>
2011/05/28 Ver.1.31.00.01<br>
Ver1.31.00の以下の障害を修正し「AGATA」再リリース<br>
・チャットパレット編集時に正しく内容が反映されない。<br>
・共有メモのカーソル合わせた際の拡大率を修正。<br>
<br>
2011/05/28 Ver.1.31.00<br>
Ver.1.30.13をベースに安定版を開発コード「AGATA」としてリリース<br>
<br>
2011/05/27 Ver.1.31.13<br>
・マップ上のアイテムへカーソルを合わせた場合にドラッグ可能を示す為に少し拡大する処理を追加。<br>
・プレイルームの設定として、デフォルトの表示状態を設定できるように機能追加。<br>
・簡易マップ作成画面でウィンドウサイズを変更すると設定した色が消える不具合を修正。<br>
<br>
2011/05/21 Ver.1.30.12<br>
・メインメニューの項目配置を整理。<br>
・再ログイン時にカードの権限が保持されるように改良。<br>
・トランプを捨てたときに捨てた札名を表示するように改良。<br>
・キャラクター追加／変更画面のチェックボックス欄カラム名の色の変更を取りやめ（チャットログスクロール問題対応）。<br>
・キャラクター拡大／縮小時の回転動作の不具合修正。<br>
・RubyのMySQLライブラリを2.9.4-betaに更新<br>
<br>
2011/05/17 Ver.1.30.11<br>
・回転マーカーの置き換え（超小兎さんありがとうっ！）<br>
・回転マーカーがサイズ2以上に途中変更すると破綻する問題を修正。<br>
・イニシアティブ表のチェックボックス欄カラム名の色の変更を取りやめ（チャットログスクロール問題対応）。<br>
・マップドラッグ中にウィンドウでマウスボタンを離してもドラッグが解除されない問題に対処。<br>
・チャットパレットに最後に記入した情報をキャッシュに保持するように機能追加。<br>
・カード引き・捨て時のメッセージを表示へ。<br>
・カード／山札／捨て札をダブルクリックでカード裏返し／カード引きを行うように変更。<br>
・完全非公開カードを捨て札に置いたときにカード内容を表示しないように変更。<br>
・ダイスボット処理のCGI完全移行。<br>
・マヨキンやその他ゲームのダイスボットをD66ダイス対応に修正。<br>
<br>
2011/05/13 Ver.1.30.10<br>
・画面全体を半透明に<br>
・キャラクター／カードの回転方法を右クリックメニューから左上回転アイコン操作に変更。<br>
・捨て札から任意のカードを抜き出す機能を追加。<br>
・捨て札の画像を最後に捨てたカードの画像に<br>
・画面更新時に極端に重くなる障害に対応<br>
<br>
2011/05/08 Ver.1.30.09<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.29準拠へ。ネクロニカに対応。マギカロギアのロール結果をソート表示に。<br>
・ダイスボットの解説文章を改善<br>
・キャラクター追加・変更画面にカウンターの変更機能を追加。<br>
・ロード画面にキャラクター待合室の部分ロード機能を追加。<br>
・同一名キャラクター追加時のエラー処理対象にキャラクター待合室も追加。<br>
<br>
2011/05/07 Ver.1.30.08<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.27準拠へ。マギカロギアの魔素獲等と判定結果表示を追加。<br>
・ダイスボットのヘルプメッセージ等をsrc_ruby/diceBotInfos.rbへ集約。任意のダイスボット対応を可能に。<br>
<br>
2011/05/07 Ver.1.30.07<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.26準拠へ。マギカロギア対応。シノビガミ「死」「乱」対応。<br>
・キャラクター待合室を追加。「コマ」→「キャラクター待合室」で画面起動できます。<br>
・画像保持件数の最大数を500件から2000件に変更。<br>
・イニシアティブ表のカラム幅を保存するように改善。<br>
・各ウィンドウの位置を部屋毎に保存するように改善。<br>
<br>
2011/04/25 Ver.1.30.06<br>
・イニシアティブ表のチェック入力時にチャットログのスクロールが最上段に移動する障害に対応。<br>
<br>
2011/04/24 Ver.1.30.05.01<br>
・ログイン画面でプレイルーム削除時に100以上の番号でエラーとなる障害を修正。<br>
・チャットログの改行がうまく表示されない障害を修正。<br>
・カードにアリアンロッド等のランダムダンジョン機能を追加。<br>
・イニシアティブ表のカウンターに「＊転倒」のように先頭に ＊ を付ける事でチェックボックスを追加できるように改良。またチェックを入れるとキャラクターコマの左下にマーカーが表示され、カーソルON時の表示にも記載されます。仕様検討ありがとう超小兎さん！！<br>
<br>
2011/04/06 Ver.1.30.04<br>
・録画時に自分宛以外の秘話メッセージを取得しないように改善。<br>
<br>
2011/03/27 Ver.1.30.03<br>
・ログイン画面で並び順を変えクリックすると誤ったプレイルーム番号が入力される障害を修正。<br>
・点呼／投票時に見学者を除外するように改善。<br>
・ログイン画面での見学者名にも＠見学者をつけるように改善。<br>
<br>
2011/03/25 Ver.1.30.02<br>
・チャットパレットに｛キーワード｝のような置換方式を追加。<br>
・キャラクター画像にポーンを追加。流さんありがとうっ！<br>
<br>
2011/03/23 Ver.1.30.01<br>
・一部データのみのロードでチャットログが再読み込みされないように修正。<br>
・録画時のデータ容量を削減するように改良。<br>
<br>
2011/03/14 Ver.1.30.00<br>
Ver.1.29.07をベースに安定版を開発コード「PARANOIA」としてリリース<br>
<br>
2011/03/04 Ver.1.29.07<br>
・ログイン画面でダブルクリックでのログイン時に正しいプレイルームに入れない障害を修正。<br>
<br>
2011/03/04 Ver.1.29.06<br>
・ログイン画面でのプレイルーム削除処理の障害を修正。<br>
<br>
2011/03/04 Ver.1.29.05<br>
・ログイン画面を更新し、プレイルームの大量管理を可能に。<br>
<br>
2011/02/15 Ver.1.29.04<br>
・マップマスク作成・変更画面を改善。複数一括登録を可能に。<br>
<br>
2011/02/01 Ver.1.29.00.03<br>
Ver.1.29.03をベースに安定版「Viva la Vida」を再リリース<br>
<br>
2011/02/04 Ver.1.29.03<br>
・点呼機能が正しく動作していなかった障害を修正。<br>
・ファイルアップロード機能でアップロードできるファイル拡張子を制限へ。<br>
・チャットパレットでCtrl＋Shift＋左右キーでチャットウィンドウのタブを切り替え可能に（前はShift＋左右キーでしたが変更に）<br>
<br>
2011/02/01 Ver.1.29.00.02<br>
Ver.1.29.02をベースに安定版「Viva la Vida」を再リリース<br>
<br>
2011/01/31 Ver.1.29.02<br>
・プレイルーム変更時にパスワードが誤った値で設定される障害を修正。<br>
<br>
2011/01/30 Ver.1.29.00.01<br>
Ver.1.29.01をベースに安定版「Viva la Vida」を再リリース<br>
<br>
2011/01/29 Ver.1.29.01<br>
・チャットウィンドウでCtrlキー操作時に雑談チャットにログが表示される障害を修正。<br>
・外部画像参照機能をプレイルーム設定画面からON/OFF可能に（デフォルトはOFF）。「No.xxx」のボタンからプレイルーム変更画面で設定できます。<br>
・チャットウィンドウの名前欄に入力補完（サジェスチョン）機能を追加。<br>
・マップ状態保存/切り替えの対象としてマップマーカーを追加。（これまではマップ＋マップマスクのみ）<br>
<br>
2011/01/26 Ver.1.29.00<br>
Ver.1.28.16をベースに安定版を開発コード「Viva la Vida」としてリリース<br>
<br>
2011/01/26 Ver.1.28.16<br>
・チャットウィンドウでHPなどの値をマイナス表示できなかった問題を修正。<br>
・ダイスボットで（指定無し）が選択できなくなっていた問題を修正。JAMさんありがとぅ！<br>
<br>
2011/01/25 Ver.1.28.15<br>
・リプレイモードが再生できない障害を修正。<br>
・チャットログの保存を複数チャンネル方式に対応へ。<br>
・チャットでのカットイン・立ち絵発動時に＠を前につけて「〜＠立ち絵」のように記述すると、＠以下が削除するように機能拡張。<br>
　これでチャットパレットに「台詞＠笑顔」のように記述することで立ち絵の差し替えが可能になります。<br>
・チャットログをテキスト形式でも保存可能に。<br>
・イニシアティブ表の数値にマイナス値も設定可能に。<br>
・チャットパレットでShitf＋左右でチャットウィンドウのタブ移動を可能に。<br>
・ダイスボットの定義をsrc_ruby/diceBotInfo.rbに変更。データには変更なし。<br>
・CGIスクリプトをRuby1.9用に修正。<br>
<br>
2011/01/21 Ver.1.28.14<br>
・チャットパレットでダイス文字列の場合に色が反映されない問題を修正。<br>
・チャットウィンドウのCtrl+左右キーでのタブ遷移を左右巡回へ。<br>
・カードにマスカレイドスタイルのアクトカードの枚数が不足していたため修正。<br>
<br>
2011/01/16 Ver.1.28.13<br>
・イニシアティブ表で数値を変更すると更新が行われなくなる不具合に対応。<br>
・見学モードを追加。プレイルーム作成・変更時に見学の有無を指定でき、見学可の場合はパスワード有りでも見学はできるようになります。<br>
・画像タグ名選択にタグ名入力入力による補完（サジェスチョン）機能を追加。清水さんありがとぅっ！！<br>
・リプレイアップロード機能追加。ログイン画面の「＞＞拡張機能」「リプレイ投稿」でリプレイデータの投稿を可能に。<br>
　事前にreplayDataUploadSpaceディレクトリに書き込み権限を与えてください（お試し新機能）<br>
・前回ログイン時のダイスボット選択状態を自動記録して次回再現するように改善。<br>
・チャットウィンドウの最大化ボタン追加。<br>
・チャットパレットのウィンド位置が初期化時に不正になる障害を修正。<br>
・チャットのタブを任意に増減できるように機能追加。プレイルームの設定画面（初期ルーム作成時か「ルーム」ボタンからの設定画面）で変更可能。<br>
・迷宮キングダムの魅力休憩表の表記を修正。<br>
<br>
2010/12/17 Ver.1.28.12<br>
・デフォルトの画像を大量追加。既にサーバ運用中の方はimage\defaultImageSet\taketomu28配下の画像を確認してください。<br>
　たけとむ二十八号さんありがとうっ！！<br>
・サーバ設置直後のプレイルームNo.0が正しく表示できない問題を修正。<br>
・外部画像参照禁止処理の誤り修正。<br>
<br>
・カードにマスカレイドスタイルのアクトカードを追加。<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.23準拠へ。ハンターズムーンの特技指定表を追加。<br>
・データ転送字のGZIP圧縮をデフォルト無効に<br>
<br>
2010/11/29 Ver.1.28.10<br>
・ハンターズムーンの命中部位表の誤字修正<br>
・カードの拡大表示部を表示位置・サイズ変更できるように改良。<br>
・FirstCGI環境でも動作が可能となるようconfig.rbにオプション追加。<br>
・Ruby1.9環境に対応。<br>
<br>
2010/11/15 Ver.1.28.09<br>
・カードを伏せた時にカードテキストの引用が出来ないように改良。<br>
・URLアップローダー機能を削除。どどんとふ動作サーバ以外のURL引用は×印と差し替えるように機能制限<br>
<br>
2010/11/13 Ver.1.28.08<br>
・キャラクター移動時のデータ管理をVer.1.27以前のものに差し戻し。<br>
・「カード置き場」を「手札置き場」と名前変更。<br>
・山札からのカード抜き取り字の告知メッセージを修正。<br>
・カードを伏せた時に背面で上下がバレないように改良<br>
<br>
2010/10/09 Ver.1.28.07<br>
・ロード機能が正しく動作しない障害を修正。<br>
<br>
2010/10/09 Ver.1.28.06<br>
・ファイルのアップローダー機能が一部環境で正しく動作しない障害を修正。<br>
<br>
2010/10/06 Ver.1.28.05<br>
・ファイルのアップローダー機能を追加。チャットウィンドウの右端アイコンから実行。<br>
　サーバを設置する人は実施前にfileUploadSpaceディレクトリに権限を忘れずに与えること。<br>
・チャットパレットでCtrl+左右キーでタブ移動した際に左右を循環するように改善。<br>
・不要なデバッグログを削除。<br>
<br>
2010/10/06 Ver.1.28.04<br>
・Ver1.28.00以前のリプレイデータを再生できない障害を修正。<br>
・チャットパレットでCtrl+左右キーでタブの移動を可能に<br>
・チャットパレットで発言文字の色指定を可能に（デフォルトの白の場合はチャットと同じ色に）<br>
<br>
2010/10/01 Ver.1.28.03<br>
・ログイン画面で選択プレイルームがマウス移動だけで変更されてしまう障害を解消。<br>
・画像のタグ名が長すぎる場合にタグ欄が表示しきれない障害を解消。<br>
<br>
2010/09/30 Ver.1.28.02<br>
・不要なデバッグログを削除。（指摘ありがとう飯綱さん！！）<br>
・ログイン画面のプレイルームメンバー表示タイミングを改善<br>
<br>
2010/09/26 Ver.1.28.01<br>
・画像削除時に縮小画像だけが削除され、オリジナルファイルが残る障害を修正。（指摘ありがとう飯綱さん！！）<br>
・サーバからの応答データを軽量化。<br>
・密かに暫定対応していたGoogleWave関連のファイルを削除。さらばGoogleWave。<br>
・サーバ応答のGZIP圧縮の指定を src_ruby/config.rb に追加。<br>
・削除させたくないプレイルームの指定を src_ruby/config.rb に追加。<br>
<br>
2010/09/14 Ver.1.28.00<br>
Ver.1.27.04をベースに安定版を開発コード「NON-FICTION」としてリリース<br>
<br>
2010/09/05 Ver.1.27.04<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.22準拠へ。ゲヘナ・アナスタシアへ対応。<br>
<br>
2010/08/31 Ver.1.27.03<br>
・カードゾーンへのカード譲渡時の表示メッセージ誤りを修正。<br>
・投票・点呼で参加人数よりも呼数が少ない場合にチェック画面を自動で閉じるように改善。<br>
・リプレイエディター機能に別セーブデータを追加できる「ロード挿入」ボタンを追加。<br>
・GZIP圧縮をMySQL版にも対応。<br>
<br>
2010/08/27 Ver.1.27.02<br>
・リプレイエディター機能にグリッド・座標文字の表示制御用の「設定挿入」ボタンを追加。<br>
・フロアパネルで縦横サイズを変えても画像が元の比率保持のままだった障害を修正。<br>
・CGIサーバの応答をGZIP圧縮することで転送効率アップ。（ちんみーさんありがとう！）<br>
<br>
2010/07/31 Ver.1.27.01<br>
・ダイスボットにヒロインジェネレータ追加。「make heroine」「make heroine?」でランダム作成。<br>
・ダイスボットにエムブリオマシン、パラサイトブラッド追加。<br>
・ダイスボットにダイス目・達成値に(1+2)D6<=(3*2-1)のように計算入力可能に。C(計算式）で四則演算も可能に。（例：C(6/2*3)）<br>
・カードを個別ロード時の選択条件に追加。<br>
<br>
2010/07/25 Ver.1.27.00<br>
Ver.1.26.07をベースに安定版を開発コード「Idea」としてリリース<br>
<br>
2010/07/25 Ver.1.26.07<br>
・ダイスボットのアースドーンが正しく動かなかった障害を修正。<br>
・MySQL版で不要なログを出力していた箇所を修正。<br>
<br>
2010/07/21 Ver.1.26.06<br>
・ダイスボットにアースドーン追加。akamanbowさんFacelessさんありがとぅ！！<br>
・チャットログ保存時に「メイン」「雑談」を選択できるように機能追加。<br>
・チャットの入力中にCtrl+左右カーソルキーで「メイン」「雑談」のタブ切り替えを可能に。<br>
・チャットの入力中にCtrl+上下カーソルキーで発言履歴を表示するように改造。<br>
・キャラクターの回転角度にヘクス用に左右に少しだけ回転するメニューを追加。<br>
・アラーム機能にタイマー指定を追加。<br>
・チャットのURL文字列にリンク開く機能を追加。<br>
・ログイン画面の更新日時が正しく表示されなかった障害を修正。<br>
<br>
2010/07/04 Ver.1.26.05<br>
・プレイルーム作成に失敗する不具合を修正。<br>
・ログイン時に雑談タブに不要なメッセージが表示される不具合を修正。<br>
<br>
2010/07/03 Ver.1.26.04<br>
・カードに山札から任意のカードを抜き取れる機能を追加。山札の右クリックメニューから実行可能。<br>
・カードに手札置き場機能を追加。カード用マット（緑のフィールド）上で右クリックから作成可能。<br>
・トランプ画像を変更。<br>
・ロード時の一部対象選択に共有メモを追加。<br>
・セーブ・ロード時にルーム名やパスワードも対象とするように改造。<br>
・ダイスシンボルロール時にビジュアルダイスが非表示だとダイスが表示されない問題点を改善。<br>
・セーブデータロード時にチャットログも全文ロードでき、その際カットイン等が暴発しないように改良。<br>
<br>
2010/06/15 Ver.1.26.03<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.19準拠へ。ダイスロールが正しく動作しない障害を修正。<br>
・ダイスボットに特命転校生を追加。<br>
<br>
2010/06/14 Ver.1.26.02<br>
・データベース（MySQL）利用版が正常に起動できない問題に対応。<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.18準拠へ。迷宮キングダムに対応。<br>
・フォントサイズ変更時に正しいサイズで表示されない障害を修正。<br>
<br>
2010/06/12 Ver.1.26.01<br>
プレイルームのデータ管理方法にデータベース（MySQL）を利用可能に。従来どおりの使用も可能です。<br>
サーバ設置する方は「<a href='#dodontoFSettingMySQL'>設置方法その２：MySQLサーバ編</a>」「<a href='#howToCheckSetting'>動作確認方法</a>」を参考に設定行ってください<br>
<br>
2010/06/09 Ver.1.26.00.01<br>
Ver.1.26.00に開発途中機能が混入していたため修正版をリリース。<br>
<br>
2010/05/29 Ver.1.26.00<br>
Ver.1.25.03をベースに安定版を開発コード「Ashiato Rhythm」としてリリース<br>
<br>
<br>
2010/05/23 Ver.1.25.03<br>
・リプレイ再生時にカードを表示できるように右上にボタン追加。<br>
・ログイン画面に現在の総ログイン人数の表示を追加。<br>
・画像選択画面に選択番号・表示件数の表示を追加。<br>
・カード操作時にマップ同様に立ち絵が非表示になるように変更。<br>
・リプレイ再生時に雑談チャットを表示しないように修正。<br>
・録画時のログに雑談チャットを含めないように修正。<br>
・フロアタイル配置時に出ていたログを削除。<br>
<br>
2010/05/11 Ver.1.25.02<br>
・チャットにメイン・雑談と複数チャットを可能に。<br>
・ガンメタル・ブレイズのシチュエーションカードにラバーズストリート対応版を追加。<br>
・魔法タイマーの時間切れでイニシアティブ表の行背景が灰色になるよう改良。<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.17準拠へ。シノビガミ参の追加シーンに対応。<br>
<br>
2010/05/08 Ver.1.25.01<br>
・簡易版モードを追加。 DodontoF.swf?mode=tiny で起動可能。<br>
・ビジュアルダイスの演出を変更。<br>
・ログイン直後のページめくり音を停止<br>
・チャット末尾文字列からサイズ指定のカットインを呼び出すと余分なカットインが表示される障害を修正。<br>
<br>
2010/04/04 Ver.1.25.00.01<br>
Ver.1.25.00に立ち絵が追加できない障害があったため修正版作成。<br>
<br>
2010/03/31 Ver.1.25.00<br>
Ver.1.24.03をベースに安定版を開発コード「everywhere」としてリリース<br>
<br>
<br>
2010/03/30 Ver.1.24.03<br>
・サイズの小さい画像アップロード時にタグ名・パスワードが消えてしまう障害を修正。<br>
・同一名称の立ち絵を追加した場合に追加されないように処理修正。<br>
・立ち絵更新時に状態名選択がリセットされないように改善。<br>
・画像一覧が表示に失敗する障害を修正。<br>
<br>
2010/03/27 Ver.1.24.02.01<br>
・サムネイル一括作成時にタグ名・パスワードが消える障害を修正。<br>
・コマ移動時に移動エフェクトを追加。<br>
・コマ設置時に移動エフェクトが発動しないよう修正。<br>
<br>
2010/03/27 Ver.1.24.02<br>
・フロアタイル設置機能を追加。「マップ」→「フロアタイル変更モード」を選択。<br>
・共有メモ機能を追加。画面上部の「共有メモ」ボタンを押して作成。<br>
・サムネイル画像の削除機能追加。<br>
<br>
2010/03/17 Ver.1.24.01<br>
・ログイン時のメッセージ抑止を修正。ログアウトメッセージも抑止へ。<br>
・動作検証用のcustomBot.htmlを修正<br>
・画像の一覧表示に縮小画像（サムネイル）を表示するようにし、処理を軽量化。<br>
【★重要】ダウンロードユーザー必見！【超重要★】<br>
以下に、「どどんとふ」をダウンロードしてサイトに設置しているユーザーには大事なお知らせがあります。<br>
必ず読んでください。必ずです。<br>
サムネイル画像作成にあたり、
　imageUploadSpace (ディレクトリ)<br>
の配下に
　imageUploadSpace/smallImages<br>
というディレクトリを追加してください。（今回の媒体参照）<br>
また追加したディレクトリの書き込み権限をimageUploadSpaceと同じに設定してください。<br>
設定が完了し、どどんとふをバージョンアップしたら既存の画像に対するサムネイルを作成するために<br>
(あなたのどどんとふへのURL)/DodontoF.swf?createSmallImage=on<br>
というパスでどどんとふを起動して下さい。<br>
後は画面の支持に従って下さい。<br>
<br>
2010/03/01 Ver.1.24.00<br>
Ver.1.23.10をベースに安定版を開発コード「光の人」としてリリース<br>
<br>
<br>2010/03/01 Ver.1.23.10<br>
・TORGドラマデッキNo.117の誤字を修正。<br>
・ログイン時のメッセージ抑止を src_ruby/coonfig.rb の $isWelcomeMessageOn として追加。<br>
<br>
2010/02/18 Ver.1.23.09<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.16準拠へ。ハンターズムーンに対応。<br>
・キャラクター移動時のエフェクトを削除（キャラクター追加時にエラーが発生する場合があるため）<br>
<br>
2010/02/16 Ver.1.23.08<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.15準拠へ。TORGに対応。<br>
・チャットログのHTML保存時の改行を改善<br>
・ダイスボットの乱数を改善<br>
・キャラクター移動時にエフェクトを追加。<br>
・キャラクターの向き表示機能を削除。以降は画像の回転で代用ください。<br>
<br>
2010/01/29 Ver.1.23.07<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.13準拠へ。ソード・ワールド2.0で運命変転やクリティカルレイに対応。<br>
・立ち絵のデフォルトをサイズ調整をデフォルトに。またマウス上載せで非表示しないように変更。<br>
・ダイスボットに不具合があったため、Choiseコマンドを未サポートへ差し戻し。<br>
<br>
2010/01/28 Ver.1.23.06<br>
・ダイスボットコマンドに Choise[A,B,C] を追加対応。<br>
・ダイス文字の後ろに全角空白入れての発言でロールされない障害を修正。<br>
<br>
2010/01/25 Ver.1.23.05<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.12準拠へ。ナイトウィザードに対応。<br>
・ログイン画面でユーザー名を変更可能に。<br>
・チャットパレットから発言者名・状態を変更可能へ。<br>
・立ち絵をマップ操作時の邪魔にならないように、チャットウィンドウ上を操作しているときのみ表示に変更。<br>
・「立ち絵のサイズを自動調整する」のデフォルトをOFFへ変更。<br>
<br>
<br>
2010/01/17 Ver.1.23.04<br>
・立ち絵に口パク機能を追加。立ち絵の状態名に「（他の状態名）@speak」と設定すると発言時に立ち絵が切り替わります。<br>
・プレイルームの名前／パスワードを変更できるように機能追加。画面上部の「ルームNo.x」ボタンから起動。<br>
・チャットパレットを改善(ありがとう超小兎さん！)。行をクリックで発言欄にコピー。ダブルクリックするとそのまま発言。<br>
・ダイスボットをボーンズ＆カーズ Ver.1.2.10準拠へ。ガンドッグ・ゼロの各種表に対応。<br>
・立ち絵の位置を変更した場合に、位置変更前の画像が残る障害を修正。<br>
・サーバ処理を高速化。<br>
<br>
<br>
2010/01/06 Ver.1.23.03<br>
ダイスボットをボーンズ＆カーズ Ver.1.2.9準拠。ダークブレイズのクリティカル判定を修正。<br>
また判定用ダイスボット表記に以下を追加。<br>
判定　(DBx,y#m) (DB@x@y#m) (x:能力値, y:技能値, m:修正)<br>
<br>
2010/01/05 Ver.1.23.02<br>
ダイスボットをボーンズ＆カーズ Ver.1.2.8準拠に更新。ダークブレイズに対応。<br>
ダイスボット表記は以下の通り（OD Tools準拠）<br>
判定　(DBxy#m) (x:能力値, y:技能値, m:修正)<br>
掘り出し袋表　(BTx)　　(x:ダイス数)<br>
<br>
2009/12/27 Ver.1.23.01<br>
「魔法タイマー追加」画面のイニシアティブ値に現状値が正しく設定されない障害を修正。<br>
簡易マップ作成にペンの太さ指定を追加。<br>
ダウンロード媒体へ基本添付する画像データを追加。なぎさん、斗之さん、ありがとう！<br>
<br>
2009/12/05 Ver.1.23.00<br>
Ver.1.22.03をベースに安定版を開発コード「RGB」としてリリース<br>
<br>
2009/12/05 Ver.1.22.03<br>
チャットで長い行数を送信するとスクロールが追随しない問題に対応。<br>
<br>
2009/11/21 Ver.1.22.02<br>
プレイルームで101番以上の数値が指定できなかった障害を修正。<br>
魔法範囲の枠を削除し表示を簡素化。<br>
ログアウトをファイルメニューにも追加。<br>
<br>
2009/11/19 Ver.1.22.01<br>
メニューの「マップ」に「マップマップ状態保存」「マップ切り替え」を追加。マップとマップマスクのみを差し替えて、マップを切り替えます。<br>
「ファイルアップローダー」でFLVファイルもアップロード可能に（サイズ上限10M）。ただし使えるのはカットインのみ。<br>
イニシアティブ表のカウンター変更時に正しく更新されない障害に対応。<br>
<br>
2009/10/17 Ver.1.22.00<br>
Ver.1.21.04をベースに安定版を開発コード「Schwarzschild」としてリリース<br>
<br>
2009/11/10 Ver.1.21.04<br>
ダイスボットを「ボーンズ＆カーズ」Ver1.2.6対応に更新。シノビガミ弐のシーン表を追加。<br>
ダイスボットの出力の「＞」を「→」に差し替え<br>
<br>
2009/11/06 Ver.1.21.03<br>
SWFファイルをキャラクターに指定した際に右クリックメニューが動かない障害を修正。<br>
キャラクター画像の縦横比を維持して拡大するように改善。<br>
キャラクター画像の背景色を透明に変更。<br>
<br>
2009/11/02 Ver.1.21.02<br>
イニシアティブ表から魔法タイマーが変更・削除できない問題を解消。<br>
　イニシアティブ表下部に変更／削除ボタン追加。
　墓地ボタンを追加。イニシアティブ表からドラッグすると削除可能。<br>
<br>
2009/10/30 Ver.1.21.01<br>
イニシアティブ表を大幅に改良。<br>
キャラクターデータに汎用のカウンターを追加（現状、編集はイニシアティブ表からのみ対応）<br>
<br>
2009/10/17 Ver.1.21.00<br>
Ver.1.20.08をベースに安定版を開発コード「WhiteAlbum」としてリリース<br>
<br>
2009/10/16 Ver.1.20.08<br>
ボーンズ＆カーズVer.1.2.5に対応。T&amp;Tのバーサークに対応<br>
マップマーカーの背景塗りつぶしで文字表示する際に文字をサイドカットするように改善<br>
<br>
2009/10/07 Ver.1.20.07<br>
点呼／投票機能を追加(チャットのアイコンから実行)<br>
カード捨て札をシャッフルせずに山に戻すメニューを追加。<br>
URLの末尾に DodontoF.swf?loginRoom=2 のように追記することでプレイルーム選択をパスしてログインできるように改善<br>
横に倒したカードを捨て札から戻せない障害を修正。<br>
縮小表示したカードを捨て札　から取り出せない障害を修正。<br>
<br>
2009/09/29 Ver.1.20.06<br>
ダイスボットをボーンズ＆カーズ Ver.1.2.3にバージョンアップ。サタスペとアスルマギカに対応。<br>
ダイスボット入力時の [x,y] を 「ｘ、ｙ」 と入力可能に機能拡張。<br>
立ち絵が外部URL指定時に表示されなかった障害を修正。<br>
画像削除画面にタグ名フィルタ機能を追加。<br>
カードのテキスト引用時に正位置、逆位置を表示。上下両用カードの場合は上になっているテキストを先に。<br>
立ち絵の無いキャラクターの発言で表示中の立ち絵が非表示にならないように修正。<br>
<br>
2009/09/25 Ver.1.20.05<br>
一部プロバイダーで正しく動作しなかった障害を修正。<br>
<br>
2009/09/24 Ver.1.20.04<br>
サタスペ用ダイスボットを仮実装<br>
10-1d6のようなダイスが後ろになる算術に対応<br>
FireFoxで応答エラーが多発する問題を暫定対処。<br>
チャットのフォントサイズ・色が保持されない問題を対処。<br>
<br>
2009/09/24 Ver.1.20.03<br>
欠番<br>
<br>
2009/09/13 Ver.1.20.02<br>
リプレイデータ投稿機能が実装未完了のまま公開されていたため削除。<br>
カード記載テキストをチャット上に出力する機能を「右クリックメニューから発言箇所にテキストを貼り付ける」に変更。<br>
イニシアティブ表クリック時と「次へ」実施時ににキャラクターを画面中央に設定していたのを取り止め。ダブルクリックで中央表示するように変更。<br>
<br>
2009/09/11 Ver.1.20.01<br>
カットインのファイル指定にYoutubeのURLを指定可能に。<br>
処理軽量化のために、モーダルウィンドウ（他のウィンドウが操作出来ないよう半透明のフィルタが掛かる）を停止。<br>
チャットHTMLログ保存時にHTMLの各行に改行を追加。<br>
カードダブルクリック時にカード記載テキストをチャット上に（自分にだけ）出力するように機能追加。<br>
ダイスボットでの全角->半角変換に「−」記号も対応。<br>
<br>
2009/09/04 Ver.1.20.00<br>
Ver.1.19.04をベースに安定版 Ver.1.20.00 を開発コード「Grapefruit」としてリリース<br>
<br>
2009/09/04 Ver.1.19.04<br>
カードを上下以外に左右にも回転できるように機能追加。<br>
<br>
2009/09/03 Ver.1.19.03<br>
キャラクターを右クリックメニューから回転可能に。<br>
ログオフ時に録画終了が実施されるように機能追加。<br>
同じ名前のキャラクターを追加時にはエラーメッセージを表示するように改善<br>
<br>
2009/08/24 Ver.1.19.02<br>
一部プロバイダで上手く動かない障害を修正。<br>
ログインユーザー確認画面にプレイルーム名を表示するように機能追加。<br>
ダイスボットの全角対応に＜,＞,＝の記号を追加。<br>
キャラクター追加・変更画面のデザインを修正。<br>
マップのキャラクタークリック時にイニシアティブ表の説明箇所がスクロールして表示されるように改善。<br>
<br>
2009/08/15 Ver.1.19.01<br>
秘話機能を実装。チャットウィンドウの鍵型アイコンを押すと送信先設定が出来ます。（自分以外ログインしていないなら選択できません）<br>
ダブルクロス用の感情表を実装（ETと入力でポジティブとネガティブの両方を振って、表になっている側に○を付けて表示）<br>
ダイスボット文字列が全角でも使用できるように改善<br>
一部環境(Linuxの64bit版Flash)で乱数に偏りがあったため乱数算出方法を変更。<br>
<br>
2009/08/05 Ver.1.19.0<br>
Ver.1.18.5をベースにVer.1.19.0、開発コード「HoneyDawn」としてリリース<br>
<br>
2009/08/04 Ver.1.18.5<br>
「ノベルゲーム風表示」の表示条件を「チャットウィンドウにマウスカーソルがある場合」に変更。（表示されていると通常操作が重くなるため）<br>
<br>
2009/08/02 Ver.1.18.4<br>
チャット受信時の自動スクロールを改善<br>
「ノベルゲーム風表示」時にチャットウィンドウ上でホイールを操作することでログがスクロールするように機能改善。<br>
「ノベルゲーム風表示」ボタンの位置を左端に変更。実行時に確認画面を出すように変更。<br>
<br>
2009/07/26 Ver.1.18.3<br>
チャットウィンドウの右端に「ノベルゲーム風表示」への切り替えボタンを追加。<br>
　チャットログをノベルゲームのログのようにマップ・立ち絵の前に透過して表示するようになります。<br>
　マウスカーソルをログに乗せると非表示になります。<br>
　切り替えボタンの右隣の「自動ログ隠し」チェックを外すか、シフトキーもしくはCtrlキーを押しながらマウスカーソルを操作すれば非表示になりません。<br>
デモンパラサイトの衝動表のダイスボットで「新衝動表」「誤動作表」「ミュータント衝動表」の対応が抜けていたため追加。（それぞれnurge1, aurge2, murge3 の形式で発動）<br>
<br>
2009/07/24 Ver.1.18.2<br>
ダイスボットを「ボーンズ＆カーズ(bcdice.pl)」Ver.1.1.22対応に更新。ダブルクロス2nd,3rdに対応。<br>
デフォルトイラストに結城ユキさんのドワーフ娘を追加。<br>
<br>
2009/07/24 Ver.1.18.1<br>
カード画面の右クリックメニューに「メッセージカードの追加」コマンドを追加。<br>
　メッセージカードを通常のカード風に追加することができます。<br>
　削除はメッセージカードの右メニューから行います。<br>
チャットログの背景色が変更できなくなっていた障害を修正。<br>
<br>
2009/07/11 Ver.1.18<br>
Ver.1.17.1をVer.1.18、開発コード「POLAND」としてリリース<br>
<br>
2009/07/11 Ver.1.17.1<br>
メニューの「表示」に「キャラクターの向きを表示」を追加。<br>
立ち位置の違う立ち絵がある場合に、発言者以外を半透明にするよう処理変更。<br>
ダイスボットのシークレットダイスに対応。<br>
ダイスボットをボーンズ＆カーズ Ver.1.1.21ベースに更新。<br>
<br>
2009/07/05 Ver.1.17<br>
セーブデータのロード時にマップやキャラクターと一部対象のみに選択出来るように機能追加。<br>
マップマーカー上にキャラクターがいる場合に上下に展開して表示するよう機能追加。<br>
立ち絵表示時の左右位置を変更できるように機能追加。<br>
カットインのBGMをボリューム調整できるように機能改善<br>
<br>
2009/06/27 Ver.1.16<br>
立ち絵のサイズが常に小さくなっていた障害を修正。<br>
<br>
2009/06/21 Ver.1.15<br>
チャットの動作を高速化（＜前バージョンでの記載忘れ）<br>
カットインの表示位置を画面上部、画面左右、どこに寄せるか指定できるように機能追加。<br>
簡易マップ作成画面で白地図の場合に表示できない障害を修正。<br>
<br>
2009/06/14 Ver.1.14<br>
画像ファイルのアップロードに失敗する障害を修正。<br>
リプレイ動画再生時に一時停止できない障害を修正。<br>
<br>
2009/06/12 Ver.1.13<br>
深淵の運命カードの背面の赤に対応。色味も修正。<br>
ダイスボットを「ボーンズ＆カーズ(bcdice.pl)」Ver.1.1.16ベースに更新。（シノビガミの戦場表(BT)に対応）<br>
カットイン動画の表示位置が高くなっていた障害を修正。<br>
<br>
2009/06/09 Ver.1.12<br>
ダイスボットを「ボーンズ＆カーズ(bcdice.pl)」Ver.1.1.16ベースに更新。（SWロールの修正とシノビガミ対応）<br>
リプレイエディターにHTML形式での保存機能を追加。<br>
<br>
2009/06/07 Ver.1.11<br>
深淵の運命カードを更新。運命カードの種類に夢魔の占い札対応版を追加。<br>
リプレイ再生時にチャットメッセージの読み飛ばし速度が狂っていた障害を修正。<br>
ビジュアルダイスをロール後、新規ダイスを追加すると以前のダイスの個数にさらに追加してしまう障害を修正。<br>
<br>
2009/06/05 Ver.1.10<br>
カードを上下で2分割し逆さまに文字を表示できるように機能拡張。(TORG、ガンメタルブレイズの表示を改善）<br>
<br>
2009/06/04 Ver.1.09<br>
カードにガンメタルブレイズのシチュエーションカードを追加。<br>
<br>
2009/06/03 Ver.1.08<br>
ダイスボットを「ボーンズ＆カーズ(bcdice.pl)」Ver.1.1.14ベースに更新。（ウォーハンマーロール修正対応）<br>
リプレイエディターで1行目のデータが消える障害を修正。<br>
ダイスロール時に立ち絵の指定文字が反映されるよう機能拡張。<br>
カットインにBGMの再生機能を追加。<br>
リプレイエディターに画像編集機能を追加。<br>
リプレイファイルをURLで指定時に開始場所を指定できるように機能追加。<br>
簡易マップ作成画面のプレビューを画面一杯に拡大できるように変更<br>
ダイスシンボルで隠したダイスではダブルクリックからのダイスロールが出来ないように修正。<br>
<br>
2009/05/28 Ver.1.07<br>
ダイスシンボルにダイス目を隠して設置するオプションを追加。<br>
画像ファイルが削除できない障害を修正。<br>
プレイルームが削除できない障害を修正。<br>
<br>
2009/05/23 Ver.1.06<br>
画像選択画面の表示を高速化（2回目以降の表示のみ）<br>
カットイン動画でボリュームを設定可能に。<br>
リプレイエディターで立ち絵表示にコマ画像も表示するように改良。<br>
<br>
2009/05/19 Ver.1.05<br>
リプレイエディターを追加。ログイン画面から「＞＞拡張機能」「リプレイエディター」で開いてください。<br>
あるいは、URLで DodontoF.swf?isReplayEditMode=true と指定しても開きます。（こちらの方が早い）<br>
キャラクター等の画像表示で無用な画像再読み込みをしている処理を修正。<br>
簡易マップ作成画面で、スポイト使用後に鉛筆に切り替わるように変更。また右クリックメニューにスポイト機能を追加。<br>
マップのマス目・座標文字の色をマップ変更画面から変更可能に。<br>
マップマーカーの色とメッセージを変更可能に。<br>
マップマスクの透明度を指定可能に。<br>
チャットの末尾にカットイン名を記載するとカットインが発動するように機能追加。<br>
<br>
2009/05/04 Ver.1.04.01<br>
ログイン画面での人数取得処理に障害があったため修正。<br>
<br>
2009/05/03 Ver.1.04<br>
リプレイモードに再生位置のシーク機能と一時停止機能を追加。<br>
リプレイモードで移動したキャラクターにマップを追随するように機能追加。<br>
ダイスボットで全角スペースもメッセージの区切りに使用できるように変更。<br>
ビジュアルダイスの表示場所をウィンドウサイズで固定に。<br>
カットインの画像URL入力をキャラクター作成等と同様に画像選択式に変更。ただしFLV動画は以前と同様、直接どこかにアップロードし、URLを入力する必要があります。<br>
「マップの下に隠す」をチェックするとログインしている他のユーザーでエラーが発生する障害を修正。<br>
カードの文字を読みやすいように改善。<br>
カード操作を軽量化。<br>
カード操作でブラウザが落ちやすい障害に対応。<br>
チャットパレットを複数タブ追加可能に拡張。<br>
<br>
2009/04/15 Ver.1.03.01<br>
リプレイモードの画面構成を修正。<br>
リプレイモードでキャラクターをドラッグできないように機能修正。<br>
<br>
2009/04/15 Ver.1.03<br>
マウスホイールでのマップの拡大・縮小判定範囲をマップ上だけで有効に変更。<br>
カードのプレビュー表示位置を画面右下から左上に変更。<br>
サーバとクライアント(Flash)のバージョン不一致チェックを追加。（Flashが最新版読み出しに失敗する場合用）<br>
ログイン画面の構成を変更。<br>
ビジュアルダイスに右クリックメニューとして「削除」を追加。<br>
ダイスシンボルをシンボルをダブルクリックでダイスロール可能に。<br>
<br>
2009/04/11 Ver.1.02<br>
ダイスの管理に使用する「ダイスシンボル」を追加。<br>
チャットが混雑時に欠落する問題に対応。<br>
<br>
2009/04/05 Ver.1.01.01<br>
ウィンドウサイズを変更するとエラーが発生する障害を修正。<br>
<br>
2009/04/05 Ver.1.01<br>
イニシアティブ表から直接キャラクターの「その他」情報を書き込めるように機能追加。<br>
マップ用マーカー(マップ上の目印。任意のメッセージを書き込める)を追加。<br>
キャラクター・魔法範囲の詳細情報をツールチップとして表示すように機能追加。<br>
上記に伴いキャラクター追加・変更画面の構成を変更。<br>
チャットの再送判定時間を調整<br>
<br>
2009/04/01 Ver.1.00<br>
祝、Ver1.00！！<br>
大々的に画面構成を変更し、一通りの動作確認を行ったのでバージョンを正式に1.00に。<br>
変更内容は以下の通り。<br>
画像にパスワードを付与し「隠し画像」にできるよう機能を追加。(パスワード管理方法は非常に簡易なため、過信せず重要なパスワードは使用しないようにしてください。)<br>
また上記に合わせて画像表示関連の画面構成を一新。<br>
アップロード画像のファイル名に日本語を使用した場合でもアップロード処理できるように機能修正<br>
<br>
2009/03/21 Ver.0.99.09<br>
マップマスクに変更画面を追加。<br>
キャラクターやマップの画像選択画面を軽量化。<br>
<br>
2009/03/20 Ver.0.99.08<br>
アップロードに失敗する場合がある障害を修正。<br>
マップマスクに名前表示機能を追加。<br>
<br>
2009/03/17 Ver.0.99.07<br>
チャット送信失敗時の再送機能を追加。（送信失敗時にはチャットログの下に失敗メッセージと再送ボタンが表示されます）<br>
<br>
2009/03/09 Ver.0.99.06<br>
コマと立ち絵が同じ名前の場合に正常に表示されない障害を修正。<br>
<br>
2009/03/07 Ver.0.99.05<br>
チャットの反映速度を改善。ただし方式を変更したため今までのチャットログは表示されなくなります。（今後は従来どおりログが蓄積されます。）<br>
<br>
2009/03/06 Ver.0.99.04<br>
マップマスク機能で「固定」が出来ない障害を修正。<br>
「セーブ」が実行できない障害を修正。これに伴い、saveDataTempSpaceディレクトリを追加。詳細はREADMEを参照。<br>
<br>
2009/03/02 Ver.0.99.03<br>
前回の表示状態保存で、ウィンドウを移動した場合の自動保存が失敗していたため修正。<br>
またプレイヤー名を保存するように保存対象を追加。<br>
<br>
2009/03/01 Ver.0.99.02<br>
表示情報を自動的に保存し、次回ログイン時に前回の状態へ戻すように機能追加。<br>
保持する情報は以下の通り<br>
　・ウィンドウの表示状態<br>
　・チャットの文字サイズ・色<br>
　・「表示」メニューのチェック全て<br>
またこれに伴い、「表示」メニューに「表示状態初期化」を追加。保持してある表示方法を全て破棄します。<br>
上記の保持情報で不具合があった場合（例えば画面サイズの関係でウィンドウが表示されなくなった場合等）に実行してください。<br>
「表示」メニューに「立ち絵のサイズを自動調整する」を追加。「立ち絵が自動で拡大・縮小されると絵が荒くなるのを避けたい」という要望があったので機能追加。<br>
<br>
2009/02/27 Ver.0.99.01<br>
画像の「タグ」フィルター機能を立ち絵画面、タグ編集画面にも追加。<br>
「タグ」フィルター関連のGUI配置を改良。<br>
<br>
2009/02/26 Ver.0.99<br>
各種ウィンドウに×ボタン（閉じるボタン）を追加。<br>
画像に「タグ」をつけられるように機能拡張。<br>
<br>
【★重要】ダウンロードユーザー必見！【超重要★】<br>
以下に、「どどんとふ」をダウンロードしてサイトに設置しているユーザーには大事なお知らせがあります。<br>
必ず読んでください。必ずです。<br>
上記の画像へのタグ付与対応に伴い、従来の画像ディレクトリ<br>
　saveData/characterImages (ディレクトリ)<br>
　saveData/mapImages (ディレクトリ)<br>
が無くなりました。削除してください。<br>
代わりに imageUploadSpace が出来ました。<br>
移行の際には、インストール手順に従い imageUploadSpace ディレクトリに権限を付与した後、今までのキャラクター、マップ画像をそれぞれ画像アップローダーでアップロードする方法をオススメします。<br>
また「<a href='#dodontoFSetting'>設置方法</a>」にセーブデータディレクトリの扱いについて追記がありますので、そちらもあわせて再読願います。<br>
<br>
<br>
2009/02/19 Ver.0.98.19<br>
へクスマップへの対応として、「表示」メニューに「マス目にキャラクターを合わせる」を追加。<br>
<br>
2009/02/15 Ver.0.98.18<br>
ブレード・オブ・アルカナのタロットに対応。<br>
マップのマス目を非表示にできるように機能追加。<br>
チャットでシフトかコントロールキーを押しながらリターンキーを押すと改行文字が入力できるように変更。<br>
チャットで文字の途中でリターンキーを押すと途中改行で送信されてしまう障害を修正。<br>
チャットのログ保存時に改行が正しく入らない障害を修正。<br>
<br>
2009/02/14 Ver.0.98.17<br>
キャラクターをマップマスクの下に隠す機能を追加（モンスターの事前配置用）。<br>
チャットの背景色を変更可能に。これに伴いチャットの文字設定関連を個別画面へ集約。<br>
カード機能に「全員に非公開でカードを引く」方法を追加。<br>
<br>
2009/02/11 Ver.0.98.16<br>
カードを上下反転できるように機能追加。<br>
チャットパレットにセーブ・ロード機能追加。<br>
チャットのログを上から下へ流れるように仕様変更。<br>
ログイン画面に参加者名を表示するように機能追加。<br>
ダイスボットで振ったダイスの目をデフォルトで常に全表示するように変更。<br>
SW2.0のダイスボットのクリティカル値省略時の値を10に変更。<br>
捨て札からのカードシャッフル時に正しくシャッフルされていなかった障害を修正。<br>
<br>
2009/02/05 Ver.0.98.15<br>
カード初期化方法を、任意のカードを組み合わせられるように変更。<br>
深淵の運命カードに対応<br>
<br>
2009/02/01 Ver.0.98.14.1<br>
新規作成プレイルームで「保存」機能が正しく動いていなかった障害の修正漏れを再修正。<br>
最終更新時刻から１分経過すればプレイルームが削除できるように仕様変更。<br>
<br>
2009/01/31 Ver.0.98.14<br>
チャットパレット機能を追加。<br>
デフォルトの表示マップを変更。<br>
バージョンロゴを変更。<br>
ダイスボットでSW2.0のクリティカル表示が正しく表示されない障害を修正。<br>
新規作成プレイルームで「保存」機能が正しく動いていなかった障害を修正。<br>
ダイスボット・ビジュアルダイスの乱数精度を向上。<br>
<br>
2009/01/24 Ver.0.98.13<br>
ダイスボットや定型文の事前登録用に「チャットパレット」を実装。「ビジュアルダイス」の下にボタンが追加されているので、それを押すとチャットパレットになります。<br>
<br>
2009/01/23 Ver.0.98.12.5<br>
チャットの文字サイズを変更できるように機能変更。<br>
アラームが鳴らない障害を修正。<br>
マップのサイズ変更しても座標表示が正しく更新されない障害を修正。<br>
<br>
2009/01/23 Ver.0.98.12.4<br>
ダイスボットでゲーム種別を選択しても設定が反映されない障害を修正。<br>
マップの座標を非表示状態でマップ画像を変更すると座標が再表示されてしまう障害を修正。<br>
ダイスボットの設定でPerlの判定を行う作業を不要に。<a href='#cgiServerSetting'>CGIサーバの用意</a>から不要となった作業を削除。(Facelessさんありがとう！)<br>
<br>
2009/01/18 Ver.0.98.12.3<br>
ダイスボットを＠Pages、land.toと言ったレンタルサーバで動くように.haccessを修正。<br>
上記に合わせ、各種サーバの設定方法を<a href='#cgiServerSetting'>CGIサーバの用意</a>に追記。<br>
<br>
2009/01/17 Ver.0.98.12.2<br>
チャットのテキスト出力が逆順になるバグがあったため修正。<br>
ログイン画面の「お知らせ」が表示されないバグがあったため修正。<br>
また、READMEの「<a href='#othersSetting'>その他</a>」にセーブデータのパス変更方法を追記。<br>
<br>
2009/01/17 Ver.0.98.12.1<br>
マップマスクがたまに消えてしまうバグを修正。<br>
リプレイ機能に早送りボタンを追加。URLからのリプレイファイル指定を追加。<br>
<br>
2009/01/12 Ver.0.98.12<br>
お試し用のログイン方法を追加。<br>
DodontoF.swf?isSampleMode=true にログインすると、自分一人だけがログインできるプレイルームを一時的に作成。<br>
このプレイルームは1時間以上操作が行われないと削除されます。<br>
立ち絵の表示／非表示設定をチャットのアイコンからメニューの「表示」へ変更。<br>
リプレイ機能の表示を変更。文字を大きくしヴィジュアルダイスウィンドウを非表示に。<br>
<br>
2009/01/09 Ver.0.98.11.8<br>
立ち絵の「状態」文字をチャットの末尾に記載することで状態を変更できるように。<br>
これでたとえばダイスボットで「自動成功」の文字があればクリティカル用の立ち絵を出す、といった小細工ができるようになります。<br>
また、SW2.0でダイスボットが自動成功・失敗を表示できるよう処理変更。<br>
<br>
2009/01/08 Ver.0.98.11.7<br>
サーバの更新チェックが切断された場合のチェック方式を変更。<br>
サーバとの接続エラーをチャットログではなくチャットウィンドウのステータス欄(ウィンドウタイトルの右横)に表示するように変更。<br>
チャットで改行キー押し続けで連続送信される問題を対処。また送信時に末尾の余分な改行を削除<br>
<br>
2009/01/07 Ver.0.98.11.6<br>
ダイスボットが広告挿入型のサーバで上手く動かない問題に対応。<br>
README.htmlの設置方法にファイルの権限について記載を追加。<br>
<br>
2009/01/06 Ver.0.98.11.5<br>
ダイスボットが一部のCGIサーバ(Perl5.8以上をサポート)で動作しない問題を修正。<br>
（上記に伴い、ダイスボットのCGIが変更になっています。サーバを自前で設置している人は「設置方法」を再確認してください。）<br>
キャラクターや魔法範囲の変更時のソースコードを整理。<br>
<br>
2009/01/01 Ver.0.98.11.4<br>
N◎VAのトランプを2組セットに変更。<br>
カードの公開・非公開をカードのフチの色で表示するように変更。<br>
カードの右クリックメニューを実行可能なものだけ表示するように変更。<br>
キャラクターの「その他」の1行目をキャラクター名に続けてマップ上に表示するように変更。<br>
<br>
2008/12/23 Ver.0.98.11.3<br>
カードを「山札」から引いて、「捨て札」に捨てるよう方式を変更。<br>
「捨て札」から「山札」へシャッフルしてカードを戻すこともできます。<br>
これでニューロデッキとトランプのシャッフルを個別に行うことができるようになりました。<br>
<br>
2008/12/23 Ver.0.98.11.2<br>
小さい画像のアップロードに失敗する障害を修正。<br>
<br>
2008/12/23 Ver.0.98.11.1<br>
カード表示に対応。デフォルトでは非表示なので「表示」＝＞「カード表示」を選択してください。<br>
現状ではN◎VAのニューロデッキとトランプ、それにTORGドラマデッキに対応しています。<br>
テキスト・画像を用意できれば任意に拡張が可能です。<br>
<br>
2008/12/19 Ver.0.98.10.2<br>
チャットのログ保存機能を高速化。ただしFlashPlayer10が必須のためその旨を表示するように変更。<br>
ダイスボットが小文字で 2d6 のように表記したときにロール結果が表示されないバグを修正。<br>
<br>
2008/12/19 Ver.0.98.10.1<br>
DD4th対応の魔法範囲の種別をメニューに追加。<br>
リプレイ機能の動作を軽くなるように修正。<br>
<br>
2008/12/17 Ver.0.98.9.1<br>
リプレイ機能を追加。<br>
画像アップローダーを複数ファイルの一括アップロードに対応。<br>
<br>
2008/12/12 Ver.0.98.8.2<br>
キャラクター／マップ画像ではSWFを使用不可能に。<br>
立ち絵で外部URL指定の場合は表示されない問題を修正。<br>
外部ファイルでのカットイン再生に対応するため明示的に幅・高さを指定できるように変更。<br>
<br>
2008/12/09 Ver.0.98.8.1<br>
立ち絵機能を追加。<br>
カットイン管理画面の構成を変更。<br>
カットインにFLVに加え静止画・SWFも使用可能に。<br>
キャラクター／マップ画像にもSWFを使用可能に。<br>
チャットの新着音(ページ送り音)を画面が非アクティブの場合のみ再生されるように機能変更。<br>
<br>
2008/12/05 Ver.0.98.7.19<br>
カットイン動画処理を登録・送信するよう処理変更。これに伴い静止画カットインを一時削除。<br>
Ruby実装の旧ダイスボット機能を削除し、Perlダイスボットに完全移行。<br>
チャットの送信処理を高速化。<br>
キャラクター重なり時の展開表示をサイズが2以上のキャラクターにも対応。<br>
ダイスボットを「ボーンズ＆カーズ(bcdice.pl)」Ver.1.1.3 へ以降し、クトゥルフテックに対応。<br>
<br>
2008/12/03 Ver.0.98.7.18<br>
READMEの記述を整理。<br>
<br>
2008/12/01 Ver.0.98.7.17<br>
キャラクターが同じ座標に重なった場合、少しずらして表示。またその状態でカーソルがキャラクターの上に来ると展開表示されるよう機能追加。<br>
ダイスボッツの有効・無効を設定できるようsrc_ruby/config.rb に $isDiceBotOn を追加。<br>
チャットウィンドウでのタブの移動順序が名前＝＞チャットメッセージ欄になるように変更。<br>
カットインの動画が正しい高さ・幅で表示されなかったバグを修正。<br>
<br>
2008/11/21 Ver.0.98.7.16<br>
ログアウトボタン追加（メインメニュー右端）。ログアウトすればルーム人数もその瞬間に更新されます。<br>
ログイン・ログアウト時には通知メッセージをチャットに表示するように変更。<br>
ダイスボット使用時に使用ゲームシステムを表示するように変更。<br>
<br>
2008/11/20 Ver.0.98.7.15<br>
ダイスボット機能修正。<br>
デフォルトはボット無しで、各ゲーム毎に特化する用選択可能に。<br>
各ゲーム毎の具体的は <u><a href="src_perl/readme_BC.txt">Facelessさんのボーンズ＆カーズのREADME</a></u>の「3.ボットの利用法」を参照してください。<br>
＃Facelessさん本当にありがとう！！<br>
ただしIRCボットとは以下の点が異なります。<br>
　・「４．カード機能」はサポートされていません。ダイスのみです。<br>
　・ダイス用の文字は文頭でのみ有効。<br>
たとえば、ソードワールド2.0であれば、<br>
「K20+1@9 攻撃！」のように行頭に「K(レート)+(修正)」と記載するとロールされます。（修正は省略可能)<br>
ロール文字列に続けて通常の文字も書けます。<br>
「攻撃！ K20+129」は無効です。<br>
文頭にスペースがある場合も無効になります。<br>
またダイス文字列と続く文字列の間には必ず半角スペースを入れてください。<br>
<br>
2008/11/19 Ver.0.98.7.14<br>
ソードワールド2.0用にダイスボットを設定<br>
<a href="http://faceless-tools.cocolog-nifty.com/blog/">Facelessさん</a>のIRC用ダイスボット「ボーンズ＆カーズ(bcdice.pl)」Ver.1.1.1を移植。<br>
チャットに「K(レーティング)[(クリティカル値)]+(修正値)」の書式を入力し、「DiceBot送信(SW2.0)」ボタンを押すと威力表のロール結果が出力されます。<br>
例）K20,K10+5,k30,k10+10,k10-1 k10+5+2<br>
K20[10],K10+5[9],k30[10],k10[9]+10<br>
注意：この機能をダウンロードした「どどんとふ」を元に自前のサーバで使用する場合は別途、<br>
src_perl/customBot.pl ファイルの先頭にPerlのパスを指定してください。<br>
<br>
2008/11/19 Ver.0.98.7.13<br>
動画のカットイン設定画面から設定項目を削減しシンプルに。<br>
<s>ソードワールド2.0用にダイスボットを設定</s>（バグがあったため差し戻し）<br>
<br>
2008/11/16 Ver.0.98.7.12<br>
カットイン動画をポップアップ方式へ変更。<br>
サーバとの通信速度を向上。（特にチャット、キャラクター移動時の応答）<br>
<br>
2008/11/15 Ver.0.98.7.11<br>
簡易マップ作成機能でマスが塗られない場合がある障害を修正。<br>
<br>
2008/11/15 Ver.0.98.7.10<br>
ログイン画面でソートすると正しいログインルームが選択されない障害を修正。<br>
ログイン中ユーザーがいてもプレイルームが削除できるように変更。<br>
簡易マップ作成機能でマップが白一色に染まる障害を修正。<br>
静止画カットインが正しく動かない障害を修正。<br>
<br>
2008/11/14 Ver.0.98.7.9<br>
プレイルームが常に削除できてしまう障害を修正。<br>
ログイン画面でパスワードのチェックボックスが操作できてしまう障害を修正。<br>
<br>
2008/11/14 Ver.0.98.7.8<br>
簡易マップ作成機能の出力がズレる障害を修正。<br>
ログイン画面の見た目を修正。<br>
<br>
2008/11/13 Ver.0.98.7.7<br>
初回ログイン時にパスワードを登録可能に。これで仲間内だけに公開する非公開プレイが可能になりました。<br>
誰もログインしていないで、最終更新から8時間が経過しているプレイルームを削除できるよう機能追加。<br>
各種登録画面のボタン配置をある程度統一。<br>
<br>
2008/11/09 Ver.0.98.7.6<br>
簡易マップがマップサイズ変更時に狂うバグを修正。<br>
ついでに簡易マップ画面にスポイト機能を追加。<br>
<br>
2008/11/09 Ver.0.98.7.5<br>
チャット、イニシアティブ表、ダイスの各ウィンドウをサイズ変更可能に。背景色も変更。<br>
アイコンを変更。<br>
<br>
2008/11/08 Ver.0.98.7.4<br>
ログイン画面で現在のログイン人数を表示するように機能追加。<br>
<br>
2008/11/08 Ver.0.98.7.3<br>
チャット、イニシアティブ表、ダイス、座標の表示・非表示制御をメニュー組み込みに変更。<br>
チャットの着信音をデフォルトOFFに。<br>
ログイン中のメンバーを確認できるようメニューバーにボタンを追加。<br>
<br>
2008/11/03 Ver.0.98.7.2<br>
チャット、イニシアティブ表、ダイスがチェックボックスで表示制御できなくなっていたバグを修正。<br>
<br>
2008/11/02 Ver.0.98.7.1<br>
マップの縦横幅指定が逆に設定されてしまうバグを修正。<br>
ロード機能が失敗する場合があるバグを修正。<br>
<br>
2008/11/01 Ver.0.98.7<br>
セーブ・ロードのロード機能が動作しなくなっていたバグを修正。<br>
ウィンドウ配置方法を根本から変更。（見た目にはあまり変わりません。）<br>
カットイン作成画面に「動画」作成用のタブを追加。<br>
任意のFLVファイル（ぶっちゃけニコニコ動画ファイル）の再生が可能です。<br>
サンプルは無音ですが音もなります。<br>
<br>
2008/10/30 Ver.0.98.6.7<br>
カットイン機能を強化。音を追加したりコマンドで再生可能にしたり。<br>
あと、チャットでのダイス機能を微妙に修正。<br>
<br>
2008/10/29 Ver.0.98.6.6<br>
カットイン機能を暫定追加。<br>
<br>
2008/10/28 Ver.0.98.6.5<br>
目覚まし機能を任意のMP3が鳴らせる「アラーム」コマンドへ拡張。<br>
<br>
2008/10/27 Ver.0.98.6.4<br>
画像アップローダーをFlashに統合<br>
<br>
2008/10/25 Ver.0.98.6.3<br>
READMEをHTML化<br>
<br>
2008/10/25 Ver.0.98.6.2<br>
目覚ましアラームの着信先を選択可能に。<br>
<br>
2008/10/25 Ver.0.98.6<br>
目覚ましボタンを追加。<br>
アラーム音は sound/alarm.mp3 固定。任意のMP3を上書きすることで音が変えられます。<br>
<br>
2008/10/24 Ver.0.98.5<br>
メニューの「ファイル」にセーブ＆ロード機能追加<br>
（もし表示されていない場合はリロードしてください）<br>
　マップやキャラクター等作成・変更するものはほぼ全てセーブされます。<br>
　別のプレイルームにロードすることもできます。<br>
魔法タイマーを変更してからリロードするとタイマーが消えてしまうバグを修正。<br>
<br>
2008/10/21 Ver.0.98.4.3<br>
イニシアティブ表をチェックボックスで非表示可能にできていなかったので修正。<br>
魔法タイマーを変更可能に。<br>
次回はセーブ＆ロード機能を実装予定。<br>
<br>
2008/10/20 Ver.0.98.4.2<br>
イニシアティブ表をチェックボックスで非表示可能に。<br>
<br>
2008/10/18 Ver.0.98.4<br>
「マップ」メニューに「簡易マップ作成」を追加。<br>
「マップ変更」で白地図を選ぶこともでるようになりましたので、マス目を色塗りするだけの簡易ダンジョンが作成できるようになりました。<br>
通信遅延に追加対応。<br>
<br>
2008/10/14 Ver.0.98.3<br>
障害物として、とりあえずマップマスクを流用しやすいようにマップマスクの作成方法を簡素化。<br>
色も付けられるように機能拡張。<br>
次回は白地図のマス目を着色するだけのお手軽なダンジョン作成画面を実装予定。<br>
<br>
2008/10/12 Ver.0.98.2<br>
キャラクター等の画像が存在しない場合にエラーを表示するよう修正。<br>
<br>
2008/10/10 Ver.0.98.1<br>
各入力画面の数値入力をスピンボックスへ変更。<br>
セーブデータに不正なキャラクターデータが混在した場合のエラー処理を追加。<br>
[ソースコード]単体テスト作成方法変更。これに伴いActionScriptコンパイル時のオプションを変更。<br>
<br>
2008/10/07 Ver.0.98.0<br>
BUG:「マウスを右クリックして魔法範囲の作成を指定した際に、その右クリックした場所に魔法範囲が現れない」を修正。<br>
魔法範囲の残りラウンドを変更可能に。<br>
魔法範囲で、円や円錐だけでなく、四角形を作成可能に。<br>
<br>
2008/10/06 Ver.0.97.9<br>
キャラクター移動など更新時に全キャラクターの画像がちらつく問題に対応。<br>
ウィンドウ周りの透過等、全体的構成を修正。<br>
・機能：魔法で、範囲ではなく時間のみ管理（ヘイストやエンラージパースン等にて使用）<br>
対応として「魔法タイマー」を追加。<br>
・BUG：魔法範囲を作成後、それに変更を加えると残りラウンドの表示が勝手に変わってしまう<br>
を修正。<br>
<br>
2008/10/05 Ver.0.97.8<br>
キャラクター追加方法をドラッグでの張り付けに変更。<br>
大量NPCにはこのほうが便利なはず・・・？<br>
<br>
2008/10/04 Ver.0.97.7<br>
通信の遅延にお試し対処<br>
<br>
2008/10/04 Ver.0.97.6<br>
ズーム時にキャラクターの座標が中央に来ないバグを修正。<br>
バージョン表記の飛び番を修正。<br>
ログイン画面の表示メッセージを loginMessage.txt で変更できるように。<br>
またログイン画面の構成を変更。<br>
<br>
2008/10/01 Ver.0.97.5<br>
Rubyソースコードのファイル構成を整理。これに伴いREADMEのファイル構成の記述を修正。<br>
マップマスクを墓場に送らないように修正。<br>
キャラクターをクリックでイニシアティブ表が、イニシアティブ表クリック時でキャラクターが点滅するよう機能追加。<br>
魔法範囲に残りラウンド数のカウント機能を追加。<br>
<br>
2008/09/27 Ver.0.97.4<br>
キャラクター画像の透明度を変更可能に。<br>
チャット・ダイス・座標文字の表示を非表示可能に。<br>
メニュー周りを変更。（キャラクター追加等のメニュー化)<br>
<br>
2008/09/26 Ver.0.97.3<br>
マップマスクを追加。<br>
WEBカメラ画像アップローダーを追加。<br>
画像削除時のデバッグログを削除。<br>
<br>
2008/09/22 Ver.0.97.2<br>
BMPファイルのような不正な画像が削除できない障害を修正。<br>
メニュー周りを変更。（ズームをアイコン化など）<br>
<br>
2008/09/22 Ver.0.97.1<br>
大々的に公開するべくREADMEやログイン画面等の見た目を修正。<br>
キャラクター作成時にマウス座標が微妙にずれる問題に対応。<br>
あと、この調子でバージョン上げると1.00に到達すると気づいたので細かく刻むことにする。<br>
<br>
2008/09/21 Ver.0.97<br>
アップロード画像の削除機能を追加。<br>
メニュー追加に伴いメニューバー周りを修正。<br>
<br>
2008/09/21 Ver.0.96<br>
マップの変更画面をリストからURL選択ではなく一覧からクリック選択に変更。<br>
「画像URLアップローダー」機能を追加。外部URLをローカル画像のように参照できるようにする機能です。<br>
イニシアティブ表の「変更」ボタンからキャラクター情報変更画面が開くようにイニシアティブ表の構成を大幅に変更。<br>
<br>
<br>
2008/09/19 Ver.0.95<br>
キャラクターの追加・変更画面で画像の設定をリストからURL選択ではなく一覧からクリック選択に変更。<br>
キャラクターの削除を高速化<br>
<br>
2008/09/08 Ver.0.94<br>
とりあえずHP上に公開。<br>
<br>
<br>
2008/09/06 Ver.0.93<br>
D100をD%100と名称変更。D100とD10を同時に振るように動作変更。(D100が00、D10が0なら値は0になります)<br>
チャット手打ちのダイスに＋−の修正値入力機能を追加。<br>
<br>
2008/09/03 Ver.0.92<br>
D100実装。<br>
ログ保存機能修正。<br>
<br>
2008/09/02 Ver.0.91<br>
すっかり忘れてたチャットのログ保存機能を追加。<br>
<br>
2008/09/01 Ver.0.90<br>
「どどんと」の機能もあらかた実装できたのでバージョン正式に付与。<br>
あとはD100を実装したり、細々とした変更を予定しています。<br>
<br>
2008/07/05 Ver.-.--<br>
「どどんとふ」仮作成開始。<br>
以前作った「どどんと」を4th対応の名の下軽量化を目指してFlashで再実装。<br>
名称は「新たなる開拓地を切り開く」という意味でFrontierを付与し、DnDMapFrontier略して「どどんとＦ」−＞「どどんとふ」となりました。<br>
・・・うそです。FlashのFです。あと上記の説明はマクロスＦ見ながらでっち上げました。<br>
