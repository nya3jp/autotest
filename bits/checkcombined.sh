#!/bin/sh

judge=$1

if [ -z "$judge" ] || [ -z "$MAKE" ]; then
    echo "this script should be called by make."
    exit 1;
fi

TIMELIMIT=60
# TIMELIMITが設定されていなければ落ちる
#if [ -z "$TIMELIMIT" ]; then
#    printf '\033[31mERROR: TIMELIMIT is not set!\033[0m\n'
#    exit 1
#fi

# JavaならTLEは2倍にしない?
#src=`$MAKE -C "$judge" -s src 2> /dev/null`
#case "$src" in
#*.java)
#    TIMELIMIT=`expr 2 '*' $TIMELIMIT`
#    ;;
#esac

## ulimitが使えない環境(cygwinおまえのことだ!!!)があるのでコメントアウト
#ulimit -St $TIMELIMIT > /dev/null 2>&1

# ジャッジ名に@を含むときは失敗を無視する
ignore_fail=false
echo "$judge" | grep '@' > /dev/null 2>&1 && ignore_fail=true

# 各種一時ファイル
tmptime="./tmp/checkcombined.time"
tmpout="./tmp/checkcombined.out"
tmpdiff="./tmp/checkcombined.diff"
tmpdet="./tmp/checkcombined.det"

# validateというスクリプトがあればそれでdiffる
if [ -f "./validate" ]; then
    if [ -x "./validate" ]; then
        validator="./validate"
    else
        validator="/usr/bin/perl ./validate"
    fi
fi

# 改行コードをネイティブに直すスクリプト
normcrlf=`dirname $0`/normcrlf.pl

# かかった最大の時間
maxtime='0'

# ulimitのかわりの動作を行うスクリプト
ulscript=`dirname $0`/judgetool.pl

infile=./tests.in
difffile=./tests.diff
atime=`"$ulscript" "$TIMELIMIT" $MAKE -C "$judge" -s run < $infile 2>&1 > $tmpout`
r=$?
if [ $r != 0 ]; then
    if [ $r = 143 ]; then
        printf ' \033[31mTLE!\033[0m\n'
    else
        printf ' \033[31mERROR!\033[0m\n'
    fi
    $ignore_fail
    exit
fi
maxtime=`echo "a=$maxtime;b=$atime;if(a<b){a=b};a" | bc`
eval "$normcrlf" < $tmpout > $tmpdiff
if [ -z "$validator" ]; then
    valcmd="diff -u $difffile $tmpdiff"
else
    valcmd="$validator $infile $difffile $tmpdiff"
fi
if eval $valcmd > $tmpdet 2>&1 && [ ! -s "$tmpdet" ]; then
    printf "PASSED"
else
    printf ' \033[31mFAILED!\033[0m\n'
    if [ "$ignore_fail" = "false" ]; then
        cat $tmpdet
    fi
    $ignore_fail
    exit
fi

printf ' \033[1m(%.2fsec)\033[0m\n' $atime

if $ignore_fail; then
    printf '\033[33mWARNING: this solution is not intended to pass the tests!\033[0m\n'
fi

