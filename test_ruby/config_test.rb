# -*- coding: utf-8 -*-
# テスト時用の設定群

$logFileName = "test_log.txt"
$SAVE_DATA_DIR = ".temp/save"
$SAVE_DATA_LOCK_FILE_DIR = nil
$imageUploadDir = ".temp/imageUploadSpace"
$replayDataUploadDir = ".temp/replayDataUploadSpace"
$saveDataTempDir = ".temp/saveDataTempSpace"
$fileUploadDir = ".temp/fileUploadSpace"

# 環境に依存しないようにするため gem の msgpack は使わない
$isMessagePackInstalled = false
