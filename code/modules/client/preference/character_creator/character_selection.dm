/// Backend component for character selection functionality including headshots
/// Frontend sibling: tgui/packages/tgui/interfaces/CharacterCreator/character_selection.tsx

/// Gets the first name from a character's full name
/datum/character_creator/proc/get_first_name(full_name)
	if(!full_name || full_name == "")
		return "Unnamed"
	var/list/name_parts = splittext(full_name, " ")
	return name_parts[1]

/// Character selection and headshot management
/datum/character_creator
	/// Cache for character headshots to prevent flickering
	var/list/cached_headshots = list()
	var/list/headshot_timestamps = list()
	/// Current active character's headshot filename
	var/active_character_headshot = null
	/// Version tracking for double-buffering (0 or 1)
	var/headshot_version = 0

/// Generates character selection headshot data for character saves list
/datum/character_creator/proc/generate_character_headshots(mob/user)
	if(!cached_headshots)
		cached_headshots = list()
	if(!headshot_timestamps)
		headshot_timestamps = list()

	var/list/character_list = list()

	for(var/i in 1 to length(user.client.prefs.character_saves))
		var/datum/character_save/char_save = user.client.prefs.character_saves[i]
		var/list/char_info = list()
		var/slot_key = "slot_[i]"

		char_info["slot"] = i

		// Use first name if available, otherwise show appropriate fallback
		if(char_save.real_name && char_save.real_name != "")
			char_info["name"] = get_first_name(char_save.real_name)
		else
			char_info["name"] = "Slot [i]"

		char_info["species"] = char_save.species || "Human"
		char_info["is_active"] = (char_save == user.client.prefs.active_character)
		char_info["valid_save"] = char_save.valid_save

		// Use cached headshot (generated when main preview updates)
		if(char_info["is_active"] && active_character_headshot)
			// Use the current active character's headshot
			char_info["preview_headshot"] = active_character_headshot
		else
			// Use cached headshot for inactive characters
			char_info["preview_headshot"] = cached_headshots[slot_key]

		character_list += list(char_info)

	return character_list

/// Invalidates cached headshot for a specific character slot (simplified)
/datum/character_creator/proc/invalidate_character_headshot(slot_num)
	if(!cached_headshots)
		cached_headshots = list()
	if(!headshot_timestamps)
		headshot_timestamps = list()

	var/slot_key = "slot_[slot_num]"
	// Completely remove the entries from the cache
	if(slot_key in cached_headshots)
		cached_headshots.Remove(slot_key)
	if(slot_key in headshot_timestamps)
		headshot_timestamps.Remove(slot_key)

/// Creates a properly layered headshot icon without transparency issues
/datum/character_creator/proc/create_headshot_icon(datum/character_save/char_save)
	if(!char_save.preview_icon_front)
		return null

	// Create a copy of the front-facing icon
	var/icon/headshot = new(char_save.preview_icon_front)

	return headshot

/// Generates initial headshot for a character if needed
/datum/character_creator/proc/generate_initial_headshot(mob/user, datum/character_save/character)
	if(!SSatoms.initialized)
		return FALSE

	var/slot_key = "slot_[character.slot_number]"
	if(!(slot_key in cached_headshots) || !active_character_headshot)
		character.update_preview_icon()
		if(character.preview_icon_front)
			// Generate headshot immediately
			var/icon/headshot_icon = create_headshot_icon(character)
			if(headshot_icon)
				var/timestamp = world.time
				var/headshot_filename = "char_headshot_[character.slot_number]_[timestamp]_v[headshot_version].png"
				user << browse_rsc(headshot_icon, headshot_filename)
				cached_headshots[slot_key] = headshot_filename
				headshot_timestamps[slot_key] = timestamp
				active_character_headshot = headshot_filename
				return TRUE
	return FALSE

/// Updates headshot when character preview changes
/datum/character_creator/proc/update_character_headshot(mob/user, datum/character_save/character, timestamp)
	if(!SSatoms.initialized || !character.preview_icon_front)
		return FALSE

	// Alternate version number for double-buffering
	headshot_version = !headshot_version

	// Generate and cache the headshot from the front preview with version
	var/icon/headshot_icon = create_headshot_icon(character)
	if(headshot_icon)
		var/slot_num = character.slot_number
		var/headshot_filename = "char_headshot_[slot_num]_[timestamp]_v[headshot_version].png"
		user << browse_rsc(headshot_icon, headshot_filename)

		// Cache the headshot for the character list
		var/slot_key = "slot_[slot_num]"
		cached_headshots[slot_key] = headshot_filename
		headshot_timestamps[slot_key] = timestamp

		// Store as the current active character headshot
		active_character_headshot = headshot_filename
		return TRUE
	return FALSE
