local Imbued, super = Class(EnemyStatusCondition)

function Imbued:init()
    super.init(self)
	
	self.default_turns = 99
	
	self.icon = "ui/status/burn"
end

function Imbued:onUpdate(battler)
    battler.statuses["imbued"].turn_count = 99
end

function Imbued:onTurnStart(battler)
    battler:hurtStatus(love.math.random(25, 50))
    Assets.playSound("creature_hurtmini", 0.5, 1)
end

return Imbued