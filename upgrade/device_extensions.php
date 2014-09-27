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

// FusionPBX Upgrade script used to upgrade from 3.4 to 3.6 for those using provisioning in FusionPBX.
	// Purpose of this script is to move provisioning assignments from device extensions to device lines
	// Use this script only one time.

//set default values
	$sip_port = '5060';
	$sip_transport = 'TCP';
	$register_expires = '120';

//get the assigned extensions from the device extensions
	$sql = "select * from v_device_extensions ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	$result_count = count($result);
	unset ($prep_statement, $sql);
	if ($result_count > 0) {
		foreach($result as $row) {
			//set the variables from value in the database
				$domain_uuid = $row['domain_uuid'];
				$device_extension_uuid = $row['device_extension_uuid'];
				$device_uuid = $row['device_uuid'];
				$extension_uuid = $row['extension_uuid'];
				$line_number = $row['device_line'];

			//get the registration information for device lines
				$sql = "select * from v_extensions ";
				$sql .= "where extension_uuid = '".$extension_uuid."' ";
				$prep_statement = $db->prepare(check_sql($sql));
				$prep_statement->execute();
				$sub_result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
				foreach ($sub_result as &$field) {
					$user_id = $field["extension"];
					$auth_id = $field["extension"];
					$display_name = $field["extension"];
					$password = $field["password"];
				}

			//set a new uuid
				device_line_uuid = uuid();

			//get the server address from the domains array using the domain_uuid
				$server_address = $_SESSION[domains][$domain_uuid]["domain_name"];

			//insert into device lines
				$sql = "insert into v_device_lines ";
				$sql .= "(";
				$sql .= "domain_uuid, ";
				$sql .= "device_line_uuid, ";
				$sql .= "device_uuid, ";
				$sql .= "line_number, ";
				$sql .= "server_address, ";
				//$sql .= "outbound_proxy, ";
				$sql .= "display_name, ";
				$sql .= "user_id, ";
				$sql .= "auth_id, ";
				$sql .= "password, ";
				$sql .= "sip_port, ";
				$sql .= "sip_transport, ";
				$sql .= "register_expires ";
				$sql .= ") ";
				$sql .= "values ";
				$sql .= "(";
				$sql .= "'$domain_uuid', ";
				$sql .= "'$device_line_uuid', ";
				$sql .= "'$device_uuid', ";
				$sql .= "'$line_number', ";
				$sql .= "'$server_address', ";
				//$sql .= "'$outbound_proxy', ";
				$sql .= "'$display_name', ";
				$sql .= "'$user_id', ";
				$sql .= "'$auth_id', ";
				$sql .= "'$password', ";
				$sql .= "'$sip_port', ";
				$sql .= "'$sip_transport', ";
				$sql .= "'$register_expires' ";
				$sql .= ");\n";
				echo $sql;
				//$db->exec(check_sql($sql));
				unset($sql);

		}
	}

?>