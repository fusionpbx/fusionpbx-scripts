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
require "includes/require.php";
require_once "includes/checkauth.php";
require_once "app_languages.php";
if (permission_exists('voicemail_view')) {
	//access granted
}
else {
	echo "access denied";
	exit;
}

//get the includes
	require "includes/require.php";
	require_once "includes/header.php";
	echo "<pre>\n";

//prepare the data variable
	$data = '';

//delete the voicemail dialplans so that they can be updated
	// <extension name="local_extension" app_uuid="71cf1310-b6e3-415b-8745-3cbdc8e15212">
	$sql = "select dialplan_uuid from v_dialplans where app_uuid = '71cf1310-b6e3-415b-8745-3cbdc8e15212' ";

	// <extension name="send_to_voicemail" app_uuid="001d5dab-e0c6-4352-8f06-e9986ee7b0d8">
	$sql .= "or app_uuid = '001d5dab-e0c6-4352-8f06-e9986ee7b0d8' ";

	// <extension name="vmain" app_uuid="d085a1e3-c53a-4480-9ca6-6a362899a681">
	$sql .= "or app_uuid = 'd085a1e3-c53a-4480-9ca6-6a362899a681' ";

	// <extension name="vmain_user" app_uuid="5d47ab13-f25d-4f62-a68e-2a7d945d05b7">
	$sql .= "or app_uuid = '5d47ab13-f25d-4f62-a68e-2a7d945d05b7' ";

	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach($result as $row) {
		$sql = "delete from v_dialplans where dialplan_uuid = '".$row['dialplan_uuid']."'";
		echo $sql."\n";
		$db->query($sql);
		unset($sql);

		$sql = "delete from v_dialplan_details where dialplan_uuid = '".$row['dialplan_uuid']."'";
		echo $sql."\n";
		$db->query($sql);
		unset($sql);
	}

//list the voicemail prefs
	$sql = "select * from v_extensions ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	$result_count = count($result);
	unset ($prep_statement, $sql);
	if ($result_count > 0) {
		foreach($result as $row) {
			$domain_uuid = $row['domain_uuid'];
			$voicemail_id = $row['extension'];
			$voicemail_password = $row['vm_password'];
			$voicemail_enabled = $row['vm_enabled']; //true, false
			$voicemail_mail_to = $row['vm_mailto'];
			$voicemail_attach_file = $row['vm_attach_file']; //true, false
			$voicemail_local_after_email = $row['vm_keep_local_after_email']; //true, false
			$voicemail_description = $row['description'];
			//print_r($row);

			//map the voicemail_id to the voicemail_uuid
			$voicemail_uuid = uuid();
			$mailbox[$voicemail_id]['voicemail_uuid'] = $voicemail_uuid;

			if ($row['vm_enabled'] == "true" || $row['vm_enabled'] == "") {
				$sql = "insert into v_voicemails ";
				$sql .= "(";
				$sql .= "domain_uuid, ";
				$sql .= "voicemail_uuid, ";
				$sql .= "voicemail_id, ";
				$sql .= "voicemail_password, ";
				//if (strlen($greeting_id) > 0) {
				//	$sql .= "greeting_id, ";
				//}
				$sql .= "voicemail_mail_to, ";
				$sql .= "voicemail_attach_file, ";
				$sql .= "voicemail_local_after_email, ";
				$sql .= "voicemail_enabled, ";
				$sql .= "voicemail_description ";
				$sql .= ") ";
				$sql .= "values ";
				$sql .= "(";
				$sql .= "'$domain_uuid', ";
				$sql .= "'$voicemail_uuid', ";
				$sql .= "'$voicemail_id', ";
				$sql .= "'$voicemail_password', ";
				//if (strlen($greeting_id) > 0) {
				//	$sql .= "'$greeting_id', ";
				//}
				$sql .= "'$voicemail_mail_to', ";
				$sql .= "'$voicemail_attach_file', ";
				$sql .= "'$voicemail_local_after_email', ";
				$sql .= "'$voicemail_enabled', ";
				$sql .= "'$voicemail_description' ";
				$sql .= ");\n";
				echo $sql;
				$db->exec(check_sql($sql));
				unset($sql);
			}
		}
	}

//pdo voicemail database connection
	include "includes/lib_pdo_vm.php";

//list the voicemail prefs
	$sql = "select * from voicemail_prefs ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	$result_count = count($result);
	unset ($prep_statement, $sql);
	if ($result_count > 0) {
		foreach($result as $row) {
			$voicemail_id = $row['username'];
			$domain_name = $row['domain'];
			//$name_path = $row['name_path'];
			$greeting_path = $row['greeting_path'];
			if (strlen($row['greeting_path']) > 0) {
				$greeting_id = substr($greeting_path, -5, 1);
			}
			else {
				$greeting_id = '';
			}
			$voicemail_password = $row['password'];
			//print_r($row);

			//get the domain_uuid
			foreach($_SESSION['domains'] as $tmp) {
				if ($tmp['domain_name'] == $domain_name) {
					$domain_uuid = $tmp['domain_uuid'];
				}
			}

			//get the voicemail_uuid
			$voicemail_uuid = $mailbox[$voicemail_id]['voicemail_uuid'];

			$sql = "update v_voicemails set ";
			if (strlen($voicemail_password) > 0) {
				$sql .= "voicemail_password = '$voicemail_password', ";
			}
			if (strlen($greeting_id) > 0) {
				$sql .= "greeting_id = '$greeting_id' ";
			}
			else {
				$sql .= "greeting_id = null ";
			}
			$sql .= "where domain_uuid = '$domain_uuid' ";
			$sql .= "and voicemail_uuid = '$voicemail_uuid';";
			$data .= $sql;
			unset($sql);
		}
		unset($prep_statement, $sql, $result, $row_count);
	}

//list the voicemail messages
	$sql = "select * from voicemail_msgs ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	$result_count = count($result);
	unset ($prep_statement, $sql);
	if ($result_count > 0) {
		foreach($result as $row) {
			$created_epoch = $row['created_epoch'];
			$read_epoch = $row['read_epoch'];
			$voicemail_id = $row['username'];
			$domain_name = $row['domain'];
			$voicemail_message_uuid = $row['uuid'];
			$caller_id_name = $row['cid_name'];
			$caller_id_number = $row['cid_number'];
			//$in_folder = $row['in_folder'];
			//$file_path = $row['file_path']; // /usr/local/freeswitch/storage/voicemail/default/domain/1234/msg_91a5ca90-2767-11e2-9ebe-5dc9a6afc9fd.wav
			$message_length = $row['message_len'];
			$voicemail_status = $row['flags'];
			$voicemail_priority = $row['read_flags']; // B_NORMAL
			//$forwarded_by = $row['forwarded_by'];
			//print_r($row);

			//get the domain_uuid
			foreach($_SESSION['domains'] as $tmp) {
				if ($tmp['domain_name'] == $domain_name) {
					$domain_uuid = $tmp['domain_uuid'];
				}
			}

			//get the voicemail_uuid
			$voicemail_uuid = $mailbox[$voicemail_id]['voicemail_uuid'];

			$sql = "insert into v_voicemail_messages ";
			$sql .= "(";
			$sql .= "domain_uuid, ";
			$sql .= "voicemail_message_uuid, ";
			$sql .= "voicemail_uuid, ";
			$sql .= "created_epoch, ";
			$sql .= "read_epoch, ";
			$sql .= "caller_id_name, ";
			$sql .= "caller_id_number, ";
			$sql .= "message_length, ";
			$sql .= "message_status, ";
			$sql .= "message_priority ";
			$sql .= ") ";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'$domain_uuid', ";
			$sql .= "'$voicemail_message_uuid', ";
			$sql .= "'$voicemail_uuid', ";
			$sql .= "'$created_epoch', ";
			$sql .= "'$read_epoch', ";
			$sql .= "'$caller_id_name', ";
			$sql .= "'$caller_id_number', ";
			$sql .= "'$message_length', ";
			$sql .= "'$message_status', ";
			$sql .= "'$message_priority' ";
			$sql .= ");";
			$data .= $sql;
			unset($sql);
		}
		unset($prep_statement, $sql, $result, $row_count, $domain_uuid);
	}

//reset the database connection
	unset($db);
	require "includes/require.php";

//loop through the sql array
	$sql_array = explode(";", $data);
	foreach($sql_array as $sql) {
		echo $sql."\n";
		$db->exec(check_sql($sql));
	}

//show the footer
	echo "</pre>\n";
	require_once "includes/footer.php";

?>