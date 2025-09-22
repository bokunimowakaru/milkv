#!/bin/bash
################################################################################
# ★★★ このプログラムは Milk-V Duo 64MB ではリソース不足で動作しません ★★★
#  This program doesn't run on Milk-V Duo 64MB due to insufficient resources.
#  Please try this using 256MB board with V2 firmware.
################################################################################
# IoT Thermometer with CSVxUDP Transmitter for Milk-V Duo
# This program sends the temperature value of Milk-V Duo via CSVxUDP and HTTP.
# ------------------------------------------------------------------------------
# IoT温度計 送信機 for Milk-V Duo
# Milk-V Duo の温度値をCSVxUDP方式とHTTP方式で送信するプログラムです。
# 温度値は誤差の多い目安値です。通信実験以外の目的では使用できません。
#                                          Copyright (c) 2019-2025 Wataru KUNINO
################################################################################
# テスト方法
# 1. あらかじめPC上でudp_logger.pyを実行しておきます。
#       PS C:\Users\watt\milkv\duo> python udp_logger.py
# 2. 下記のコマンドで本プログラムを実行します。
#       [root@milkv-duo]~/milkv/duo# python ex03_temp_tx.sh
# 3. PC上のudp_logger.pyの実行画面に以下のような結果が表示されます。
#       NEW Device, temp0_5
#       2025/09/21 21:33, temp0_5, 192.168.42.1, 28.1 -> log_temp0_5.csv
################################################################################
# 応用①：リモート温度計
# Milk-V Duo にイーサネット端子を接続し、「udp_ip='192.168.42.1'」をイーサネット
# 用のブロードキャストIPアドレス(末尾255)に変更すると、温度値をブロードキャスト
# で送信します。LAN内のPC等でudp_logger.pyを実行すると受信できます。
################################################################################
# 応用②：インターネット上のクラウドサーバAmbientへ送信する
# Milk-V Duo にイーサネット端子を接続し、Ambient(https://ambidata.io/)でチャネル
# IDとライトキーを取得し、それぞれの値をAmbientChannelIdとAmbientWriteKeyに代入
# してください。本プログラムは、指定したAmbientのチャネルに温度値を送信します。
################################################################################

# 温度計の設定
temp_offset=18                                          # CPUの温度上昇値(要調整)
interval=30                                             # 測定間隔(1日3000件以下)
sensor="/sys/class/thermal/thermal_zone0/temp"          # CPUの温度センサ

# CSVxUDP送信の設定
udp_ip="192.168.42.255"                                 # CSVxUDP宛先IPアドレス
udp_port=1024                                           # CSVxUDP宛先ポート番号
device="temp0_5"                                        # CSVxUDP用デバイス名

# Ambient(https://ambidata.io/)へ HTTPで送信する設定
AmbientChannelId=0                                      # チャネルID(Ambientで取得)
AmbientWriteKey="0123456789abcdef"                      # ライトキー(16桁・同上)
AmbientHost="54.65.206.59"                              # 送信先アドレス(変更不要)
amdient_tag='d1'                                        # データ番号d1～d8

url_s = 'https://ambidata.io/api/v2/channels/'+str(AmbientChannelId)+'/data' 
head_dict = {'Content-Type':'application/json'}         # ヘッダをhead_dictへ
body_dict = {'writeKey':AmbientWriteKey, amdient_tag:0.0} # 内容をbody_dictへ

import socket                                           # ソケットの組み込み
import urllib.request                                   # HTTP通信ライブラリ
import json                                             # JSON変換ライブラリ
from time import sleep                                  # スリープの組み込み

def temp():
    fp = open(sensor)                                   # 温度ファイルを開く
    temp = float(fp.read()) / 1000 - temp_offset        # 読み込み
    fp.close()                                          # ファイルを閉じる
    print('Temperature =',temp)                         # 温度を表示する
    return temp

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) # ソケットを作成
sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST,1) # ブロードキャスト

while True:                                             # 繰り返し構文

    # 温度を取得する
    val = str(round(temp(),1))                          # 温度値を取得

    # 温度値のCSVxUDP送信
    udp = device + ',' + str(val) + '\n'                # 送信文字列を生成
    try:                                                # 例外処理の監視を開始
        sock.sendto(udp.encode(),(udp_ip,udp_port))     # UDP送信
    except Exception as e:                              # 例外処理発生時
        print(e,udp_ip,udp_port)                        # エラー内容と宛先表示
    print('send :', udp, end='')                        # 送信データを出力

    # 温度値のAmbient送信
    if AmbientChannelId != 0:
        body_dict[amdient_tag] = val                    # 温度値を送信電文に
        # print(head_dict)                              # 送信ヘッダhead_dictを表示
        print('> POST',body_dict)                       # 送信内容body_dictを表示
        post = urllib.request.Request(url_s, json.dumps(body_dict).encode(), head_dict)
                                                        # POSTリクエストデータを作成
        try:                                            # 例外処理の監視を開始
            res = urllib.request.urlopen(post)          # HTTPアクセスを実行
        except Exception as e:                          # 例外処理発生時
            print(e,url_s)                              # エラー内容と変数url_sを表示
            exit()                                      # プログラムの終了
        res_str = res.read().decode()                   # 受信テキストを変数res_strへ
        res.close()                                     # HTTPアクセスの終了
        if len(res_str):                                # 受信テキストがあれば
            print('Response:', res_str)                 # 変数res_strの内容を表示
        else:
            print('Done')                               # Doneを表示
    sleep(interval)                                     # 測定間隔の待ち時間
sock.close()                                            # 切断(実行されない)

################################################################################
# 参考文献
################################################################################
# 下記からダウンロードしたものを Milk-V Duo 用に改変しました
#   https://github.com/bokunimowakaru/iot/blob/master/learning
#   example09_ambient.py
#   https://github.com/bokunimowakaru/udp/blob/master/learning
#   ex3_tx_temp.py
#   lib_tempSensor.py
################################################################################
