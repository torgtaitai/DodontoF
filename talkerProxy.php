<?php
$queryText = (isset($_POST['queryText']) && $_POST['queryText']) ? $_POST['queryText'] : 'undefined';
$url = "http://translate.google.com/translate_tts?tl=ja&q=" + $queryText;

$option = array(
    'http'=>array(
        'method'=>"GET",
        'header' => "User-Agent:Mozilla/5.5\r\n". //Mozilla‚ðŽw’è
                    "Content-type: application/x-www-form-urlencoded\r\n".
                    "Accept-Language: ja-jp,en;q=0.5\r\n".
                    "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7" ));
$context = stream_context_create($option);
$fp = fopen($url, 'r', false, $context);
fpassthru($fp);
fclose($fp);
?>
