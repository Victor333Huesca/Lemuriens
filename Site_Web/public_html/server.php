<?php
/*@author Rodriguez Julien
 *@brief fichier decrivant la classe server
 */

 include 'date.php';
 include 'parserJson.php';

/*@class server
 *@biref class server, gère les connexions entrantes et la reception de donnée(s) client
 */ 
class Server
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
        $this->parser = new ParserJson();
        $this->parser->setObjects("salle1", "salle2", "salle3", "salle4", "salle5");

        $this->socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP) or die("Erreur socket_create\n");

        $result = socket_bind($this->socket, $adress, $port) or die("Erreur socket_bind\n");
        $result = socket_listen($this->socket)  or die("Erreur socket_listen\n");

        $this->clients = array();
    }

    /*@function work 
     *@brief gère l'arrivé des clients
     */
    public function work(){
        $b = true;
        $h = 0;
        while($b){
            $this->actualClient = socket_accept($this->socket) or die("Erreur socket_accept\n");            
            $day = currentDay();
            $hour = currentHour();
            $recv = socket_read($this->actualClient, 1024) or die("Erreur socket_read\n"); 
            $datas = preg_split("/ /", $recv);
            if(strcmp($recv, "stop") == 0){
                $b = false;
                break;
            }
            $day .= " " . $hour;
            $i = 1;
            foreach($datas as $data){
                $obj = "salle" . $i;
                $this->parser->setDataForObject($obj, $day, $data);
                $i++;
            }
            $this->parser->parser();
            $h++;
            if($h == 24){ //minuit on vide le fichier
                unset($this->parser);
                $this->parser = new ParserJson();
                $this->parser->setObjects("salle1", "salle2", "salle3", "salle4", "salle5");
            }
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