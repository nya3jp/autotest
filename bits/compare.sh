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
acjudges=
wajudges=
for m in ./*/Makefile; do
    judge=$(basename $(dirname $m))
    # 20100123 svn1.6.5以降で@が特別な意味を持つため、_に変更した(野田)
    if echo "$judge" | grep '_' > /dev/null 2>&1; then
        if [ "`echo "$ALL" | cut -b 1`" = "y" ]; then
            wajudges="$wajudges $judge"
        fi
        continue
    fi
    if $MAKE -C "$judge" -s src > /dev/null 2>&1; then
        acjudges="$acjudges $judge"
    fi
done

width=8
for judge in $acjudges $wajudges; do
    w=`printf "%s" "$judge" | wc -c`
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
for judge in $acjudges; do
    printf "\033[1;32m%-${width}s\033[0m  " "$judge"
done
for judge in $wajudges; do
    printf "\033[1;33m%-${width}s\033[0m  " "$judge"
done
printf '| %-12s' 'Match'
echo
printf '%s' '--------+-'
for judge in $acjudges $wajudges; do
    yes - | head -n `expr $width + 2` | tr -d "\012"
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
    match=y
    dontcare=n
    for judge in $acjudges -- $wajudges; do
        if [ $judge = -- ]; then
            dontcare=y
            # 模範解答を準備
            eval "$normcrlf" < ./tmp/compare.judge.$refjudge.out > $tmprefdiff
            continue
        fi
        if [ $dontcare = y ] && [ $match = n ]; then
            printf "%-${width}s  " "  ---"
            continue
        fi
        atime=`"$ulscript" "$TIMELIMIT" $MAKE -C "$judge" -s run < $infile 2>&1 > ./tmp/compare.judge.$judge.out`
        r=$?
        if [ $r = 0 ]; then
            disptime=`printf '%5.2fs' $atime`
            if [ $dontcare = y ]; then
                eval "$normcrlf" < ./tmp/compare.judge.$judge.out > $tmpcurdiff
                if [ -z "$validator" ]; then
                    valcmd="diff -u $tmprefdiff $tmpcurdiff"
                else
                    valcmd="$validator $infile $tmprefdiff $tmpcurdiff"
                fi
                if eval $valcmd > $tmpdet 2>&1 && [ ! -s "$tmpdet" ]; then
                    printf "%-${width}s  " "$disptime"
                else
                    printf "\033[30;43m%-${width}s\033[0m  " 'WA'
                fi
            else
                printf "%-${width}s  " "$disptime"
            fi
        else
            errcolor="37;41"
            if [ $dontcare = y ] && [ $r = 143 ]; then
                errcolor="30;43"
            fi
            if [ $r = 143 ]; then
                printf "\033[${errcolor}m%-${width}s\033[0m  " 'TLE'
            else
                printf "\033[${errcolor}m%-${width}s\033[0m  " 'ERROR'
            fi
            if [ $dontcare = n ]; then
                match=n
            fi
        fi
    done

    printf '| '

    # 全て解答を出力したらdiffする
    if [ $match = y ]; then
        for judge in $acjudges; do
            eval "$normcrlf" < ./tmp/compare.judge.$judge.out > $tmpcurdiff
            if [ -z "$validator" ]; then
                valcmd="diff -u $tmprefdiff $tmpcurdiff"
            else
                valcmd="$validator $infile $tmprefdiff $tmpcurdiff"
            fi
            if eval $valcmd > $tmpdet 2>&1 && [ ! -s "$tmpdet" ]; then
                :
            else
                match=n
                break
            fi
        done
        if [ $match = y ]; then
            printf '\033[37;44m%s\033[0m    ' ' PASSED '
        else
            printf '\033[37;41m%s\033[0m    ' ' FAILED '
        fi
    else
        printf '%-10s  ' " ---"
    fi

    # 入力の名前があれば出力
    if [ -f "$namefile" ]; then
        printf "# %s" "`cat $namefile`"
    fi
    echo
done

