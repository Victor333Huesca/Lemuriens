<?php
/*@author Rodriguez Julien
 *@brief fichier simulant le client 
 */

$_host    = "127.0.0.1";
$_port    = 1234;

/*@function sendTo
 *@param string $host l'adresse du serveur hote
 *@param int $port le port  
 *@param $data les données à transmettre
 *@return void
 */
function sendTo($host, $port, $data){
    $socket = socket_create(AF_INET, SOCK_STREAM, 0) or die("Erreur socket_create\n");
    $result = socket_connect($socket, "127.0.0.1", 1234) or die("Erreur socket_connect\n");  
    socket_write($socket, $data, strlen($data)) or die("Erreur socket_write\n");
    socket_close($socket);
}

/*@function simuleData
 *@param int $time le temps  d'attente (seconde) avant l'envoies d'une data générée aléatoirement
 *@param int $n nombre de données maximum à générer
 */
function simuleData($time, $n){
    $i = 0;
    $datas = "";
    while($i < $n){
        for($j=1; $j < 5; $j++){
            $datas .= strval(rand(5, 25)) . " ";
        } 
        echo $datas . "\n";
        sendTo("127.0.0.1", 1234, $datas);
        $datas = "";
        $i = $i + 1;
        sleep($time);
    }
}

simuleData(1, 20);
sendTo("127.0.0.1", 1234, "stop");


?>