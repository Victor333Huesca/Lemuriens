<?php
/*@author Rodriguez Julien
 *@brief fichier decrivant la classe parserJson
 */

/*@class parserJson
 *@biref class parserJson, transforme les donnée(s) en format json
 */
class parserJson
{
    private $fileOut;
    private $objects;

    /*@function construct
     *@brief constructeur de l'objet parserJson
     */
    public function __construct(){
        $this->objects = array();
    }

    /*@function setObjects
     *@param array $objs un tableau de chaînes de caractères représentant le nom des objets
     *@brief ajoute des objets
     */
    public function setObjects($objs) {
        foreach($objs as $obj) {
            $this->objects[$obj] = array();
        }
    }

    /*@function setDataForObject
     *@param string $object l'object concerner
     *@param array $datas un tableau de chaînes de caractères représentant les donnée(s) sous forme de couple
     *@brief ajoute les donnée(s) à l'objet
     */
    public function setDataForObject($object, $datas){
        $this->objects[$object][$datas[0]] = $datas[1];
    }

    /*@function parser
     *@brief génère un fichier datas.json
     */
    public function parser(){
        $this->fileOut = fopen("datas.json", "r+");

        $buffer = json_encode($this->objects);
        fwrite($this->fileOut, $buffer);

        fclose($this->fileOut);
    }
}


?>
