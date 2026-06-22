---@class Event.climbentry : Event
local ClimbEntry, super = HookSystem.hookScript(ClimbEntry)

function ClimbEntry:init(x, y, shape, settings)
    super.init(self, x, y, shape, settings)
	self.need_climbclaws = settings["clawsneeded"] or true
end

function ClimbEntry:onInteract(player, dir)
	if self.need_climbclaws and not Game.inventory:getDarkInventory():hasItem("claimbclaws") then
		Game.world:showText("* (It looks like you'd be able to climb this if you had the right tools.)")
		return true
	end
	return super.onInteract(self, player, dir)
end

return ClimbEntry