<?php
/*@author Rodriguez Julien
 *@brief fichier decrivant la classe server
 */

 include 'date.php';
 include 'parserJson.php';

/*@class server
 *@biref class server, gère les connexions entrantes et la reception de donnée(s) client
 */
class server
{
    private $socket;
    private $actualClient;
    private $clients;
    private $parser;

    /*@function constructeur
     *@param string $adress l'adresse de la socket
     *@param int $port le port de la socket
     *@brief construit une instance de la classe serveur
     */
    public function __construct($adress, $port){
        $this->parser = new parserJson();
	$t;
	$t[0] = "salle1";
	$t[1] = "salle2";
	$t[2] = "salle3";
	$t[3] = "salle4";
	$t[4] = "salle5";
        //$this->parser->setObjects("salle1", "salle2", "salle3", "salle4", "salle5");
	$this->parser->setObjects($t);

	// Create socket
        $this->socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
        if ($this->socket == false) {
		$m = "Impossible to create the socket\m";
		die($m);
		if (file_put_contents('construct.log', $m, FILE_APPEND)) {
        		// Données enregistrées
        	} else {
           		// Error
       		}
	}

	// Bind socket to the port
        $result = socket_bind($this->socket, $adress, $port);
	if ($result == false) {
		$m = "Impossible to bind\n";
		die($m);
                if (file_put_contents('construct.log', $m, FILE_APPEND)) {
                        // Données enregistrées
                } else {
                        // Error
                }
        }

	$result = socket_listen($this->socket);
	 if ($result == false) {
		$m = "Impossible to listen\n";
		die($m);
                if (file_put_contents('construct.log', $m, FILE_APPEND)) {
                        // Données enregistrées
                } else {
                        // Error
                }
        }

	$m = "Server created\n";
	if (file_put_contents('construct.log', $m, FILE_APPEND)) {
                // Données enregistrées
        } else {
                // Error
        }

        $this->clients = array();
    }

    /*@function work
     *@brief gère l'arrivé des clients
     */
    public function work(){
        $b = true;
        while($b){
            $this->actualClient = socket_accept($this->socket) or die("Erreur socket_accept\n");
            $day = currentDay();
            $hour = currentHour();
            $recv = socket_read($this->actualClient, 1024) or die("Erreur socket_read\n");

	    // Log de la reception
	    if (file_put_contents('tcp.log', (string) $recv, FILE_APPEND)) {
                // Données enregistrées
            } else {
               // Error
            }

            $datas = preg_split("/ /", $recv);
            if(strcmp($recv, "stop") == 0){
                $b = false;
                break;
            }
            $day .= " " . $hour;
            $i = 1;
            foreach($datas as $data){
                $t;
		$obj = "salle" . $i;
		$t[0] = $obj;
		$t[1] = $day;
		$t[2] = $data;
                //$this->parser->setDataForObject($obj, $day, $data);
                $this->parser->setDataForObject($t);
                $i++;
            }
            $this->parser->parser();
        }
        socket_close($this->socket);
        socket_close($this->actualClient);
    }

    /*@function getSocket
     *@return stream une socket
     */
    public function getSocket(){
       return $this->socket;
    }
    /*@function getActualCLient
     *@return stream une socket
     */
    public function getActualClient(){
        return $this->actualClient;
    }
    /*@function getClient
     *@return string le nom d'un client
     */
    public function getClient($index){
        return $this->clients[$index];
    }

}
?>
