DFX=1 # Draw offset x
DFY=1 # Draw offset y

function setCursorPos(){ #(x, y)
    printf "\e[$(($2+$DFY));$(($1+$DFX))H"
}

function getTile(){ #(TILE_MAP, x, y)
    if (($2>=$WIDTH||$2<0||$3>=$HEIGHT||$3<0)); then
        retVar=" "
        return
    fi
    local -n ref_MAP=$1
    local line=${ref_MAP[$3]}
    retVar="${line:$2:1}"
}

function setTile(){ #(TILE_MAP, x, y, c)
    if (($2>=$WIDTH||$2<0||$3>=$HEIGHT||$3<0)); then
        return
    fi
    local -n ref_MAP=$1
    local line=${ref_MAP[$3]}
    ref_MAP[$3]="${line:0:$2}$4${line:$2+1}"
}

function repeatString(){ #(rep, n)
    retVar=""
    local i=0
    for ((;i<$2;i++)); do retVar="${retVar}$1"; done
    retVar="${retVar}";
}

function fillMinefield(){ #(MINEFIELD_NAME, w, h, c)
    repeatString $4 $2
    local -n ref_MAP=$1
    local i=0
    for ((;i<$3;i++)); do ref_MAP+=("$retVar"); done
}

function populateMinefield(){
    fillMinefield MINEFIELD $WIDTH $HEIGHT "0"

    local i=0
    local ncx=(-1 -1 -1  0  0  1  1  1)
    local ncy=(-1  0  1 -1  1 -1  0  1)
    for ((;i<$MINES;i++)); do
        while true; do
            local x=$(($RANDOM%$HEIGHT))
            local y=$(($RANDOM%$WIDTH))
            if (($x>=$PX-1&&$x<=$PX+1&&$y>=$PY-1&&$y<=$PY+1)); then continue; fi # Don't place mines next to guess

            getTile MINEFIELD $x $y
            local tile="$retVar"
            if [ $tile != "P" ]; then break; fi
        done
        setTile MINEFIELD $x $y P

        for ((n=0;n<8;n++)); do
            local mx=$(($x+${ncx[$n]}))
            local my=$(($y+${ncy[$n]}))
            getTile MINEFIELD $mx $my
            local tile="$retVar"
            if [[ $tile != " " ]] && [[ $tile != "P" ]]; then
                setTile MINEFIELD $mx $my "$(($tile+1))"
            fi
        done
    done
}

function chartFlag(){ #(x, y)
    getTile CHARTED $1 $2
    if [[ $retVar = "·" ]]; then
        if (($CHARTED_FLAGS<$MINES)); then
            setTile CHARTED $1 $2 P; CHARTED_FLAGS=$(($CHARTED_FLAGS+1))
        fi
    elif [[ $retVar = "P" ]]; then
        setTile CHARTED $1 $2 ·; CHARTED_FLAGS=$(($CHARTED_FLAGS-1))
    else return; fi
}

function chartTerritory(){ #(x, y)
    # Return if territory has already been charted

    getTile MINEFIELD $1 $2
    if [[ $retVar = "P" ]]; then 
        MISTAKES=$(($MISTAKES+1)); 
        CHARTED_TERRITORY=$(($CHARTED_TERRITORY-1));

        setTile CHARTED $1 $2 $retVar
    fi

    getTile CHARTED $1 $2
    if ! [[ $retVar = "·" || $retVar = "P" ]]; then return; fi

    getTile MINEFIELD $1 $2
    setTile CHARTED $1 $2 $retVar
    CHARTED_TERRITORY=$(($CHARTED_TERRITORY+1))

    if [[ $retVar = "0" ]]; then
        setTile CHARTED $1 $2 " "

        local ncx=(-1 -1 -1  0  0  1  1  1)
        local ncy=(-1  0  1 -1  1 -1  0  1)
        local n=0
        for ((;n<8;n++)); do
            local x=$(($1+${ncx[$n]}))
            local y=$(($2+${ncy[$n]}))

            getTile CHARTED $x $y
            if [[ $retVar = "P" ]]; then
                chartTerritory $x $y;
                CHARTED_FLAGS=$(($CHARTED_FLAGS-1))
            fi
            if [[ $retVar = "·" ]]; then 
                chartTerritory $x $y;
            fi
        done
    fi

    drawTile $1 $2
}

function drawColor(){ #(CHAR)
    if   [[ $1 = " " ]]; then printf $DARK_GRAY
    elif [[ $1 = "·" ]]; then printf "$UNDERLINE$DARK_GRAY"
    elif [[ $1 = "P" ]]; then printf $LIGHT_RED
    elif [[ $1 = "1" ]]; then printf $BLUE
    elif [[ $1 = "2" ]]; then printf $GREEN
    elif [[ $1 = "3" ]]; then printf $RED
    elif [[ $1 = "4" ]]; then printf $ORANGE
    elif [[ $1 = "5" ]]; then printf $PURPLE
    elif [[ $1 = "6" ]]; then printf $CYAN
    elif [[ $1 = "7" ]]; then printf $YELLOW
    elif [[ $1 = "8" ]]; then printf $PINK
    fi
}

function drawCursorTile(){ #(x, y)
    printf $NO_UNDERLINE
    getTile CHARTED $1 $2
    
    drawColor $retVar
    
    setCursorPos $(($1*2+1)) $(($2+1))
    printf "$ON_WHITE$retVar"
}

function drawTile(){ #(x, y)
    setCursorPos $(($1*2+1)) $(($2+1))
    printf $NC
    printf $NO_UNDERLINE
    getTile CHARTED $1 $2

    drawColor $retVar
    
    printf "$retVar"
}

function initGame(){
    source assets/colors.sh

    initRound

    GAME_STAGE=0
}

function initRound(){
    WIDTH=20
    HEIGHT=20
    MINES=$((($WIDTH*$HEIGHT)/5))
    SAFE_TERRITORY=$(($WIDTH*$HEIGHT-$MINES))
    CHARTED_TERRITORY=0
    CHARTED_FLAGS=0

    MISTAKES=0

    PX=$(($WIDTH/2))
    PY=$(($HEIGHT/2))
    
    MINEFIELD=( )
    
    CHARTED=( )
    fillMinefield CHARTED $WIDTH $HEIGHT "·"

    printf "$NC"
    clear
    repeatString "  " $WIDTH
    printf "$DARK_GRAY$UNDERLINE$retVar \n"
    repeatString "┃·" $WIDTH
    for ((i=0;i<$HEIGHT;i++)); do printf "$retVar┃\n"; done
}

function updateGame(){

    if (($GAME_STAGE==1)); then
        if (($CONGRATULATIONS>0)); then
            CONGRATULATIONS=$(($CONGRATULATIONS-1))
            return
        fi

        GAME_STAGE=0
        initRound
        return
    fi


    if (($CHARTED_TERRITORY==$SAFE_TERRITORY||$MISTAKES>0)); then
        GAME_STAGE=1
        CONGRATULATIONS=60
    fi

    drawTile $PX $PY

    PX=$((($PX+$KEY_X+$WIDTH)%$WIDTH))
    PY=$((($PY+$KEY_Y+$HEIGHT)%$HEIGHT))

    drawCursorTile $PX $PY

    printf $NC
    setCursorPos 0 $(($HEIGHT+1))
    printf "${LIGHT_RED}P${DARK_GRAY}: $(($MINES-$CHARTED_FLAGS))    "

    if [[ $KEY = "d" ]]; then
        if (($CHARTED_TERRITORY==0)); then
            populateMinefield
        fi
        getTile CHARTED $PX $PY
        if [[ $retVar = "·" ]]; then chartTerritory $PX $PY; fi
    fi

    if [[ $KEY = "f" ]]; then
        chartFlag $PX $PY
    fi
}