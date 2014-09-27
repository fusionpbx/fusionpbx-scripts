// FusionPBX Upgrade script used to upgrade from 3.4 to 3.6 for those using provisioning in FusionPBX.
	// Purpose of this script is to move provisioning assignments from device extensions to device lines
	// Use this script only one time.

	$sql = "insert into v_device_extensions ";
	$sql .= "domain_uuid, ";
	$sql .= "device_extension_uuid, ";
	$sql .= "device_uuid, ";
	$sql .= "extension_uuid, ";
	$sql .= "device_line ";

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
				$device_line = $row['device_line'];

			//get the registration information for device lines
				$sql = "select * from v_extensions ";
				$sql .= "where extension_uuid = '".$extension_uuid."' ";
				$prep_statement = $db->prepare(check_sql($sql));
				$prep_statement->execute();
				$sub_result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
				foreach ($sub_result as &$field) {
					$zzz = $field["zzz"];
					$zzz = $field["zzz"];
					$zzz = $field["zzz"];
					$zzz = $field["zzz"];
					$zzz = $field["zzz"];
					$zzz = $field["zzz"];
					$zzz = $field["zzz"];
					$zzz = $field["zzz"];
					$zzz = $field["zzz"];
				}

			//set a new uuid
				device_line_uuid = uuid();

			//insert into device lines
				$sql = "insert into v_device_lines ";
				$sql .= "(";
				$sql .= "domain_uuid, ";
				$sql .= "device_line_uuid, ";
				$sql .= "device_uuid, ";
				$sql .= "line_number, ";
				$sql .= "server_address, ";
				$sql .= "outbound_proxy, ";
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
				$sql .= "'$outbound_proxy', ";
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
				//unset($sql);

		}
	}