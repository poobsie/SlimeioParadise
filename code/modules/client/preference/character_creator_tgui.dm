/// Main backend TGUI interface for character creator
/// Frontend sibling: tgui/packages/tgui/interfaces/CharacterCreator.tsx

/datum/character_creator
	var/list/cached_hair_styles
	var/cached_hair_species
	var/list/cached_facial_hair_styles
	var/cached_facial_hair_species
	var/list/served_resources

/datum/character_creator/ui_state(mob/user)
	return GLOB.always_state

/datum/character_creator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CharacterCreator", "Character Creator")
		ui.open()

/datum/character_creator/ui_data(mob/user)
	var/list/data = list()

	if(!user.client?.prefs?.active_character)
		return data

	var/datum/character_save/character = user.client.prefs.active_character

	// Handle character preview icons
	var/list/preview_data = handle_character_preview(user)

	// Character selection data with headshots
	data["character_saves"] = generate_character_headshots(user)
	data["active_slot"] = character.slot_number

	// Basic character information data
	data["basic_information"] = get_basic_information_data(user)
	data["species_selection"] = get_species_selection_data(user)

	// Basic character info (legacy - remove when fully migrated)
	data["real_name"] = character.real_name
	data["age"] = character.age
	data["species"] = character.species
	data["gender"] = character.gender == MALE ? "Male" : (character.gender == FEMALE ? "Female" : "Genderless")
	data["available_genders"] = list("Male", "Female", "Genderless")
	data["body_type"] = character.body_type == MALE ? "masculine" : "feminine"
	data["flavor_text"] = character.flavor_text
	data["physique"] = character.physique
	data["height"] = character.height
	data["runechat_color"] = character.runechat_color

	// Character records
	data["med_record"] = character.med_record
	data["sec_record"] = character.sec_record
	data["gen_record"] = character.gen_record

	// Background settings
	data["language"] = character.language
	data["b_type"] = character.b_type
	data["disabilities"] = character.disabilities
	data["nanotrasen_relation"] = character.nanotrasen_relation
	data["cyborg_brain_type"] = character.cyborg_brain_type

	// Preview data from character preview component
	data["has_preview"] = preview_data["has_preview"]
	data["preview_timestamp"] = preview_data["preview_timestamp"]

	// Appearance
	data["h_style"] = character.h_style
	data["h_colour"] = character.h_colour
	data["h_sec_colour"] = character.h_sec_colour
	data["h_gradient_style"] = character.h_grad_style
	data["h_gradient_colour"] = character.h_grad_colour
	data["f_style"] = character.f_style
	data["f_colour"] = character.f_colour
	data["f_sec_colour"] = character.f_sec_colour
	data["e_colour"] = character.e_colour
	data["s_colour"] = character.s_colour
	data["s_tone"] = character.s_tone

	// Clothing selections
	data["underwear"] = character.underwear
	data["undershirt"] = character.undershirt
	data["socks"] = character.socks
	data["backbag"] = character.backbag

	// Prosthetic selections - get current state for each part
	var/list/prosthetic_states = list()
	var/list/body_parts = list("head", "l_arm", "r_arm", "l_hand", "r_hand", "l_leg", "r_leg", "l_foot", "r_foot", "chest", "groin")
	var/datum/species/S = GLOB.all_species[character.species]
	var/is_machine = (S.bodyflags & ALL_RPARTS)

	for(var/part_name in body_parts)
		var/current_state = "none"
		if(character.organ_data[part_name] == "amputated")
			current_state = "amputated"
		else if(character.organ_data[part_name] == "cyborg" && character.rlimb_data[part_name])
			current_state = character.rlimb_data[part_name]
		else if(is_machine)
			// Machines default to Morpheus Cyberkinetics, not none
			current_state = "Morpheus Cyberkinetics"
		prosthetic_states[part_name] = current_state
	data["prosthetic_states"] = prosthetic_states
	data["is_machine_species"] = is_machine

	// Species capabilities for tab visibility
	data["species_has_hair"] = !(S.bodyflags & BALD)
	data["species_has_facial_hair"] = !(S.bodyflags & SHAVED)
	data["species_has_wings"] = (S.bodyflags & HAS_WING)
	data["species_has_head_accessory"] = (S.bodyflags & HAS_HEAD_ACCESSORY)
	data["species_has_head_markings"] = (S.bodyflags & HAS_HEAD_MARKINGS)
	data["species_has_body_markings"] = (S.bodyflags & HAS_BODY_MARKINGS)
	data["species_has_body_accessory"] = (S.bodyflags & HAS_BODY_ACCESSORY)

	// Available options
	data["available_species"] = get_available_species(user)

	// Use cached hair styles if species hasn't changed
	if(cached_hair_styles && cached_hair_species == character.species)
		data["available_hair_styles"] = cached_hair_styles
	else
		data["available_hair_styles"] = get_available_hair_styles_with_icons(character)
		cached_hair_styles = data["available_hair_styles"]
		cached_hair_species = character.species

	// Use cached facial hair styles if species hasn't changed
	if(cached_facial_hair_styles && cached_facial_hair_species == character.species)
		data["available_facial_hair_styles"] = cached_facial_hair_styles
	else
		data["available_facial_hair_styles"] = get_available_facial_hair_styles_with_icons(character)
		cached_facial_hair_styles = data["available_facial_hair_styles"]
		cached_facial_hair_species = character.species
	data["available_hair_gradients"] = get_available_hair_gradients()

	// Clothing options
	data["available_underwear"] = get_available_underwear_with_icons(character)
	data["available_undershirt"] = get_available_undershirt_with_icons(character)
	data["available_socks"] = get_available_socks_with_icons(character)
	data["available_backpack_types"] = get_available_backpack_types(character)

	// Prosthetics options
	data["available_prosthetics"] = get_available_prosthetics_with_icons(character)

	// Wing options for species that have wings
	if(S.bodyflags & HAS_WING)
		data["available_wings"] = get_available_wing_styles_with_icons(character)
		data["wing_style"] = character.body_accessory ? character.body_accessory : "None"

	// Head accessories
	if(S.bodyflags & HAS_HEAD_ACCESSORY)
		data["available_head_accessories"] = get_available_head_accessory_styles_with_icons(character)
		data["head_accessory_style"] = character.ha_style ? character.ha_style : "None"
		data["head_accessory_colour"] = character.hacc_colour

	// Head markings
	if(S.bodyflags & HAS_HEAD_MARKINGS)
		data["available_head_markings"] = get_available_head_marking_styles_with_icons(character)
		data["head_marking_style"] = character.m_styles["head"] ? character.m_styles["head"] : "None"
		data["head_marking_colour"] = character.m_colours["head"]

	// Body markings
	if(S.bodyflags & HAS_BODY_MARKINGS)
		data["available_body_markings"] = get_available_body_marking_styles_with_icons(character)
		data["body_marking_style"] = character.m_styles["body"] ? character.m_styles["body"] : "None"
		data["body_marking_colour"] = character.m_colours["body"]

	// Body accessories
	if(S.bodyflags & HAS_BODY_ACCESSORY)
		data["available_body_accessories"] = get_available_body_accessory_styles_with_icons(character)
		data["body_accessory_style"] = character.body_accessory ? character.body_accessory : "None"

	// Quirks
	var/list/selected_quirks = list()
	for(var/datum/quirk/quirk in character.quirks)
		selected_quirks += quirk.name
	data["selected_quirks"] = selected_quirks
	data["quirk_balance"] = character.rebuild_quirks()

	// Loadout
	data["gear_slots"] = user?.client?.prefs.build_loadout()
	data["selected_gears"] = character.loadout_gear
	data["max_gear_slots"] = user?.client?.prefs?.max_gear_slots
	data["user_tier"] = user?.client?.donator_level

	/*
	// Antag preferences
	var/list/antag_prefs = list()
	antag_prefs["changeling"] = ROLE_CHANGELING in user?.client?.prefs?.be_special ? TRUE : FALSE
	antag_prefs["cultist"] = ROLE_CULTIST in user?.client?.prefs?.be_special ? TRUE : FALSE
	antag_prefs["revolutionary"] = ROLE_REV in user?.client?.prefs?.be_special ? TRUE : FALSE
	antag_prefs["traitor"] = ROLE_TRAITOR in user?.client?.prefs?.be_special ? TRUE : FALSE
	antag_prefs["vampire"] = ROLE_VAMPIRE in user?.client?.prefs?.be_special ? TRUE : FALSE
	antag_prefs["wizard"] = ROLE_WIZARD in user?.client?.prefs?.be_special ? TRUE : FALSE
	antag_prefs["mindflayer"] = ROLE_MIND_FLAYER in user?.client?.prefs?.be_special ? TRUE : FALSE
	data["antag_preferences"] = antag_prefs
	*/

	return data

/datum/character_creator/ui_static_data(mob/user)
	var/list/data = list()
	data["all_quirks"] = GLOB.quirk_tgui_info
	data["gears"] = GLOB.gear_tgui_info
	data["available_physiques"] = GLOB.character_physiques
	data["available_heights"] = GLOB.character_heights

	// Languages
	var/list/available_languages = list()
	for(var/lang_name in GLOB.all_languages)
		var/datum/language/lang = GLOB.all_languages[lang_name]
		if(!(lang.flags & RESTRICTED))
			available_languages += lang.name
	data["available_languages"] = available_languages

	// Blood types
	data["available_blood_types"] = list("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-")

	// Disabilities for current species
	if(user.client?.prefs?.active_character)
		var/datum/character_save/character = user.client.prefs.active_character
		var/datum/species/S = GLOB.all_species[character.species]
		var/list/disability_list = list()
		var/list/accent_list = list()
		// Non-quirk disabilities
		disability_list["dizzy"] = list("name" = "Dizziness", "flag" = DISABILITY_FLAG_DIZZY)
		disability_list["paraplegic"] = list("name" = "Paraplegia", "flag" = DISABILITY_FLAG_PARAPLEGIC)
		if(!(TRAIT_NOFAT in S.inherent_traits))
			disability_list["fat"] = list("name" = "Obese", "flag" = DISABILITY_FLAG_FAT)
		if(CAN_WINGDINGS in S.species_traits)
			disability_list["wingdings"] = list("name" = "Speak in Wingdings", "flag" = DISABILITY_FLAG_WINGDINGS)
		// Add accent "disabilities" as a separate category
		accent_list["nervous"] = list("name" = "Stutter", "flag" = DISABILITY_FLAG_NERVOUS)
		accent_list["swedish"] = list("name" = "Swedish accent", "flag" = DISABILITY_FLAG_SWEDISH)
		accent_list["chav"] = list("name" = "Chav accent", "flag" = DISABILITY_FLAG_CHAV)
		accent_list["lisp"] = list("name" = "Lisp", "flag" = DISABILITY_FLAG_LISP)
		data["available_disabilities"] = disability_list
		data["available_accents"] = accent_list
	else
		data["available_disabilities"] = list()
		data["available_accents"] = list()

	// Nanotrasen relations
	data["available_nanotrasen_relations"] = list("Loyal", "Supportive", "Neutral", "Skeptical", "Opposed")

	// Cyborg brain types
	var/list/available_brain_types
	if(GLOB.borg_brain_choices)
		for(var/brain_type in GLOB.borg_brain_choices)
			available_brain_types |= brain_type
	data["available_cyborg_brain_types"] = available_brain_types

	// Species information with descriptions
	var/list/species_info = list()
	for(var/species_name in get_available_species(user))
		var/datum/species/S = GLOB.all_species[species_name]
		species_info[species_name] = list(
			"name" = S.name,
			"description" = S.blurb || "No description available.",
		)
	data["species_info"] = species_info

	/*
	// Antag information with icons
	var/list/antag_info = list()
	antag_info += list(list(
		"name" = "Traitor",
		"key" = "traitor",
		"description" = "A Syndicate agent sent to complete objectives. Gets an Uplink which allows them to purchase gear and weapons for their mission.",
		"icon" = "data:image/png;base64,[icon2base64(icon('icons/obj/card.dmi', "emag", SOUTH, 1))]"
	))
	antag_info += list(list(
		"name" = "Vampire",
		"key" = "vampire",
		"description" = "A bloodsucker with supernatural powers. Feeds on the blood of the crew to grow in strength and gain new abilities.",
		"icon" = "data:image/png;base64,[icon2base64(icon('icons/obj/closet.dmi', "coffin", SOUTH, 1))]"
	))
	antag_info += list(list(
		"name" = "Mindflayer",
		"key" = "mindflayer",
		"description" = "An IPC host to a nanite swarm. Drains the mental energy of the crew to grow in strength and gain new abilities.",
		"icon" = "data:image/png;base64,[icon2base64(icon('icons/obj/weapons/baton.dmi', "swarmprod", SOUTH, 1))]"
	))
	antag_info += list(list(
		"name" = "Changeling",
		"key" = "changeling",
		"description" = "A powerful, parasitic alien that has replaced your character. Can shapeshift to mimic other crew members.",
		"icon" = "data:image/png;base64,[icon2base64(icon('icons/obj/weapons/melee.dmi', "arm_blade", SOUTH, 1))]"
	))
	antag_info += list(list(
		"name" = "Cultist",
		"key" = "cultist",
		"description" = "A founding member of a blood cult onstation seeking to summon their god. Works with other cultists to perform rituals and convert the crew.",
		"icon" = "data:image/png;base64,[icon2base64(icon('icons/obj/cult.dmi', "blood_dagger", SOUTH, 1))]"
	))
	antag_info += list(list(
		"name" = "Wizard",
		"key" = "wizard",
		"description" = "A devastatingly powerful spellcaster. Their goal is to cause as much chaos onstation as possible. Hunted by the entire crew.",
		"icon" = "data:image/png;base64,[icon2base64(icon('icons/obj/clothing/hats.dmi', "wizard", SOUTH, 1))]"
	))
	antag_info += list(list(
		"name" = "Revolutionary",
		"key" = "revolutionary",
		"description" = "A crew member seeking to overthrow station command. Converts other crew to the revolutionary cause through ideology or force. This antag can only roll with admin intervention.",
		"icon" = "data:image/png;base64,[icon2base64(icon('icons/obj/device.dmi', "flash", SOUTH, 1))]"
	))
	data["available_antags"] = antag_info
	*/

	return data

/datum/character_creator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	var/mob/user = ui.user
	if(!user.client?.prefs?.active_character)
		return FALSE

	var/datum/character_save/character = user.client.prefs.active_character

	// There are lots of things we can do in the character creator. This switch divvies them out.
	// Todo - who belongs to helper functions?
	switch(action)
		// Switch to a different character save slot
		if("switch_character")
			var/slot_num = text2num(params["slot"])
			if(slot_num && slot_num >= 1 && slot_num <= length(user.client.prefs.character_saves))
				user.client.prefs.active_character = user.client.prefs.character_saves[slot_num]
				user.client.prefs.default_slot = slot_num

				// Update active character headshot from cache
				var/slot_key = "slot_[slot_num]"
				active_character_headshot = cached_headshots[slot_key]

				// Refresh the entire UI with the new character's data
				return TRUE

		// Set a new name - sanitize input
		if("set_name")
			if(set_character_name(user, params["name"]))
				return refresh_preview(user)
			return TRUE

		// Set name to a random name
		if("random_name")
			if(set_random_character_name(user))
				return refresh_preview(user)
			return TRUE

		// Set the character's age
		if("set_age")
			if(set_character_age(user, params["age"]))
				return refresh_preview(user)
			return TRUE

		// Set character's species
		// A lot of things change when we update species - a lot of options become invalid or no longer shown.
		// This will need to be expanded most likely
		if("set_species")
			var/new_species = params["species"]
			if(new_species in get_available_species(user))
				var/old_species = character.species
				character.species = new_species
				// Flush cached sprites
				cached_hair_styles = null
				cached_facial_hair_species = null
				var/datum/species/S = GLOB.all_species[character.species]
				var/datum/species/old_S = GLOB.all_species[old_species]

				var/was_machine = (old_S?.bodyflags & ALL_RPARTS)
				var/is_machine = (S.bodyflags & ALL_RPARTS)

				// Reset all prosthetics to None when switching off machine
				if(was_machine && !is_machine)
					var/list/all_parts = list("head", "chest", "l_arm", "r_arm", "l_hand", "r_hand", "l_leg", "r_leg", "l_foot", "r_foot")
					for(var/part_name in all_parts)
						character.organ_data -= part_name
						character.rlimb_data -= part_name
				// Machines have all Morpheus Cyberkinetics parts by default
				else if(!was_machine && is_machine)
					var/list/machine_parts = list("head", "chest", "l_arm", "r_arm", "l_hand", "r_hand", "l_leg", "r_leg", "l_foot", "r_foot")
					for(var/part_name in machine_parts)
						character.organ_data[part_name] = "cyborg"
						character.rlimb_data[part_name] = "Morpheus Cyberkinetics"

				character.age = clamp(character.age, S.min_age, S.max_age)
				// Reset hair style if invalid for new species
				var/list/valid_hair_styles = get_available_hair_styles(character)
				if(!(character.h_style in valid_hair_styles))
					character.h_style = valid_hair_styles[1]
				// Reset facial hair style if invalid for new species
				var/list/valid_facial_hair_styles = get_available_facial_hair_styles(character)
				if(!(character.f_style in valid_facial_hair_styles))
					character.f_style = valid_facial_hair_styles[1]

				// Clear wings if new species doesn't have wings
				if(!(S.bodyflags & HAS_WING))
					character.body_accessory = null
				else if(character.species == "Nian" && (!character.body_accessory || character.body_accessory == "None"))
					// Set default wings for Nian if they don't have any
					character.body_accessory = "Plain Wings"
				else if(old_species == "Nian" && character.species != "Nian")
					// Clear wings when changing away from Nian
					character.body_accessory = null

				// Clear head accessories if new species doesn't have them
				if(!(S.bodyflags & HAS_HEAD_ACCESSORY))
					character.ha_style = "None"

				// Clear head markings if new species doesn't have them
				if(!(S.bodyflags & HAS_HEAD_MARKINGS))
					character.m_styles["head"] = "None"

				// Clear body markings if new species doesn't have them
				if(!(S.bodyflags & HAS_BODY_MARKINGS))
					character.m_styles["body"] = "None"
			return refresh_preview(user)

		// Character gender - Male, Female, Genderless, Object
		if("set_gender")
			if(set_character_gender(user, params["gender"]))
				return refresh_preview(user)
			return TRUE

		// Body type Masculine or Feminine
		if("set_body_type")
			var/new_body_type = params["body_type"]
			if(new_body_type in list("masculine", "feminine"))
				character.body_type = new_body_type == "masculine" ? MALE : FEMALE
			return refresh_preview(user)

		// Set character physique
		if("set_physique")
			var/new_physique = params["physique"]
			if(new_physique in GLOB.character_physiques)
				character.physique = new_physique
			return refresh_preview(user)

		// Set character height
		if("set_height")
			var/new_height = params["height"]
			if(new_height in GLOB.character_heights)
				character.height = new_height
			return refresh_preview(user)

		// Set runechat color
		if("set_runechat_color")
			var/new_color = tgui_input_color(user, "Choose runechat color", "Runechat Color", character.runechat_color)
			if(new_color)
				character.runechat_color = new_color
			return TRUE

		// Set character flavor text
		if("set_flavor_text")
			character.flavor_text = params["flavor_text"]
			return TRUE

		// Set character flavor text with dialog
		if("set_flavor_text_dialog")
			var/new_flavor = tgui_input_text(user, "Set your character description here.", "Character Description", character.flavor_text, max_length = MAX_PAPER_MESSAGE_LEN, multiline = TRUE)
			if(!isnull(new_flavor))
				character.flavor_text = new_flavor
			return TRUE

		// Clear text actions
		if("clear_flavor_text")
			character.flavor_text = ""
			return TRUE
		if("clear_medical_record")
			character.med_record = ""
			return TRUE
		if("clear_security_record")
			character.sec_record = ""
			return TRUE
		if("clear_employment_record")
			character.gen_record = ""
			return TRUE

		// Character records
		if("set_medical_record")
			var/new_record = tgui_input_text(user, "Set your medical notes here.", "Medical Records", character.med_record, max_length = MAX_PAPER_MESSAGE_LEN, multiline = TRUE)
			if(!isnull(new_record))
				character.med_record = new_record
			return TRUE
		if("set_security_record")
			var/new_record = tgui_input_text(user, "Set your security notes here.", "Security Records", character.sec_record, max_length = MAX_PAPER_MESSAGE_LEN, multiline = TRUE)
			if(!isnull(new_record))
				character.sec_record = new_record
			return TRUE
		if("set_employment_record")
			var/new_record = tgui_input_text(user, "Set your employment notes here.", "Employment Records", character.gen_record, max_length = MAX_PAPER_MESSAGE_LEN, multiline = TRUE)
			if(!isnull(new_record))
				character.gen_record = new_record
			return TRUE

		// Background settings
		if("set_language")
			var/new_language = params["language"]
			character.language = new_language
			return TRUE
		if("set_blood_type")
			var/new_blood_type = params["blood_type"]
			character.b_type = new_blood_type
			return TRUE
		if("set_nanotrasen_relation")
			var/new_relation = params["relation"]
			character.nanotrasen_relation = new_relation
			return TRUE
		if("set_cyborg_brain_type")
			var/new_brain_type = params["brain_type"]
			character.cyborg_brain_type = new_brain_type
			return TRUE
		if("toggle_disability")
			var/disability_flag = text2num(params["disability"])
			if(disability_flag)
				character.disabilities ^= disability_flag
			return TRUE

		// Set character hair style
		if("set_hair_style")
			var/new_style = params["style"]
			character.h_style = new_style
			return refresh_preview(user)

		// Set character facial hair style
		if("set_facial_hair_style")
			var/new_style = params["style"]
			character.f_style = new_style
			return refresh_preview(user)

		// Set character hair color
		if("set_hair_color")
			var/new_color = tgui_input_color(user, "Choose hair color", "Hair Color", character.h_colour)
			if(new_color)
				character.h_colour = new_color
			return refresh_preview(user)

		// Set character secondary hair color (is this used anywhere?)
		if("set_secondary_hair_color")
			var/new_color = tgui_input_color(user, "Choose secondary hair color", "Secondary Hair Color", character.h_sec_colour)
			if(new_color)
				character.h_sec_colour = new_color
			return refresh_preview(user)

		// Set facial hair color
		if("set_facial_hair_color")
			var/new_color = tgui_input_color(user, "Choose facial hair color", "Facial Hair Color", character.f_colour)
			if(new_color)
				character.f_colour = new_color
			return refresh_preview(user)

		// Set secondary facial hair color (there's no way this is used)
		if("set_secondary_facial_hair_color")
			var/new_color = tgui_input_color(user, "Choose secondary facial hair color", "Secondary Facial Hair Color", character.f_sec_colour)
			if(new_color)
				character.f_sec_colour = new_color
			return refresh_preview(user)

		// Set hair gradient type
		if("set_hair_gradient")
			var/new_gradient = params["gradient"]
			if(new_gradient in GLOB.hair_gradients_list)
				character.h_grad_style = new_gradient
			return TRUE

		// Set hair gradient color
		if("set_hair_gradient_color")
			var/new_color = tgui_input_color(user, "Choose hair gradient color", "Hair Gradient Color", character.h_grad_colour)
			if(new_color)
				character.h_grad_colour = new_color
			return refresh_preview(user)

		// Set underwear
		if("set_underwear")
			var/new_underwear = params["underwear"]
			character.underwear = new_underwear
			return refresh_preview(user)

		// Set undershirt
		if("set_undershirt")
			var/new_undershirt = params["undershirt"]
			character.undershirt = new_undershirt
			return refresh_preview(user)

		// Set socks
		if("set_socks")
			var/new_socks = params["socks"]
			character.socks = new_socks
			return refresh_preview(user)

		// Set backpack
		if("set_backpack")
			var/new_backpack = params["backpack"]
			if(new_backpack in GLOB.backbaglist)
				character.backbag = new_backpack
			return refresh_preview(user)

		// Set prosthetic. This has a lot of logic to keep things intuitive and physically possible.
		if("set_prosthetic")
			var/part_name = params["part"]
			var/prosthetic_value = params["value"]

			if(!part_name || !prosthetic_value)
				return FALSE

			var/datum/species/S = GLOB.all_species[character.species]
			var/is_machine = (S.bodyflags & ALL_RPARTS)

			// Check for invalid limb combinations
			if(part_name in list("l_hand", "r_hand", "l_foot", "r_foot"))
				var/main_limb = ""
				if(part_name == "l_hand")
					main_limb = "l_arm"
				else if(part_name == "r_hand")
					main_limb = "r_arm"
				else if(part_name == "l_foot")
					main_limb = "l_leg"
				else if(part_name == "r_foot")
					main_limb = "r_leg"

				var/main_limb_state = character.organ_data[main_limb]

				// Can't have organic hand/foot with prosthetic arm/leg - no blood flow
				if(main_limb_state == "cyborg" && prosthetic_value == "none")
					to_chat(user, "<span class='warning'>You cannot have an organic [part_name] with a prosthetic [main_limb]!</span>")
					return FALSE

			// Handle different prosthetic states
			if(prosthetic_value == "none")
				// Set to intact biological limb (or default for machines)
				character.organ_data -= part_name
				character.rlimb_data -= part_name

				// For consistency with old character creator, if arm/leg becomes intact, also set corresponding hand/foot to intact
				if(part_name == "l_arm")
					character.organ_data -= "l_hand"
					character.rlimb_data -= "l_hand"
				else if(part_name == "r_arm")
					character.organ_data -= "r_hand"
					character.rlimb_data -= "r_hand"
				else if(part_name == "l_leg")
					character.organ_data -= "l_foot"
					character.rlimb_data -= "l_foot"
				else if(part_name == "r_leg")
					character.organ_data -= "r_foot"
					character.rlimb_data -= "r_foot"

			else if(prosthetic_value == "amputated")
				// Set to amputated
				character.organ_data[part_name] = "amputated"
				character.rlimb_data -= part_name

				// If arm/leg is amputated, also amputate corresponding hand/foot (no floating hands/feet)
				if(part_name == "l_arm")
					character.organ_data["l_hand"] = "amputated"
					character.rlimb_data -= "l_hand"
				else if(part_name == "r_arm")
					character.organ_data["r_hand"] = "amputated"
					character.rlimb_data -= "r_hand"
				else if(part_name == "l_leg")
					character.organ_data["l_foot"] = "amputated"
					character.rlimb_data -= "l_foot"
				else if(part_name == "r_leg")
					character.organ_data["r_foot"] = "amputated"
					character.rlimb_data -= "r_foot"

			else
				// Set to prosthetic
				var/datum/robolimb/R = GLOB.all_robolimbs[prosthetic_value]
				var/include_variant = FALSE
				if(is_machine && part_name == "head")
					// Include monitor variants and selectable variants for machine heads
					if(R && (R.is_monitor || R.selectable) && !R.unavailable_at_chargen)
						include_variant = TRUE
				else if(R && R.selectable && !R.unavailable_at_chargen)
					include_variant = TRUE

				if(R && (part_name in R.parts) && include_variant)
					character.organ_data[part_name] = "cyborg"
					character.rlimb_data[part_name] = prosthetic_value

					// For consistency with old character creator, if arm/leg becomes prosthetic, always set corresponding hand/foot to the same prosthetic type
					// You can have granular control over hand/feet prosthetic types by setting those themselves.
					if(part_name == "l_arm")
						character.organ_data["l_hand"] = "cyborg"
						character.rlimb_data["l_hand"] = prosthetic_value
					else if(part_name == "r_arm")
						character.organ_data["r_hand"] = "cyborg"
						character.rlimb_data["r_hand"] = prosthetic_value
					else if(part_name == "l_leg")
						character.organ_data["l_foot"] = "cyborg"
						character.rlimb_data["l_foot"] = prosthetic_value
					else if(part_name == "r_leg")
						character.organ_data["r_foot"] = "cyborg"
						character.rlimb_data["r_foot"] = prosthetic_value

			return refresh_preview(user)

		// Set a nian's wings
		if("set_wing_style")
			var/new_wing_style = params["wing_style"]
			var/datum/species/S = GLOB.all_species[character.species]
			if(S.bodyflags & HAS_WING)
				// Nian must have wings, so default to Plain Wings.
				if(new_wing_style == "None" && character.species == "Nian")
					new_wing_style = "Plain Wings"

				if(new_wing_style == "None")
					character.body_accessory = null
				else if(GLOB.body_accessory_by_name[new_wing_style])
					character.body_accessory = new_wing_style
			return refresh_preview(user)

		// Todo: more exceptions for species-specific body parts, head accessories, body markings, blah blah blah blah blah

		// Eye color
		if("set_eye_color")
			var/new_color = tgui_input_color(user, "Choose eye color", "Eye Color", character.e_colour)
			if(new_color)
				character.e_colour = new_color
			return refresh_preview(user)

		// Skin color
		// Todo: break down by species (some get the full spectrum but a lot have to pick between numerical values)
		// Probably some better way we can handle that
		if("set_skin_color")
			var/new_color = tgui_input_color(user, "Choose skin color", "Skin Color", character.s_colour)
			if(new_color)
				character.s_colour = new_color
			return refresh_preview(user)

		// Randomize the body
		if("randomize_all")
			// First randomize species
			var/list/available_species = get_available_species(user)
			if(length(available_species))
				character.species = pick(available_species)
			// Then randomize everything else based on the new species
			character.randomise()
			return refresh_preview(user)

		/*
		// Toggle antag preferences
		if("toggle_antag_preference")
			var/antag_type = params["antag_type"]
			var/role_to_toggle
			switch(antag_type)
				if("changeling")
					role_to_toggle = ROLE_CHANGELING
				if("cultist")
					role_to_toggle = ROLE_CULTIST
				if("revolutionary")
					role_to_toggle = ROLE_REV
				if("traitor")
					role_to_toggle = ROLE_TRAITOR
				if("vampire")
					role_to_toggle = ROLE_VAMPIRE
				if("wizard")
					role_to_toggle = ROLE_WIZARD
				if("mindflayer")
					role_to_toggle = ROLE_MIND_FLAYER
			if(role_to_toggle)
				if(role_to_toggle in user.client.prefs.be_special)
					user.client.prefs.be_special -= role_to_toggle
				else
					user.client.prefs.be_special += role_to_toggle
				user.client.prefs.save_preferences(user.client)
			return TRUE
		*/

		// Save character
		if("save")
			user.client.prefs.save_preferences(user.client)
			character.save(user.client)
			to_chat(user, "<span class='notice'>Character saved.</span>")
			return TRUE

		// And close.
		if("close")
			ui.close()
			return TRUE

		// Quirk actions
		if("add_quirk")
			var/quirk_path = text2path(params["path"])
			var/datum/quirk/quirk = new quirk_path
			user.add_quirk_to_save(quirk)
			return TRUE

		if("remove_quirk")
			var/quirk_path = text2path(params["path"])
			var/datum/quirk/quirk = new quirk_path
			user.remove_quirk_from_save(quirk)
			return TRUE

		// Loadout actions
		if("toggle_gear")
			var/datum/gear/gear = GLOB.gear_datums[text2path(params["gear"])]
			if(gear && ("[gear]" in character.loadout_gear))
				character.loadout_gear -= "[gear]"
				return TRUE

			if(gear.donator_tier && user.client.donator_level < gear.donator_tier)
				to_chat(user, "<span class='warning'>That gear is only available at a higher donation tier than you are on.</span>")
				return FALSE

			user.client.prefs.build_loadout(gear)
			return TRUE

		if("set_tweak")
			if(!(params["gear"] in character.loadout_gear))
				return FALSE

			var/datum/gear/gear = GLOB.gear_datums[text2path(params["gear"])]
			var/datum/gear_tweak/tweak = locate(text2path(params["tweak"])) in gear.gear_tweaks
			character.set_tweak_metadata(gear, tweak, tweak.get_metadata(user, character.get_tweak_metadata(gear, tweak)))
			return TRUE

		if("clear_loadout")
			character.loadout_gear.Cut()
			return TRUE

	return FALSE

/datum/character_creator/proc/get_available_species(mob/user)
	var/list/available = list()
	for(var/species_name in GLOB.all_species)
		if(can_use_species(user, species_name))
			available += species_name
	return available

/datum/character_creator/proc/get_available_hair_styles(datum/character_save/character)
	var/list/available = list()
	var/datum/species/S = GLOB.all_species[character.species]

	if(S.bodyflags & BALD)
		return list("Bald")

	for(var/hair_style in GLOB.hair_styles_public_list)
		var/datum/sprite_accessory/hair/H = GLOB.hair_styles_public_list[hair_style]
		if(!H.species_allowed || (character.species in H.species_allowed))
			available += hair_style

	if(!length(available))
		available += "Bald"

	return available

/datum/character_creator/proc/get_available_hair_styles_with_icons(datum/character_save/character)
	var/list/available = list()
	var/datum/species/S = GLOB.all_species[character.species]

	if(S.bodyflags & BALD)
		var/icon/bald_icon = icon('icons/mob/human_face.dmi', "bald")
		var/bald_resource = "hair_bald.png"
		if(!served_resources)
			served_resources = list()
		if(!(bald_resource in served_resources))
			usr << browse_rsc(bald_icon, bald_resource)
			served_resources[bald_resource] = TRUE
		available += list(list(
			"name" = "Bald",
			"icon" = bald_resource,
			"icon_state" = ""
		))
		return available

	for(var/hair_style in GLOB.hair_styles_public_list)
		var/datum/sprite_accessory/hair/H = GLOB.hair_styles_public_list[hair_style]
		if(!H.species_allowed || (character.species in H.species_allowed))
			// Generate individual sprite file for each hair style using _s suffix like character preview
			var/icon/hair_icon = icon(H.icon, "[H.icon_state]_s")
			// Use stable resource name for caching
			var/hair_resource = "hair_[H.icon_state].png"
			// Only serve if not already served
			if(!served_resources)
				served_resources = list()
			if(!(hair_resource in served_resources))
				usr << browse_rsc(hair_icon, hair_resource)
				served_resources[hair_resource] = TRUE

			available += list(list(
				"name" = hair_style,
				"icon" = hair_resource,
				"icon_state" = ""
			))

	if(!length(available))
		var/icon/bald_icon = icon('icons/mob/human_face.dmi', "bald")
		var/bald_resource = "hair_bald.png"
		if(!served_resources)
			served_resources = list()
		if(!(bald_resource in served_resources))
			usr << browse_rsc(bald_icon, bald_resource)
			served_resources[bald_resource] = TRUE
		available += list(list(
			"name" = "Bald",
			"icon" = bald_resource,
			"icon_state" = ""
		))

	return available

// What facial hair styles is this character eligible for?
/datum/character_creator/proc/get_available_facial_hair_styles(datum/character_save/character)
	var/list/available = list()
	var/datum/species/S = GLOB.all_species[character.species]

	if(S.bodyflags & SHAVED)
		return list("Shaved")

	for(var/facial_hair_style in GLOB.facial_hair_styles_list)
		var/datum/sprite_accessory/facial_hair/F = GLOB.facial_hair_styles_list[facial_hair_style]
		if(!F.species_allowed || (character.species in F.species_allowed))
			available += facial_hair_style

	if(!length(available))
		available += "Shaved"

	return available

// What facial hair styles is this character eligible for, with icons?
// Probably can merge this with the above somehow
/datum/character_creator/proc/get_available_facial_hair_styles_with_icons(datum/character_save/character)
	var/list/available = list()
	var/datum/species/S = GLOB.all_species[character.species]

	if(S.bodyflags & SHAVED)
		var/icon/shaved_icon = icon('icons/mob/human_face.dmi', "bald")
		var/shaved_resource = "facial_hair_shaved.png"
		if(!served_resources)
			served_resources = list()
		if(!(shaved_resource in served_resources))
			usr << browse_rsc(shaved_icon, shaved_resource)
			served_resources[shaved_resource] = TRUE
		available += list(list(
			"name" = "Shaved",
			"icon" = shaved_resource,
			"icon_state" = ""
		))
		return available

	for(var/facial_hair_style in GLOB.facial_hair_styles_list)
		var/datum/sprite_accessory/facial_hair/F = GLOB.facial_hair_styles_list[facial_hair_style]
		if(!F.species_allowed || (character.species in F.species_allowed))
			// Generate individual sprite file for each facial hair style using _s suffix like character preview
			var/icon/facial_hair_icon = icon(F.icon, "[F.icon_state]_s")
			// Use stable resource name for caching
			var/facial_hair_resource = "facial_hair_[F.icon_state].png"
			// Only serve if not already served
			if(!served_resources)
				served_resources = list()
			if(!(facial_hair_resource in served_resources))
				usr << browse_rsc(facial_hair_icon, facial_hair_resource)
				served_resources[facial_hair_resource] = TRUE

			available += list(list(
				"name" = facial_hair_style,
				"icon" = facial_hair_resource,
				"icon_state" = ""
			))

	if(!length(available))
		var/icon/shaved_icon = icon('icons/mob/human_face.dmi', "bald")
		var/shaved_resource = "facial_hair_shaved.png"
		if(!served_resources)
			served_resources = list()
		if(!(shaved_resource in served_resources))
			usr << browse_rsc(shaved_icon, shaved_resource)
			served_resources[shaved_resource] = TRUE
		available += list(list(
			"name" = "Shaved",
			"icon" = shaved_resource,
			"icon_state" = ""
		))

	return available

// Hair gradients don't ever really change, and we're not previewing them for now.
/datum/character_creator/proc/get_available_hair_gradients()
	var/list/available = list()
	for(var/gradient_style in GLOB.hair_gradients_list)
		var/datum/sprite_accessory/hair_gradient/G = GLOB.hair_gradients_list[gradient_style]
		available += list(list(
			"name" = gradient_style,
			"icon" = G.icon,
			"icon_state" = G.icon_state
		))
	return available

/datum/character_creator/proc/get_available_underwear_with_icons(datum/character_save/character)
	var/list/available = list()

	for(var/underwear_style in GLOB.underwear_list)
		var/datum/sprite_accessory/underwear/U = GLOB.underwear_list[underwear_style]
		if(!(character.species in U.species_allowed))
			continue
		if(character.body_type == MALE && U.body_type == FEMALE)
			continue
		if(character.body_type == FEMALE && U.body_type == MALE)
			continue

		// Generate individual sprite file using _s suffix
		var/icon/underwear_icon = icon(U.icon, "uw_[U.icon_state]_s")
		// Use stable resource name for caching
		var/underwear_resource = "underwear_[U.icon_state].png"
		// Only serve if not already served
		if(!served_resources)
			served_resources = list()
		if(!(underwear_resource in served_resources))
			usr << browse_rsc(underwear_icon, underwear_resource)
			served_resources[underwear_resource] = TRUE

		available += list(list(
			"name" = underwear_style,
			"icon" = underwear_resource,
			"icon_state" = ""
		))
	return available

/datum/character_creator/proc/get_available_undershirt_with_icons(datum/character_save/character)
	var/list/available = list()

	for(var/undershirt_style in GLOB.undershirt_list)
		var/datum/sprite_accessory/undershirt/U = GLOB.undershirt_list[undershirt_style]
		if(!(character.species in U.species_allowed))
			continue
		if(character.body_type == MALE && U.body_type == FEMALE)
			continue
		if(character.body_type == FEMALE && U.body_type == MALE)
			continue

		// Generate individual sprite file using _s suffix
		var/icon/undershirt_icon = icon(U.icon, "us_[U.icon_state]_s")
		// Use stable resource name for caching
		var/undershirt_resource = "undershirt_[U.icon_state].png"
		// Only serve if not already served
		if(!served_resources)
			served_resources = list()
		if(!(undershirt_resource in served_resources))
			usr << browse_rsc(undershirt_icon, undershirt_resource)
			served_resources[undershirt_resource] = TRUE

		available += list(list(
			"name" = undershirt_style,
			"icon" = undershirt_resource,
			"icon_state" = ""
		))
	return available

/datum/character_creator/proc/get_available_socks_with_icons(datum/character_save/character)
	var/list/available = list()

	for(var/socks_style in GLOB.socks_list)
		var/datum/sprite_accessory/socks/U = GLOB.socks_list[socks_style]
		if(!(character.species in U.species_allowed))
			continue
		if(character.body_type == MALE && U.body_type == FEMALE)
			continue
		if(character.body_type == FEMALE && U.body_type == MALE)
			continue

		// Generate individual sprite file using _s suffix like character preview
		var/icon/socks_icon = icon(U.icon, "sk_[U.icon_state]_s")
		// Use stable resource name for caching
		var/socks_resource = "socks_[U.icon_state].png"
		// Only serve if not already served
		if(!served_resources)
			served_resources = list()
		if(!(socks_resource in served_resources))
			usr << browse_rsc(socks_icon, socks_resource)
			served_resources[socks_resource] = TRUE

		available += list(list(
			"name" = socks_style,
			"icon" = socks_resource,
			"icon_state" = ""
		))
	return available

/datum/character_creator/proc/get_available_wing_styles_with_icons(datum/character_save/character)
	var/list/available = list()
	var/datum/species/S = GLOB.all_species[character.species]

	if(!(S.bodyflags & HAS_WING))
		return available

	// Only add "None" option if species is not Nian
	if(character.species != "Nian")
		available += list(list(
			"name" = "None",
			"icon" = null,
			"icon_state" = ""
		))

	// Add wing styles from body accessory list for this species
	if(GLOB.body_accessory_by_species[character.species])
		for(var/wing_name in GLOB.body_accessory_by_species[character.species])
			var/datum/body_accessory/W = GLOB.body_accessory_by_species[character.species][wing_name]
			if(!istype(W, /datum/body_accessory/wing))
				continue

			// Generate individual sprite file for each wing style
			var/icon/wing_icon = icon(W.icon, W.icon_state)
			// Use stable resource name for caching
			var/wing_resource = "wing_[W.icon_state].png"
			// Only serve if not already served
			if(!served_resources)
				served_resources = list()
			if(!(wing_resource in served_resources))
				usr << browse_rsc(wing_icon, wing_resource)
				served_resources[wing_resource] = TRUE

			available += list(list(
				"name" = wing_name,
				"icon" = wing_resource,
				"icon_state" = W.icon_state
			))

	return available

/datum/character_creator/proc/get_available_backpack_types(datum/character_save/character)
	var/list/available = list()
	for(var/backpack_type in GLOB.backbaglist)
		available += list(list(
			"name" = backpack_type,
			"value" = backpack_type
		))
	return available

/datum/character_creator/proc/get_available_prosthetics_with_icons(datum/character_save/character)
	var/list/available = list()
	var/datum/species/S = GLOB.all_species[character.species]

	// Check if species is machine for special handling
	var/is_machine = (S.bodyflags & ALL_RPARTS)

	// Get list of body parts based on species
	var/list/body_parts = list()

	// Always available parts
	body_parts += list("l_arm", "r_arm", "l_hand", "r_hand", "l_leg", "r_leg", "l_foot", "r_foot")

	// Machine-only parts
	if(is_machine)
		body_parts += list("head", "chest")

	for(var/part_name in body_parts)
		var/list/part_options = list()

		// Add None option for non-machines, Morpheus Cyberkinetics for machines
		if(is_machine)
			part_options += list(list(
				"name" = "Morpheus Cyberkinetics",
				"value" = "Morpheus Cyberkinetics",
				"icon" = "prosthetic_Morpheus Cyberkinetics_[part_name].png",
				"description" = "Standard Morpheus Cyberkinetics prosthetic"
			))
		else
			part_options += list(list(
				"name" = "None",
				"value" = "none",
				"icon" = null,
				"description" = "Intact biological limb"
			))

		// Add Amputated option for amputatable parts
		// Head can only be amputated on machines, torso never amputated
		var/can_amputate = FALSE
		if(part_name == "head" && is_machine)
			can_amputate = TRUE
		else if(!(part_name in list("head", "chest")))
			can_amputate = TRUE

		if(can_amputate)
			part_options += list(list(
				"name" = "Amputated",
				"value" = "amputated",
				"icon" = null,
				"description" = "Missing limb"
			))

		// Add prosthetic options
		for(var/company in GLOB.all_robolimbs)
			var/datum/robolimb/R = GLOB.all_robolimbs[company]

			// Skip if this company doesn't support this part
			if(!(part_name in R.parts))
				continue

			// Skip if not available at chargen
			if(R.unavailable_at_chargen)
				continue

			// For non-machines, skip if not selectable (includes alt/monitor variants)
			// For machines, include monitor variants for heads but check selectable flag
			var/include_variant = FALSE
			if(is_machine && part_name == "head")
				// Include monitor variants and selectable variants for machine heads
				// But exclude monitor variants from preview - only show for selection
				if(!R.is_monitor && R.selectable)
					include_variant = TRUE
				else if(R.is_monitor)
					// Allow monitor variants for selection only, they won't show in preview
					include_variant = TRUE
			else if(R.selectable)
				include_variant = TRUE

			if(!include_variant)
				continue

			// Skip head prosthetics for non-machine species
			if(part_name == "head" && !is_machine)
				continue

			var/prosthetic_resource = "prosthetic_[company]_[part_name].png"

			// Serve prosthetic icon if not already served
			if(!served_resources)
				served_resources = list()
			if(!(prosthetic_resource in served_resources))
				var/icon/prosthetic_icon = new /icon(R.icon, part_name)
				usr << browse_rsc(prosthetic_icon, prosthetic_resource)
				served_resources[prosthetic_resource] = world.time

			part_options += list(list(
				"name" = company,
				"value" = company,
				"icon" = prosthetic_resource,
				"description" = R.desc
			))

		available[part_name] = part_options

	return available

/datum/character_creator/proc/get_available_head_accessories_with_icons(datum/character_save/character)
	var/list/available = list()
	var/datum/species/S = GLOB.all_species[character.species]

	if(!(S.bodyflags & HAS_HEAD_ACCESSORY))
		return available

	// Add "None" option first
	available += list(list(
		"name" = "None",
		"icon" = null,
		"icon_state" = ""
	))

	// Add head accessory styles for this species
	for(var/accessory_name in GLOB.head_accessory_styles_list)
		var/datum/sprite_accessory/head_accessory/HA = GLOB.head_accessory_styles_list[accessory_name]
		if(!(character.species in HA.species_allowed))
			continue

		// Generate sprite file for each accessory style
		var/icon/accessory_icon = icon(HA.icon, "[HA.icon_state]_s")
		var/accessory_resource = "head_accessory_[HA.icon_state].png"
		if(!served_resources)
			served_resources = list()
		if(!(accessory_resource in served_resources))
			usr << browse_rsc(accessory_icon, accessory_resource)
			served_resources[accessory_resource] = TRUE

		available += list(list(
			"name" = accessory_name,
			"icon" = accessory_resource,
			"icon_state" = HA.icon_state
		))

	return available

/datum/character_creator/proc/get_available_head_markings_with_icons(datum/character_save/character)
	var/list/available = list()
	var/datum/species/S = GLOB.all_species[character.species]

	if(!(S.bodyflags & HAS_HEAD_MARKINGS))
		return available

	// Add "None" option first
	available += list(list(
		"name" = "None",
		"icon" = null,
		"icon_state" = ""
	))

	// Add head marking styles for this species
	for(var/marking_name in GLOB.marking_styles_list)
		var/datum/sprite_accessory/body_markings/HM = GLOB.marking_styles_list[marking_name]
		if(HM.marking_location != "head")
			continue
		if(!(character.species in HM.species_allowed))
			continue

		// Generate sprite file for each marking style
		var/icon/marking_icon = icon(HM.icon, "[HM.icon_state]_s")
		var/marking_resource = "head_marking_[HM.icon_state].png"
		if(!served_resources)
			served_resources = list()
		if(!(marking_resource in served_resources))
			usr << browse_rsc(marking_icon, marking_resource)
			served_resources[marking_resource] = TRUE

		available += list(list(
			"name" = marking_name,
			"icon" = marking_resource,
			"icon_state" = HM.icon_state
		))

	return available

/datum/character_creator/proc/get_available_body_markings_with_icons(datum/character_save/character)
	var/list/available = list()
	var/datum/species/S = GLOB.all_species[character.species]

	if(!(S.bodyflags & HAS_BODY_MARKINGS))
		return available

	// Add "None" option first
	available += list(list(
		"name" = "None",
		"icon" = null,
		"icon_state" = ""
	))

	// Add body marking styles for this species
	for(var/marking_name in GLOB.marking_styles_list)
		var/datum/sprite_accessory/body_markings/BM = GLOB.marking_styles_list[marking_name]
		if(BM.marking_location != "body")
			continue
		if(!(character.species in BM.species_allowed))
			continue

		// Generate sprite file for each marking style
		var/icon/marking_icon = icon(BM.icon, BM.icon_state)
		var/marking_resource = "body_marking_[BM.icon_state].png"
		if(!served_resources)
			served_resources = list()
		if(!(marking_resource in served_resources))
			usr << browse_rsc(marking_icon, marking_resource)
			served_resources[marking_resource] = TRUE

		available += list(list(
			"name" = marking_name,
			"icon" = marking_resource,
			"icon_state" = BM.icon_state
		))

	return available

/datum/character_creator/proc/get_available_body_accessories_with_icons(datum/character_save/character)
	var/list/available = list()
	var/datum/species/S = GLOB.all_species[character.species]

	// Skip if this is a wing species (wings are handled separately)
	if(S.bodyflags & HAS_WING)
		return available

	// Add "None" option first
	available += list(list(
		"name" = "None",
		"icon" = null,
		"icon_state" = ""
	))

	// Add body accessories (tails, etc.) for this species
	if(GLOB.body_accessory_by_species[character.species])
		for(var/accessory_name in GLOB.body_accessory_by_species[character.species])
			var/datum/body_accessory/BA = GLOB.body_accessory_by_species[character.species][accessory_name]
			if(istype(BA, /datum/body_accessory/wing))
				continue // Skip wings in body accessory list

			// Generate sprite file for each accessory
			var/icon/accessory_icon = icon(BA.icon, BA.icon_state)
			var/accessory_resource = "body_accessory_[BA.icon_state].png"
			if(!served_resources)
				served_resources = list()
			if(!(accessory_resource in served_resources))
				usr << browse_rsc(accessory_icon, accessory_resource)
				served_resources[accessory_resource] = TRUE

			available += list(list(
				"name" = accessory_name,
				"icon" = accessory_resource,
				"icon_state" = BA.icon_state
			))

	return available

// Helper function to refresh character preview (optimized to only run when appearance changes)
/datum/character_creator/proc/refresh_preview(mob/user)
	// Refresh main preview (this automatically updates the headshot too)
	refresh_character_preview(user)
	return TRUE

/datum/character_creator/proc/get_available_head_accessory_styles_with_icons(datum/character_save/character)
	var/list/available = list()

	// Add "None" option first
	available += list(list(
		"name" = "None",
		"icon" = null,
		"icon_state" = ""
	))

	// Add head accessories for this species
	if(GLOB.head_accessory_styles_list)
		for(var/accessory_name in GLOB.head_accessory_styles_list)
			var/datum/sprite_accessory/HA = GLOB.head_accessory_styles_list[accessory_name]

			// Generate sprite file for each accessory
			var/icon/accessory_icon = icon(HA.icon, HA.icon_state)
			var/accessory_resource = "head_accessory_[HA.icon_state].png"
			if(!served_resources)
				served_resources = list()
			if(!(accessory_resource in served_resources))
				usr << browse_rsc(accessory_icon, accessory_resource)
				served_resources[accessory_resource] = TRUE

			available += list(list(
				"name" = accessory_name,
				"icon" = accessory_resource,
				"icon_state" = HA.icon_state
			))

	return available

/datum/character_creator/proc/get_available_head_marking_styles_with_icons(datum/character_save/character)
	var/list/available = list()

	// Add "None" option first
	available += list(list(
		"name" = "None",
		"icon" = null,
		"icon_state" = ""
	))

	// Add head markings for this species
	if(GLOB.marking_styles_list)
		for(var/marking_name in GLOB.marking_styles_list)
			var/datum/sprite_accessory/MA = GLOB.marking_styles_list[marking_name]
			if(!istype(MA, /datum/sprite_accessory/body_markings/head))
				continue

			// Generate sprite file for each marking
			var/icon/marking_icon = icon(MA.icon, MA.icon_state)
			var/marking_resource = "head_marking_[MA.icon_state].png"
			if(!served_resources)
				served_resources = list()
			if(!(marking_resource in served_resources))
				usr << browse_rsc(marking_icon, marking_resource)
				served_resources[marking_resource] = TRUE

			available += list(list(
				"name" = marking_name,
				"icon" = marking_resource,
				"icon_state" = MA.icon_state
			))

	return available

/datum/character_creator/proc/get_available_body_marking_styles_with_icons(datum/character_save/character)
	var/list/available = list()

	// Add "None" option first
	available += list(list(
		"name" = "None",
		"icon" = null,
		"icon_state" = ""
	))

	// Add body markings for this species
	if(GLOB.marking_styles_list)
		for(var/marking_name in GLOB.marking_styles_list)
			var/datum/sprite_accessory/MA = GLOB.marking_styles_list[marking_name]
			if(!istype(MA, /datum/sprite_accessory/body_markings))
				continue

			// Generate sprite file for each marking
			var/icon/marking_icon = icon(MA.icon, MA.icon_state)
			var/marking_resource = "body_marking_[MA.icon_state].png"
			if(!served_resources)
				served_resources = list()
			if(!(marking_resource in served_resources))
				usr << browse_rsc(marking_icon, marking_resource)
				served_resources[marking_resource] = TRUE

			available += list(list(
				"name" = marking_name,
				"icon" = marking_resource,
				"icon_state" = MA.icon_state
			))

	return available

/datum/character_creator/proc/get_available_body_accessory_styles_with_icons(datum/character_save/character)
	var/list/available = list()

	// Add "None" option first
	available += list(list(
		"name" = "None",
		"icon" = null,
		"icon_state" = ""
	))

	// Add body accessories for this species (excluding wings)
	if(GLOB.body_accessory_by_species[character.species])
		for(var/accessory_name in GLOB.body_accessory_by_species[character.species])
			var/datum/body_accessory/BA = GLOB.body_accessory_by_species[character.species][accessory_name]
			if(istype(BA, /datum/body_accessory/wing))
				continue // Skip wings in body accessory list

			// Generate sprite file for each accessory
			var/icon/accessory_icon = icon(BA.icon, BA.icon_state)
			var/accessory_resource = "body_accessory_[BA.icon_state].png"
			if(!served_resources)
				served_resources = list()
			if(!(accessory_resource in served_resources))
				usr << browse_rsc(accessory_icon, accessory_resource)
				served_resources[accessory_resource] = TRUE

			available += list(list(
				"name" = accessory_name,
				"icon" = accessory_resource,
				"icon_state" = BA.icon_state
			))

	return available
