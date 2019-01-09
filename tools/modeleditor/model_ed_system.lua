local ecs = ...
local world = ecs.world

-- runtime
ecs.import "render.camera.camera_component"
ecs.import "render.entity_rendering_system"
ecs.import "render.view_system"


-- lighting
ecs.import "render.light.light"

-- serialize
ecs.import "serialize.serialize_system"

-- scene
ecs.import "scene.cull_system"
ecs.import "scene.filter.filter_system"
ecs.import "scene.filter.lighting_filter"

-- animation
ecs.import "animation.skinning.skinning_system"
ecs.import "animation.animation"
ecs.import "animation.ik"

-- editor
ecs.import "editor.ecs.camera_controller"
ecs.import "editor.ecs.pickup_system"
ecs.import "editor.ecs.render.widget_system"

-- editor elements
ecs.import "editor.ecs.general_editor_entities"
ecs.import "editor.ecs.debug.debug_drawing"
ecs.import "tools.modeleditor.accessory_system"

local math = import_package "math"
local ms = math.stack
local util = require "tools.modeleditor.util"
local assetmgr = require "asset"
local fs = require "filesystem"
local camerautil = require "render.camera.util"

ecs.tag "sampleobj"

local model_ed_sys = ecs.system "model_editor_system"
model_ed_sys.singleton "debug_object"
model_ed_sys.singleton "timer"
model_ed_sys.depend "camera_init"

-- luacheck: globals main_dialog
-- luacheck: globals iup
local function get_ani_cursor(slider)
	assert(tonumber(slider.MIN) == 0)
	assert(tonumber(slider.MAX) == 1)
	return tonumber(slider.VALUE)
end

local function update_animation_ratio(eid, cursor_pos)
	local e = world[eid]	
	local anicomp = e.animation
	if anicomp then
		anicomp.ratio = cursor_pos
	end
end

local sample_eid

local function sample_entity()
	if sample_eid then
		return world[sample_eid]
	end
end

local function dlg_item(name)	
	return iup.GetDialogChild(main_dialog(), name)
end

local function enable_sample_visible()
	if sample_eid then
		local sample = world[sample_eid]
		if sample then
			local sample_shower = dlg_item("SHOWSAMPLE")
			sample.can_render = sample_shower.VALUE ~= "OFF"
		end
	end
end

local function enable_sample_boundingbox()
	local sample = sample_entity()
	if sample then
		local bounding = dlg_item("SHOWSAMPLEBOUNDING")
		sample.widget.can_render = bounding.VALUE ~= "OFF"
	end
end

local function enable_bones_visible()
	if sample_eid then
		local sample =world[sample_eid]
		if sample then
			local bone_shower = dlg_item("SHOWBONES")
			if bone_shower.VALUE ~= "OFF" then
				assert(sample.debug_skeleton == nil)
				world:add_component(sample_eid, "debug_skeleton")
			else
				if sample.debug_skeleton then
					world:remove_component(sample_eid, "debug_skeleton")
				end
			end
		end
	end
end

local function check_create_sample_entity(skepath, anipaths, smpath)
	local function check_path_valid(pp)
		if not assetmgr.find_valid_asset_path(pp) then
			iup.Message("Error", string.format("invalid path : %s", pp))
			return false
		end

		return true
	end

	-- only skinning meshpath is needed!
	if check_path_valid(smpath) then			
		if sample_eid then
			world:remove_entity(sample_eid)
		end

		sample_eid = util.create_sample_entity(world, skepath, anipaths, smpath)
		enable_sample_visible()
	end
end

local function get_sel_ani()
	local dlg = main_dialog()
	local aniview = iup.GetDialogChild(dlg, "ANIVIEW").owner
	return aniview:get()
end

local function update_static_duration_value()
	if sample_eid then
		local e = world[sample_eid]
		local ani = e.animation
		if ani then 
			local anipath = get_sel_ani()
			local anihandle = nil
			for _, ani in ipairs(ani.anilist) do
				if ani.ref_path == fs.path(anipath) then
					anihandle = ani.handle
				end
			end

			if anihandle then
				local duration = anihandle:duration()
				local dlg = main_dialog()
				local static_duration_value = iup.GetDialogChild(dlg, "STATIC_DURATION")
				static_duration_value.TITLE = string.format("Time(%.2f ms)", duration * 1000)
			else
				print("not found ani handle, select animation resource:%s", anipath)
			end
		end
	end
end

local function update_duration_text(cursorpos)		
	local dlg = main_dialog()
	local duration_value = iup.GetDialogChild(dlg, "DURATION")
	if duration_value == nil then
		return 
	end

	local sample = sample_entity()
	if sample == nil then
		return 
	end
	local anicomp = sample.animation
	if anicomp then
		local ani_assetinfo = anicomp.assetinfo
		if ani_assetinfo then
			local ani_handle = ani_assetinfo.handle
			local duration_pos = ani_handle:duration() * cursorpos
			duration_value.VALUE = string.format("%2f", duration_pos)
		end
	end
end

local function slider_value_chaged(slider)
	if sample_eid then
		local cursorpos = get_ani_cursor(slider)
		update_duration_text(cursorpos)
		update_animation_ratio(sample_eid, cursorpos)
	end
end

local function init_paths_ctrl()
	local dlg = main_dialog()

	--default value
	local skeinputer = iup.GetDialogChild(dlg, "SKEINPUTER").owner
	local sminputer = iup.GetDialogChild(dlg, "SMINPUTER").owner
	local aniview = iup.GetDialogChild(dlg, "ANIVIEW").owner

	local skepath = fs.path "meshes/skeleton/arm_skeleton.ozz"
	skeinputer:set_input(skepath:string())

	-- local smfilename = fs.path "meshes/mesh.ozz"	
	-- sminputer:set_input(smfilename:string())

	-- assert(aniview:count() == 0)
	-- aniview:add(fs.path "meshes/animation/animation1.ozz")
	-- aniview:add(fs.path "meshes/animation/animation2.ozz")
	
	local blender = iup.GetDialogChild(dlg, "BLENDER").owner
	aniview:set_blender(blender)

	local change_cb = function ()
		local skepath = fs.path(skeinputer:get_input())
		local smpath = fs.path(sminputer:get_input())

		local anipaths = {}
		for i=1, aniview:count() do
			anipaths[#anipaths+1] = fs.path(aniview:get(i))
		end
		check_create_sample_entity(skepath, anipaths, smpath)
	end

	skeinputer:add_changed_cb(change_cb)
	sminputer:add_changed_cb(change_cb)

	change_cb()
end

local function init_playitme_ctrl()
	local dlg = main_dialog()

	local slider = iup.GetDialogChild(dlg, "ANITIME_SLIDER")

	update_static_duration_value()

	local duration_value = iup.GetDialogChild(dlg, "DURATION")
	function duration_value:killfocus_cb()
		local duration = tonumber(self.VALUE)

		if sample_eid then
			local e = world[sample_eid]
			local anicomp = e.animation
			if anicomp then
				local anihandle = anicomp.assetinfo.handle
				local aniduration = anihandle:duration()
				local ratio = math.min(math.max(0, duration / aniduration), 1)
				anicomp.ratio = ratio
			end
		end
	end
	
	function slider:valuechanged_cb()
		slider_value_chaged(self)
	end

	slider_value_chaged(slider)

	local autoplay = iup.GetDialogChild(dlg, "AUTO_PLAY")
	function autoplay:action()
		local active = self.VALUE == "OFF" and "ON" or "OFF"
		duration_value.ACTIVE = active
		slider.ACTIVE = active
	end
end

local function init_check_shower()
	local checkers = {
		SHOWBONES=enable_bones_visible,
		SHOWSAMPLE=enable_sample_visible,
		SHOWSAMPLEBOUNDING=enable_sample_boundingbox,
	}

	for k, v in pairs(checkers) do
		local checker = dlg_item(k)
		checker.action = function () v() end
	end
end

local function init_res_ctrl()
	local dlg = main_dialog()
	local assetview = assert(iup.GetDialogChild(dlg, "ASSETVIEW").owner)

	assetview:init("project")
end

local function init_blend_ctrl()
	local dlg = main_dialog()
	local blender = dlg_item("BLENDER").owner
	blender:observer_blend("blend", function (blendlist, type)
		local sample = sample_entity()
		if sample then
			local anicomp = sample.animation
			if anicomp then

			end
		end
	end)
end

local function find_child(container, name)
	local child_count = iup.GetChildCount(container)
	if child_count == nil then
		return 
	end

	for ii=0, child_count - 1 do
		local c = iup.GetChild(container, ii)
		if c.NAME == name then
			return c
		end

		local cc = find_child(c, name)
		if cc then
			return cc
		end
	end				
end

local function update_ik_ctrl()
	local sample = sample_entity()
	if sample then
		local ik = sample.ik
		if ik then			
			local ikview = dlg_item("IKVIEW")
			local function update_vec_ctrl(ctrlname, ref)
				local ctrl = find_child(ikview, ctrlname).owner
				local v = ms(ref, "T")
				ctrl:x(v[1])
				ctrl:y(v[2])
				ctrl:z(v[3])
			end

			update_vec_ctrl("TARGET", ik.target)
			update_vec_ctrl("MID_AXIS", ik.mid_axis)
			update_vec_ctrl("POLE_VECTOR", ik.pole_vector)

			local weight = find_child(ikview, "WEIGHT")
			weight.VALUE = tostring(ik.weight)

			local soften = find_child(ikview, "SOFTEN")
			soften.VALUE = tostring(ik.soften)

			local twist_angle = find_child(ikview, "TWIST_ANGLE")
			twist_angle.VALUE = tostring(ik.twist_angle)

			local startjoint = find_child(ikview, "START_JOINT")
			startjoint.VALUE = tostring(ik.start_joint)

			local midjoint = find_child(ikview, "MID_JOINT")
			midjoint.VALUE = tostring(ik.mid_joint)

			local endjoint = find_child(ikview, "END_JOINT")
			endjoint.VALUE = tostring(ik.end_joint)
		end
	end
end

local function init_ik_ctrl()	
	local ikview = dlg_item("IKVIEW")

	local applybtn = iup.GetChild(ikview, 4)
	assert(applybtn.NAME=="APPLY")	
	function applybtn:action()
		local sample = sample_entity()
		if sample then
			local ik = sample.ik
			if ik then
				local function update_vec(name, ispoint, ref)					
					local ctrl = find_child(ikview, name).owner
					local tv = ctrl:get_vec()
					assert(#tv == 3)
					tv[4] = ispoint and 1 or 0
					ms(ref, tv, "=")
				end

				update_vec("TARGET", true, ik.target)
				update_vec("POLE_VECTOR", false, ik.pole_vector)
				update_vec("MID_AXIS", true, ik.mid_axis)

				local weight = find_child(ikview, "WEIGHT")
				ik.weight = tonumber(weight.VALUE)

				local soften = find_child(ikview, "SOFTEN")
				ik.soften = tonumber(soften.VALUE)

				local twist_angle = find_child(ikview, "TWIST_ANGLE")
				ik.twist_angle = tonumber(twist_angle.VALUE)

				local startjoint = find_child(ikview, "START_JOINT")
				ik.start_joint = tonumber(startjoint.VALUE)

				local midjoint = find_child(ikview, "MID_JOINT")
				ik.mid_joint = tonumber(midjoint.VALUE)

				local endjoint = find_child(ikview, "END_JOINT")
				ik.end_joint = tonumber(endjoint.VALUE)
			end
		end
	end
end

local function init_control()
	init_paths_ctrl()
	init_playitme_ctrl()
	init_check_shower()
	init_res_ctrl()
	init_blend_ctrl()
	init_ik_ctrl()
	iup.Map(main_dialog())
end

local function init_lighting()
	local lu = require "render.light.util"
	local leid = lu.create_directional_light_entity(world)
	local lentity = world[leid]
	local lightcomp = lentity.light
	lightcomp.color = {1,1,1,1}
	lightcomp.intensity = 2.0
	ms(lentity.rotation, {123.4, -34.22,-28.2}, "=")
end

local function focus_sample()
	if sample_eid then		
		if camerautil.focus_selected_obj(world, sample_eid) then
			return 
		end	
	end

	camerautil.focus_point(world, {0, 0, 0})
end

local function init_ik()
	local sample = sample_entity()
	if sample then
		assert(sample.ik == nil)
		local ske = assert(sample.skeleton)
		world:add_component(sample_eid, "ik")
		if sample.animation == nil then
			world:add_component(sample_eid, "animation")
			local aniutil = require "animation.util"
			aniutil.init_animation(sample.animation, ske)
		end
	
		local ik = sample.ik
		ik.enable = true
		ms(ik.target, {1, 2, 0, 1}, "=")
		ms(ik.pole_vector, {0, 1, 0, 0}, "=")
		ms(ik.mid_axis, {0, 0, 1, 0}, "=")
		ik.weight = 1.0
		ik.soften = 0.5
		ik.twist_angle = 0

		
		local skehandle = ske.assetinfo.handle
		ik.start_joint = skehandle:joint_index("shoulder")
		ik.mid_joint = skehandle:joint_index("forearm")
		ik.end_joint = skehandle:joint_index("wrist")
	end
end

-- luacheck: ignore self
function model_ed_sys:init()	
	init_control()
	init_lighting()

	init_ik()

	update_ik_ctrl()

	focus_sample()
end

local function auto_update_ani(deltatimeInSecond)
	local sample = sample_entity()
	if sample == nil then
		return
	end

	local ani = sample.animation
	if ani == nil then
		return
	end

	local dlg = main_dialog()
	local autoplay = iup.GetDialogChild(dlg, "AUTO_PLAY")
	if autoplay.VALUE ~= "OFF" then
		local anilist = ani.anilist
		if #anilist > 0 then
			local function update_ani_timer_ctrl(anihandle, ctrlname)
				local aniduration = anihandle:duration()

				local timerctrl = iup.GetDialogChild(dlg, ctrlname)
				local duration = tonumber(timerctrl.VALUE)
			
				local function calc_new_duration(duration, aniduration)
					local function is_number_equal(lhs, rhs)
						local delta = lhs - rhs
						local tolerance = 10e-6
						return -tolerance <= delta and delta <= tolerance
					end
					if is_number_equal(duration, aniduration) then
						return 0
					end
		
					local newduration = duration + deltatimeInSecond
					if newduration > aniduration then
						return aniduration
					end
					return newduration
				end
		
				local newduration = calc_new_duration(duration, aniduration)
			
				local ratio = math.min(math.max(0, newduration / aniduration), 1)
				ani.ratio = ratio
				timerctrl.VALUE = tostring(newduration)
			end

			update_ani_timer_ctrl(assert(anilist[1]).handle, "DURATION")
		end

	end
end

function model_ed_sys:update()
	local timer = self.timer
	auto_update_ani(timer.delta * 0.001)
end