#!/bin/sh

[ -z "$MAKE" ] && exit 1


# TIMELIMITが設定されていなければ落ちる
if [ -z "$TIMELIMIT" ]; then
    printf '\033[31mERROR: TIMELIMIT is not set!\033[0m\n'
    exit 1
fi
# TLEはTLE*3
DIFF_TIMELIMIT=`expr $TIMELIMIT '*' 3`

# 各種一時ファイル
tmpout=`mktemp ./tmp/checkone.XXXXXXXXXXXXX`
trap 'rm -f $tmpout' EXIT

# 改行コードをネイティブに直すスクリプト
normcrlf=`dirname $0`/normcrlf.pl

# ulimitのかわりの動作を行うスクリプト
ulscript=`dirname $0`/judgetool.pl

printf "generating diffs: "
for i in `seq 1 99`; do
    infile=./tests/$i.in
    difffile=./tests/$i.diff
    [ -f $infile ] || continue
    [ -f $difffile ] && {
        printf "($i)"
        continue
    }
    printf "[$i"
    eval $ulscript $DIFF_TIMELIMIT $MAKE -s run-one < $infile > $tmpout 2> /dev/null
    r=$?
    if [ $r != 0 ]; then
        if [ $r = 143 ]; then
            printf ' \033[31mTLE!\033[0m]\n'
        else
            printf ' \033[31mERROR!\033[0m]\n'
        fi
        exit 1
    fi
    eval "$normcrlf" < $tmpout > $difffile 2>&1
    [ -s "$difffile" ] || {
        printf ' \033[31mERROR!\033[0m]\n'
        exit 1
    }
    printf "]"
done
echo
