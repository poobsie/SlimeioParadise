/// Antag Tickets System Helper Procedures
/// These procedures handle the management of antag tickets which replace the "antag rep" concept
/// from the Monkestation implementation. Players start with 10 tickets and gain more when they don't
/// get selected for antag roles.

/**
 * Adjusts a client's antag tickets by the specified amount
 *
 * @param client/client - The client whose tickets to adjust
 * @param value - The amount to adjust tickets by (can be positive or negative)
 * @param reason - Optional reason for the adjustment (for logging)
 */
/proc/adjust_antag_tickets(client/client, value, reason = "unspecified")
	if(!client?.prefs)
		return FALSE

	var/old_tickets = client.prefs.antag_tickets
	client.prefs.antag_tickets += value

	// Keep tickets above 0.1 minimum
	if(client.prefs.antag_tickets < 0.1)
		client.prefs.antag_tickets = 0.1

	// Round to nearest tenth
	client.prefs.antag_tickets = round(client.prefs.antag_tickets, 0.1)

	log_antag_tickets("[client.ckey]'s antag tickets adjusted from [old_tickets] to [client.prefs.antag_tickets] ([value > 0 ? "+" : ""][value]) - Reason: [reason]")
	client.prefs.save_preferences(client)
	return TRUE

/**
 * Resets a client's antag tickets to the default value
 *
 * @param client/client - The client whose tickets to reset
 * @param reason - Optional reason for the reset (for logging)
 */
/proc/reset_antag_tickets(client/client, reason = "unspecified")
	if(!client?.prefs)
		return FALSE

	var/old_tickets = client.prefs.antag_tickets
	client.prefs.antag_tickets = DEFAULT_ANTAG_TICKETS
	client.prefs.rounds_since_antag = 0

	log_antag_tickets("[client.ckey]'s antag tickets reset from [old_tickets] to [DEFAULT_ANTAG_TICKETS] and rounds since antag reset to 0 - Reason: [reason]")
	client.prefs.save_preferences(client)
	return TRUE

/**
 * Increments a client's rounds since antag counter and awards tickets
 *
 * @param client/client - The client whose counter to increment
 * @param ticket_award - How many tickets to award (defaults to configured participation award)
 */
/proc/increment_rounds_since_antag(client/client, ticket_award = null)
	if(!client?.prefs)
		return FALSE

	// Use configured participation award if not specified
	if(ticket_award == null)
		ticket_award = GLOB.configuration.antag_tickets.participation_award

	client.prefs.rounds_since_antag++
	adjust_antag_tickets(client, ticket_award, "round participation without antag role")
	return TRUE

/**
 * Handles ticket reset when player gets an antag role
 * Resets both tickets to default value and rounds since antag counter
 *
 * @param client/client - The client who got an antag role
 */
/proc/handle_antag_selection(client/client)
	if(!client?.prefs)
		return FALSE

	var/old_tickets = client.prefs.antag_tickets
	var/old_rounds = client.prefs.rounds_since_antag

	// Reset tickets to default (configured minimum/reset value)
	client.prefs.antag_tickets = GLOB.configuration.antag_tickets.default_antag_tickets
	client.prefs.rounds_since_antag = 0

	log_antag_tickets("[client.ckey] selected for antag role: tickets reset from [old_tickets] to [client.prefs.antag_tickets], rounds since antag reset from [old_rounds] to 0")
	client.prefs.save_preferences(client)
	return TRUE

/**
 * Creates a weighted list based on antag tickets for antag selection
 *
 * @param list/candidates - List of clients or mobs to weight
 * @return list - Weighted list where each client appears multiple times based on their ticket count
 */
/proc/create_antag_ticket_weighted_list(list/candidates)
	var/list/weighted_list = list()

	for(var/candidate in candidates)
		var/client/candidate_client

		// Handle different input types
		if(istype(candidate, /client))
			candidate_client = candidate
		else if(ismob(candidate))
			var/mob/candidate_mob = candidate
			candidate_client = candidate_mob.client
		else if(istype(candidate, /datum/mind))
			var/datum/mind/candidate_mind = candidate
			candidate_client = GLOB.directory[ckey(candidate_mind.key)]
		else
			continue

		if(!candidate_client?.prefs)
			continue

		var/ticket_weight = max(1, round(candidate_client.prefs.antag_tickets))

		// Add the candidate to the weighted list multiple times based on their tickets
		for(var/i = 1 to ticket_weight)
			weighted_list += candidate

	log_antag_tickets("Created weighted antag selection list with [length(weighted_list)] total entries from [length(candidates)] candidates")
	return weighted_list/**
 * Gets the current antag ticket count for a client
 *
 * @param client/client - The client to check
 * @return num - The client's current antag ticket count, or 0 if invalid
 */
/proc/get_antag_tickets(client/client)
	if(!client?.prefs)
		return 0
	return client.prefs.antag_tickets

/**
 * Gets the rounds since antag count for a client
 *
 * @param client/client - The client to check
 * @return num - The client's rounds since antag count, or 0 if invalid
 */
/proc/get_rounds_since_antag(client/client)
	if(!client?.prefs)
		return 0
	return client.prefs.rounds_since_antag

/**
 * Awards antag tickets to all participating players at round end
 * Called from SSticker.declare_completion()
 */
/proc/award_round_participation_tickets()
	log_antag_tickets("Beginning round end antag ticket awards")
	var/awarded_count = 0

	for(var/client/C in GLOB.clients)
		if(!C?.prefs)
			continue

		// Only award to players who actually participated in the round (not observers/etc)
		if(!C.mob?.mind)
			continue

		// Don't award tickets to players who got antag roles (they already had their tickets reset)
		if(C.mob.mind.special_role)
			continue

		// Award participation tickets
		increment_rounds_since_antag(C)
		awarded_count++

	log_antag_tickets("Round end: awarded participation tickets to [awarded_count] non-antag players")
