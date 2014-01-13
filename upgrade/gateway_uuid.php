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
	Portions created by the Initial Developer are Copyright (C) 2008-2012
	the Initial Developer. All Rights Reserved.

	Contributor(s):
	Mark J Crane <markjcrane@fusionpbx.com>
*/
include "root.php";
require "resources/require.php";
require_once "resources/check_auth.php";
if (permission_exists('dialplan_edit')) {
	//access granted
}
else {
	echo "access denied";
	exit;
}

//get the includes
	require "resources/require.php";
	require_once "resources/header.php";
	echo "<pre>\n";

//get the domain, and gateway information
	$sql = "SELECT d.domain_uuid, d.domain_name, g.gateway_uuid, g.gateway FROM v_domains as d, v_gateways as g ";
	$sql .= "WHERE d.domain_uuid = g.domain_uuid \n";
	//echo $sql."<br />\n";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$gateways = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	//print_r($gateways);
	unset($prep_statement);

//start the atomic transaction
	$db->exec("BEGIN;");

//migrate from gateway names to gateway uuids
	echo "<pre>\n";
	$sql = "SELECT dialplan_detail_uuid, dialplan_detail_data FROM v_dialplan_details ";
	$sql .= "WHERE dialplan_detail_data LIKE 'sofia/gateway/%' \n";
	//echo $sql."<br />\n";
	$prep_statement2 = $db->prepare(check_sql($sql));
	$prep_statement2->execute();
	$result = $prep_statement2->fetchAll(PDO::FETCH_NAMED);
	//unset($prep_statement2);
	//print_r($result);
	foreach($result as $field) {
		//set the variables
			$dialplan_detail_uuid = $field['dialplan_detail_uuid'];
			$dialplan_detail_data = $field['dialplan_detail_data'];
			//echo "dialplan_detail_data29: ".$dialplan_detail_data."<br />\n";
		//parse the data
			//sofia/gateway/domain_name-gateway_name/1208$1
			$data = substr($dialplan_detail_data, 14);  //domain_name-gateway_name/1208$1
			$data = explode("/", $data);
			$deprecated = $data[0]; //domain_name-gateway_name
			//print_r($gateways);
		//gateways
			foreach ($gateways as $row) {
				//set the variables
					$domain_uuid = $row["domain_uuid"];
					$domain_name = $row["domain_name"];
					$gateway = $row["gateway"];

				//find a match
					if ($deprecated == $domain_name."-".$gateway) {
						//get the variables
							$domain_uuid = $row["domain_uuid"];
							$gateway_uuid = $row["gateway_uuid"];
							$postfix = substr($dialplan_detail_data, (strlen($deprecated) + 14)); 
						//update the data
							$bridge = "sofia/gateway/".$gateway_uuid.$postfix;
							$sql = "update v_dialplan_details set ";
							$sql .= "dialplan_detail_data = '".$bridge."' ";
							$sql .= "where dialplan_detail_uuid = '$dialplan_detail_uuid'; ";
							$db->exec(check_sql($sql));
							echo $sql."<br />\n";
							unset($sql);
						//exit the loop
							break;
					}
			}

	}
	echo "completed";
	echo "<pre>\n";

//commit the atomic transaction
	$count = $db->exec("COMMIT;");

//show the footer
	echo "</pre>\n";
	require_once "resources/footer.php";

?>