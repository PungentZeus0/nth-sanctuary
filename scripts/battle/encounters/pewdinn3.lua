local Pewdinns, super = Class(Encounter)

function Pewdinns:init()
    super.init(self)

    -- Text displayed at the bottom of the screen at the start of the encounter
    self.text = "* A sermon of Pewdinn come forth!"

    -- Battle music ("battle" is rude buster)
    self.music = "battle2"
    -- Enables the purple grid battle background
    self.background = true

    self.reduced_tp = false

    -- Add the dummy enemy to the encounter
    self:addEnemy("pewdinn")
    self:addEnemy("pewdinn")
    self:addEnemy("pewdinn")
    
	self.heat_wave_mag_bg = 0
	self.heat_wave_mag = 0
	self.apply_heatfx_to_bullets = false
	self.undo_heatwave_at_end = false
	self.heatfxbg = ShaderFX("lavawave", {
		wave_sine = function()
			return Kristal.getTime() * 90
		end,
        wave_mag = function()
            return self.heat_wave_mag_bg
        end,
        wave_height = SCREEN_HEIGHT / 100,
        texsize = { SCREEN_WIDTH, SCREEN_HEIGHT }
    })	
	self.heatfx = ShaderFX("lavawave", {
		wave_sine = function()
			return Kristal.getTime() * 90
		end,
		wave_mag = function()
			return self.heat_wave_mag
		end,
		wave_height = function()
			return Game.battle.arena and Game.battle.arena.height / 50 or SCREEN_HEIGHT / 50
		end,
		texsize = { SCREEN_WIDTH, SCREEN_HEIGHT }
	})
end

function Pewdinns:onBattleStart()
	Game.battle.background:addFX(self.heatfxbg)
end

function Pewdinns:update()
	super.update(self)
	if self.apply_heatfx_to_bullets then
		for _, wave in ipairs(Game.battle.waves) do
			if wave then
				for _, bullet in ipairs(wave.bullets) do
					if bullet and not bullet:getFX("heatfx") then
						bullet:addFX(self.heatfx, "heatfx")
					end
				end
				for _, object in ipairs(wave.objects) do
					if object and not object:getFX("heatfx") then
						object:addFX(self.heatfx, "heatfx")
					end
				end
			end
		end
	end
end

function Pewdinns:onStateChange(old, new, reason)
    if new == "DEFENDINGBEGIN" then
		self.undo_heatwave_at_end = true
		Game.battle.arena:addFX(self.heatfx)
		Game.battle.soul:addFX(self.heatfx)
		self.apply_heatfx_to_bullets = true
	elseif new == "ACTIONSELECT" then
		if self.undo_heatwave_at_end then
			Game.battle.timer:tween(0.5, self, {heat_wave_mag_bg = math.max(self.heat_wave_mag_bg - 1, 0)})
			self.heat_wave_mag = math.max(self.heat_wave_mag - 1, 0)
			if self.heat_wave_mag <= 0 then
				self.apply_heatfx_to_bullets = false
			end
			self.undo_heatwave_at_end = false
		end
	end
end

return Pewdinns