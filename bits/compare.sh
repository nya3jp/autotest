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
    if [ "`expr substr "$ALL" 1 1`" != "y" ] && echo "$judge" | grep '@' > /dev/null 2>&1; then
        continue
    fi
    if $MAKE -C "$judge" -s src > /dev/null 2>&1; then
        judges="$judges $judge"
    fi
done

width=8
for judge in $judges; do
    w=`expr \( length "$judge" \) + 2`
    if [ $w -gt $width ]; then
        width=$w
    fi
done

# refjudgeの取得
refjudge=`$MAKE refjudge`

# 各種一時ファイル
tmptime="./tmp/compare.time"
tmprefdiff="./tmp/compare.refjudge.diff"
tmpcurdiff="./tmp/compare.curjudge.diff"
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
printf '%-8s| ' 'Solution'
for judge in $judges; do
    printf "%-${width}s" "$judge"
done
printf '| %-12s' 'Match'
echo
printf '%s' '--------+-'
for judge in $judges; do
    yes - | head -n $width | tr -d "\012"
done
printf '+-----------'
echo

for index in `seq 1 99`; do
    # 入力の存在チェック
    infile=./tests/$index.in
    if [ ! -f $infile ]; then
        continue
    fi

    # ケース番号を出す
    printf 'Case %2d | ' $index
    difffile=./tests/$index.diff
    namefile=./tests/.$index.name

    # とりあえず実行してTLE/REをチェック
    match=true
    for judge in $judges; do
        atime=`"$ulscript" "$TIMELIMIT" $MAKE -C "$judge" -s run < $infile 2>&1 > ./tmp/compare.judge.$judge.out`
        r=$?
        if [ $r = 0 ]; then
            disptime=`printf '%5.2fs' $atime`
            printf "%-${width}s" $disptime
        else
            if [ $r = 143 ]; then
                printf '\033[31m%-12s\033[0m' 'TLE'
            else
                printf '\033[31m%-12s\033[0m' 'ERROR'
            fi
            match=false
        fi
    done

    printf '| '

    # 全て解答を出力したらdiffする
    if eval $match; then
        # 模範解答を準備
        eval "$normcrlf" < ./tmp/compare.judge.$refjudge.out > $tmprefdiff
        for judge in $judges; do
            eval "$normcrlf" < ./tmp/compare.judge.$judge.out > $tmpcurdiff
            if [ -z "$validator" ]; then
                valcmd="diff -u $tmprefdiff $tmpcurdiff"
            else
                valcmd="$validator $infile $tmprefdiff $tmpcurdiff"
            fi
            if eval $valcmd > $tmpdet 2>&1 && [ ! -s "$tmpdet" ]; then
                :
            else
                match=false
                break
            fi
        done
        if eval $match; then
            printf '%-12s' "PASSED"
        else
            printf '\033[31m%-12s\033[0m' 'FAILED'
        fi
    else
        printf '%-12s' "---"
    fi

    # 入力の名前があれば出力
    if [ -f "$namefile" ]; then
        printf "# %s" "`cat $namefile`"
    fi
    echo
done

