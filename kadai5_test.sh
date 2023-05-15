#!/bin/bash
# Test code for syspro2023 kadai5
# Written by Shinichi Awamoto and Daichi Morita
# Edited by PENG AO and Joe Hattori

state=0
warn() { echo $1; state=1; }
dir=$(mktemp -d)
trap "rm -rf $dir" 0

check-report() {
    if [ ! -f report-$1.txt ]; then
        $2 "kadai-$1: Missing report-$1.txt."
    elif [ `cat report-$1.txt | wc -l` -eq 0 ]; then
        $2 "kadai-$1: 'report-$1.txt' is empty!"
    fi
}

kadai-a() {
    if [ -d kadai-a ]; then
        cp -r kadai-a $dir
        pushd $dir/kadai-a > /dev/null 2>&1

        if [ ! -f Makefile ]; then
            warn "kadai-a: Missing Makefile"
        fi

        make myexec > /dev/null 2>&1

        if [ ! -f myexec ]; then
            warn "kadai-a: Failed to generate the binary(myexec) with '$ make myexec'"
        fi

        if [ ! -z `diff -q <(./myexec /bin/ls -l /var) <(ls -l /var)` ]; then
            warn "kadai-a: Diff detected."
        fi

        local out=__strace.txt
        strace -f ./myexec /bin/false 2> $out
        if [ `grep '^\[pid \+[0-9]\+\]' $out | wc -l` -eq 0 ]; then
            warn "kadai-a: Fork was not called."
        fi

        if [ `grep 'wait' $out | wc -l` -eq 0 ]; then
            warn "kadai-a: Wait was not called."
        fi

        rm -f $out

        make clean > /dev/null 2>&1

        if [ -f myexec ]; then
            warn "kadai-a: Failed to remove the binary(myexec) with '$ make clean'."
        fi

        if [ ! -z "`find . -name \*.o`" ]; then
            warn "kadai-a: Failed to remove object files(*.o) with '$ make clean'."
        fi

        if [ `grep '\-Wall' Makefile | wc -l` -eq 0 ]; then
            warn "kadai-a: Missing '-Wall' option."
        fi

        check-report a warn

        popd > /dev/null 2>&1
    else
        warn "kadai-a: No 'kadai-a' directory"
    fi
}

kadai-b() {
    if [ -d kadai-bcde ]; then
        cp -r kadai-bcde $dir
        pushd $dir/kadai-bcde > /dev/null 2>&1

        if [ ! -f Makefile ]; then
            warn "kadai-b: Missing Makefile"
        fi

        local shell=ish
        make $shell > /dev/null 2>&1

        if [ ! -f $shell ]; then
            warn "kadai-b: Failed to generate the binary($shell) with '$ make $shell'"
        fi

        local out=__output.txt
        export OSENSHU=__2023__
        script-b | ./$shell > $out
        local RET=$?
        if [ $RET -ne 0 ]; then
            warn "kadai-b: Exited with status $RET."
        fi

        grep -q "ECHOTEST1" $out || warn "kadai-b: Command failed '/bin/echo ECHOTEST1'"
        grep -q "ECHOTEST2" $out || warn "kadai-b: Command failed '/bin/echo ECHOTEST2'"
        grep -q "ECHOTEST3" $out || warn "kadai-b: Command failed '/bin/echo ECHOTEST3'"
        grep -q "__2023__" $out  || warn "kadai-b: Failed to read environement variables"

        unset OSENSHU
        rm -f $out

        make clean > /dev/null 2>&1

        if [ -f $shell ]; then
            warn "kadai-b: Failed to remove the binary($shell) with '$ make clean'."
        fi

        if [ ! -z "`find . -name \*.o`" ]; then
            warn "kadai-b: Failed to remove object files(*.o) with '$ make clean'."
        fi

        if [ `grep '\-Wall' Makefile | wc -l` -eq 0 ]; then
            warn "kadai-b: Missing '-Wall' option."
        fi

        check-report b warn

        popd > /dev/null 2>&1
    else
        warn "kadai-b: No 'kadai-bcde' directory"
    fi
}

script-b() {
cat << END
/bin/echo ECHOTEST1
/bin/echo ECHOTEST2
/bin/echo ECHOTEST3
/usr/bin/printenv OSENSHU
exit
END
}

kadai-c() {
    if [ -d kadai-bcde ]; then
        cp -r kadai-bcde $dir
        pushd $dir/kadai-bcde > /dev/null 2>&1

        if [ ! -f Makefile ]; then
            warn "kadai-c: Missing Makefile"
        fi

        local shell=ish
        make $shell > /dev/null 2>&1

        if [ ! -f $shell ]; then
            warn "kadai-c: Failed to generate the binary($shell) with '$ make $shell'"
        fi

        check-ish c1 "Failed to redicrect out"
        check-ish c2 "Failed to redicrect in"
        check-ish c3 "Failed to pipe"
        check-ish c4 "Failed to pipe large file"

        make clean > /dev/null 2>&1

        if [ -f $shell ]; then
            warn "kadai-c: Failed to remove the binary($shell) with '$ make clean'."
        fi

        if [ ! -z "`find . -name \*.o`" ]; then
            warn "kadai-c: Failed to remove object files(*.o) with '$ make clean'."
        fi

        if [ `grep '\-Wall' Makefile | wc -l` -eq 0 ]; then
            warn "kadai-c: Missing '-Wall' option."
        fi

        check-report c warn

        popd > /dev/null 2>&1
    else
        warn "kadai-c: No 'kadai-bcde' directory"
    fi
}

script-c1() {
cat << END
/usr/bin/wc -l /proc/meminfo > $out
/bin/true
/bin/false
/usr/bin/wc -l /proc/meminfo > $out
exit
END
}

script-c2() {
cat << END
/usr/bin/cut -d: -f1 < /proc/meminfo > $out
/bin/true
/bin/false
/usr/bin/cut -d: -f1 < /proc/meminfo > $out
exit
END
}

script-c3() {
cat << END
/usr/bin/cut -d: -f1 /proc/meminfo | /usr/bin/tr -d '\n' > $out
/bin/true
/bin/false
/usr/bin/cut -d: -f1 /proc/meminfo | /usr/bin/tr -d '\n' > $out
exit
END
}

script-c4() {
cat << END
/usr/bin/find /usr | /bin/cat > $out
exit
END
}

kadai-d() {
    if [ -d kadai-bcde ] && [ -f kadai-d.txt ]; then
        cp -r kadai-bcde $dir
        pushd $dir/kadai-bcde > /dev/null 2>&1

        if [ ! -f Makefile ]; then
            warn "kadai-d: Missing Makefile"
        fi

        local shell=ish
        make $shell > /dev/null 2>&1

        if [ ! -f $shell ]; then
            warn "kadai-d: Failed to generate the binary($shell) with '$ make $shell'"
        fi

        check-ish d1 "Failed to append"
        check-ish d2 "Failed to multiple pipes"

        make clean > /dev/null 2>&1

        if [ -f $shell ]; then
            warn "kadai-d: Failed to remove the binary($shell) with '$ make clean'."
        fi

        if [ ! -z "`find . -name \*.o`" ]; then
            warn "kadai-d: Failed to remove object files(*.o) with '$ make clean'."
        fi

        if [ `grep '\-Wall' Makefile | wc -l` -eq 0 ]; then
            warn "kadai-d: Missing '-Wall' option."
        fi

        check-report d warn

        popd > /dev/null 2>&1
    fi
}

script-d1() {
cat << END
/usr/bin/cut -d: -f1 /proc/meminfo | /usr/bin/tr -d '\n' > $out
/usr/bin/cut -d: -f1 /proc/meminfo | /usr/bin/tr -d '\n' >> $out
/usr/bin/cut -d: -f1 /proc/meminfo | /usr/bin/tr -d '\n' >> $out
/usr/bin/cut -d: -f1 /proc/meminfo | /usr/bin/tr -d '\n' >> $out
exit
END
}

script-d2() {
cat << END
/bin/cat < /proc/meminfo | /bin/cat | /bin/cat | /usr/bin/wc -l > $out
exit
END
}

kadai-e() {
    if [ -d kadai-bcde ] && [ -f kadai-e.txt ]; then
        cp -r kadai-bcde $dir
        pushd $dir/kadai-bcde > /dev/null 2>&1

        check-report e warn

        popd > /dev/null 2>&1
    fi
}

check-ish() {
    local shell=ish
    local script=script-$1
    local out=__output.txt
    local ans=__answer.txt

    $script | sh
    mv $out $ans
    if [ ! "$3" = "" ]; then
        $script | ./$shell > /dev/null 2>&1 &
        sleep 1
        disown -a
        pkill -Kill $shell
    else
        $script | ./$shell > /dev/null 2>&1
    fi

    diff -q $out $ans > /dev/null 2>&1 || warn "${FUNCNAME[1]}" "$2"
    rm -f $out $ans
}

if [ $# -eq 0 ]; then
    echo "#############################################"
    echo "Running tests..."
fi
for arg in {a..e}; do
    if [ $# -eq 0 ] || [[ "$@" == *"$arg"* ]]; then kadai-$arg; fi
done
if [ $# -eq 0 ]; then
    if [ $state -eq 0 ]; then echo "All tests have passed!"; fi
    echo "#############################################"
fi
exit $state
