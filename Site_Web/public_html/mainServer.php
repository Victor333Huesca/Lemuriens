<?php
    include 'server.php';
    $hostname = "";
    $host = gethostbyname($hostname);
    $serv = new Server("127.0.0.1", 1234);
    $serv->work();

?>