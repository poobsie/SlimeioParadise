/// Backend component for basic character information functionality
/// Frontend sibling: tgui/packages/tgui/interfaces/CharacterCreator/basic_information.tsx

/// Generates basic character information data for the UI
/datum/character_creator/proc/get_basic_information_data(mob/user)
	if(!user.client?.prefs?.active_character)
		return list()

	var/datum/character_save/character = user.client.prefs.active_character

	var/list/data = list()

	// Basic character info
	data["real_name"] = character.real_name
	data["age"] = character.age
	data["gender"] = character.gender == MALE ? "Male" : (character.gender == FEMALE ? "Female" : "Genderless")

	// Available options
	data["available_genders"] = list("Male", "Female", "Genderless")

	return data

/// Handles setting character name with validation
/datum/character_creator/proc/set_character_name(mob/user, name)
	if(!user.client?.prefs?.active_character)
		return FALSE

	var/new_name = reject_bad_name(name, TRUE)
	if(new_name)
		user.client.prefs.active_character.real_name = new_name
		return TRUE
	return FALSE

/// Generates a random name for the character
/datum/character_creator/proc/set_random_character_name(mob/user)
	if(!user.client?.prefs?.active_character)
		return FALSE

	var/datum/character_save/character = user.client.prefs.active_character
	character.real_name = random_name(character.gender, character.species)
	return TRUE

/// Sets character age with species constraints
/datum/character_creator/proc/set_character_age(mob/user, age)
	if(!user.client?.prefs?.active_character)
		return FALSE

	var/datum/character_save/character = user.client.prefs.active_character
	var/new_age = text2num(age)
	if(new_age)
		var/datum/species/S = GLOB.all_species[character.species]
		character.age = clamp(new_age, S.min_age, S.max_age)
		return TRUE
	return FALSE

/// Sets character gender
/datum/character_creator/proc/set_character_gender(mob/user, gender)
	if(!user.client?.prefs?.active_character)
		return FALSE

	var/datum/character_save/character = user.client.prefs.active_character
	switch(gender)
		if("Male")
			character.gender = MALE
		if("Female")
			character.gender = FEMALE
		if("Genderless")
			character.gender = NEUTER
		else
			return FALSE
	return TRUE
