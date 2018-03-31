<!DOCTYPE html>

<?php
    //include 'server.php';

    //$serv = new server("127.0.0.1", 8080);
    //$serv->work();
?>


<html>

<head>
	<meta charset="utf-8" />
	<title>Lemuriens</title>
	<link rel="icon" type="image/png" href="lemuriens.png" />
	<link rel="stylesheet" type="text/css" href="index.css" />
</head>
<body>
	<h1>Bienvenue sur le site des lémuriens !</h1>
	<p>Les lémuriens sont actuellement en cours de préparation du site. Par conséquent nous vous prions de bien vouloir attendre quelques temps afin de leur laisser le temps de contruire le site (car c'est lourd les briques pour ces pauvres pitites bêtes).'</p>
	<form action="index.php" method=GET>
		<input type='text' name='varA'>
		<input type='submit' name='valider'>
	</form>
	<?php
		if (isset($_GET['varA'])) {
			echo $_GET['varA'];
			if (file_put_contents('varA.log', $_GET['varA'] . "\n", FILE_APPEND)) {
				// Données enregistrées
			} else {
				// Error
			}
		}
	?>
</body>

</html>
