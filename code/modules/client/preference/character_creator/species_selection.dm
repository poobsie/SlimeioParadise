/// Backend component for species selection functionality
/// Frontend sibling: tgui/packages/tgui/interfaces/CharacterCreator/species_selection.tsx

/// Generates species selection data for the UI
/datum/character_creator/proc/get_species_selection_data(mob/user)
	if(!user.client?.prefs?.active_character)
		return list()

	var/datum/character_save/character = user.client.prefs.active_character

	var/list/data = list()

	// Current species
	data["selected_species"] = character.species

	// Available species with detailed info
	var/list/available_species = list()
	for(var/species_name in get_available_species(user))
		var/datum/species/S = GLOB.all_species[species_name]
		if(S)
			available_species[species_name] = list(
				"name" = S.name,
				"description" = S.blurb,
				"flesh_color" = S.flesh_color,
				"icon" = S.icon_template || 'icons/mob/human.dmi'
			)

	data["available_species"] = available_species

	// Species preview is generated asynchronously to avoid blocking UI open.
	request_species_preview(user)
	if(species_preview_timestamp && species_preview_species == character.species)
		data["has_character_preview"] = TRUE
		data["preview_timestamp"] = species_preview_timestamp
	else
		data["has_character_preview"] = FALSE

	return data

/// Requests (async) generation of the species preview image used in the species selection tab.
/datum/character_creator/proc/request_species_preview(mob/user)
	if(QDELETED(src) || !user?.client?.prefs?.active_character)
		return FALSE
	if(!SSatoms.initialized)
		return FALSE
	var/datum/character_save/character = user.client.prefs.active_character
	var/species = character.species

	// If species changed, invalidate cached preview timestamp.
	if(species_preview_species != species)
		species_preview_species = species
		species_preview_timestamp = 0

	if(species_preview_in_progress)
		species_preview_dirty = TRUE
		return TRUE
	if(species_preview_timestamp)
		return TRUE

	species_preview_in_progress = TRUE
	species_preview_dirty = FALSE
	var/slot_num = character.slot_number

	spawn(0)
		if(QDELETED(src) || !user?.client?.prefs?.active_character)
			species_preview_in_progress = FALSE
			return
		var/datum/character_save/current_character = user.client.prefs.active_character
		if(!current_character || current_character.slot_number != slot_num)
			species_preview_in_progress = FALSE
			return

		generate_species_character_preview(user, current_character)
		species_preview_timestamp = world.time
		species_preview_species = current_character.species
		species_preview_in_progress = FALSE
		SStgui.update_uis(src)
		if(species_preview_dirty)
			species_preview_dirty = FALSE
			species_preview_timestamp = 0
			request_species_preview(user)

	return TRUE

/// Sets the character's species
/datum/character_creator/proc/set_character_species(mob/user, species_name)
	if(!user.client?.prefs?.active_character)
		return FALSE

	// Validate species is available
	if(!(species_name in get_available_species(user)))
		return FALSE

	var/datum/character_save/character = user.client.prefs.active_character
	character.species = species_name

	// Update appearance to match new species defaults
	var/datum/species/S = GLOB.all_species[species_name]
	if(S)
		// Reset hair/facial hair if the new species doesn't support them
		if(S.bodyflags & BALD)
			character.h_style = "Bald"
		if(S.bodyflags & SHAVED)
			character.f_style = "Shaved"

		// Reset skin color to species default if needed
		if(S.flesh_color && S.flesh_color != character.s_colour)
			character.s_colour = S.flesh_color

		// Reset eye color if needed - using default eyes sprite
		// Note: Eyes are handled differently - they reference sprite names, not colors

	return TRUE

/// Generates a full character preview for the species selection (at 2x size, 100% opacity)
/datum/character_creator/proc/generate_species_character_preview(mob/user, datum/character_save/character)
	if(!user?.client || !character)
		return FALSE

	// Create a temporary default character for this species preview (naked/basic)
	var/datum/character_save/preview_character = new()
	preview_character.species = character.species
	preview_character.gender = MALE // Default to male for consistency
	preview_character.body_type = MALE
	preview_character.real_name = "Preview Character"
	preview_character.age = 30

	// Set default appearance based on species
	var/datum/species/S = GLOB.all_species[character.species]
	if(S)
		preview_character.h_style = "Bald" // Default bald
		preview_character.f_style = "Shaved" // Default no facial hair
		preview_character.s_colour = S.flesh_color || "#AAAAAA" // Default species skin color
		preview_character.e_colour = "#000000" // Default black eyes

		// Set species-specific defaults
		if(character.species == "Machine")
			preview_character.h_style = "Blue IPC Screen" // Default IPC screen
			preview_character.s_colour = "#AAAAAA" // Gray IPC body
		else if(S.default_hair)
			preview_character.h_style = S.default_hair

		// Clear all clothing/accessories for naked preview
		preview_character.underwear = "Nude"
		preview_character.undershirt = "Nude"
		preview_character.socks = "Nude"
		preview_character.body_accessory = null
		preview_character.ha_style = "None"
		for(var/marking_key in preview_character.m_styles)
			preview_character.m_styles[marking_key] = "None"

	// Generate full character preview using the temporary character
	preview_character.update_preview_icon()

	var/timestamp = world.time

	// Create 2x size versions of the previews - only send front view
	if(preview_character.preview_icon_front)
		var/icon/front_preview = new(preview_character.preview_icon_front)
		// Scale up 2x but keep original color/opacity intact
		front_preview.Scale(front_preview.Width() * 2, front_preview.Height() * 2)
		user << browse_rsc(front_preview, "species_char_preview_front_[timestamp].png")

	// Clean up temporary character
	qdel(preview_character)

	return TRUE
