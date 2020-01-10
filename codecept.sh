#!/bin/bash
function openFifo() {
    local fifoFilename=$$.fifo

    mkfifo ${fifoFilename}
    exec 254<>${fifoFilename}
    rm -rf ${fifoFilename}
}

function closeFifo() {
    exec 254>&-
}

#####################
# @param string $dir
# @param string $pattern
# @param string $skipList
# @param number $fid
########################
function batch() {
    local filename
    local dir=$1
    local pattern=$2
    local skipList=$3
    local fid=$4
    local pidsFilename=$$.pid
    local thread=10
    local i
    local status
    local ret=0

    for ((i = 0; i < ${thread}; i++)); do
        echo
    done >&${fid}

    for filename in $(find ${dir} -type f -name $pattern); do
        if grep -P "^${filename}\$" ${skipList} &>/dev/null; then
            continue
        fi

        read -u${fid} status
        if [ "${status}" == "stop" ]; then
            echo stop >&${fid}
            break
        fi
        _run ${filename} ${fid} ${pidsFilename} &
    done

    wait
    echo done >&${fid}
    rm -rf ${pidsFilename}
    while read -u${fid} status; do
        if [ "${status}" == "stop" ]; then
            ret=1
        elif [ "${status}" == "done" ]; then
            break
        fi
    done

    return $ret
}

######################
# @param string $filename
# @param number $fid
# @param string $pidsFilename
#######################
function _run() {
    local resultFilename=$!.unit.log
    local filename=$1
    local fid=$2
    local pidsFilename=$3
    local waitResult=0
    local status
    local pid

    echo ${filename}
    ./vendor/bin/codecept --no-colors run ${filename} &> ${resultFilename} &
    echo $! >>${pidsFilename}
    wait $! 2>/dev/null
    waitResult=$?
    sed -n "/$!/d" ${pidsFilename}
    if [ "${waitResult}" == "0" ]; then
        echo >&${fid}
    elif [ "${waitResult}" != "137" ]; then
        cat <${resultFilename}
        echo stop >&${fid}

        while read -u${fid} status; do
            if [ "$status" == "stop" ]; then
                echo stop >&${fid}
                break
            fi
        done

        while read pid; do
            kill -9 ${pid} 2>/dev/null
        done <${pidsFilename}
    else
        #        echo kill $!
        :
    fi

    rm -rf ${resultFilename}
}

###############
# @param string $list filename
###############
function runList() {
    local list=$1
    local filename
    local ret
    local resultFilename=$$.unit.log

    while read filename; do
        echo ${filename}
        ./vendor/bin/codecept --no-colors run ${filename} &>${resultFilename}
        ret=$?
        if [ "${ret}" != "0" ]; then
            cat <${resultFilename}
            break
        fi
    done <${list}

    rm -f ${resultFilename}
    return $ret
}

#####################
# @param number $ret
#####################
function result() {
    local ret=$1

    if [ "$1" == "0" ]; then
        echo "Codecept Success!"
    else
        echo "Codecept Has FAILURES!"
    fi
}

SCRIPT_PATH=$(cd $(dirname $0) && pwd)
FID=254
LIST_FILENAME=common/tests/runTestAlone
pushd . >/dev/null
cd ${SCRIPT_PATH}
openFifo
([ "$1" == "skip" ] || ./yii tool/bi/validate-database) && batch common/tests/unit "*Test.php" ${LIST_FILENAME} $FID && runList ${LIST_FILENAME}
ret=$?
result $ret
closeFifo
popd >/dev/null

exit $ret
