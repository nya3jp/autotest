#!/bin/sh

[ -z "$MAKE" ] && exit 1

printf "generating tests: "

if [ ! -d "./tests-template" ]; then echo; exit; fi

normcrlf=`dirname $0`/normcrlf.pl

index=1
for i in `find ./tests-template -type f -name '*.in' | sort`; do
    cp -f "$i" tests/$index.in
    echo `basename "$i"` > tests/.$index.name
    prefix=`echo "$i" | sed 's/.in$//'`
    [ -f "$prefix.diff" ] && $normcrlf < "$prefix.diff" > tests/$index.diff
    [ -f "$prefix.out" ] && $normcrlf < "$prefix.out" > tests/$index.diff
    printf "[$index]"
    index=`expr $index + 1`
done
echo
