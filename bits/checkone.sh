#!/bin/sh

judge=$1

if [ -z "$judge" ] || [ -z "$MAKE" ]; then
    echo "this script should be called by make."
    exit 1;
fi

# TIMELIMITが設定されていなければ落ちる
if [ -z "$TIMELIMIT" ]; then
    printf '\033[31mERROR: TIMELIMIT is not set!\033[0m\n'
    exit 1
fi

# JavaならTLEは2倍
src=`$MAKE -C "$judge" -s src 2> /dev/null`
case "$src" in
*.java)
    TIMELIMIT=`expr 2 '*' $TIMELIMIT`
    ;;
esac

## ulimitが使えない環境(cygwinおまえのことだ!!!)があるのでコメントアウト
#ulimit -St $TIMELIMIT > /dev/null 2>&1

# ジャッジ名に_を含むときは失敗を無視する
# 20100123 svn1.6.5以降で@が特別な意味を持つため、_に変更した(野田)
ignore_fail=false
echo "$judge" | grep '_' > /dev/null 2>&1 && ignore_fail=true

# 各種一時ファイル
tmptime="./tmp/checkone.time"
tmpout="./tmp/checkone.out"
tmpdiff="./tmp/checkone.diff"
tmpdet="./tmp/checkone.det"

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

for index in `seq 1 99`; do
    infile=./tests/$index.in
    if [ -f $infile ]; then
        difffile=./tests/$index.diff
        namefile=./tests/.$index.name
        printf "[$index"
        atime=`"$ulscript" "$TIMELIMIT" $MAKE -C "$judge" -s run < $infile 2>&1 > $tmpout`
        r=$?
        if [ $r != 0 ]; then
            if [ $r = 143 ]; then
                printf ' \033[31mTLE!\033[0m'
            else
                printf ' \033[31mERROR!\033[0m'
            fi
            if [ -f $namefile ]; then
                printf '('`cat $namefile`')]\n'
            else
                printf ']\n'
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
            printf "]"
        else
            printf ' \033[31mFAILED!\033[0m'
            if [ -f $namefile ]; then
                printf '('`cat $namefile`')]\n'
            else
                printf ']\n'
            fi
            if [ "$ignore_fail" = "false" ]; then
                cat $tmpdet
            fi
            $ignore_fail
            exit
        fi
    fi
done

printf ' \033[1m(max real: %.2f)\033[0m\n' $maxtime

if $ignore_fail; then
    printf '\033[30;43mWARNING: this solution is not intended to pass the tests!\033[0m\n'
fi

