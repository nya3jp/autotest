#!/bin/sh

# 改行コードをネイティブに直すスクリプト
normcrlf=`dirname $0`/normcrlf.pl

# ulimitのかわりの動作を行うスクリプト
ulscript=`dirname $0`/judgetool.pl

# makeからの呼び出しチェック
if [ -z "$MAKE" ]; then
    echo "this script should be called by make."
    exit 1;
fi

# TIMELIMITが設定されていなければ落ちる
if [ -z "$TIMELIMIT" ]; then
    printf '\033[31mERROR: TIMELIMIT is not set!\033[0m\n'
    exit 1
fi

# FIXME: Java時間? なにそれ?

# 解答の列挙
judges=
for m in ./*/Makefile; do
    judge=$(basename $(dirname $m))
    if echo "$judge" | grep '@' > /dev/null 2>&1; then
        continue
    fi
    if $MAKE -C "$judge" -s src > /dev/null 2>&1; then
        judges="$judges $judge"
    fi
done

# refjudgeの取得
refjudge=`$MAKE refjudge`

# 各種一時ファイル
tmptime="./tmp/compare.time"
tmpout="./tmp/compare.out"
tmpdiff="./tmp/compare.diff"
tmpdet="./tmp/compare.det"

# validateというスクリプトがあればそれでdiffる
if [ -f "./validate" ]; then
    if [ -x "./validate" ]; then
        validator="./validate"
    else
        validator="/usr/bin/perl ./validate"
    fi
fi

# ヘッダ出力
printf '%-12s' ''
for judge in $judges; do
    if [ "$judge" = "$refjudge" ]; then
        printf '%-12s' "$judge*"
    else
        printf '%-12s' "$judge"
    fi
done
echo

for index in `seq 1 99`; do
    infile=./tests/$index.in
    if [ -f $infile ]; then
        printf 'Case %2d:    ' $index
        difffile=./tests/$index.diff
        namefile=./tests/.$index.name
        for judge in $judges; do
            atime=`"$ulscript" "$TIMELIMIT" $MAKE -C "$judge" -s run < $infile 2>&1 > $tmpout`
            r=$?
            if [ $r != 0 ]; then
                if [ $r = 143 ]; then
                    printf '\033[31m%-12s\033[0m' 'TLE!'
                else
                    printf '\033[31m%-12s\033[0m' 'ERROR!'
                fi
            else
                eval "$normcrlf" < $tmpout > $tmpdiff
                if [ -z "$validator" ]; then
                    valcmd="diff -u $difffile $tmpdiff"
                else
                    valcmd="$validator $infile $difffile $tmpdiff"
                fi
                if eval $valcmd > $tmpdet 2>&1 && [ ! -s "$tmpdet" ]; then
                    printf '%-12s' 'PASSED'
                else
                    printf '\033[31m%-12s\033[0m' 'FAILED!'
                fi
            fi
        done
        if [ -f "$namefile" ]; then
            printf "# %s" `cat $namefile`
        fi
        echo
    fi
done

