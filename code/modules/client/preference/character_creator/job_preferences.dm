/// Job Preferences backend for character creator
/// Frontend sibling: tgui/packages/tgui/interfaces/CharacterCreator/job_preferences.tsx

/// Returns structured job preference data for the UI
/datum/character_creator/proc/get_job_preferences_data(mob/user)
	var/list/data = list()

	if(!user.client?.prefs?.active_character)
		return data

	var/datum/character_save/character = user.client.prefs.active_character

	// Assistant toggle
	data["assistant_enabled"] = (character.job_support_low & JOB_ASSISTANT) ? TRUE : FALSE

	// Cycle behavior when preferred jobs unavailable
	data["alternate_option"] = character.alternate_option

	// Build departments structure with organized jobs
	var/list/departments = list()

	// Column 1: Assistant, Engineering, Medical, Science
	departments += build_job_department("Assistant", "#d6d6d6", "#a8a8a8", list(SSjobs.GetJob("Assistant")))
	departments += build_job_department("Engineering", "#fff5cc", "#ffa500", GLOB.engineering_positions, JOB_ENGSEC)
	departments += build_job_department("Medical", "#fef9e7", "#009b4c", GLOB.medical_positions, JOB_MEDSCI)
	departments += build_job_department("Science", "#ffeeff", "#c973ff", GLOB.science_positions, JOB_MEDSCI)

	// Column 2: Security, Synthetics, Command
	departments += build_job_department("Security", "#ffd4d4", "#e74c3c", GLOB.active_security_positions, JOB_ENGSEC)
	departments += build_job_department("Synthetics", "#ccffcc", "#2ecc71", GLOB.nonhuman_positions, JOB_SUPPORT)
	departments += build_job_department("Command", "#d4e6ff", "#3498db", GLOB.command_positions, JOB_ENGSEC)

	// Column 3: Supply, Service
	departments += build_job_department("Supply", "#f4e7d7", "#cd853f", GLOB.supply_positions, JOB_SUPPORT)
	departments += build_job_department("Service", "#e8d4f1", "#9b59b6", GLOB.service_positions, JOB_SUPPORT)

	data["departments"] = departments

	return data

/// Builds a department structure with all jobs and their current preferences
/datum/character_creator/proc/build_job_department(dept_name, color, accent_color, list/job_titles, category_flag = JOB_SUPPORT)
	var/list/dept = list()
	var/datum/character_save/character = usr?.client?.prefs?.active_character
	if(!character)
		return null

	dept["name"] = dept_name
	dept["color"] = color
	dept["accent_color"] = accent_color
	dept["column"] = get_department_column(dept_name)

	var/list/jobs = list()
	for(var/job_title in job_titles)
		var/datum/job/J
		if(istype(job_title, /datum/job))
			J = job_title
		else
			J = SSjobs.GetJob(job_title)

		if(!J || J.hidden_from_job_prefs)
			continue

		var/list/job_data = list()
		job_data["title"] = J.title
		job_data["flag"] = J.flag
		job_data["selection_color"] = J.selection_color

		// Alternate titles
		if(length(J.alt_titles))
			job_data["alt_titles"] = J.alt_titles
			// Get selected alt title if any
			if(character.player_alt_titles && character.player_alt_titles[J.title])
				job_data["selected_alt_title"] = character.player_alt_titles[J.title]

		// Get current priority level for this job
		job_data["current_priority"] = get_job_priority(J, character, category_flag)

		// Check if job is unavailable for this character
		var/unavailable_reason = get_job_unavailable_reason(J, usr?.client)
		if(unavailable_reason)
			job_data["unavailable"] = TRUE
			job_data["unavailable_reason"] = unavailable_reason

		jobs += list(job_data)

	dept["jobs"] = jobs
	return dept

/// Determines which UI column a department belongs to
/datum/character_creator/proc/get_department_column(dept_name)
	switch(dept_name)
		if("Assistant", "Engineering", "Medical", "Science")
			return 1
		if("Security", "Synthetics", "Command")
			return 2
		if("Supply", "Service")
			return 3
	return 1

/// Gets the current priority level (0-3) for a job
/datum/character_creator/proc/get_job_priority(datum/job/J, datum/character_save/character, category_flag)
	if(!J || !character)
		return 0

	var/job_flag = J.flag

	// Determine which category this job belongs to
	var/high_var
	var/med_var
	var/low_var

	if(category_flag == JOB_SUPPORT)
		high_var = character.job_support_high
		med_var = character.job_support_med
		low_var = character.job_support_low
	else if(category_flag == JOB_MEDSCI)
		high_var = character.job_medsci_high
		med_var = character.job_medsci_med
		low_var = character.job_medsci_low
	else if(category_flag == JOB_ENGSEC)
		high_var = character.job_engsec_high
		med_var = character.job_engsec_med
		low_var = character.job_engsec_low
	else
		return 0

	if(high_var & job_flag)
		return 3 // High
	else if(med_var & job_flag)
		return 2 // Medium
	else if(low_var & job_flag)
		return 1 // Low
	else
		return 0 // Never

/// Checks if a job is unavailable and returns the reason
/datum/character_creator/proc/get_job_unavailable_reason(datum/job/J, client/C)
	if(!J || !C)
		return null

	// Check age requirement
	var/days_until_available = J.available_in_days(C)
	if(days_until_available > 0)
		return "Requires [days_until_available] more day\s"

	// Check job ban
	if(jobban_isbanned(C, J.title))
		return "Jobbanned"

	// Check disability restrictions
	if(J.barred_by_disability(C))
		return "Disability"

	// Check quirk restrictions
	if(J.barred_by_quirk(C))
		return "Quirk"

	// Check missing limbs
	if(J.barred_by_missing_limbs(C))
		return "Missing limbs"

	// Check gamemode ban
	if(J.job_banned_gamemode)
		return "Gamemode restriction"

	return null

/// Sets a job's priority level
/datum/character_creator/proc/set_job_priority(mob/user, job_title, new_priority)
	if(!user?.client?.prefs?.active_character)
		return FALSE

	var/datum/character_save/character = user.client.prefs.active_character
	var/datum/job/J = SSjobs.GetJob(job_title)

	if(!J)
		return FALSE

	// Prevent setting priority if assistant is enabled (except for assistant itself)
	if((character.job_support_low & JOB_ASSISTANT) && J.title != "Assistant")
		return FALSE

	// Get category flag
	var/category_flag = get_job_category_flag(J)

	// Get the appropriate vars for this category
	var/high_var
	var/med_var
	var/low_var

	if(category_flag == JOB_SUPPORT)
		high_var = character.job_support_high
		med_var = character.job_support_med
		low_var = character.job_support_low
	else if(category_flag == JOB_MEDSCI)
		high_var = character.job_medsci_high
		med_var = character.job_medsci_med
		low_var = character.job_medsci_low
	else if(category_flag == JOB_ENGSEC)
		high_var = character.job_engsec_high
		med_var = character.job_engsec_med
		low_var = character.job_engsec_low
	else
		return FALSE

	// Clear this job from all priority levels in its category
	high_var &= ~J.flag
	med_var &= ~J.flag
	low_var &= ~J.flag

	// If setting to High (3), clear any existing High job in ALL categories
	if(new_priority == 3)
		var/current_high_job = get_high_priority_job(character)
		if(current_high_job)
			demote_high_job_to_medium(character, current_high_job)

	// Set the new priority
	switch(new_priority)
		if(3) // High
			high_var |= J.flag
		if(2) // Medium
			med_var |= J.flag
		if(1) // Low
			low_var |= J.flag
		// if(0) // Never - already cleared above

	// Write back to character
	if(category_flag == JOB_SUPPORT)
		character.job_support_high = high_var
		character.job_support_med = med_var
		character.job_support_low = low_var
	else if(category_flag == JOB_MEDSCI)
		character.job_medsci_high = high_var
		character.job_medsci_med = med_var
		character.job_medsci_low = low_var
	else if(category_flag == JOB_ENGSEC)
		character.job_engsec_high = high_var
		character.job_engsec_med = med_var
		character.job_engsec_low = low_var

	// Trigger preview update if High was set (for job outfit preview)
	if(new_priority == 3)
		request_character_preview(user)

	return TRUE

/// Gets the category flag for a job based on its department flag
/datum/character_creator/proc/get_job_category_flag(datum/job/J)
	if(!J)
		return JOB_SUPPORT

	// Command jobs go in ENGSEC
	if(J.department_flag & JOBCAT_COMMAND)
		return JOB_ENGSEC

	// Engineering/Security category
	if(J.department_flag & JOBCAT_ENGSEC)
		return JOB_ENGSEC

	// Medical/Science category
	if(J.department_flag & JOBCAT_MEDSCI)
		return JOB_MEDSCI

	// Support category (supply/service/assistant/synthetics)
	if(J.department_flag & JOBCAT_SUPPORT)
		return JOB_SUPPORT

	// Special handling for nonhuman positions
	if(J.title in GLOB.nonhuman_positions)
		return JOB_SUPPORT

	// Default to support
	return JOB_SUPPORT

/// Finds the currently high-priority job across all categories
/datum/character_creator/proc/get_high_priority_job(datum/character_save/character)
	if(!character)
		return null

	// Check all three categories for a high priority job
	var/list/all_jobs = SSjobs.occupations

	for(var/datum/job/J in all_jobs)
		if(!J)
			continue

		var/category_flag = get_job_category_flag(J)
		var/high_var

		if(category_flag == JOB_SUPPORT)
			high_var = character.job_support_high
		else if(category_flag == JOB_MEDSCI)
			high_var = character.job_medsci_high
		else if(category_flag == JOB_ENGSEC)
			high_var = character.job_engsec_high
		else
			continue

		if(high_var & J.flag)
			return J

	return null

/// Demotes a high-priority job to medium priority
/datum/character_creator/proc/demote_high_job_to_medium(datum/character_save/character, datum/job/J)
	if(!character || !J)
		return FALSE

	var/category_flag = get_job_category_flag(J)

	if(category_flag == JOB_SUPPORT)
		character.job_support_high &= ~J.flag
		character.job_support_med |= J.flag
	else if(category_flag == JOB_MEDSCI)
		character.job_medsci_high &= ~J.flag
		character.job_medsci_med |= J.flag
	else if(category_flag == JOB_ENGSEC)
		character.job_engsec_high &= ~J.flag
		character.job_engsec_med |= J.flag

	return TRUE

/// Handles ui_act for job preferences
/datum/character_creator/proc/handle_job_preferences_action(action, params, mob/user)
	var/datum/character_save/character = user?.client?.prefs?.active_character
	if(!character)
		return FALSE

	switch(action)
		if("set_job_priority")
			var/job_title = params["job_title"]
			var/priority = params["priority"]

			if(!istext(job_title) || !isnum(priority))
				return FALSE

			return set_job_priority(user, job_title, priority)

		if("set_alt_title")
			var/job_title = params["job_title"]
			var/alt_title = params["alt_title"]

			if(!istext(job_title) || !istext(alt_title))
				return FALSE

			var/datum/job/J = SSjobs.GetJob(job_title)
			if(!J)
				return FALSE

			// Validate that this is a valid alt title
			if(alt_title == J.title || (length(J.alt_titles) && (alt_title in J.alt_titles)))
				if(!character.player_alt_titles)
					character.player_alt_titles = list()

				if(alt_title == J.title)
					// Remove alt title entry if selecting the base title
					character.player_alt_titles -= J.title
				else
					character.player_alt_titles[J.title] = alt_title

				return TRUE

			return FALSE

		if("toggle_assistant")
			var/enabled = params["enabled"]
			if(!isnum(enabled))
				return FALSE

			if(enabled)
				// Enable assistant-only mode
				character.job_support_low |= JOB_ASSISTANT
			else
				// Disable assistant-only mode
				character.job_support_low &= ~JOB_ASSISTANT

			return TRUE

		if("set_alternate_option")
			var/option = params["option"]
			if(!isnum(option))
				return FALSE

			character.alternate_option = clamp(option, 0, 2)
			return TRUE

	return FALSE
