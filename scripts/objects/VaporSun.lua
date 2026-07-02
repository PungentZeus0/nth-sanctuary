local VaporSun, super = Class(Object)

function VaporSun:init(x, y)
    self.spr = Assets.getTexture("world/objects/vapor_sun")
    super.init(self, x, y, self.spr:getWidth(), self.spr:getHeight())

    self:setScale(2)
    self:setOrigin(0.5, 0.5)
    self.layer = WORLD_LAYERS["bottom"]
    self.overlay = Assets.getTexture("lines")

    self:addFX(ShaderFX("wave_interlace", {
				["wave_sine"] = function () return Kristal.getTime() * 50 end,
				["wave_mag"] = function () return 10 end,
				["wave_height"] = 25,
				["texsize"] = { SCREEN_WIDTH, SCREEN_HEIGHT }
			}), "funky_mode")
end

function VaporSun:draw()
    super.draw(self)
        Draw.pushShader("checkerboard_mask", {
        ["pattern"] = self.overlay
        }
    )
    local shader = Assets.getShader("checkerboard_mask")
    shader:send("offset", {Kristal.getTime()/10, Kristal.getTime()/10})
    super.draw(self)
    Draw.draw(self.spr)
    Draw.popShader()

end

return VaporSun