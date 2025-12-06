/obj/item/scissors
	name = "Scissors"
	desc = "Those are scissors. Don't run with them!"
	icon_state = "scissor"
	inhand_icon_state = "scissor"
	force = 5
	sharp = TRUE
	w_class = WEIGHT_CLASS_SMALL
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("slices", "cuts", "stabs", "jabs")

/obj/item/scissors/barber
	name = "hairdressing shears"
	desc = "Professional hairdressing shears. You'll need a comb to use these properly."
	icon_state = "bscissor"
	attack_verb = list("beautifully sliced", "artistically cut", "smoothly stabbed", "quickly jabbed")
	toolspeed = 0.75

/obj/item/comb
	name = "comb"
	desc = "A styling comb for grooming hair. You'll need hairdressing shears to use this properly."
	icon = 'icons/obj/items.dmi'
	icon_state = "comb"
	w_class = WEIGHT_CLASS_TINY
	force = 1
	hitsound = 'sound/weapons/tap.ogg'

// Hair styling proc - requires both shears and comb, target must be sitting
/proc/style_hair_with_tools(obj/item/scissors/barber/shears, obj/item/comb/comb, mob/living/carbon/human/target, mob/user)
	if(!ishuman(target))
		return FALSE

	var/obj/item/organ/external/head/head_organ = target.get_organ("head")
	if(!head_organ)
		to_chat(user, "<span class='warning'>[target] doesn't have a head!</span>")
		return FALSE

	// Check if target is sitting
	if(target.body_position != LYING_DOWN && !target.buckled)
		to_chat(user, "<span class='warning'>[target] needs to be sitting down for you to properly style their hair!</span>")
		return FALSE

	// Open the professional hair stylist TGUI interface
	var/datum/ui_module/hair_stylist/stylist_ui = new(user, target, shears, comb)
	stylist_ui.ui_interact(user)
	return TRUE

/obj/item/scissors/attack__legacy__attackchain(mob/living/carbon/M as mob, mob/user as mob)
	if(user.a_intent != INTENT_HELP)
		..()
		return
	if(!(M in view(1))) //Adjacency test
		..()
		return

	// Check if this is a barber scissors and if we're trying to style hair
	if(istype(src, /obj/item/scissors/barber))
		// Check for comb in other hand
		var/obj/item/other_hand = user.get_inactive_hand()
		if(!istype(other_hand, /obj/item/comb))
			to_chat(user, "<span class='warning'>You need to hold a comb in your other hand to style hair properly!</span>")
			return

		// Try to style hair with professional tools
		style_hair_with_tools(src, other_hand, M, user)
		return

	// Regular scissors behavior for non-barber scissors only
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/organ/external/head/C = H.get_organ("head")
		if(!C)
			to_chat(user, "<span class='warning'>[M] doesn't have a head!</span>")
			return
		//facial hair
		var/f_new_style = tgui_input_list(user, "Select a facial hair style", "Basic Grooming", H.generate_valid_facial_hairstyles())
		//handle normal hair
		var/h_new_style = tgui_input_list(user, "Select a hair style", "Basic Grooming", H.generate_valid_hairstyles())
		user.visible_message("<span class='notice'>[user] starts cutting [M]'s hair!</span>", "<span class='notice'>You start cutting [M]'s hair!</span>")
		playsound(loc, 'sound/goonstation/misc/scissor.ogg', 100, 1)
		if(do_after(user, 50 * toolspeed, target = H))
			if(!(M in view(1)))
				user.visible_message("<span class='notice'>[user] stops cutting [M]'s hair.</span>", "<span class='notice'>You stop cutting [M]'s hair.</span>")
				return
			if(f_new_style)
				C.f_style = f_new_style
			if(h_new_style)
				C.h_style = h_new_style

		H.update_hair()
		H.update_fhair()
		user.visible_message("<span class='notice'>[user] finishes cutting [M]'s hair!</span>")

/obj/item/comb/attack__legacy__attackchain(mob/living/carbon/M as mob, mob/user as mob)
	if(user.a_intent != INTENT_HELP)
		..()
		return
	if(!(M in view(1)))
		..()
		return

	// Check for hairdressing shears in other hand
	var/obj/item/other_hand = user.get_inactive_hand()
	if(!istype(other_hand, /obj/item/scissors/barber))
		to_chat(user, "<span class='warning'>You need to hold hairdressing shears in your other hand to style hair properly!</span>")
		return

	// Try to style hair
	style_hair_with_tools(other_hand, src, M, user)
