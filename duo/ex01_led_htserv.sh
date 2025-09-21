#!/bin/bash
################################################################################
# HTTP サーバ + LED制御 for Milk-V Duo
#                                          Copyright (c) 2017-2025 Wataru KUNINO
################################################################################
# GPIOポートを変更する場合は下記を参照ください
#   https://milkv.io/docs/duo/getting-started/duo#gpio-pinout
################################################################################
# テスト方法
# 1.プログラムを開始するには下記のコマンドを入力します
#   [root@milkv-duo]~# bash ./ex01_led_htserv.sh
# 2.待ち受けIPアドレスとポート番号を確認してください。
#   初期値はIPアドレス＝192.168.42.1で、ポート番号＝8080です。
#   HTTP Server Started http://192.168.42.1:8080/
# 3.LEDを点灯する場合は、他のターミナルから下記のコマンドを入力します
#   [root@milkv-duo]~# curl http://192.168.42.1:8080/?L=1
#   制御できないときは、何度か試してください。
# 4.LEDを消灯する場合は下記です。
#   [root@milkv-duo]~# curl http://192.168.42.1:8080/?L=0
# 5.プログラムを停止するには[Ctrl]+[C]を押してください
#   止まらないときは下記を実行してください(他のbash処理も止まります)
#   [root@milkv-duo]~# kill `pidof bash`
################################################################################
# 応用①：インターネット・ブラウザから制御
# 本機にUSB接続したPCのインターネットブラウザから制御できます。
# Microsoft Edgeのアドレスバーに下記を入力してください。
#      http://192.168.42.1:8080/
# Level = の欄に0または1を入力し、[送信]ボタンを押すとLEDを制御できます。
################################################################################
# 応用②：リモートLED制御
# Milk-V Duo にイーサネット端子を接続し、「IP='192.168.42.1'」をイーサネット用の
# IPアドレスに変更すると、LAN内の他のPCからLEDの制御ができるようになります
################################################################################

IP='192.168.42.1'                       # 本機のIPアドレス
PORT=8080                               # 待ち受けポート番号
LED_GPIO=440                            # GPIO C24の Port NUM

HTML="HTTP/1.0 200 OK\nContent-Type: text/html\nConnection: close\n\n<html>\n\
    <head>\n<title>LED制御</title>\n\
    <meta http-equiv=\"Content-type\" content=\"text/html; charset=UTF-8\">\n\
    </head>\n<body>\n<h3>LED制御</h3>\n\
    <form method=\"GET\" action=\"http://"${IP}":"${PORT}"/\">\n\
    Level = <input type=\"text\" size=\"1\" name=\"L\" >(0~1)\n\
    <input type=\"submit\" value=\"送信\">\n</form>\n</html>\n\n\
"                                       # HTTP + HTMLコンテンツ

pid=`pidof S99user`
if [ $? -eq 0 ]; then
    echo "kill "${pid}"(/etc/init.d/S99user)"
    kill $pid
fi
sleep 3
if [ -d /sys/class/gpio/gpio${LED_GPIO} ]; then
    echo "GPIO"${LED_GPIO} "already exported"
else
    echo -n "${LED_GPIO}" > /sys/class/gpio/export
fi
echo -n "out" > /sys/class/gpio/gpio${LED_GPIO}/direction
echo -n "0" > /sys/class/gpio/gpio${LED_GPIO}/value

trap "exit" SIGINT                      # Ctrl-Cでプログラムを終了

# メイン処理部 #################################################################
echo "HTTP Server Started http://"${IP}":"${PORT}"/"    # アクセス用URL表示
while true; do                                          # HTTP待ち受け
    sleep 0.1
    echo -e $HTML\
    |nc -l -v -s ${IP} -p ${PORT}\
    |while read tcp; do                                 # 受信データをtcpに代入
        DATE=`date "+%Y/%m/%d %R"`                      # 時刻を取得
        HTTP=`echo -E ${tcp}|cut -d"=" -f1`             # HTTPコマンドを抽出
        if [[ ${HTTP} == "GET /?L" || ${HTTP} == "GET /?" ]]; then
            echo -E $DATE, ${tcp}                       # 取得日時とデータを表示
            level=`echo -E ${tcp}|cut -d"=" -f2|cut -d" " -f1` # 値を取得
            if [[ ${level} < 0 || ${level} > 1 ]]; then # 値が範囲外の時
                level=0                                 # LEDを消灯
            fi                                          # if文の終了
            echo -n ${level} > /sys/class/gpio/gpio${LED_GPIO}/value # LED制御
        fi
        sleep 0.1
        pid=`pidof nc`
        if [ $? -eq 0 ]; then
            echo -n "kill "${pid}"(netcat) -> "
            kill $pid
        fi
done; done                                              # 繰り返しここまで

################################################################################
# 参考文献
################################################################################
# 下記からダウンロードしたものを Milk-V Duo 用に改変しました
#   https://github.com/bokunimowakaru/bash/blob/master/learning/
#   learning/example27_led3_http.sh
################################################################################
# GPIO制御部は下記のLED点滅用プログラムを参考にしました
#   https://github.com/milkv-duo/duo-buildroot-sdk/blob/develop/
#   device/milkv-duo-sd/overlay/mnt/system/blink.sh
################################################################################
