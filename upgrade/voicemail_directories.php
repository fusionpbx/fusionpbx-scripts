<?php

//migrate existing attachment preferences to new column, where appropriate
	$sql = "update v_voicemails set voicemail_file = 'attach' where voicemail_attach_file = 'true'";
	//$db->exec(check_sql($sql));
	//unset($sql);

//add that the directory structure for voicemail each domain and voicemail id is
	$sql = "select d.domain_name, v.voicemail_id ";
	$sql .= "from v_domains as d, v_voicemails as v ";
	$sql .= "where v.domain_uuid = d.domain_uuid ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$voicemails = $prep_statement->fetchAll(PDO::FETCH_ASSOC);
	foreach ($voicemails as $row) {
		$path = $_SESSION['switch']['voicemail']['dir'].'/default/'.$row['domain_name'].'/'.$row['voicemail_id'];
		if (!file_exists($path)) {
			event_socket_mkdir($path);
			//mkdir($path, 0744, true);
		}
	}
	unset ($prep_statement, $sql);

?>