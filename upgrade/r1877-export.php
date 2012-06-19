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
require_once "includes/config.php";
require_once "includes/checkauth.php";
if (ifgroup("superadmin")) {
	//access granted
}
else {
	echo "access denied";
	exit;
}

//user defined settings
	$export_type = "sql"; //sql, db (for sqlite)
	$debug = false;
	$invoices = false; //default false;
	$db_type = "sqlite"; //pgsql, sqlite, mysql

//used for debugging
	if ($debug) {
		echo "<pre>\n";
	}

//create the destination database object
	if ($export_type == "db") {
		$dest_db = new PDO('sqlite:/tmp/fusionpbx.db');
	}

//set the headers
	if ($export_type == "sql" && !$debug) {
		header('Content-type: application/octet-binary');
		header('Content-Disposition: attachment; filename=database_backup.sql');
	}

//add an rfc compliant version 4 uuid function
	if (!function_exists('uuid')) {
		function uuid() {
			return sprintf( '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
				// 32 bits for 'time_low'
				mt_rand( 0, 0xffff ), mt_rand( 0, 0xffff ),

				// 16 bits 'for time_mid'
				mt_rand( 0, 0xffff ),

				// 16 bits for 'time_hi_and_version',
				// four most significant bits holds version number 4
				mt_rand( 0, 0x0fff ) | 0x4000,

				// 16 bits, 8 bits for 'clk_seq_hi_res',
				// 8 bits for 'clk_seq_low',
				// two most significant bits holds zero and one for variant DCE1.1
				mt_rand( 0, 0x3fff ) | 0x8000,

				// 48 bits for 'node'
				mt_rand( 0, 0xffff ), mt_rand( 0, 0xffff ), mt_rand( 0, 0xffff )
			);
		}
	}

$schema_pgsql = <<<EOD
CREATE TABLE v_call_broadcasts (
call_call_broadcast_uuid uuid PRIMARY KEY,
domain_uuid uuid,
broadcast_name text,
broadcast_description text,
broadcast_timeout numeric,
broadcast_concurrent_limit numeric,
recording_uuid uuid,
broadcast_caller_id_name text,
broadcast_caller_id_number text,
broadcast_destination_type text,
broadcast_phone_numbers text,
broadcast_destination_data text);

CREATE TABLE v_call_center_agents (
call_center_agent_uuid uuid PRIMARY KEY,
domain_uuid uuid,
agent_name text,
agent_type text,
agent_call_timeout numeric,
agent_contact text,
agent_status text,
agent_logout text,
agent_max_no_answer numeric,
agent_wrap_up_time numeric,
agent_reject_delay_time numeric,
agent_busy_delay_time numeric,
agent_no_answer_delay_time text);

CREATE TABLE v_call_center_logs (
cc_uuid uuid PRIMARY KEY,
domain_uuid uuid,
cc_queue text,
cc_action text,
cc_count numeric,
cc_agent text,
cc_agent_system text,
cc_agent_status text,
cc_agent_state text,
cc_agent_uuid uuid,
cc_selection text,
cc_cause text,
cc_wait_time text,
cc_talk_time text,
cc_total_time text,
cc_epoch numeric,
cc_date timestamp,
cc_agent_type text,
cc_member_uuid text,
cc_member_session_uuid text,
cc_member_cid_name text,
cc_member_cid_number text,
cc_agent_called_time numeric,
cc_agent_answered_time numeric,
cc_member_joined_time numeric,
cc_member_leaving_time numeric,
cc_bridge_terminated_time numeric,
cc_hangup_cause text);

CREATE TABLE v_call_center_queues (
call_center_queue_uuid uuid PRIMARY KEY,
domain_uuid uuid,
dialplan_uuid uuid,
queue_name text,
queue_extension text,
queue_strategy text,
queue_moh_sound text,
queue_record_template text,
queue_time_base_score text,
queue_max_wait_time numeric,
queue_max_wait_time_with_no_agent numeric,
queue_tier_rules_apply text,
queue_tier_rule_wait_second numeric,
queue_tier_rule_no_agent_no_wait text,
queue_timeout_action text,
queue_discard_abandoned_after numeric,
queue_abandoned_resume_allowed text,
queue_tier_rule_wait_multiply_level text,
queue_cid_prefix text,
queue_description text);

CREATE TABLE v_call_center_tiers (
call_center_tier_uuid uuid PRIMARY KEY,
domain_uuid uuid,
agent_name text,
queue_name text,
tier_level numeric,
tier_position numeric);

CREATE TABLE v_conferences (
domain_uuid uuid,
conference_uuid uuid PRIMARY KEY,
dialplan_uuid uuid,
conference_name text,
conference_extension text,
conference_pin_number text,
conference_profile text,
conference_flags text,
conference_order numeric,
conference_description text,
conference_enabled text);

CREATE TABLE v_conference_users (
conference_user_uuid uuid PRIMARY KEY,
domain_uuid uuid,
conference_uuid uuid,
user_uuid uuid);

CREATE TABLE v_contacts (
contact_uuid uuid PRIMARY KEY,
domain_uuid uuid,
contact_type text,
contact_organization text,
contact_name_given text,
contact_name_family text,
contact_nickname text,
contact_title text,
contact_role text,
contact_email text,
contact_url text,
contact_time_zone text,
contact_note text);

CREATE TABLE v_contact_addresses (
contact_address_uuid uuid PRIMARY KEY,
domain_uuid uuid,
contact_uuid uuid,
address_type text,
address_street text,
address_extended text,
address_locality text,
address_region text,
address_postal_code text,
address_country text,
address_latitude text,
address_longitude text);

CREATE TABLE v_contact_phones (
contact_phone_uuid uuid PRIMARY KEY,
domain_uuid uuid,
contact_uuid uuid,
phone_type text,
phone_number text);

CREATE TABLE v_contact_notes (
contact_note_uuid uuid PRIMARY KEY,
domain_uuid uuid,
contact_uuid uuid,
contact_note text,
last_mod_date text,
last_mod_user text);

CREATE TABLE v_rss (
rss_uuid uuid PRIMARY KEY,
domain_uuid uuid,
rss_language text,
rss_category text,
rss_sub_category text,
rss_title text,
rss_link text,
rss_description text,
rss_img bytea,
rss_optional_1 text,
rss_optional_2 text,
rss_optional_3 text,
rss_optional_4 text,
rss_optional_5 text,
rss_add_date text,
rss_add_user text,
rss_del_date text,
rss_del_user text,
rss_order numeric,
rss_content text,
rss_group text);

CREATE TABLE v_rss_sub (
rss_sub_uuid uuid PRIMARY KEY,
domain_uuid uuid,
rss_uuid uuid,
rss_sub_language text,
rss_sub_title text,
rss_sub_link text,
rss_sub_description text,
rss_sub_optional_1 text,
rss_sub_optional_2 text,
rss_sub_optional_3 text,
rss_sub_optional_4 text,
rss_sub_optional_5 text,
rss_sub_add_date text,
rss_sub_add_user text,
rss_sub_del_user text,
rss_sub_del_date text);

CREATE TABLE v_rss_sub_category (
rss_sub_category_uuid uuid PRIMARY KEY,
domain_uuid uuid,
rss_sub_category_language text,
rss_category text,
rss_sub_category text,
rss_sub_category_description text,
rss_sub_add_user text,
rss_sub_add_date text);

CREATE TABLE v_destinations (
domain_uuid uuid,
destination_uuid uuid PRIMARY KEY,
destination_name text,
destination_context text,
destination_extension text,
destination_enabled text,
destination_description text);

CREATE TABLE v_dialplans (
domain_uuid uuid,
dialplan_uuid uuid PRIMARY KEY,
app_uuid uuid,
dialplan_context text,
dialplan_name text,
dialplan_number text,
dialplan_continue text,
dialplan_order numeric,
dialplan_enabled text,
dialplan_description text);

CREATE TABLE v_dialplan_details (
domain_uuid uuid,
dialplan_uuid uuid,
dialplan_detail_uuid uuid PRIMARY KEY,
dialplan_detail_tag text,
dialplan_detail_type text,
dialplan_detail_data text,
dialplan_detail_break text,
dialplan_detail_inline text,
dialplan_detail_group numeric,
dialplan_detail_order numeric);

CREATE TABLE v_extensions (
extension_uuid uuid PRIMARY KEY,
domain_uuid uuid,
extension text,
number_alias text,
password text,
provisioning_list text,
mailbox text,
vm_password text,
accountcode text,
effective_caller_id_name text,
effective_caller_id_number text,
outbound_caller_id_name text,
outbound_caller_id_number text,
emergency_caller_id_number text,
directory_full_name text,
directory_visible text,
directory_exten_visible text,
limit_max numeric,
limit_destination text,
vm_enabled text,
vm_mailto text,
vm_attach_file text,
vm_keep_local_after_email text,
user_context text,
toll_allow text,
call_group text,
hold_music text,
auth_acl text,
cidr text,
sip_force_contact text,
nibble_account numeric,
sip_force_expires numeric,
enabled text,
description text,
mwi_account text,
sip_bypass_media text);

CREATE TABLE v_extension_users (
extension_user_uuid uuid PRIMARY KEY,
domain_uuid uuid,
extension_uuid uuid,
user_uuid uuid);

CREATE TABLE v_fax (
fax_uuid uuid PRIMARY KEY,
domain_uuid uuid,
dialplan_uuid uuid,
fax_extension text,
fax_name text,
fax_email text,
fax_pin_number text,
fax_caller_id_name text,
fax_caller_id_number text,
fax_forward_number numeric,
fax_description text);

CREATE TABLE v_fax_users (
fax_user_uuid uuid PRIMARY KEY,
domain_uuid uuid,
fax_uuid uuid,
user_uuid uuid);

CREATE TABLE v_gateways (
gateway_uuid uuid PRIMARY KEY,
domain_uuid uuid,
gateway text,
username text,
password text,
distinct_to text,
auth_username text,
realm text,
from_user text,
from_domain text,
proxy text,
register_proxy text,
outbound_proxy text,
expire_seconds numeric,
register text,
register_transport text,
retry_seconds numeric,
extension text,
ping text,
caller_id_in_from text,
supress_cng text,
sip_cid_type text,
extension_in_contact text,
context text,
profile text,
enabled text,
description text);

CREATE TABLE v_hardware_phones (
hardware_phone_uuid uuid PRIMARY KEY,
domain_uuid uuid,
phone_mac_address text,
phone_label text,
phone_vendor text,
phone_model text,
phone_firmware_version text,
phone_provision_enable text,
phone_template text,
phone_username text,
phone_password text,
phone_time_zone text,
phone_description text);

CREATE TABLE v_hunt_groups (
hunt_group_uuid uuid PRIMARY KEY,
domain_uuid uuid,
dialplan_uuid uuid,
hunt_group_extension text,
hunt_group_name text,
hunt_group_type text,
hunt_group_context text,
hunt_group_timeout text,
hunt_group_timeout_destination text,
hunt_group_timeout_type text,
hunt_group_ringback text,
hunt_group_cid_name_prefix text,
hunt_group_pin text,
hunt_group_caller_announce text,
hunt_group_call_prompt text,
hunt_group_user_list text,
hunt_group_enabled text,
hunt_group_description text);

CREATE TABLE v_hunt_group_destinations (
hunt_group_destination_uuid uuid PRIMARY KEY,
domain_uuid uuid,
hunt_group_uuid uuid,
destination_data text,
destination_type text,
destination_profile text,
destination_timeout text,
destination_order numeric,
destination_enabled text,
destination_description text);

CREATE TABLE v_hunt_group_users (
hunt_group_user_uuid uuid PRIMARY KEY,
domain_uuid uuid,
hunt_group_uuid uuid,
user_uuid uuid);

CREATE TABLE v_invoices (
invoice_uuid uuid,
domain_uuid uuid,
contact_uuid_from uuid,
contact_uuid_to uuid,
invoice_number numeric,
invoice_date timestamp with time zone,
invoice_notes text);

CREATE TABLE v_invoice_items (
invoice_item_uuid uuid,
domain_uuid uuid,
invoice_uuid uuid,
item_qty numeric,
item_desc text,
item_unit_price numeric);

CREATE TABLE v_ivr_menus (
ivr_menu_uuid uuid PRIMARY KEY,
domain_uuid uuid,
dialplan_uuid uuid,
ivr_menu_name text,
ivr_menu_extension numeric,
ivr_menu_greet_long text,
ivr_menu_greet_short text,
ivr_menu_invalid_sound text,
ivr_menu_exit_sound text,
ivr_menu_confirm_macro text,
ivr_menu_confirm_key text,
ivr_menu_tts_engine text,
ivr_menu_tts_voice text,
ivr_menu_confirm_attempts numeric,
ivr_menu_timeout numeric,
ivr_menu_exit_app text,
ivr_menu_exit_data text,
ivr_menu_inter_digit_timeout numeric,
ivr_menu_max_failures numeric,
ivr_menu_max_timeouts numeric,
ivr_menu_digit_len numeric,
ivr_menu_direct_dial text,
ivr_menu_enabled text,
ivr_menu_description text);

CREATE TABLE v_ivr_menu_options (
ivr_menu_option_uuid uuid PRIMARY KEY,
ivr_menu_uuid uuid,
domain_uuid uuid,
ivr_menu_option_digits text,
ivr_menu_option_action text,
ivr_menu_option_param text,
ivr_menu_option_order numeric,
ivr_menu_option_description text);

CREATE TABLE v_modules (
module_uuid uuid PRIMARY KEY,
module_label text,
module_name text,
module_category text,
module_enabled text,
module_default_enabled text,
module_description text);

CREATE TABLE v_clips (
clip_uuid uuid PRIMARY KEY,
clip_name text,
clip_folder text,
clip_text_start text,
clip_text_end text,
clip_order text,
clip_desc text);

CREATE TABLE v_php_services (
php_service_uuid uuid PRIMARY KEY,
domain_uuid uuid,
service_name text,
service_script text,
service_enabled text,
service_description text);

CREATE TABLE v_recordings (
recording_uuid uuid PRIMARY KEY,
domain_uuid uuid,
recording_filename text,
recording_name text,
recording_description text);

CREATE TABLE v_ring_groups (
domain_uuid uuid,
ring_group_uuid uuid,
ring_group_name text,
ring_group_extension text,
ring_group_context text,
ring_group_strategy text,
ring_group_timeout_sec numeric,
ring_group_timeout_app text,
ring_group_timeout_data text,
ring_group_enabled text,
ring_group_description text,
dialplan_uuid uuid);

CREATE TABLE v_ring_group_extensions (
ring_group_extension_uuid uuid,
domain_uuid uuid,
ring_group_uuid uuid,
extension_uuid uuid);

CREATE TABLE v_services (
service_uuid uuid PRIMARY KEY,
domain_uuid uuid,
service_name text,
service_type text,
service_data text,
service_cmd_start text,
service_cmd_stop text,
service_cmd_restart text,
service_description text);

CREATE TABLE v_settings (
numbering_plan text,
event_socket_ip_address text,
event_socket_port text,
event_socket_password text,
xml_rpc_http_port text,
xml_rpc_auth_realm text,
xml_rpc_auth_user text,
xml_rpc_auth_pass text,
admin_pin numeric,
smtp_host text,
smtp_secure text,
smtp_auth text,
smtp_username text,
smtp_password text,
smtp_from text,
smtp_from_name text,
mod_shout_decoder text,
mod_shout_volume text);

CREATE TABLE v_sip_profiles (
sip_profile_uuid uuid,
sip_profile_name text,
sip_profile_description text);

CREATE TABLE v_sip_profile_settings (
sip_profile_setting_uuid uuid,
sip_profile_uuid uuid,
sip_profile_setting_name text,
sip_profile_setting_value text,
sip_profile_setting_enabled text,
sip_profile_setting_description text);

CREATE TABLE v_software (
software_name text,
software_url text,
software_version text);

CREATE TABLE v_vars (
var_uuid uuid PRIMARY KEY,
var_name text,
var_value text,
var_cat text,
var_enabled text,
var_order numeric,
var_description text);

CREATE TABLE v_virtual_table_data (
virtual_table_data_uuid uuid PRIMARY KEY,
domain_uuid uuid,
virtual_table_uuid uuid,
virtual_data_row_uuid text,
virtual_field_name text,
virtual_data_field_value text,
virtual_data_add_user text,
virtual_data_add_date text,
virtual_data_del_user text,
virtual_data_del_date text,
virtual_table_parent_uuid uuid,
virtual_data_parent_row_uuid text);

CREATE TABLE v_virtual_table_data_types_name_value (
virtual_table_data_types_name_value_uuid uuid PRIMARY KEY,
domain_uuid uuid,
virtual_table_uuid uuid,
virtual_table_field_uuid uuid,
virtual_data_types_name text,
virtual_data_types_value text);

CREATE TABLE v_virtual_table_fields (
virtual_table_field_uuid uuid PRIMARY KEY,
domain_uuid uuid,
virtual_table_uuid uuid,
virtual_field_label text,
virtual_field_name text,
virtual_field_type text,
virtual_field_list_hidden text,
virtual_field_column text,
virtual_field_required text,
virtual_field_order numeric,
virtual_field_order_tab numeric,
virtual_field_description text,
virtual_field_value text);

CREATE TABLE v_virtual_tables (
virtual_table_uuid uuid PRIMARY KEY,
domain_uuid uuid,
virtual_table_category text,
virtual_table_label text,
virtual_table_name text,
virtual_table_auth text,
virtual_table_captcha text,
virtual_table_parent_uuid uuid,
virtual_table_description text);

CREATE TABLE v_voicemail_greetings (
greeting_uuid uuid PRIMARY KEY,
domain_uuid uuid,
user_id text,
greeting_name text,
greeting_description text);

CREATE TABLE v_xml_cdr (
uuid uuid PRIMARY KEY,
domain_uuid uuid,
domain_name text,
accountcode text,
direction text,
default_language text,
context text,
xml_cdr text,
caller_id_name text,
caller_id_number text,
destination_number text,
start_epoch numeric,
start_stamp timestamp,
answer_stamp timestamp,
answer_epoch numeric,
end_epoch numeric,
end_stamp text,
duration numeric,
mduration numeric,
billsec numeric,
billmsec numeric,
bridge_uuid text,
read_codec text,
read_rate text,
write_codec text,
write_rate text,
remote_media_ip text,
network_addr text,
recording_file text,
leg char(1),
pdd_ms numeric,
last_app text,
last_arg text,
cc_side text,
cc_member_uuid uuid,
cc_queue_joined_epoch text,
cc_queue text,
cc_member_session_uuid uuid,
cc_agent text,
cc_agent_type text,
waitsec numeric,
conference_name text,
conference_uuid uuid,
conference_member_id text,
digits_dialed text,
hangup_cause text,
hangup_cause_q850 numeric,
sip_hangup_disposition text);

CREATE TABLE v_xmpp (
xmpp_profile_uuid uuid PRIMARY KEY,
domain_uuid uuid,
profile_name text,
username text,
password text,
dialplan text,
context text,
rtp_ip text,
ext_rtp_ip text,
auto_login text,
sasl_type text,
xmpp_server text,
tls_enable text,
usr_rtp_timer text,
default_exten text,
vad text,
avatar text,
candidate_acl text,
local_network_acl text,
enabled text,
description text);

CREATE TABLE v_apps (
app_uuid uuid);

CREATE TABLE v_databases (
database_uuid uuid PRIMARY KEY,
database_type text,
database_host text,
database_port text,
database_name text,
database_username text,
database_password text,
database_path text,
database_description text);

CREATE TABLE v_default_settings (
default_setting_uuid uuid PRIMARY KEY,
default_setting_category text,
default_setting_subcategory text,
default_setting_name text,
default_setting_value text,
default_setting_enabled text,
default_setting_description text);

CREATE TABLE v_domains (
domain_uuid uuid PRIMARY KEY,
domain_name text,
domain_description text);

CREATE TABLE v_domain_settings (
domain_uuid uuid,
domain_setting_uuid uuid PRIMARY KEY,
domain_setting_category text,
domain_setting_subcategory text,
domain_setting_name text,
domain_setting_value text,
domain_setting_enabled text,
domain_setting_description text);

CREATE TABLE v_menus (
menu_uuid uuid PRIMARY KEY,
menu_name text,
menu_language text,
menu_description text);

CREATE TABLE v_menu_items (
menu_item_uuid uuid,
menu_uuid uuid,
menu_item_parent_uuid uuid,
menu_item_title text,
menu_item_link text,
menu_item_category text,
menu_item_protected text,
menu_item_order numeric,
menu_item_description text,
menu_item_add_user text,
menu_item_add_date text,
menu_item_mod_user text,
menu_item_mod_date text);

CREATE TABLE v_menu_item_groups (
menu_uuid uuid,
menu_item_uuid uuid,
group_name text);

CREATE TABLE v_users (
user_uuid uuid PRIMARY KEY,
domain_uuid uuid,
username text,
password text,
salt text,
contact_uuid uuid,
user_status text,
user_add_user text,
user_add_date text);

CREATE TABLE v_groups (
group_uuid uuid PRIMARY KEY,
domain_uuid uuid,
group_name text,
group_description text);

CREATE TABLE v_group_users (
group_user_uuid uuid PRIMARY KEY,
domain_uuid uuid,
group_name text,
user_uuid uuid);

CREATE TABLE v_group_permissions (
group_permission_uuid uuid PRIMARY KEY,
domain_uuid uuid,
permission_name text,
group_name text);

CREATE TABLE v_user_settings (
user_setting_uuid uuid PRIMARY KEY,
user_uuid uuid,
user_setting_category text,
user_setting_subcategory text,
user_setting_name text,
user_setting_value text,
user_setting_enabled text,
user_setting_description text);
EOD;

$schema_sqlite = <<<EOD

CREATE TABLE v_call_broadcasts (
call_call_broadcast_uuid text PRIMARY KEY,
domain_uuid text,
broadcast_name text,
broadcast_description text,
broadcast_timeout numeric,
broadcast_concurrent_limit numeric,
recording_uuid text,
broadcast_caller_id_name text,
broadcast_caller_id_number text,
broadcast_destination_type text,
broadcast_phone_numbers text,
broadcast_destination_data text);

CREATE TABLE v_call_center_agents (
call_center_agent_uuid text PRIMARY KEY,
domain_uuid text,
agent_name text,
agent_type text,
agent_call_timeout numeric,
agent_contact text,
agent_status text,
agent_logout text,
agent_max_no_answer numeric,
agent_wrap_up_time numeric,
agent_reject_delay_time numeric,
agent_busy_delay_time numeric,
agent_no_answer_delay_time text);

CREATE TABLE v_call_center_logs (
cc_uuid text PRIMARY KEY,
domain_uuid text,
cc_queue text,
cc_action text,
cc_count numeric,
cc_agent text,
cc_agent_system text,
cc_agent_status text,
cc_agent_state text,
cc_agent_uuid text,
cc_selection text,
cc_cause text,
cc_wait_time text,
cc_talk_time text,
cc_total_time text,
cc_epoch numeric,
cc_date date,
cc_agent_type text,
cc_member_uuid text,
cc_member_session_uuid text,
cc_member_cid_name text,
cc_member_cid_number text,
cc_agent_called_time numeric,
cc_agent_answered_time numeric,
cc_member_joined_time numeric,
cc_member_leaving_time numeric,
cc_bridge_terminated_time numeric,
cc_hangup_cause text);

CREATE TABLE v_call_center_queues (
call_center_queue_uuid text PRIMARY KEY,
domain_uuid text,
dialplan_uuid text,
queue_name text,
queue_extension text,
queue_strategy text,
queue_moh_sound text,
queue_record_template text,
queue_time_base_score text,
queue_max_wait_time numeric,
queue_max_wait_time_with_no_agent numeric,
queue_tier_rules_apply text,
queue_tier_rule_wait_second numeric,
queue_tier_rule_no_agent_no_wait text,
queue_timeout_action text,
queue_discard_abandoned_after numeric,
queue_abandoned_resume_allowed text,
queue_tier_rule_wait_multiply_level text,
queue_cid_prefix text,
queue_description text);

CREATE TABLE v_call_center_tiers (
call_center_tier_uuid text PRIMARY KEY,
domain_uuid text,
agent_name text,
queue_name text,
tier_level numeric,
tier_position numeric);

CREATE TABLE v_conferences (
domain_uuid text,
conference_uuid text PRIMARY KEY,
dialplan_uuid text,
conference_name text,
conference_extension text,
conference_pin_number text,
conference_profile text,
conference_flags text,
conference_order numeric,
conference_description text,
conference_enabled text);

CREATE TABLE v_conference_users (
conference_user_uuid text PRIMARY KEY,
domain_uuid text,
conference_uuid text,
user_uuid text);

CREATE TABLE v_contacts (
contact_uuid text PRIMARY KEY,
domain_uuid text,
contact_type text,
contact_organization text,
contact_name_given text,
contact_name_family text,
contact_nickname text,
contact_title text,
contact_role text,
contact_email text,
contact_url text,
contact_time_zone text,
contact_note text);

CREATE TABLE v_contact_addresses (
contact_address_uuid text PRIMARY KEY,
domain_uuid text,
contact_uuid text,
address_type text,
address_street text,
address_extended text,
address_locality text,
address_region text,
address_postal_code text,
address_country text,
address_latitude text,
address_longitude text);

CREATE TABLE v_contact_phones (
contact_phone_uuid text PRIMARY KEY,
domain_uuid text,
contact_uuid text,
phone_type text,
phone_number text);

CREATE TABLE v_contact_notes (
contact_note_uuid text PRIMARY KEY,
domain_uuid text,
contact_uuid text,
contact_note text,
last_mod_date text,
last_mod_user text);

CREATE TABLE v_rss (
rss_uuid text PRIMARY KEY,
domain_uuid text,
rss_language text,
rss_category text,
rss_sub_category text,
rss_title text,
rss_link text,
rss_description text,
rss_img blob,
rss_optional_1 text,
rss_optional_2 text,
rss_optional_3 text,
rss_optional_4 text,
rss_optional_5 text,
rss_add_date text,
rss_add_user text,
rss_del_date text,
rss_del_user text,
rss_order numeric,
rss_content text,
rss_group text);

CREATE TABLE v_rss_sub (
rss_sub_uuid text PRIMARY KEY,
domain_uuid text,
rss_uuid text,
rss_sub_language text,
rss_sub_title text,
rss_sub_link text,
rss_sub_description text,
rss_sub_optional_1 text,
rss_sub_optional_2 text,
rss_sub_optional_3 text,
rss_sub_optional_4 text,
rss_sub_optional_5 text,
rss_sub_add_date text,
rss_sub_add_user text,
rss_sub_del_user text,
rss_sub_del_date text);

CREATE TABLE v_rss_sub_category (
rss_sub_category_uuid text PRIMARY KEY,
domain_uuid text,
rss_sub_category_language text,
rss_category text,
rss_sub_category text,
rss_sub_category_description text,
rss_sub_add_user text,
rss_sub_add_date text);

CREATE TABLE v_destinations (
domain_uuid text,
destination_uuid text PRIMARY KEY,
destination_name text,
destination_context text,
destination_extension text,
destination_enabled text,
destination_description text);

CREATE TABLE v_dialplans (
domain_uuid text,
dialplan_uuid text PRIMARY KEY,
app_uuid text,
dialplan_context text,
dialplan_name text,
dialplan_number text,
dialplan_continue text,
dialplan_order numeric,
dialplan_enabled text,
dialplan_description text);

CREATE TABLE v_dialplan_details (
domain_uuid text,
dialplan_uuid text,
dialplan_detail_uuid text PRIMARY KEY,
dialplan_detail_tag text,
dialplan_detail_type text,
dialplan_detail_data text,
dialplan_detail_break text,
dialplan_detail_inline text,
dialplan_detail_group numeric,
dialplan_detail_order numeric);

CREATE TABLE v_extensions (
extension_uuid text PRIMARY KEY,
domain_uuid text,
extension text,
number_alias text,
password text,
provisioning_list text,
mailbox text,
vm_password text,
accountcode text,
effective_caller_id_name text,
effective_caller_id_number text,
outbound_caller_id_name text,
outbound_caller_id_number text,
emergency_caller_id_number text,
directory_full_name text,
directory_visible text,
directory_exten_visible text,
limit_max numeric,
limit_destination text,
vm_enabled text,
vm_mailto text,
vm_attach_file text,
vm_keep_local_after_email text,
user_context text,
toll_allow text,
call_group text,
hold_music text,
auth_acl text,
cidr text,
sip_force_contact text,
nibble_account numeric,
sip_force_expires numeric,
enabled text,
description text,
mwi_account text,
sip_bypass_media text);

CREATE TABLE v_extension_users (
extension_user_uuid text PRIMARY KEY,
domain_uuid text,
extension_uuid text,
user_uuid text);

CREATE TABLE v_fax (
fax_uuid text PRIMARY KEY,
domain_uuid text,
dialplan_uuid text,
fax_extension text,
fax_name text,
fax_email text,
fax_pin_number text,
fax_caller_id_name text,
fax_caller_id_number text,
fax_forward_number numeric,
fax_description text);

CREATE TABLE v_fax_users (
fax_user_uuid text PRIMARY KEY,
domain_uuid text,
fax_uuid text,
user_uuid text);

CREATE TABLE v_gateways (
gateway_uuid text PRIMARY KEY,
domain_uuid text,
gateway text,
username text,
password text,
distinct_to text,
auth_username text,
realm text,
from_user text,
from_domain text,
proxy text,
register_proxy text,
outbound_proxy text,
expire_seconds numeric,
register text,
register_transport text,
retry_seconds numeric,
extension text,
ping text,
caller_id_in_from text,
supress_cng text,
sip_cid_type text,
extension_in_contact text,
context text,
profile text,
enabled text,
description text);

CREATE TABLE v_hardware_phones (
hardware_phone_uuid text PRIMARY KEY,
domain_uuid text,
phone_mac_address text,
phone_label text,
phone_vendor text,
phone_model text,
phone_firmware_version text,
phone_provision_enable text,
phone_template text,
phone_username text,
phone_password text,
phone_time_zone text,
phone_description text);

CREATE TABLE v_hunt_groups (
hunt_group_uuid text PRIMARY KEY,
domain_uuid text,
dialplan_uuid text,
hunt_group_extension text,
hunt_group_name text,
hunt_group_type text,
hunt_group_context text,
hunt_group_timeout text,
hunt_group_timeout_destination text,
hunt_group_timeout_type text,
hunt_group_ringback text,
hunt_group_cid_name_prefix text,
hunt_group_pin text,
hunt_group_caller_announce text,
hunt_group_call_prompt text,
hunt_group_user_list text,
hunt_group_enabled text,
hunt_group_description text);

CREATE TABLE v_hunt_group_destinations (
hunt_group_destination_uuid text PRIMARY KEY,
domain_uuid text,
hunt_group_uuid text,
destination_data text,
destination_type text,
destination_profile text,
destination_timeout text,
destination_order numeric,
destination_enabled text,
destination_description text);

CREATE TABLE v_hunt_group_users (
hunt_group_user_uuid text PRIMARY KEY,
domain_uuid text,
hunt_group_uuid text,
user_uuid text);

CREATE TABLE v_invoices (
invoice_uuid text,
domain_uuid text,
contact_uuid_from text,
contact_uuid_to text,
invoice_number numeric,
invoice_date datetime,
invoice_notes text);

CREATE TABLE v_invoice_items (
invoice_item_uuid text,
domain_uuid text,
invoice_uuid text,
item_qty numeric,
item_desc text,
item_unit_price numeric);

CREATE TABLE v_ivr_menus (
ivr_menu_uuid text PRIMARY KEY,
domain_uuid text,
dialplan_uuid text,
ivr_menu_name text,
ivr_menu_extension numeric,
ivr_menu_greet_long text,
ivr_menu_greet_short text,
ivr_menu_invalid_sound text,
ivr_menu_exit_sound text,
ivr_menu_confirm_macro text,
ivr_menu_confirm_key text,
ivr_menu_tts_engine text,
ivr_menu_tts_voice text,
ivr_menu_confirm_attempts numeric,
ivr_menu_timeout numeric,
ivr_menu_exit_app text,
ivr_menu_exit_data text,
ivr_menu_inter_digit_timeout numeric,
ivr_menu_max_failures numeric,
ivr_menu_max_timeouts numeric,
ivr_menu_digit_len numeric,
ivr_menu_direct_dial text,
ivr_menu_enabled text,
ivr_menu_description text);

CREATE TABLE v_ivr_menu_options (
ivr_menu_option_uuid text PRIMARY KEY,
ivr_menu_uuid text,
domain_uuid text,
ivr_menu_option_digits text,
ivr_menu_option_action text,
ivr_menu_option_param text,
ivr_menu_option_order numeric,
ivr_menu_option_description text);

CREATE TABLE v_modules (
module_uuid text PRIMARY KEY,
module_label text,
module_name text,
module_category text,
module_enabled text,
module_default_enabled text,
module_description text);

CREATE TABLE v_clips (
clip_uuid text PRIMARY KEY,
clip_name text,
clip_folder text,
clip_text_start text,
clip_text_end text,
clip_order text,
clip_desc text);

CREATE TABLE v_php_services (
php_service_uuid text PRIMARY KEY,
domain_uuid text,
service_name text,
service_script text,
service_enabled text,
service_description text);

CREATE TABLE v_recordings (
recording_uuid text PRIMARY KEY,
domain_uuid text,
recording_filename text,
recording_name text,
recording_description text);

CREATE TABLE v_ring_groups (
domain_uuid text,
ring_group_uuid text,
ring_group_name text,
ring_group_extension text,
ring_group_context text,
ring_group_strategy text,
ring_group_timeout_sec numeric,
ring_group_timeout_app text,
ring_group_timeout_data text,
ring_group_enabled text,
ring_group_description text,
dialplan_uuid text);

CREATE TABLE v_ring_group_extensions (
ring_group_extension_uuid text,
domain_uuid text,
ring_group_uuid text,
extension_uuid text);

CREATE TABLE v_services (
service_uuid text PRIMARY KEY,
domain_uuid text,
service_name text,
service_type text,
service_data text,
service_cmd_start text,
service_cmd_stop text,
service_cmd_restart text,
service_description text);

CREATE TABLE v_settings (
numbering_plan text,
event_socket_ip_address text,
event_socket_port text,
event_socket_password text,
xml_rpc_http_port text,
xml_rpc_auth_realm text,
xml_rpc_auth_user text,
xml_rpc_auth_pass text,
admin_pin numeric,
smtp_host text,
smtp_secure text,
smtp_auth text,
smtp_username text,
smtp_password text,
smtp_from text,
smtp_from_name text,
mod_shout_decoder text,
mod_shout_volume text);

CREATE TABLE v_sip_profiles (
sip_profile_uuid text,
sip_profile_name text,
sip_profile_description text);

CREATE TABLE v_sip_profile_settings (
sip_profile_setting_uuid text,
sip_profile_uuid text,
sip_profile_setting_name text,
sip_profile_setting_value text,
sip_profile_setting_enabled text,
sip_profile_setting_description text);

CREATE TABLE v_software (
software_name text,
software_url text,
software_version text);

CREATE TABLE v_vars (
var_uuid text PRIMARY KEY,
var_name text,
var_value text,
var_cat text,
var_enabled text,
var_order numeric,
var_description text);

CREATE TABLE v_virtual_table_data (
virtual_table_data_uuid text PRIMARY KEY,
domain_uuid text,
virtual_table_uuid text,
virtual_data_row_uuid text,
virtual_field_name text,
virtual_data_field_value text,
virtual_data_add_user text,
virtual_data_add_date text,
virtual_data_del_user text,
virtual_data_del_date text,
virtual_table_parent_uuid text,
virtual_data_parent_row_uuid text);

CREATE TABLE v_virtual_table_data_types_name_value (
virtual_table_data_types_name_value_uuid text PRIMARY KEY,
domain_uuid text,
virtual_table_uuid text,
virtual_table_field_uuid text,
virtual_data_types_name text,
virtual_data_types_value text);

CREATE TABLE v_virtual_table_fields (
virtual_table_field_uuid text PRIMARY KEY,
domain_uuid text,
virtual_table_uuid text,
virtual_field_label text,
virtual_field_name text,
virtual_field_type text,
virtual_field_list_hidden text,
virtual_field_column text,
virtual_field_required text,
virtual_field_order numeric,
virtual_field_order_tab numeric,
virtual_field_description text,
virtual_field_value text);

CREATE TABLE v_virtual_tables (
virtual_table_uuid text PRIMARY KEY,
domain_uuid text,
virtual_table_category text,
virtual_table_label text,
virtual_table_name text,
virtual_table_auth text,
virtual_table_captcha text,
virtual_table_parent_uuid text,
virtual_table_description text);

CREATE TABLE v_voicemail_greetings (
greeting_uuid text PRIMARY KEY,
domain_uuid text,
user_id text,
greeting_name text,
greeting_description text);

CREATE TABLE v_xml_cdr (
uuid text PRIMARY KEY,
domain_uuid text,
domain_name text,
accountcode text,
direction text,
default_language text,
context text,
xml_cdr text,
caller_id_name text,
caller_id_number text,
destination_number text,
start_epoch numeric,
start_stamp date,
answer_stamp date,
answer_epoch numeric,
end_epoch numeric,
end_stamp text,
duration numeric,
mduration numeric,
billsec numeric,
billmsec numeric,
bridge_uuid text,
read_codec text,
read_rate text,
write_codec text,
write_rate text,
remote_media_ip text,
network_addr text,
recording_file text,
leg text,
pdd_ms numeric,
last_app text,
last_arg text,
cc_side text,
cc_member_uuid text,
cc_queue_joined_epoch text,
cc_queue text,
cc_member_session_uuid text,
cc_agent text,
cc_agent_type text,
waitsec numeric,
conference_name text,
conference_uuid text,
conference_member_id text,
digits_dialed text,
hangup_cause text,
hangup_cause_q850 numeric,
sip_hangup_disposition text);

CREATE TABLE v_xmpp (
xmpp_profile_uuid text PRIMARY KEY,
domain_uuid text,
profile_name text,
username text,
password text,
dialplan text,
context text,
rtp_ip text,
ext_rtp_ip text,
auto_login text,
sasl_type text,
xmpp_server text,
tls_enable text,
usr_rtp_timer text,
default_exten text,
vad text,
avatar text,
candidate_acl text,
local_network_acl text,
enabled text,
description text);

CREATE TABLE v_apps (
app_uuid text);

CREATE TABLE v_databases (
database_uuid text PRIMARY KEY,
database_type text,
database_host text,
database_port text,
database_name text,
database_username text,
database_password text,
database_path text,
database_description text);

CREATE TABLE v_default_settings (
default_setting_uuid text PRIMARY KEY,
default_setting_category text,
default_setting_subcategory text,
default_setting_name text,
default_setting_value text,
default_setting_enabled text,
default_setting_description text);

CREATE TABLE v_domains (
domain_uuid text PRIMARY KEY,
domain_name text,
domain_description text);

CREATE TABLE v_domain_settings (
domain_uuid text,
domain_setting_uuid text PRIMARY KEY,
domain_setting_category text,
domain_setting_subcategory text,
domain_setting_name text,
domain_setting_value text,
domain_setting_enabled text,
domain_setting_description text);

CREATE TABLE v_menus (
menu_uuid text PRIMARY KEY,
menu_name text,
menu_language text,
menu_description text);

CREATE TABLE v_menu_items (
menu_item_uuid text,
menu_uuid text,
menu_item_parent_uuid text,
menu_item_title text,
menu_item_link text,
menu_item_category text,
menu_item_protected text,
menu_item_order numeric,
menu_item_description text,
menu_item_add_user text,
menu_item_add_date text,
menu_item_mod_user text,
menu_item_mod_date text);

CREATE TABLE v_menu_item_groups (
menu_uuid text,
menu_item_uuid text,
group_name text);

CREATE TABLE v_users (
user_uuid text PRIMARY KEY,
domain_uuid text,
username text,
password text,
salt text,
contact_uuid text,
user_status text,
user_add_user text,
user_add_date text);

CREATE TABLE v_groups (
group_uuid text PRIMARY KEY,
domain_uuid text,
group_name text,
group_description text);

CREATE TABLE v_group_users (
group_user_uuid text PRIMARY KEY,
domain_uuid text,
group_name text,
user_uuid text);

CREATE TABLE v_group_permissions (
group_permission_uuid text PRIMARY KEY,
domain_uuid text,
permission_name text,
group_name text);

CREATE TABLE v_user_settings (
user_setting_uuid text PRIMARY KEY,
user_uuid text,
user_setting_category text,
user_setting_subcategory text,
user_setting_name text,
user_setting_value text,
user_setting_enabled text,
user_setting_description text);
EOD;

$schema_mysql = <<<EOD
CREATE TABLE v_call_broadcasts (
call_call_broadcast_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
broadcast_name text,
broadcast_description text,
broadcast_timeout numeric,
broadcast_concurrent_limit numeric,
recording_uuid char(36),
broadcast_caller_id_name text,
broadcast_caller_id_number text,
broadcast_destination_type text,
broadcast_phone_numbers text,
broadcast_destination_data text) ENGINE=INNODB;

CREATE TABLE v_call_center_agents (
call_center_agent_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
agent_name text,
agent_type text,
agent_call_timeout numeric,
agent_contact text,
agent_status text,
agent_logout text,
agent_max_no_answer numeric,
agent_wrap_up_time numeric,
agent_reject_delay_time numeric,
agent_busy_delay_time numeric,
agent_no_answer_delay_time text) ENGINE=INNODB;

CREATE TABLE v_call_center_logs (
cc_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
cc_queue text,
cc_action text,
cc_count numeric,
cc_agent text,
cc_agent_system text,
cc_agent_status text,
cc_agent_state text,
cc_agent_uuid char(36),
cc_selection text,
cc_cause text,
cc_wait_time text,
cc_talk_time text,
cc_total_time text,
cc_epoch numeric,
cc_date timestamp,
cc_agent_type text,
cc_member_uuid text,
cc_member_session_uuid text,
cc_member_cid_name text,
cc_member_cid_number text,
cc_agent_called_time numeric,
cc_agent_answered_time numeric,
cc_member_joined_time numeric,
cc_member_leaving_time numeric,
cc_bridge_terminated_time numeric,
cc_hangup_cause text) ENGINE=INNODB;

CREATE TABLE v_call_center_queues (
call_center_queue_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
dialplan_uuid char(36),
queue_name text,
queue_extension text,
queue_strategy text,
queue_moh_sound text,
queue_record_template text,
queue_time_base_score text,
queue_max_wait_time numeric,
queue_max_wait_time_with_no_agent numeric,
queue_tier_rules_apply text,
queue_tier_rule_wait_second numeric,
queue_tier_rule_no_agent_no_wait text,
queue_timeout_action text,
queue_discard_abandoned_after numeric,
queue_abandoned_resume_allowed text,
queue_tier_rule_wait_multiply_level text,
queue_cid_prefix text,
queue_description text) ENGINE=INNODB;

CREATE TABLE v_call_center_tiers (
call_center_tier_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
agent_name text,
queue_name text,
tier_level numeric,
tier_position numeric) ENGINE=INNODB;

CREATE TABLE v_conferences (
domain_uuid char(36),
conference_uuid char(36) PRIMARY KEY,
dialplan_uuid char(36),
conference_name text,
conference_extension text,
conference_pin_number text,
conference_profile text,
conference_flags text,
conference_order numeric,
conference_description text,
conference_enabled text) ENGINE=INNODB;

CREATE TABLE v_conference_users (
conference_user_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
conference_uuid char(36),
user_uuid char(36)) ENGINE=INNODB;

CREATE TABLE v_contacts (
contact_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
contact_type text,
contact_organization text,
contact_name_given text,
contact_name_family text,
contact_nickname text,
contact_title text,
contact_role text,
contact_email text,
contact_url text,
contact_time_zone text,
contact_note text) ENGINE=INNODB;

CREATE TABLE v_contact_addresses (
contact_address_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
contact_uuid char(36),
address_type text,
address_street text,
address_extended text,
address_locality text,
address_region text,
address_postal_code text,
address_country text,
address_latitude text,
address_longitude text) ENGINE=INNODB;

CREATE TABLE v_contact_phones (
contact_phone_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
contact_uuid char(36),
phone_type text,
phone_number text) ENGINE=INNODB;

CREATE TABLE v_contact_notes (
contact_note_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
contact_uuid char(36),
contact_note text,
last_mod_date text,
last_mod_user text) ENGINE=INNODB;

CREATE TABLE v_rss (
rss_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
rss_language text,
rss_category text,
rss_sub_category text,
rss_title text,
rss_link text,
rss_description text,
rss_img blob,
rss_optional_1 text,
rss_optional_2 text,
rss_optional_3 text,
rss_optional_4 text,
rss_optional_5 text,
rss_add_date text,
rss_add_user text,
rss_del_date text,
rss_del_user text,
rss_order numeric,
rss_content text,
rss_group text) ENGINE=INNODB;

CREATE TABLE v_rss_sub (
rss_sub_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
rss_uuid char(36),
rss_sub_language text,
rss_sub_title text,
rss_sub_link text,
rss_sub_description text,
rss_sub_optional_1 text,
rss_sub_optional_2 text,
rss_sub_optional_3 text,
rss_sub_optional_4 text,
rss_sub_optional_5 text,
rss_sub_add_date text,
rss_sub_add_user text,
rss_sub_del_user text,
rss_sub_del_date text) ENGINE=INNODB;

CREATE TABLE v_rss_sub_category (
rss_sub_category_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
rss_sub_category_language text,
rss_category text,
rss_sub_category text,
rss_sub_category_description text,
rss_sub_add_user text,
rss_sub_add_date text) ENGINE=INNODB;

CREATE TABLE v_destinations (
domain_uuid char(36),
destination_uuid char(36) PRIMARY KEY,
destination_name text,
destination_context text,
destination_extension text,
destination_enabled text,
destination_description text) ENGINE=INNODB;

CREATE TABLE v_dialplans (
domain_uuid char(36),
dialplan_uuid char(36) PRIMARY KEY,
app_uuid char(36),
dialplan_context text,
dialplan_name text,
dialplan_number text,
dialplan_continue text,
dialplan_order numeric,
dialplan_enabled text,
dialplan_description text) ENGINE=INNODB;

CREATE TABLE v_dialplan_details (
domain_uuid char(36),
dialplan_uuid char(36),
dialplan_detail_uuid char(36) PRIMARY KEY,
dialplan_detail_tag text,
dialplan_detail_type text,
dialplan_detail_data text,
dialplan_detail_break text,
dialplan_detail_inline text,
dialplan_detail_group numeric,
dialplan_detail_order numeric) ENGINE=INNODB;

CREATE TABLE v_extensions (
extension_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
extension text,
number_alias text,
password text,
provisioning_list text,
mailbox text,
vm_password text,
accountcode text,
effective_caller_id_name text,
effective_caller_id_number text,
outbound_caller_id_name text,
outbound_caller_id_number text,
emergency_caller_id_number text,
directory_full_name text,
directory_visible text,
directory_exten_visible text,
limit_max numeric,
limit_destination text,
vm_enabled text,
vm_mailto text,
vm_attach_file text,
vm_keep_local_after_email text,
user_context text,
toll_allow text,
call_group text,
hold_music text,
auth_acl text,
cidr text,
sip_force_contact text,
nibble_account numeric,
sip_force_expires numeric,
enabled text,
description text,
mwi_account text,
sip_bypass_media text) ENGINE=INNODB;

CREATE TABLE v_extension_users (
extension_user_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
extension_uuid char(36),
user_uuid char(36)) ENGINE=INNODB;

CREATE TABLE v_fax (
fax_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
dialplan_uuid char(36),
fax_extension text,
fax_name text,
fax_email text,
fax_pin_number text,
fax_caller_id_name text,
fax_caller_id_number text,
fax_forward_number numeric,
fax_description text) ENGINE=INNODB;

CREATE TABLE v_fax_users (
fax_user_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
fax_uuid char(36),
user_uuid char(36)) ENGINE=INNODB;

CREATE TABLE v_gateways (
gateway_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
gateway text,
username text,
password text,
distinct_to text,
auth_username text,
realm text,
from_user text,
from_domain text,
proxy text,
register_proxy text,
outbound_proxy text,
expire_seconds numeric,
register text,
register_transport text,
retry_seconds numeric,
extension text,
ping text,
caller_id_in_from text,
supress_cng text,
sip_cid_type text,
extension_in_contact text,
context text,
profile text,
enabled text,
description text) ENGINE=INNODB;

CREATE TABLE v_hardware_phones (
hardware_phone_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
phone_mac_address text,
phone_label text,
phone_vendor text,
phone_model text,
phone_firmware_version text,
phone_provision_enable text,
phone_template text,
phone_username text,
phone_password text,
phone_time_zone text,
phone_description text) ENGINE=INNODB;

CREATE TABLE v_hunt_groups (
hunt_group_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
dialplan_uuid char(36),
hunt_group_extension text,
hunt_group_name text,
hunt_group_type text,
hunt_group_context text,
hunt_group_timeout text,
hunt_group_timeout_destination text,
hunt_group_timeout_type text,
hunt_group_ringback text,
hunt_group_cid_name_prefix text,
hunt_group_pin text,
hunt_group_caller_announce text,
hunt_group_call_prompt text,
hunt_group_user_list text,
hunt_group_enabled text,
hunt_group_description text) ENGINE=INNODB;

CREATE TABLE v_hunt_group_destinations (
hunt_group_destination_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
hunt_group_uuid char(36),
destination_data text,
destination_type text,
destination_profile text,
destination_timeout text,
destination_order numeric,
destination_enabled text,
destination_description text) ENGINE=INNODB;

CREATE TABLE v_hunt_group_users (
hunt_group_user_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
hunt_group_uuid char(36),
user_uuid char(36)) ENGINE=INNODB;

CREATE TABLE v_invoices (
invoice_uuid char(36),
domain_uuid char(36),
contact_uuid_from char(36),
contact_uuid_to char(36),
invoice_number numeric,
invoice_date timestamp,
invoice_notes text) ENGINE=INNODB;

CREATE TABLE v_invoice_items (
invoice_item_uuid char(36),
domain_uuid char(36),
invoice_uuid char(36),
item_qty numeric,
item_desc text,
item_unit_price decimal(10,2)) ENGINE=INNODB;

CREATE TABLE v_ivr_menus (
ivr_menu_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
dialplan_uuid char(36),
ivr_menu_name text,
ivr_menu_extension numeric,
ivr_menu_greet_long text,
ivr_menu_greet_short text,
ivr_menu_invalid_sound text,
ivr_menu_exit_sound text,
ivr_menu_confirm_macro text,
ivr_menu_confirm_key text,
ivr_menu_tts_engine text,
ivr_menu_tts_voice text,
ivr_menu_confirm_attempts numeric,
ivr_menu_timeout numeric,
ivr_menu_exit_app text,
ivr_menu_exit_data text,
ivr_menu_inter_digit_timeout numeric,
ivr_menu_max_failures numeric,
ivr_menu_max_timeouts numeric,
ivr_menu_digit_len numeric,
ivr_menu_direct_dial text,
ivr_menu_enabled text,
ivr_menu_description text) ENGINE=INNODB;

CREATE TABLE v_ivr_menu_options (
ivr_menu_option_uuid char(36) PRIMARY KEY,
ivr_menu_uuid char(36),
domain_uuid char(36),
ivr_menu_option_digits text,
ivr_menu_option_action text,
ivr_menu_option_param text,
ivr_menu_option_order numeric,
ivr_menu_option_description text) ENGINE=INNODB;

CREATE TABLE v_modules (
module_uuid char(36) PRIMARY KEY,
module_label text,
module_name text,
module_category text,
module_enabled text,
module_default_enabled text,
module_description text) ENGINE=INNODB;

CREATE TABLE v_clips (
clip_uuid char(36) PRIMARY KEY,
clip_name text,
clip_folder text,
clip_text_start text,
clip_text_end text,
clip_order text,
clip_desc text) ENGINE=INNODB;

CREATE TABLE v_php_services (
php_service_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
service_name text,
service_script text,
service_enabled text,
service_description text) ENGINE=INNODB;

CREATE TABLE v_recordings (
recording_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
recording_filename text,
recording_name text,
recording_description text) ENGINE=INNODB;

CREATE TABLE v_ring_groups (
domain_uuid char(36),
ring_group_uuid char(36),
ring_group_name text,
ring_group_extension text,
ring_group_context text,
ring_group_strategy text,
ring_group_timeout_sec numeric,
ring_group_timeout_app text,
ring_group_timeout_data text,
ring_group_enabled text,
ring_group_description text,
dialplan_uuid char(36)) ENGINE=INNODB;

CREATE TABLE v_ring_group_extensions (
ring_group_extension_uuid char(36),
domain_uuid char(36),
ring_group_uuid char(36),
extension_uuid char(36)) ENGINE=INNODB;

CREATE TABLE v_services (
service_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
service_name text,
service_type text,
service_data text,
service_cmd_start text,
service_cmd_stop text,
service_cmd_restart text,
service_description text) ENGINE=INNODB;

CREATE TABLE v_settings (
numbering_plan text,
event_socket_ip_address text,
event_socket_port text,
event_socket_password text,
xml_rpc_http_port text,
xml_rpc_auth_realm text,
xml_rpc_auth_user text,
xml_rpc_auth_pass text,
admin_pin numeric,
smtp_host text,
smtp_secure text,
smtp_auth text,
smtp_username text,
smtp_password text,
smtp_from text,
smtp_from_name text,
mod_shout_decoder text,
mod_shout_volume text) ENGINE=INNODB;

CREATE TABLE v_sip_profiles (
sip_profile_uuid char(36),
sip_profile_name text,
sip_profile_description text) ENGINE=INNODB;

CREATE TABLE v_sip_profile_settings (
sip_profile_setting_uuid char(36),
sip_profile_uuid char(36),
sip_profile_setting_name text,
sip_profile_setting_value text,
sip_profile_setting_enabled text,
sip_profile_setting_description text) ENGINE=INNODB;

CREATE TABLE v_software (
software_name text,
software_url text,
software_version text) ENGINE=INNODB;

CREATE TABLE v_vars (
var_uuid char(36) PRIMARY KEY,
var_name text,
var_value text,
var_cat text,
var_enabled text,
var_order numeric,
var_description text) ENGINE=INNODB;

CREATE TABLE v_virtual_table_data (
virtual_table_data_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
virtual_table_uuid char(36),
virtual_data_row_uuid text,
virtual_field_name text,
virtual_data_field_value text,
virtual_data_add_user text,
virtual_data_add_date text,
virtual_data_del_user text,
virtual_data_del_date text,
virtual_table_parent_uuid char(36),
virtual_data_parent_row_uuid text) ENGINE=INNODB;

CREATE TABLE v_virtual_table_data_types_name_value (
virtual_table_data_types_name_value_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
virtual_table_uuid char(36),
virtual_table_field_uuid char(36),
virtual_data_types_name text,
virtual_data_types_value text) ENGINE=INNODB;

CREATE TABLE v_virtual_table_fields (
virtual_table_field_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
virtual_table_uuid char(36),
virtual_field_label text,
virtual_field_name text,
virtual_field_type text,
virtual_field_list_hidden text,
virtual_field_column text,
virtual_field_required text,
virtual_field_order numeric,
virtual_field_order_tab numeric,
virtual_field_description text,
virtual_field_value text) ENGINE=INNODB;

CREATE TABLE v_virtual_tables (
virtual_table_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
virtual_table_category text,
virtual_table_label text,
virtual_table_name text,
virtual_table_auth text,
virtual_table_captcha text,
virtual_table_parent_uuid char(36),
virtual_table_description text) ENGINE=INNODB;

CREATE TABLE v_voicemail_greetings (
greeting_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
user_id text,
greeting_name text,
greeting_description text) ENGINE=INNODB;

CREATE TABLE v_xml_cdr (
uuid char(36) PRIMARY KEY,
domain_uuid char(36),
domain_name text,
accountcode text,
direction text,
default_language text,
context text,
xml_cdr text,
caller_id_name text,
caller_id_number text,
destination_number text,
start_epoch bigint,
start_stamp timestamp,
answer_stamp timestamp,
answer_epoch bigint,
end_epoch bigint,
end_stamp text,
duration numeric,
mduration numeric,
billsec numeric,
billmsec numeric,
bridge_uuid text,
read_codec text,
read_rate text,
write_codec text,
write_rate text,
remote_media_ip text,
network_addr text,
recording_file text,
leg char(1),
pdd_ms smallint,
last_app text,
last_arg text,
cc_side text,
cc_member_uuid char(36),
cc_queue_joined_epoch text,
cc_queue text,
cc_member_session_uuid char(36),
cc_agent text,
cc_agent_type text,
waitsec numeric,
conference_name text,
conference_uuid char(36),
conference_member_id text,
digits_dialed text,
hangup_cause text,
hangup_cause_q850 numeric,
sip_hangup_disposition text) ENGINE=INNODB;

CREATE TABLE v_xmpp (
xmpp_profile_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
profile_name text,
username text,
password text,
dialplan text,
context text,
rtp_ip text,
ext_rtp_ip text,
auto_login text,
sasl_type text,
xmpp_server text,
tls_enable text,
usr_rtp_timer text,
default_exten text,
vad text,
avatar text,
candidate_acl text,
local_network_acl text,
enabled text,
description text) ENGINE=INNODB;

CREATE TABLE v_apps (
app_uuid char(36)) ENGINE=INNODB;

CREATE TABLE v_databases (
database_uuid char(36) PRIMARY KEY,
database_type text,
database_host text,
database_port text,
database_name text,
database_username text,
database_password text,
database_path text,
database_description text) ENGINE=INNODB;

CREATE TABLE v_default_settings (
default_setting_uuid char(36) PRIMARY KEY,
default_setting_category text,
default_setting_subcategory text,
default_setting_name text,
default_setting_value text,
default_setting_enabled text,
default_setting_description text) ENGINE=INNODB;

CREATE TABLE v_domains (
domain_uuid char(36) PRIMARY KEY,
domain_name text,
domain_description text) ENGINE=INNODB;

CREATE TABLE v_domain_settings (
domain_uuid char(36),
domain_setting_uuid char(36) PRIMARY KEY,
domain_setting_category text,
domain_setting_subcategory text,
domain_setting_name text,
domain_setting_value text,
domain_setting_enabled text,
domain_setting_description text) ENGINE=INNODB;

CREATE TABLE v_menus (
menu_uuid char(36) PRIMARY KEY,
menu_name text,
menu_language text,
menu_description text) ENGINE=INNODB;

CREATE TABLE v_menu_items (
menu_item_uuid char(36),
menu_uuid char(36),
menu_item_parent_uuid char(36),
menu_item_title text,
menu_item_link text,
menu_item_category text,
menu_item_protected text,
menu_item_order numeric,
menu_item_description text,
menu_item_add_user text,
menu_item_add_date text,
menu_item_mod_user text,
menu_item_mod_date text) ENGINE=INNODB;

CREATE TABLE v_menu_item_groups (
menu_uuid char(36),
menu_item_uuid char(36),
group_name text) ENGINE=INNODB;

CREATE TABLE v_users (
user_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
username text,
password text,
salt text,
contact_uuid char(36),
user_status text,
user_add_user text,
user_add_date text) ENGINE=INNODB;

CREATE TABLE v_groups (
group_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
group_name text,
group_description text) ENGINE=INNODB;

CREATE TABLE v_group_users (
group_user_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
group_name text,
user_uuid char(36)) ENGINE=INNODB;

CREATE TABLE v_group_permissions (
group_permission_uuid char(36) PRIMARY KEY,
domain_uuid char(36),
permission_name text,
group_name text) ENGINE=INNODB;

CREATE TABLE v_user_settings (
user_setting_uuid char(36) PRIMARY KEY,
user_uuid char(36),
user_setting_category text,
user_setting_subcategory text,
user_setting_name text,
user_setting_value text,
user_setting_enabled text,
user_setting_description text) ENGINE=INNODB;
EOD;

//add the create table statements
	if ($db_type == "pgsql") {
		echo $schema_pgsql."\n";
	}
	if ($db_type == "sqlite") {
		echo $schema_sqlite."\n";
	}
	if ($db_type == "mysql") {
		echo $schema_mysql."\n";
	}

//get the domain array and make it easily accessible by the v_id
	$sql = "select v_id, v_domain as domain_name, v_description as domain_description from v_system_settings ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$v_id = $row['v_id'];
		$domain_array[$v_id]['domain_name'] = check_str($row['domain_name']);
		$domain_array[$v_id]['domain_uuid'] = uuid();
		$domain_array[$v_id]['domain_description'] = check_str($row['domain_description']);

		$sql = "insert into v_domains ";
		$sql .= "(";
		$sql .= "domain_uuid, ";
		$sql .= "domain_name, ";
		$sql .= "domain_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$domain_array[$v_id]['domain_uuid']."', ";
		$sql .= "'".$domain_array[$v_id]['domain_name']."', ";
		$sql .= "'".$domain_array[$v_id]['domain_description']."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; } 
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); } 
		unset($sql);
	}
	unset ($prep_statement);

//export the default settings path
	$sql = "select * from v_system_settings ";
	$sql .= "limit 1 ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		//general
			$v_id = check_str($row["v_id"]);
			$domain_name = check_str($row["v_domain"]);
		//switch
			$switch_base_dir = check_str($row["v_dir"]);
			$switch_bin_dir = check_str($row["bin_dir"]);
			$switch_conf_dir = check_str($row["v_conf_dir"]);
			$switch_db_dir = check_str($row["v_db_dir"]);
			$switch_dialplan_dir = check_str($row["v_dialplan_default_dir"]);
			if (substr($switch_dialplan_dir, -(strlen($domain_name))) == $domain_name) {
				$switch_dialplan_dir = substr($switch_dialplan_dir, 0, -(strlen($domain_name)+1));
			}
			$switch_extensions_dir = check_str($row["v_extensions_dir"]);
			if (substr($switch_extensions_dir, -(strlen($domain_name))) == $domain_name) {
				$switch_extensions_dir = substr($switch_extensions_dir, 0, -(strlen($domain_name)+1));
			}
			$switch_gateways_dir = check_str($row["v_gateways_dir"]);
			$switch_grammar_dir = check_str($row["v_grammar_dir"]);
			$switch_log_dir = check_str($row["v_log_dir"]);
			$switch_mod_dir = check_str($row["v_mod_dir"]);
			if (strlen($row["v_provisioning_tftp_dir"]) > 0) { $switch_provision_dir = check_str($row["v_provisioning_tftp_dir"]); }
			if (strlen($row["v_provisioning_ftp_dir"]) > 0) { $switch_provision_dir = check_str($row["v_provisioning_ftp_dir"]); }
			if (strlen($row["v_provisioning_https_dir"]) > 0) { $switch_provision_dir = check_str($row["v_provisioning_https_dir"]); }
			if (strlen($row["v_provisioning_http_dir"]) > 0) { $switch_provision_dir = check_str($row["v_provisioning_http_dir"]); }
			$switch_recordings_dir = check_str($row["v_recordings_dir"]);
			if (substr($switch_recordings_dir, -(strlen($domain_name))) == $domain_name) {
				$switch_recordings_dir = substr($switch_extensions_dir, 0, -(strlen($domain_name)+1));
			}
			$switch_scripts_dir = check_str($row["v_scripts_dir"]);
			$switch_sounds_dir = check_str($row["v_sounds_dir"]);
			$switch_storage_dir = check_str($row["v_storage_dir"]);
			$switch_voicemail_dir = check_str($row["v_voicemail_dir"]);
		//server
			$server_startup_script_dir = check_str($row["v_startup_script_dir"]);
			$server_backup_dir = check_str($row["v_backup_dir"]);
			$server_temp_dir = check_str($row["tmp_dir"]);
		//domain
			$domain_menu_uuid = strtolower(check_str($row["v_menu_uuid"]));
			$domain_time_zone =  check_str($row["v_time_zone"]);
			$domain_template_name = check_str($row["v_template_name"]);

	//add the default settings
		$x = 0;
		$tmp[$x]['name'] = 'uuid';
		$tmp[$x]['value'] = $domain_menu_uuid;
		$tmp[$x]['category'] = 'domain';
		$tmp[$x]['subcategory'] = 'menu';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'name';
		$tmp[$x]['value'] = $domain_time_zone;
		$tmp[$x]['category'] = 'domain';
		$tmp[$x]['subcategory'] = 'time_zone';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'name';
		$tmp[$x]['value'] = $domain_template_name;
		$tmp[$x]['category'] = 'domain';
		$tmp[$x]['subcategory'] = 'template';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $server_temp_dir;
		$tmp[$x]['category'] = 'server';
		$tmp[$x]['subcategory'] = 'temp';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $server_startup_script_dir;
		$tmp[$x]['category'] = 'server';
		$tmp[$x]['subcategory'] = 'startup_script';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $server_backup_dir;
		$tmp[$x]['category'] = 'server';
		$tmp[$x]['subcategory'] = 'backup';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_bin_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'bin';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $install_switch_base_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'base';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_conf_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'conf';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_db_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'db';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_log_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'log';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_extensions_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'extensions';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_gateways_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'gateways';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_dialplan_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'dialplan';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_mod_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'mod';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_scripts_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'scripts';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_grammar_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'grammar';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_storage_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'storage';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_voicemail_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'voicemail';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_recordings_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'recordings';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_sounds_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'sounds';
		$tmp[$x]['enabled'] = 'true';
		$x++;
		$tmp[$x]['name'] = 'dir';
		$tmp[$x]['value'] = $switch_provision_dir;
		$tmp[$x]['category'] = 'switch';
		$tmp[$x]['subcategory'] = 'provision';
		$tmp[$x]['enabled'] = 'false';
		$x++;
		//$dest_db->beginTransaction();
		foreach($tmp as $row) {
			$sql = "insert into v_default_settings ";
			$sql .= "(";
			$sql .= "default_setting_uuid, ";
			$sql .= "default_setting_name, ";
			$sql .= "default_setting_value, ";
			$sql .= "default_setting_category, ";
			$sql .= "default_setting_subcategory, ";
			$sql .= "default_setting_enabled ";
			$sql .= ") ";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'".uuid()."', ";
			$sql .= "'".$row['name']."', ";
			$sql .= "'".$row['value']."', ";
			$sql .= "'".$row['category']."', ";
			$sql .= "'".$row['subcategory']."', ";
			$sql .= "'".$row['enabled']."' ";
			$sql .= ")";
			if ($export_type == "sql") { echo check_sql($sql).";\n"; } 
			if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
			unset($sql);
		}
		//$dest_db->commit();
		unset($tmp);
	}
	unset ($prep_statement);

//get the user array
	$sql = "select username, v_id from v_users ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$v_id = check_str($row["v_id"]);
		$username = check_str($row["username"]);
		$user_array[$v_id][$username]['user_uuid'] = uuid();
		$user_array[$v_id][$username]['contact_uuid'] = uuid();
	}
	//print_r($user_array);
	unset ($prep_statement);

//export the group members and add them into group users
	$sql = "select * from v_group_members ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$group_user_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$username = check_str($row["username"]);
		$group_name = check_str($row["group_id"]);
		$user_uuid = $user_array[$v_id][$username]['user_uuid'];

		if (strlen($domain_uuid) > 0 && strlen($user_uuid) > 0) {
			$sql = "insert into v_group_users ";
			$sql .= "(";
			$sql .= "group_user_uuid, ";
			$sql .= "domain_uuid, ";
			$sql .= "group_name, ";
			$sql .= "user_uuid ";
			$sql .= ")";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'".$group_user_uuid."', ";
			$sql .= "'".$domain_uuid."', ";
			$sql .= "'".$group_name."', ";
			if (strlen($user_uuid) > 0) {
				$sql .= "'".$user_uuid."' ";
			}
			else {
				$sql .= "null ";
			}
			$sql .= ")";
			if ($export_type == "sql") { echo check_sql($sql).";\n"; }
			if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
		}
	}
	unset ($prep_statement);

//export the group permissions
	$sql = "select * from v_group_permissions ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$group_permission_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$permission_name = check_str($row["permission_id"]);
		$group_name = check_str($row["group_id"]);

		if (strlen($domain_uuid) > 0) {
			$sql = "insert into v_group_permissions ";
			$sql .= "(";
			$sql .= "group_permission_uuid, ";
			$sql .= "domain_uuid, ";
			$sql .= "permission_name, ";
			$sql .= "group_name ";
			$sql .= ")";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'".$group_permission_uuid."', ";
			$sql .= "'".$domain_uuid."', ";
			$sql .= "'".$permission_name."', ";
			$sql .= "'".$group_name."' ";
			$sql .= ")";
			if ($export_type == "sql") { echo check_sql($sql).";\n"; }
			if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
		}
	}
	unset ($prep_statement);

//export the groups
	$sql = "select * from v_groups ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$group_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$group_name = check_str($row["group_id"]);
		$group_description = check_str($row["group_desc"]);

		if (strlen($domain_uuid) > 0) {
			$sql = "insert into v_groups ";
			$sql .= "(";
			$sql .= "group_uuid, ";
			$sql .= "domain_uuid, ";
			$sql .= "group_name, ";
			$sql .= "group_description ";
			$sql .= ")";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'".$group_uuid."', ";
			$sql .= "'".$domain_uuid."', ";
			$sql .= "'".$group_name."', ";
			$sql .= "'".$group_description."' ";
			$sql .= ")";
			if ($export_type == "sql") { echo check_sql($sql).";\n"; }
			if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
		}
	}
	unset ($prep_statement);

//export the menus
	$sql = "select * from v_menus ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$menu_uuid = check_str($row["menu_uuid"]);
		$menu_name = check_str($row["menu_name"]);
		$menu_language = check_str($row["menu_language"]);
		$menu_description = check_str($row["menu_desc"]);

		$sql = "insert into v_menus ";
		$sql .= "(";
		$sql .= "menu_uuid, ";
		$sql .= "menu_name, ";
		$sql .= "menu_language, ";
		$sql .= "menu_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$menu_uuid."', ";
		$sql .= "'".$menu_name."', ";
		$sql .= "'".$menu_language."', ";
		$sql .= "'".$menu_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the menu items
	$sql = "select * from v_menu_items ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$menu_item_uuid = strtolower(check_str($row["menu_item_uuid"]));
		$menu_uuid = strtolower(check_str($row["menu_uuid"]));
		$menu_item_parent_uuid = strtolower(check_str($row["menu_item_parent_uuid"]));
		$menu_item_title = check_str($row["menu_item_title"]);
		$menu_item_link = check_str($row["menu_item_str"]);
		$menu_item_category = check_str($row["menu_item_category"]);
		$menu_item_protected = check_str($row["menu_item_protected"]);
		$menu_item_order = check_str($row["menu_item_order"]);
		$menu_item_description = check_str($row["menu_item_desc"]);
		$menu_item_add_user = check_str($row["menu_item_add_user"]);
		$menu_item_add_date = check_str($row["menu_item_add_date"]);
		$menu_item_mod_user = check_str($row["menu_item_mod_user"]);
		$menu_item_mod_date = check_str($row["menu_item_mod_date"]);

		$sql = "insert into v_menu_items ";
		$sql .= "(";
		$sql .= "menu_item_uuid, ";
		$sql .= "menu_uuid, ";
		$sql .= "menu_item_parent_uuid, ";
		$sql .= "menu_item_title, ";
		$sql .= "menu_item_link, ";
		$sql .= "menu_item_category, ";
		$sql .= "menu_item_protected, ";
		$sql .= "menu_item_order, ";
		$sql .= "menu_item_description, ";
		$sql .= "menu_item_add_user, ";
		$sql .= "menu_item_add_date, ";
		$sql .= "menu_item_mod_user, ";
		$sql .= "menu_item_mod_date ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$menu_item_uuid."', ";
		$sql .= "'".$menu_uuid."', ";
		if (strlen($menu_item_parent_uuid) > 0) {
			$sql .= "'".$menu_item_parent_uuid."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$menu_item_title."', ";
		$sql .= "'".$menu_item_link."', ";
		$sql .= "'".$menu_item_category."', ";
		$sql .= "'".$menu_item_protected."', ";
		$sql .= "'".$menu_item_order."', ";
		$sql .= "'".$menu_item_description."', ";
		$sql .= "'".$menu_item_add_user."', ";
		$sql .= "'".$menu_item_add_date."', ";
		$sql .= "'".$menu_item_mod_user."', ";
		$sql .= "'".$menu_item_mod_date."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the groups assigned to the menu itmes
	$sql = "select * from v_menu_item_groups ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$menu_uuid = check_str($row["menu_uuid"]);
		$menu_item_uuid = check_str($row["menu_item_uuid"]);
		$group_name = check_str($row["group_id"]);

		if (strlen($menu_item_uuid) > 0) {
			$sql = "insert into v_menu_item_groups ";
			$sql .= "(";
			$sql .= "menu_uuid, ";
			$sql .= "menu_item_uuid, ";
			$sql .= "group_name ";
			$sql .= ")";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'".$menu_uuid."', ";
			$sql .= "'".$menu_item_uuid."', ";
			$sql .= "'".$group_name."' ";
			$sql .= ")";
			if ($export_type == "sql") { echo check_sql($sql).";\n"; }
			if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
		}
	}
	unset ($prep_statement);

//export the users
	$sql = "select * from v_users ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$v_id = check_str($row["v_id"]);
		$username = check_str($row["username"]);
		$user_uuid = $user_array[$v_id][$username]['user_uuid'];
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$password = check_str($row["password"]);
		$salt = check_str($row["salt"]);
		$contact_uuid = $user_array[$v_id][$username]['contact_uuid'];
		$user_status = check_str($row["user_status"]);
		$user_time_zone = check_str($row["user_time_zone"]);
		$user_type = check_str($row["user_type"]);
		$user_category = check_str($row["user_category"]);

		if (strlen($user_uuid) == 0) {
			$user_uuid = uuid();
		}

		if (strlen($domain_uuid) > 0) {
			if (strlen($username) > 0) {
				$sql = "insert into v_users ";
				$sql .= "(";
				$sql .= "user_uuid, ";
				$sql .= "domain_uuid, ";
				$sql .= "username, ";
				$sql .= "password, ";
				$sql .= "salt, ";
				$sql .= "contact_uuid, ";
				$sql .= "user_status, ";
				$sql .= "user_add_user, ";
				$sql .= "user_add_date ";
				$sql .= ")";
				$sql .= "values ";
				$sql .= "(";
				$sql .= "'".$user_uuid."', ";
				$sql .= "'".$domain_uuid."', ";
				$sql .= "'".$username."', ";
				$sql .= "'".$password."', ";
				$sql .= "'".$salt."', ";
				$sql .= "'".$contact_uuid."', ";
				$sql .= "'".$user_status."', ";
				$sql .= "'".$user_add_user."', ";
				$sql .= "'".$user_add_date."' ";
				$sql .= ")";
				if ($export_type == "sql") { echo check_sql($sql).";\n"; }
				if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
			}

			//export contacts
				$contact_name_given = check_str($row["user_first_name"]);
				$contact_name_family = check_str($row["user_last_name"]);
				$contact_organization = check_str($row["user_company_name"]);
				$contact_email = check_str($row["user_email"]);
				$contact_note = check_str($row["user_notes"]);
				$contact_url = check_str($row["user_url"]);

				$sql = "insert into v_contacts ";
				$sql .= "(";
				$sql .= "contact_uuid, ";
				$sql .= "domain_uuid, ";
				$sql .= "contact_type, ";
				$sql .= "contact_organization, ";
				$sql .= "contact_name_given, ";
				$sql .= "contact_name_family, ";
				$sql .= "contact_email, ";
				$sql .= "contact_url, ";
				$sql .= "contact_time_zone, ";
				$sql .= "contact_note ";
				$sql .= ")";
				$sql .= "values ";
				$sql .= "(";
				$sql .= "'".$contact_uuid."', ";
				$sql .= "'".$domain_uuid."', ";
				if ($user_type == 'user') {
					$sql .= "'user', ";
				}
				else {
					$sql .= "'".$user_category."', ";
				}
				$sql .= "'".$contact_organization."', ";
				$sql .= "'".$contact_name_given."', ";
				$sql .= "'".$contact_name_family."', ";
				$sql .= "'".$contact_email."', ";
				$sql .= "'".$contact_url."', ";
				$sql .= "'".$user_time_zone."', ";
				$sql .= "'".$contact_note."' ";
				$sql .= ")";
				if ($export_type == "sql") { echo check_sql($sql).";\n"; }
				if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }

			//export the contact addresses
				$x = 0;
				if (strlen($row["user_physical_city"]) > 0) {
					$addresses[$x]['address_1'] = check_str($row["user_physical_address_1"]);
					$addresses[$x]['address_2'] = check_str($row["user_physical_address_2"]);
					$addresses[$x]['city'] = check_str($row["user_physical_city"]);
					$addresses[$x]['state_province'] = check_str($row["user_physical_state_province"]);
					$addresses[$x]['country'] = check_str($row["user_physical_country"]);
					$addresses[$x]['postal_code'] = check_str($row["user_physical_postal_code"]);
					$addresses[$x]['address_type'] = 'work';
					$x++;
				}
				if (strlen($row["user_mailing_city"]) > 0) {
					$addresses[$x]['address_1'] = check_str($row["user_mailing_address_1"]);
					$addresses[$x]['address_2'] = check_str($row["user_mailing_address_2"]);
					$addresses[$x]['city'] = check_str($row["user_mailing_city"]);
					$addresses[$x]['state_province'] = check_str($row["user_mailing_state_province"]);
					$addresses[$x]['country'] = check_str($row["user_mailing_country"]);
					$addresses[$x]['postal_code'] = check_str($row["user_mailing_postal_code"]);
					$addresses[$x]['address_type'] = 'work';
					$x++;
				}
				if (strlen($row["user_billing_city"]) > 0) {
					$addresses[$x]['address_1'] = check_str($row["user_billing_address_1"]);
					$addresses[$x]['address_2'] = check_str($row["user_billing_address_2"]);
					$addresses[$x]['city'] = check_str($row["user_billing_city"]);
					$addresses[$x]['state_province'] = check_str($row["user_billing_state_province"]);
					$addresses[$x]['country'] = check_str($row["user_billing_country"]);
					$addresses[$x]['postal_code'] = check_str($row["user_billing_postal_code"]);
					$addresses[$x]['address_type'] = 'work';
					$x++;
				}
				if (strlen($row["user_shipping_city"]) > 0) {
					$addresses[$x]['address_1'] = check_str($row["user_shipping_address_1"]);
					$addresses[$x]['address_2'] = check_str($row["user_shipping_address_2"]);
					$addresses[$x]['city'] = check_str($row["user_shipping_city"]);
					$addresses[$x]['state_province'] = check_str($row["user_shipping_state_province"]);
					$addresses[$x]['country'] = check_str($row["user_shipping_country"]);
					$addresses[$x]['postal_code'] = check_str($row["user_shipping_postal_code"]);
					$addresses[$x]['address_type'] = 'work';
				}
				foreach($addresses as $address) {
					$sql = "insert into v_contact_addresses ";
					$sql .= "(";
					$sql .= "contact_address_uuid, ";
					$sql .= "contact_uuid, ";
					$sql .= "domain_uuid, ";
					$sql .= "address_type, ";
					$sql .= "address_street, ";
					$sql .= "address_extended, ";
					$sql .= "address_locality, ";
					$sql .= "address_region, ";
					$sql .= "address_postal_code, ";
					$sql .= "address_country ";
					$sql .= ")";
					$sql .= "values ";
					$sql .= "(";
					$sql .= "'".uuid()."', ";
					$sql .= "'".$contact_uuid."', ";
					$sql .= "'".$domain_uuid."', ";
					$sql .= "'".$address["address_type"]."', ";
					$sql .= "'".$address["address_1"]."', ";
					$sql .= "'".$address["address_2"]."', ";
					$sql .= "'".$address["city"]."', ";
					$sql .= "'".$address["state_province"]."', ";
					$sql .= "'".$address["postal_code"]."', ";
					$sql .= "'".$address["country"]."' ";
					$sql .= ")";
					if ($export_type == "sql") { echo check_sql($sql).";\n"; }
					if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
				}
				unset($addresses);

			//export the contact phone numbers
				$x = 0;
				if (strlen($row["user_phone_1"]) > 0) {
					$phones[$x]['number'] = check_str($row["user_phone_1"]);
					$phones[$x]['type'] = 'work';
					$x++;
				}
				if (strlen($row["user_phone_2"]) > 0) {
					$phones[$x]['number'] = check_str($row["user_phone_2"]);
					$phones[$x]['type'] = 'work';
					$x++;
				}
				if (strlen($row["user_phone_mobile"]) > 0) {
					$phones[$x]['number'] = check_str($row["user_phone_mobile"]);
					$phones[$x]['type'] = 'cell';
					$x++;
				}
				if (strlen($row["user_phone_emergency_mobile"]) > 0) {
					$phones[$x]['number'] = check_str($row["user_phone_emergency_mobile"]);
					$phones[$x]['type'] = 'x-emergency';
					$x++;
				}
				if (strlen($row["user_phone_fax"]) > 0) {
					$phones[$x]['number'] = check_str($row["user_phone_fax"]);
					$phones[$x]['type'] = 'fax';
					$x++;
				}
				foreach($phones as $phone) {
					$sql = "insert into v_contact_phones ";
					$sql .= "(";
					$sql .= "contact_phone_uuid, ";
					$sql .= "domain_uuid, ";
					$sql .= "contact_uuid, ";
					$sql .= "phone_type, ";
					$sql .= "phone_number ";
					$sql .= ")";
					$sql .= "values ";
					$sql .= "(";
					$sql .= "'".uuid()."', ";
					$sql .= "'".$domain_uuid."', ";
					$sql .= "'".$contact_uuid."', ";
					$sql .= "'".$phone["type"]."', ";
					$sql .= "'".$phone["number"]."' ";
					$sql .= ")";
					if ($export_type == "sql") { echo check_sql($sql).";\n"; }
					if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
				}
				unset($phones);

			//add to user settings
				//$user_template_name = $row["user_template_name"];
				if (strlen($row["user_time_zone"]) > 0) {
					$user_settings[$x]['category'] = 'domain';
					$user_settings[$x]['sub_category'] = 'time_zone';
					$user_settings[$x]['name'] = "name";
					$user_settings[$x]['value'] = check_str($row["user_time_zone"]);
					$x++;
				}
				foreach($user_settings as $setting) {
					$sql = "insert into v_user_settings ";
					$sql .= "(";
					$sql .= "user_setting_uuid, ";
					$sql .= "user_setting_category, ";
					$sql .= "user_setting_subcategory, ";
					$sql .= "user_setting_name, ";
					$sql .= "user_setting_value, ";
					$sql .= "user_setting_enabled, ";
					$sql .= "user_uuid ";
					$sql .= ") ";
					$sql .= "values ";
					$sql .= "(";
					$sql .= "'".uuid()."', ";
					$sql .= "'".$setting["category"]."', ";
					$sql .= "'".$setting["sub_category"]."', ";
					$sql .= "'".$setting["name"]."', ";
					$sql .= "'".$setting["value"]."', ";
					$sql .= "'true', ";
					$sql .= "'".$user_uuid."' ";
					$sql .= ")";
					$db->exec(check_sql($sql));
				}
				unset($user_settings);
		}
	}
	unset ($prep_statement);

//export the call broadcasts
	$sql = "select * from v_call_broadcast ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$call_call_broadcast_uuid = uuid();
		$broadcast_name = check_str($row["broadcast_name"]);
		$broadcast_description = check_str($row["broadcast_desc"]);
		$broadcast_timeout = check_str($row["broadcast_timeout"]);
		$broadcast_concurrent_limit = check_str($row["broadcast_concurrent_limit"]);
		$recording_uuid = check_str($row["recording_uuid"]);
		$broadcast_caller_id_name = check_str($row["broadcast_caller_id_name"]);
		$broadcast_caller_id_number = check_str($row["broadcast_caller_id_number"]);
		$broadcast_destination_type = check_str($row["broadcast_destination_type"]);
		$broadcast_phone_numbers = check_str($row["broadcast_phone_numbers"]);
		$broadcast_destination_data = check_str($row["broadcast_destination_data"]);

		$sql = "insert into v_call_broadcasts ";
		$sql .= "(";
		$sql .= "call_call_broadcast_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "broadcast_name, ";
		$sql .= "broadcast_description, ";
		$sql .= "broadcast_timeout, ";
		$sql .= "broadcast_concurrent_limit, ";
		$sql .= "recording_uuid, ";
		$sql .= "broadcast_caller_id_name, ";
		$sql .= "broadcast_caller_id_number, ";
		$sql .= "broadcast_destination_type, ";
		$sql .= "broadcast_phone_numbers, ";
		$sql .= "broadcast_destination_data ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$call_call_broadcast_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$broadcast_name."', ";
		$sql .= "'".$broadcast_description."', ";
		$sql .= "'".$broadcast_timeout."', ";
		$sql .= "'".$broadcast_concurrent_limit."', ";
		$sql .= "null, ";
		$sql .= "'".$broadcast_caller_id_name."', ";
		$sql .= "'".$broadcast_caller_id_number."', ";
		$sql .= "'".$broadcast_destination_type."', ";
		$sql .= "'".$broadcast_phone_numbers."', ";
		$sql .= "'".$broadcast_destination_data."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export call center agents
	$sql = "select * from v_call_center_agent ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$call_center_agent_uuid = uuid();
		$agent_name = check_str($row["agent_name"]);
		$agent_type = check_str($row["agent_type"]);
		$agent_call_timeout = check_str($row["agent_call_timeout"]);
		$agent_contact = check_str($row["agent_contact"]);
		$agent_status = check_str($row["agent_status"]);
		$agent_logout = check_str($row["agent_logout"]);
		$agent_max_no_answer = check_str($row["agent_max_no_answer"]);
		$agent_wrap_up_time = check_str($row["agent_wrap_up_time"]);
		$agent_reject_delay_time = check_str($row["agent_reject_delay_time"]);
		$agent_busy_delay_time = check_str($row["agent_busy_delay_time"]);
		$agent_no_answer_delay_time = check_str($row["agent_no_answer_delay_time"]);

		$sql = "insert into v_call_center_agents ";
		$sql .= "(";
		$sql .= "call_center_agent_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "agent_name, ";
		$sql .= "agent_type, ";
		$sql .= "agent_call_timeout, ";
		$sql .= "agent_contact, ";
		$sql .= "agent_status, ";
		$sql .= "agent_logout, ";
		$sql .= "agent_max_no_answer, ";
		$sql .= "agent_wrap_up_time, ";
		$sql .= "agent_reject_delay_time, ";
		$sql .= "agent_busy_delay_time, ";
		$sql .= "agent_no_answer_delay_time ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$call_center_agent_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$agent_name."', ";
		$sql .= "'".$agent_type."', ";
		$sql .= "'".$agent_call_timeout."', ";
		$sql .= "'".$agent_contact."', ";
		$sql .= "'".$agent_status."', ";
		$sql .= "'".$agent_logout."', ";
		$sql .= "'".$agent_max_no_answer."', ";
		$sql .= "'".$agent_wrap_up_time."', ";
		$sql .= "'".$agent_reject_delay_time."', ";
		$sql .= "'".$agent_busy_delay_time."', ";
		$sql .= "'".$agent_no_answer_delay_time."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export call center logs
	$sql = "select * from v_call_center_logs ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$cc_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$cc_queue = check_str($row["cc_queue"]);
		$cc_action = check_str($row["cc_action"]);
		$cc_count = check_str($row["cc_count"]);
		$cc_agent = check_str($row["cc_agent"]);
		$cc_agent_system = check_str($row["cc_agent_system"]);
		$cc_agent_status = check_str($row["cc_agent_status"]);
		$cc_agent_state = check_str($row["cc_agent_state"]);
		$cc_agent_uuid = check_str($row["cc_agent_uuid"]);
		$cc_selection = check_str($row["cc_selection"]);
		$cc_cause = check_str($row["cc_cause"]);
		$cc_wait_time = check_str($row["cc_wait_time"]);
		$cc_talk_time = check_str($row["cc_talk_time"]);
		$cc_total_time = check_str($row["cc_total_time"]);
		$cc_epoch = check_str($row["cc_epoch"]);
		$cc_date = check_str($row["cc_date"]);
		$cc_agent_type = check_str($row["cc_agent_type"]);
		$cc_member_uuid = check_str($row["cc_member_uuid"]);
		$cc_member_session_uuid = check_str($row["cc_member_session_uuid"]);
		$cc_member_cid_name = check_str($row["cc_member_cid_name"]);
		$cc_member_cid_number = check_str($row["cc_member_cid_number"]);
		$cc_agent_called_time = check_str($row["cc_agent_called_time"]);
		$cc_agent_answered_time = check_str($row["cc_agent_answered_time"]);
		$cc_member_joined_time = check_str($row["cc_member_joined_time"]);
		$cc_member_leaving_time = check_str($row["cc_member_leaving_time"]);
		$cc_bridge_terminated_time = check_str($row["cc_bridge_terminated_time"]);
		$cc_hangup_cause = check_str($row["cc_hangup_cause"]);

		$sql = "insert into v_call_center_logs ";
		$sql .= "(";
		$sql .= "cc_uuid, ";
		$sql .= "cc_queue, ";
		$sql .= "cc_action, ";
		$sql .= "cc_count, ";
		$sql .= "cc_agent, ";
		$sql .= "cc_agent_system, ";
		$sql .= "cc_agent_status, ";
		$sql .= "cc_agent_state, ";
		$sql .= "cc_agent_uuid, ";
		$sql .= "cc_selection, ";
		$sql .= "cc_cause, ";
		$sql .= "cc_wait_time, ";
		$sql .= "cc_talk_time, ";
		$sql .= "cc_total_time, ";
		$sql .= "cc_epoch, ";
		$sql .= "cc_date, ";
		$sql .= "cc_agent_type, ";
		$sql .= "cc_member_uuid, ";
		$sql .= "cc_member_session_uuid, ";
		$sql .= "cc_member_cid_name, ";
		$sql .= "cc_member_cid_number, ";
		$sql .= "cc_agent_called_time, ";
		$sql .= "cc_agent_answered_time, ";
		$sql .= "cc_member_joined_time, ";
		$sql .= "cc_member_leaving_time, ";
		$sql .= "cc_bridge_terminated_time, ";
		$sql .= "cc_hangup_cause ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$cc_uuid."', ";
		$sql .= "'".$cc_queue."', ";
		$sql .= "'".$cc_action."', ";
		if (strlen($cc_count) > 0) {
			$sql .= "'".$cc_count."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$cc_agent."', ";
		$sql .= "'".$cc_agent_system."', ";
		$sql .= "'".$cc_agent_status."', ";
		$sql .= "'".$cc_agent_state."', ";
		$sql .= "'".$cc_agent_uuid."', ";
		$sql .= "'".$cc_selection."', ";
		$sql .= "'".$cc_cause."', ";
		$sql .= "'".$cc_wait_time."', ";
		$sql .= "'".$cc_talk_time."', ";
		$sql .= "'".$cc_total_time."', ";
		if (strlen($cc_epoch) > 0) {
			$sql .= "'".$cc_epoch."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$cc_date."', ";
		$sql .= "'".$cc_agent_type."', ";
		$sql .= "'".$cc_member_uuid."', ";
		$sql .= "'".$cc_member_session_uuid."', ";
		$sql .= "'".$cc_member_cid_name."', ";
		$sql .= "'".$cc_member_cid_number."', ";
		if (strlen($cc_agent_called_time) > 0) {
			$sql .= "'".$cc_agent_called_time."', ";
		}
		else {
			$sql .= "null, ";
		}
		if (strlen($cc_agent_answered_time) > 0) {
			$sql .= "'".$cc_agent_answered_time."', ";
		}
		else {
			$sql .= "null, ";
		}
		if (strlen($cc_member_joined_time) > 0) {
			$sql .= "'".$cc_member_joined_time."', ";
		}
		else {
			$sql .= "null, ";
		}
		if (strlen($cc_member_leaving_time) > 0) {
			$sql .= "'".$cc_member_leaving_time."', ";
		}
		else {
			$sql .= "null, ";
		}
		if (strlen($cc_bridge_terminated_time) > 0) {
			$sql .= "'".$cc_bridge_terminated_time."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$cc_hangup_cause."' ";
		$sql .= ")";
		//if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		//if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the call center queues
	$sql = "select * from v_call_center_queue ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$call_center_queue_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$queue_name = check_str($row["queue_name"]);
		$queue_extension = check_str($row["queue_extension"]);
		$queue_strategy = check_str($row["queue_strategy"]);
		$queue_moh_sound = check_str($row["queue_moh_sound"]);
		$queue_record_template = check_str($row["queue_record_template"]);
		$queue_time_base_score = check_str($row["queue_time_base_score"]);
		$queue_max_wait_time = check_str($row["queue_max_wait_time"]);
		$queue_max_wait_time_with_no_agent = check_str($row["queue_max_wait_time_with_no_agent"]);
		$queue_tier_rules_apply = check_str($row["queue_tier_rules_apply"]);
		$queue_tier_rule_wait_second = check_str($row["queue_tier_rule_wait_second"]);
		$queue_tier_rule_no_agent_no_wait = check_str($row["queue_tier_rule_no_agent_no_wait"]);
		$queue_timeout_action = check_str($row["queue_timeout_action"]);
		$queue_discard_abandoned_after = check_str($row["queue_discard_abandoned_after"]);
		$queue_abandoned_resume_allowed = check_str($row["queue_abandoned_resume_allowed"]);
		$queue_tier_rule_wait_multiply_level = check_str($row["queue_tier_rule_wait_multiply_level"]);
		$queue_cid_prefix = check_str($row["queue_cid_prefix"]);
		$queue_description = check_str($row["queue_description"]);

		$sql = "insert into v_call_center_queues ";
		$sql .= "(";
		$sql .= "call_center_queue_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "queue_name, ";
		$sql .= "queue_extension, ";
		$sql .= "queue_strategy, ";
		$sql .= "queue_moh_sound, ";
		$sql .= "queue_record_template, ";
		$sql .= "queue_time_base_score, ";
		$sql .= "queue_max_wait_time, ";
		$sql .= "queue_max_wait_time_with_no_agent, ";
		$sql .= "queue_tier_rules_apply, ";
		$sql .= "queue_tier_rule_wait_second, ";
		$sql .= "queue_tier_rule_no_agent_no_wait, ";
		$sql .= "queue_timeout_action, ";
		$sql .= "queue_discard_abandoned_after, ";
		$sql .= "queue_abandoned_resume_allowed, ";
		$sql .= "queue_tier_rule_wait_multiply_level, ";
		$sql .= "queue_cid_prefix, ";
		$sql .= "queue_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$call_center_queue_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$queue_name."', ";
		$sql .= "'".$queue_extension."', ";
		$sql .= "'".$queue_strategy."', ";
		$sql .= "'".$queue_moh_sound."', ";
		$sql .= "'".$queue_record_template."', ";
		$sql .= "'".$queue_time_base_score."', ";
		$sql .= "'".$queue_max_wait_time."', ";
		$sql .= "'".$queue_max_wait_time_with_no_agent."', ";
		$sql .= "'".$queue_tier_rules_apply."', ";
		$sql .= "'".$queue_tier_rule_wait_second."', ";
		$sql .= "'".$queue_tier_rule_no_agent_no_wait."', ";
		$sql .= "'".$queue_timeout_action."', ";
		$sql .= "'".$queue_discard_abandoned_after."', ";
		$sql .= "'".$queue_abandoned_resume_allowed."', ";
		$sql .= "'".$queue_tier_rule_wait_multiply_level."', ";
		$sql .= "'".$queue_cid_prefix."', ";
		$sql .= "'".$queue_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the call center tiers
	$sql = "select * from v_call_center_tier ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$call_center_tier_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$agent_name = check_str($row["agent_name"]);
		$queue_name = check_str($row["queue_name"]);
		$tier_level = check_str($row["tier_level"]);
		$tier_position = check_str($row["tier_position"]);

		$sql = "insert into v_call_center_tiers ";
		$sql .= "(";
		$sql .= "call_center_tier_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "agent_name, ";
		$sql .= "queue_name, ";
		$sql .= "tier_level, ";
		$sql .= "tier_position ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$call_center_tier_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$agent_name."', ";
		$sql .= "'".$queue_name."', ";
		$sql .= "'".$tier_level."', ";
		$sql .= "'".$tier_position."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export contacts
	$sql = "select * from v_contacts ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$contact_id = check_str($row["contact_id"]);
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$contact_uuid = uuid();
		$contact_type = check_str($row["type"]);
		$contact_organization = check_str($row["org"]);
		$contact_name_given = check_str($row["n_given"]);
		$contact_name_family = check_str($row["n_family"]);
		$contact_nickname = check_str($row["nickname"]);
		$contact_title = check_str($row["title"]);
		$contact_role = check_str($row["role"]);
		$contact_email = check_str($row["email"]);
		$contact_url = check_str($row["url"]);
		$contact_time_zone = check_str($row["tz"]);
		$contact_note = check_str($row["note"]);

		//set the contact_uuid
		$contact_array[$contact_id]['contact_uuid'] = $contact_uuid;

		$sql = "insert into v_contacts ";
		$sql .= "(";
		$sql .= "contact_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "contact_type, ";
		$sql .= "contact_organization, ";
		$sql .= "contact_name_given, ";
		$sql .= "contact_name_family, ";
		$sql .= "contact_nickname, ";
		$sql .= "contact_title, ";
		$sql .= "contact_role, ";
		$sql .= "contact_email, ";
		$sql .= "contact_url, ";
		$sql .= "contact_time_zone, ";
		$sql .= "contact_note ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$contact_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$contact_type."', ";
		$sql .= "'".$contact_organization."', ";
		$sql .= "'".$contact_name_given."', ";
		$sql .= "'".$contact_name_family."', ";
		$sql .= "'".$contact_nickname."', ";
		$sql .= "'".$contact_title."', ";
		$sql .= "'".$contact_role."', ";
		$sql .= "'".$contact_email."', ";
		$sql .= "'".$contact_url."', ";
		$sql .= "'".$contact_time_zone."', ";
		$sql .= "'".$contact_note."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the contact addresses
	$sql = "select * from v_contacts_adr ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$contact_address_uuid = uuid();
		$contact_id = check_str($row["contact_id"]);
		$address_type = check_str($row["adr_type"]);
		$address_street = check_str($row["adr_street"]);
		$address_extended = check_str($row["adr_extended"]);
		$address_locality = check_str($row["adr_locality"]);
		$address_region = check_str($row["adr_region"]);
		$address_postal_code = check_str($row["adr_postal_code"]);
		$address_country = check_str($row["adr_country"]);
		$address_latitude = check_str($row["adr_latitude"]);
		$address_longitude = check_str($row["adr_longitude"]);

		//get the contact_uuid
		$contact_uuid = $contact_array[$contact_id]['contact_uuid'];

		$sql = "insert into v_contact_addresses ";
		$sql .= "(";
		$sql .= "contact_address_uuid, ";
		$sql .= "contact_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "address_type, ";
		$sql .= "address_street, ";
		$sql .= "address_extended, ";
		$sql .= "address_locality, ";
		$sql .= "address_region, ";
		$sql .= "address_postal_code, ";
		$sql .= "address_country, ";
		$sql .= "address_latitude, ";
		$sql .= "address_longitude ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$contact_address_uuid."', ";
		$sql .= "'".$contact_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$address_type."', ";
		$sql .= "'".$address_street."', ";
		$sql .= "'".$address_extended."', ";
		$sql .= "'".$address_locality."', ";
		$sql .= "'".$address_region."', ";
		$sql .= "'".$address_postal_code."', ";
		$sql .= "'".$address_country."', ";
		$sql .= "'".$address_latitude."', ";
		$sql .= "'".$address_longitude."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the contact phone numbers
	$sql = "select * from v_contacts_tel ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$contact_phone_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$contact_id = check_str($row["contact_id"]);
		$phone_type = check_str($row["tel_type"]);
		$phone_number = check_str($row["tel_number"]);

		//get the contact_uuid
		$contact_uuid = $contact_array[$contact_id]['contact_uuid'];

		if (strlen($contact_uuid) > 0) {
			$sql = "insert into v_contact_phones ";
			$sql .= "(";
			$sql .= "contact_phone_uuid, ";
			$sql .= "domain_uuid, ";
			$sql .= "contact_uuid, ";
			$sql .= "phone_type, ";
			$sql .= "phone_number ";
			$sql .= ")";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'".$contact_phone_uuid."', ";
			$sql .= "'".$domain_uuid."', ";
			$sql .= "'".$contact_uuid."', ";
			$sql .= "'".$phone_type."', ";
			$sql .= "'".$phone_number."' ";
			$sql .= ")";
		}
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the contact notes
	$sql = "select * from v_contact_notes ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$contact_note_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$contact_id = check_str($row["contact_id"]);
		$contact_note = check_str($row["notes"]);
		$last_mod_date = check_str($row["last_mod_date"]);
		$last_mod_user = check_str($row["last_mod_user"]);

		//get the contact_uuid
		$contact_uuid = $contact_array[$contact_id]['contact_uuid'];

		$sql = "insert into v_contact_notes ";
		$sql .= "(";
		$sql .= "contact_note_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "contact_uuid, ";
		$sql .= "contact_note, ";
		$sql .= "last_mod_date, ";
		$sql .= "last_mod_user ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$contact_note_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$contact_uuid."', ";
		$sql .= "'".$contact_note."', ";
		$sql .= "'".$last_mod_date."', ";
		$sql .= "'".$last_mod_user."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the rss data
	$sql = "select * from v_rss ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$rss_id = check_str($row["rss_id"]);
		$rss_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$rss_language = check_str($row["rss_language"]);
		$rss_category = check_str($row["rss_category"]);
		$rss_sub_category = check_str($row["rss_sub_category"]);
		$rss_title = check_str($row["rss_title"]);
		$rss_link = check_str($row["rss_link"]);
		$rss_description = check_str($row["rss_desc"]);
		$rss_img = check_str($row["rss_img"]);
		$rss_optional_1 = check_str($row["rss_optional_1"]);
		$rss_optional_2 = check_str($row["rss_optional_2"]);
		$rss_optional_3 = check_str($row["rss_optional_3"]);
		$rss_optional_4 = check_str($row["rss_optional_4"]);
		$rss_optional_5 = check_str($row["rss_optional_5"]);
		$rss_add_date = check_str($row["rss_add_date"]);
		$rss_add_user = check_str($row["rss_add_user"]);
		$rss_del_date = check_str($row["rss_del_date"]);
		$rss_del_user = check_str($row["rss_del_user"]);
		$rss_order = check_str($row["rss_order"]);
		$rss_content = check_str($row["rss_content"]);
		$rss_group = check_str($row["rss_group"]);

		//set the rss_uuid
		$rss_array[$rss_id]['rss_uuid'] = $rss_uuid;

		$sql = "insert into v_rss ";
		$sql .= "(";
		$sql .= "rss_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "rss_language, ";
		$sql .= "rss_category, ";
		$sql .= "rss_sub_category, ";
		$sql .= "rss_title, ";
		$sql .= "rss_link, ";
		$sql .= "rss_description, ";
		$sql .= "rss_img, ";
		$sql .= "rss_optional_1, ";
		$sql .= "rss_optional_2, ";
		$sql .= "rss_optional_3, ";
		$sql .= "rss_optional_4, ";
		$sql .= "rss_optional_5, ";
		$sql .= "rss_add_date, ";
		$sql .= "rss_add_user, ";
		$sql .= "rss_del_date, ";
		$sql .= "rss_del_user, ";
		$sql .= "rss_order, ";
		$sql .= "rss_content, ";
		$sql .= "rss_group ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$rss_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$rss_language."', ";
		$sql .= "'".$rss_category."', ";
		$sql .= "'".$rss_sub_category."', ";
		$sql .= "'".$rss_title."', ";
		$sql .= "'".$rss_link."', ";
		$sql .= "'".$rss_description."', ";
		$sql .= "'".$rss_img."', ";
		$sql .= "'".$rss_optional_1."', ";
		$sql .= "'".$rss_optional_2."', ";
		$sql .= "'".$rss_optional_3."', ";
		$sql .= "'".$rss_optional_4."', ";
		$sql .= "'".$rss_optional_5."', ";
		$sql .= "'".$rss_add_date."', ";
		$sql .= "'".$rss_add_user."', ";
		$sql .= "'".$rss_del_date."', ";
		$sql .= "'".$rss_del_user."', ";
		$sql .= "'".$rss_order."', ";
		$sql .= "'".$rss_content."', ";
		$sql .= "'".$rss_group."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the rss sub data
	$sql = "select * from v_rss_sub ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$rss_sub_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$rss_id = check_str($row["rss_id"]);
		$rss_sub_language = check_str($row["rss_sub_language"]);
		$rss_sub_title = check_str($row["rss_sub_title"]);
		$rss_sub_link = check_str($row["rss_sub_link"]);
		$rss_sub_description = check_str($row["rss_sub_desc"]);
		$rss_sub_optional_1 = check_str($row["rss_sub_optional_1"]);
		$rss_sub_optional_2 = check_str($row["rss_sub_optional_2"]);
		$rss_sub_optional_3 = check_str($row["rss_sub_optional_3"]);
		$rss_sub_optional_4 = check_str($row["rss_sub_optional_4"]);
		$rss_sub_optional_5 = check_str($row["rss_sub_optional_5"]);
		$rss_sub_add_date = check_str($row["rss_sub_add_date"]);
		$rss_sub_add_user = check_str($row["rss_sub_add_user"]);
		$rss_sub_del_user = check_str($row["rss_sub_del_user"]);
		$rss_sub_del_date = check_str($row["rss_sub_del_date"]);

		//get the rss_uuid
		$rss_uuid = $rss_array[$rss_id]['rss_uuid'];

		$sql = "insert into v_rss_sub ";
		$sql .= "(";
		$sql .= "rss_sub_uuid, ";
		$sql .= "rss_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "rss_sub_language, ";
		$sql .= "rss_sub_title, ";
		$sql .= "rss_sub_link, ";
		$sql .= "rss_sub_description, ";
		$sql .= "rss_sub_optional_1, ";
		$sql .= "rss_sub_optional_2, ";
		$sql .= "rss_sub_optional_3, ";
		$sql .= "rss_sub_optional_4, ";
		$sql .= "rss_sub_optional_5, ";
		$sql .= "rss_sub_add_date, ";
		$sql .= "rss_sub_add_user, ";
		$sql .= "rss_sub_del_user, ";
		$sql .= "rss_sub_del_date ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$rss_sub_uuid."', ";
		$sql .= "'".$rss_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$rss_sub_language."', ";
		$sql .= "'".$rss_sub_title."', ";
		$sql .= "'".$rss_sub_link."', ";
		$sql .= "'".$rss_sub_description."', ";
		$sql .= "'".$rss_sub_optional_1."', ";
		$sql .= "'".$rss_sub_optional_2."', ";
		$sql .= "'".$rss_sub_optional_3."', ";
		$sql .= "'".$rss_sub_optional_4."', ";
		$sql .= "'".$rss_sub_optional_5."', ";
		$sql .= "'".$rss_sub_add_date."', ";
		$sql .= "'".$rss_sub_add_user."', ";
		$sql .= "'".$rss_sub_del_user."', ";
		$sql .= "'".$rss_sub_del_date."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the rss sub category data
	$sql = "select * from v_rss_sub_category ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$rss_sub_category_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$rss_sub_category_language = check_str($row["rss_sub_category_language"]);
		$rss_category = check_str($row["rss_category"]);
		$rss_sub_category = check_str($row["rss_sub_category"]);
		$rss_sub_category_description = check_str($row["rss_sub_category_desc"]);
		$rss_sub_add_user = check_str($row["rss_sub_add_user"]);
		$rss_sub_add_date = check_str($row["rss_sub_add_date"]);

		$sql = "insert into v_rss_sub_category ";
		$sql .= "(";
		$sql .= "rss_sub_category_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "rss_sub_category_language, ";
		$sql .= "rss_category, ";
		$sql .= "rss_sub_category, ";
		$sql .= "rss_sub_category_description, ";
		$sql .= "rss_sub_add_user, ";
		$sql .= "rss_sub_add_date ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$rss_sub_category_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$rss_sub_category_language."', ";
		$sql .= "'".$rss_category."', ";
		$sql .= "'".$rss_sub_category."', ";
		$sql .= "'".$rss_sub_category_description."', ";
		$sql .= "'".$rss_sub_add_user."', ";
		$sql .= "'".$rss_sub_add_date."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//get the database connection information
	$sql = "select * from v_database_connections ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$database_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$database_type = check_str($row["db_type"]);
		$database_host = check_str($row["db_host"]);
		$database_port = check_str($row["db_port"]);
		$database_name = check_str($row["db_name"]);
		$database_username = check_str($row["db_username"]);
		$database_password = check_str($row["db_password"]);
		$database_path = check_str($row["db_path"]);
		$database_description = check_str($row["db_description"]);

		$sql = "insert into v_databases ";
		$sql .= "(";
		$sql .= "database_uuid, ";
		$sql .= "database_type, ";
		$sql .= "database_host, ";
		$sql .= "database_port, ";
		$sql .= "database_name, ";
		$sql .= "database_username, ";
		$sql .= "database_password, ";
		$sql .= "database_path, ";
		$sql .= "database_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$database_uuid."', ";
		$sql .= "'".$database_type."', ";
		$sql .= "'".$database_host."', ";
		$sql .= "'".$database_port."', ";
		$sql .= "'".$database_name."', ";
		$sql .= "'".$database_username."', ";
		$sql .= "'".$database_password."', ";
		$sql .= "'".$database_path."', ";
		$sql .= "'".$database_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the dialplan
	$sql = "select * from v_dialplan_includes ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$dialplan_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$dialplan_include_id = check_str($row["dialplan_include_id"]);
		$app_uuid = '742714e5-8cdf-32fd-462c-cbe7e3d655db'; //dialplan app_uuid
		$dialplan_name = check_str($row["extension_name"]);
		$dialplan_number = check_str($row["extension_number"]);
		//$dialplan_context = check_str($row["context"]);
		$dialplan_continue = check_str($row["extension_continue"]);
		$dialplan_order = check_str($row["dialplan_order"]);
		$dialplan_enabled = check_str($row["enabled"]);
		$dialplan_description = check_str($row["descr"]);
		//$opt_1_name = check_str($row["opt_1_name"]);
		//$opt_1_value = check_str($row["opt_1_value"]);

		//set the dialplan order
		if ($dialplan_order < 320) { $dialplan_order = 320; }

		//set the dialplan_uuid
		$dialplan_array[$dialplan_include_id]['dialplan_uuid'] = $dialplan_uuid;

		//set the dialplan context
		if (count($domain_array) > 1) {
			$dialplan_context = $domain_array[$v_id]['domain_name'];
		}
		else {
			$dialplan_context = "default";
		}

		if (strlen($domain_uuid) > 0) {
			$sql = "insert into v_dialplans ";
			$sql .= "(";
			$sql .= "dialplan_uuid, ";
			$sql .= "domain_uuid, ";
			$sql .= "app_uuid, ";
			$sql .= "dialplan_name, ";
			$sql .= "dialplan_number, ";
			$sql .= "dialplan_context, ";
			$sql .= "dialplan_continue, ";
			$sql .= "dialplan_order, ";
			$sql .= "dialplan_enabled, ";
			$sql .= "dialplan_description ";
			$sql .= ")";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'".$dialplan_uuid."', ";
			$sql .= "'".$domain_uuid."', ";
			$sql .= "'".$app_uuid."', ";
			$sql .= "'".$dialplan_name."', ";
			$sql .= "'".$dialplan_number."', ";
			$sql .= "'".$dialplan_context."', ";
			$sql .= "'".$dialplan_continue."', ";
			$sql .= "'".$dialplan_order."', ";
			$sql .= "'".$dialplan_enabled."', ";
			$sql .= "'".$dialplan_description."' ";
			$sql .= ")";
			if ($export_type == "sql") { echo check_sql($sql).";\n"; }
			if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
		}
	}
	unset ($prep_statement);

//export the dialplan details
	$sql = "select * from v_dialplan_includes_details ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$dialplan_detail_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$dialplan_include_id = check_str($row["dialplan_include_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$dialplan_detail_tag = check_str($row["tag"]);
		$dialplan_detail_type = check_str($row["field_type"]);
		$dialplan_detail_data = check_str($row["field_data"]);
		$dialplan_detail_break = check_str($row["field_break"]);
		$dialplan_detail_inline = check_str($row["field_inline"]);
		$dialplan_detail_group = check_str($row["field_group"]);
		$dialplan_detail_order = check_str($row["field_order"]);
		$dialplan_detail_data = str_replace("\\\\", "\\", $dialplan_detail_data);

		//get the dialplan_uuid
		$dialplan_uuid = $dialplan_array[$dialplan_include_id]['dialplan_uuid'];

		if (strlen($domain_uuid) > 0 && strlen($dialplan_uuid) > 0 ) {
			$sql = "insert into v_dialplan_details ";
			$sql .= "(";
			$sql .= "dialplan_detail_uuid, ";
			$sql .= "domain_uuid, ";
			$sql .= "dialplan_uuid, ";
			$sql .= "dialplan_detail_tag, ";
			$sql .= "dialplan_detail_type, ";
			$sql .= "dialplan_detail_data, ";
			$sql .= "dialplan_detail_break, ";
			$sql .= "dialplan_detail_inline, ";
			$sql .= "dialplan_detail_group, ";
			$sql .= "dialplan_detail_order ";
			$sql .= ")";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'".$dialplan_detail_uuid."', ";
			$sql .= "'".$domain_uuid."', ";
			$sql .= "'".$dialplan_uuid."', ";
			$sql .= "'".$dialplan_detail_tag."', ";
			$sql .= "'".$dialplan_detail_type."', ";
			$sql .= "'".$dialplan_detail_data."', ";
			$sql .= "'".$dialplan_detail_break."', ";
			$sql .= "'".$dialplan_detail_inline."', ";
			if (strlen($dialplan_detail_group) > 0) {
				$sql .= "'".$dialplan_detail_group."', ";
			}
			else {
				$sql .= "null, ";
			}
			if (strlen($dialplan_detail_order) > 0) {
				$sql .= "'".$dialplan_detail_order."' ";
			}
			else {
				$sql .= "'330' ";
			}
			$sql .= ")";
			if ($export_type == "sql") { echo check_sql($sql).";\n"; }
			if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
		}
	}
	unset ($prep_statement);

//export the inbound routes
	$sql = "select * from v_public_includes ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$public_include_id = $row["public_include_id"];
		$dialplan_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$app_uuid = 'c03b422e-13a8-bd1b-e42b-b6b9b4d27ce4';
		$dialplan_name = check_str($row["extension_name"]);
		$dialplan_context = 'public';
		$dialplan_continue = check_str($row["extension_continue"]);
		$dialplan_order = check_str($row["public_order"]);
		$dialplan_enabled = check_str($row["enabled"]);
		$dialplan_description = check_str($row["descr"]);

		//set the dialplan_uuid
		$public_dialplan_array[$public_include_id]['dialplan_uuid'] = $dialplan_uuid;

		$sql = "insert into v_dialplans ";
		$sql .= "(";
		$sql .= "dialplan_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "app_uuid, ";
		$sql .= "dialplan_name, ";
		$sql .= "dialplan_context, ";
		$sql .= "dialplan_continue, ";
		$sql .= "dialplan_order, ";
		$sql .= "dialplan_enabled, ";
		$sql .= "dialplan_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$dialplan_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$app_uuid."', ";
		$sql .= "'".$dialplan_name."', ";
		$sql .= "'".$dialplan_context."', ";
		$sql .= "'".$dialplan_continue."', ";
		$sql .= "'".$dialplan_order."', ";
		$sql .= "'".$dialplan_enabled."', ";
		$sql .= "'".$dialplan_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export inbound route details
	$sql = "select * from v_public_includes_details ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$dialplan_detail_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$public_include_id = check_str($row["public_include_id"]);
		$dialplan_detail_tag = check_str($row["tag"]);
		$dialplan_detail_type = check_str($row["field_type"]);
		$dialplan_detail_data = check_str($row["field_data"]);
		$dialplan_detail_break = check_str($row["field_break"]);
		$dialplan_detail_inline = check_str($row["field_inline"]);
		$dialplan_detail_group = check_str($row["field_group"]);
		$dialplan_detail_order = check_str($row["field_order"]);

		//get the dialplan_uuid
		$dialplan_uuid = $public_dialplan_array[$public_include_id]['dialplan_uuid'];

		$sql = "insert into v_dialplan_details ";
		$sql .= "(";
		$sql .= "dialplan_detail_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "dialplan_uuid, ";
		$sql .= "dialplan_detail_tag, ";
		$sql .= "dialplan_detail_type, ";
		$sql .= "dialplan_detail_data, ";
		$sql .= "dialplan_detail_break, ";
		$sql .= "dialplan_detail_inline, ";
		$sql .= "dialplan_detail_group, ";
		$sql .= "dialplan_detail_order ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$dialplan_detail_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$dialplan_uuid."', ";
		$sql .= "'".$dialplan_detail_tag."', ";
		$sql .= "'".$dialplan_detail_type."', ";
		$sql .= "'".$dialplan_detail_data."', ";
		$sql .= "'".$dialplan_detail_break."', ";
		$sql .= "'".$dialplan_detail_inline."', ";
		if (strlen($dialplan_detail_group) > 0) {
			$sql .= "'".$dialplan_detail_group."', ";
		}
		else {
			$sql .= "null, ";
		}
		if (strlen($dialplan_detail_order) > 0) {
			$sql .= "'".$dialplan_detail_order."' ";
		}
		else {
			$sql .= "null ";
		}
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//set the app_uuid for the dialplan outbound route
	$sql = "select * from v_dialplan_includes_details ";
	$sql .= "where (";
	$sql .= "field_data like '%sofia/gateway/%' ";
	$sql .= "or field_data like '%freetdm%' ";
	$sql .= "or field_data like '%openzap%' ";
	$sql .= "or field_data like '%dingaling%' ";
	$sql .= "or field_data like '%enum_auto_route%' ";
	$sql .= ") ";
	$prepstatement = $db->prepare(check_sql($sql));
	$prepstatement->execute();
	$result = $prepstatement->fetchAll();
	foreach ($result as &$row) {
		$dialplan_include_id = check_str($row["dialplan_include_id"]);

		//get the dialplan_uuid
		$dialplan_uuid = $dialplan_array[$dialplan_include_id]['dialplan_uuid'];

		$sql = "update v_dialplans set ";
		$sql .= "app_uuid = '8c914ec3-9fc0-8ab5-4cda-6c9288bdc9a3' ";
		$sql .= "where dialplan_uuid = '$dialplan_uuid'";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
		unset($sql);
	}
	unset ($prepstatement);

//export the extensions
	$sql = "select * from v_extensions ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$extension_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$extension = check_str($row["extension"]);
		$number_alias = check_str($row["number_alias"]);
		$password = check_str($row["password"]);
		$user_list = check_str($row["user_list"]);
		$provisioning_list = check_str($row["provisioning_list"]);
		$mailbox = check_str($row["mailbox"]);
		$vm_password = check_str($row["vm_password"]);
		$accountcode = check_str($row["accountcode"]);
		$effective_caller_id_name = check_str($row["effective_caller_id_name"]);
		$effective_caller_id_number = check_str($row["effective_caller_id_number"]);
		$outbound_caller_id_name = check_str($row["outbound_caller_id_name"]);
		$outbound_caller_id_number = check_str($row["outbound_caller_id_number"]);
		$limit_max = check_str($row["limit_max"]);
		$limit_destination = check_str($row["limit_destination"]);
		$vm_enabled = check_str($row["vm_enabled"]);
		$vm_mailto = check_str($row["vm_mailto"]);
		$vm_attach_file = check_str($row["vm_attach_file"]);
		$vm_keep_local_after_email = check_str($row["vm_keep_local_after_email"]);
		$user_context = check_str($row["user_context"]);
		$toll_allow = check_str($row["toll_allow"]);
		$call_group = check_str($row["callgroup"]);
		$hold_music = check_str($row["hold_music"]);
		$auth_acl = check_str($row["auth_acl"]);
		$cidr = check_str($row["cidr"]);
		$sip_force_contact = check_str($row["sip_force_contact"]);
		$nibble_account = check_str($row["nibble_account"]);
		$sip_force_expires = check_str($row["sip_force_expires"]);
		$enabled = check_str($row["enabled"]);
		$description = check_str($row["description"]);
		$mwi_account = check_str($row["mwi_account"]);
		$sip_bypass_media = check_str($row["sip_bypass_media"]);

		$sql = "insert into v_extensions ";
		$sql .= "(";
		$sql .= "extension_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "extension, ";
		$sql .= "number_alias, ";
		$sql .= "password, ";
		$sql .= "provisioning_list, ";
		$sql .= "mailbox, ";
		$sql .= "vm_password, ";
		$sql .= "accountcode, ";
		$sql .= "effective_caller_id_name, ";
		$sql .= "effective_caller_id_number, ";
		$sql .= "outbound_caller_id_name, ";
		$sql .= "outbound_caller_id_number, ";
		$sql .= "limit_max, ";
		$sql .= "limit_destination, ";
		$sql .= "vm_enabled, ";
		$sql .= "vm_mailto, ";
		$sql .= "vm_attach_file, ";
		$sql .= "vm_keep_local_after_email, ";
		$sql .= "user_context, ";
		$sql .= "toll_allow, ";
		$sql .= "call_group, ";
		$sql .= "hold_music, ";
		$sql .= "auth_acl, ";
		$sql .= "cidr, ";
		$sql .= "sip_force_contact, ";
		$sql .= "nibble_account, ";
		$sql .= "sip_force_expires, ";
		$sql .= "enabled, ";
		$sql .= "description, ";
		$sql .= "mwi_account, ";
		$sql .= "sip_bypass_media ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$extension_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$extension."', ";
		$sql .= "'".$number_alias."', ";
		$sql .= "'".$password."', ";
		$sql .= "'".$provisioning_list."', ";
		$sql .= "'".$mailbox."', ";
		$sql .= "'".$vm_password."', ";
		$sql .= "'".$accountcode."', ";
		$sql .= "'".$effective_caller_id_name."', ";
		$sql .= "'".$effective_caller_id_number."', ";
		$sql .= "'".$outbound_caller_id_name."', ";
		$sql .= "'".$outbound_caller_id_number."', ";
		if (strlen($limit_max) > 0) {
			$sql .= "'".$limit_max."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$limit_destination."', ";
		$sql .= "'".$vm_enabled."', ";
		$sql .= "'".$vm_mailto."', ";
		$sql .= "'".$vm_attach_file."', ";
		$sql .= "'".$vm_keep_local_after_email."', ";
		$sql .= "'".$user_context."', ";
		$sql .= "'".$toll_allow."', ";
		$sql .= "'".$call_group."', ";
		$sql .= "'".$hold_music."', ";
		$sql .= "'".$auth_acl."', ";
		$sql .= "'".$cidr."', ";
		$sql .= "'".$sip_force_contact."', ";
		if (strlen($nibble_account) > 0) {
			$sql .= "'".$nibble_account."', ";
		}
		else {
			$sql .= "null, ";
		}
		if (strlen($sip_force_expires) > 0) {
			$sql .= "'".$sip_force_expires."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$enabled."', ";
		$sql .= "'".$description."', ";
		$sql .= "'".$mwi_account."', ";
		$sql .= "'".$sip_bypass_media."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }

		$user_list_array = explode("|", $user_list);
		foreach($user_list_array as $username){
			if (strlen($username) > 0) {
				$user_uuid = $user_array[$v_id][$username]['user_uuid'];
				if (strlen($user_uuid) > 0) {
					$sql = "insert into v_extension_users ";
					$sql .= "(";
					$sql .= "extension_user_uuid, ";
					$sql .= "domain_uuid, ";
					$sql .= "extension_uuid, ";
					$sql .= "user_uuid ";
					$sql .= ")";
					$sql .= "values ";
					$sql .= "(";
					$sql .= "'".uuid()."', ";
					$sql .= "'".$domain_uuid."', ";
					$sql .= "'".$extension_uuid."', ";
					$sql .= "'".$user_uuid."' ";
					$sql .= ")";
					if ($export_type == "sql") { echo check_sql($sql).";\n"; }
					if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
				}
			}
		}
		unset($user_list_array, $username, $extension_uuid);
	}
	unset ($prep_statement);

//get the conference identifiers
	$sql = "select * from v_dialplan_includes_details ";
	$sql .= "where field_data like 'conference_user_list%' ";
	$prepstatement = $db->prepare(check_sql($sql));
	$prepstatement->execute();
	$x = 0;
	$result = $prepstatement->fetchAll();
	foreach ($result as &$row) {
		$dialplan_include_id = $row["dialplan_include_id"];
		$field_type = $row["field_type"];
		$conference_array[$x]['dialplan_include_id'] = $dialplan_include_id;
		$x++;
	}
	unset ($prepstatement);

//get the conferences
	$sql = "select * from v_dialplan_includes ";
	$x = 0;
	foreach ($conference_array as &$row) {
		if ($x == 0) {
			$sql .= " where dialplan_include_id = '".$row['dialplan_include_id']."' \n";
		}
		else {
			$sql .= " or dialplan_include_id = '".$row['dialplan_include_id']."' \n";
		}
		$x++;
	}
	$sql .= "order by dialplan_order, extension_name asc ";
	$prep_statement = $db->prepare(check_sql($sql));
	$prep_statement->execute();
	$result = $prep_statement->fetchAll();
	foreach ($result as &$tmp) {
		//get the values from the database
			$v_id = check_str($tmp["v_id"]);
			$dialplan_include_id = check_str($tmp["dialplan_include_id"]);
		//get the dialplan
			$sql = "select * from v_dialplan_includes ";
			$sql .= "where v_id = '$v_id' ";
			$sql .= "and dialplan_include_id = '$dialplan_include_id' ";
			$row = $db->query($sql)->fetch();
			$conference_name = $row['extension_name'];
			$conference_name = str_replace("-", " ", $conference_name);
			//$context = $row['context'];
			$conference_order = $row['dialplan_order'];
			$conference_enabled = $row['enabled'];
			$conference_description = $row['descr'];
		//get the dialplan details
			$sql = "select * from v_dialplan_includes_details ";
			$sql .= "where v_id = '$v_id' ";
			$sql .= "and dialplan_include_id = '$dialplan_include_id' ";
			$prepstatement = $db->prepare(check_sql($sql));
			$prepstatement->execute();
			$result_details = $prepstatement->fetchAll();
			foreach ($result_details as &$row) {
				if ($row['field_type'] == "destination_number") {
					$conference_extension = $row['field_data'];
					$conference_extension = trim($conference_extension, '^$');
				}
				$field_data_array = explode("=", $row['field_data']);
				if ($field_data_array[0] == "conference_user_list") {
					$user_list = $field_data_array[1];
				}
				if ($row['field_type'] == "conference") {
					$field_data = $row['field_data'];
					$tmp_pos = stripos($field_data, "@");
					if ($tmp_pos !== false) {
						$tmp_field_data = substr($field_data, $tmp_pos+1, strlen($field_data));
						$tmp_field_data_array = explode("+",$tmp_field_data);
						foreach ($tmp_field_data_array as &$tmp_row) {
							if (is_numeric($tmp_row)) {
								$conference_pin_number = $tmp_row;
							}
							if (substr($tmp_row, 0, 5) == "flags") {
								$conference_flags = substr($tmp_row, 6, $tmp_row-1);
							}
						}
						$conference_profile = $tmp_field_data_array[0];
					}
				}
			}
		//get the uuids
			$dialplan_uuid = $dialplan_array[$dialplan_include_id]['dialplan_uuid'];
			$domain_uuid = $domain_array[$v_id]['domain_uuid'];
			$conference_uuid = uuid();
		//add the conference
			$sql = "insert into v_conferences ";
			$sql .= "(";
			$sql .= "domain_uuid, ";
			$sql .= "conference_uuid, ";
			$sql .= "dialplan_uuid, ";
			$sql .= "conference_name, ";
			$sql .= "conference_extension, ";
			$sql .= "conference_pin_number, ";
			$sql .= "conference_profile, ";
			$sql .= "conference_flags, ";
			$sql .= "conference_order, ";
			$sql .= "conference_description, ";
			$sql .= "conference_enabled ";
			$sql .= ")";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'$domain_uuid', ";
			$sql .= "'$conference_uuid', ";
			$sql .= "'$dialplan_uuid', ";
			$sql .= "'$conference_name', ";
			$sql .= "'$conference_extension', ";
			$sql .= "'$conference_pin_number', ";
			$sql .= "'$conference_profile', ";
			$sql .= "'$conference_flags', ";
			$sql .= "'$conference_order', ";
			$sql .= "'$conference_description', ";
			$sql .= "'$conference_enabled' ";
			$sql .= ")";
			if ($export_type == "sql") { echo check_sql($sql).";\n"; }
			if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }

		//add the assigned users to the conference
			$user_list_array = explode("|", $user_list);
			foreach($user_list_array as $username){
				if (strlen($username) > 0) {
					$user_uuid = $user_array[$v_id][$username]['user_uuid'];
					if (strlen($user_uuid) > 0) {
						$sql = "insert into v_conference_users ";
						$sql .= "(";
						$sql .= "conference_user_uuid, ";
						$sql .= "domain_uuid, ";
						$sql .= "conference_uuid, ";
						$sql .= "user_uuid ";
						$sql .= ")";
						$sql .= "values ";
						$sql .= "(";
						$sql .= "'".uuid()."', ";
						$sql .= "'".$domain_uuid."', ";
						$sql .= "'".$conference_uuid."', ";
						$sql .= "'".$user_uuid."' ";
						$sql .= ")";
						if ($export_type == "sql") { echo check_sql($sql).";\n"; }
						if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
					}
				}
			}
			unset($user_list_array);
	}
	unset ($prepstatement, $result, $sql, $user_list);

//get the fax information
	$sql = "select * from v_fax ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$fax_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$fax_extension = check_str($row["fax_extension"]);
		$fax_name = check_str($row["fax_name"]);
		$fax_email = check_str($row["fax_email"]);
		$fax_pin_number = check_str($row["fax_pin_number"]);
		$fax_caller_id_name = check_str($row["fax_caller_id_name"]);
		$fax_caller_id_number = check_str($row["fax_caller_id_number"]);
		$fax_user_list = check_str($row["fax_user_list"]);
		$fax_forward_number = check_str($row["fax_forward_number"]);
		$fax_description = check_str($row["fax_description"]);

		$sql = "insert into v_fax ";
		$sql .= "(";
		$sql .= "fax_uuid, ";
		$sql .= "domain_uuid, ";
		//dialplan_uuid
		$sql .= "fax_extension, ";
		$sql .= "fax_name, ";
		$sql .= "fax_email, ";
		$sql .= "fax_pin_number, ";
		$sql .= "fax_caller_id_name, ";
		$sql .= "fax_caller_id_number, ";
		$sql .= "fax_forward_number, ";
		$sql .= "fax_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$fax_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		//dialplan_uuid
		$sql .= "'".$fax_extension."', ";
		$sql .= "'".$fax_name."', ";
		$sql .= "'".$fax_email."', ";
		$sql .= "'".$fax_pin_number."', ";
		$sql .= "'".$fax_caller_id_name."', ";
		$sql .= "'".$fax_caller_id_number."', ";
		if (strlen($fax_forward_number) > 0) {
			$sql .= "'".$fax_forward_number."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$fax_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }

		$user_list_array = explode("|", $fax_user_list);
		foreach($user_list_array as $username){
			if (strlen($username) > 0) {
				$user_uuid = $user_array[$v_id][$username]['user_uuid'];
				if (strlen($user_uuid) > 0) {
					$sql = "insert into v_fax_users ";
					$sql .= "(";
					$sql .= "fax_user_uuid, ";
					$sql .= "domain_uuid, ";
					$sql .= "fax_uuid, ";
					$sql .= "user_uuid ";
					$sql .= ")";
					$sql .= "values ";
					$sql .= "(";
					$sql .= "'".uuid()."', ";
					$sql .= "'".$domain_uuid."', ";
					$sql .= "'".$fax_uuid."', ";
					$sql .= "'".$user_uuid."' ";
					$sql .= ")";
					if ($export_type == "sql") { echo check_sql($sql).";\n"; }
					if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
				}
			}
		}
		unset($user_list_array);
		unset($username);
	}
	unset ($prep_statement);

//export the gateways
	$sql = "select * from v_gateways ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$gateway_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$gateway = check_str($row["gateway"]);
		$username = check_str($row["username"]);
		$password = check_str($row["password"]);
		$auth_username = check_str($row["auth_username"]);
		$realm = check_str($row["realm"]);
		$from_user = check_str($row["from_user"]);
		$from_domain = check_str($row["from_domain"]);
		$proxy = check_str($row["proxy"]);
		$register_proxy = check_str($row["register_proxy"]);
		$outbound_proxy = check_str($row["outbound_proxy"]);
		$expire_seconds = check_str($row["expire_seconds"]);
		$register = check_str($row["register"]);
		$register_transport = check_str($row["register_transport"]);
		$retry_seconds = check_str($row["retry_seconds"]);
		$extension = check_str($row["extension"]);
		$ping = check_str($row["ping"]);
		$caller_id_in_from = check_str($row["caller_id_in_from"]);
		$supress_cng = check_str($row["supress_cng"]);
		$sip_cid_type = check_str($row["sip_cid_type"]);
		$extension_in_contact = check_str($row["extension_in_contact"]);
		$context = check_str($row["context"]);
		$profile = check_str($row["profile"]);
		$enabled = check_str($row["enabled"]);
		$description = check_str($row["description"]);

		$sql = "insert into v_gateways ";
		$sql .= "(";
		$sql .= "gateway_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "gateway, ";
		$sql .= "username, ";
		$sql .= "password, ";
		$sql .= "auth_username, ";
		$sql .= "realm, ";
		$sql .= "from_user, ";
		$sql .= "from_domain, ";
		$sql .= "proxy, ";
		$sql .= "register_proxy, ";
		$sql .= "outbound_proxy, ";
		$sql .= "expire_seconds, ";
		$sql .= "register, ";
		$sql .= "register_transport, ";
		$sql .= "retry_seconds, ";
		$sql .= "extension, ";
		$sql .= "ping, ";
		$sql .= "caller_id_in_from, ";
		$sql .= "supress_cng, ";
		$sql .= "sip_cid_type, ";
		$sql .= "extension_in_contact, ";
		$sql .= "context, ";
		$sql .= "profile, ";
		$sql .= "enabled, ";
		$sql .= "description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$gateway_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$gateway."', ";
		$sql .= "'".$username."', ";
		$sql .= "'".$password."', ";
		$sql .= "'".$auth_username."', ";
		$sql .= "'".$realm."', ";
		$sql .= "'".$from_user."', ";
		$sql .= "'".$from_domain."', ";
		$sql .= "'".$proxy."', ";
		$sql .= "'".$register_proxy."', ";
		$sql .= "'".$outbound_proxy."', ";
		$sql .= "'".$expire_seconds."', ";
		$sql .= "'".$register."', ";
		$sql .= "'".$register_transport."', ";
		$sql .= "'".$retry_seconds."', ";
		$sql .= "'".$extension."', ";
		$sql .= "'".$ping."', ";
		$sql .= "'".$caller_id_in_from."', ";
		$sql .= "'".$supress_cng."', ";
		$sql .= "'".$sip_cid_type."', ";
		$sql .= "'".$extension_in_contact."', ";
		$sql .= "'".$context."', ";
		$sql .= "'".$profile."', ";
		$sql .= "'".$enabled."', ";
		$sql .= "'".$description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the provisioning information
	$sql = "select * from v_hardware_phones ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$hardware_phone_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$phone_mac_address = check_str($row["phone_mac_address"]);
		$phone_label = check_str($row["phone_label"]);
		$phone_vendor = check_str($row["phone_vendor"]);
		$phone_model = check_str($row["phone_model"]);
		$phone_firmware_version = check_str($row["phone_firmware_version"]);
		$phone_provision_enable = check_str($row["phone_provision_enable"]);
		$phone_template = check_str($row["phone_template"]);
		$phone_username = check_str($row["phone_username"]);
		$phone_password = check_str($row["phone_password"]);
		$phone_time_zone = check_str($row["phone_time_zone"]);
		$phone_description = check_str($row["phone_description"]);

		$sql = "insert into v_hardware_phones ";
		$sql .= "(";
		$sql .= "hardware_phone_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "phone_mac_address, ";
		$sql .= "phone_label, ";
		$sql .= "phone_vendor, ";
		$sql .= "phone_model, ";
		$sql .= "phone_firmware_version, ";
		$sql .= "phone_provision_enable, ";
		$sql .= "phone_template, ";
		$sql .= "phone_username, ";
		$sql .= "phone_password, ";
		$sql .= "phone_time_zone, ";
		$sql .= "phone_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$hardware_phone_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$phone_mac_address."', ";
		$sql .= "'".$phone_label."', ";
		$sql .= "'".$phone_vendor."', ";
		$sql .= "'".$phone_model."', ";
		$sql .= "'".$phone_firmware_version."', ";
		$sql .= "'".$phone_provision_enable."', ";
		$sql .= "'".$phone_template."', ";
		$sql .= "'".$phone_username."', ";
		$sql .= "'".$phone_password."', ";
		$sql .= "'".$phone_time_zone."', ";
		$sql .= "'".$phone_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the hunt groups
	$sql = "select * from v_hunt_group ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$hunt_group_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$hunt_group_extension = check_str($row["hunt_group_extension"]);
		$hunt_group_id = check_str($row["hunt_group_id"]);
		$hunt_group_name = check_str($row["hunt_group_name"]);
		$hunt_group_type = check_str($row["hunt_group_type"]);
		$hunt_group_context = check_str($row["hunt_group_context"]);
		$hunt_group_timeout = check_str($row["hunt_group_timeout"]);
		$hunt_group_timeout_destination = check_str($row["hunt_group_timeout_destination"]);
		$hunt_group_timeout_type = check_str($row["hunt_group_time_out_type"]);
		$hunt_group_ringback = check_str($row["hunt_group_ringback"]);
		$hunt_group_cid_name_prefix = check_str($row["hunt_group_cid_name_prefix"]);
		$hunt_group_pin = check_str($row["hunt_group_pin"]);
		$hunt_group_caller_announce = check_str($row["hunt_group_caller_announce"]);
		$hunt_group_call_prompt = check_str($row["hunt_group_call_prompt"]);
		$hunt_group_user_list = check_str($row["hunt_group_user_list"]);
		$hunt_group_enabled = check_str($row["hunt_group_enabled"]);
		$hunt_group_description = check_str($row["hunt_group_descr"]);

		//set the hunt_group_uuid
		$hunt_group_array[$hunt_group_id]['hunt_group_uuid'] = $hunt_group_uuid;

		$sql = "insert into v_hunt_groups ";
		$sql .= "(";
		$sql .= "hunt_group_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "hunt_group_extension, ";
		$sql .= "hunt_group_name, ";
		$sql .= "hunt_group_type, ";
		$sql .= "hunt_group_context, ";
		$sql .= "hunt_group_timeout, ";
		$sql .= "hunt_group_timeout_destination, ";
		$sql .= "hunt_group_timeout_type, ";
		$sql .= "hunt_group_ringback, ";
		$sql .= "hunt_group_cid_name_prefix, ";
		$sql .= "hunt_group_pin, ";
		$sql .= "hunt_group_caller_announce, ";
		$sql .= "hunt_group_call_prompt, ";
		$sql .= "hunt_group_user_list, ";
		$sql .= "hunt_group_enabled, ";
		$sql .= "hunt_group_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$hunt_group_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$hunt_group_extension."', ";
		$sql .= "'".$hunt_group_name."', ";
		$sql .= "'".$hunt_group_type."', ";
		$sql .= "'".$hunt_group_context."', ";
		$sql .= "'".$hunt_group_timeout."', ";
		$sql .= "'".$hunt_group_timeout_destination."', ";
		$sql .= "'".$hunt_group_timeout_type."', ";
		$sql .= "'".$hunt_group_ringback."', ";
		$sql .= "'".$hunt_group_cid_name_prefix."', ";
		$sql .= "'".$hunt_group_pin."', ";
		$sql .= "'".$hunt_group_caller_announce."', ";
		$sql .= "'".$hunt_group_call_prompt."', ";
		$sql .= "'".$hunt_group_user_list."', ";
		$sql .= "'".$hunt_group_enabled."', ";
		$sql .= "'".$hunt_group_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the hunt group destinations
	$sql = "select * from v_hunt_group_destinations ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$hunt_group_destination_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$hunt_group_id = check_str($row["hunt_group_id"]);
		$destination_data = check_str($row["destination_data"]);
		$destination_type = check_str($row["destination_type"]);
		$destination_profile = check_str($row["destination_profile"]);
		$destination_timeout = check_str($row["destination_timeout"]);
		$destination_order = check_str($row["destination_order"]);
		$destination_enabled = check_str($row["destination_enabled"]);
		$destination_description = check_str($row["destination_descr"]);

		//get the hunt_group_uuid
		$hunt_group_uuid = $hunt_group_array[$hunt_group_id]['hunt_group_uuid'];

		$sql = "insert into v_hunt_group_destinations ";
		$sql .= "(";
		$sql .= "hunt_group_destination_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "hunt_group_uuid, ";
		$sql .= "destination_data, ";
		$sql .= "destination_type, ";
		$sql .= "destination_profile, ";
		$sql .= "destination_timeout, ";
		$sql .= "destination_order, ";
		$sql .= "destination_enabled, ";
		$sql .= "destination_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$hunt_group_destination_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$hunt_group_uuid."', ";
		$sql .= "'".$destination_data."', ";
		$sql .= "'".$destination_type."', ";
		$sql .= "'".$destination_profile."', ";
		$sql .= "'".$destination_timeout."', ";
		if (strlen($destination_order) > 0) {
			$sql .= "'".$destination_order."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$destination_enabled."', ";
		$sql .= "'".$destination_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the invoices
	if ($invoices) {
		//get the invoices and insert them
			$sql = "select * from v_invoices ";
			$prep_statement = $db->prepare($sql);
			$prep_statement->execute();
			$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
			foreach ($result as &$row) {
				$invoice_id = check_str($row["invoice_id"]);
				//set the invoice_uuid
				$invoice_array[$invoice_id]['uuid'] = uuid();
			}
			foreach ($result as &$row) {
				$invoice_id = check_str($row["invoice_id"]);
				$invoice_uuid = uuid();
				$v_id = check_str($row["v_id"]);
				$domain_uuid = $domain_array[$v_id]['domain_uuid'];
				$contact_id_from = check_str($row["contact_id_from"]);
				$contact_id_to = check_str($row["contact_id_to"]);
				$invoice_number = check_str($row["invoice_number"]);
				$invoice_date = check_str($row["invoice_date"]);
				$invoice_notes = check_str($row["invoice_notes"]);

				//get the uuids
				$invoice_uuid = $invoice_array[$invoice_id]['uuid'];
				$contact_uuid_from = $contact_array[$contact_id_from]['contact_uuid'];
				$contact_uuid_to = $contact_array[$contact_id_to]['contact_uuid'];

				$sql = "insert into v_invoices ";
				$sql .= "(";
				$sql .= "invoice_uuid, ";
				$sql .= "domain_uuid, ";
				$sql .= "contact_uuid_from, ";
				$sql .= "contact_uuid_to, ";
				$sql .= "invoice_number, ";
				$sql .= "invoice_date, ";
				$sql .= "invoice_notes ";
				$sql .= ")";
				$sql .= "values ";
				$sql .= "(";
				$sql .= "'".$invoice_uuid."', ";
				$sql .= "'".$domain_uuid."', ";
				if (strlen($contact_uuid_from) > 0) {
					$sql .= "'".$contact_uuid_from."', ";
				}
				else {
					$sql .= "null, ";
				}
				if (strlen($contact_uuid_to) > 0) {
					$sql .= "'".$contact_uuid_to."', ";
				}
				else {
					$sql .= "null, ";
				}
				if (strlen($invoice_number) > 0) {
					$sql .= "'".$invoice_number."', ";
				}
				else {
					$sql .= "null, ";
				}
				$sql .= "'".$invoice_date."', ";
				$sql .= "'".$invoice_notes."' ";
				$sql .= ")";
				if ($export_type == "sql") { echo check_sql($sql).";\n"; }
				if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
			}
			unset ($prep_statement);

		//export invoice items
			$sql = "select * from v_invoice_items ";
			$prep_statement = $db->prepare($sql);
			$prep_statement->execute();
			$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
			foreach ($result as &$row) {
				$invoice_item_uuid = uuid();
				$v_id = check_str($row["v_id"]);
				$domain_uuid = $domain_array[$v_id]['domain_uuid'];
				$invoice_id = check_str($row["invoice_id"]);
				$item_qty = check_str($row["item_qty"]);
				$item_description = check_str($row["item_desc"]);
				$item_unit_price = check_str($row["item_unit_price"]);

				//get the invoice_uuid
				$invoice_uuid = $invoice_array[$invoice_id]['uuid'];

				$sql = "insert into v_invoice_items ";
				$sql .= "(";
				$sql .= "invoice_item_uuid, ";
				$sql .= "domain_uuid, ";
				$sql .= "invoice_uuid, ";
				$sql .= "item_qty, ";
				$sql .= "item_desc, ";
				$sql .= "item_unit_price ";
				$sql .= ")";
				$sql .= "values ";
				$sql .= "(";
				$sql .= "'".$invoice_item_uuid."', ";
				$sql .= "'".$domain_uuid."', ";
				$sql .= "'".$invoice_uuid."', ";
				if (strlen($item_qty) > 0) {
					$sql .= "'".$item_qty."', ";
				}
				else {
					$sql .= "null, ";
				}
				$sql .= "'".$item_desc."', ";
				if (strlen($item_unit_price) > 0) {
					$sql .= "'".$item_unit_price."' ";
				}
				else {
					$sql .= "null ";
				}
				$sql .= ")";
				if ($export_type == "sql") { echo check_sql($sql).";\n"; }
				if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
			}
			unset ($prep_statement);
	}

//export the ivr menus
	$sql = "select * from v_ivr_menu ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$ivr_menu_id = check_str($row["ivr_menu_id"]);
		$ivr_menu_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$ivr_menu_name = check_str($row["ivr_menu_name"]);
		$ivr_menu_extension = check_str($row["ivr_menu_extension"]);
		$ivr_menu_greet_long = check_str($row["ivr_menu_greet_long"]);
		$ivr_menu_greet_short = check_str($row["ivr_menu_greet_short"]);
		$ivr_menu_invalid_sound = check_str($row["ivr_menu_invalid_sound"]);
		$ivr_menu_exit_sound = check_str($row["ivr_menu_exit_sound"]);
		$ivr_menu_confirm_macro = check_str($row["ivr_menu_confirm_macro"]);
		$ivr_menu_confirm_key = check_str($row["ivr_menu_confirm_key"]);
		$ivr_menu_tts_engine = check_str($row["ivr_menu_tts_engine"]);
		$ivr_menu_tts_voice = check_str($row["ivr_menu_tts_voice"]);
		$ivr_menu_confirm_attempts = check_str($row["ivr_menu_confirm_attempts"]);
		$ivr_menu_timeout = check_str($row["ivr_menu_timeout"]);
		$ivr_menu_exit_app = check_str($row["ivr_menu_exit_app"]);
		$ivr_menu_exit_data = check_str($row["ivr_menu_exit_data"]);
		$ivr_menu_inter_digit_timeout = check_str($row["ivr_menu_inter_digit_timeout"]);
		$ivr_menu_max_failures = check_str($row["ivr_menu_max_failures"]);
		$ivr_menu_max_timeouts = check_str($row["ivr_menu_max_timeouts"]);
		$ivr_menu_digit_len = check_str($row["ivr_menu_digit_len"]);
		$ivr_menu_direct_dial = check_str($row["ivr_menu_direct_dial"]);
		$ivr_menu_enabled = check_str($row["ivr_menu_enabled"]);
		$ivr_menu_description = check_str($row["ivr_menu_desc"]);

		//set the ivr_menu_uuid
		$ivr_menu_array[$ivr_menu_id]['ivr_menu_uuid'] = $ivr_menu_uuid;

		$sql = "insert into v_ivr_menus ";
		$sql .= "(";
		$sql .= "ivr_menu_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "ivr_menu_name, ";
		$sql .= "ivr_menu_extension, ";
		$sql .= "ivr_menu_greet_long, ";
		$sql .= "ivr_menu_greet_short, ";
		$sql .= "ivr_menu_invalid_sound, ";
		$sql .= "ivr_menu_exit_sound, ";
		$sql .= "ivr_menu_confirm_macro, ";
		$sql .= "ivr_menu_confirm_key, ";
		$sql .= "ivr_menu_tts_engine, ";
		$sql .= "ivr_menu_tts_voice, ";
		$sql .= "ivr_menu_confirm_attempts, ";
		$sql .= "ivr_menu_timeout, ";
		$sql .= "ivr_menu_exit_app, ";
		$sql .= "ivr_menu_exit_data, ";
		$sql .= "ivr_menu_inter_digit_timeout, ";
		$sql .= "ivr_menu_max_failures, ";
		$sql .= "ivr_menu_max_timeouts, ";
		$sql .= "ivr_menu_digit_len, ";
		$sql .= "ivr_menu_direct_dial, ";
		$sql .= "ivr_menu_enabled, ";
		$sql .= "ivr_menu_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$ivr_menu_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$ivr_menu_name."', ";
		$sql .= "'".$ivr_menu_extension."', ";
		$sql .= "'".$ivr_menu_greet_long."', ";
		$sql .= "'".$ivr_menu_greet_short."', ";
		$sql .= "'".$ivr_menu_invalid_sound."', ";
		$sql .= "'".$ivr_menu_exit_sound."', ";
		$sql .= "'".$ivr_menu_confirm_macro."', ";
		$sql .= "'".$ivr_menu_confirm_key."', ";
		$sql .= "'".$ivr_menu_tts_engine."', ";
		$sql .= "'".$ivr_menu_tts_voice."', ";
		$sql .= "'".$ivr_menu_confirm_attempts."', ";
		$sql .= "'".$ivr_menu_timeout."', ";
		$sql .= "'".$ivr_menu_exit_app."', ";
		$sql .= "'".$ivr_menu_exit_data."', ";
		$sql .= "'".$ivr_menu_inter_digit_timeout."', ";
		$sql .= "'".$ivr_menu_max_failures."', ";
		$sql .= "'".$ivr_menu_max_timeouts."', ";
		$sql .= "'".$ivr_menu_digit_len."', ";
		$sql .= "'".$ivr_menu_direct_dial."', ";
		$sql .= "'".$ivr_menu_enabled."', ";
		$sql .= "'".$ivr_menu_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the ivr menu options
	$sql = "select * from v_ivr_menu_options ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$ivr_menu_option_uuid = uuid();
		$ivr_menu_id = check_str($row["ivr_menu_id"]);
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$ivr_menu_option_digits = check_str($row["ivr_menu_options_digits"]);
		$ivr_menu_option_action = check_str($row["ivr_menu_options_action"]);
		$ivr_menu_option_param = check_str($row["ivr_menu_options_param"]);
		$ivr_menu_option_order = check_str($row["ivr_menu_options_order"]);
		$ivr_menu_option_description = check_str($row["ivr_menu_options_desc"]);
		$ivr_menu_options_action = str_replace("\\\\", "\\", $ivr_menu_options_action);

		//get the ivr_menu_uuid
		$ivr_menu_uuid = $ivr_menu_array[$ivr_menu_id]['ivr_menu_uuid'];

		$sql = "insert into v_ivr_menu_options ";
		$sql .= "(";
		$sql .= "ivr_menu_option_uuid, ";
		$sql .= "ivr_menu_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "ivr_menu_option_digits, ";
		$sql .= "ivr_menu_option_action, ";
		$sql .= "ivr_menu_option_param, ";
		$sql .= "ivr_menu_option_order, ";
		$sql .= "ivr_menu_option_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$ivr_menu_option_uuid."', ";
		$sql .= "'".$ivr_menu_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$ivr_menu_option_digits."', ";
		$sql .= "'".$ivr_menu_option_action."', ";
		$sql .= "'".$ivr_menu_option_param."', ";
		$sql .= "'".$ivr_menu_option_order."', ";
		$sql .= "'".$ivr_menu_option_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the modules
	$sql = "select * from v_modules ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$module_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$module_label = check_str($row["module_label"]);
		$module_name = check_str($row["module_name"]);
		$module_description = check_str($row["module_desc"]);
		$module_category = check_str($row["module_category"]);
		$module_enabled = check_str($row["module_enabled"]);
		$module_default_enabled = check_str($row["module_default_enabled"]);

		$sql = "insert into v_modules ";
		$sql .= "(";
		$sql .= "module_uuid, ";
		$sql .= "module_label, ";
		$sql .= "module_name, ";
		$sql .= "module_description, ";
		$sql .= "module_category, ";
		$sql .= "module_enabled, ";
		$sql .= "module_default_enabled ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$module_uuid."', ";
		$sql .= "'".$module_label."', ";
		$sql .= "'".$module_name."', ";
		$sql .= "'".$module_description."', ";
		$sql .= "'".$module_category."', ";
		$sql .= "'".$module_enabled."', ";
		$sql .= "'".$module_default_enabled."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export to php services
	$sql = "select * from v_php_service ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$php_service_uuid = uuid();
		$service_name = check_str($row["service_name"]);
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$service_script = check_str($row["service_script"]);
		$service_enabled = check_str($row["service_enabled"]);
		$service_description = check_str($row["service_description"]);

		$sql = "insert into v_php_services ";
		$sql .= "(";
		$sql .= "php_service_uuid, ";
		$sql .= "service_name, ";
		$sql .= "domain_uuid, ";
		$sql .= "service_script, ";
		$sql .= "service_enabled, ";
		$sql .= "service_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$php_service_uuid."', ";
		$sql .= "'".$service_name."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$service_script."', ";
		$sql .= "'".$service_enabled."', ";
		$sql .= "'".$service_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the recordings
	$sql = "select * from v_recordings ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$recording_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$recording_filename = check_str($row["recording_filename"]);
		$recording_name = check_str($row["recording_name"]);
		$recording_description = check_str($row["recording_desc"]);

		$sql = "insert into v_recordings ";
		$sql .= "(";
		$sql .= "recording_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "recording_filename, ";
		$sql .= "recording_name, ";
		$sql .= "recording_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$recording_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$recording_filename."', ";
		$sql .= "'".$recording_name."', ";
		$sql .= "'".$recording_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the services
	$sql = "select * from v_services ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$service_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$service_name = check_str($row["v_service_name"]);
		$service_type = check_str($row["v_service_type"]);
		$service_data = check_str($row["v_service_data"]);
		$service_cmd_start = check_str($row["v_service_cmd_start"]);
		$service_cmd_stop = check_str($row["v_service_cmd_stop"]);
		$service_cmd_restart = check_str($row["v_service_cmd_restart"]);
		$service_description = check_str($row["v_service_desc"]);

		$sql = "insert into v_services ";
		$sql .= "(";
		$sql .= "service_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "service_name, ";
		$sql .= "service_type, ";
		$sql .= "service_data, ";
		$sql .= "service_cmd_start, ";
		$sql .= "service_cmd_stop, ";
		$sql .= "service_cmd_restart, ";
		$sql .= "service_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$service_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$service_name."', ";
		$sql .= "'".$service_type."', ";
		$sql .= "'".$service_data."', ";
		$sql .= "'".$service_cmd_start."', ";
		$sql .= "'".$service_cmd_stop."', ";
		$sql .= "'".$service_cmd_restart."', ";
		$sql .= "'".$service_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the settings
	$sql = "select * from v_settings ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$numbering_plan = check_str($row["numbering_plan"]);
		$smtp_password = check_str($row["default_gateway"]);
		$event_socket_ip_address = check_str($row["event_socket_ip_address"]);
		$event_socket_port = check_str($row["event_socket_port"]);
		$event_socket_password = check_str($row["event_socket_password"]);
		$xml_rpc_http_port = check_str($row["xml_rpc_http_port"]);
		$xml_rpc_auth_realm = check_str($row["xml_rpc_auth_realm"]);
		$xml_rpc_auth_user = check_str($row["xml_rpc_auth_user"]);
		$xml_rpc_auth_pass = check_str($row["xml_rpc_auth_pass"]);
		$admin_pin = check_str($row["admin_pin"]);
		$smtp_host = check_str($row["smtp_host"]);
		$smtp_secure = check_str($row["smtp_secure"]);
		$smtp_auth = check_str($row["smtp_auth"]);
		$smtp_username = check_str($row["smtp_username"]);
		$smtp_password = check_str($row["smtp_password"]);
		$smtp_from = check_str($row["smtp_from"]);
		$smtp_from_name = check_str($row["smtp_from_name"]);
		$mod_shout_decoder = check_str($row["mod_shout_decoder"]);
		$mod_shout_volume = check_str($row["mod_shout_volume"]);

		$sql = "insert into v_settings ";
		$sql .= "(";
		$sql .= "numbering_plan, ";
		$sql .= "event_socket_ip_address, ";
		$sql .= "event_socket_port, ";
		$sql .= "event_socket_password, ";
		$sql .= "xml_rpc_http_port, ";
		$sql .= "xml_rpc_auth_realm, ";
		$sql .= "xml_rpc_auth_user, ";
		$sql .= "xml_rpc_auth_pass, ";
		$sql .= "admin_pin, ";
		$sql .= "smtp_host, ";
		$sql .= "smtp_secure, ";
		$sql .= "smtp_auth, ";
		$sql .= "smtp_username, ";
		$sql .= "smtp_password, ";
		$sql .= "smtp_from, ";
		$sql .= "smtp_from_name, ";
		$sql .= "mod_shout_decoder, ";
		$sql .= "mod_shout_volume ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$numbering_plan."', ";
		$sql .= "'".$event_socket_ip_address."', ";
		$sql .= "'".$event_socket_port."', ";
		$sql .= "'".$event_socket_password."', ";
		$sql .= "'".$xml_rpc_http_port."', ";
		$sql .= "'".$xml_rpc_auth_realm."', ";
		$sql .= "'".$xml_rpc_auth_user."', ";
		$sql .= "'".$xml_rpc_auth_pass."', ";
		$sql .= "'".$admin_pin."', ";
		$sql .= "'".$smtp_host."', ";
		$sql .= "'".$smtp_secure."', ";
		$sql .= "'".$smtp_auth."', ";
		$sql .= "'".$smtp_username."', ";
		$sql .= "'".$smtp_password."', ";
		$sql .= "'".$smtp_from."', ";
		$sql .= "'".$smtp_from_name."', ";
		$sql .= "'".$mod_shout_decoder."', ";
		$sql .= "'".$mod_shout_volume."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//get the time conditions and use diaplan_uuid to set the app_uuid
	$sql = "select * from v_dialplan_includes_details ";
	$prepstatement = $db->prepare(check_sql($sql));
	$prepstatement->execute();
	$x = 0;
	$result = $prepstatement->fetchAll();
	foreach ($result as &$row) {
		$dialplan_include_id = $row["dialplan_include_id"];
		$field_type = $row["field_type"];
		//$field_data = $row["field_data"];

		//get the dialplan_uuid
		$dialplan_uuid = $dialplan_array[$dialplan_include_id]['dialplan_uuid'];

		switch ($row['field_type']) {
		case "hour":
			$time_array[$x]['dialplan_uuid'] = $dialplan_uuid;
			$x++;
			break;
		case "minute":
			$time_array[$x]['dialplan_uuid'] = $dialplan_uuid;
			$x++;
			break;
		case "minute-of-day":
			$time_array[$x]['dialplan_uuid'] = $dialplan_uuid;
			$x++;
			break;
		case "mday":
			$time_array[$x]['dialplan_uuid'] = $dialplan_uuid;
			$x++;
			break;
		case "mweek":
			$time_array[$x]['dialplan_uuid'] = $dialplan_uuid;
			$x++;
			break;
		case "mon":
			$time_array[$x]['dialplan_uuid'] = $dialplan_uuid;
			$x++;
			break;
		case "yday":
			$time_array[$x]['dialplan_uuid'] = $dialplan_uuid;
			$x++;
			break;
		case "year":
			$time_array[$x]['dialplan_uuid'] = $dialplan_uuid;
			$x++;
			break;
		case "wday":
			$time_array[$x]['dialplan_uuid'] = $dialplan_uuid;
			$x++;
			break;
		case "week":
			$time_array[$x]['dialplan_uuid'] = $dialplan_uuid;
			$x++;
			break;
		}
	}
	unset ($prepstatement);
	foreach ($time_array as &$row) {
		$sql = "update v_dialplans set ";
		$sql .= "app_uuid = '4b821450-926b-175a-af93-a03c441818b1' ";
		$sql .= "where dialplan_uuid = '".$row['dialplan_uuid']."' ";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
		unset($sql);
	}

//get the variables
	$sql = "select * from v_vars ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$var_uuid = uuid();
		$var_name = check_str($row["var_name"]);
		$var_value = check_str($row["var_value"]);
		$var_cat = check_str($row["var_cat"]);
		$var_enabled = check_str($row["var_enabled"]);
		$var_order = check_str($row["var_order"]);
		$var_description = check_str($row["var_desc"]);

		$sql = "insert into v_vars ";
		$sql .= "(";
		$sql .= "var_uuid, ";
		$sql .= "var_name, ";
		$sql .= "var_value, ";
		$sql .= "var_cat, ";
		$sql .= "var_enabled, ";
		$sql .= "var_order, ";
		$sql .= "var_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$var_uuid."', ";
		$sql .= "'".$var_name."', ";
		$sql .= "'".$var_value."', ";
		$sql .= "'".$var_cat."', ";
		$sql .= "'".$var_enabled."', ";
		$sql .= "'".$var_order."', ";
		$sql .= "'".$var_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the virtual tables
	$sql = "select * from v_virtual_tables ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$virtual_table_id = check_str($row["virtual_table_id"]);
		$virtual_table_uuid = uuid();

		//set the virtual_table_uuid
		$virtual_table_array[$virtual_table_id]['virtual_table_uuid'] = $virtual_table_uuid;
	}
	foreach ($result as &$row) {
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$virtual_table_id = check_str($row["virtual_table_id"]);
		$virtual_table_category = check_str($row["virtual_table_category"]);
		$virtual_table_label = check_str($row["virtual_table_label"]);
		$virtual_table_name = check_str($row["virtual_table_name"]);
		$virtual_table_auth = check_str($row["virtual_table_auth"]);
		$virtual_table_captcha = check_str($row["virtual_table_captcha"]);
		$virtual_table_parent_id = check_str($row["virtual_table_parent_id"]);
		$virtual_table_description = check_str($row["virtual_table_desc"]);

		//get the uuids
		$virtual_table_uuid = $virtual_table_array[$virtual_table_id]['virtual_table_uuid'];
		if (strlen($virtual_table_parent_id) > 0) {
			$virtual_table_parent_uuid = $virtual_table_array[$virtual_table_parent_id]['virtual_table_uuid'];
		}

		$sql = "insert into v_virtual_tables ";
		$sql .= "(";
		$sql .= "virtual_table_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "virtual_table_category, ";
		$sql .= "virtual_table_label, ";
		$sql .= "virtual_table_name, ";
		$sql .= "virtual_table_auth, ";
		$sql .= "virtual_table_captcha, ";
		$sql .= "virtual_table_parent_uuid, ";
		$sql .= "virtual_table_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$virtual_table_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$virtual_table_category."', ";
		$sql .= "'".$virtual_table_label."', ";
		$sql .= "'".$virtual_table_name."', ";
		$sql .= "'".$virtual_table_auth."', ";
		$sql .= "'".$virtual_table_captcha."', ";
		if (strlen($virtual_table_parent_uuid) > 0) {
			$sql .= "'".$virtual_table_parent_uuid."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$virtual_table_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//export the virtual table fields
	$sql = "select * from v_virtual_table_fields ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$virtual_table_field_id = check_str($row["virtual_table_field_id"]);
		$virtual_table_field_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$virtual_table_id = check_str($row["virtual_table_id"]);
		$virtual_field_label = check_str($row["virtual_field_label"]);
		$virtual_field_name = check_str($row["virtual_field_name"]);
		$virtual_field_type = check_str($row["virtual_field_type"]);
		$virtual_field_list_hidden = check_str($row["virtual_field_list_hidden"]);
		$virtual_field_column = check_str($row["virtual_field_column"]);
		$virtual_field_required = check_str($row["virtual_field_required"]);
		$virtual_field_order = check_str($row["virtual_field_order"]);
		$virtual_field_order_tab = check_str($row["virtual_field_order_tab"]);
		$virtual_field_description = check_str($row["virtual_field_desc"]);
		$virtual_field_value = check_str($row["virtual_field_value"]);

		//get the virtual_table_uuid
		$virtual_table_uuid = $virtual_table_array[$virtual_table_id]['virtual_table_uuid'];

		//set virtual_table_field_uuid
		$virtual_table_field_array[$virtual_table_field_id]['virtual_table_field_uuid'] = $virtual_table_field_uuid;
		if (strlen($virtual_table_uuid) > 0) {
			$sql = "insert into v_virtual_table_fields ";
			$sql .= "(";
			$sql .= "virtual_table_field_uuid, ";
			$sql .= "domain_uuid, ";
			$sql .= "virtual_table_uuid, ";
			$sql .= "virtual_field_label, ";
			$sql .= "virtual_field_name, ";
			$sql .= "virtual_field_type, ";
			$sql .= "virtual_field_list_hidden, ";
			$sql .= "virtual_field_column, ";
			$sql .= "virtual_field_required, ";
			$sql .= "virtual_field_order, ";
			$sql .= "virtual_field_order_tab, ";
			$sql .= "virtual_field_description, ";
			$sql .= "virtual_field_value ";
			$sql .= ")";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'".$virtual_table_field_uuid."', ";
			$sql .= "'".$domain_uuid."', ";
			$sql .= "'".$virtual_table_uuid."', ";
			$sql .= "'".$virtual_field_label."', ";
			$sql .= "'".$virtual_field_name."', ";
			$sql .= "'".$virtual_field_type."', ";
			$sql .= "'".$virtual_field_list_hidden."', ";
			$sql .= "'".$virtual_field_column."', ";
			$sql .= "'".$virtual_field_required."', ";
			$sql .= "'".$virtual_field_order."', ";
			$sql .= "'".$virtual_field_order_tab."', ";
			$sql .= "'".$virtual_field_description."', ";
			$sql .= "'".$virtual_field_value."' ";
			$sql .= ")";
			if ($export_type == "sql") { echo check_sql($sql).";\n"; }
			if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
		}
	}
	unset ($prep_statement);

//export the virtual table data
	$sql = "select * from v_virtual_table_data ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	while($row = $prep_statement->fetch(PDO::FETCH_ASSOC)) {
		$virtual_table_data_id = check_str($row["virtual_table_data_id"]);
		$virtual_table_data_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$virtual_table_id = check_str($row["virtual_table_id"]);
		$virtual_data_row_id = check_str($row["virtual_data_row_id"]);
		$virtual_field_name = check_str($row["virtual_field_name"]);
		$virtual_data_field_value = check_str($row["virtual_data_field_value"]);
		$virtual_data_add_user = check_str($row["virtual_data_add_user"]);
		$virtual_data_add_date = check_str($row["virtual_data_add_date"]);
		$virtual_data_del_user = check_str($row["virtual_data_del_user"]);
		$virtual_data_del_date = check_str($row["virtual_data_del_date"]);
		$virtual_table_parent_id = check_str($row["virtual_table_parent_id"]);
		$virtual_data_parent_row_uuid = check_str($row["virtual_data_parent_row_id"]);

		//get the virtual_table_uuid
		$virtual_table_uuid = $virtual_table_array[$virtual_table_id]['virtual_table_uuid'];
		if (strlen($virtual_table_parent_id) > 0) {
			$virtual_table_parent_uuid = $virtual_table_array[$virtual_table_parent_id]['virtual_table_uuid'];
		}

		//get or set the virtual table data row uuid
		if (strlen($virtual_table_array[$virtual_data_row_id]['virtual_data_row_uuid']) == 0) {
			$virtual_data_row_uuid = uuid();
			$virtual_table_array[$virtual_data_row_id]['virtual_data_row_uuid'] = $virtual_data_row_uuid;
		}
		else {
			$virtual_data_row_uuid = $virtual_table_array[$virtual_data_row_id]['virtual_data_row_uuid'];
		}

		$sql = "insert into v_virtual_table_data ";
		$sql .= "(";
		$sql .= "virtual_table_data_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "virtual_table_uuid, ";
		$sql .= "virtual_data_row_uuid, ";
		$sql .= "virtual_field_name, ";
		$sql .= "virtual_data_field_value, ";
		$sql .= "virtual_table_parent_uuid, ";
		$sql .= "virtual_data_parent_row_uuid, ";
		$sql .= "virtual_data_add_user, ";
		$sql .= "virtual_data_add_date, ";
		$sql .= "virtual_data_del_user, ";
		$sql .= "virtual_data_del_date ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$virtual_table_data_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$virtual_table_uuid."', ";
		$sql .= "'".$virtual_data_row_uuid."', ";
		$sql .= "'".$virtual_field_name."', ";
		$sql .= "'".$virtual_data_field_value."', ";
		if (strlen($virtual_table_parent_uuid) > 0) {
			$sql .= "'".$virtual_table_parent_uuid."', ";
		}
		else {
			$sql .= "null, ";
		}
		if (strlen($virtual_data_parent_row_uuid) > 0) {
			$sql .= "'".$virtual_data_parent_row_uuid."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$virtual_data_add_user."', ";
		$sql .= "'".$virtual_data_add_date."', ";
		$sql .= "'".$virtual_data_del_user."', ";
		$sql .= "'".$virtual_data_del_date."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//get the virtual table data name value pairs
	$sql = "select * from v_virtual_table_data_types_name_value ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$virtual_table_data_types_name_value_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$virtual_table_id = check_str($row["virtual_table_id"]);
		$virtual_table_field_id = check_str($row["virtual_table_field_id"]);
		$virtual_data_types_name = check_str($row["virtual_data_types_name"]);
		$virtual_data_types_value = check_str($row["virtual_data_types_value"]);

		//get the virtual_table_uuid
		$virtual_table_uuid = $virtual_table_array[$virtual_table_id]['virtual_table_uuid'];

		//get the virtual_table_field_uuid
		$virtual_table_field_uuid = $virtual_table_field_array[$virtual_table_field_id]['virtual_table_field_uuid'];
		if (strlen($virtual_table_uuid) > 0 && strlen($virtual_table_field_uuid) > 0) {
			$sql = "insert into v_virtual_table_data_types_name_value ";
			$sql .= "(";
			$sql .= "virtual_table_data_types_name_value_uuid, ";
			$sql .= "domain_uuid, ";
			$sql .= "virtual_table_uuid, ";
			$sql .= "virtual_table_field_uuid, ";
			$sql .= "virtual_data_types_name, ";
			$sql .= "virtual_data_types_value ";
			$sql .= ")";
			$sql .= "values ";
			$sql .= "(";
			$sql .= "'".$virtual_table_data_types_name_value_uuid."', ";
			$sql .= "'".$domain_uuid."', ";
			$sql .= "'".$virtual_table_uuid."', ";
			$sql .= "'".$virtual_table_field_uuid."', ";
			$sql .= "'".$virtual_data_types_name."', ";
			$sql .= "'".$virtual_data_types_value."' ";
			$sql .= ")";
			if ($export_type == "sql") { echo check_sql($sql).";\n"; }
			if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
		}
	}
	unset ($prep_statement);

//export voicemail greetings
	$sql = "select * from v_voicemail_greetings ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$greeting_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$user_id = check_str($row["user_id"]);
		$greeting_name = check_str($row["greeting_name"]);
		$greeting_description = check_str($row["greeting_description"]);

		$sql = "insert into v_voicemail_greetings ";
		$sql .= "(";
		$sql .= "greeting_uuid, ";
		$sql .= "user_id, ";
		$sql .= "domain_uuid, ";
		$sql .= "greeting_name, ";
		$sql .= "greeting_description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$greeting_uuid."', ";
		$sql .= "'".$user_id."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$greeting_name."', ";
		$sql .= "'".$greeting_description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//get the xmpp info
	$sql = "select * from v_xmpp ";
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	$result = $prep_statement->fetchAll(PDO::FETCH_NAMED);
	foreach ($result as &$row) {
		$xmpp_profile_uuid = uuid();
		$v_id = check_str($row["v_id"]);
		$domain_uuid = $domain_array[$v_id]['domain_uuid'];
		$profile_name = check_str($row["profile_name"]);
		$username = check_str($row["username"]);
		$password = check_str($row["password"]);
		$dialplan = check_str($row["dialplan"]);
		$context = check_str($row["context"]);
		$rtp_ip = check_str($row["rtp_ip"]);
		$ext_rtp_ip = check_str($row["ext_rtp_ip"]);
		$auto_login = check_str($row["auto_login"]);
		$sasl_type = check_str($row["sasl_type"]);
		$xmpp_server = check_str($row["xmpp_server"]);
		$tls_enable = check_str($row["tls_enable"]);
		$usr_rtp_timer = check_str($row["usr_rtp_timer"]);
		$default_exten = check_str($row["default_exten"]);
		$vad = check_str($row["vad"]);
		$avatar = check_str($row["avatar"]);
		$candidate_acl = check_str($row["candidate_acl"]);
		$local_network_acl = check_str($row["local_network_acl"]);
		$enabled = check_str($row["enabled"]);
		$description = check_str($row["description"]);

		$sql = "insert into v_xmpp ";
		$sql .= "(";
		$sql .= "xmpp_profile_uuid, ";
		$sql .= "domain_uuid, ";
		$sql .= "profile_name, ";
		$sql .= "username, ";
		$sql .= "password, ";
		$sql .= "dialplan, ";
		$sql .= "context, ";
		$sql .= "rtp_ip, ";
		$sql .= "ext_rtp_ip, ";
		$sql .= "auto_login, ";
		$sql .= "sasl_type, ";
		$sql .= "xmpp_server, ";
		$sql .= "tls_enable, ";
		$sql .= "usr_rtp_timer, ";
		$sql .= "default_exten, ";
		$sql .= "vad, ";
		$sql .= "avatar, ";
		$sql .= "candidate_acl, ";
		$sql .= "local_network_acl, ";
		$sql .= "enabled, ";
		$sql .= "description ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$xmpp_profile_uuid."', ";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$profile_name."', ";
		$sql .= "'".$username."', ";
		$sql .= "'".$password."', ";
		$sql .= "'".$dialplan."', ";
		$sql .= "'".$context."', ";
		$sql .= "'".$rtp_ip."', ";
		$sql .= "'".$ext_rtp_ip."', ";
		$sql .= "'".$auto_login."', ";
		$sql .= "'".$sasl_type."', ";
		$sql .= "'".$xmpp_server."', ";
		$sql .= "'".$tls_enable."', ";
		$sql .= "'".$usr_rtp_timer."', ";
		$sql .= "'".$default_exten."', ";
		$sql .= "'".$vad."', ";
		$sql .= "'".$avatar."', ";
		$sql .= "'".$candidate_acl."', ";
		$sql .= "'".$local_network_acl."', ";
		$sql .= "'".$enabled."', ";
		$sql .= "'".$description."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//get the xml cdr info
	$sql = "select * from v_xml_cdr ";
	if ($debug) {
		$sql .= "limit 3 ";
	}
	$prep_statement = $db->prepare($sql);
	$prep_statement->execute();
	while($row = $prep_statement->fetch(PDO::FETCH_ASSOC)) {
		$uuid = check_str($row["v_id"]);
		$domain_name = check_str($row["domain_name"]);
		$accountcode = check_str($row["accountcode"]);
		$uuid = check_str($row["uuid"]);
		$direction = check_str($row["direction"]);
		$default_language = check_str($row["default_language"]);
		$context = check_str($row["context"]);
		$xml_cdr = check_str($row["xml_cdr"]);
		$caller_id_name = check_str($row["caller_id_name"]);
		$caller_id_number = check_str($row["caller_id_number"]);
		$destination_number = check_str($row["destination_number"]);
		$start_epoch = check_str($row["start_epoch"]);
		$start_stamp = check_str($row["start_stamp"]);
		$answer_stamp = check_str($row["answer_stamp"]);
		$answer_epoch = check_str($row["answer_epoch"]);
		$end_epoch = check_str($row["end_epoch"]);
		$end_stamp = check_str($row["end_stamp"]);
		$duration = check_str($row["duration"]);
		$mduration = check_str($row["mduration"]);
		$billsec = check_str($row["billsec"]);
		$billmsec = check_str($row["billmsec"]);
		$bridge_uuid = check_str($row["bridge_uuid"]);
		$read_codec = check_str($row["read_codec"]);
		$read_rate = check_str($row["read_rate"]);
		$write_codec = check_str($row["write_codec"]);
		$write_rate = check_str($row["write_rate"]);
		$remote_media_ip = check_str($row["remote_media_ip"]);
		$network_addr = check_str($row["network_addr"]);
		$recording_file = check_str($row["recording_file"]);
		$leg = check_str($row["leg"]);
		$pdd_ms = check_str($row["pdd_ms"]);
		$last_app = check_str($row["last_app"]);
		$last_arg = check_str($row["last_arg"]);
		$cc_side = check_str($row["cc_side"]);
		$cc_member_uuid = check_str($row["cc_member_uuid"]);
		$cc_queue_joined_epoch = check_str($row["cc_queue_joined_epoch"]);
		$cc_queue = check_str($row["cc_queue"]);
		$cc_member_session_uuid = check_str($row["cc_member_session_uuid"]);
		$cc_agent = check_str($row["cc_agent"]);
		$cc_agent_type = check_str($row["cc_agent_type"]);
		$waitsec = check_str($row["waitsec"]);
		$conference_name = check_str($row["conference_name"]);
		$conference_uuid = check_str($row["conference_uuid"]);
		$conference_member_id = check_str($row["conference_member_id"]);
		$digits_dialed = check_str($row["digits_dialed"]);
		$hangup_cause = check_str($row["hangup_cause"]);
		$hangup_cause_q850 = check_str($row["hangup_cause_q850"]);
		$sip_hangup_disposition = check_str($row["sip_hangup_disposition"]);

		$sql = "insert into v_xml_cdr ";
		$sql .= "(";
		$sql .= "domain_uuid, ";
		$sql .= "domain_name, ";
		$sql .= "accountcode, ";
		$sql .= "uuid, ";
		$sql .= "direction, ";
		$sql .= "default_language, ";
		$sql .= "context, ";
		$sql .= "xml_cdr, ";
		$sql .= "caller_id_name, ";
		$sql .= "caller_id_number, ";
		$sql .= "destination_number, ";
		$sql .= "start_epoch, ";
		$sql .= "start_stamp, ";
		$sql .= "answer_stamp, ";
		$sql .= "answer_epoch, ";
		$sql .= "end_epoch, ";
		$sql .= "end_stamp, ";
		$sql .= "duration, ";
		$sql .= "mduration, ";
		$sql .= "billsec, ";
		$sql .= "billmsec, ";
		$sql .= "bridge_uuid, ";
		$sql .= "read_codec, ";
		$sql .= "read_rate, ";
		$sql .= "write_codec, ";
		$sql .= "write_rate, ";
		$sql .= "remote_media_ip, ";
		$sql .= "network_addr, ";
		$sql .= "recording_file, ";
		$sql .= "leg, ";
		$sql .= "pdd_ms, ";
		$sql .= "last_app, ";
		$sql .= "last_arg, ";
		$sql .= "cc_side, ";
		$sql .= "cc_member_uuid, ";
		$sql .= "cc_queue_joined_epoch, ";
		$sql .= "cc_queue, ";
		$sql .= "cc_member_session_uuid, ";
		$sql .= "cc_agent, ";
		$sql .= "cc_agent_type, ";
		$sql .= "waitsec, ";
		$sql .= "conference_name, ";
		$sql .= "conference_uuid, ";
		$sql .= "conference_member_id, ";
		$sql .= "digits_dialed, ";
		$sql .= "hangup_cause, ";
		$sql .= "hangup_cause_q850, ";
		$sql .= "sip_hangup_disposition ";
		$sql .= ")";
		$sql .= "values ";
		$sql .= "(";
		$sql .= "'".$domain_uuid."', ";
		$sql .= "'".$domain_name."', ";
		$sql .= "'".$accountcode."', ";
		$sql .= "'".$uuid."', ";
		$sql .= "'".$direction."', ";
		$sql .= "'".$default_language."', ";
		$sql .= "'".$context."', ";
		$sql .= "'".$xml_cdr."', ";
		$sql .= "'".$caller_id_name."', ";
		$sql .= "'".$caller_id_number."', ";
		$sql .= "'".$destination_number."', ";
		$sql .= "'".$start_epoch."', ";
		if (strlen($start_stamp) > 0) {
			$sql .= "'".$start_stamp."', ";
		}
		else {
			$sql .= "null, ";
		}
		if (strlen($answer_stamp) > 0) {
			$sql .= "'".$answer_stamp."', ";
		}
		else {
			$sql .= "null, ";
		}
		if (strlen($answer_epoch) > 0) {
			$sql .= "'".$answer_epoch."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$end_epoch."', ";
		$sql .= "'".$end_stamp."', ";
		if (strlen($duration) > 0) {
			$sql .= "'".$duration."', ";
		}
		else {
			$sql .= "null, ";
		}
		if (strlen($mduration) > 0) {
			$sql .= "'".$mduration."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$billsec."', ";
		$sql .= "'".$billmsec."', ";
		$sql .= "'".$bridge_uuid."', ";
		$sql .= "'".$read_codec."', ";
		$sql .= "'".$read_rate."', ";
		$sql .= "'".$write_codec."', ";
		$sql .= "'".$write_rate."', ";
		$sql .= "'".$remote_media_ip."', ";
		$sql .= "'".$network_addr."', ";
		$sql .= "'".$recording_file."', ";
		$sql .= "'".$leg."', ";
		if (strlen($cc_member_uuid) > 0) {
			$sql .= "'".$pdd_ms."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$last_app."', ";
		$sql .= "'".$last_arg."', ";
		$sql .= "'".$cc_side."', ";
		if (strlen($cc_member_uuid) > 0) {
			$sql .= "'".$cc_member_uuid."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$cc_queue_joined_epoch."', ";
		$sql .= "'".$cc_queue."', ";
		if (strlen($cc_member_session_uuid) > 0) {
			$sql .= "'".$cc_member_session_uuid."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$cc_agent."', ";
		$sql .= "'".$cc_agent_type."', ";
		if (strlen($waitsec) > 0) {
			$sql .= "'".$waitsec."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$conference_name."', ";
		if (strlen($conference_uuid) > 0) {
			$sql .= "'".$conference_uuid."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$conference_member_id."', ";
		$sql .= "'".$digits_dialed."', ";
		$sql .= "'".$hangup_cause."', ";
		if (strlen($hangup_cause_q850) > 0) {
			$sql .= "'".$hangup_cause_q850."', ";
		}
		else {
			$sql .= "null, ";
		}
		$sql .= "'".$sip_hangup_disposition."' ";
		$sql .= ")";
		if ($export_type == "sql") { echo check_sql($sql).";\n"; }
		if ($export_type == "db") { $dest_db->exec(check_sql($sql)); }
	}
	unset ($prep_statement);

//used for debugging
	if ($debug) {
		echo "</pre>\n";
	}
?>