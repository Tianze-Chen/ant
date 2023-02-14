local ecs           = ...
local world         = ecs.world
local w             = world.w
local math3d        = require "math3d"

local ientity       = ecs.import.interface "ant.render|ientity"
local imaterial     = ecs.import.interface "ant.asset|imaterial"
local imesh         = ecs.import.interface "ant.asset|imesh"
local iom           = ecs.import.interface "ant.objcontroller|iobj_motion"
local irl           = ecs.import.interface "ant.render|irender_layer"

local assetmgr      = import_package "ant.asset"

local mathpkg       = import_package"ant.math"
local mc, mu        = mathpkg.constant, mathpkg.util

local renderpkg     = import_package "ant.render"
local declmgr       = renderpkg.declmgr

local init_loader_sys   = ecs.system 'init_loader_system'

local printer
local printer_material
local function point_light_test()
    local pl_pos = {
        {  1, 0, 1},
        { -1, 0, 1},
        { -1, 0,-1},
        {  1, 0,-1},
        {  1, 2, 1},
        { -1, 2, 1},
        { -1, 2,-1},
        {  1, 2,-1},

        {  3, 0, 3},
        { -3, 0, 3},
        { -3, 0,-3},
        {  3, 0,-3},
        {  3, 2, 3},
        { -3, 2, 3},
        { -3, 2,-3},
        {  3, 2,-3},
    }

    for _, p in ipairs(pl_pos) do
        local  pl = ecs.create_instance  "/pkg/ant.test.features/assets/entities/light_point.prefab"[1]
        pl.on_ready = function()
            iom.set_position(pl.root, p)
        end
        world:create_object(pl)
    end

    local ce = ecs.create_instance  "/pkg/ant.test.features/assets/entities/pbr_cube.prefab"[1]
    ce.on_ready = function ()
        iom.set_position(ce.root, {0, 0, 0, 1})
    end
    world:create_object(ce)
    

    ecs.create_instance  "/pkg/ant.test.features/assets/entities/light_directional.prefab"
end

local function create_texture_plane_entity(color, tex, tex_rect, tex_size)
    local m = imesh.init_mesh(ientity.plane_mesh(mu.texture_uv(tex_rect, tex_size)))
    m.vb.owned = true
    return ecs.create_entity{
        policy = {
            "ant.render|simplerender",
            "ant.general|name",
        },
        data = {
            name = "test_texture_plane",
            simplemesh = m,
            owned_mesh_buffer = true,
            material = "/pkg/ant.resources/materials/texture_plane.material",
            visible_state= "main_view",
            render_layer = "background",
            scene   = { srt = {t={0, 5, 5}}},
            on_ready = function (e)
                imaterial.set_property(e, "u_basecolor_factor", math3d.vector(color))
                local texobj = assetmgr.resource(tex)
                imaterial.set_property(e, "s_basecolor", texobj.handle)
            end
        }
    }
end

local function color_palette_test()
    local bgfx = require "bgfx"
    return ecs.create_entity {
        policy = {
            "ant.render|simplerender",
            "ant.general|name",
        },
        data = {
            simplemesh = {
                vb = {
                    start = 0, num = 3,
                    handle = bgfx.create_vertex_buffer(bgfx.memory_buffer("fff", {
                        0.0, 0.0, 0.0, 
                        0.0, 0.0, 1.0,
                        1.0, 0.0, 0.0,
                    }), declmgr.get "p3".handle)
                }
            },
            material = "/pkg/ant.resources/materials/color_palette_test.material",
            visible_state = "main_view",
            scene = {srt={}},
            name = "color_pal_test",
        }
    }
end

local cp_eid, quad_eid
local testprefab

local after_init_mb = world:sub{"after_init"}
function init_loader_sys:init()
    --point_light_test()
    local eid1, eid2, eid3 = ientity.create_grid_entity("polyline_grid", 64, 64, 1, 5)
    -- print(eid1, eid2, eid3)

    -- local pp = ecs.create_instance "/pkg/ant.resources.binary/meshes/up_box.glb|mesh.prefab"
    -- function pp.on_ready(e)
    --     local ee<close> = w:entity(e.root)
    --     iom.set_scale(ee, 2.5)
    -- end
    -- world:create_object(pp)
    -- local p = ecs.create_instance "/pkg/ant.resources.binary/meshes/DamagedHelmet.glb|mesh.prefab"
    -- p.on_ready = function (e)
    --     local ee<close> = w:entity(e.root)
    --     iom.set_position(ee, math3d.vector(0, 5, 0, 1))
    -- end
    -- world:create_object(p)

    -- local p = ecs.create_instance "/pkg/ant.resources.binary/meshes/headquater.glb|mesh.prefab"
    -- p.on_ready = function (e)
    --     local ee<close> = w:entity(e.root)
    --     iom.set_scale(ee, 0.1)
    -- end
    -- world:create_object(p)

    --cp_eid = color_palette_test()

    quad_eid = ientity.create_quad_lines_entity("quads", {r={0.0, math.pi*0.5, 0.0}}, 
        "/pkg/ant.test.features/assets/quad.material", 10, 1.0)

    ecs.create_instance "/pkg/ant.test.features/assets/entities/daynight.prefab"
    do
        local p = ecs.create_instance "/pkg/ant.test.features/assets/glb/headquater-1.glb|mesh.prefab"
        p.on_ready = function(e)
            local ee<close> = w:entity(e.tag['*'][1], "scene:in")
            iom.set_scale(ee, 0.1)
        end
        world:create_object(p)
    end

    -- create_texture_plane_entity(
    --     {1, 1.0, 1.0, 1.0}, 
    --     "/pkg/ant.resources/textures/texture_plane.texture",
    --     {x=64, y=0, w=64, h=64}, {w=384, h=64})

    -- do
    --     local p = ecs.create_instance "/pkg/ant.resources.binary/meshes/world_simple.glb|mesh.prefab"
    --     p.on_ready = function (e)
    --         local ee<close> = w:entity(e.root)
    --         iom.set_scale(ee, 0.1)
    --     end
    --     world:create_object(p)
    -- end

    -- do
    --     local p = ecs.create_instance "/pkg/ant.resources.binary/meshes/plane.glb|mesh.prefab"
    --     p.on_ready = function (e)
    --         local ee<close> = w:entity(e.root)
    --         iom.set_scale(ee, 0.1)
    --         local ivav = ecs.import.interface "ant.test.features|ivertex_attrib_visualizer"

    --         local dl = w:first("directional_light scene:in")
    --         local d = math3d.inverse(math3d.todirection(dl.scene.r))
    --         for _, eid in ipairs(e.tag["*"]) do
    --             local ee<close> = w:entity(eid)
    --             ivav.display_normal(ee, d)
    --         end
            
    --     end
    --     world:create_object(p)
    -- end

    -- do
    --     local p = ecs.create_instance "/pkg/ant.resources.binary/meshes/world_simple.glb|mesh.prefab"
    --     p.on_ready = function (e)
    --         local ee<close> = w:entity(e.root)
    --         iom.set_scale(ee, 0.1)
    --         -- local ivav = ecs.import.interface "ant.test.features|ivertex_attrib_visualizer"

    --         -- local dl = w:first("directional_light scene:in")
    --         -- local d = math3d.inverse(math3d.todirection(dl.scene.r))
    --         -- for _, eid in ipairs(e.tag["*"]) do
    --         --     local ee<close> = w:entity(eid)
    --         --     ivav.display_normal(ee, d)
    --         -- end
            
    --     end
    --     world:create_object(p)
    -- end

    --ientity.create_grid_entity_simple "grid"

    -- ecs.create_entity{
	-- 	policy = {
	-- 		"ant.render|simplerender",
	-- 		"ant.general|name",
	-- 	},
	-- 	data = {
	-- 		scene 		= {
    --             srt = {
    --                 s = {50, 1, 50, 0}
    --             }
    --         },
	-- 		material 	= "/pkg/ant.resources/materials/singlecolor1.material",
	-- 		visible_state= "main_view",
	-- 		name 		= "test_shadow_plane",
	-- 		simplemesh 	= imesh.init_mesh(ientity.plane_mesh()),
	-- 		on_ready = function (e)
	-- 			imaterial.set_property(e, "u_basecolor_factor", {0.5, 0.5, 0.5, 1})
	-- 		end,
	-- 	}
    -- }
    --ientity.create_procedural_sky()
    --local p = ecs.create_instance "/pkg/ant.resources.binary/meshes/headquater.glb|mesh.prefab"
--[[     local g1 = ecs.group(1)
    local group_root = g1:create_entity{
        policy = {
            "ant.scene|scene_object",
            "ant.general|name",
        },
        data = {
            scene = {},
            on_ready = function (e)
                iom.set_position(e, math3d.vector(-20, 0, 0))
            end,
            name = "test_group",
        },
    }
    g1:create_entity{
        policy = {
            "ant.render|render",
            "ant.general|name",
        },
        data = {
            mesh = "/pkg/ant.resources.binary/meshes/base/cube.glb|meshes/Cube_P1.meshbin",
            material = "/pkg/ant.resources.binary/meshes/base/cube.glb|materials/Material.001.material",
            visible_state = "main_view",
            scene = {
                parent = group_root,
            },
            on_ready = function (e)
                iom.set_scale(e, 10)
            end,
            name = "test_group",
        },
    } ]]

    ecs.create_instance"/pkg/ant.test.features/assets/entities/skybox_test.prefab"
    local p = ecs.create_instance  "/pkg/ant.test.features/assets/entities/light_directional.prefab"
    p.on_ready = function (e)
        local pid = e.tag["*"][1]

        ecs.create_entity{
            policy = {
                "ant.render|simplerender",
                "ant.general|name",
            },
            data = {
                simplemesh = ientity.arrow_mesh(0.3),
                material = "/pkg/ant.resources/materials/meshcolor.material",
                visible_state = "main_view",
                scene = {
                    parent = pid
                },
                name = "arrow",
                on_ready = function (ee)
                    imaterial.set_property(ee, "u_color", math3d.vector(1.0, 0.0, 0.0, 1.0))
                end
            }
        }

        local le<close> = w:entity(pid)
        iom.set_direction(le, math3d.vector(0.0, -1.0, 0.0))
    end
    world:create_object(p)

--[[     do
        testprefab = ecs.create_instance "/pkg/ant.test.features/assets/glb/headquater-1.glb|mesh.prefab"
        function testprefab.on_ready(e)
            local t = assetmgr.resource "/pkg/ant.test.features/assets/textures/headquater_basecolor_red.texture"
            local mesh_eid = e.tag["*"][2]
            local te<close> = w:entity(mesh_eid)
            imaterial.set_property(te, "s_basecolor", t.id)
            iom.set_scale(te, 0.1)
        end
        world:create_object(testprefab)
    end ]]

    -- do
    --     ecs.create_instance "/pkg/ant.test.features/assets/glb/electric-pole-1.glb|mesh.prefab"
    -- end


    local off = 0.1
	ientity.create_screen_axis_entity("global_axes", {type = "percent", screen_pos = {off, 1-off}}, {s=0.1})
    --ecs.create_instance "/pkg/ant.test.features/assets/glb/logistics_center.glb|mesh.prefab"

--[[      local p = ecs.create_instance "/pkg/ant.test.features/assets/entities/cube.prefab"
     function p:on_ready()
         local e = self.tag.cube[1]
         e.render_object.material.u_color = math3d.vector(0.8, 0, 0.8, 1.0)
     end

    world:create_object(p) ]]
    --print(p)
    --ecs.create_instance  "/pkg/ant.test.features/assets/entities/test_scene.prefab"
    --ecs.create_instance  "/pkg/ant.test.features/assets/entities/skybox_test.prefab"
    --ecs.create_instance  "/pkg/ant.test.features/assets/glb/cloud.glb|mesh.prefab"
    --ecs.create_instance  "/pkg/ant.test.features/assets/glb/shadow.glb|mesh.prefab"
    -- local p = ecs.create_instance  "/pkg/ant.test.features/assets/glb/Fox.glb|mesh.prefab"
    -- foxeid = p[3]
    
    --ecs.create_instance  "/pkg/ant.test.features/assets/glb/shuijing.glb|mesh.prefab"
    --ecs.create_instance  "/pkg/ant.resources/meshes/SimpleSkin/SimpleSkin.glb|mesh.prefab"
    -- ecs.create_instance  "/pkg/ant.test.features/assets/entities/light_point.prefab"
    -- local eid = ecs.create_instance  "/pkg/ant.resources.binary/meshes/Duck.glb|mesh.prefab"[1]
    -- world:pub{"after_init", eid}
    --ecs.create_instance  "/pkg/ant.test.features/assets/entities/font_tt.prefab"
    --ecs.create_instance  "/pkg/ant.resources.binary/meshes/female/female.glb|mesh.prefab"

    --ientity.create_procedural_sky()
    --target_lock_test()

    --ientity.create_skybox()
    --ecs.create_instance  "/pkg/ant.test.features/assets/glb/Duck.glb|mesh.prefab"

    --ecs.create_instance  "/pkg/ant.resources.binary/meshes/cloud_run.glb|mesh.prefab"
    --ecs.create_instance  "/pkg/ant.test.features/assets/CloudTestRun.glb|mesh.prefab"

    -- local eid = world:deprecated_create_entity {
    --     policy = {
    --         "ant.general|name",
    --         "ant.render|render",
    --         "ant.scene|transform_policy",
    --     },
    --     data = {
    --         name = "collider",
    --         scene_entity = true,
    --         sceme = {srt={s=100}},
    --         filterstate = "main_view|selectable",
    --         material = "/pkg/ant.resources/materials/singlecolor.material",
    --         mesh = "/pkg/ant.resources.binary/meshes/base/cube.glb|meshes/Cube_P1.meshbin",
    --     }
    -- }

--[[      local pp = ecs.create_instance "/pkg/ant.test.features/assets/glb/miner-1.glb|mesh.prefab"
    pp.on_ready = function (e)
        local ee<close> = w:entity(e.tag['*'][1])
        iom.set_scale(ee, 0.1)
        iom.set_position(ee, math3d.vector(0, 0, 0))
    end

    world:create_object(pp)  ]]

--[[     local t = ecs.create_instance  "/pkg/ant.test.features/assets/glb/test5.glb|mesh.prefab"
    t.on_ready = function (e)
        local pid<close> = w:entity(e.tag['*'][1])
        iom.set_scale(pid, 0.1)
        iom.set_position(pid, math3d.vector(5, 0, 5))
    end
    world:create_object(t) ]]

--[[     local units = 1
    local tt1 = ecs.create_instance "/pkg/ant.test.features/assets/glb/truck2.glb|mesh.prefab"
    tt1.on_ready = function (e)
        local pid<close> = w:entity(e.tag['*'][1])
        iom.set_scale(pid, 0.1)
        iom.set_position(pid, math3d.vector(2.25*units, 0, 1.25*units))
    end

    local tt2 = ecs.create_instance "/pkg/ant.test.features/assets/glb/truck2.glb|mesh.prefab"
    tt2.on_ready = function (e)
        local pid<close> = w:entity(e.tag['*'][1])
        iom.set_scale(pid, 0.1)
        iom.set_position(pid, math3d.vector(2.75*units, 0, 1.25*units))
    end

    local tt3 = ecs.create_instance "/pkg/ant.test.features/assets/glb/truck2.glb|mesh.prefab"
    tt3.on_ready = function (e)
        local pid<close> = w:entity(e.tag['*'][1])
        iom.set_scale(pid, 0.1)
        iom.set_position(pid, math3d.vector(2.25*units, 0, 1.75*units))
    end

    local tt4 = ecs.create_instance "/pkg/ant.test.features/assets/glb/truck2.glb|mesh.prefab"
    tt4.on_ready = function (e)
        local pid<close> = w:entity(e.tag['*'][1])
        iom.set_scale(pid, 0.1)
        iom.set_position(pid, math3d.vector(2.75*units, 0, 1.75*units))
    end
    world:create_object(tt1)
    world:create_object(tt2)
    world:create_object(tt3)
    world:create_object(tt4)

    local ep = ecs.create_instance "/pkg/ant.test.features/assets/glb/electric-pole-1.glb|mesh.prefab"
    ep.on_ready = function (e)
        local pid<close> = w:entity(e.tag['*'][1])
        iom.set_scale(pid, 0.1)
        iom.set_position(pid, math3d.vector(8*units, 0, 8*units))
    end
    world:create_object(ep) ]]

    -- ecs.create_entity {
    --     policy = {
    --         "ant.render|render",
    --         "ant.general|name",
    --         "mod.printer|printer",
    --     },
    --     data = {
    --         name        = "printer_test",
    --         scene  = {s = 0.2, t = {5, 0, 5}},
    --         material    = "/pkg/mod.printer/assets/printer.material",
    --         visible_state = "main_view",
    --         mesh        = "/pkg/mod.printer/assets/electric-pole-1.glb|meshes/Cylinder.006_P1.meshbin",
    --         render_layer= "postprocess_obj",
    --         -- add printer tag
    --         -- previous still be zero
    --         -- duration means generation duration time
    --         printer = {
    --             previous = 0,
    --             duration = 5
    --         }
    --     },
    -- }
end

local function render_layer_test()
    irl.add_layers(irl.layeridx "opacity", "after_opacity", "after_opacity2")
    local m = imesh.init_mesh(ientity.plane_mesh())

    ecs.create_entity {
        policy = {
            "ant.render|simplerender",
            "ant.general|name",
        },
        data = {
            simplemesh = m,
            scene = {},
            material = "/pkg/ant.test.features/assets/render_layer_test.material",
            render_layer = "after_opacity2",
            visible_state = "main_view",
            name = "test",
        }
    }

    ecs.create_entity {
        policy = {
            "ant.render|simplerender",
            "ant.general|name",
        },
        data = {
            simplemesh = m,
            scene = {
                t = {0.5, 0.0, 0.0}
            },
            material = "/pkg/ant.test.features/assets/render_layer_test.material",
            render_layer = "after_opacity",
            visible_state = "main_view",
            on_ready = function (e)
                imaterial.set_property(e, "u_basecolor_factor", math3d.vector(1.0, 0.0, 0.0, 1.0))
            end,
            name = "test",
        }
    }
end

local sampler_eid
local function motion_sampler_test()
    local ims = ecs.import.interface "ant.motion_sampler|imotion_sampler"
    local g = ims.sampler_group()
    local eid = g:create_entity {
        policy = {
            "ant.scene|scene_object",
            "ant.motion_sampler|motion_sampler",
            "ant.general|name",
        },
        data = {
            scene = {},
            name = "motion_sampler",
            on_ready = function (e)
                ims.set_target(e, nil, math3d.quaternion{0.0, 1.2, 0.0}, math3d.vector(0.0, 0.0, 2.0), 2000)
            end
        }
    }
    sampler_eid = eid

    g:enable "view_visible"
    g:enable "scene_update"

    local p = g:create_instance("/pkg/ant.test.features/assets/glb/Duck.glb|mesh.prefab", eid)
    p.on_ready = function (e)
        
    end

    world:create_object(p)
end

local canvas_eid
local function canvas_test()
    canvas_eid = ecs.create_entity {
        policy = {
            "ant.scene|scene_object",
            "ant.terrain|canvas",
            "ant.general|name",
        },
        data = {
            name = "canvas",
            scene = {
                t = {0.0, 10, 0.0},
            },
            canvas = {
                textures = {},
                texts = {},
                show = true,
            },
        }
    }
end

function init_loader_sys:init_world()
    for msg in after_init_mb:each() do
        local e = msg[2]
        local s = iom.get_scale(e)
        iom.set_scale(e, math3d.mul(s, {5, 5, 5, 0}))
    end

    local mq = w:first("main_queue camera_ref:in")
    local eyepos = math3d.vector(0, 8, -8)
    local camera_ref<close> = w:entity(mq.camera_ref)
    iom.set_position(camera_ref, eyepos)
    local dir = math3d.normalize(math3d.sub(mc.ZERO_PT, eyepos))
    iom.set_direction(camera_ref, dir)

    render_layer_test()
    canvas_test()

    motion_sampler_test()
end

local kb_mb = world:sub{"keyboard"}

local mouse_mb = world:sub{"mouse", "LEFT"}

local enable = 1
function init_loader_sys:entity_init()
    
    for _, key, press in kb_mb:unpack() do
        if key == "T" and press == 0 then
            -- local e<close> = w:entity(quad_eid)
            -- ivs.set_visible(e, "main_view", true)

            -- local quad_2 = 2
            -- e.render_object.ib_num = quad_2 * 6
        elseif key == "Y" and press == 0 then
            local mesh_eid = testprefab.tag["*"][2]
            local te<close> = w:entity(mesh_eid)
            local t = assetmgr.resource "/pkg/ant.test.features/assets/glb/headquater-1.glb|images/headquater_color.texture"
            imaterial.set_property(te, "s_basecolor", t.id)
        elseif key == "N" and press == 0 then
            -- local icw = ecs.import.interface "ant.render|icurve_world"
            -- icw.enable(not icw.param().enable)

            --imaterial.set_color_palette("default", 0, math3d.vector(1.0, 0.0, 1.0, 0.0))
            
            if enable == 1 then
                ecs.group(1):enable "view_visible"
                ecs.group(1):enable "scene_update"

                ecs.group(0):disable "view_visible"
                ecs.group(0):disable "scene_update"
            else
                ecs.group(0):enable "view_visible"
                ecs.group(0):enable "scene_update"

                ecs.group(1):disable "view_visible"
                ecs.group(1):disable "scene_update"
            end
            enable = enable == 1 and 0 or 1

        elseif key == "LEFT" and press == 0 then
            local d = w:first("directional_light scene:in eid:in")
            iom.set_position(d, {0, 1, 0})
        elseif key == "C" and press == 0 then
            local icanvas = ecs.import.interface "ant.terrain|icanvas"
            icanvas.add_items(w:entity(canvas_eid), "/pkg/ant.test.features/assets/canvas_texture.material", "background",
            {
                x = 2, y = 2, w = 4, h = 4,
                texture = {
                    rect = {
                        x = 0, y = 0,
                        w = 32, h = 32,
                    },
                },
            },
            {
                x = 0, y = 0, w = 2, h = 2,
                texture = {
                    rect = {
                        x = 32, y = 32,
                        w = 32, h = 32,
                    },
                },
            }
        )
        elseif key == "P" and press == 0 then
            local e = assert(w:entity(sampler_eid))
            local p = math3d.add(iom.get_position(e), math3d.vector(0.0, 0.0, 1.0))
            local ims = ecs.import.interface "ant.motion_sampler|imotion_sampler"
            ims.set_target(e, nil, nil, p, 100)

        elseif key == "O" and press == 0 then
            local e = assert(w:entity(sampler_eid))
            print(math3d.tostring(iom.get_position(e)))
        end
    end


end

function init_loader_sys:camera_usage()
    -- for _, _, state, x, y in mouse_mb:unpack() do
    --     local mq = w:first("main_queue render_target:in camera_ref:in")
    --     local ce = w:entity(mq.camera_ref, "camera:in")
    --     local camera = ce.camera
    --     local vpmat = camera.viewprojmat
    
    --     local vr = mq.render_target.view_rect
    --     local nx, ny = mu.remap_xy(x, y, vr.ratio)
    --     local ndcpt = mu.pt2D_to_NDC({nx, ny}, vr)
    --     ndcpt[3] = 0
    --     local p0 = mu.ndc_to_world(vpmat, ndcpt)
    --     ndcpt[3] = 1
    --     local p1 = mu.ndc_to_world(vpmat, ndcpt)
    
    --     local ray = {o = p0, d = math3d.sub(p0, p1)}
    
    --     local plane = math3d.vector(0, 1, 0, 0)
    --     local r = math3d.muladd(ray.d, math3d.plane_ray(ray.o, ray.d, plane), ray.o)
        
    --     print("click:", x, y, math3d.tostring(r), "view_rect:", vr.x, vr.y, vr.w, vr.h)
    -- end
end

