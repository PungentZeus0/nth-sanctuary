local Prism, super = Class(Recruit)

function Prism:init()
    super.init(self)
    self.name = "3D Spinning Prism"
    self.recruit_amount = 1
    self.description = "Spinning and spinning and \nspinning and spinning and \nspinning and spinning and \nspinning and spinning and \nspinning and spinning and \n"
    self.chapter = "4.5?"
    self.level = 0
    self.attack = "x^3"
    self.defense = "y"
    self.element = "3D:SPIN"
    self.like = "Spinning and spinning"
    self.dislike = "Challenges"
    self.box_gradient_type = "bright"
    self.box_gradient_color = {1, 1,1}
    self.box_sprite = {"enemies/3d/idle", 0, 0}
    self.recruited = 0
end

return                                                                                                                           Prism