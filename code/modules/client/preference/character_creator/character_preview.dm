/// Backend component for character preview functionality
/// Frontend sibling: tgui/packages/tgui/interfaces/CharacterCreator/character_preview.tsx

/// Handles character preview icon generation and management for the character creator
/datum/character_creator/proc/handle_character_preview(mob/user)
	if(!user.client?.prefs?.active_character)
		return list()

	// Don't automatically request preview here - only return current state
	// Preview requests should only come from refresh_preview() or initial setup

	return list(
		"has_preview" = (character_preview_timestamp > 0),
		"preview_timestamp" = character_preview_timestamp
	)

/// Refreshes character preview icons and sends updated data to client
/datum/character_creator/proc/refresh_character_preview(mob/user)
	if(!user.client?.prefs?.active_character)
		return FALSE
	request_character_preview(user)
	return TRUE

/// Requests generation of the main character preview images without blocking UI updates.
/datum/character_creator/proc/request_character_preview(mob/user)
	if(QDELETED(src) || !user?.client?.prefs?.active_character)
		return FALSE
	if(!SSatoms.initialized)
		return FALSE

	var/datum/character_save/character = user.client.prefs.active_character
	// Invalidate cached timestamp if we switched slots
	if(last_preview_slot_number != character.slot_number)
		last_preview_slot_number = character.slot_number
		character_preview_timestamp = 0
		active_character_headshot = null

	if(character_preview_in_progress)
		character_preview_dirty = TRUE
		return TRUE

	// Already have a valid preview
	if(character_preview_timestamp > 0)
		return TRUE

	character_preview_in_progress = TRUE
	character_preview_dirty = FALSE
	var/slot_num = character.slot_number

	spawn(0)
		if(QDELETED(src) || !user?.client?.prefs?.active_character)
			character_preview_in_progress = FALSE
			return
		var/datum/character_save/current_character = user.client.prefs.active_character
		if(!current_character || current_character.slot_number != slot_num)
			character_preview_in_progress = FALSE
			return

		current_character.update_preview_icon()
		var/timestamp = world.time
		if(current_character.preview_icon_front)
			user << browse_rsc(current_character.preview_icon_front, "char_preview_front_[timestamp].png")
			update_character_headshot(user, current_character, timestamp)
		if(current_character.preview_icon_side)
			user << browse_rsc(current_character.preview_icon_side, "char_preview_side_[timestamp].png")

		character_preview_timestamp = timestamp
		character_preview_in_progress = FALSE
		SStgui.update_uis(src)
		if(character_preview_dirty)
			character_preview_dirty = FALSE
			character_preview_timestamp = 0
			request_character_preview(user)

	return TRUE
