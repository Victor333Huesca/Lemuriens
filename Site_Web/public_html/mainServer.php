<?php
    include 'server.php';

    $serv = new Server("127.0.0.1", 1234);
    $serv->work();

?>