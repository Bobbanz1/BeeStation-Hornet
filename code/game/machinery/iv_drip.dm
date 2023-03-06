///IV drip operation mode when it sucks blood from the object
#define IV_TAKING 0
///IV drip operation mode when it injects reagents into the object
#define IV_INJECTING 1
///Minimum possible IV drip transfer rate in units per second
#define MIN_IV_TRANSFER_RATE 0
///Maximum possible IV drip transfer rate in units per second
#define MAX_IV_TRANSFER_RATE 5
///What the transfer rate value is rounded to
#define IV_TRANSFER_RATE_STEP 0.01

///Universal IV that can drain blood or feed reagents over a period of time from or to a replaceable container
/obj/machinery/iv_drip
	name = "\improper IV drip"
	desc = "An IV drip with an advanced infusion pump that can both drain blood into and inject liquids from attached containers. Blood packs are injected at an twice the displayed rate. Alt-Click to change the transfer rate to the maximum possible."
	icon = 'icons/obj/iv_drip.dmi'
	icon_state = "iv_drip"
	base_icon_state = "iv_drip"
	///icon_state for the reagent fill overlay
	var/fill_icon_state = "reagent"
	///The thresholds used to determine the reagent fill icon
	var/list/fill_icon_thresholds = list(0,10,25,50,75,80,90)
	anchored = FALSE
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	///What are we sticking our needle in?
	var/atom/attached
	///Are we donating or injecting?
	var/mode = IV_INJECTING
	///whether we feed slower
	var/transfer_rate = MIN_IV_TRANSFER_RATE
	///Internal beaker
	var/obj/item/reagent_containers/beaker
	///Typecache of containers we accept
	var/static/list/drip_containers = typecacheof(list(/obj/item/reagent_containers/blood,
									/obj/item/reagent_containers/chem_bag,
									/obj/item/reagent_containers/food,
									/obj/item/reagent_containers/glass))
	var/can_convert = TRUE // If it can be made into an anesthetic machine or not
	// If the blood draining tab should be greyed out
	var/inject_only = FALSE

/obj/machinery/iv_drip/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_ICON)

/obj/machinery/iv_drip/Destroy()
	attached = null
	QDEL_NULL(beaker)
	return ..()

/obj/machinery/iv_drip/Moved(atom/OldLoc, Dir)
	. = ..()
	if(has_gravity())
		playsound(src, 'sound/effects/roll.ogg', 100, TRUE)

/obj/machinery/iv_drip/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IVDrip", name)
		ui.open()
		ui.set_autoupdate(TRUE) // Reagent Amounts

/obj/machinery/iv_drip/ui_data(mob/user)
	var/list/data = list()
	data["transferRate"] = transfer_rate
	data["transferStep"] = IV_TRANSFER_RATE_STEP
	data["maxInjectRate"] = MAX_IV_TRANSFER_RATE
	data["minInjectRate"] = MIN_IV_TRANSFER_RATE
	data["mode"] = mode == IV_INJECTING ? TRUE : FALSE
	data["connected"] = attached ? TRUE : FALSE
	if(attached)
		data["objectName"] = attached.name
	data["injectOnly"] = inject_only || (attached && !isliving(attached)) ? TRUE : FALSE
	data["containerAttached"] = beaker ? TRUE : FALSE
	var/datum/reagents/drip_reagents = get_reagents()
	if(drip_reagents)
		data["containerCurrentVolume"] = round(drip_reagents.total_volume, IV_TRANSFER_RATE_STEP)
		data["containerMaxVolume"] = drip_reagents.maximum_volume
		data["containerReagentColor"] = mix_color_from_reagents(drip_reagents.reagent_list)
	data["isContainerRemovable"] = !istype(src, /obj/machinery/iv_drip/saline)
	return data

/obj/machinery/iv_drip/ui_act(action, params)
	if(..())
		return TRUE
	switch(action)
		if("changeMode")
			toggle_mode()
			return TRUE
		if("eject")
			eject_beaker()
			return TRUE
		if("detach")
			detach_iv()
			return TRUE
		if("changeRate")
			change_transfer_rate(text2num(params["rate"]))
			return TRUE

/// Sets the transfer rate to the provided value
/obj/machinery/iv_drip/proc/change_transfer_rate(var/new_rate)
	if(!beaker)
		return
	if(!attached)
		return
	if(!new_rate)
		return
	transfer_rate = round(clamp(new_rate, MIN_IV_TRANSFER_RATE, MAX_IV_TRANSFER_RATE), IV_TRANSFER_RATE_STEP)

/obj/machinery/iv_drip/obj_destruction()
	if(beaker)
		beaker.forceMove(drop_location())
		beaker.SplashReagents(drop_location())
		beaker.visible_message("<span class='notice'>[beaker] falls to the ground from the destroyed IV drip.</span>")
		beaker = null
	return ..()

/obj/machinery/iv_drip/update_icon_state()
	if(transfer_rate > 0)
		icon_state = "[base_icon_state]_[mode ? "injecting" : "donating"]"
	else
		icon_state = "[base_icon_state]_[mode ? "injectidle" : "donateidle"]"
	return ..()

/obj/machinery/iv_drip/update_overlays()
	. = ..()

	if(!beaker)
		return

	. += attached ? "beakeractive" : "beakeridle"
	var/datum/reagents/container_reagents = get_reagents()
	if(!container_reagents)
		return
	var/threshold = null
	for(var/i in 1 to fill_icon_thresholds.len)
		if(ROUND_UP(100 * container_reagents.total_volume / container_reagents.maximum_volume) >= fill_icon_thresholds[i])
			threshold = i
	if(threshold)
		var/fill_name = "[fill_icon_state][fill_icon_thresholds[threshold]]"
		var/mutable_appearance/filling = mutable_appearance(icon, fill_name)
		filling.color = mix_color_from_reagents(container_reagents.reagent_list)
		. += filling

/obj/machinery/iv_drip/MouseDrop(atom/target)
	. = ..()
	if(!Adjacent(target) || !usr.canUseTopic(src, be_close = TRUE))
		return
	if(!isliving(usr))
		to_chat(usr, "<span class='warning'>You can't do that!</span>")
		return
	if(!get_reagents())
		to_chat(usr, "<span class='warning'>There's nothing attached to the IV drip!</span>")
		return
	if(!target.reagents)
		to_chat(usr, "<span class='warning'>Target can't hold reagents!</span>")
		return
	if(attached)
		visible_message("<span class='warning'>[attached] is detached from [src].</span>")
		attached = null
		update_appearance(UPDATE_ICON)
	usr.visible_message("<span class='warning'>[usr] attaches [src] to [target].</span>", "<span class='notice'>You attach [src] to [target].</span>")
	attach_iv(target, usr)

/obj/machinery/iv_drip/attackby(obj/item/W, mob/user, params)
	if(is_type_in_typecache(W, drip_containers))
		if(beaker)
			to_chat(user, "<span class='warning'>There is already a reagent container loaded!</span>")
			return
		if(!user.transferItemToLoc(W, src))
			return
		beaker = W
		to_chat(user, "<span class='notice'>You attach [W] to [src].</span>")
		user.log_message("attached a [W] to [src] at [AREACOORD(src)] containing ([beaker.reagents.log_list()])", LOG_ATTACK)
		add_fingerprint(user)
		update_appearance(UPDATE_ICON)
		return
	else
		return ..()

/// Checks whether the IV drip transfer rate can be modified with AltClick
/obj/machinery/iv_drip/proc/can_use_alt_click(mob/user)
	if(!can_interact(user))
		return FALSE
	if(!attached)
		return FALSE
	if(!get_reagents())
		return FALSE
	return TRUE

/obj/machinery/iv_drip/AltClick(mob/user)
	if(!can_use_alt_click(user))
		return ..()
	if(transfer_rate > MIN_IV_TRANSFER_RATE)
		transfer_rate = MIN_IV_TRANSFER_RATE
	else
		transfer_rate = MAX_IV_TRANSFER_RATE
	investigate_log("was set to [transfer_rate] u/sec. by [key_name(user)]", INVESTIGATE_ATMOS)
	balloon_alert(user, "transfer rate set to [transfer_rate] u/sec.")
	update_appearance(UPDATE_ICON)

/obj/machinery/iv_drip/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/iron(loc)
	qdel(src)

/obj/machinery/iv_drip/process(delta_time)
	if(!attached)
		return PROCESS_KILL

	if(!(get_dist(src, attached) <= 1 && isturf(attached.loc)))
		if(isliving(attached))
			var/mob/living/attached_mob = attached
			to_chat(attached_mob, "<span class='userdanger'>The IV drip needle is ripped out of you!</span>")
			attached_mob.apply_damage(3, BRUTE, pick(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM))
			visible_message("<span class='warning'>[attached] is detached from [src].</span>")
		detach_iv()
		return PROCESS_KILL

	var/datum/reagents/drip_reagents = get_reagents()
	if(!drip_reagents)
		return PROCESS_KILL

	if(transfer_rate == 0)
		return

	// Give reagents
	if(mode)
		if(drip_reagents.total_volume)
			drip_reagents.trans_to(attached, transfer_rate * delta_time, method = INJECT, show_message = FALSE) //make reagents reacts, but don't spam messages
			update_appearance(UPDATE_ICON)

	// Take blood
	else if (isliving(attached))
		var/mob/living/attached_mob = attached
		var/amount = min(transfer_rate * delta_time, drip_reagents.maximum_volume - drip_reagents.total_volume)
		// If the beaker is full, ping
		if(!amount)
			transfer_rate = MIN_IV_TRANSFER_RATE
			visible_message("<span class='hear'>[src] pings.</span>")
			return

		// If the human is losing too much blood, beep.
		if(attached_mob.blood_volume < BLOOD_VOLUME_SAFE && prob(5))
			visible_message("<span class='hear'>[src] beeps loudly.</span>")
			playsound(loc, 'sound/machines/twobeep_high.ogg', 50, TRUE)
		var/atom/movable/target = beaker
		attached_mob.transfer_blood_to(target, amount)
		update_appearance(UPDATE_ICON)

/obj/machinery/iv_drip/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		return
	if(attached)
		visible_message("[attached] is detached from \the [src].")
		detach_iv()
		return
	else if(beaker)
		eject_beaker(user)
	else
		toggle_mode()

///called when an IV is attached
/obj/machinery/iv_drip/proc/attach_iv(atom/target, mob/user)
	if(isliving(target))
		user.visible_message("<span class='warning'>[usr] begins attaching [src] to [target]...</span>", "<span class='notice'>You begin attaching [src] to [target].</span>")
		if(!do_after(usr, 1 SECONDS, target))
			return
	else
		mode = IV_INJECTING
	usr.visible_message("<span class='warning'>[usr] attaches [src] to [target].</span>", "<span class='notice'>You attach [src] to [target].</span>")
	var/datum/reagents/container = get_reagents()
	log_combat(usr, target, "attached", src, "containing: ([container.log_list()])")
	add_fingerprint(usr)
	attached = target
	START_PROCESSING(SSmachines, src)
	update_appearance(UPDATE_ICON)

	SEND_SIGNAL(src, COMSIG_IV_ATTACH, target)

///Called when an iv is detached. doesnt include chat stuff because there's multiple options and its better handled by the caller
/obj/machinery/iv_drip/proc/detach_iv()
	if(attached)
		visible_message("<span class='notice'>[attached] is detached from [src].</span>")
	SEND_SIGNAL(src, COMSIG_IV_DETACH, attached)
	transfer_rate = MIN_IV_TRANSFER_RATE
	attached = null
	update_appearance(UPDATE_ICON)

/// Get the reagents used by IV drip
/obj/machinery/iv_drip/proc/get_reagents()
	return beaker?.reagents

/obj/machinery/iv_drip/verb/eject_beaker()
	set category = "Object"
	set name = "Remove IV Container"
	set src in view(1)

	if(!isliving(usr))
		to_chat(usr, "<span class='warning'>You can't do that!</span>")
		return

	if(usr.incapacitated())
		return
	if(beaker)
		if(attached)
			visible_message("<span class='notice'>[attached] is detached from [src].</span>")
			detach_iv()
		beaker.forceMove(drop_location())
		beaker = null
		update_appearance(UPDATE_ICON)

/obj/machinery/iv_drip/verb/toggle_mode()
	set category = "Object"
	set name = "Toggle Mode"
	set src in view(1)

	if(!isliving(usr))
		to_chat(usr, "<span class='warning'>You can't do that!</span>")
		return

	if(usr.incapacitated())
		return
	if(inject_only)
		if(!mode)
			update_appearance(UPDATE_ICON)
		mode = IV_INJECTING
		return
	// Prevent blood draining from non-living
	if(attached && !isliving(attached))
		if(!mode)
			update_appearance(UPDATE_ICON)
		mode = IV_INJECTING
		return
	mode = !mode
	transfer_rate = MIN_IV_TRANSFER_RATE
	to_chat(usr, "The IV drip is now [mode ? "injecting" : "taking blood"].")
	update_appearance(UPDATE_ICON)

/obj/machinery/iv_drip/examine(mob/user)
	. = ..()
	if(get_dist(user, src) > 2)
		return
	. += "[src] is [mode ? "injecting" : "taking blood"]."
	if(beaker)
		if(beaker.reagents && beaker.reagents.reagent_list.len)
			. += "<span class='notice'>[icon2html(beaker, user)] Attached is \a [beaker] with [beaker.reagents.total_volume] units of liquid.</span>"
		else
			. += "<span class='notice'>Attached is an empty [beaker.name].</span>"
	else
		. += "<span class='notice'>No chemicals are attached.</span>"

	. += "<span class='notice'>[attached ? attached : "Nothing"] is connected.</span>"
	if(!attached && !beaker)
		. += "<span class='notice'>A breath mask could be <b>attached</b> to it.</span>"

/obj/machinery/iv_drip/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(beaker)
		to_chat(user, "<span class='warning'>You need to remove the [beaker] first!</span>")
		return
	if(user.is_holding_item_of_type(/obj/item/clothing/mask/breath) && can_convert)
		visible_message("<span class='warning'>[user] attempts to attach the breath mask to [src].</span>", "<span class='notice'>You attempt to attach the breath mask to [src].</span>")
		if(!do_after(user, 100, FALSE, src))
			to_chat(user, "<span class='warning'>You fail to attach the breath mask to [src]!</span>")
			return
		var/item = user.is_holding_item_of_type(/obj/item/clothing/mask/breath)
		if(!item) // Check after the do_after as well
			return
		visible_message("<span class='warning'>[user] attaches the breath mask to [src].</span>", "<span class='notice'>You attach the breath mask to [src].</span>")
		qdel(item)
		new /obj/machinery/anesthetic_machine(loc)
		qdel(src)

/datum/crafting_recipe/iv_drip
	name = "IV drip"
	result = /obj/machinery/iv_drip
	time = 30
	tools = list(TOOL_SCREWDRIVER)
	reqs = list(
		/obj/item/stack/rods = 2,
		/obj/item/stack/sheet/plastic = 1,
		/obj/item/reagent_containers/syringe = 1,
	)
	category = CAT_MISC

/obj/machinery/iv_drip/saline
	name = "saline drip"
	desc = "An all-you-can-drip saline canister designed to supply a hospital without running out, with a scary looking pump rigged to inject saline into containers, but filling people directly might be a bad idea."
	icon_state = "saline"
	density = TRUE
	can_convert = FALSE
	inject_only = TRUE

/obj/machinery/iv_drip/saline/Initialize(mapload)
    . = ..()
    beaker = new /obj/item/reagent_containers/glass/saline(src)

/obj/machinery/iv_drip/saline/update_icon()
    return

/obj/machinery/iv_drip/saline/eject_beaker()
    return
/obj/machinery/iv_drip/saline/toggle_mode()
	return
#undef IV_TAKING
#undef IV_INJECTING

#undef MIN_IV_TRANSFER_RATE
#undef MAX_IV_TRANSFER_RATE
