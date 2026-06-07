---@class AK3D.Assets3D
local Assets3D = {}

function Assets3D.initialize()
    Assets3D.initShaders()
    Assets3D.initModels()
end

---@private
---@param base_path string
---@param handler fun(id:string, full_path:string)
---@param exts string[]
function Assets3D._loadFrom(base_path, handler, exts)
    for _, relative_path in ipairs(Utils.getFilesRecursive(base_path)) do
        local full_path = base_path .. "/" .. relative_path
        for _,ext in ipairs(exts) do
            local ends, id = Utils.endsWith(relative_path, "." .. ext)
            if ends then
                handler(id, full_path)
                goto continue
            end
        end
        ::continue::
    end
end

function Assets3D.initShaders()
    Assets3D.shader_paths = {}
    local function handler(id, full_path)
        Assets3D.shader_paths[id] = full_path
    end
    for i = 1, #Mod.info.lib_order do
        Assets3D._loadFrom(Mod.info.libs[Mod.info.lib_order[i]].path .. "/ak3dassets/shaders", handler, {"glsl", "vert", "frag"})
    end
    Assets3D._loadFrom(Mod.info.path .. "/ak3dassets/shaders", handler, {"glsl", "vert", "frag"})
    ---@type table<string, love.Shader>
    Assets3D.shaders = {}
    for k, v in pairs(Assets3D.shader_paths) do
        if not Utils.startsWith(k, "_include/") then
            Assets3D.shaders[k] = Assets3D.newShader(k)
        end
    end
end

function Assets3D.preprocessShader(id, file_names)
    local path = assert(Assets3D.shader_paths[id], "No such shader: "..id)
    file_names = file_names or {[1] = id}
    if not TableUtils.getKey(file_names, id) then
        table.insert(file_names, id)
    end
    local file_id = TableUtils.getKey(file_names, id)
    local shader_src = ("#line 0 " .. file_id .. "\n")
    local line_n = 0
    for line in love.filesystem.lines(Assets3D.shader_paths[id]) do
        ---@cast line string
        ---@type boolean, string
        local incl, include_path = StringUtils.startsWith(line, "#include")
        if incl then
            local shader_id = "_include/" .. select(3,include_path:find(" *\"(.*)\""))
            line = Assets3D.preprocessShader(shader_id, file_names)
        end
        shader_src = shader_src .. line .. "\n"
        if incl then
            shader_src = shader_src .. "#line " .. line_n .. " " .. file_id .. "\n"
        end
        line_n = line_n + 1
    end
    return shader_src, file_names
end

---@return love.Shader
function Assets3D.newShader(id)
    local shader_src, file_ids = Assets3D.preprocessShader(id)
    if id == "p3d" then
        print(shader_src)
    end
    local ok, out = pcall(love.graphics.newShader, shader_src, nil)
    if ok then --[[@cast out -string]] return out end
    ---@cast out string

    local error_line_pattern = "ERROR: (%d+):"
    error({msg = ([[
%s
shader %s: %s
%s
]]) :format(
            TableUtils.dump(file_ids),
            id,out:gsub(error_line_pattern, function(n)
        return string.format("ERROR: %s:", file_ids[tonumber(n)] or n)
    end), debug.traceback())})
end

function Assets3D.initModels()
    Assets3D.model_paths = {}
    local exts = {"obj", "dae"}
    local function handler(id, full_path)
        Assets3D.model_paths[id] = full_path
    end
    for i = 1, #Mod.info.lib_order do
        Assets3D._loadFrom(Mod.info.libs[Mod.info.lib_order[i]].path .. "/ak3dassets/models", handler, exts)
    end
    Assets3D._loadFrom(Mod.info.path .. "/ak3dassets/models", handler, exts)
end

function Assets3D.getShader(id)
    return assert(Assets3D.shaders[id], "No such shader: "..id)
end
function Assets3D.hasShader(id)
    return Assets3D.shaders[id] ~= nil
end

function Assets3D.getModelPath(id)
    return assert(Assets3D.model_paths[id], "No such shader: "..id)
end

function Assets3D.newModel(id, texture, translation, rotation, scale)
	local Model = modRequire("libraries.ak3d.g3dlib.g3d.model")
    return Model(Assets3D.getModelPath(id), Assets.getTexture(texture), translation, rotation, scale)
end

function Assets3D.hasModel(id)
    return Assets3D.model_paths[id] ~= nil
end

return Assets3D
