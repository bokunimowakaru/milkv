#!/bin/bash
################################################################################
# HTTP サーバ + IoT温度計 for Milk-V Duo
#                                          Copyright (c) 2017-2025 Wataru KUNINO
################################################################################
# テスト方法
# 1.プログラムを開始するには下記のコマンドを入力します
#       [root@milkv-duo]~# bash ./ex02_temp_htserv.sh
# 2.待ち受けIPアドレスとポート番号を確認してください。
#   初期値はIPアドレス＝192.168.42.1で、ポート番号＝8080です。
#       HTTP Server Started http://192.168.42.1:8080/
# 3.温度値を取得したいときは、他のターミナルから下記のコマンドを入力します
#   [root@milkv-duo]~# curl http://192.168.42.1:8080/val.txt
#   温度値の取得に成功すると以下のように表示されます。
#       Temperature = 23.9
#   取得できないときは、何度か試してください。
# 4.プログラムを停止するには[Ctrl]+[C]を押してください
#   止まらないときは下記を実行してください(他のbash処理も止まります)
#       [root@milkv-duo]~# kill `pidof bash`
################################################################################
# 応用①：インターネット・ブラウザで表示
# 本機にUSB接続したPCのインターネットブラウザからアクセスできます。
# Microsoft Edgeのアドレスバーに下記を入力してください。
#      http://192.168.42.1:8080/
################################################################################
# 応用②：リモート温度計
# Milk-V Duo にイーサネット端子を接続し、「IP='192.168.42.1'」をイーサネット用の
# IPアドレスに変更すると、LAN内の他のPCから温度値の取得ができるようになります
# インターネットブラウザでアクセスしてください。
################################################################################

IP='192.168.42.1'                       # 本機のIPアドレス
PORT=8080                               # 待ち受けポート番号
temp_offset=18                          # CPUの温度上昇値

sensor="/sys/devices/virtual/thermal/thermal_zone0/temp" # CPUの温度センサ

URL="http://"${IP}":"${PORT}
HTML="HTTP/1.0 200 OK\nContent-Type: text/html\nConnection: close\n\n<html>\n\
    <head>\n<title>Thermometer</title>\n\
    <meta http-equiv=\"Content-type\" content=\"text/html; charset=UTF-8\">\n\
    </head>\n<body>\n<h3>Thermometer</h3>\n\
    <p>Temperature = #</p>\n\
    </body></html>\n\n"                                     # HTTP+HTML応答電文
TEXT="HTTP/1.0 200 OK\nContent-Type: text/plain \nConnection: close\n\n\
    Temperature = #\n"                                      # HTTP+TXT応答電文
error="HTTP/1.0 404 Not Found\n\n"                          # Error時応答電文

mkfifo payload_tx                       # HTTPデータ送信用のパイプを作成
trap "rm -f payload_tx; exit" SIGINT    # Ctrl-Cでパイプ切断し、プログラムを終了

thermometer (){
    temp=`cat ${sensor}`                                # 温度を取得
    temp=$((temp / 100 - temp_offset * 10))             # 温度に変換(10倍値)
    int=$((temp / 10))                                  # 整数部
    dec=$((temp - int * 10))                            # 小数部
    echo ${int}"."${dec}                                # 温度測定結果の表示
}

payload_rx (){                          # HTTPリクエスト受信処理(レスポンス出力)
    while read tcp_rx; do                               # 標準入力から受信
        temp=`thermometer`
        HTTP=`echo -E ${tcp_rx}|cut -d"=" -f1`          # HTTPコマンドを抽出
        if [[ ${HTTP:0:12} == "GET /val.txt" ]]; then
            tcp_tx=`echo -e ${TEXT}|sed "s/#/${temp}/g"` # TEXTコンテンツ作成
            echo "${tcp_tx}"                            # TEXTコンテンツを出力
        elif [[ ${HTTP:0:5} == "GET /" ]]; then
            tcp_tx=`echo -e ${HTML}|sed "s/#/${temp}/g"` # HTMLコンテンツ作成
            echo "${tcp_tx}"                            # HTMLコンテンツを出力
        else                                            # 他の要求時にエラー出力
            echo -e ${error}
        fi
        sleep 0.1
        pid=`pidof nc`
        if [ $? -eq 0 ]; then
            kill $pid
        fi
    done
}

# メイン処理部 #################################################################
while true; do                                              # 繰り返し処理
    echo "HTTP Server Started http://"${IP}":"${PORT}"/"    # アクセス用URL表示
    sleep 0.1
    nc -l -v -s ${IP} -p ${PORT} < payload_tx| payload_rx > payload_tx
done                                                        # 繰り返しここまで

################################################################################
# 参考文献
################################################################################
# 下記からダウンロードしたものを Milk-V Duo 用に改変しました
#   https://github.com/bokunimowakaru/bash/blob/master/learning/
#   example15_temp.sh
#   example29_cam_http.sh
################################################################################
