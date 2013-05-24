// FusionPBX Upgrade script used to upgrade from 3.2 to 3.3 for those using provisioning in FusionPBX.
	// Purpose of this script is to move provisioning assignments that tie a device to an extension 
	// FusionPBX 3.2 and older used provisioning_list a delimitted list in v_extensions.
	// FusionPBX 3.3 and higher use v_device_extensions to assign the device to the extension
	// Use this script only one time.

//get the assigned extensions from the provisioning_list
	$sql = "select * from v_extensions where provisioning_list <> '' ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	$result_count = count($result);
	unset ($prep_statement, $sql);
	if ($result_count > 0) {
		foreach($result as $row) {
			$domain_uuid = $row['domain_uuid'];
			$extension_uuid = $row['extension_uuid'];
			$provisioning_list = $row['provisioning_list'];
			if (strlen($provisioning_list) > 1) {
				//get the array from the provisioning list
					$provision_array = explode("|", $provisioning_list);

				//process each device
					foreach($provision_array as $provision_row) {

						//get the mac address
							if (strlen($provision_row) > 0) {
								$device_array = explode(":", $provision_row);
								$mac_address = $device_array[0];
								$device_line = $device_array[1];
							}

						//normalize the mac address
							$mac_address = strtolower($mac_address);
							$mac_address = preg_replace('#[^a-fA-F0-9./]#', '', $mac_address);

						//add the device to device extensions
							if (strlen($mac_address) > 0) {
								//get the device_uuid using the mac address from devices
									$sql = "select device_uuid from v_devices ";
									$sql .= "where domain_uuid = '".$domain_uuid."' ";
									$sql .= "and device_mac_address = '".$mac_address."' ";
									$prep_statement = $db->prepare(check_sql($sql));
									$prep_statement->execute();
									$sub_result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
									foreach ($sub_result as &$field) {
										$device_uuid = $field["device_uuid"];
									}

								//set the uuid
									$device_extension_uuid = uuid();

								//set a default line number
									if (strlen($device_line) == 0) {
										$device_line = "1";
									}

								if (strlen($device_uuid) > 0) {
									$sql = "insert into v_device_extensions ";
									$sql .= "(";
									$sql .= "domain_uuid, ";
									$sql .= "device_extension_uuid, ";
									$sql .= "device_uuid, ";
									$sql .= "extension_uuid, ";
									$sql .= "device_line ";
									$sql .= ") ";
									$sql .= "values ";
									$sql .= "(";
									$sql .= "'$domain_uuid', ";
									$sql .= "'$device_extension_uuid', ";
									$sql .= "'$device_uuid', ";
									$sql .= "'$extension_uuid', ";
									$sql .= "'$device_line' ";
									$sql .= ");\n";
									echo $sql;
									$db->exec(check_sql($sql));
									unset($sql);
								}
							}

						//unset the variables
							unset($mac_address,$device_uuid,$device_line);
					}
			}
		}
	}