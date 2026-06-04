local MadDummy, super = Class(EnemyBattler)

function MadDummy:init()
    super.init(self)

    self.name = "Dummy"
    self:setActor("maddummy")

    self.max_health = 450
    self.health = 450
    self.attack = 4
    self.defense = 0
    self.money = 100
    self.spare_points = 0

    self.the_true_fight = false
    self.the_true_end = false
    self.trigger_cause = ""
    
    self.dialogue_index = 1
    self.random_dialogue = {
        "[float:2]Pitiful.\nPitiful!\nPITIFUL!!",
        "[float:2]Feeble.\nFeeble!\nFEEBLE!!",
        "[float:2]Futile.\nFutile!\nFUTILE!!",
        "[float:2]Foolish.\nFoolish!\nFOOLISH!!",
    }

    self.siner_active = false
    self.siner = 0
    self.y_speed = 0.05
    self.x_speed = 0
    self.radius = self.y_speed * 400

    self.waves = {"basic", "aiming"}
    self.dialogue = {"..."}
    self.check = "AT 4 DF 0\n* Cotton heart and button eye\n* Looks just like a fluffy guy."

    self.text = {
        "* The dummy gives you a soft\nsmile.",
        "* The power of fluffy boys is\nin the air.",
        "* Smells like cardboard.",
    }

    self.low_health_text = "* The dummy looks like it's\nabout to fall over."

    self:registerAct("Smile", "Induce\nMERCY")
    self:registerAct("Tell Story", "Induce\nTIRED", {"ralsei"})
	self.hit_once = false
end

function MadDummy:getEnemyDialogue()
    if self.dialogue_override then
        local dialogue = self.dialogue_override
        self.dialogue_override = nil
        return dialogue
    end

    if self.the_true_fight then
        if self.dialogue_index <= #self.dialogue then
            local line = self.dialogue[self.dialogue_index]
            self.dialogue_index = self.dialogue_index + 1
            return line
        else
            return TableUtils.pick(self.random_dialogue)
        end
    end

    return TableUtils.pick(self.dialogue)
end

function MadDummy:getEncounterText()
    if self.dialogue_index == 2 then
        return "[facec:ralsei/smile_b_battle][voice:ralsei]* (Hey, Kris!)[wait:5]\n* (It looks like the [color:yellow]MAGICAL[color:reset]\nbullets are damaging them!)"
    elseif self.dialogue_index == 3 then
        return "[facec:ralsei/wink_battle][voice:ralsei]* (Let's try to make them\nshoot [color:yellow]MAGICAL[color:reset] bullets at\nthemself,[wait:5] okay, Kris?)"
    elseif self.dialogue_index == 4 then
        return "[facec:susie/smile][voice:susie]* (Or you can just use my\nRUDE BUSTER, because it's\ncooler.)"
    elseif self.dialogue_index == 5 then
        return "* You tell Mad Dummy that there is no such thing as a \"barrier\" here."
    elseif self.dialogue_index == 6 then
        return "* You are filled with the power of\nnot knowing what you're talking\nabout."
    end

    return super.getEncounterText(self)
end

function MadDummy:onTurnEnd()
    self.y_speed = self.y_speed + 0.01
    self.x_speed = self.x_speed + 0.01
    self.radius = self.y_speed * 500
end

function MadDummy:triggerTrueBattle(cause, noact)
    if self.the_true_fight then return end

    self.the_true_fight = true
    self.trigger_cause = cause or "smile"
    self.dialogue_index = 1

    self.old_x = self.x
    self.old_y = self.y

    if noact ~= true then
        Game.battle:setState("CUTSCENE")
        Game.battle:resetAttackers() 
        Game.battle.processing_action = false
    
        Game.battle.should_finish_action = false
        Game.battle.on_finish_keep_animation = nil
        Game.battle.on_finish_action = nil
        
        Game.battle:startActCutscene("dummy", "the_true_fight", self)
    end

    self.max_health = 900
    self.health = 900
    self.mercy = 0
    self.spare_points = 0

    self.name = "Mad Dummy"
    self.attack = 15
    self.defense = 100
    self.waves = {"mad_dummy/aiming", "mad_dummy/basic", "mad_dummy/wall"}
    self.wave_override = "mad_dummy/aiming"

    local first_line = {"[float:2]YOU!!", "[float:2]You think you\ncan just stand\nthere and smile?!", "[float:2]Perhaps you\nshould've\nASKED for it\nfirst!"}
    local middle_line_1 = {"[float:2]And then\nYOU show up.", "[float:2]With your\nfluffy\nfriends!", "[float:2]And your\n\"storytelling\"!"}
    local middle_line_2 = {"[float:2]And the way\nyou tell me\nall this...!", "[float:2]Horrible.\nShocking!\nMIND-BLOWING!!"}

    if self.trigger_cause == "tell story" then
        first_line = {"[float:2]YOU!!", "[float:2]And your\nfluffy friend\nand his\nBORING stories!!", "[float:2]I've heard\nbetter plots\nfrom a\nPOST-IT NOTE!!"}
        middle_line_1 = {"[float:2]And then\nyou both\nhave the\nAUDACITY...", "[float:2]To stand\nthere and\nlecture me?!"}
    elseif self.trigger_cause == "susie action" then
        first_line = {"[float:2]YOU!!", "[float:2]And your\npurple friend\nand her\nVIOLENT hands!!", "[float:2]PUNCHING a\ndummy?!\nHow original!!"}
        middle_line_1 = {"[float:2]She thinks\nshe's so\ntough!", "[float:2]A real\nshocker!\nA real\nKNOCKOUT!!"}
    elseif self.trigger_cause == "ralsei action" then
        first_line = {"[float:2]YOU!!", "[float:2]Letting that\nfluffy boy\ndrag on\nforever!!", "[float:2]He's boring\nme to\nDEATH!!"}
        middle_line_1 = {"[float:2]I'm a ghost,\nand even I\nwant to\nbe free!!", "[float:2]Free from your\n\"GOAT\" FRIEND'S\nSPEECHES!"}
    elseif self.trigger_cause == "fight" then
        first_line = {"[float:2]YOU!!", "[float:2]Attacking a\ndefenseless\ntraining \"tool\"?!", "[float:2]Ghosts have\nfeelings too!", "[float:2]Coward.\nCoward!\nCOWARD!!"}
        middle_line_2 = {"[float:2]The way\nyou swing\nthat weapon...!", "[float:2]DREADFUL!!\nABHORRENT!!\nSTUPID!!"}
    end

    self.dialogue = {
        first_line,
        {"[float:2]What?\nWhat?!\nWHAT?!?", "[float:2]What magic attacks?[wait:5]\nNo magic attacks\ncan hurt me!", "[float:2]These are all lies...!"},
        {"[float:2]You know what\nwould've been\nmillion times\nbetter?", "[float:2]If I'd spooked\naway your SOUL\nall by myself!"},
        {"[float:2]That's right!\nAll by myself!", "[float:2]For I to cross\nthe BARRIER and\nbe free!"},
        {"[float:2]WHAT?!\nWHAT DO YOU\nMEAN \"THERE'S\nNO BARRIER\"?!?", "[float:2]Foolish.\nFoolish!\nFOOLISH!!"},
        {"[float:2]I've spent\neons in this\nstupid room!", "[float:2]Waiting for\na fool like\nYOU!!", "[float:2]Waiting for\na PURPOSE!"},
        middle_line_1,
        middle_line_2,
        {"[float:2]I don't need\na SOUL to\ndefeat you!", "[float:2]I have\nSPIRIT!", "[float:2]Literally!\nI'm a ghost!"},
        {"[float:2]Why won't\nyou just\nSTAY STILL?!", "[float:2]Stop moving!\nStop breathing!\nSTOP EXISTING!"},
        {"[float:2]Fine!\nKeep acting!", "[float:2]Keep smiling!", "[float:2]It won't\nsave you\nanymore!"}
    }

    self:setTired(false)
    self.boss = true
	self.low_health_percentage = 0.25
    self.tired_percentage = 0.25
    self.spare_points = 0
    self.disable_mercy = true
    self.check = {"AT 15 DF YES\n* Its cotton burns with fury.\n* It rejects your ACTions.", "* Because they're a ghost,[wait:5]\nphysical attacks will fail.[wait:5]\n* Try using [color:yellow]MAGIC[color:reset] instead."}
    self.text = {"* The air crackles with rage.", "* The dummy trembles violently.", "* This is no longer pretend."}

    self:getAct("Check").description = "Consider\nstrategy"
    self:getAct("Smile").description = "Useless\naction"
    self:getAct("Tell Story").description = "Useless\naction"
    self.low_health_text = "* Mad Dummy looks like they're\nabout to fall apart."
end

function MadDummy:getHealthDisplay()
    if self.the_true_fight then return "???" end
    return super.getHealthDisplay(self)
end

function MadDummy:spare(pacify)
    self.siner_active = false
    return super.spare(self, pacify)
end

function MadDummy:onHurt(damage, battler)
	if self.siner_active then
		if not self.hit_once then
			self.sprite.rotmod = 0.4
			self.sprite.speedmod = 1
			self.hit_once = true
		end
		self.sprite.part_data["head"].ox = self.sprite.width/2
		self.sprite.part_data["head"].oy = 21
		self.sprite.part_data["head"].orot = self.sprite.rot
		self.sprite.part_data["body"].ox = self.sprite.width/2
		self.sprite.part_data["body"].oy = 23 + (self.sprite.rot / 4)
		self.sprite.part_data["body"].orot = self.sprite.rot / 2
		self.sprite.part_data["base"].ox = self.sprite.width/2 - (self.sprite.rot / 3)
		self.sprite.part_data["base"].oy = 36 + (self.sprite.rot / 3)
		self.sprite.part_data["base"].orot = -self.sprite.rot
		
		self.sprite.part_data["head"].x = self.sprite.part_data["head"].ox + -5 + MathUtils.random(10)
		self.sprite.part_data["head"].y = self.sprite.part_data["head"].oy + -2.5 + MathUtils.random(5)
		self.sprite.part_data["head"].rot = self.sprite.part_data["head"].orot + -90 + MathUtils.random(180)
		self.sprite.part_data["body"].x = self.sprite.part_data["head"].ox + -5 + MathUtils.random(10)
		self.sprite.part_data["body"].y = self.sprite.part_data["head"].oy + -2.5 + MathUtils.random(5)
		self.sprite.part_data["body"].rot = self.sprite.part_data["head"].orot + -90 + MathUtils.random(180)
		self.sprite.part_data["base"].x = self.sprite.part_data["head"].ox + -5 + MathUtils.random(10)
		self.sprite.part_data["base"].y = self.sprite.part_data["head"].oy + -2.5 + MathUtils.random(5)
		self.sprite.part_data["base"].rot = self.sprite.part_data["head"].orot + -90 + MathUtils.random(180)
		
		self.sprite.mode = 5
		Game.battle.timer:after(5/30, function()
			self.sprite.ow_timer = 21
			self.sprite.mode = 2
		end)
		
		for i = 1, self.sprite.cotton_count do
			local cotton = Sprite("bullets/maddummy/cotton")
			cotton:setFrame(TableUtils.pick{1, 2, 3})
			cotton.x, cotton.y = self.x, self.y
			cotton:setScale(1.5)
			cotton:setOrigin(0.5)
			cotton:fadeOutAndRemove(2)
			cotton.physics.speed_x = MathUtils.random(-2, 2)
			cotton.graphics.spin = 0.1
			cotton.graphics.grow = -0.02
			cotton.physics.speed_y = MathUtils.random(-12, -8)
			cotton.physics.gravity = 0.5
			Game.battle:addChild(cotton)
		end
	else	
		self:toggleOverlay(true)
	end
    self:getActiveSprite():shake(9, 0, 0.5, 2 / 30)

    if self.health <= (self.max_health * self.tired_percentage) then
        self:setTired(true, self.tired_percentage <= 0)
    end
end

function MadDummy:onDefeat(damage, battler)
    if self.the_true_end == true then return super.onDefeat(self, damage, battler) end
    if Game.battle.battle_ui.attacking then
        Game.battle.battle_ui:endAttack()
    end
    if not self.the_true_fight then
        self:triggerTrueBattle("fight")
        return false
    end
    Game.battle:setState("CUTSCENE")
    Game.battle:resetAttackers() 
    Game.battle.processing_action = false

    Game.battle.should_finish_action = false
    Game.battle.on_finish_keep_animation = nil
    Game.battle.on_finish_action = nil
    self.siner_active = false

    Game.battle:startCutscene("dummy", "the_true_end")
    return
    -- return super.onDefeat(self, damage, battler)
end

function MadDummy:onAct(battler, name)
    if self.the_true_fight then
        if name == "Check" then
            return {"* MAD DUMMY - AT 30 DF YES\n* Its cotton burns with fury.\n* It rejects your ACTions.", "* Because they're a ghost,[wait:5]\nphysical attacks will fail.[wait:5]\n* Try using [color:yellow]MAGIC[color:reset] instead."}
        elseif name == "Smile" then
            return {
                "* You smiled.\n* Mad Dummy laughed at your pity."
            }
        elseif name == "Tell Story" then
            return {
                "* You and Ralsei tried telling a story.\n* Mad Dummy shouted over you."
            }
        elseif name == "Standard" then
            return {
                "* "..battler.chara:getName().." reached toward Mad Dummy.\n* It punched your hand away."
            }
        else
            return "* Mad Dummy ignores you completely."
        end
    end

    if not self.the_true_fight then
        if name == "Check" then
            return "* DUMMY - AT 4 DF 0\n* Cotton heart and button eye\n* Looks just like a fluffy guy."
        elseif name == "Smile" then
            self:triggerTrueBattle("smile")
        elseif name == "Tell Story" then
            self:triggerTrueBattle("tell story")
        elseif name == "Standard" then
            self:triggerTrueBattle(battler.chara.id .. " action")
        else
            self:triggerTrueBattle()
        end
    end
    return super.onAct(self, battler, name)
end

function MadDummy:update()
    super.update(self)
    self.hp_ratio = (self.health / self.max_health)
	
    if Game.battle.state ~= "TRANSITION" and Game.battle.state ~= "INTRO" then
        if self.siner_active then
            self.siner = self.siner + DTMULT
            local y_offset = math.sin(self.siner * self.y_speed) * self.radius
            local x_offset = math.sin(self.siner * self.x_speed) * (self.radius/4)
            local lerp_x = MathUtils.lerp(self.x, self.old_x + x_offset, 0.1 * DTMULT)
            local lerp_y = MathUtils.lerp(self.y, self.old_y + y_offset, 0.1 * DTMULT)
            self:setPosition(lerp_x, lerp_y)
        end
        if self.bubble then
            local spr = self.sprite or self
            local x, y = spr:getRelativePos(0, spr.height/2, Game.battle)
            self.bubble.x = x
            self.bubble.y = y
        end
    end
end

return MadDummy