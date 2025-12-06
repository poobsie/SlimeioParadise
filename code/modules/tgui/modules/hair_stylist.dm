/datum/ui_module/hair_stylist
	name = "Professional Hair Stylist"
	var/mob/living/carbon/human/target
	var/mob/user
	var/obj/item/scissors/barber/shears
	var/obj/item/comb/styling_comb
	var/selected_hair_style
	var/selected_facial_hair_style
	var/preview_timestamp

/datum/ui_module/hair_stylist/New(mob/_user, mob/living/carbon/human/_target, obj/item/scissors/barber/_shears, obj/item/comb/_comb)
	. = ..()
	user = _user
	target = _target
	shears = _shears
	styling_comb = _comb
	preview_timestamp = world.time

/datum/ui_module/hair_stylist/ui_state(mob/user)
	return GLOB.conscious_state

/datum/ui_module/hair_stylist/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HairStylist", name)
		ui.autoupdate = TRUE
		ui.open()

/datum/ui_module/hair_stylist/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/hair_stylist)
	)

/datum/ui_module/hair_stylist/ui_data(mob/user)
	var/list/data = list()

	// Basic info
	data["target_name"] = target?.real_name || "Unknown"
	data["has_preview"] = FALSE // Disabled preview for now
	data["preview_timestamp"] = preview_timestamp
	data["selected_hair_style"] = selected_hair_style
	data["selected_facial_hair_style"] = selected_facial_hair_style

	// Check what we can style
	var/obj/item/organ/external/head/head_organ = target?.get_organ("head")
	data["can_style_hair"] = !!head_organ && !(target.dna.species.bodyflags & BALD)
	data["can_style_facial_hair"] = !!head_organ && !(target.dna.species.bodyflags & SHAVED)

	// Generate hair styles
	data["available_hair_styles"] = get_hair_styles_data()
	data["available_facial_hair_styles"] = get_facial_hair_styles_data()

	return data

/datum/ui_module/hair_stylist/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	// Validate that we still have the required tools and target
	if(!user || !target || !shears || !styling_comb)
		return FALSE

	if(!(user in view(1, target)))
		return FALSE

	// Check if target is still sitting
	if(target.body_position != LYING_DOWN && !target.buckled)
		return FALSE

	switch(action)
		if("set_hair_style")
			var/style = params["style"]
			var/list/valid_styles = target.generate_valid_hairstyles()
			if(style in valid_styles)
				selected_hair_style = style
				preview_timestamp = world.time
				generate_preview()
				return TRUE

		if("set_facial_hair_style")
			var/style = params["style"]
			var/list/valid_styles = target.generate_valid_facial_hairstyles()
			if(style in valid_styles)
				selected_facial_hair_style = style
				preview_timestamp = world.time
				generate_preview()
				return TRUE

		if("apply_styles")
			return apply_selected_styles()

		if("close")
			ui.close()
			return TRUE

/datum/ui_module/hair_stylist/proc/get_hair_styles_data()
	var/list/hair_styles = list()
	var/list/valid_styles = target.generate_valid_hairstyles()

	for(var/style_name in valid_styles)
		var/datum/sprite_accessory/hair/style_datum = GLOB.hair_styles_public_list[style_name]
		if(!style_datum)
			continue

		hair_styles += list(list(
			"name" = style_name,
			"icon_state" = style_datum.icon_state,
			"icon" = "hair_[style_datum.icon_state].png"
		))

	return hair_styles

/datum/ui_module/hair_stylist/proc/get_facial_hair_styles_data()
	var/list/facial_styles = list()
	var/list/valid_styles = target.generate_valid_facial_hairstyles()

	for(var/style_name in valid_styles)
		var/datum/sprite_accessory/facial_hair/style_datum = GLOB.facial_hair_styles_list[style_name]
		if(!style_datum)
			continue

		facial_styles += list(list(
			"name" = style_name,
			"icon_state" = style_datum.icon_state,
			"icon" = "facial_hair_[style_datum.icon_state].png"
		))

	return facial_styles

/datum/ui_module/hair_stylist/proc/generate_preview()
	// Disabled for now due to runtime errors - will implement simple text preview instead
	preview_timestamp = world.time



/datum/ui_module/hair_stylist/proc/apply_selected_styles()
	if(!selected_hair_style && !selected_facial_hair_style)
		return FALSE

	var/obj/item/organ/external/head/head_organ = target.get_organ("head")
	if(!head_organ)
		return FALSE

	user.visible_message("<span class='notice'>[user] begins professionally styling [target]'s hair with [shears] and [styling_comb]!</span>",
						 "<span class='notice'>You begin professionally styling [target]'s hair!</span>")
	playsound(user.loc, 'sound/goonstation/misc/scissor.ogg', 100, 1)

	if(do_after(user, 50 * shears.toolspeed, target = target))
		if(!(target in view(1, user)))
			user.visible_message("<span class='notice'>[user] stops styling [target]'s hair.</span>",
								 "<span class='notice'>You stop styling [target]'s hair.</span>")
			return FALSE

		var/changed_something = FALSE
		if(selected_facial_hair_style)
			head_organ.f_style = selected_facial_hair_style
			changed_something = TRUE
		if(selected_hair_style)
			head_organ.h_style = selected_hair_style
			changed_something = TRUE

		if(changed_something)
			target.update_hair()
			target.update_fhair()
			user.visible_message("<span class='notice'>[user] finishes styling [target]'s hair professionally!</span>")
			// Find and close any open UIs
			for(var/datum/tgui/open_ui in SStgui.open_uis)
				if(open_ui.src_object == src)
					open_ui.close()
			return TRUE
	return FALSE
