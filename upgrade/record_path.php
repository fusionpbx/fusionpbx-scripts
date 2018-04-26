<?php
/*
	FusionPBX
	Version: MPL 1.1
	The contents of this file are subject to the Mozilla Public License Version
	1.1 (the "License"); you may not use this file except in compliance with
	the License. You may obtain a copy of the License at
	http://www.mozilla.org/MPL/
	Software distributed under the License is distributed on an "AS IS" basis,
	WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
	for the specific language governing rights and limitations under the
	License.
	The Original Code is FusionPBX
	The Initial Developer of the Original Code is
	Mark J Crane <markjcrane@fusionpbx.com>
	Portions created by the Initial Developer are Copyright (C) 2018
	the Initial Developer. All Rights Reserved.
	Contributor(s):
	Mark J Crane <markjcrane@fusionpbx.com>
*/

//settings
	$domain_name = '*';
	$year = '2018';
	$type = 'wav';  //wav or mp3
	$execute_sql = true;
        $document_root = '/var/www/fusionpbx';

//web server or command line
        if(defined('STDIN')) {
                set_include_path($document_root);
                $_SERVER["DOCUMENT_ROOT"] = $document_root;
                $project_path = $_SERVER["DOCUMENT_ROOT"];
                define('PROJECT_PATH', $project_path);
                $_SERVER["PROJECT_ROOT"] = realpath($_SERVER["DOCUMENT_ROOT"] . PROJECT_PATH);
                set_include_path(get_include_path() . PATH_SEPARATOR . $_SERVER["PROJECT_ROOT"]);
                require_once "resources/require.php";
                $display_type = 'text'; //html, text
        }
	else {
		include "root.php";
		require_once "resources/require.php";
		require_once "resources/pdo.php";
	}

//get the uuid recordings and update the information in the database
	$recordings = glob($_SESSION['switch']['recordings']['dir'].'/'.$domain_name.'/archive/'.$year.'/*/*/*.'.$type);
	foreach($recordings as $path) {
		//get the details from the path
		$parts = pathinfo($path);
		$record_path = $parts['dirname'];
		$record_name = $parts['basename'];
		$uuid = $parts['filename'];
		$extension = $parts['extension'];

		//update the database
		if (is_uuid($uuid)) {
			$sql = "update v_xml_cdr set ";
			$sql .= "record_path = '".$record_path."', ";
			$sql .= "record_name = '".$record_name."' ";
			$sql .= "where uuid = '".$uuid."';\n";
			if ($execute_sql) { 
				$db->exec($sql); 
			}
			echo $sql."\n";
		}
	}

//send a message
	if ($execute_sql) {
		echo "\n";
		echo "-- The following SQL command have been executed.\n";
	}
	else {
		echo "\n";
		echo "-- Run the SQL commands on the database server.\n";
	}

//include the footer
	if(!defined('STDIN')) {
		require_once "resources/footer.php";
	}

?>
