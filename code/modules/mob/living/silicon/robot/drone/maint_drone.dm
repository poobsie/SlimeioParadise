#define EMAG_TIMER 5 MINUTES
/mob/living/silicon/robot/drone
	name = "drone"
	real_name = "drone"
	icon_state = "repairbot"
	maxHealth = 35
	health = 35
	bubble_icon = "machine"
	pass_flags = PASSTABLE
	braintype = "Robot"
	lawupdate = FALSE
	density = FALSE
	has_camera = FALSE
	req_one_access = list(ACCESS_ENGINE, ACCESS_ROBOTICS)
	ventcrawler = VENTCRAWLER_ALWAYS
	mob_size = MOB_SIZE_SMALL
	pull_force = MOVE_FORCE_VERY_WEAK // Can only drag small items
	modules_break = FALSE
	hat_offset_y = -15
	is_centered = TRUE
	can_be_hatted = TRUE
	can_wear_restricted_hats = TRUE
	/// Cooldown for law syncs
	var/sync_cooldown = 0


	// We need to keep track of a few module items so we don't need to do list operations
	// every time we need them. These get set in New() after the module is chosen.
	var/obj/item/stack/sheet/metal/cyborg/stack_metal = null
	var/obj/item/stack/sheet/wood/stack_wood = null
	var/obj/item/stack/sheet/glass/cyborg/stack_glass = null
	var/obj/item/stack/sheet/plastic/stack_plastic = null
	var/obj/item/matter_decompiler/decompiler = null

	// What objects can drones bump into
	var/static/list/allowed_bumpable_objects = list(/obj/machinery/door, /obj/machinery/recharge_station, /obj/machinery/disposal/delivery_chute,
													/obj/machinery/teleport/hub, /obj/effect/portal, /obj/structure/transit_tube/station)

	var/reboot_cooldown = 1 MINUTES
	var/last_reboot
	var/list/pullable_drone_items = list(
		/obj/item/pipe,
		/obj/structure/disposalconstruct,
		/obj/item/stack/cable_coil,
		/obj/item/stack/rods,
		/obj/item/stack/sheet,
		/obj/item/stack/tile
	)

	holder_type = /obj/item/holder/drone

	var/datum/pathfinding_mover/pathfinding
	silicon_subsystems = list(
		/mob/living/silicon/robot/proc/set_mail_tag,
		/mob/living/silicon/robot/proc/self_diagnosis,
		/mob/living/silicon/proc/subsystem_law_manager,
		/mob/living/silicon/proc/subsystem_power_monitor)


/mob/living/silicon/robot/drone/New()
	..()

	remove_language("Robot Talk")
	remove_language("Galactic Common")
	add_language("Drone Talk", TRUE)
	add_language("Drone", TRUE)

	// Disable the microphone wire on Drones
	if(radio)
		radio.wires.cut(WIRE_RADIO_TRANSMIT)

	if(camera && ("Robots" in camera.network))
		camera.network.Add("Engineering")

	//They are unable to be upgraded, so let's give them a bit of a better battery.
	cell = new /obj/item/stock_parts/cell/high(src)

	// NO BRAIN.
	mmi = null

	//We need to screw with their HP a bit. They have around one fifth as much HP as a full borg.
	for(var/V in components) if(V != "power cell")
		var/datum/robot_component/C = components[V]
		C.max_damage = 10

	remove_verb(src, /mob/living/silicon/robot/verb/Namepick)
	module = new /obj/item/robot_module/drone(src)
	// Give us our action button
	var/datum/action/innate/hide/drone_hide/hide = new()
	var/datum/action/innate/robot_magpulse/pulse = new()
	hide.Grant(src)
	pulse.Grant(src)

	//Allows Drones to hear the Engineering channel.
	module.channels = list("Engineering" = 1)
	radio.recalculateChannels()

	//Grab stacks.
	stack_metal = locate(/obj/item/stack/sheet/metal/cyborg) in module
	stack_wood = locate(/obj/item/stack/sheet/wood) in module
	stack_glass = locate(/obj/item/stack/sheet/glass/cyborg) in module
	stack_plastic = locate(/obj/item/stack/sheet/plastic) in module

	//Grab decompiler.
	decompiler = locate(/obj/item/matter_decompiler) in module

	//Some tidying-up.
	flavor_text = "It's a tiny little repair drone. The casing is stamped with an NT logo and the subscript: 'Nanotrasen Recursive Repair Systems: Fixing Tomorrow's Problem, Today!'"
	scanner.Grant(src)
	update_icons()

	// Drones have laws to not attack people
	ADD_TRAIT(src, TRAIT_PACIFISM, INNATE_TRAIT)

/mob/living/silicon/robot/drone/init(alien = FALSE, mob/living/silicon/ai/ai_to_sync_to = null)
	laws = new /datum/ai_laws/drone()
	set_connected_ai(null)

	aiCamera = new /obj/item/camera/siliconcam/drone_camera(src)
	additional_law_channels["Drone"] = ";"
	ADD_TRAIT(src, TRAIT_RESPAWNABLE, UNIQUE_TRAIT_SOURCE(src))

	playsound(loc, 'sound/machines/twobeep.ogg', 50)

//Redefining some robot procs...
/mob/living/silicon/robot/drone/rename_character(oldname, newname)
	// force it to not actually change most things
	return ..(newname, newname)

// Drones don't have a PDA.
/mob/living/silicon/robot/drone/open_pda()
	to_chat(src, SPAN_WARNING("This unit does not have PDA functionality!"))
	return

/mob/living/silicon/robot/drone/get_default_name()
	return "maintenance drone ([rand(100, 999)])"

/mob/living/silicon/robot/drone/update_icons()
	overlays.Cut()
	if(stat == CONSCIOUS)
		overlays += "eyes-[icon_state]"
		if(pathfinding)
			overlays += "eyes-repairbot-pathfinding"
	else
		overlays -= "eyes"
	update_hat_icons()

/mob/living/silicon/robot/drone/pick_module()
	return

/mob/living/silicon/robot/drone/examine(mob/user)
	. = ..()
	if(isAntag(user))
		. += SPAN_WARNING("Using an emag on this drone will slave them to you for 5 minutes... until they explode in a shower of sparks.")

/mob/living/silicon/robot/drone/examine_more(mob/user)//I know examine_more is for lore but the length of this description is too much
	. = ..()
	. += SPAN_NOTICE("<i>The ever-loyal workers of Nanotrasen facilities. Known for their small and cute look, these drones seek only to repair damaged parts of the station, being lawed against hurting even a spiderling. These fine drones are programmed against interfering with any business of anyone, so they won't do anything you don't want them to.</i>")

//Drones cannot be upgraded with borg modules so we need to catch some items before they get used in ..().
/mob/living/silicon/robot/drone/item_interaction(mob/living/user, obj/item/I, list/modifiers)
	if(istype(I, /obj/item/borg/upgrade))
		to_chat(user, SPAN_WARNING("The maintenance drone chassis is not compatible with [I]."))
		return ITEM_INTERACT_COMPLETE

	else if(istype(I, /obj/item/card/id) || istype(I, /obj/item/pda))
		if(stat == DEAD)
		// Currently not functional, so commenting out until it's fixed to avoid confusion
			/*if(!config.allow_drone_spawn || emagged || health < -35) //It's dead, Dave.
				to_chat(user, SPAN_WARNING("The interface is fried, and a distressing burned smell wafts from the robot's interior. You're not rebooting this one."))
				return

			if(!allowed(I))
				to_chat(user, SPAN_WARNING("Access denied."))
				return

			var/delta = (world.time / 10) - last_reboot
			if(reboot_cooldown > delta)
				var/cooldown_time = round(reboot_cooldown - ((world.time / 10) - last_reboot), 1)
				to_chat(usr, SPAN_WARNING("The reboot system is currently offline. Please wait another [cooldown_time] seconds."))
				return

			user.visible_message(SPAN_WARNING("[user] swipes [user.p_their()] ID card through [src], attempting to reboot it."),
				SPAN_WARNING("You swipe your ID card through [src], attempting to reboot it."))
			last_reboot = world.time / 10
			var/drones = 0
			for(var/mob/living/silicon/robot/drone/D in GLOB.silicon_mob_list)
				if(D.key && D.client)
					drones++
			if(drones < config.max_maint_drones)
				request_player()*/
			return ITEM_INTERACT_COMPLETE

		else
			var/confirm = tgui_alert(user, "Using your ID on a Maintenance Drone will shut it down, are you sure you want to do this?", "Disable Drone", list("Yes", "No"))
			if(confirm == ("Yes") && (user in range(3, src)))
				user.visible_message(SPAN_WARNING("[user] swipes [user.p_their()] ID card through [src], attempting to shut it down."),
					SPAN_WARNING("You swipe your ID card through [src], attempting to shut it down."))

				if(emagged)
					return
				if(allowed(I))
					shut_down()
				else
					to_chat(user, SPAN_WARNING("Access denied."))

		return ITEM_INTERACT_COMPLETE

	return ..()

/mob/living/silicon/robot/drone/crowbar_act(mob/user, obj/item/I)
	. = TRUE
	to_chat(user, SPAN_WARNING("The machine is hermetically sealed. You can't open the case."))

/mob/living/silicon/robot/drone/Destroy()
	. = ..()
	QDEL_NULL(stack_glass)
	QDEL_NULL(stack_metal)
	QDEL_NULL(stack_wood)
	QDEL_NULL(stack_plastic)
	QDEL_NULL(decompiler)
	for(var/datum/action/innate/hide/drone_hide/hide in actions)
		hide.Remove(src)

/mob/living/silicon/robot/drone/emag_act(mob/user)
	if(!client || stat == DEAD)
		to_chat(user, SPAN_WARNING("There's not much point subverting this heap of junk."))
		return

	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user

	if(emagged)
		to_chat(src, SPAN_WARNING("[user] attempts to load subversive software into you, but your hacked subroutined ignore the attempt."))
		to_chat(user, SPAN_WARNING("You attempt to subvert [src], but the sequencer has no effect."))
		return

	to_chat(user, SPAN_WARNING("You swipe the sequencer across [src]'s interface and watch its eyes flicker."))

	if(jobban_isbanned(src, ROLE_SYNDICATE))
		SSticker.mode.replace_jobbanned_player(src, ROLE_SYNDICATE)

	to_chat(src, SPAN_WARNING("You feel a sudden burst of malware loaded into your execute-as-root buffer. Your tiny brain methodically parses, loads and executes the script. You sense you have <b>five minutes</b> before the drone server detects this and automatically shuts you down."))
	REMOVE_TRAIT(src, TRAIT_RESPAWNABLE, UNIQUE_TRAIT_SOURCE(src))
	message_admins("[key_name_admin(user)] emagged drone [key_name_admin(src)].  Laws overridden.")
	log_game("[key_name(user)] emagged drone [key_name(src)].  Laws overridden.")
	var/time = time2text(world.realtime,"hh:mm:ss")
	GLOB.lawchanges.Add("[time] <B>:</B> [H.name]([H.key]) emagged [name]([key])")
	addtimer(CALLBACK(src, PROC_REF(shut_down), TRUE), EMAG_TIMER)

	emagged = TRUE
	density = TRUE
	pass_flags = 0
	icon_state = "repairbot-emagged"
	holder_type = /obj/item/holder/drone/emagged
	update_icons()
	set_connected_ai(null)
	clear_supplied_laws()
	clear_inherent_laws()
	laws = new /datum/ai_laws/syndicate_override
	REMOVE_TRAIT(src, TRAIT_PACIFISM, INNATE_TRAIT)
	set_zeroth_law("Only [H.real_name] and people [H.real_name] designates as being such are Syndicate Agents.")

	to_chat(src, "<b>Obey these laws:</b>")
	laws.show_laws(src)
	to_chat(src, SPAN_BOLDWARNING("ALERT: [H.real_name] is your new master. Obey your new laws and [H.real_name]'s commands."))
	return TRUE

//DRONE LIFE/DEATH

//For some goddamn reason robots have this hardcoded. Redefining it for our fragile friends here.
/mob/living/silicon/robot/drone/updatehealth(reason = "none given")
	if(status_flags & GODMODE)
		health = 35
		set_stat(CONSCIOUS)
		return
	health = 35 - (getBruteLoss() + getFireLoss() + getOxyLoss())
	update_stat("updatehealth([reason])")

/mob/living/silicon/robot/drone/death(gibbed)
	. = ..(gibbed)
	adjustBruteLoss(health)

//CONSOLE PROCS
/mob/living/silicon/robot/drone/proc/law_resync()
	if(stat != DEAD)
		if(emagged)
			to_chat(src, SPAN_WARNING("You feel something attempting to modify your programming, but your hacked subroutines are unaffected."))
		else
			to_chat(src, SPAN_WARNING("A reset-to-factory directive packet filters through your data connection, and you obediently modify your programming to suit it."))
			full_law_reset()
			show_laws()

/mob/living/silicon/robot/drone/proc/shut_down(force = FALSE)
	if(stat == DEAD)
		return

	if(emagged && !force)
		to_chat(src, SPAN_WARNING("You feel a system kill order percolate through your tiny brain, but it doesn't seem like a good idea to you."))
		return

	if(!emagged && pathfind_to_dronefab())
		to_chat(src, SPAN_WARNING("You feel a system recall order percolate through your tiny brain, and you return to your drone fabricator."))
		return

	to_chat(src, SPAN_WARNING("You feel a system kill order percolate through your tiny brain, and you obediently destroy yourself."))
	death()

/mob/living/silicon/robot/drone/proc/full_law_reset()
	clear_supplied_laws(TRUE)
	clear_inherent_laws(TRUE)
	clear_ion_laws(TRUE)
	laws = new /datum/ai_laws/drone

//Reboot procs.

/mob/living/silicon/robot/drone/proc/request_player()
	for(var/mob/dead/observer/O in GLOB.player_list)
		if(!O.check_ahud_rejoin_eligibility())
			continue
		if(jobban_isbanned(O, "nonhumandept") || jobban_isbanned(O, "Drone"))
			continue
		if(O.client)
			if(ROLE_PAI in O.client.prefs.be_special)
				question(O.client, O)

/mob/living/silicon/robot/drone/proc/question(client/C, mob/M)
	spawn(0)
		if(!C || !M || jobban_isbanned(M, "nonhumandept") || jobban_isbanned(M, "Drone"))
			return
		var/response = tgui_alert(C, "Someone is attempting to reboot a maintenance drone. Would you like to play as one?", "Maintenance drone reboot", list("Yes", "No"))
		if(!C || ckey)
			return
		if(response == "Yes")
			transfer_personality(C)

/mob/living/silicon/robot/drone/proc/transfer_personality(client/player)
	if(!player)
		return

	ckey = player.ckey

	to_chat(src, "<b>Systems rebooted</b>. Loading base pattern maintenance protocol... <b>loaded</b>.")
	full_law_reset()
	to_chat(src, "<br><b>You are a maintenance drone, a tiny-brained robotic repair machine</b>.")
	to_chat(src, "You have no individual will, no personality, and no drives or urges other than your laws.")
	to_chat(src, "Use <b>:d</b> to talk to other drones, and <b>say</b> to speak silently in a language only your fellows understand.")
	to_chat(src, "Remember, you are <b>lawed against interference with the crew</b>. Also remember, <b>you DO NOT take orders from the AI.</b>")
	to_chat(src, "<b>Don't invade their worksites, don't steal their resources, don't tell them about the changeling in the toilets.</b>")
	to_chat(src, "<b>Make sure crew members do not notice you.</b>.")

/*
	sprite["Default"] = "repairbot"
	sprite["Mk2 Mousedrone"] = "mk2"
	sprite["Mk3 Monkeydrone"] = "mk3"
	var/icontype
	icontype = input(player,"Pick an icon") in sprite
	icon_state = sprite[icontype]

	choose_icon(6,sprite)
*/


/mob/living/silicon/robot/drone/Bump(atom/movable/AM)
	if(is_type_in_list(AM, allowed_bumpable_objects))
		return ..()

/mob/living/silicon/robot/drone/Bumped(atom/movable/AM)
	return

/mob/living/silicon/robot/drone/start_pulling(atom/movable/AM, state, force = pull_force, show_message = FALSE)

	if(is_type_in_list(AM, pullable_drone_items))
		..(AM, force = INFINITY) // Drone power! Makes them able to drag pipes and such

	else if(isitem(AM))
		var/obj/item/O = AM
		if(O.w_class > WEIGHT_CLASS_SMALL)
			if(show_message)
				to_chat(src, SPAN_WARNING("You are too small to pull that."))
			return
		else
			..()
	else
		if(show_message)
			to_chat(src, SPAN_WARNING("You are too small to pull that."))

/mob/living/silicon/robot/drone/add_robot_verbs()
	add_verb(src, silicon_subsystems)

/mob/living/silicon/robot/drone/remove_robot_verbs()
	remove_verb(src, silicon_subsystems)

/mob/living/silicon/robot/drone/add_ventcrawl(obj/machinery/atmospherics/starting_machine)
	..()
	update_headlamp(TRUE, 0, FALSE)

/mob/living/silicon/robot/drone/flash_eyes(intensity = 1, override_blindness_check = FALSE, affect_silicon = FALSE, visual = FALSE, laser_pointer = FALSE, flash_type = /atom/movable/screen/fullscreen/stretch/flash/noise)
	if(affect_silicon)
		return ..()

/mob/living/silicon/robot/drone/decompile_act(obj/item/matter_decompiler/C, mob/user)
	if(!client && isdrone(user))
		to_chat(user, SPAN_WARNING("You begin decompiling the other drone."))
		if(!do_after(user, 5 SECONDS, target = loc))
			to_chat(user, SPAN_WARNING("You need to remain still while decompiling such a large object."))
			return
		if(QDELETED(src) || QDELETED(user))
			return ..()
		to_chat(user, SPAN_WARNING("You carefully and thoroughly decompile your downed fellow, storing as much of its resources as you can within yourself."))
		new /obj/effect/decal/cleanable/blood/oil(get_turf(src))
		C.stored_comms["metal"] += 15
		C.stored_comms["glass"] += 15
		C.stored_comms["wood"] += 5
		qdel(src)
		return TRUE
	return ..()

/mob/living/silicon/robot/drone/do_suicide()
	ghostize()
	shut_down()

/mob/living/silicon/robot/drone/proc/pathfind_to_dronefab()
	if(pathfinding)
		return TRUE

	if(istype(get_turf(src), /turf/space))
		return FALSE // Pretty damn hard to path through space

	var/turf/target
	for(var/obj/machinery/drone_fabricator/DF in SSmachines.get_by_type(/obj/machinery/drone_fabricator))
		if(DF.z != z)
			continue
		target = get_turf(DF)
		target = get_step(target, EAST)
		break

	if(!target)
		return FALSE

	// Mimic having the hide-ability activated
	layer = TURF_LAYER + 0.2
	pass_flags |= PASSDOOR

	var/datum/pathfinding_mover/pathfind = new(src, target)

	set_pathfinding(pathfind)
	var/found_path = pathfind.generate_path(150, null, get_all_accesses())
	if(!found_path)
		set_pathfinding(null)
		return FALSE

	pathfind.on_set_path_null = CALLBACK(src, PROC_REF(pathfind_failed_cleanup))
	pathfind.on_success = CALLBACK(src, PROC_REF(at_dronefab))
	pathfind.start()
	return TRUE

/mob/living/silicon/robot/drone/proc/pathfind_failed_cleanup(pathfind)
	set_pathfinding(null)
	death()

/mob/living/silicon/robot/drone/proc/at_dronefab(pathfind)
	set_pathfinding(null)
	cryo_with_dronefab()

/mob/living/silicon/robot/drone/proc/cryo_with_dronefab(obj/machinery/drone_fabricator/drone_fab)
	if(!drone_fab)
		drone_fab = locate() in range(1, src)
	if(!drone_fab)
		return FALSE
	drone_fab.drone_progress = 100 // recycling!

	visible_message(SPAN_NOTICE("[src] shuts down and enters [drone_fab]."))
	playsound(loc, 'sound/machines/twobeep.ogg', 50)
	qdel(src)
	return TRUE

/mob/living/silicon/robot/drone/proc/set_pathfinding(datum/pathfinding_mover/new_pathfind)
	if(isnull(new_pathfind) && istype(pathfinding))
		qdel(pathfinding)
	pathfinding = new_pathfind
	notransform = istype(new_pathfind) ? TRUE : FALSE // prevent them from moving themselves while pathfinding.
	update_icons()


// ==============================
// Nanodrones (Nanotoys Presents)
// ==============================

#define NANODRONE_UPGRADE_GARDENING (1<<0)
#define NANODRONE_UPGRADE_CLEANER_SPRAYER (1<<1)

// Costs are in personal nanodrone "points" (deposited Happiness minus spent).
#define NANODRONE_UPGRADE_COST_GARDENING 50
#define NANODRONE_UPGRADE_COST_CLEANER_SPRAYER 25

GLOBAL_DATUM_INIT(nanodroneController, /datum/nanodrone_controller, new())

/atom/movable/screen/nanodrone_happiness_display
	name = "0 / ?"
	mouse_opacity = 1

/atom/movable/screen/nanodrone_happiness_display/proc/update_tooltip()
	var/global_current = GLOB.nanodroneController ? GLOB.nanodroneController.global_happiness : 0
	var/global_goal_text = (GLOB.nanodroneController && GLOB.nanodroneController.target_happiness_threshold) ? "[GLOB.nanodroneController.target_happiness_threshold]" : "?"
	name = "[global_current] / [global_goal_text]"

/atom/movable/screen/nanodrone_happiness_display/MouseEntered(location, control, params)
	. = ..()
	update_tooltip()

/datum/nanodrone_controller
	/// Happiness that has been successfully banked by Nanodrones.
	var/global_happiness = 0
	/// Roundstart crew count used to generate goals.
	var/roundstart_crew_count = 0
	/// Target happiness threshold for the shift.
	var/target_happiness_threshold = 0
	/// Baseline station integrity percent at roundstart (relative to the roundstart station state).
	var/baseline_station_integrity_percent = null
	/// Baseline station cleanliness percent at roundstart (absolute).
	var/baseline_station_cleanliness_percent = null
	/// Baseline number of dirty turfs at roundstart (used for "cleanup progress").
	var/baseline_station_dirty_turfs = null
	/// Baseline number of counted (non-space) station turfs.
	var/baseline_station_counted_turfs = null
	/// Cache timestamp for expensive station metric recomputes.
	var/last_station_metrics_update = 0
	/// Cached station integrity percent.
	var/cached_station_integrity_percent = null
	/// Cached station cleanliness percent.
	var/cached_station_cleanliness_percent = null
	/// Cached dirty turf count.
	var/cached_station_dirty_turfs = null
	/// Cached counted turf count.
	var/cached_station_counted_turfs = null

/datum/nanodrone_controller/proc/generate_roundstart_goals(crew_count)
	roundstart_crew_count = max(crew_count, 0)
	// Baseline: 1000 minimum. Add +50 for each roundstart crew above 20.
	target_happiness_threshold = 1000 + (max(roundstart_crew_count - 20, 0) * 50)
	return target_happiness_threshold

/datum/nanodrone_controller/proc/initialize_roundstart_station_baselines()
	// Ensure we have an initial metric snapshot for drones to compare against.
	update_station_metrics(TRUE)
	baseline_station_integrity_percent = cached_station_integrity_percent
	baseline_station_cleanliness_percent = cached_station_cleanliness_percent
	baseline_station_dirty_turfs = cached_station_dirty_turfs
	baseline_station_counted_turfs = cached_station_counted_turfs

/datum/nanodrone_controller/proc/update_station_metrics(force = FALSE)
	// These scans are expensive; cache for a short period.
	if(!force && world.time < (last_station_metrics_update + 300))
		return
	last_station_metrics_update = world.time

	var/datum/station_state/current_state = new /datum/station_state()
	var/station_zlevel = level_name_to_num(MAIN_STATION)
	var/dirty_turfs = 0
	var/counted_turfs = 0

	for(var/turf/T in block(1, 1, station_zlevel, world.maxx, world.maxy, station_zlevel))
		if(istype(T, /turf/space))
			continue
		counted_turfs++

		// ----- Integrity counting (mirrors /datum/station_state/count() without logging) -----
		if(istype(T, /turf/simulated/floor))
			var/turf/simulated/floor/T2 = T
			current_state.floor += (T2.burnt ? 1 : 12)
		if(istype(T, /turf/simulated/wall))
			var/turf/simulated/wall/W = T
			current_state.wall += (W.intact ? 2 : 1)
		if(istype(T, /turf/simulated/wall/r_wall))
			var/turf/simulated/wall/r_wall/R = T
			current_state.r_wall += (R.intact ? 2 : 1)

		for(var/obj/O in T.contents)
			if(istype(O, /obj/structure/window))
				current_state.window += 1
			else if(istype(O, /obj/structure/grille))
				var/obj/structure/grille/GR = O
				if(!GR.broken)
					current_state.grille += 1
			else if(isairlock(O))
				current_state.door += 1
			else if(istype(O, /obj/machinery))
				current_state.mach += 1

		// ----- Cleanliness counting -----
		if(T.blood_DNA)
			dirty_turfs++
			continue
		if(locate(/obj/effect/decal/cleanable) in T)
			dirty_turfs++
			continue

	cached_station_dirty_turfs = dirty_turfs
	cached_station_counted_turfs = counted_turfs
	if(counted_turfs <= 0)
		cached_station_cleanliness_percent = 100
	else
		cached_station_cleanliness_percent = clamp(round(((counted_turfs - dirty_turfs) / counted_turfs) * 100, 0.1), 0, 100)

	// ----- Integrity (relative to roundstart station state) -----
	var/integrity_percent = 100
	if(GLOB.start_state)
		integrity_percent = clamp(round(GLOB.start_state.score(current_state) * 100, 0.1), 0, 100)
	cached_station_integrity_percent = integrity_percent

/datum/nanodrone_controller/proc/get_station_integrity_percent()
	update_station_metrics()
	return (isnull(cached_station_integrity_percent) ? 100 : cached_station_integrity_percent)

/datum/nanodrone_controller/proc/get_station_cleanliness_percent()
	update_station_metrics()
	return (isnull(cached_station_cleanliness_percent) ? 100 : cached_station_cleanliness_percent)

/datum/nanodrone_controller/proc/get_station_cleanliness_progress_percent()
	// "Cleanup progress" relative to roundstart dirt: 0% at roundstart, 100% when all baseline mess is cleaned.
	update_station_metrics()
	if(isnull(baseline_station_dirty_turfs) || baseline_station_dirty_turfs <= 0)
		return 0
	var/current_dirty = max(cached_station_dirty_turfs, 0)
	return clamp(round(((baseline_station_dirty_turfs - current_dirty) / baseline_station_dirty_turfs) * 100, 0.1), 0, 100)

/datum/nanodrone_controller/proc/add_carried_happiness(mob/living/silicon/robot/drone/nanodrone/N, amount, reason)
	if(!N || QDELETED(N) || amount == 0)
		return FALSE
	N.carried_happiness = clamp(N.carried_happiness + amount, 0, N.max_carry_happiness)
	N.update_happiness_hud()
	return TRUE

/datum/nanodrone_controller/proc/deposit_happiness(mob/living/silicon/robot/drone/nanodrone/N)
	if(!N || QDELETED(N))
		return 0
	var/amount = max(N.carried_happiness, 0)
	if(!amount)
		return 0
	global_happiness += amount
	N.carried_happiness = 0
	N.update_happiness_hud()
	return amount

/// Drain from carried happiness first, then global happiness if needed.
/datum/nanodrone_controller/proc/drain_happiness(mob/living/silicon/robot/drone/nanodrone/N, amount, reason)
	if(!N || QDELETED(N) || amount <= 0)
		return FALSE
	var/to_drain = amount
	if(N.carried_happiness > 0)
		var/from_carried = min(N.carried_happiness, to_drain)
		N.carried_happiness -= from_carried
		to_drain -= from_carried
	if(to_drain > 0)
		global_happiness = max(global_happiness - to_drain, 0)
	N.update_happiness_hud()
	return TRUE


/mob/living/silicon/robot/drone/nanodrone
	name = "nanodrone"
	real_name = "nanodrone"
	flavor_text = "It's a tiny little Nanotoys nanodrone, built to help the station and make people happy."
	icon = 'icons/mob/nanodrone.dmi'
	icon_state = "nanodrone"

	/// Happiness currently carried by this Nanodrone (lost on destruction).
	var/carried_happiness = 0
	/// Maximum happiness this Nanodrone can carry before banking.
	var/max_carry_happiness = 100
	/// Total Happiness deposited by this nanodrone into the communal reservoir.
	var/happiness_points_deposited = 0
	/// Total points spent by this nanodrone on upgrades.
	var/happiness_points_spent = 0
	/// Bitfield of purchased nanodrone upgrades.
	var/nanodrone_upgrades = 0
	/// Who we're currently doing a deed for (placeholder until deed datums exist).
	var/mob/living/active_deed_issuer
	/// Which hub we should return to when leaving the CentCom hub room.
	var/obj/machinery/nanodrone_hub/return_hub
	/// Simple debounce for hub teleports to prevent immediate re-triggers on arrival/return.
	var/nanodrone_hub_cooldown_until = 0

/mob/living/silicon/robot/drone/nanodrone/proc/get_happiness_points_balance()
	return max(happiness_points_deposited - happiness_points_spent, 0)

/mob/living/silicon/robot/drone/nanodrone/proc/has_nanodrone_upgrade(flag)
	return (nanodrone_upgrades & flag)

/mob/living/silicon/robot/drone/nanodrone/proc/can_afford_nanodrone_upgrade(cost)
	return (get_happiness_points_balance() >= cost)

/mob/living/silicon/robot/drone/nanodrone/proc/purchase_nanodrone_upgrade(flag, cost)
	if(has_nanodrone_upgrade(flag))
		return FALSE
	if(!can_afford_nanodrone_upgrade(cost))
		return FALSE
	happiness_points_spent += cost
	nanodrone_upgrades |= flag
	return TRUE

/mob/living/silicon/robot/drone/nanodrone/proc/ensure_module_item(item_type)
	if(!module)
		return null
	var/obj/item/existing = locate(item_type) in module
	if(existing)
		return existing
	var/obj/item/new_item = new item_type(module)
	module.add_module(new_item, FALSE)
	if(hud_used)
		hud_used.update_robot_modules_display()
	return new_item

/mob/living/silicon/robot/drone/nanodrone/proc/grant_gardening_kit()
	ensure_module_item(/obj/item/stack/tile/grass/cyborg)
	ensure_module_item(/obj/item/nanodrone_seed_pouch)
	ensure_module_item(/obj/item/nanodrone_watering_can)
	ensure_module_item(/obj/item/nanodrone_flower_basket)

/mob/living/silicon/robot/drone/nanodrone/proc/upgrade_cleaner_sprayer()
	if(!module)
		return FALSE

	var/obj/item/reagent_containers/spray/cleaner/drone/upgraded/already = locate(/obj/item/reagent_containers/spray/cleaner/drone/upgraded) in module
	if(already)
		return TRUE

	var/obj/item/reagent_containers/spray/cleaner/drone/S = locate(/obj/item/reagent_containers/spray/cleaner/drone) in module
	if(!S)
		S = new /obj/item/reagent_containers/spray/cleaner/drone(module)
		module.add_module(S, FALSE)
		module.special_rechargables += S

	var/obj/item/reagent_containers/spray/cleaner/drone/upgraded/U = new /obj/item/reagent_containers/spray/cleaner/drone/upgraded(module)
	module.add_module(U, FALSE)
	module.special_rechargables += U

	if(S.reagents && U.reagents)
		S.reagents.trans_to(U, S.reagents.total_volume)

	if(S == get_active_hand())
		uneq_module(S)
	if(S == get_inactive_hand())
		uneq_module(S)

	module.special_rechargables -= S
	module.modules -= S
	qdel(S)

	if(hud_used)
		hud_used.update_robot_modules_display()
	return TRUE

/mob/living/silicon/robot/drone/nanodrone/proc/update_happiness_hud()
	if(!client || !hud_used)
		return
	var/datum/hud/hud = hud_used
	if(!hud.nanodrone_happiness_display)
		hud.nanodrone_happiness_display = new /atom/movable/screen/nanodrone_happiness_display()
		hud.nanodrone_happiness_display.icon_state = "blood_display"
		hud.nanodrone_happiness_display.screen_loc = "WEST:6,CENTER-1:15"
		hud.static_inventory += hud.nanodrone_happiness_display
		hud.show_hud(hud.hud_version)

	var/atom/movable/screen/nanodrone_happiness_display/happiness_display = hud.nanodrone_happiness_display
	happiness_display.update_tooltip()

	hud.nanodrone_happiness_display.maptext = "<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font face='Small Fonts' color=[COLOR_BLUE_LIGHT]>[carried_happiness]</font></div>"

/mob/living/silicon/robot/drone/nanodrone/proc/remove_happiness_hud()
	hud_used?.remove_nanodrone_hud()

/mob/living/silicon/robot/drone/nanodrone/Login()
	. = ..()
	update_happiness_hud()

/mob/living/silicon/robot/drone/nanodrone/Destroy()
	remove_happiness_hud()
	return ..()

/mob/living/silicon/robot/drone/nanodrone/init(alien = FALSE, mob/living/silicon/ai/ai_to_sync_to = null)
	laws = new /datum/ai_laws/nanodrone_creed()
	set_connected_ai(null)

	aiCamera = new /obj/item/camera/siliconcam/drone_camera(src)
	additional_law_channels["Drone"] = ";"
	ADD_TRAIT(src, TRAIT_RESPAWNABLE, UNIQUE_TRAIT_SOURCE(src))

	playsound(loc, 'sound/machines/twobeep.ogg', 50)

/mob/living/silicon/robot/drone/nanodrone/full_law_reset()
	clear_supplied_laws(TRUE)
	clear_inherent_laws(TRUE)
	clear_ion_laws(TRUE)
	laws = new /datum/ai_laws/nanodrone_creed

/mob/living/silicon/robot/drone/nanodrone/get_default_name()
	return "nanodrone ([rand(100, 999)])"

/mob/living/silicon/robot/drone/nanodrone/transfer_personality(client/player)
	if(!player)
		return

	ckey = player.ckey

	to_chat(src, "<b>Systems rebooted</b>. Loading Nanotoys nanodrone collective profile... <b>loaded</b>.")
	full_law_reset()
	to_chat(src, "<br><b>You are a Nanodrone</b>, a tiny helper that earns and banks Happiness for the collective.")
	to_chat(src, "Use <b>:d</b> to talk to other drones, and <b>say</b> to speak in a language only your fellows understand.")
	to_chat(src, "Your objectives and more systems will be added as Nanodrones are implemented.")
	update_happiness_hud()

/mob/living/silicon/robot/drone/nanodrone/death(gibbed)
	carried_happiness = 0
	return ..(gibbed)

/mob/living/silicon/robot/drone/nanodrone/proc/all_done_finish_effects()
	if(QDELETED(src) || stat != CONSCIOUS)
		return
	var/turf/T = get_turf(src)
	if(!T)
		return

	playsound(T, 'sound/effects/confetti_partywhistle.ogg', 35, 1)

	// Spawn a small confetti burst originating from the drone.
	var/spawner_type = /obj/effect/decal/cleanable/confetti
	var/volume = 12
	var/range = 2
	for(var/i in 1 to volume)
		var/atom/movable/x = new spawner_type(T)
		for(var/j in 1 to rand(1, range))
			step(x, pick(NORTH, SOUTH, EAST, WEST))

/mob/living/silicon/robot/drone/nanodrone/emote(emote_key, type_override = null, message = null, intentional = FALSE, force_silence = FALSE)
	// Provide Nanodrone-specific yes/no presentation without relying on global emote ordering.
	var/key = lowertext(emote_key)
	var/custom_param_offset = findtext(key, EMOTE_PARAM_SEPARATOR, 1, null)
	if(custom_param_offset)
		key = copytext(key, 1, custom_param_offset)

	switch(key)
		if("yes")
			if(stat != CONSCIOUS)
				return TRUE
			visible_message(SPAN_EMOTE("<b>[src]</b> bobs up and down affirmatively."))
			playsound(loc, 'sound/machines/synth_yes.ogg', 50)
			return TRUE
		if("no")
			if(stat != CONSCIOUS)
				return TRUE
			visible_message(SPAN_EMOTE("<b>[src]</b> waggles side-to-side negatively."))
			playsound(loc, 'sound/machines/synth_no.ogg', 50)
			return TRUE

	return ..()


/datum/emote/living/silicon/nanodrone_done
	key = "done"
	key_third_person = "done"
	message = "does an all-done dance!"
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	mob_type_allowed_typecache = list(/mob/living/silicon/robot/drone/nanodrone)
	cooldown = 5 SECONDS

/datum/emote/living/silicon/nanodrone_done/run_emote(mob/user, emote_arg, type_override, intentional)
	var/mob/living/silicon/robot/drone/nanodrone/N = user
	if(!istype(N))
		return TRUE
	if(N.stat != CONSCIOUS)
		return TRUE
	if(!N.active_deed_issuer || QDELETED(N.active_deed_issuer) || !(N.active_deed_issuer in view(N)))
		to_chat(N, SPAN_WARNING("You can only do the all-done dance when the person you're helping can see you."))
		return TRUE
	. = ..()

	// Do a spin emote as part of the dance.
	if(!N.emote("spin", intentional = TRUE, force_silence = TRUE))
		N.spin(20, 1)

	// When the spin finishes, play the sound at half volume and spawn confetti.
	addtimer(CALLBACK(N, TYPE_PROC_REF(/mob/living/silicon/robot/drone/nanodrone, all_done_finish_effects)), 2 SECONDS)
	return TRUE

#undef EMAG_TIMER
