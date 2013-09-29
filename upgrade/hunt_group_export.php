<?php
include "root.php";
require_once "resources/require.php";
require_once "resources/check_auth.php";
require_once "resources/paging.php";

//check permissions
	if (permission_exists('hunt_group_add') || permission_exists('hunt_group_edit')) {
		//access granted
	}
	else {
		echo "access denied";
		exit;
	}

//show debug
	echo "<pre>\n";

//start the atomic transaction
	$db->exec("BEGIN;");

//get the hunt groups
	$sql = "select d.domain_name, h.domain_uuid, h.dialplan_uuid, h.hunt_group_uuid, h.hunt_group_extension, h.hunt_group_name, h.hunt_group_type, h.hunt_group_context, ";
	$sql .= "h.hunt_group_timeout, h.hunt_group_timeout_destination, h.hunt_group_timeout_type, h.hunt_group_ringback, h.hunt_group_cid_name_prefix, ";
	$sql .= "h.hunt_group_pin, h.hunt_group_caller_announce, h.hunt_group_call_prompt, h.hunt_group_user_list, h.hunt_group_enabled, h.hunt_group_description ";
	$sql .= "from v_hunt_groups as h, v_domains as d ";
	$sql .= "where d.domain_uuid = h.domain_uuid ";
	$sql .= "and (h.hunt_group_type = 'simultaneous' or h.hunt_group_type = 'sequentially') ";
	//$sql .= "and h.domain_uuid = '".$_SESSION["domain_uuid"]."' ";
	//$sql .= "and hunt_group_enabled = 'true' ";
	//echo $sql."\n";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	//print_r($result);
	foreach ($result as &$row) {
		//get the hunt group information and set as variables
			$domain_name = $row["domain_name"];
			$domain_uuid = $row["domain_uuid"];
			$hunt_group_uuid = $row["hunt_group_uuid"];
			$dialplan_uuid = $row["dialplan_uuid"];
			$ring_group_extension = $row["hunt_group_extension"];
			$ring_group_name = check_str($row["hunt_group_name"]);
			$ring_group_strategy = $row["hunt_group_type"]; //simultaneous //sequentially
			$ring_group_timeout_sec = $row["hunt_group_timeout"];
			$ring_group_timeout_data = $row["hunt_group_timeout_destination"];
			$ring_group_timeout_type = $row["hunt_group_timeout_type"]; //extension //voicemail //sip uri
			$ring_group_ringback = $row["hunt_group_ringback"];
			$ring_group_cid_name_prefix = $row["hunt_group_cid_name_prefix"];
			//$hunt_group_pin = $row["hunt_group_pin"];
			$ring_group_users = $row["hunt_group_user_list"];
			$ring_group_enabled = $row["hunt_group_enabled"];
			$ring_group_description = check_str($row["hunt_group_description"]);

			if ($ring_group_strategy == "sequentially") {
				$ring_group_strategy = "sequence";
			}

			//set the ring group context
			if (count($_SESSION["domains"]) > 1) {
				$ring_group_context = $domain_name;
			}
			else {
				$ring_group_context = "default";
			}

			if ($ring_group_timeout_type == "extension") {
				$ring_group_timeout_app = "transfer";
			} elseif ($ring_group_timeout_type == "voicemail") {
				$ring_group_timeout_app = "transfer";
				$ring_group_timeout_data = "*99".$ring_group_timeout_data." XML ".$ring_group_context;
			} else {
				$ring_group_timeout_app = "transfer";
			}

			if (strlen($dialplan_uuid) > 0) {
					//delete from the dialplan details
						$sql = "delete from v_dialplan_details ";
						$sql .= "where domain_uuid = '".$domain_uuid."' ";
						$sql .= "and dialplan_uuid = '".$dialplan_uuid."' ";
						$db->exec(check_sql($sql));
						unset($sql);

					//delete from the dialplan
						$sql = "delete from v_dialplans ";
						$sql .= "where domain_uuid = '".$domain_uuid."' ";
						$sql .= "and dialplan_uuid = '".$dialplan_uuid."' ";
						$db->exec(check_sql($sql));
						unset($sql);
			}
			else {
				$dialplan_uuid = uuid();
			}

		//add the ring group
			//prepare the uuids
				$ring_group_uuid = uuid();
			//add the ring group
				$sql = "insert into v_ring_groups ";
				$sql .= "(";
				$sql .= "domain_uuid, ";
				$sql .= "ring_group_uuid, ";
				$sql .= "ring_group_name, ";
				$sql .= "ring_group_extension, ";
				$sql .= "ring_group_context, ";
				$sql .= "ring_group_strategy, ";
				$sql .= "ring_group_timeout_sec, ";
				$sql .= "ring_group_timeout_app, ";
				$sql .= "ring_group_timeout_data, ";
				$sql .= "ring_group_cid_name_prefix, ";
				$sql .= "ring_group_ringback, ";
				$sql .= "ring_group_enabled, ";
				$sql .= "ring_group_description, ";
				$sql .= "dialplan_uuid ";
				$sql .= ")";
				$sql .= "values ";
				$sql .= "(";
				$sql .= "'".$domain_uuid."', ";
				$sql .= "'".$ring_group_uuid."', ";
				$sql .= "'$ring_group_name', ";
				$sql .= "'$ring_group_extension', ";
				$sql .= "'$ring_group_context', ";
				$sql .= "'$ring_group_strategy', ";
				$sql .= "'$ring_group_timeout_sec', ";
				$sql .= "'$ring_group_timeout_app', ";
				$sql .= "'$ring_group_timeout_data', ";
				$sql .= "'$ring_group_cid_name_prefix', ";
				$sql .= "'$ring_group_ringback', ";
				$sql .= "'$ring_group_enabled', ";
				$sql .= "'$ring_group_description', ";
				$sql .= "'$dialplan_uuid' ";
				$sql .= ");";
				echo $sql."\n";
				$db->exec(check_sql($sql));
				unset($sql);

		//add the dialplan
			require_once "resources/classes/database.php";
			$database = new database;
			$database->db = $db;
			$database->table = "v_dialplans";
			$database->fields['domain_uuid'] = $domain_uuid;
			$database->fields['dialplan_uuid'] = $dialplan_uuid;
			$database->fields['dialplan_name'] = $ring_group_name;
			$database->fields['dialplan_order'] = '333';
			$database->fields['dialplan_context'] = $ring_group_context;
			$database->fields['dialplan_enabled'] = 'true';
			$database->fields['dialplan_description'] = $ring_group_description;
			$database->fields['app_uuid'] = '1d61fb65-1eec-bc73-a6ee-a6203b4fe6f2';
			$database->add();

		//add the dialplan details
			$database->table = "v_dialplan_details";
			$database->fields['domain_uuid'] = $domain_uuid;
			$database->fields['dialplan_uuid'] = $dialplan_uuid;
			$database->fields['dialplan_detail_uuid'] = uuid();
			$database->fields['dialplan_detail_tag'] = 'condition'; //condition, action, antiaction
			$database->fields['dialplan_detail_type'] = 'destination_number';
			$database->fields['dialplan_detail_data'] = '^'.$ring_group_extension.'$';
			$database->fields['dialplan_detail_order'] = '000';
			$database->add();

		//add the dialplan details
			$database->table = "v_dialplan_details";
			$database->fields['domain_uuid'] = $domain_uuid;
			$database->fields['dialplan_uuid'] = $dialplan_uuid;
			$database->fields['dialplan_detail_uuid'] = uuid();
			$database->fields['dialplan_detail_tag'] = 'action'; //condition, action, antiaction
			$database->fields['dialplan_detail_type'] = 'set';
			$database->fields['dialplan_detail_data'] = 'ring_group_uuid='.$ring_group_uuid;
			$database->fields['dialplan_detail_order'] = '025';
			$database->add();

		//add the dialplan details
			$database->table = "v_dialplan_details";
			$database->fields['domain_uuid'] = $domain_uuid;
			$database->fields['dialplan_uuid'] = $dialplan_uuid;
			$database->fields['dialplan_detail_uuid'] = uuid();
			$database->fields['dialplan_detail_tag'] = 'action'; //condition, action, antiaction
			$database->fields['dialplan_detail_type'] = 'lua';
			$database->fields['dialplan_detail_data'] = 'app.lua ring_groups';
			$database->fields['dialplan_detail_order'] = '030';
			$database->add();

		//get the hunt group destinations
			$sql = "select * from v_hunt_group_destinations ";
			$sql .= "where domain_uuid = '$domain_uuid' ";
			$sql .= "and hunt_group_uuid = '$hunt_group_uuid' ";
			$sql .= "order by destination_order, destination_data asc";
			$sub_prep_statement = $db->prepare(check_sql($sql));
			$sub_prep_statement->execute();
			$sub_result = $sub_prep_statement->fetchAll(PDO::FETCH_NAMED);
			//print_r($sub_result);
			unset ($sub_prep_statement, $sql);
			if (count($sub_result) > 0) {
				foreach($sub_result as $field) {
					//get the hunt group destinations and set them as variables
						//$hunt_group_uuid = $field["hunt_group_uuid"];
						$destination_number = $field["destination_data"];
						$destination_type = $field["destination_type"];
						$destination_timeout = $field["destination_timeout"];
						$destination_order = $field["destination_order"];
						//$destination_enabled = $field["destination_enabled"];
						//$destination_description = $field["destination_description"];

						if (strlen($destination_timeout) == 0) {
							$destination_timeout = "30";
						}

						$destination_delay = "0";
						if ($ring_group_strategy == "sequence") {
							$destination_delay = $destination_order;
						}

						if ($destination_type == "extension") {
							//do nothing
						}
						elseif ($destination_type == "voicemail") {
							$destination_number = "*99".$destination_number." XML ".$ring_group_context;
						}
						elseif ($destination_type == "sip uri") {
							//do nothing
						}
						else {
							//do nothing
						}

					//add the ring group destinations
						$sql = "insert into v_ring_group_destinations ";
						$sql .= "(";
						$sql .= "domain_uuid, ";
						$sql .= "ring_group_destination_uuid, ";
						$sql .= "ring_group_uuid, ";
						$sql .= "destination_number, ";
						$sql .= "destination_delay, ";
						$sql .= "destination_timeout, ";
						$sql .= "destination_prompt ";
						$sql .= ") ";
						$sql .= "values ";
						$sql .= "(";
						$sql .= "'$domain_uuid', ";
						$sql .= "'".uuid()."', ";
						$sql .= "'$ring_group_uuid', ";
						$sql .= "'$destination_number', ";
						$sql .= "'$destination_delay', ";
						$sql .= "'$destination_timeout', ";
						$sql .= "null ";
						$sql .= ");";
						echo $sql."\n";
						$db->exec(check_sql($sql));
						unset($sql);

				} //end foreach
				unset($sql, $result, $row_count);
			} //end if results
	}
	unset ($prep_statement);

//assign the users
		if (strlen($ring_group_users) > 0) {
			$ring_group_user_array = explode("|", $ring_group_users);
			if (count($ring_group_user_array) > 0) {
				foreach($ring_group_user_array as $username){
					if (strlen(trim($username)) > 0) {
						//get the user_uuid
							$sql = "select * from v_users ";
							$sql .= "where domain_uuid = '$domain_uuid' ";
							$sql .= "and username = '".trim($username)."' ";
							$tmp_prep_statement = $db->prepare(check_sql($sql));
							$tmp_prep_statement->execute();
							$tmp_result = $tmp_prep_statement->fetchAll(PDO::FETCH_NAMED);
							foreach($tmp_result as $field) {
								$user_uuid = $field["user_uuid"];
							}
							unset ($tmp_prep_statement, $sql,$tmp_result);
						//assign the user to the ring group
							$sql_insert = "insert into v_ring_group_users ";
							$sql_insert .= "(";
							$sql_insert .= "ring_group_user_uuid, ";
							$sql_insert .= "domain_uuid, ";
							$sql_insert .= "ring_group_uuid, ";
							$sql_insert .= "user_uuid ";
							$sql_insert .= ")";
							$sql_insert .= "values ";
							$sql_insert .= "(";
							$sql_insert .= "'".uuid()."', ";
							$sql_insert .= "'$domain_uuid', ";
							$sql_insert .= "'".$ring_group_uuid."', ";
							$sql_insert .= "'".$user_uuid."' ";
							$sql_insert .= ");";
							echo $sql_insert."\n";
							$db->exec($sql_insert);
					}
				}
			}
		}

//commit the atomic transaction
	$count = $db->exec("COMMIT;"); //returns affected rows

//save the xml
	save_dialplan_xml();

//apply settings reminder
	$_SESSION["reload_xml"] = true;

//delete the dialplan context from memcache
	$fp = event_socket_create($_SESSION['event_socket_ip_address'], $_SESSION['event_socket_port'], $_SESSION['event_socket_password']);
	if ($fp) {
		$switch_cmd = "memcache delete dialplan:".$ring_group_context;
		$switch_result = event_socket_request($fp, 'api '.$switch_cmd);
	}

//show debug
	echo "</pre>\n";

//send a message
	echo "completed";
?>