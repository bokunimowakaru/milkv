#!/usr/bin/env python3
# coding: utf-8

################################################################################
# IoT Thermometer with HTTP Server for Milk-V Duo
# This program gets the temperature value of Milk-V Duo via HTTP.
# ------------------------------------------------------------------------------
# HTTP サーバ + IoT温度計 for Milk-V Duo
# HTTPで Milk-V Duo の温度値を取得するプログラムです。
# 温度値は誤差の多い目安値です。通信実験以外の目的では使用できません。
#                                          Copyright (c) 2022-2025 Wataru KUNINO
################################################################################
# テスト方法
# 1.プログラムを開始するには下記のコマンドを入力します
#       [root@milkv-duo]~/milkv/duo# python ex02_temp_htserv.py
# 2.待ち受けIPアドレスとポート番号を確認してください。
#   初期値はIPアドレス＝192.168.42.1で、ポート番号＝8080です。
#       HTTP Server Started http://192.168.42.1:8080/
# 3.温度値を取得したいときは、他のターミナルから下記のコマンドを入力します
#       [root@milkv-duo]~/milkv/duo# curl http://192.168.42.1:8080/val.txt
#   温度値の取得に成功すると以下のように表示されます。
#       Temperature = 23.9
#   取得できないときは、何度か試してください。
# 4.プログラムを停止するには[Ctrl]+[C]を押してください
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

HTML="HTTP/1.0 200 OK\nContent-Type: text/html\nConnection: close\n\n<html>\n\
    <head>\n<title>Thermometer</title>\n\
    <meta http-equiv=\"Content-type\" content=\"text/html; charset=UTF-8\">\n\
    </head>\n<body>\n<h3>Thermometer</h3>\n\
    <p>Temperature = #</p>\n\
    </body>\n</html>\n\n"                                   # HTTP+HTML応答電文
TEXT="HTTP/1.0 200 OK\nContent-Type: text/plain \nConnection: close\n\n\
    Temperature = #\n"                                      # HTTP+TXT応答電文
error="HTTP/1.0 404 Not Found\n\n"                          # Error時応答電文
sensor="/sys/class/thermal/thermal_zone0/temp"              # CPUの温度センサ

def temp():
    fp = open(sensor)                                       # 温度ファイルを開く
    temp = float(fp.read()) / 1000 - temp_offset            # 読み込み
    fp.close()                                              # ファイルを閉じる
    print('Temperature =',temp)                             # 温度を表示する
    return temp

# メイン処理部 #################################################################
import socket                                               # ソケットの組み込み
sock0 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)   # TCP用ソケット作成
sock0.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) # ポート再利用の許可
sock0.bind((IP, PORT))                                      # ソケットに接続
sock0.listen(1)                                             # 同時接続数=1
print("HTTP Server Started http://"+IP+":"+str(PORT)+"/")   # アクセス用URL表示

while True:
    (sock, sock_from) = sock0.accept()                      # アクセス待ち
    print(sock_from[0], sock_from[1])                       # アクセス元の表示
    tcp_rx = sock.recv(1024)                                # 受信データの取得
    tcp_tx = error                                          # 送信データ生成
    for line in tcp_rx.decode().strip().splitlines():
        if line[0:12] == "GET /val.txt":
            print("Recieved :",line)
            i = TEXT.find("#")
            tcp_tx = TEXT[0:i] + str(round(temp(),1)) + TEXT[i+1:]
            break
        elif line[0:5] == "GET /":
            print("Recieved :",line)
            i = HTML.find("#")
            tcp_tx = HTML[0:i] + str(round(temp(),1)) + HTML[i+1:]
            break
    sock.send(tcp_tx.encode())                              # 応答メッセージ送信
    sock.close()                                            # ソケットの切断

################################################################################
# 参考文献
################################################################################
# 下記からダウンロードしたものを Milk-V Duo 用に改変しました
#   https://github.com/bokunimowakaru/tcp/blob/master/learning
#   ex4_http_srv.py
#   https://github.com/bokunimowakaru/tcp/blob/master/learning/
#   lib_tempSensor.py
################################################################################
