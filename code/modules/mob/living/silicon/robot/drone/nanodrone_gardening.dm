// Nanodrone gardening toys: grass tiles, flower seed pouch, watering can, flower basket, and simple flowers.

#define NANODRONE_FLOWER_RED "red"
#define NANODRONE_FLOWER_YELLOW "yellow"
#define NANODRONE_FLOWER_BLUE "blue"

#define NANODRONE_FLOWER_STAGE_SEED 0
#define NANODRONE_FLOWER_STAGE_1 1
#define NANODRONE_FLOWER_STAGE_2 2
#define NANODRONE_FLOWER_STAGE_FULL 3

#define NANODRONE_FLOWER_GROW_TIME_STAGE_1 (30 SECONDS)
#define NANODRONE_FLOWER_GROW_TIME_STAGE_2 (30 SECONDS)
#define NANODRONE_FLOWER_GROW_TIME_STAGE_FULL (30 SECONDS)
#define NANODRONE_FLOWER_WILT_TIME (90 SECONDS)

#define NANODRONE_FLOWER_MIN_PIXEL_DIST_SQ 49

/proc/nanodrone_is_grass_turf(turf/T)
	return istype(T, /turf/simulated/floor/grass) || istype(T, /turf/simulated/floor/grass/jungle)

/proc/nanodrone_pick_flower_offset(turf/T)
	var/list/candidates = list()
	for(var/i in 1 to 12)
		candidates += i
	var/tries = 12
	while(tries-- > 0)
		var/x = rand(-12, 12)
		var/y = rand(-12, 12)
		var/ok = TRUE
		for(var/obj/effect/nanodrone_flower/F in T)
			var/dx = x - F.pixel_x
			var/dy = y - F.pixel_y
			if((dx*dx + dy*dy) < NANODRONE_FLOWER_MIN_PIXEL_DIST_SQ)
				ok = FALSE
				break
		if(ok)
			return list(x, y)
	return list(0, 0)


/obj/item/nanodrone_seed_pouch
	name = "flower seed pouch"
	desc = "A pouch of flower seeds. Use it on a grass tile to plant."
	icon = 'icons/obj/gardening.dmi'
	icon_state = "seed_pouch"
	w_class = WEIGHT_CLASS_TINY

/obj/item/nanodrone_seed_pouch/afterattack__legacy__attackchain(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	var/turf/T = get_turf(target)
	if(!T || !nanodrone_is_grass_turf(T))
		to_chat(user, SPAN_WARNING("You can only plant these on grass."))
		return

	var/list/choices = list(
		NANODRONE_FLOWER_RED = image(icon = 'icons/obj/gardening.dmi', icon_state = "red_flower"),
		NANODRONE_FLOWER_YELLOW = image(icon = 'icons/obj/gardening.dmi', icon_state = "yellow_flower"),
		NANODRONE_FLOWER_BLUE = image(icon = 'icons/obj/gardening.dmi', icon_state = "blue_flower")
	)

	var/uniqueid = "nanodrone_seed_pouch_[text_ref(user)]"
	var/choice = show_radial_menu(user, src, choices, uniqueid, 40, null, TRUE)
	if(!choice)
		return

	var/obj/effect/nanodrone_flower/F = new /obj/effect/nanodrone_flower(T)
	F.flower_type = choice
	var/list/offset = nanodrone_pick_flower_offset(T)
	F.pixel_x = offset[1]
	F.pixel_y = offset[2]
	F.start_growth()


/obj/item/nanodrone_watering_can
	name = "watering can"
	desc = "A tiny can of plant rejuvenator. It doesn't wet floors."
	icon = 'icons/obj/gardening.dmi'
	icon_state = "watering_can"
	w_class = WEIGHT_CLASS_SMALL
	var/charges = 20
	var/max_charges = 20

/obj/item/nanodrone_watering_can/examine(mob/user)
	. = ..()
	. += SPAN_NOTICE("It has [charges]/[max_charges] sprays remaining.")

/obj/item/nanodrone_watering_can/afterattack__legacy__attackchain(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(charges <= 0)
		to_chat(user, SPAN_WARNING("It's empty."))
		return
	var/turf/T = get_turf(target)
	if(!T)
		return
	if(get_dist(user, T) > 1)
		return

	charges--
	playsound(T, 'sound/effects/spray2.ogg', 35, TRUE)
	var/did_anything = FALSE
	for(var/obj/effect/nanodrone_flower/F in T)
		F.rejuvenate()
		did_anything = TRUE
	if(!did_anything)
		to_chat(user, SPAN_NOTICE("You mist the turf."))


/obj/item/nanodrone_flower_basket
	name = "flower basket"
	desc = "A little basket for collecting and gifting flowers."
	icon = 'icons/obj/gardening.dmi'
	icon_state = "flower_basket"
	w_class = WEIGHT_CLASS_SMALL
	var/list/flower_counts

/obj/item/nanodrone_flower_basket/Initialize(mapload)
	. = ..()
	flower_counts = list(
		NANODRONE_FLOWER_RED = 0,
		NANODRONE_FLOWER_YELLOW = 0,
		NANODRONE_FLOWER_BLUE = 0
	)

/obj/item/nanodrone_flower_basket/proc/add_flower(flower_type, amount = 1)
	if(!flower_counts)
		flower_counts = list()
	flower_counts[flower_type] = max((flower_counts[flower_type] || 0) + amount, 0)

/obj/item/nanodrone_flower_basket/proc/has_any_flowers()
	if(!flower_counts)
		return FALSE
	for(var/k in flower_counts)
		if(flower_counts[k] > 0)
			return TRUE
	return FALSE

/obj/item/nanodrone_flower_basket/proc/get_give_choices()
	var/list/choices = list()
	if((flower_counts[NANODRONE_FLOWER_RED] || 0) > 0)
		choices[NANODRONE_FLOWER_RED] = image(icon = 'icons/obj/gardening.dmi', icon_state = "red_flower")
	if((flower_counts[NANODRONE_FLOWER_YELLOW] || 0) > 0)
		choices[NANODRONE_FLOWER_YELLOW] = image(icon = 'icons/obj/gardening.dmi', icon_state = "yellow_flower")
	if((flower_counts[NANODRONE_FLOWER_BLUE] || 0) > 0)
		choices[NANODRONE_FLOWER_BLUE] = image(icon = 'icons/obj/gardening.dmi', icon_state = "blue_flower")
	return choices

/obj/item/nanodrone_flower_basket/proc/try_give_to_mob(mob/target, mob/user)
	if(!user || !target)
		return FALSE

	// For silicons, only allow gifting when the basket is the active module item.
	if(istype(user, /mob/living/silicon/robot))
		var/mob/living/silicon/robot/R = user
		if(R.get_active_hand() != src)
			return FALSE

	if(!user.Adjacent(target))
		return FALSE

	if(!has_any_flowers())
		to_chat(user, SPAN_WARNING("The basket is empty."))
		return TRUE

	var/list/choices = get_give_choices()
	if(!length(choices))
		to_chat(user, SPAN_WARNING("The basket is empty."))
		return TRUE

	var/uniqueid = "nanodrone_flower_give_[text_ref(user)]"
	var/choice = show_radial_menu(user, src, choices, uniqueid, 40, null, TRUE)
	if(!choice)
		return TRUE
	if((flower_counts[choice] || 0) <= 0)
		to_chat(user, SPAN_WARNING("You don't have that kind of flower."))
		return TRUE

	var/accept = alert(target, "[user] offers you a flower. Accept?", "Flower", "Accept", "Decline")
	if(accept != "Accept")
		to_chat(user, SPAN_NOTICE("They decline."))
		return TRUE

	flower_counts[choice] = max((flower_counts[choice] || 0) - 1, 0)
	var/obj/item/nanodrone_flower_item/I = new(get_turf(target))
	I.flower_type = choice
	I.update_icon_state()
	target.put_in_hands(I)
	to_chat(user, SPAN_NOTICE("They accept the flower."))

	var/mob/living/silicon/robot/drone/nanodrone/N = user
	if(istype(N) && GLOB.nanodroneController)
		GLOB.nanodroneController.add_carried_happiness(N, 20, "gifted flower")

	return TRUE

/obj/item/nanodrone_flower_basket/attack__legacy__attackchain(mob/target as mob, mob/user as mob)
	if(try_give_to_mob(target, user))
		return
	return ..()

/obj/item/nanodrone_flower_basket/afterattack__legacy__attackchain(atom/target, mob/user, proximity)
	. = ..()
	if(ismob(target))
		try_give_to_mob(target, user)
		return
	if(!proximity)
		return

	if(istype(target, /obj/item/nanodrone_flower_item))
		var/obj/item/nanodrone_flower_item/F = target
		add_flower(F.flower_type, 1)
		to_chat(user, SPAN_NOTICE("You add the flower to the basket."))
		qdel(F)
		return

	return


/obj/item/nanodrone_flower_item
	name = "flower"
	desc = "A pretty flower."
	icon = 'icons/obj/gardening.dmi'
	w_class = WEIGHT_CLASS_TINY
	var/flower_type = NANODRONE_FLOWER_RED

/obj/item/nanodrone_flower_item/update_icon_state()
	switch(flower_type)
		if(NANODRONE_FLOWER_RED)
			icon_state = "red_flower"
		if(NANODRONE_FLOWER_YELLOW)
			icon_state = "yellow_flower"
		if(NANODRONE_FLOWER_BLUE)
			icon_state = "blue_flower"
		else
			icon_state = "red_flower"


/obj/effect/nanodrone_flower
	name = "seed"
	desc = "A planted seed."
	icon = 'icons/obj/gardening.dmi'
	icon_state = "seed"
	anchored = TRUE
	layer = OBJ_LAYER
	mouse_opacity = 1
	var/flower_type = NANODRONE_FLOWER_RED
	var/stage = NANODRONE_FLOWER_STAGE_SEED
	var/wilting = FALSE
	var/last_watered_time = 0

/obj/effect/nanodrone_flower/Initialize(mapload)
	. = ..()
	last_watered_time = world.time
	update_icon_state()

/obj/effect/nanodrone_flower/proc/start_growth()
	last_watered_time = world.time
	schedule_next_growth()
	schedule_wilt_check()

/obj/effect/nanodrone_flower/proc/schedule_next_growth()
	var/delay
	switch(stage)
		if(NANODRONE_FLOWER_STAGE_SEED)
			delay = NANODRONE_FLOWER_GROW_TIME_STAGE_1
		if(NANODRONE_FLOWER_STAGE_1)
			delay = NANODRONE_FLOWER_GROW_TIME_STAGE_2
		if(NANODRONE_FLOWER_STAGE_2)
			delay = NANODRONE_FLOWER_GROW_TIME_STAGE_FULL
		else
			return
	addtimer(CALLBACK(src, PROC_REF(advance_growth)), delay)

/obj/effect/nanodrone_flower/proc/schedule_wilt_check()
	addtimer(CALLBACK(src, PROC_REF(wilt_check)), NANODRONE_FLOWER_WILT_TIME)

/obj/effect/nanodrone_flower/proc/wilt_check()
	if(QDELETED(src))
		return
	if(world.time >= (last_watered_time + NANODRONE_FLOWER_WILT_TIME) && stage < NANODRONE_FLOWER_STAGE_FULL)
		wilting = TRUE
		update_icon_state()
	else if(world.time >= (last_watered_time + NANODRONE_FLOWER_WILT_TIME) && stage >= NANODRONE_FLOWER_STAGE_FULL)
		wilting = TRUE
		update_icon_state()
	// Keep checking periodically.
	schedule_wilt_check()

/obj/effect/nanodrone_flower/proc/rejuvenate()
	last_watered_time = world.time
	if(wilting)
		wilting = FALSE
		update_icon_state()
	if(stage < NANODRONE_FLOWER_STAGE_FULL)
		schedule_next_growth()

/obj/effect/nanodrone_flower/proc/advance_growth()
	if(QDELETED(src) || wilting)
		return
	if(stage >= NANODRONE_FLOWER_STAGE_FULL)
		return
	stage++
	update_icon_state()
	if(stage < NANODRONE_FLOWER_STAGE_FULL)
		schedule_next_growth()

/obj/effect/nanodrone_flower/update_icon_state()
	switch(stage)
		if(NANODRONE_FLOWER_STAGE_SEED)
			name = "seed"
			desc = "A planted seed."
			icon_state = "seed"
		if(NANODRONE_FLOWER_STAGE_1)
			name = "sprout"
			desc = "A small sprout."
			icon_state = wilting ? "flower_1_wilting" : "flower_1"
		if(NANODRONE_FLOWER_STAGE_2)
			name = "bud"
			desc = "A growing bud."
			icon_state = wilting ? "flower_2_wilting" : "flower_2"
		if(NANODRONE_FLOWER_STAGE_FULL)
			name = "flower"
			desc = "A fully grown flower."
			switch(flower_type)
				if(NANODRONE_FLOWER_RED)
					icon_state = wilting ? "red_flower_wilting" : "red_flower"
				if(NANODRONE_FLOWER_YELLOW)
					icon_state = wilting ? "yellow_flower_wilting" : "yellow_flower"
				if(NANODRONE_FLOWER_BLUE)
					icon_state = wilting ? "blue_flower_wilting" : "blue_flower"
				else
					icon_state = wilting ? "red_flower_wilting" : "red_flower"

/obj/effect/nanodrone_flower/wirecutter_act(mob/living/user, obj/item/I)
	if(stage < NANODRONE_FLOWER_STAGE_FULL)
		to_chat(user, SPAN_WARNING("It's not ready to harvest."))
		return TRUE

	var/turf/T = get_turf(src)
	if(!T)
		return TRUE

	var/mob/living/silicon/robot/drone/nanodrone/N = user
	if(istype(N))
		var/obj/item/nanodrone_flower_basket/B = locate(/obj/item/nanodrone_flower_basket) in user
		if(!B)
			B = locate(/obj/item/nanodrone_flower_basket) in N.module
		if(B)
			B.add_flower(flower_type, 1)
			to_chat(user, SPAN_NOTICE("You snip the flower into your basket."))
			qdel(src)
			return TRUE

	var/obj/item/nanodrone_flower_item/drop = new(T)
	drop.flower_type = flower_type
	drop.update_icon_state()
	to_chat(user, SPAN_NOTICE("You cut the flower."))
	qdel(src)
	return TRUE

#undef NANODRONE_FLOWER_RED
#undef NANODRONE_FLOWER_YELLOW
#undef NANODRONE_FLOWER_BLUE

#undef NANODRONE_FLOWER_STAGE_SEED
#undef NANODRONE_FLOWER_STAGE_1
#undef NANODRONE_FLOWER_STAGE_2
#undef NANODRONE_FLOWER_STAGE_FULL

#undef NANODRONE_FLOWER_GROW_TIME_STAGE_1
#undef NANODRONE_FLOWER_GROW_TIME_STAGE_2
#undef NANODRONE_FLOWER_GROW_TIME_STAGE_FULL
#undef NANODRONE_FLOWER_WILT_TIME

#undef NANODRONE_FLOWER_MIN_PIXEL_DIST_SQ
