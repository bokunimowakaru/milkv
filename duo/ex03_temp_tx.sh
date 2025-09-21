#!/bin/bash
################################################################################
# IoT Thermometer with Transmitter for Milk-V Duo
# This program sends the temperature value of Milk-V Duo via CSVxUDP and HTTP.
# ------------------------------------------------------------------------------
# IoT温度計 送信機 for Milk-V Duo
# Milk-V Duo の温度値をCSVxUDP方式とHTTP方式で送信するプログラムです。
#                                          Copyright (c) 2016-2025 Wataru KUNINO
################################################################################
# テスト方法
# 1. あらかじめPC上でudp_logger.pyを実行しておきます。
# 2. 下記のコマンドで本プログラムを実行します。
#       [root@milkv-duo]~/milkv/duo# bash ex03_temp_tx.sh
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
sensor="/sys/devices/virtual/thermal/thermal_zone0/temp" # CPUの温度センサ

# CSVxUDP送信の設定
udp_ip="192.168.42.255"                                 # CSVxUDP宛先IPアドレス
udp_port=1024                                           # CSVxUDP宛先ポート番号
device="temp0_5"                                        # CSVxUDP用デバイス名

# Ambient(https://ambidata.io/)へ Raspberry Piの温度データを送信する設定
AmbientChannelId=0                                      # チャネルID(Ambientで取得)
AmbientWriteKey="0123456789abcdef"                      # ライトキー(16桁・同上)
AmbientHost="54.65.206.59"                              # 送信先アドレス(変更不要)

while true;do                                           # 永久に繰り返し
    temp=`cat ${sensor}`                                # 温度を取得
    temp=$(( ${temp} / 100 - $temp_offset * 10 ))       # 温度に変換(10倍値)
    dec=$(( ${temp} / 10))
    temp=${dec}"."$(( ${temp} - ${dec} * 10))           # 少数に変換
    echo "Temperature = ${temp}"                        # 温度測定結果の表示

    # 温度値のCSVxUDP送信
    echo ${device}","${temp} | python udp_sender.py ${udp_port} ${udp_ip}

    # 温度値のAmbient送信
    if [[ ${AmbientChannelId} -ne 0 ]]; then
        data=\"d1\"\:\"${temp}\"                        # データ生成
        echo "send : Ambient {"${data}"}"
        json="{\"writeKey\":\"${AmbientWriteKey}\",${data}}" # JSON用のデータを生成
        curl -s ${AmbientHost}/api/v2/channels/${AmbientChannelId}/data\
             -X POST -H "Content-Type: application/json" -d ${json} # データ送信
    fi
    sleep ${interval}                                   # 測定間隔の待ち時間
done                                                    # 繰り返し

################################################################################
# 参考文献
################################################################################
# 下記からダウンロードしたものを Milk-V Duo 用に改変しました
#   https://github.com/bokunimowakaru/RaspberryPi/blob/master/network/ambient
#   temperature.sh
################################################################################
