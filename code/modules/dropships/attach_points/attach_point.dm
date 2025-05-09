/// The bases onto which you attach dropship equipments.
/obj/effect/attach_point
	name = "equipment attach point"
	desc = "A place where heavy equipment can be installed with a powerloader."
	icon = 'icons/obj/structures/props/almayer_props.dmi'
	icon_state = "equip_base"
	unacidable = TRUE
	anchored = TRUE
	layer = ABOVE_TURF_LAYER
	plane = GAME_PLANE
	/// The currently installed equipment, if any
	var/obj/structure/dropship_equipment/installed_equipment
	/// What kind of equipment this base accepts
	var/base_category
	/// Identifier used to refer to the dropship it belongs to
	var/ship_tag
	/// Static numbered identifier for singular attach points
	var/attach_id
	/// Relative position of the attach_point alongside dropship transverse
	var/transverse = NONE
	/// Relative position alongside longitudinal axis
	var/long = NONE

/obj/effect/attach_point/Destroy()
	QDEL_NULL(installed_equipment)
	return ..()

/obj/effect/attach_point/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/powerloader_clamp))
		var/obj/item/powerloader_clamp/clamp = I
		install_equipment(clamp, user)
		return TRUE
	return ..()

/// Called when a real user with a powerloader attempts to install an equipment on the attach point
/obj/effect/attach_point/proc/install_equipment(obj/item/powerloader_clamp/clamp, mob/living/user)
	if(!istype(clamp.loaded, /obj/structure/dropship_equipment))
		return
	var/obj/structure/dropship_equipment/ds_equipment = clamp.loaded
	if(!(base_category in ds_equipment.equip_categories))
		to_chat(user, SPAN_WARNING("[ds_equipment] doesn't fit on [src]."))
		return
	if(installed_equipment)
		return
	playsound(loc, 'sound/machines/hydraulics_1.ogg', 40, TRUE)
	var/point_loc = loc
	if(!user || !do_after(user, (7 SECONDS) * user.get_skill_duration_multiplier(SKILL_ENGINEER), INTERRUPT_NO_NEEDHAND|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
		return
	if(loc != point_loc)//dropship flew away
		return
	if(installed_equipment || clamp.loaded != ds_equipment)
		return
	to_chat(user, SPAN_NOTICE("You install [ds_equipment] on [src]."))
	ds_equipment.forceMove(loc)
	clamp.loaded = null
	playsound(loc, 'sound/machines/hydraulics_2.ogg', 40, TRUE)
	clamp.update_icon()
	installed_equipment = ds_equipment
	ds_equipment.ship_base = src
	ds_equipment.plane = plane

	for(var/obj/docking_port/mobile/marine_dropship/shuttle in SSshuttle.mobile)
		if(shuttle.id == ship_tag)
			ds_equipment.linked_shuttle = shuttle
			SEND_SIGNAL(shuttle, COMSIG_DROPSHIP_ADD_EQUIPMENT, ds_equipment)
			break

	ds_equipment.update_equipment()

/// Weapon specific attachment point
/obj/effect/attach_point/weapon
	name = "weapon system attach point"
	icon_state = "equip_base_front"
	base_category = null
	layer = ABOVE_OBJ_LAYER
	var/firing_arc_min
	var/firing_arc_max

/// Get base allowed offsets for the attach point
/obj/effect/attach_point/weapon/proc/get_offsets()
	return list(
		"min" = transverse + firing_arc_min,
		"max" = transverse + firing_arc_max
	)
