local ImbuedGuei, super = Class(Encounter)

function ImbuedGuei:init()
    super.init(self)

    -- Text displayed at the bottom of the screen at the start of the encounter
    self.text = [[
* Darkness pours everywhere... [wait:10]\n
* The creature's presence makes you shake.
]]

    -- Battle music ("battle" is rude buster)
    self.music = "battle_creature"
    -- Enables the purple grid battle background
    self.background = true

    -- Add the dummy enemy to the encounter
    self.g = self:addEnemy("creature_a")
    self.orig_layer = self.g.layer

    --- Uncomment this line to add another!
    --self:addEnemy("dummy")
    self.fakefade = Rectangle(0,0,999,999)
    self.fakefade:setColor(COLORS.black)
    self.fakefade.alpha = 0
    Game.battle:addChild(self.fakefade)
end

function ImbuedGuei:onBattleStart()
	Game:setFlag("imbued_battle_fading", false)
end

function ImbuedGuei:createBackground()
    return Game.battle:addChild(CreatureBG())
end

function ImbuedGuei:getDialogueCutscene()
    if self.g.health <= 1000 then
        return function(cutscene, battler)
            Game.battle.music:fade(0, 2)
            
            self.g.layer = BATTLE_LAYERS["ui"]
            self.fakefade.layer = self.g.layer - 1

            Game.battle.timer:tween(2, self.fakefade, {alpha = 0.5})
            cutscene:wait(3)
            local spr = self.g.sprite.eye.sprite
            local aura = Sprite("effects/darksmoke")
			aura:addFX(ColorMaskFX(COLORS.white), "color")
			Game.battle:addChild(aura)
			aura.layer = self.g.layer + 1
			aura:setOrigin(0.5, 0.5)
            local x, y = spr:getScreenPos()
            aura:setPosition(x, y)
            aura:setScale(10)
            aura.alpha = 0
            Assets.playSound("rocket", 1, 0.5)
            Game.battle.timer:tween(2, aura, {scale_x = 2, scale_y = 2, alpha = 1}, 'out-cubic')
            local radius_points = {}
            local particles = {}
            for k = 1, 360 do
                local angle = math.rad(k)
                local dx = math.cos(angle) * 100
                local dy = math.sin(angle) * 100
                table.insert(radius_points, {dx, dy})
            end
            for i = 1, 30 do
                local p = Sprite("effects/particle")
                local offset = TableUtils.pick(radius_points)
                p:setPosition(x + offset[1], y + offset[2])
                p:setOrigin(0.5, 0.5)
                Game.battle:addChild(p)
                p.layer = aura.layer + 1
                p.physics.gravity = 0.2
                p.physics.gravity_direction = MathUtils.angle(p.x, p.y, x, y)
                table.insert(particles, p)
                cutscene:wait(1/15)
            end
            cutscene:during(function()
                for i = #particles, 1, -1 do
                    local particle = particles[i]
                    local dx = x - particle.x
                    local dy = y - particle.y
                    if dx * dx + dy * dy < 16 then
                        particle:remove()
                        table.remove(particles, i)
                    end
                end
            end) -- ??? Need to make them vanish when they reach the center
            cutscene:wait(5)
        end
    end
end

return ImbuedGuei