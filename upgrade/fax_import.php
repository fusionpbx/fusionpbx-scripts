<?php
//check the permission
	if (defined('STDIN')) {
		$document_root = str_replace("\\", "/", $_SERVER["PHP_SELF"]);
		preg_match("/^(.*)\/app\/.*$/", $document_root, $matches);
		@$document_root = $matches[1];
		set_include_path($document_root);
		$_SERVER["DOCUMENT_ROOT"] = $document_root;
		require_once "resources/require.php";
		$html = false;
	}
	else {
		include "root.php";
		require_once "resources/require.php";
		require_once "resources/pdo.php";
		require_once "resources/check_auth.php";
		if (permission_exists('fax_extension_edit')) {
			//access granted
		}
		else {
			echo "access denied";
			exit;
		}
		$html = true;
	}

//increase limits
	set_time_limit(3600);
	ini_set('memory_limit', '256M');
	ini_set("precision", 6);

//set pdo attribute that enables exception handling
	$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

//get default storage directory
	$sql = "select default_setting_value from v_default_settings ";
	$sql .= "where default_setting_category = 'switch' ";
	$sql .= "and default_setting_subcategory = 'storage' ";
	$sql .= "and default_setting_name = 'dir' ";
	$sql .= "and default_setting_enabled = 'true' ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$result = $prep_statement->fetch(PDO::FETCH_ASSOC);
	$default_storage_folder = $result['default_setting_value'];
	unset($prep_statement, $sql, $result);

//get domain storage directory
	$sql = "select domain_uuid, domain_setting_value from v_domain_settings ";
	$sql .= "where domain_setting_category = 'switch' ";
	$sql .= "and domain_setting_subcategory = 'storage' ";
	$sql .= "and domain_setting_name = 'dir' ";
	$sql .= "and domain_setting_enabled = 'true' ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$results = $prep_statement->fetch(PDO::FETCH_ASSOC);
	foreach ($results as $index => $row) {
		$domain_storage_folders[$row['domain_uuid']] = $row['default_setting_value'];
	}
	unset($prep_statement, $sql, $results);

//get domains and uuids
	$sql = "select domain_uuid, domain_name from v_domains ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$results = $prep_statement->fetchAll(PDO::FETCH_ASSOC);
	if (count($results) > 0) {
		foreach ($results as $row) {
			$domain_names[$row['domain_uuid']] = $row['domain_name'];
		}
	}
	unset($prep_statement, $sql, $results);

//add a function to check for a valid uuid
	if (!function_exists('is_uuid')) {
		function is_uuid($uuid) {
			//uuid version 4
			$regex = '/^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i';
			return preg_match($regex, $uuid);
		}
	}

//get fax extensions and uuids
	$sql = "select fax_uuid, domain_uuid, fax_extension, fax_caller_id_name, fax_caller_id_number from v_fax ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$results = $prep_statement->fetchAll(PDO::FETCH_ASSOC);
	if (count($results) > 0) {
		foreach ($results as $row) {
			$fax_extension_uuids[$row['domain_uuid']][$row['fax_extension']] = $row['fax_uuid'];
			$fax_extension_cid[$row['domain_uuid']][$row['fax_extension']]['name'] = $row['fax_caller_id_name'];
			$fax_extension_cid[$row['domain_uuid']][$row['fax_extension']]['number'] = $row['fax_caller_id_number'];
		}
	}
	unset($prep_statement, $sql, $results);

//set domain fax storage folder paths to check
	foreach ($domain_names as $domain_uuid => $domain_name) {
		if (count($domain_names) == 1) {
			$domain_fax_storage_paths[$domain_uuid] = (($domain_storage_folders[$domain_uuid] != '') ? $domain_storage_folders[$domain_uuid] : $default_storage_folder).'/fax';
		}
		else {
			$domain_fax_storage_paths[$domain_uuid] = (($domain_storage_folders[$domain_uuid] != '') ? $domain_storage_folders[$domain_uuid] : $default_storage_folder).'/fax/'.$domain_name;
		}
	}

//traverse through domain fax storage folders
	foreach ($domain_fax_storage_paths as $domain_uuid => $domain_fax_storage_path) {
		if (file_exists($domain_fax_storage_path)) {
			$domain_fax_file_paths[$domain_uuid] = glob($domain_fax_storage_path.'/*/*/*.tif');
		}
	}

//traverse through domain fax file paths
	foreach ($domain_fax_file_paths as $domain_uuid => $fax_file_paths) {
		echo "\n\nImporting ".$domain_names[$domain_uuid]." faxes...".(($html) ? "<br><br>" : null)."\n\n";
		foreach ($fax_file_paths as $fax_file_path) {
			$fax_ext_path = str_replace($domain_fax_storage_paths[$domain_uuid].'/', '', $fax_file_path);
			$tmp_array = explode('/', $fax_ext_path);
			$fax_ext = $tmp_array[0];
			$fax_box = $tmp_array[1];
			$fax_file = $tmp_array[2];
			if ($fax_box == 'temp') { continue; }
			else {
				if ($fax_box == 'inbox') {
					$record['fax_file_uuid'] = uuid();
					$record['fax_uuid'] = $fax_extension_uuids[$domain_uuid][$fax_ext];
					$record['fax_mode'] = 'rx';
					$record['fax_destination'] = '';
					$record['fax_file_type'] = substr($fax_file, -3);
					$record['fax_file_path'] = $fax_file_path;
					$record['fax_caller_id_name'] = substr($fax_file, 0, strpos($fax_file, '-'));
					$record['fax_caller_id_number'] = (is_numeric($record['fax_caller_id_name'])) ? (int) $record['fax_caller_id_name'] : null;
					$tmp_array = explode('-',substr($fax_file, strpos($fax_file, '-')+1));
					$record['fax_date'] = $tmp_array[0].'-'.$tmp_array[1].'-'.$tmp_array[2].' '.$tmp_array[3].':'.$tmp_array[4].':'.str_replace('.'.$record['fax_file_type'], '', $tmp_array[5]);
					$record['fax_epoch'] = strtotime($record['fax_date']);
				}
				if ($fax_box == 'sent') {
					$xml_cdr_uuid = substr($fax_file, 0, strpos($fax_file, '.'));

					$record['fax_file_uuid'] = $xml_cdr_uuid;
					$record['fax_uuid'] = $fax_extension_uuids[$domain_uuid][$fax_ext];
					$record['fax_mode'] = 'tx';
					$record['fax_file_type'] = substr($fax_file, -3);
					$record['fax_file_path'] = $fax_file_path;

					//get cdr details (if any)
					if (is_uuid($xml_cdr_uuid)) {
						$sql = "select destination_number, caller_id_name, caller_id_number, start_stamp, start_epoch from v_xml_cdr ";
						$sql .= "where uuid = '".$xml_cdr_uuid."' ";
						$sql .= "and domain_uuid = '".$domain_uuid."' ";
						$prep_statement = $db->prepare(check_sql($sql));
						$prep_statement->execute();
						$cdr = $prep_statement->fetch(PDO::FETCH_ASSOC);
						if (is_array($cdr) && count($cdr) > 0) {
							$record['fax_destination'] = $cdr['destination_number'];
							$record['fax_caller_id_name'] = $cdr['caller_id_name'];
							$record['fax_caller_id_number'] = $cdr['caller_id_number'];
							$record['fax_date'] = $cdr['start_stamp'];
							$record['fax_epoch'] = $cdr['start_epoch'];
						}
						else {
							$record['fax_caller_id_name'] = $fax_extension_cid[$domain_uuid][$fax_ext]['name'];
							$record['fax_caller_id_number'] = $fax_extension_cid[$domain_uuid][$fax_ext]['number'];
							$record['fax_epoch'] = filemtime($fax_file_path);
							$record['fax_date'] = date("Y-m-d H:i:s", $record['fax_epoch']);
						}
						unset($prep_statement, $sql, $cdr);
					}
				}

				//create record in the db
					if (is_uuid($record['fax_uuid']) && is_uuid($record['fax_file_uuid'])) {
						$sql = "insert into v_fax_files ";
						$sql .= "( ";
						$sql .= "fax_file_uuid, ";
						$sql .= "fax_uuid, ";
						$sql .= "domain_uuid, ";
						$sql .= "fax_mode, ";
						$sql .= "fax_destination, ";
						$sql .= "fax_file_type, ";
						$sql .= "fax_file_path, ";
						$sql .= "fax_caller_id_name, ";
						$sql .= "fax_caller_id_number, ";
						$sql .= "fax_date, ";
						$sql .= "fax_epoch ";
						$sql .= ") ";
						$sql .= "values ";
						$sql .= "( ";
						$sql .= "'".$record['fax_file_uuid']."', ";
						$sql .= "'".$record['fax_uuid']."', ";
						$sql .= "'".$domain_uuid."', ";
						$sql .= "'".$record['fax_mode']."', ";
						$sql .= "'".$record['fax_destination']."', ";
						$sql .= "'".$record['fax_file_type']."', ";
						$sql .= "'".$record['fax_file_path']."', ";
						$sql .= "'".$record['fax_caller_id_name']."', ";
						$sql .= "'".$record['fax_caller_id_number']."', ";
						$sql .= "'".$record['fax_date']."', ";
						$sql .= "'".$record['fax_epoch']."' ";
						$sql .= ") ";
						//echo $sql;
						try {
							$db->exec($sql);
						}
						catch (Exception $e) {
							echo 'Caught exception: ',  $e->getMessage(), "\n";
						}
					}

				echo $fax_ext.", ".strtoupper($fax_box).", ".$fax_file.(($html) ? "<br>" : null)."\n";

				unset($record);
			} //if

		} //foreach
	} //foreach

	echo (($html) ? "<br>" : null)."\nImport complete.".(($html) ? "<br><br><br>" : null)."\n\n\n";

?>