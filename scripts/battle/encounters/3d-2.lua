local Dummy, super = Class(Encounter)

function Dummy:init()
    super.init(self)

    -- Text displayed at the bottom of the screen at the start of the encounter
    self.text = [==[
* Not again...
* ([color:yellow]TP[color:reset] Gain reduced because [color:red]FUCK YOU[color:reset])
]==]

    -- Battle music ("battle" is rude buster)
    self.music = "3d_boss"
    -- Enables the purple grid battle background
    self.background = true

    self.reduced_tp = true

    -- Add the dummy enemy to the encounter
    self:addEnemy("3d-2", 490, 270)

    --- Uncomment this line to add another!
    --self:addEnemy("dummy")
end

return Dummy