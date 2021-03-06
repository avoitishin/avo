#!/bin/lua
--[[-- INFO -------------------------------------------------------------------
	File				: avo_debug_m
	Description : Debug functions and callbacks for most game events
	Credits		 	: aVo, Alundaio
	Revision		: 0.4
	Change Date : 07.29.2013
--]]---------------------------------------------------------------------------
--[[-- TODO -------------------------------------------------------------------
	1. luacap debug functionality
--]]---------------------------------------------------------------------------
--/----------------------------------------------------------------------------
--/ Variables
--/----------------------------------------------------------------------------
local sname = script_name()

local show_top_hud = false
local show_left_hud = false
local show_right_hud = false
local keybind_shift_key = DIK_keys.DIK_RCONTROL
local keybind_toggle_top_hud = DIK_keys.DIK_HOME
local keybind_toggle_left_hud = DIK_keys.DIK_DELETE
local keybind_toggle_right_hud = DIK_keys.DIK_END
local debug_hud_top = nil
local debug_hud_left = nil
local debug_hud_right = nil

local toggle_top_key = 4
local toggle_left_key = 3
local toggle_right_key = 5
local debug_huds = {
	"position_hud", 
	--[["corpse_hud",]]--
	"position_other_hud", 
	"squad_info_hud", 
	"stalker_info_hud", 
	"enemy_hud", 
	"planner_hud", 
	"wounded_hud", 
	"anim_hud", 
	--[["behavior_hud",]]-- 
	"weapon_hud",
	"stalker_data_hud"
}

local debug_god = false

local actions_by_stalker_ids = nil

--/----------------------------------------------------------------------------
--/ Module entry point.
--/----------------------------------------------------------------------------
function _init(ini)
	_G.callstack = this.callstack

	--/ Logging
	local printf_log = avo_utils.read_from_ini(ini,"logging","printf","bool",false)
	local debug_log = avo_utils.read_from_ini(ini,"logging","debug","bool",false)
	local warning_log = avo_utils.read_from_ini(ini,"logging","warning","bool",false)
	local error_log = avo_utils.read_from_ini(ini,"logging","error","bool",false)
	local visual_log = avo_utils.read_from_ini(ini,"logging","visual","bool",false)
	if debug_log then _G.dlog = avo_log.dlog end
	if warning_log then _G.wlog = avo_log.wlog end
	if error_log then _G.elog = avo_log.elog end
	if visual_log then _G.vlog = avo_log.vlog end
	if printf_log then _G.printf = avo_log.printf end
	
	--/ Debug
	local dev_debug = avo_utils.read_from_ini(ini,"debug","dev_debug","bool",false)
	local sim_debug = avo_utils.read_from_ini(ini,"debug","sim_debug","bool",false)
	if dev_debug then _G.dev_debug = true end
	if sim_debug then _G.sim_debug = true end
	
	--/ Debug HUD
	show_top_hud = avo_utils.read_from_ini(ini,"debug_hud","show_top_hud","bool",false)
	show_left_hud = avo_utils.read_from_ini(ini,"debug_hud","show_left_hud","bool",false)
	show_right_hud = avo_utils.read_from_ini(ini,"debug_hud","show_right_hud","bool",false)
	keybind_shift_key = DIK_keys["DIK_"..avo_utils.read_from_ini(ini,"debug_hud","keybind_shift_key","string","RCONTROL")]
	keybind_toggle_top_hud = DIK_keys["DIK_"..avo_utils.read_from_ini(ini,"debug_hud","keybind_toggle_top_hud","string","HOME")]
	keybind_toggle_left_hud = DIK_keys["DIK_"..avo_utils.read_from_ini(ini,"debug_hud","keybind_toggle_left_hud","string","DELETE")]
	keybind_toggle_right_hud = DIK_keys["DIK_"..avo_utils.read_from_ini(ini,"debug_hud","keybind_toggle_right_hud","string","END")]
	
	--/ Cheat
	debug_god = avo_utils.read_from_ini(ini,"cheat","god","bool",false)
	
	--/ Callbacks
	if avo_utils.read_from_ini(ini,"callbacks","enabled","bool",false) then init_slots() end
	
	build_actions() --/ build stalker action ids table
end

--/----------------------------------------------------------------------------
--/ Debug HUDs
--/----------------------------------------------------------------------------
--/----------------------------------------------------------------------------
--/ Actor position information
--/----------------------------------------------------------------------------
function position_hud_show(hud)
	local pos = db.actor:position()
	local cam
	if (pos:distance_to_sqr(device().cam_pos) > 25) then
		cam = true
		pos = device().cam_pos
	end

	local lvid = cam and level.vertex_id(pos) or db.actor:level_vertex_id()
	local gvid = cam and nil or db.actor:game_vertex_id()

	local dir = device().cam_dir
	local pos2 = level.vertex_position(lvid)
	local valid = pos2:distance_to(pos) <= 0.7

	local se_actor = not cam and alife():object(db.actor:id())

	hud:set_header("-[Actor Position Info]-")
	hud:add_msg("Lvid",lvid)
	hud:add_msg("Gvid",gvid)
	hud:add_msg("Pos",string.format("%0.4f, %0.4f, %0.4f", pos.x, pos.y, pos.z))
	hud:add_msg("Dir",string.format("%0.3f, %0.3f, %0.3f HP = %0.3f, %0.3f", dir.x, dir.y, dir.z,dir:getH(),dir:getP()))
	hud:add_msg("Angle",se_actor and se_actor.angle and string.format("%0.3f, %0.3f, %0.3f", se_actor.angle.x, se_actor.angle.y, se_actor.angle.z))
	hud:add_msg("Valid",valid)
	hud:add_msg("FOV",math.floor(device().fov))

	local Y, M, D, h, m, s, ms
	Y, M, D, h, m, s, ms = game.get_game_time():get( Y, M, D, h, m, s, ms )
	hud:add_msg("GameTime",string.format("Y:%d M:%d D:%d h:%d m:%d s:%d ms:%d",Y, M, D, h, m, s, ms))
	hud:display()
end
--/----------------------------------------------------------------------------
--/ Corpses information
--/----------------------------------------------------------------------------
function corpse_hud_show(hud)
	local corpses = release_body_manager.get_release_body_manager().release_objects_table
	local id, obj
	hud:set_header("-[Dead People]-")
	hud:add_msg("Count",#corpses)
	for i=1,#corpses do
		id = corpses[i].id
		obj = id and level.object_by_id(id)
		if (obj) then
			hud:add_msg("",obj:name().."  DeathTime = "..obj:death_time())
		end
	end
	
	hud:display()
end
--/----------------------------------------------------------------------------
--/ NPC position information
--/----------------------------------------------------------------------------
function position_other_hud_show(hud)
	local obj = avo_utils.get_target_npc() or avo_utils.get_nearest_stalker("cam",500)

	hud:set_header("-[NPC Position Info]-")
	if obj then
		local lvid, gvid = obj:level_vertex_id(), obj:game_vertex_id()
		local pos = obj:position()
		local dir = obj:direction()
		local angle = alife():object(obj:id()).angle
		local pos2 = level.vertex_position(lvid)
		local valid = pos2:distance_to(pos) <= 0.7

		hud:add_msg("Name",obj:name()) --/ object name is section_name..id
		local dist = level.get_target_dist and level.get_target_dist() --/ x-ray extensions
		if (dist) then
			hud:add_msg("Distance",string.format("%0.3f",dist))
		end
		hud:add_msg("Lvid",lvid)
		hud:add_msg("Gvid",gvid)
		hud:add_msg("Pos",string.format("%0.3f, %0.3f, %0.3f", pos.x, pos.y, pos.z))
		hud:add_msg("Dir",string.format("%0.3f, %0.3f, %0.3f HP (%0.3f, %0.3f)", dir.x, dir.y, dir.z,dir:getH(),dir:getP()))
		hud:add_msg("Angle",angle and string.format("%0.3f, %0.3f, %0.3f", angle.x, angle.y, angle.z))
		hud:display()
	end
end
--/----------------------------------------------------------------------------
--/ Squad information
--/----------------------------------------------------------------------------
function squad_info_hud_show(hud)
	local near = avo_utils.get_target_npc() or avo_utils.get_nearest_stalker("cam",500)
	if (near) then
		local squad = get_object_squad(near)
		if not(squad) then return end
		local smart = squad.smart_id and alife():object(squad.smart_id):name()
		local current_target = squad.current_target_id and alife():object(squad.current_target_id):name()
		local assigned_target = squad.assigned_target_id and alife():object(squad.assigned_target_id):name()

		hud:add_msg("Section Name", squad:section_name())
		hud:add_msg("ID", squad.id)
		hud:add_msg("Behavior Community", squad.player_id)
		hud:add_msg("Smart", smart)
		hud:add_msg("Current Target", current_target)
		hud:add_msg("Assigned Target", assigned_target)
	end
	hud:set_header("-[Squad Info]-")
	hud:display()
end
--/----------------------------------------------------------------------------
--/ Detailed stalker information
--/----------------------------------------------------------------------------
function stalker_info_hud_show(hud)
	local near = avo_utils.get_target_npc() or avo_utils.get_nearest_stalker("cam",500)

	local st = near and db.storage[near:id()]
	if (st) then
		local sobj = alife():object(near:id())

		hud:add_msg("Stalker Name",near:character_name())
		hud:add_msg("Section Name",sobj:section_name())
		hud:add_msg("ID",near:id())
		--hud:add_msg("Name",near:name())
		hud:add_msg("Community",character_community(near))
		hud:add_msg("Rank",ranks.get_obj_rank_name(near))
		hud:add_msg("Visual",near:get_visual_name())
		hud:add_msg("Health",math.floor(near.health*100))
		hud:add_msg("FOV",near:fov())
		hud:add_msg("Range",near:range())
		local sight_type = near:sight_params()
		hud:add_msg("Sight Type",sight_type and sight_type.m_sight_type)
		hud:add_msg("SID",get_object_story_id(near:id()))
		hud:add_msg("A.Scheme",st.active_scheme)
		hud:add_msg("A.Section",st.active_section)
		hud:add_msg("Logic",st.section_logic)
		hud:add_msg("Ini",st.ini_filename)

		local pt_index = near.get_current_point_index and near:get_current_point_index()
		if (not pt_index or pt_index == 4294967296 ) then
			pt_index = st.active_scheme and (st.active_scheme == "camper" or st.active_scheme == "beh") and avo_utils.load_var(near,"path_index",nil)
		end
		hud:add_msg("PT index",pt_index)
		--[[
		local smart = xr_gulag.get_npc_smart(near)
		if (smart) then
			local npc_job
			for k,v in pairs(smart.npc_info) do
				hud:add_msg("Job",smart.job_data[v.job_id].section)
			end
		end
		--]]
	end

	hud:set_header("-[Detailed Stalker Info]-")
	hud:display()
end
--/----------------------------------------------------------------------------
--/ NPC enemy information
--/----------------------------------------------------------------------------
function enemy_hud_show(hud)
	local near = avo_utils.get_target_npc() or avo_utils.get_nearest_stalker("cam",500)
	if (near) then
		local id = near:id()
		local se_obj = alife():object(id)
		local st = db.storage[id]
		if (st) then
			local be = near:best_enemy()
			hud:add_msg("Section Name", se_obj:section_name())
			local relation = { [game_object.enemy] = "enemy",
								[game_object.friend] = "friend",
								[game_object.neutral] = "neutral"
			}
			hud:add_msg("Actor Relation",relation[near:relation(db.actor)])

			if (st.overrides and st.overrides.combat_ignore) then
				hud:add_msg("CombatIgnoreCond",xr_logic.pick_section_from_condlist(be, near, st.overrides.combat_ignore.condlist))
			end

			hud:add_msg("Combat Type",st.script_combat_type)

			if (be) then
				hud:add_msg("Best Enemy",be and be:name())
			end

			local ene = st.enemy_id and level.object_by_id(st.enemy_id)
			if (ene) then
				hud:add_msg("Enemy",ene and ene:name())
			end

			local tg = time_global()
			if (st.post_combat_wait) then
				hud:add_msg("Post Combat Wait",st.post_combat_wait.timer and st.post_combat_wait.timer-tg)
			end

			hud:add_msg("Memory Time",be and tg - near:memory_time(be))

			local combat_inertion = be and tg - near:memory_time(be)
			hud:add_msg("Combat Inertion",combat_inertion)
			hud:add_msg("Search Time",st.combat_ignore and st.combat_ignore.search_time)
			hud:add_msg("Combat Run",st.combat_ignore and st.combat_ignore.combat_run)

			local squad = get_object_squad(near)
			local cid = squad and squad.id or id
			if (xr_combat_ignore.safe_zone_npcs and xr_combat_ignore.safe_zone_npcs[cid]) then
				hud:add_msg("In no-combat zone",tg-xr_combat_ignore.safe_zone_npcs[cid])
			end

			local bd = near:best_danger()

			if (bd) then
				local danger_types = {

					[danger_object.grenade] 		= "grenade",
					[danger_object.entity_corpse] 	= "entity_corpse",
					[danger_object.entity_attacked] = "entity_attacked",
					[danger_object.attacked] 		= "attacked",
					[danger_object.bullet_ricochet] = "bullet_ricochet",
					[danger_object.enemy_sound] 	= "enemy_sound",
					[danger_object.attack_sound] 	= "attack_sound",
					[danger_object.entity_death] 	= "entity_death",
					[danger_object.hit]				= "hit",
					[danger_object.sound]			= "sound",
					[danger_object.visual]			= "visual"
				}
				local bdname = bd:object() and bd:object():name()
				local bddname = bd:dependent_object() and bd:dependent_object():name()
				local bd_type = bd:type()

				hud:add_msg("Danger",bdname)
				hud:add_msg("Dependent",bddname)
				hud:add_msg("Type",danger_types[bd_type])
				hud:add_msg("DangerMode",st.danger_flag)
				hud:add_msg("Inertion",st.danger.inertion_time)
				if (xr_danger.DangerIgnore) then
					local src = xr_danger.DangerIgnore[danger_types[bd_type]]
					local ignore_distance = xr_logic.pick_section_from_condlist(db.actor,near,xr_logic.parse_condlist(near,danger_types[bd_type],"danger_object",src))
					ignore_distance = tonumber(ignore_distance)
					hud:add_msg("Ignore Distance",ignore_distance)
				end
				local scripted = xr_danger.is_danger_scripted and xr_danger.is_danger_scripted(near)
				hud:add_msg("Scripted",scripted)
			end
		end
	end
	hud:set_header("-[Stalker Enemy Info]-")
	hud:display()
end
--/----------------------------------------------------------------------------
--/ Planner information
--/----------------------------------------------------------------------------
function planner_hud_show(hud)
	local obj = avo_utils.get_target_npc() or avo_utils.get_nearest_stalker("cam",500)
	hud:set_header("-[Planner Info]-")
	if (obj) then
		local manager = obj.motivation_action_manager and obj:motivation_action_manager()
		if (manager) then
			local combat_action = manager:action(stalker_ids.action_combat_planner)
			local combat_action_planner = cast_planner(combat_action)

			hud:add_msg("Name",obj:name())

			local actid = manager:current_action_id()
			local name = actions_by_stalker_ids[actid] or "script"
			hud:add_msg("Mgr. Act",name)
			hud:add_msg("Mgr. Act ID",manager:current_action_id())

			actid = combat_action_planner:current_action_id()
			name = actions_by_stalker_ids[actid] or "script"
			hud:add_msg("Combat Act",name)
			hud:add_msg("Combat Act ID",combat_action_planner:current_action_id())

			local st = db.storage[obj:id()]
			if (st) then
				local sm = st.state_mgr
				if sm then --/ avo: crash "attempt to index local 'sm' (a nil value)"
					hud:add_msg("alife",sm.alife)
					hud:add_msg("combat",sm.combat)
					if (sm.eval_states) then
						hud:add_msg("Weapon Locked",post_combat_idle.weapon_locked(obj))
						hud:add_msg("Animstate Locked",sm.eval_states[sm.properties["animstate_locked"]])
						hud:add_msg("Animation Locked",sm.eval_states[sm.properties["animation_locked"]])
						hud:add_msg("Movement",sm.eval_states[sm.properties["movement"]])
						hud:add_msg("Animstate",sm.eval_states[sm.properties["animstate"]])
						hud:add_msg("Animation",sm.eval_states[sm.properties["animation"]])
						hud:add_msg("Smartcover",sm.eval_states[sm.properties["smartcover"]])
					end
				end
			end
		end
	end
	hud:display()
end
--/----------------------------------------------------------------------------
--/ Wounded information
--/----------------------------------------------------------------------------
function wounded_hud_show(hud)
	local obj = avo_utils.get_target_npc() or avo_utils.get_nearest_stalker("cam",500)
	hud:set_header("-[Wounded Info]-")
	if (obj) then
		hud:add_msg("Name",obj:name())
		local st = db.storage[obj:id()]
		if (st) then
			local tg = time_global()
			if (xr_wounded.is_wounded(obj)) then
				hud:add_msg("help_wounded helper id",st.wounded_already_selected)
			end

			if (st.help_wounded) then
				local vo = st.help_wounded.selected_id and level.object_by_id(st.help_wounded.selected_id)
				hud:add_msg("help_wounded Victim",vo and vo:name())
				hud:add_msg("help_wounded Vertex",st and st.help_wounded.vertex_id)
				hud:add_msg("help_wounded Stage",st and st.help_wounded.stage)
			end
			if (st.kill_wounded) then
				local vo = st.kill_wounded.current_id and level.object_by_id(st.kill_wounded.current_id)
				hud:add_msg("kill_wounded Victim",vo and vo:name())
				hud:add_msg("kill_wounded Timer",st.kill_wounded.timer and st.kill_wounded.timer - tg)
				hud:add_msg("kill_wounded Weapon",st.kill_wounded.weapon and st.kill_wounded.weapon:name())
			end

			if (st.victim_surrender) then
				local po = level.object_by_id(st.victim_surrender)
				hud:add_msg("Surrender to",po and po:name())
			end
		end
	end
	hud:display()
end
--/----------------------------------------------------------------------------
--/ Animation information
--/----------------------------------------------------------------------------
function anim_hud_show(hud)
	local near = avo_utils.get_target_npc() or avo_utils.get_nearest_stalker("cam",500)
	if (near) then
		local st = db.storage[near:id()]
		if (st) then
			local sobj = alife():object(near:id())

			if (st.active_scheme == "animpoint") then
				local avail_animations = ""
				if st and st.animpoint then
					if st.animpoint.avail_animations then
						for k, v in pairs(st.animpoint.avail_animations) do
							avail_animations = avail_animations .. "," .. v
						end
					end

					local approved_actions = ""
					local description = st and st.animpoint and st.animpoint.description
					local avail_actions = description and xr_animpoint_predicates.associations[description]
					local actions = ""
					if avail_actions then
						for k,v in pairs(avail_actions) do
							if (v.predicate(near:id(), st.animpoint.use_camp)) then
								approved_actions = v.name .. ", " .. approved_actions
							end
							actions = v.name .. ", " .. actions
						end
					end

					hud:add_msg("Section Name",sobj:section_name())
					hud:add_msg("Avail. Animations",avail_animations)
					hud:add_msg("Avail. Actions",actions)
					hud:add_msg("Approved Actions",approved_actions)
					hud:add_msg("Cover Name",st.animpoint.cover_name)
					hud:add_msg("Use Camp",st.animpoint.use_camp)
					hud:add_msg("Description",description)
					hud:add_msg("Smart Direction",st.animpoint.smart_direction and avo_utils.vector_to_string(st.animpoint.smart_direction))
				end
			elseif (st.active_scheme == "walker") then
				local avail_actions = xr_animpoint_predicates.associations["walker_camp"]
				local actions = ""
				local approved_actions = ""
				if avail_actions then
					for k,v in pairs(avail_actions) do
						actions = actions .. "," .. v.name
						if (v.predicate(near:id())) then
							approved_actions = v.name .. "," .. approved_actions
						end
					end
				end

				hud:add_msg("Section Name",sobj:section_name())
				hud:add_msg("Use Camp",st and st.walker and st.walker.use_camp)
				hud:add_msg("Avail. Actions",actions)
				hud:add_msg("Approved Actions",approved_actions)
				hud:add_msg("Def. State Mov.",st and st.walker and st.walker.suggested_state.moving)
				hud:add_msg("Def. State Stand.", st and st.walker and st.walker.suggested_state.standing)
			end

			hud:add_msg("In Cover",near:in_smart_cover())

			local cover = near:get_dest_smart_cover_name()
			hud:add_msg("Dest Cover",cover)
			hud:add_msg("UseSmartCoverOnly",near:use_smart_covers_only())
		end
	end
	hud:set_header("-[Animation Info]-")
	hud:display()
end
--/----------------------------------------------------------------------------
--/ Behavior information (not functional in vanilla, probably meant for alundaio's)
--/ custom behaviors
--/----------------------------------------------------------------------------
function behavior_hud_show(hud)
	local near = avo_utils.get_target_npc() or avo_utils.get_nearest_stalker("cam",500)
	if (near) then
		-- local st = db.storage[near:id()].beh
		local st = db.storage[near:id()]
		if (st) then
			local target = st.desired_target and st.desired_target.object and st.desired_target.object:name()
			local target_type = st.target
			local pos = st.desired_target and st.desired_target.position and vec_to_str(st.desired_target.position)
			local beh = st.desired_behavior
			local assist_pt = st.assist_point
			local state = st.last_state

			hud:add_msg("Target",target)
			hud:add_msg("Type",target_type)
			hud:add_msg("Pos",pos)
			hud:add_msg("Behavior",beh)
			hud:add_msg("Assist Pt",assist_pt)
			hud:add_msg("State",state)
			hud:add_msg("State",state)
			st = db.storage[near:id()]
			hud:add_msg("PT Index",st.beh and st.beh.path_index)
			hud:add_msg("PT wait",st.beh and st.beh.wait_delay and st.beh.wait_delay - time_global())
			hud:add_msg("PT reached",st.beh and st.beh.am_i_reached ~= nil)
			-- hud:add_msg("Gather Items",st.gather_items and st.gather_items.gather_items_enabled and xr_logic.pick_section_from_condlist(db.actor, near, st.gather_items.gather_items_enabled))
			-- hud:add_msg("Loot Corpses",st.corpse_detection and st.corpse_detection.corpse_detection_enabled and xr_logic.pick_section_from_condlist(db.actor, near, st.corpse_detection.corpse_detection_enabled))
		end
	end
	hud:set_header("-[Behavior Info]-")
	hud:display()
end
--/----------------------------------------------------------------------------
--/ Weapon information
--/----------------------------------------------------------------------------
function weapon_hud_show(hud)
	local near = avo_utils.get_target_npc() or avo_utils.get_nearest_stalker("cam",500)
	local wpn
	if (near) then
		wpn = near:active_item()
	else
		near = db.actor
		wpn = db.actor:active_item()
	end

	if (wpn == nil or not avo_utils.item_is_fa(wpn)) then
		hud:clear()
		return
	end

	local sobj = alife():object(wpn:id())
	local pk = get_netpk(sobj) --/ get netpacket
	local data = nil
	if pk:isOk() then data = pk:get() end	--/ read from netpacket

	if (wpn and data) then
		local sec = wpn:section()
		hud:add_msg("Weapon",sec)
		hud:add_msg("Visual",data.visual_name)
		hud:add_msg("Visual Flag",data.visual_flags)
		local ef_main_weapon_type = avo_utils.read_from_ini(nil,sec,"ef_main_weapon_type","string","nil")
		hud:add_msg("ef_main_weapon_type",ef_main_weapon_type)
		local ef_weapon_type = avo_utils.read_from_ini(nil,sec,"ef_weapon_type","string","nil")
		hud:add_msg("ef_weapon_type",ef_weapon_type)
		hud:add_msg("Condition",data.condition and math.floor(data.condition*100))
		hud:add_msg("Upgrades",data.upgrades)
		hud:add_msg("Weapon State",data.weapon_state)
		hud:add_msg("AmmoCurrent",data.ammo_current)
		hud:add_msg("AmmoClip",data.ammo_elapsed)
		hud:add_msg("AddonFlag",data.addon_flags)
		hud:add_msg("AmmoType",data.ammo_type)
		hud:add_msg("XZ1",data.xz1)
	end

	hud:set_header("-[Weapon Info]-")
	hud:display()
end
--/----------------------------------------------------------------------------
--/ Stalker data
--/----------------------------------------------------------------------------
local stalker_id
local stalker_data = {}
function stalker_data_hud_show(hud)
	local obj = avo_utils.get_target_npc() or avo_utils.get_nearest_stalker("cam",500)
	hud:set_header("-[Stalker Packet Data]-")
	if (obj) then
		if (stalker_id ~= obj:id()) then
			stalker_id = obj:id()
			local se_obj = alife():object(stalker_id)
			avo_utils.switch_offline(se_obj.id)
			local pk = get_netpk(se_obj)
			if pk:isOk() then stalker_data = pk:get() end
			avo_utils.switch_online(se_obj.id)
		end
		-- hud:add_msg("cse_alife_object:",'')
		-- hud:add_msg("   Story ID",stalker_data.story_id)
		-- hud:add_msg("   Spawn Story ID",stalker_data.spawn_story_id)
		
		
		hud:add_msg("Character Name",stalker_data.checked_characters)
		hud:add_msg("Spec Char",stalker_data.specific_character)
		hud:add_msg("Profile",stalker_data.character_profile)
		hud:add_msg("Money",stalker_data.money)
		hud:add_msg("Community Index",stalker_data.community_index)
		hud:add_msg("Reputation",stalker_data.reputation)
		hud:add_msg("Rank",stalker_data.rank)
		hud:add_msg("trader_unk2_u8",stalker_data.cse_alife_trader_abstract__unk2)
		hud:add_msg("trader_unk3_u8",stalker_data.cse_alife_trader_abstract__unk3)
		hud:add_msg("distance",stalker_data.distance)
		hud:add_msg("direct_control",stalker_data.direct_control)
		-- hud:add_msg("unk3_u32",stalker_data.cse_alife_object__unk3_u32)
		hud:add_msg("Skeleton",stalker_data.skeleton_name)
		hud:add_msg("Skel. Flag",stalker_data.skeleton_flag)
		hud:add_msg("Source ID",stalker_data.source_id)
		if type(stalker_data.custom_data) == "string" then
			hud:add_msg("Custom Data",stalker_data.custom_data)
		else
			hud:add_msg("Custom Data",avo_table.hash_size(stalker_data.custom_data))
			for k,v in pairs(stalker_data.custom_data) do
				hud:add_msg("   %s:%s",k,v,'')
			end
		end
		hud:add_msg("Visual",stalker_data.visual_name)
		hud:add_msg("Vis. Flags",stalker_data.visual_flags)
		hud:add_msg("team,squad,group",string.format("%d, %d, %d", stalker_data.g_team, stalker_data.g_squad, stalker_data.g_group))
		
		--[[
		hud:add_msg("Out Rest.",#stalker_data.dynamic_out_restrictions)
		for k,v in ipairs(stalker_data.dynamic_out_restrictions) do
			hud:add_msg(k,v)
		end
		hud:add_msg("In Rest.",#stalker_data.dynamic_in_restrictions)
		for k,v in ipairs(stalker_data.dynamic_in_restrictions) do
			hud:add_msg(k,v)
		end
		--]]
		
		hud:add_msg("Equip. Pref.",#stalker_data.equipment_preferences)
		for k,v in ipairs(stalker_data.equipment_preferences) do
			hud:add_msg(k,v)
		end
		hud:add_msg("Weapon Pref.",#stalker_data.main_weapon_preferences)
		for k,v in ipairs(stalker_data.main_weapon_preferences) do
			hud:add_msg(k,v)
		end
		hud:add_msg("Out Rest.",stalker_data.base_out_restrictors)
		hud:add_msg("In Rest.",stalker_data.base_in_restrictors)
	end
	hud:display()
end

--/----------------------------------------------------------------------------
--/ Build call stack trace 
--/----------------------------------------------------------------------------
function callstack()
	local	t = {}
	if debug then
		t = avo_string.split(debug.traceback(), '\n', true)
		for k,v in pairs(t) do
			if string.match(v, "stack traceback") then 
				next(t)
			else
				t[k] = string.format("[%d] %s", k-1, string.gsub(string.gsub(v, ".+\\", ""), ">", ""))
			end
		end
	end
	return t
end

--/----------------------------------------------------------------------------
--/ Callback subscribers
--/----------------------------------------------------------------------------
function init_slots()
	--/ avo_controller
  slot("avo_game_start", on_avo_game_start)
	--/ bind_stalker
  slot("actor_init", on_actor_init)
  slot("actor_net_spawn", on_actor_net_spawn)
  slot("actor_net_destroy", on_actor_net_destroy)
  slot("actor_reinit", on_actor_reinit)
  slot("actor_update", on_actor_update)
  slot("actor_save", on_actor_save)
  slot("actor_load", on_actor_load)
	
	slot("actor_take_item_from_box", on_actor_take_item_from_box)
	slot("actor_info_callback", on_actor_info_callback)
	slot("actor_on_trade", on_actor_on_trade)
	slot("actor_article_callback", on_actor_article_callback)
	slot("actor_on_item_take", on_actor_on_item_take)
	slot("actor_on_item_drop", on_actor_on_item_drop)
	slot("actor_use_inventory_item", on_actor_use_inventory_item)
	slot("actor_anabiotic_callback", on_actor_anabiotic_callback)
	slot("actor_anabiotic_callback2", on_actor_anabiotic_callback2)
	slot("actor_task_callback", on_actor_task_callback)
	
	slot("actor_hit_callback", on_actor_hit_callback)
	slot("actor_on_key", on_actor_on_key)
	
	--/ xr_motivator
	slot("stalker_net_spawn", on_stalker_net_spawn)
	slot("stalker_net_destroy", on_stalker_net_destroy)
end

--/----------------------------------------------------------------------------
--/ Callbacks
--/----------------------------------------------------------------------------
function on_avo_game_start()
  dlog("AVO GAME STARTED")
end

--/----------------------------------------------------------------------------
--/ bind_stalker callbacks
--/----------------------------------------------------------------------------
function on_actor_init(actor_binder)
	dlog("actor_binder.__init(obj) called")
end

function on_actor_net_spawn(data)
	dlog("actor_binder.net_spawn(data) called")
	
	--/ Setup debug huds
	if show_top_hud then debug_hud_top = hud_tool("debug_hud_top") end
	if show_left_hud then debug_hud_left = hud_tool("debug_hud_left") end
	if show_right_hud then debug_hud_right = hud_tool("debug_hud_right") end
	
end

function on_actor_net_destroy()
	dlog("actor_binder.net_destroy() called")
end

function on_actor_reinit()
	dlog("actor_binder.reinit() called")
end

function on_actor_update(delta)
	-- dlog("actor_binder.update(delta) called")
	
	--/ Update debug hud displays
	if show_top_hud then
		_G["avo_debug_m"][debug_huds[toggle_top_key].."_show"](debug_hud_top)
	end
	if show_right_hud then
		_G["avo_debug_m"][debug_huds[toggle_right_key].."_show"](debug_hud_right)
	end
	if show_left_hud then
		_G["avo_debug_m"][debug_huds[toggle_left_key].."_show"](debug_hud_left)
	end
	
	--/ God mode
	if debug_god then
		db.actor.health = 1
		db.actor.bleeding = 0
		db.actor.psy_health = 1
		db.actor.radiation = 0
		db.actor.power = 1
	end
end

function on_actor_save(packet)
	dlog("actor_binder.save(packet) called")
end

function on_actor_load(reader)
	dlog("actor_binder.load(reader) called")
end

function actor_take_item_from_box(box, item)
	dlog("actor_binder.take_item_from_box(box, item) called")
end

function on_actor_info_callback(npc, info_id)
	dlog("actor_binder.info_callback(npc, info_id) called")
end

function on_actor_on_trade(item, sell_bye, money)
	dlog("actor_binder.on_trade(item, sell_bye, money) called")
end

function on_actor_article_callback(npc, group, name)
	dlog("actor_binder.article_callback(npc, group, name) called")
end

function on_actor_on_item_take(obj)
	dlog("actor_binder.on_item_take(obj) called")
end

function on_actor_on_item_drop(obj)
	dlog("actor_binder.on_item_drop(obj) called")
end

function on_actor_use_inventory_item(obj)
	dlog("actor_binder.use_inventory_item(obj) called")
end

function on_actor_anabiotic_callback()
	dlog("actor_binder.anabiotic_callback() called")
end

function on_actor_anabiotic_callback2()
	dlog("actor_binder.anabiotic_callback2() called")
end

function on_actor_task_callback(_task, _state)
	dlog("actor_binder.task_callback(_task, _state) called")
end

function on_actor_hit_callback(obj, amount, local_direction, who, bone_index)
	-- dlog("actor_binder.hit_callback(obj, amount, local_direction, who, bone_index) called")
	-- if debug_god then
		-- if amount > 0 and math.floor(obj.health*100) < 70 then
			-- db.actor.health = 1
		-- end
	-- end
end

local prev_key = nil
function on_actor_on_key(key)
	--/ Toggle debug hud displays
	if key == keybind_toggle_top_hud and prev_key == keybind_shift_key then
		if toggle_top_key < #debug_huds then
			toggle_top_key = toggle_top_key + 1
		else
			toggle_top_key = 1
		end
	elseif key == keybind_toggle_left_hud and prev_key == keybind_shift_key then
		if toggle_left_key < #debug_huds then
			toggle_left_key = toggle_left_key + 1
		else
			toggle_left_key = 1
		end
	elseif key == keybind_toggle_right_hud and prev_key == keybind_shift_key then
		if toggle_right_key < #debug_huds then
			toggle_right_key = toggle_right_key + 1
		else
			toggle_right_key = 1
		end
	end
	prev_key = key
end

--/----------------------------------------------------------------------------
--/ xr_motivator callbacks
--/----------------------------------------------------------------------------
function on_stalker_net_spawn(motivator_binder, se_object)
	dlog("motivator_binder.net_spawn(sobject) called")
end

function on_stalker_net_destroy(motivator_binder)
	dlog("motivator_binder.net_destroy() called")
end


--/----------------------------------------------------------------------------
--/ Class to create hud tools
--/----------------------------------------------------------------------------
class "hud_tool"
function hud_tool:__init(custom_static)
	local hud = get_hud()
	self.hud = hud:GetCustomStatic(custom_static)
	if not (self.hud) then
		hud:AddCustomStatic(custom_static, true)
		self.hud = hud:GetCustomStatic(custom_static)
	end
	self.header = ""
	self.msg = ""
end

function hud_tool:add_msg(text,value)
	self.msg = self.msg..avo_string.str_format(text..": %s\\n",value)
end

function hud_tool:set_header(header)
	self.header = header
end

function hud_tool:display(disable)
	if (self.hud) and not (disable) then
		self.hud:wnd():TextControl():SetText(self.msg)
		self.msg = self.header and self.header .."\\n" or ""
	end
end

function hud_tool:clear()
	if (self.hud) then
		self.hud:wnd():TextControl():SetText("")
	end
end


--/----------------------------------------------------------------------------
--/ Build stalker actions table (from lua_help and xr_actions_id)
--/----------------------------------------------------------------------------
function build_actions()
	actions_by_stalker_ids = {}
	for k,v in pairs(_G.xr_actions_id) do
		actions_by_stalker_ids[v] = k
	end
	actions_by_stalker_ids[7] = "action_accomplish_task"
	actions_by_stalker_ids[16] = "action_aim_enemy"
	actions_by_stalker_ids[88] = "action_alife_planner"
	actions_by_stalker_ids[90] = "action_anomaly_planner"
	actions_by_stalker_ids[89] = "action_combat_planner"
	actions_by_stalker_ids[9] = "action_communicate_with_customer"
	actions_by_stalker_ids[36] = "action_critically_wounded"
	actions_by_stalker_ids[73] = "action_danger_by_sound_planner"
	actions_by_stalker_ids[85] = "action_danger_grenade_look_around"
	actions_by_stalker_ids[72] = "action_danger_grenade_planner"
	actions_by_stalker_ids[86] = "action_danger_grenade_search"
	actions_by_stalker_ids[82] = "action_danger_grenade_take_cover"
	actions_by_stalker_ids[84] = "action_danger_grenade_take_cover_after_explosion"
	actions_by_stalker_ids[83] = "action_danger_grenade_wait_for_explosion"
	actions_by_stalker_ids[80] = "action_danger_in_direction_detour"
	actions_by_stalker_ids[79] = "action_danger_in_direction_hold_position"
	actions_by_stalker_ids[78] = "action_danger_in_direction_look_out"
	actions_by_stalker_ids[71] = "action_danger_in_direction_planner"
	actions_by_stalker_ids[81] = "action_danger_in_direction_search"
	actions_by_stalker_ids[77] = "action_danger_in_direction_take_cover"
	actions_by_stalker_ids[91] = "action_danger_planner"
	actions_by_stalker_ids[75] = "action_danger_unknown_look_around"
	actions_by_stalker_ids[70] = "action_danger_unknown_planner"
	actions_by_stalker_ids[76] = "action_danger_unknown_search"
	actions_by_stalker_ids[74] = "action_danger_unknown_take_cover"
	actions_by_stalker_ids[0] = "action_dead"
	actions_by_stalker_ids[87] = "action_death_planner"
	actions_by_stalker_ids[25] = "action_detour_enemy"
	actions_by_stalker_ids[1] = "action_dying"
	actions_by_stalker_ids[15] = "action_find_ammo"
	actions_by_stalker_ids[13] = "action_find_item_to_kill"
	actions_by_stalker_ids[2] = "action_gather_items"
	actions_by_stalker_ids[24] = "action_get_distance"
	actions_by_stalker_ids[12] = "action_get_item_to_kill"
	actions_by_stalker_ids[17] = "action_get_ready_to_kill"
	actions_by_stalker_ids[23] = "action_hold_position"
	actions_by_stalker_ids[19] = "action_kill_enemy"
	actions_by_stalker_ids[29] = "action_kill_enemy_if_not_visible"
	actions_by_stalker_ids[37] = "action_kill_if_enemy_critically_wounded"
	actions_by_stalker_ids[35] = "action_kill_if_player_on_the_path"
	actions_by_stalker_ids[33] = "action_kill_wounded_enemy"
	actions_by_stalker_ids[22] = "action_look_out"
	actions_by_stalker_ids[14] = "action_make_item_killing"
	actions_by_stalker_ids[3] = "action_no_alife"
	actions_by_stalker_ids[34] = "action_post_combat_wait"
	actions_by_stalker_ids[32] = "action_prepare_wounded_enemy"
	actions_by_stalker_ids[8] = "action_reach_customer_location"
	actions_by_stalker_ids[6] = "action_reach_task_location"
	actions_by_stalker_ids[30] = "action_reach_wounded_enemy"
	actions_by_stalker_ids[20] = "action_retreat_from_enemy"
	actions_by_stalker_ids[92] = "action_script"
	actions_by_stalker_ids[26] = "action_search_enemy"
	actions_by_stalker_ids[4] = "action_smart_terrain_task"
	actions_by_stalker_ids[5] = "action_solve_zone_puzzle"
	actions_by_stalker_ids[28] = "action_sudden_attack"
	actions_by_stalker_ids[21] = "action_take_cover"
	actions_by_stalker_ids[95] = "script_combat_planner"
	actions_by_stalker_ids[96] = "reach_task_location"
	actions_by_stalker_ids[142] = "corpse_exist"
	actions_by_stalker_ids[147] = "wounded_exist"
	actions_by_stalker_ids[192] = "state_mgr"
	actions_by_stalker_ids[193] = "state_mgr_to_idle_combat"
	actions_by_stalker_ids[194] = "state_mgr_to_idle_alife"
	actions_by_stalker_ids[195] = "state_mgr_to_idle_items"
	actions_by_stalker_ids[307] = "smartcover_action"
	actions_by_stalker_ids[343] = "meet_contact"
	actions_by_stalker_ids[3865] = "action_walker"
	actions_by_stalker_ids[188112] = "kill_wounded"
	actions_by_stalker_ids[188111] = "beh"
	actions_by_stalker_ids[90005] = "gather_items"
end
