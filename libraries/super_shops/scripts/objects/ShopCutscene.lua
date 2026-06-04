--- The cutscene class for cutscenes running in shops, their scripts should be located in `scripts/shopcutscenes/`. \
--- These cutscene scripts will receive a ShopCutscene as their first argument.
---
---@class ShopCutscene : Cutscene
---@overload fun(group: string, id?: string, ...) : ShopCutscene
local ShopCutscene, super = Class(Cutscene)

local function _true() return true end

function ShopCutscene.getShopCutscene(group, id)
    local cutscene = Registry.shopcut[group]
    if type(cutscene) == "table" then
        return cutscene[id], true
    elseif type(cutscene) == "function" then
        return cutscene, false
    end
end

---@param group fun(cutscene: Cutscene, ...)
---@param id? string
---@param ... unknown
function ShopCutscene:init(group, id, ...)
	local scene, args = self:parseFromGetter(self.getShopCutscene, group, id, ...)

    self.changed_sprite = {}
    self.move_targets = {}
    self.waiting_for_text = nil
	
	Game.shop.dialogue_text:setText("")

    self.last_shop_state = Game.shop.state
    Game.shop:setState("CUTSCENE")

    super.init(self, scene, unpack(args))
	
	local emoteCommand = function(text, node)
        Game.shop:onEmote(node.arguments[1])
    end
	
	local x = 32
	local y = 272
	local w = 577
	local h = 177
	
	if Mod.libs["magical-glass"] and Kristal.getLibConfig("super_shops", "magical-glass") then
		if isClass(Game.shop) and Game.shop:includes(LightShop) then
			x = 26
			y = 266
			w = 590
			h = 190
		end
	end
	
	self.textbox = Textbox(x, y, w, h)
    self.textbox.layer = SHOP_LAYERS["dialogue"]
    Game.shop:addChild(self.textbox)
	self.textbox:setParallax(0, 0)	-- May want to see if I can get away with panning the camera someday
	
	self.textbox.text:registerCommand("emote", emoteCommand)
end

function ShopCutscene:update()
    if self.ended then return end

    local done_moving = {}
    for sk,target in pairs(self.move_targets) do
        if sk.x == target[1] and sk.y == target[2] then
            table.insert(done_moving, sk)
        end
        local tx = Utils.approach(sk.x, target[1], target[3] * DTMULT)
        local ty = Utils.approach(sk.y, target[2], target[3] * DTMULT)
        sk:setPosition(tx, ty)
    end
    for _,v in ipairs(done_moving) do
        self.move_targets[v] = nil
    end
	
	if Game.shop.shopkeeper.talk_sprite then
        self.textbox.text.talk_sprite = Game.shop.shopkeeper.sprite
    else
        self.textbox.text.talk_sprite = nil
    end

    super.update(self)
end

function ShopCutscene:onEnd()
    if Game.shop.cutscene == self then
        Game.shop.cutscene = nil
    end

    self.textbox:remove()

    self.move_targets = {}

    if self.finished_callback then
        self.finished_callback(self)
    else
        Game.shop:setState(self.last_shop_state, "CUTSCENE")
    end
end

--- Moves a character to a new position (`x`, `y`) over `time` seconds. \ 
--- Supports easing.
---@param x     number          The new x-coordinate to approach.
---@param y     number          The new y-coordinate to approach.
---@param time? number          The amount of time, in seconds, that the slide should take. (Defaults to 1 second)
---@param ease? easetype        The ease type to use when moving position. (Defaults to "linear")
---@param obj?  object			The object being moved. (Defaults to Game.shop.shopkeeper)
---@return fun() : boolean finished A function that returns `true` once the movement is finished.
function ShopCutscene:slideTo(x, y, time, ease, obj)
    if not obj then
		obj = Game.shop.shopkeeper
	end
    local slided = false
    if obj:slideTo(x, y, time, ease, function() slided = true end) then
        return function() return slided end
    else
        return _true
    end
end

--- Linearly moves a character to a new position (`x`, `y`) over time at a rate of `speed` pixels per frame.
---@param x         number The new x-coordinate to approach.
---@param y         number The new y-coordinate to approach.
---@param speed?    number The amount the character's `x` and `y` should approach their new position by every frame, in pixels per frame at 30FPS. (Defaults to `4`)
---@param obj?  	object The object being moved. (Defaults to Game.shop.shopkeeper)
---@return fun() : boolean finished A function that returns `true` once the movement has finished.
function ShopCutscene:slideToSpeed(x, y, speed, obj)
    if not obj then
		obj = Game.shop.shopkeeper
	end
    local slided = false
    if obj:slideToSpeed(x, y, speed, function() slided = true end) then
        return function() return slided end
    else
        return _true
    end
end

local function waitForText(self) return self.textbox.text.text == "" end
--- Types text on the text box, and suspends the cutscene until the player progresses the dialogue. \
--- When passing arguments to this function, the options table can be passed as the second or third argument to forgo specifying `portrait` or `actor`.
---@overload fun(self: ShopCutscene, text: string, options?: table): finished: fun(): boolean
---@overload fun(self: ShopCutscene, text: string, portrait: string, options?: table): finished: fun(): boolean
---@param text      string  The text to be typed.
---@param portrait? string  The character portrait to be used.
---@param actor?    Actor   The actor to use for voice bytes and dialogue portraits, overriding the active cutscene speaker.
---@param options?  table   A table defining additional properties to control the text.
---|"x"         # The x-offset of the dialgoue portrait.
---|"y"         # The y-offset of the dialogue portrait.
---|"reactions" # A table of tables that define "reaction" dialogues. Each table defines the dialogue, x and y position of the face, actor and face sprite, in that order. x and y can be strings as well, referring to existing positions; x can be left, leftmid, mid, middle, rightmid, or right, and y can be top, mid, middle, bottommid, and bottom. Must be used in combination with a react text command.
---|"functions" # A table defining additional functions that can be used in the text with the `func` text command. Each key, value pair will form the id to use with `func` and the function to be called, respectively.
---|"font"      # The font to be used for this text. Can optionally be defined as a table {font, size} to also set the text size.
---|"align"     # Sets the alignment of the text.
---|"skip"      # If false, the player will be unable to skip the textbox with the cancel key.
---|"advance"   # When `false`, the player cannot advance the textbox, and the cutscene will no longer suspend itself on the dialogue by default.
---|"auto"      # When `true`, the text will auto-advance after the last character has been typed.
---|"wait"      # Whether the cutscene should automatically suspend itself until the textbox advances. (Defaults to `true`, unless `advance` is false.)
---@return fun() finished A function that returns `true` when the textbox has been advanced. (Only use if `options["wait"]` is set to `false`.)
function ShopCutscene:text(text, portrait, actor, options)
    if type(actor) == "table" and not isClass(actor) then
        options = actor
        actor = nil
    end
    if type(portrait) == "table" then
        options = portrait
        portrait = nil
    end

    options = options or {}

    self:closeText()

    if options["talk"] ~= false then
        self.textbox.text.talk_sprite = speaker
    end

    actor = actor or self.textbox_actor

    self.textbox:setActor(actor)

    self.textbox.active = true
    self.textbox.visible = true
    self.textbox:setFace(portrait, options["x"], options["y"])

    if options["reactions"] then
        for id,react in pairs(options["reactions"]) do
            self.textbox:addReaction(id, react[1], react[2], react[3], react[4], react[5])
        end
    end

    if options["functions"] then
        for id,func in pairs(options["functions"]) do
            self.textbox:addFunction(id, func)
        end
    end

    if options["font"] then
        if type(options["font"]) == "table" then
            -- {font, size}
            self.textbox:setFont(options["font"][1], options["font"][2])
        else
            self.textbox:setFont(options["font"])
        end
	elseif Game.shop and Game.shop.shopkeeper and Game.shop.shopkeeper:getActor() then
		self.textbox:setFont(Game.shop.shopkeeper:getActor():getFont() or "main_mono")
    end

    if options["align"] then
        self.textbox:setAlign(options["align"])
    end

    self.textbox:setSkippable(options["skip"] or options["skip"] == nil)
    self.textbox:setAdvance(options["advance"] or options["advance"] == nil)
    self.textbox:setAuto(options["auto"])

    self.textbox:setText(text, function()
		self.textbox:setActor(nil)
		self.textbox:setFace(nil)
		self.textbox:setFont()
		self.textbox:setAlign("left")
		self.textbox:setSkippable(true)
		self.textbox:setAdvance(true)
		self.textbox:setAuto(false)
        self.textbox:setText("")
		self:tryResume()
    end)

    if options["wait"] or options["wait"] == nil then
        return self:wait(waitForText)
    else
        return waitForText, self.textbox
    end
end

local function waitForChoicer(self) return self.choicebox.done, self.choicebox.selected_choice end
--- Creates a choicer with the choices specified in `choices` for the player to select from.
---@param choices  table A table of strings specifying the choices the player can select. Maximum of four.
---@param options? table A table defining additional properties to control the choicer.
---|"top"       # Override for the default textbox position, defining whether the choicer should appear at the top of the screen.
---|"color"     # The main color to set all the choices to, or a table of main colors to set for different choices. (Defaults to `COLORS.white`)
---|"highlight" # The color to highlight the selected choice in, or a table of colors to highlight different choices in when selected. (Defaults to `COLORS.yellow`)
---|"wait"      # Whether the cutscene should automatically suspend itself until the player makes their choice. (Defaults to `true`)
---@return number|function selected The index of the selected item if the cutscene has been set to wait for the choicer, otherwise a boolean that states whether the player has made their choice.
---@return Choicebox? choicer The choicebox object for this choicer. Only returned if wait is `false`. 
function ShopCutscene:choicer(choices, options)
    self:closeText()

    self.choicebox = Choicebox(32, 302, 577, 177, false, options)
    self.choicebox.layer = SHOP_LAYERS["dialogue"]
    self.choicebox.box.visible = false
    Game.shop:addChild(self.choicebox)

    for _,choice in ipairs(choices) do
        self.choicebox:addChoice(choice)
    end

    options = options or {}

    self.choicebox.active = true
    self.choicebox.visible = true

    if options["wait"] or options["wait"] == nil then
        return self:wait(waitForChoicer)
    else
        return waitForChoicer, self.choicebox
    end
end

function ShopCutscene:closeText()
	while not self.textbox do
		self:wait()
	end
    self.textbox:setText("")

    if self.choicebox then
        self.choicebox:remove()
        self.choicebox = nil
    end
end

--- Shakes a character by the specified `x`, `y`.
---@param x?        number          The amount of shake in the `x` direction. (Defaults to `4`)
---@param y?        number          The amount of shake in the `y` direction. (Defaults to `0`)
---@param friction? number          The amount that the shake should decrease by, per frame at 30FPS. (Defaults to `1`)
---@param delay?    number          The time it takes for the object to invert its shake direction, in seconds. (Defaults to `1/30`)
---@param chara?    Shopkeeper		The character being shaken. (Defaults to Game.shop.shopkeeper)
---@return fun() : boolean finished A function that returns `true` once the shake value has returned to 0.
function ShopCutscene:shakeCharacter(x, y, friction, delay, chara)
    if not chara then
		chara = Game.shop.shopkeeper
	end
    chara.sprite:shake(x, y, friction, delay)
    return function() return chara.sprite.graphics.shake_x == 0 and chara.sprite.graphics.shake_y == 0 end
end

--- Fades the screen and music out.
---@param speed?    number       The speed to fade out at, in seconds. (Defaults to `0.25`)
---@param options?  table        A table defining additional properties to control the fade.
---| "color"    # The color that should be faded to (Defaults to `COLORS.black`)
---| "alpha"    # The alpha to start at (Defaults to `0`)
---| "blocky"   # Whether to do a rough, 'blocky' fade. (Defaults to `false`)
---| "music"    # The speed to fade the music at, or whether to fade it at all (Defaults to fade speed)
---@return fun() : boolean finished    A function that returns true once the fade has finished.
function ShopCutscene:fadeOut(speed, options)
    options = options or {}

    local fader = Game.fader

    if speed then
        options["speed"] = speed
    end

    local fade_done = false

    fader:fadeOut(function() fade_done = true end, options)

    return function() return fade_done end
end

--- Fades the screen and music back in after a fade out.
---@param speed?    number  The speed to fade in at, in seconds (Defaults to last fadeOut's speed.)
---@param options?  table   A table defining additional properties to control the fade.
---| "color"    # The color that should be faded to (Defaults to last fadeOut's color)
---| "alpha"    # The alpha to start at (Defaults to `1`)
---| "blocky"   # Whether to do a rough, 'blocky' fade. (Defaults to `false`)
---| "music"    # The speed to fade the music at, or whether to fade it at all (Defaults to fade speed)
---@return fun() : boolean finished    A function that returns true once the fade has finished.
function ShopCutscene:fadeIn(speed, options)
    options = options or {}

    local fader = Game.fader

    if speed then
        options["speed"] = speed
    end

    local fade_done = false

    fader:fadeIn(function() fade_done = true end, options)

    return function() return fade_done end
end

--- Fades the screen and music back in after a fade out.
---@param emote    		string		The emote the shopkeeper uses.  
---@param shopkeeper?  	Shopkeeper  The shopkeeper to emote. (Defaults to Game.shop.shopkeeper.)
function ShopCutscene:emote(emote, shopkeeper)
    if not shopkeeper then
		shopkeeper = Game.shop.shopkeeper
	end
	
	shopkeeper:onEmote(emote)
end

--- Sets the textbox padding.
---@param x    		string		The x value of the text according to the textbox. Exactly what you think.
---@param y    		string		The y value of the text according to the textbox. Exactly what you think.
---@param offset?	string		How far down the lines will go.
function ShopCutscene:setTextboxPadding(x, y, offset)
	while not self.textbox do
		self:wait()
	end

    if (not x) or (not y) then
		error("Tried to set textbox padding, but was missing a positional argument")
	end
	
	self.textbox.text_x = x
	self.textbox.text.x = x
	self.textbox.text.y = y
	if offset then
		self.textbox.text.line_offset = offset
	end
end

return ShopCutscene