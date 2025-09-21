#!/usr/bin/env python3
# coding: utf-8

################################################################################
# HTTP サーバ + LED制御 for Milk-V Duo
#                                          Copyright (c) 2022-2025 Wataru KUNINO
################################################################################
# テスト方法
# 1.プログラムを開始するには下記のコマンドを入力します
#       [root@milkv-duo]~# python ex01_led_htserv.py
# 2.待ち受けIPアドレスとポート番号を確認してください。
#   初期値はIPアドレス＝192.168.42.1で、ポート番号＝8080です。
#       HTTP Server Started http://192.168.42.1:8080/
# 3.LEDを点灯する場合は、他のターミナルから下記のコマンドを入力します
#       [root@milkv-duo]~# curl http://192.168.42.1:8080/?L=1
#   制御できないときは、何度か試してください。
# 4.LEDを消灯する場合は下記です。
#       [root@milkv-duo]~# curl http://192.168.42.1:8080/?L=0
# 5.プログラムを停止するには[Ctrl]+[C]を押してください
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

import socket                           # ソケットの組み込み
from subprocess import run

# from pinpong.board import Board,Pin
# Board("MILKV-DUO").begin()            # Initialize, select the board type
# led = Pin(Pin.C24, Pin.OUT)           # The pin is initialized as output.

HTML="HTTP/1.0 200 OK\nContent-Type: text/html\nConnection: close\n\n<html>\n\
    <head>\n<title>LED制御</title>\n\
    <meta http-equiv=\"Content-type\" content=\"text/html; charset=UTF-8\">\n\
    </head>\n<body>\n<h3>LED制御</h3>\n\
    <form method=\"GET\" action=\"http://" + IP + ":" + str(PORT) + "/\">\n\
    Level = <input type=\"text\" size=\"1\" name=\"L\" >(0~1)\n\
    <input type=\"submit\" value=\"送信\">\n</form>\n</body>\n</html>\n\n\
"                                                           # HTTP+HTMLデータ

# メイン処理部 #################################################################
sock0 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)   # TCP用ソケット作成
sock0.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) # ポート再利用の許可
sock0.bind((IP, PORT))                                      # ソケットに接続
sock0.listen(1)                                             # 同時接続数=1
print("HTTP Server Started http://"+IP+":"+str(PORT)+"/")   # アクセス用URL表示

while True:
    (sock, sock_from) = sock0.accept()                      # アクセス待ち
    print(sock_from[0], sock_from[1])                       # アクセス元の表示
    tcp = sock.recv(1024)                                   # 受信データの取得
    sock.send(HTML.encode())                                # 応答メッセージ送信
    sock.close()                                            # ソケットの切断
    val=-1
    for line in tcp.decode().strip().splitlines():
        if line[0:6] == "GET /?":
            print("Recieved :",line)
            i = line.find("=")
            if i>0 and len(line) > i+2:
                try:
                    val=int(line[i+1:i+2])
                    print("Val =", val)
                except ValueError:
                    print("ERROR: ValueError")
            break
    if val>=0:
        run(["bash","led_ctrl.sh",str(val)])

################################################################################
# 参考文献
################################################################################
# 下記からダウンロードしたものを Milk-V Duo 用に改変しました
#   https://github.com/bokunimowakaru/tcp/blob/master/learning
#   ex4_http_srv.py
################################################################################
# GPIO制御部は下記のLED点滅用プログラムを参考にしました
#   https://milkv.io/ja/docs/duo/application-development/pinpong
#   blink.py
################################################################################
