local imgui = require "imgui"
local rhwi  = import_package 'ant.render'.hwi
local lfs   = require "filesystem.local"
local fs    = require "filesystem"
local widget_utils = require "widget.utils"
local m = {}
local world
local prefab_mgr
function m.show()
    if imgui.widget.BeginMainMenuBar() then
        if imgui.widget.BeginMenu("File") then
            if imgui.widget.MenuItem("New", "Ctrl+N") then
            end
            if imgui.widget.MenuItem("Open", "Ctrl+O") then
            end
            if imgui.widget.MenuItem("Save", "Ctrl+S") then
                prefab_mgr:save_prefab()
            end
            if imgui.widget.MenuItem("Save As..") then
                local path = widget_utils.get_saveas_path("Prefab", ".prefab")
                if path then
                    prefab_mgr:save_prefab(path)
                end
            end
            imgui.widget.EndMenu()
        end
        if imgui.widget.BeginMenu("Edit") then
            if imgui.widget.BeginMenu("Create") then
                if imgui.widget.MenuItem("EmptyNode") then
                    world:pub {"Create", "empty"}
                end
                if imgui.widget.MenuItem("Cube") then
                    world:pub {"Create", "cube"}
                end
                if imgui.widget.MenuItem("Cone") then
                    world:pub {"Create", "cone"}
                end
                if imgui.widget.MenuItem("Cylinder") then
                    world:pub {"Create", "cylinder"}
                end
                if imgui.widget.MenuItem("Sphere") then
                    world:pub {"Create", "sphere"}
                end
                if imgui.widget.MenuItem("Torus") then
                    world:pub {"Create", "torus"}
                end
                if imgui.widget.MenuItem("Camera") then
                    world:pub {"Create", "camera"}
                end
                imgui.widget.EndMenu()
            end
            imgui.cursor.Separator()
            if imgui.widget.MenuItem("Undo", "CTRL+Z") then
            end

            if imgui.widget.MenuItem("Redo", "CTRL+Y", false, false) then
            end
            imgui.cursor.Separator()
            if imgui.widget.MenuItem("SaveUILayout") then
                local setting = imgui.util.SaveIniSettings()
                local wf = assert(lfs.open(fs.path "":localpath() .. "/" .. "imgui.layout", "wb"))
                wf:write(setting)
                wf:close()
            end
            imgui.widget.EndMenu()
        end
        imgui.widget.EndMainMenuBar()
    end
end

return function(w, pm)
    world = w
    prefab_mgr = pm
    return m
end