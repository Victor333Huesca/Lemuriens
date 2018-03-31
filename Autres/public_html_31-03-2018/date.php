<?php

function currentDay(){
    $t = time();
    $d = date("d", $t);
    $m = date("m", $t);
    $a = date("Y", $t);

    $day = $d . "/" . $m . "/" . $a;

    return $day;
}

function currentHour(){
    $t = time();
    $m = date("i", $t);
    $h = date("H", $t);

    $hour = $h . ":" . $m;

    return $hour;
}

?>