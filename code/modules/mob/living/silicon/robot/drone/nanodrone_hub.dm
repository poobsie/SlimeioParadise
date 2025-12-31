// ==============================
// Nanodrones (Nanotoys Presents)
// Drone Hubs
// ==============================

#define NANODRONE_HUB_FRAME 0
#define NANODRONE_HUB_UNWIRED 1
#define NANODRONE_HUB_READY 2

/obj/effect/landmark/nanodrone_hub_destination
	name = "nanodrone hub destination"

/obj/machinery/nanodrone_hub
	name = "nanodrone hub"
	desc = "A Nanotoys hub gate. Nanodrones can enter it to reach their shared hub room."
	icon = 'icons/mob/nanodrone.dmi'
	icon_state = "nanodrone_hub"
	anchored = TRUE
	density = TRUE
	max_integrity = 200
	integrity_failure = 80
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 100, BOMB = 0, RAD = 100, FIRE = 90, ACID = 30)
	resistance_flags = FIRE_PROOF
	idle_power_consumption = 2
	active_power_consumption = 4
	power_channel = PW_CHANNEL_ENVIRONMENT

	var/wiresexposed = FALSE
	var/buildstage = NANODRONE_HUB_READY

/obj/machinery/nanodrone_hub/Initialize(mapload, direction, building)
	. = ..()

	if(building)
		buildstage = NANODRONE_HUB_FRAME
		wiresexposed = TRUE
		setDir(direction)

	update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)

	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_atom_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/machinery/nanodrone_hub/CanPass(atom/movable/mover, border_dir)
	// This hub is a dense, enterable gate: only Nanodrones can walk "into" it.
	// Entry is only allowed from the side the door is on (src.dir).
	if(!ismob(mover))
		return TRUE

	if(buildstage != NANODRONE_HUB_READY || wiresexposed)
		return FALSE
	if(stat & (NOPOWER | BROKEN))
		return FALSE

	if(!istype(mover, /mob/living/silicon/robot/drone/nanodrone))
		return FALSE

	return (border_dir == dir)

/obj/machinery/nanodrone_hub/Bumped(atom/movable/AM)
	. = ..()
	var/mob/living/silicon/robot/drone/nanodrone/N = AM
	if(!istype(N))
		return
	if(buildstage != NANODRONE_HUB_READY || wiresexposed)
		return
	if(stat & (NOPOWER | BROKEN))
		return
	to_chat(N, SPAN_WARNING("You can only enter [src] from the side its door faces."))


/obj/machinery/nanodrone_hub/proc/on_atom_entered(datum/source, atom/movable/entered)
	SIGNAL_HANDLER // COMSIG_ATOM_ENTERED

	if(buildstage != NANODRONE_HUB_READY || wiresexposed)
		return
	if(stat & (NOPOWER | BROKEN))
		return

	var/mob/living/silicon/robot/drone/nanodrone/N = entered
	if(!istype(N))
		return
	if(N.nanodrone_hub_cooldown_until && world.time < N.nanodrone_hub_cooldown_until)
		return

	var/area/A = get_area(N)
	if(istype(A, /area/centcom))
		return_from_hub(N)
		return

	enter_hub(N)

/obj/machinery/nanodrone_hub/update_icon_state()
	icon_state = initial(icon_state)

/obj/machinery/nanodrone_hub/update_overlays()
	. = ..()
	underlays.Cut()

/obj/machinery/nanodrone_hub/examine(mob/user)
	. = ..()
	switch(buildstage)
		if(NANODRONE_HUB_FRAME)
			. += SPAN_NOTICE("Its <i>circuit board</i> is missing and the <b>bolts</b> are exposed.")
		if(NANODRONE_HUB_UNWIRED)
			. += SPAN_NOTICE("The frame is missing <i>wires</i> and the control circuit can be <b>pried out</b>.")
		if(NANODRONE_HUB_READY)
			if(wiresexposed)
				. += SPAN_NOTICE("The wiring could be <i>cut and removed</i> or the panel could be <b>screwed</b> closed.")

/obj/machinery/nanodrone_hub/attack_hand(mob/user)
	if(..())
		return

	if(buildstage != NANODRONE_HUB_READY || wiresexposed)
		to_chat(user, SPAN_WARNING("[src] is not ready."))
		return

	if(stat & (NOPOWER | BROKEN))
		to_chat(user, SPAN_WARNING("[src] is unresponsive."))
		return

	var/mob/living/silicon/robot/drone/nanodrone/N = user
	if(!istype(N))
		to_chat(user, SPAN_WARNING("Only nanodrones can interface with [src]."))
		return

	var/area/A = get_area(N)
	if(istype(A, /area/centcom))
		return return_from_hub(N)

	return enter_hub(N)

/obj/machinery/nanodrone_hub/proc/enter_hub(mob/living/silicon/robot/drone/nanodrone/N)
	if(!N || QDELETED(N))
		return FALSE

	var/turf/destination = get_hub_destination_turf()
	if(!destination)
		to_chat(N, SPAN_WARNING("The hub connection fails to resolve a destination."))
		return FALSE

	N.return_hub = src
	N.nanodrone_hub_cooldown_until = world.time + 1 SECONDS
	playsound(get_turf(src), 'sound/machines/click.ogg', 35, TRUE)
	N.forceMove(destination)
	return TRUE

/obj/machinery/nanodrone_hub/proc/return_from_hub(mob/living/silicon/robot/drone/nanodrone/N)
	if(!N || QDELETED(N))
		return FALSE

	var/obj/machinery/nanodrone_hub/return_hub = N.return_hub
	if(!return_hub || QDELETED(return_hub))
		to_chat(N, SPAN_WARNING("You don't have a hub to return to."))
		return FALSE

	var/turf/return_turf = return_hub.get_exit_turf()
	if(!return_turf)
		to_chat(N, SPAN_WARNING("The hub can't find a safe return point."))
		return FALSE

	N.nanodrone_hub_cooldown_until = world.time + 1 SECONDS
	playsound(get_turf(src), 'sound/machines/click.ogg', 35, TRUE)
	N.forceMove(return_turf)
	return TRUE

/obj/machinery/nanodrone_hub/proc/get_hub_destination_turf()
	for(var/obj/effect/landmark/nanodrone_hub_destination/L in world)
		return get_turf(L)

	var/list/turfs = get_area_turfs(/area/centcom/nanodrone_hub)
	if(length(turfs))
		return pick(turfs)

	turfs = get_area_turfs(/area/centcom/holding)
	if(length(turfs))
		return pick(turfs)

	return null

/obj/machinery/nanodrone_hub/proc/get_exit_turf()
	var/turf/hub_turf = get_turf(src)
	if(!hub_turf)
		return null

	// Return drones to the tile on the door side, to avoid instantly re-triggering the hub.
	var/turf/candidate = get_step(hub_turf, dir)
	if(candidate && !candidate.density)
		return candidate

	candidate = get_step(hub_turf, turn(dir, 180))
	if(candidate && !candidate.density)
		return candidate

	for(var/turf/T as anything in orange(1, hub_turf))
		if(!T.density)
			return T

	return null

/obj/machinery/nanodrone_hub/item_interaction(mob/living/user, obj/item/used, list/modifiers)
	add_fingerprint(user)

	switch(buildstage)
		if(NANODRONE_HUB_UNWIRED)
			if(iscoil(used))
				var/obj/item/stack/cable_coil/coil = used
				if(coil.get_amount() < 5)
					to_chat(user, SPAN_WARNING("You need more cable for this!"))
					return ITEM_INTERACT_COMPLETE

				to_chat(user, SPAN_NOTICE("You wire [src]!"))
				playsound(get_turf(src), coil.usesound, 50, TRUE)
				coil.use(5)

				buildstage = NANODRONE_HUB_READY
				wiresexposed = TRUE
				update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)
				return ITEM_INTERACT_COMPLETE

		if(NANODRONE_HUB_FRAME)
			if(istype(used, /obj/item/circuitboard/nanodrone_hub))
				to_chat(user, SPAN_NOTICE("You insert [used] into [src]."))
				playsound(get_turf(src), used.usesound, 50, TRUE)
				qdel(used)
				buildstage = NANODRONE_HUB_UNWIRED
				update_icon(UPDATE_ICON_STATE)
				return ITEM_INTERACT_COMPLETE

	return ..()

/obj/machinery/nanodrone_hub/crowbar_act(mob/user, obj/item/I)
	if(buildstage != NANODRONE_HUB_UNWIRED)
		return
	. = TRUE
	if(!I.tool_start_check(src, user, 0))
		return
	CROWBAR_ATTEMPT_PRY_CIRCUIT_MESSAGE
	if(!I.use_tool(src, user, 20, volume = I.tool_volume))
		return
	if(buildstage != NANODRONE_HUB_UNWIRED)
		return
	CROWBAR_PRY_CIRCUIT_SUCCESS_MESSAGE
	new /obj/item/circuitboard/nanodrone_hub(loc)
	buildstage = NANODRONE_HUB_FRAME
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/nanodrone_hub/screwdriver_act(mob/user, obj/item/I)
	if(buildstage != NANODRONE_HUB_READY)
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	wiresexposed = !wiresexposed
	update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)
	if(wiresexposed)
		SCREWDRIVER_OPEN_PANEL_MESSAGE
	else
		SCREWDRIVER_CLOSE_PANEL_MESSAGE

/obj/machinery/nanodrone_hub/wirecutter_act(mob/user, obj/item/I)
	if(buildstage != NANODRONE_HUB_READY)
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	if(!wiresexposed)
		to_chat(user, SPAN_WARNING("You need to expose the wires first!"))
		return
	update_icon(UPDATE_ICON_STATE)
	WIRECUTTER_SNIP_MESSAGE
	var/obj/item/stack/cable_coil/new_coil = new /obj/item/stack/cable_coil(loc)
	new_coil.amount = 5
	buildstage = NANODRONE_HUB_UNWIRED

/obj/machinery/nanodrone_hub/wrench_act(mob/user, obj/item/I)
	if(buildstage != NANODRONE_HUB_FRAME)
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	new /obj/item/mounted/frame/nanodrone_hub(get_turf(user))
	WRENCH_UNANCHOR_WALL_MESSAGE
	qdel(src)


/obj/item/mounted/frame/nanodrone_hub
	name = "nanodrone hub frame"
	desc = "Used for building Nanodrone Hubs."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "alarm_bitem"

	materials = list(MAT_METAL = 2000)
	metal_sheets_refunded = 1
	mount_requirements = MOUNTED_FRAME_SIMFLOOR | MOUNTED_FRAME_NOSPACE

/obj/item/mounted/frame/nanodrone_hub/do_build(turf/on_wall, mob/user)
	var/obj/machinery/nanodrone_hub/H = new /obj/machinery/nanodrone_hub(get_turf(src), get_dir(user, on_wall), 1)
	H.buildstage = NANODRONE_HUB_FRAME
	H.update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)
	qdel(src)


// A non-constructible, wall-mounted "exit" gate intended for the CentCom hub room.
// - Only Nanodrones can enter.
// - Entry is only allowed from the north side (hardcoded).
// - On entry, it returns the Nanodrone back to its stored return hub.
/obj/machinery/nanodrone_hub_return_gate
	name = "nanodrone return gate"
	desc = "A wall-mounted Nanotoys gate. Nanodrones can exit the hub through it."
	icon = 'icons/mob/nanodrone.dmi'
	icon_state = "nanodrone_hub"
	anchored = TRUE
	density = TRUE
	power_state = NO_POWER_USE
	flags = NODECONSTRUCT

/obj/machinery/nanodrone_hub_return_gate/Initialize(mapload)
	. = ..()
	setDir(SOUTH)
	set_pixel_offsets_from_dir(26, -26, 26, -26)
	update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)

	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_atom_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/machinery/nanodrone_hub_return_gate/CanPass(atom/movable/mover, border_dir)
	if(!ismob(mover))
		return TRUE
	if(!istype(mover, /mob/living/silicon/robot/drone/nanodrone))
		return FALSE
	return (border_dir == NORTH)

/obj/machinery/nanodrone_hub_return_gate/Bumped(atom/movable/AM)
	. = ..()
	var/mob/living/silicon/robot/drone/nanodrone/N = AM
	if(!istype(N))
		return
	to_chat(N, SPAN_WARNING("You can only enter [src] from the north side."))

/obj/machinery/nanodrone_hub_return_gate/proc/on_atom_entered(datum/source, atom/movable/entered)
	SIGNAL_HANDLER // COMSIG_ATOM_ENTERED
	var/mob/living/silicon/robot/drone/nanodrone/N = entered
	if(!istype(N))
		return
	if(N.nanodrone_hub_cooldown_until && world.time < N.nanodrone_hub_cooldown_until)
		return
	return_from_hub(N)

/obj/machinery/nanodrone_hub_return_gate/proc/return_from_hub(mob/living/silicon/robot/drone/nanodrone/N)
	if(!N || QDELETED(N))
		return FALSE

	var/obj/machinery/nanodrone_hub/return_hub = N.return_hub
	if(!return_hub || QDELETED(return_hub))
		to_chat(N, SPAN_WARNING("You don't have a hub to return to."))
		return FALSE

	var/turf/return_turf = return_hub.get_exit_turf()
	if(!return_turf)
		to_chat(N, SPAN_WARNING("The hub can't find a safe return point."))
		return FALSE

	N.nanodrone_hub_cooldown_until = world.time + 1 SECONDS
	playsound(get_turf(src), 'sound/machines/click.ogg', 35, TRUE)
	N.forceMove(return_turf)
	return TRUE


/obj/machinery/nanodrone_happiness_deposit
	name = "happiness deposit port"
	desc = "A port for nanodrones to deposit collected Happiness into a larger communal reservoir."
	icon = 'icons/mob/nanodrone.dmi'
	icon_state = "nanodrone_deposit"
	anchored = TRUE
	density = FALSE
	power_state = NO_POWER_USE
	flags = NODECONSTRUCT

/obj/machinery/nanodrone_happiness_deposit/attack_hand(mob/user)
	if(..())
		return
	var/mob/living/silicon/robot/drone/nanodrone/N = user
	if(!istype(N))
		to_chat(user, SPAN_WARNING("Only nanodrones can use [src]."))
		return

	var/deposited = GLOB.nanodroneController.deposit_happiness(N)
	if(!deposited)
		to_chat(N, SPAN_NOTICE("You have no Happiness to deposit."))
		return

	playsound(get_turf(src), 'sound/machines/ping.ogg', 35, TRUE)
	N.happiness_points_deposited += deposited
	to_chat(N, SPAN_NOTICE("You deposit [deposited] Happiness."))


/obj/machinery/computer/nanodrone_hub_console
	name = "nanodrone hub console"
	desc = "A console used by nanodrones to review their collective progress."
	icon = 'icons/mob/nanodrone.dmi'
	icon_state = "nanodrone_console"
	icon_screen = null
	icon_keyboard = null
	req_access = null
	circuit = null
	flags = NODECONSTRUCT

/obj/machinery/computer/nanodrone_hub_console/attack_hand(mob/user)
	if(..())
		return
	var/mob/living/silicon/robot/drone/nanodrone/N = user
	if(!istype(N))
		to_chat(user, SPAN_WARNING("The console doesn't respond to you."))
		return
	ui_interact(user)

// tgui\packages\tgui\interfaces\NanodroneHubConsole.jsx
/obj/machinery/computer/nanodrone_hub_console/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/nanodrone_hub_console/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NanodroneHubConsole", "Nanodrone Hub Console")
		ui.open()

/obj/machinery/computer/nanodrone_hub_console/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/silicon/robot/drone/nanodrone/N = user
	if(!istype(N) || !GLOB.nanodroneController)
		return data

	var/datum/nanodrone_controller/C = GLOB.nanodroneController

	data["global_happiness"] = C.global_happiness
	data["global_goal"] = (C.target_happiness_threshold ? C.target_happiness_threshold : null)
	data["carried_happiness"] = N.carried_happiness
	data["max_carry_happiness"] = N.max_carry_happiness

	data["points_deposited"] = N.happiness_points_deposited
	data["points_spent"] = N.happiness_points_spent
	data["points_balance"] = N.get_happiness_points_balance()

	data["station_integrity"] = C.get_station_integrity_percent()
	data["station_cleanliness"] = C.get_station_cleanliness_percent()
	data["cleanup_progress"] = C.get_station_cleanliness_progress_percent()
	data["baseline_integrity"] = C.baseline_station_integrity_percent
	data["baseline_cleanliness"] = C.baseline_station_cleanliness_percent
	data["baseline_dirty_turfs"] = C.baseline_station_dirty_turfs

	data["upgrades"] = list(
		list(
			id = "gardening",
			name = "Gardening Kit",
			desc = "Unlocks grass tiles and gardening tools.",
			cost = NANODRONE_UPGRADE_COST_GARDENING,
			purchased = (N.has_nanodrone_upgrade(NANODRONE_UPGRADE_GARDENING) ? TRUE : FALSE)
		),
		list(
			id = "sprayer",
			name = "Cleaner Sprayer Upgrade",
			desc = "Increases cleaner sprayer capacity.",
			cost = NANODRONE_UPGRADE_COST_CLEANER_SPRAYER,
			purchased = (N.has_nanodrone_upgrade(NANODRONE_UPGRADE_CLEANER_SPRAYER) ? TRUE : FALSE)
		)
	)

	return data

/obj/machinery/computer/nanodrone_hub_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	. = TRUE

	var/mob/living/silicon/robot/drone/nanodrone/N = usr
	if(!istype(N))
		return

	switch(action)
		if("purchase_upgrade")
			var/upgrade_id = params["id"]
			switch(upgrade_id)
				if("gardening")
					if(!N.purchase_nanodrone_upgrade(NANODRONE_UPGRADE_GARDENING, NANODRONE_UPGRADE_COST_GARDENING))
						to_chat(N, SPAN_WARNING("You can't afford that upgrade, or you already own it."))
						return
					N.grant_gardening_kit()
					to_chat(N, SPAN_NOTICE("Gardening Kit unlocked."))
					return
				if("sprayer")
					if(!N.purchase_nanodrone_upgrade(NANODRONE_UPGRADE_CLEANER_SPRAYER, NANODRONE_UPGRADE_COST_CLEANER_SPRAYER))
						to_chat(N, SPAN_WARNING("You can't afford that upgrade, or you already own it."))
						return
					N.upgrade_cleaner_sprayer()
					to_chat(N, SPAN_NOTICE("Cleaner Sprayer upgraded."))
					return

#undef NANODRONE_HUB_FRAME
#undef NANODRONE_HUB_UNWIRED
#undef NANODRONE_HUB_READY
