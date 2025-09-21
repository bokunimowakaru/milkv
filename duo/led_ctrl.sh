#!/bin/bash
################################################################################
# led_ctrl.sh for Milk-V Duo
# https://github.com/bokunimowakaru/milkv/blob/master/duo/
#
#                                               Copyright (c) 2025 Wataru KUNINO
################################################################################
# GPIOポートを変更する場合は下記を参照ください
#   https://milkv.io/docs/duo/getting-started/duo#gpio-pinout
################################################################################

LED_GPIO=440                            # GPIO C24の Port NUM
val=1                                   # LED制御値

echo "Usage: "${0}" [0|1|on|off]"
if [[ ${#} > 0 ]]; then                 # 引数が1個以上の時
    if [[ ${1} == "0" || ${1} == "1"  ]]; then
        val=${1}                        # valに値を代入
    elif [[ ${1} == "on" || ${1} == "ON"  ]]; then
        val=1                           # valに値を代入
    elif [[ ${1} == "off" || ${1} == "OFF"  ]]; then
        val=0                           # valに値を代入
    fi
fi                                      # 条件文ifの処理の終了

pid=`pidof S99user`; if [ $? -eq 0 ]; then
    echo "kill "${pid}"(/etc/init.d/S99user)"
    kill $pid
fi
sleep 0.1

if [ ! -d /sys/class/gpio/gpio${LED_GPIO} ]; then
    echo -n "${LED_GPIO}" > /sys/class/gpio/export
fi
echo -n "out" > /sys/class/gpio/gpio${LED_GPIO}/direction
echo -n "${val}" > /sys/class/gpio/gpio${LED_GPIO}/value

echo "Done"

exit

################################################################################
# 参考文献
################################################################################
# GPIO制御部は下記のLED点滅用プログラムを参考にしました
#   https://github.com/milkv-duo/duo-buildroot-sdk/blob/develop/
#   device/milkv-duo-sd/overlay/mnt/system/blink.sh
################################################################################
