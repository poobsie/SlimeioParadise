/// Config holder for antag tickets system
/datum/configuration_section/antag_tickets_configuration
	/// Enable the antag tickets system
	var/enable_antag_tickets = TRUE
	/// Default number of antag tickets new players start with (also serves as reset value)
	var/default_antag_tickets = DEFAULT_ANTAG_TICKETS
	/// Bitflags controlling what information is shown to players pre-round
	var/display_config = ANTAG_TICKETS_DEFAULT_CONFIG
	/// How many tickets are awarded per round of participation without antag role
	var/participation_award = 0.5

/datum/configuration_section/antag_tickets_configuration/load_data(list/data)
	CONFIG_LOAD_BOOL(enable_antag_tickets, data["enable_antag_tickets"])
	CONFIG_LOAD_NUM(default_antag_tickets, data["default_antag_tickets"])
	CONFIG_LOAD_NUM(participation_award, data["participation_award"])

	// Load display configuration flags
	if("display_config" in data)
		var/list/display_settings = data["display_config"]
		display_config = 0

		if("show_readied_players" in display_settings && display_settings["show_readied_players"])
			display_config |= ANTAG_TICKETS_SHOW_READIED_PLAYERS

		if("show_rounds_since_antag" in display_settings && display_settings["show_rounds_since_antag"])
			display_config |= ANTAG_TICKETS_SHOW_ROUNDS_SINCE_ANTAG

		if("show_ticket_count" in display_settings && display_settings["show_ticket_count"])
			display_config |= ANTAG_TICKETS_SHOW_TICKET_COUNT

		if("show_precise_odds" in display_settings && display_settings["show_precise_odds"])
			display_config |= ANTAG_TICKETS_SHOW_PRECISE_ODDS
