# Behaviour: https://gameinternals.com/understanding-pac-man-ghost-behavior
# Example Proj: https://github.com/diejuse/bashblitz/blob/main/bashblitz.sh

function cleanup() {
    tput cnorm
    if [ -t 0 ]; then
    stty sane
    fi

    printf '\033[0m'
    clear
}

function hideinput()
{
  if [ -t 0 ]; then
     stty -echo -icanon time 0 min 0
  fi
}

function init(){
    read -r LINES COLUMNS < <(stty size)
    if ((COLUMNS<10 || LINES<10));then
    printf "Your terminal has $COLUMNS columns and $LINES lines.\nIt must have 57 or more columns and 31 or more lines to play this game.\n"
    exit; fi

    trap hideinput CONT
    hideinput
    tput civis
}

function key_input() {
    nextFrameTime=$(bc -l <<<"$nextFrameTime+$FRAME_TIME")
    timeNow=$(date +%s.%N)
    WAIT_TIME=$(bc -l <<<"$nextFrameTime-$timeNow")

    if (($(bc -l <<<"$WAIT_TIME<0"))); then
        WAIT_TIME=0
        nextFrameTime=$timeNow
    fi

    read -s -t $WAIT_TIME -n3 KEY 2>/dev/null >&2
    
    local ESC=$( printf "\033")
    
    KEY_X=0; KEY_Y=0
    if [[ $KEY = q ]]; then main_isRunning=0;    return; fi
    if [[ $KEY = $ESC[A ]]; then KEY_X=0;     KEY_Y=-1; fi
    if [[ $KEY = $ESC[B ]]; then KEY_X=0;     KEY_Y=1;  fi
    if [[ $KEY = $ESC[C ]]; then KEY_X=1;     KEY_Y=0;  fi
    if [[ $KEY = $ESC[D ]]; then KEY_X=-1;    KEY_Y=0;  fi;
}

function run(){
    source game.sh
    initGame

    timeNow=$(date +%s.%N)
    nextFrameTime=$timeNow

    FPS=30
    FRAME_TIME=$(bc -l <<<"1.0/$FPS")
    main_isRunning=1
    while (($main_isRunning==1)); do
        key_input
        updateGame
    done
}

function main(){
    init
    run
    cleanup
}

main