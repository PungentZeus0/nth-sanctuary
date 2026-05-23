local LightRainEffectLoader, super = Class(Event)

function LightRainEffectLoader:onLoad()
    super.onLoad(self)
    local properties = data and data.properties or {}
	local rainfx = Game.world:spawnObject(LightRainEffect())
	rainfx:setLayer(WORLD_LAYERS["below_ui"])
	rainfx.max_particles = properties["maxparticles"] or Game:getFlag("hometown_rain_max_particles", rainfx.max_particles)
	rainfx.drop_wait = properties["dropwait"] or Game:getFlag("hometown_rain_drop_wait", rainfx.drop_wait)
end

return LightRainEffectLoader