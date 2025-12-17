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
			// Generate species preview image if needed
			generate_species_preview(user, S, species_name)

			available_species[species_name] = list(
				"name" = S.name,
				"description" = S.blurb,
				"flesh_color" = S.flesh_color,
				"icon" = S.icon_template || 'icons/mob/human.dmi'
			)

	data["available_species"] = available_species

	return data

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

/// Generates and caches a preview image for a species
/datum/character_creator/proc/generate_species_preview(mob/user, datum/species/species, species_name)
	if(!user?.client || !species)
		return FALSE

	// Check if preview already exists and is cached
	var/cache_file = "species_preview_[species_name].png"

	// Generate species preview from their icobase using the same method as character preview
	var/icon/species_preview
	var/icobase = species.icobase

	if(!icobase)
		icobase = 'icons/mob/human_races/r_human.dmi'

	// Build a basic torso + head preview (male version)
	var/g = "m"
	species_preview = new /icon(icobase, "torso_[g]")
	species_preview.Blend(new /icon(icobase, "head_[g]"), ICON_OVERLAY)

	// Apply species-specific coloring if needed
	if(species.bodyflags & HAS_SKIN_COLOR)
		if(species.flesh_color)
			species_preview.Blend(species.flesh_color, ICON_ADD)

	// Send the generated preview to client
	if(species_preview && user.client)
		user << browse_rsc(species_preview, cache_file)

	return TRUE
