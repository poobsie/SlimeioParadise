/datum/asset/simple/hair_stylist
	keep_local_name = TRUE

/datum/asset/simple/hair_stylist/register()
	// Generate icons for all hair styles - use smaller, efficient icons
	for(var/style_name in GLOB.hair_styles_public_list)
		var/datum/sprite_accessory/hair/style_datum = GLOB.hair_styles_public_list[style_name]
		if(!style_datum)
			continue

		// Create a 32x32 icon for better performance
		var/icon/hair_icon = icon(style_datum.icon, style_datum.icon_state, SOUTH, 1)
		if(hair_icon)
			hair_icon = fcopy_rsc(hair_icon)
			assets["hair_[style_datum.icon_state].png"] = hair_icon

	// Generate icons for all facial hair styles - use smaller, efficient icons  
	for(var/style_name in GLOB.facial_hair_styles_list)
		var/datum/sprite_accessory/facial_hair/style_datum = GLOB.facial_hair_styles_list[style_name]
		if(!style_datum)
			continue

		var/icon/facial_icon = icon(style_datum.icon, style_datum.icon_state, SOUTH, 1)
		if(facial_icon)
			facial_icon = fcopy_rsc(facial_icon)
			assets["facial_hair_[style_datum.icon_state].png"] = facial_icon

	return ..()
