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
if (permission_exists('voicemail_view')) {
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

//start the atomic transaction
	$db->exec("BEGIN;");

//ring group export
	echo "<pre>\n";
	$sql = "SELECT g.domain_uuid, g.ring_group_extension_uuid, g.ring_group_uuid, g.extension_delay, g.extension_timeout, e.extension, e.extension_uuid ";
	$sql .= "FROM v_ring_groups as r, v_ring_group_extensions as g, v_extensions as e ";
	$sql .= "where g.ring_group_uuid = r.ring_group_uuid ";
	$sql .= "and e.extension_uuid = g.extension_uuid ";
	$sql .= "order by g.extension_delay asc, e.extension asc ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	$result_count = count($result);
	foreach($result as $field) {
		if (strlen($field['extension_delay']) == 0) { $field['extension_delay'] = "0"; }
		if (strlen($field['extension_timeout']) == 0) { $field['extension_timeout'] = "30"; }
		$ring_group_uuid = $field['ring_group_uuid'];
		$ring_group_destination_uuid = $field['ring_group_extension_uuid'];
		$destination_number = $field['extension'];
		$destination_delay = $field['extension_delay'];
		$destination_timeout = $field['extension_timeout'];

		$sql = "insert into v_ring_group_destinations ";
		$sql .= "(";
		$sql .= "domain_uuid, ";
		$sql .= "ring_group_uuid, ";
		$sql .= "ring_group_destination_uuid, ";
		$sql .= "destination_delay, ";
		$sql .= "destination_timeout, ";
		$sql .= "destination_number ";
		$sql .= ") ";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$field['domain_uuid']."', ";
		$sql .= "'$ring_group_uuid', ";
		$sql .= "'$ring_group_destination_uuid', ";
		$sql .= "'$destination_delay', ";
		$sql .= "'$destination_timeout', ";
		$sql .= "'$destination_number' ";
		$sql .= ");";
		$db->exec(check_sql($sql));
		echo $sql."\n";
		unset($sql);
	}
	echo "completed";
	echo "<pre>\n";

//commit the atomic transaction
	$count = $db->exec("COMMIT;"); //returns affected rows

//show the footer
	echo "</pre>\n";
	require_once "resources/footer.php";

?>