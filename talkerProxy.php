<?php

date_default_timezone_set('Asia/Tokyo');
mb_internal_encoding("UTF-8");
mb_regex_encoding('UTF-8');

$queryText = (isset($_POST['queryText']) && $_POST['queryText']) ? $_POST['queryText'] : 'undefined';

$url_replaced = $queryText;

if($url_replaced == 'undefined'){ print ''; exit; }

$url_replaced_decoded   = urldecode($url_replaced);

// 固有名詞置換
// Elysion関連
$url_replaced_decoded = preg_replace('/elysion/i', ' えりゅしおん ', $url_replaced_decoded);

$url_replaced_decoded = preg_replace('/「/ui', '・', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/」/ui', '・', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/^：(\d+) \((\d+D%*\d+).*/', ' だいすろーる・$2・合計・$1 ', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/^：+/ui', '', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/([^a-zA-Zａ-ｚＡ-Ｚ])[wｗ]+$/ui', '$1・わら ', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/([^a-zA-Zａ-ｚＡ-Ｚ])[wｗ]{2,}/ui', '$1・', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/[\.。．・…]{2,}/ui', '・', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/…/ui', '・', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/(ftp|http|https)\:\/\/.*/ui', '・$1のurlです・', $url_replaced_decoded);

// 辞書系
$url_replaced_decoded = preg_replace('/↑/ui', '・うえ・', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/↓/ui', '・した・', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/←/ui', '・ひだり・', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/→/ui', '・みぎ・', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/欠片/ui', 'かけら', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/SANチェック/ui', 'さんちぇっく', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/ＳＡＮチェック/ui', 'さんちぇっく', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/ktkr/ui', 'きたこれ', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/ｋｔｋｒ/ui', 'きたこれ', $url_replaced_decoded);
$url_replaced_decoded = preg_replace('/晶石/ui', 'しょうせき', $url_replaced_decoded);

//艦これ系
$url_replaced_decoded = preg_replace('/金剛/ui','こんごう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/陸奥/ui','むつ',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/雪風/ui','ゆきかぜ',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/蒼龍/ui','そうりゅう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/島風/ui','しまかぜ',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/白雪/ui','しらゆき',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/綾波/ui','あやなみ',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/鳳翔/ui','ほうしょう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/龍驤/ui','りゅうじょう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/文月/ui','ふみづき',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/川内/ui','せんだい',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/古鷹/ui','ふるたか',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/妙高/ui','みょうこう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/鳥海/ui','ちょうかい',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/飛鷹/ui','ひよう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/隼鷹/ui','じゅんよう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/初春/ui','はつはる',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/満潮/ui','みちしお',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/荒潮/ui','あらしお',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/不知火/ui','しらぬい',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/祥鳳/ui','しょうほう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/千歳甲/ui','ちとせこう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/千代田甲/ui','ちよだこう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/翔鶴/ui','しょうかく',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/瑞鶴/ui','ずいかく',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/三隈/ui','みくま',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/舞風/ui','まいかぜ',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/秋雲/ui','あきぐも',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/夕雲/ui','ゆうぐも',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/巻雲/ui','まきぐも',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/長波/ui','ながなみ',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/大鳳/ui','たいほう',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/深海棲艦/ui','しんかいせいかん',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/Bismarck/ui','びすまるく',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/zwei/ui','ツヴァイ',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/Верный/ui','べーるぬい',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/до/ui','だ',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/свидания/ui','すびだーにゃ',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/Ура+/ui','うらー',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/ypa+/ui','うらー',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/Хорошо/ui','はらしょー',$url_replaced_decoded);
$url_replaced_decoded = preg_replace('/Спасибо/ui','すぱしーば',$url_replaced_decoded);

// 通常取得
$url_replaced_decoded = mb_substr($url_replaced_decoded, 0, 256);
$url_replaced_reencoded = urlencode($url_replaced_decoded);
$url = 'http://translate.google.com/translate_tts?tl=ja&q='.$url_replaced_reencoded;

$option = array(
   	'http'=>array(
       	'method'=>"GET",
       	'header' => "User-Agent:Mozilla/5.5\r\n". //Mozillaを指定
                   	"Content-type: application/x-www-form-urlencoded\r\n".
                   	"Accept-Language: ja-jp,en;q=0.5\r\n".
                   	"Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7" ));
$context = stream_context_create($option);

$fp = @fopen($url, 'r', false, $context);
if($fp){
	fpassthru($fp);
	fclose($fp);
}


?>
