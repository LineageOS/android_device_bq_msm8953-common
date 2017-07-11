#!/system/bin/sh

MemTotalStr=`cat /proc/meminfo | grep MemTotal`
MemTotal=${MemTotalStr:16:8}
((IsPremium=MemTotal>3145728?1:0))
if [ $IsPremium -eq 1 ]; then
    setprop sys.product.model_variant premium
else
    setprop sys.product.model_variant essential
fi

if [ -e /sys/bus/i2c/drivers/es9118-codec/6-0048 ]; then
        setprop sys.product.hifi hifi
else
        setprop sys.product.hifi no_hifi
fi

cat /sys/android_camera/sensor | \
while read line; do
    if [[ $line == *"imx298"* ]]; then
        setprop sys.product.rear_camera IMX298
    else
    if [[ $line == *"s5k2l7"* ]]; then
        setprop sys.product.rear_camera S5K2L7
      fi
    fi
done
