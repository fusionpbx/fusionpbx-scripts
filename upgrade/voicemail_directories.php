<?php


$storage_dir = $_SESSION['switch']['storage']['dir'];
$sql = "select * from v_voicemails ";
$prep_statement = $db->prepare(check_sql($sql));
$prep_statement->execute();
$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
foreach ($result as &$row) {
	$domain_name = $_SESSION['domains'][$row["domain_uuid"]]['domain_name'];
	$voicemail_dir = $storage_dir . '/voicemail/default/'.$domain_name;
	if (!mkdir($voicemail_dir, 0744, true)) {
		die('Failed to create '.$voicemail_dir.');
	}
}
unset ($prep_statement);

?>