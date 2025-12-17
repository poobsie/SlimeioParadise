/// Backend component for character preview functionality
/// Frontend sibling: tgui/packages/tgui/interfaces/CharacterCreator/character_preview.tsx

/// Handles character preview icon generation and management for the character creator
/datum/character_creator/proc/handle_character_preview(mob/user)
	if(!user.client?.prefs?.active_character)
		return list()

	var/datum/character_save/character = user.client.prefs.active_character

	// Generate initial headshot if needed
	if(SSatoms.initialized)
		generate_initial_headshot(user, character)

		// Update and send character preview icons
		var/timestamp = world.time
		if(character.preview_icon_front)
			user << browse_rsc(character.preview_icon_front, "char_preview_front_[timestamp].png")
		if(character.preview_icon_side)
			user << browse_rsc(character.preview_icon_side, "char_preview_side_[timestamp].png")

	return list(
		"has_preview" = SSatoms.initialized,
		"preview_timestamp" = world.time
	)

/// Refreshes character preview icons and sends updated data to client
/datum/character_creator/proc/refresh_character_preview(mob/user)
	if(!user.client?.prefs?.active_character)
		return FALSE
	if(SSatoms.initialized)
		var/datum/character_save/character = user.client.prefs.active_character
		character.update_preview_icon()
		var/timestamp = world.time

		if(character.preview_icon_front)
			user << browse_rsc(character.preview_icon_front, "char_preview_front_[timestamp].png")

			// Update headshot when preview changes
			update_character_headshot(user, character, timestamp)
		if(character.preview_icon_side)
			user << browse_rsc(character.preview_icon_side, "char_preview_side_[timestamp].png")
	return TRUE
