local Shop, super = Utils.hookScript(Shop)

function Shop:init()
	super.init(self)
	
	self.current_x = 1
	self.current_y = 1
	
	-- Cutscenes
	self.cutscene = nil
	
	-- Haggling
	self.haggle_rate = self:getFlag("haggle_rate", 1)
	self.haggle_marks = {} -- {position, rate}, calculated after discounts
	self.can_haggle = false
	self.haggle_current = self:getFlag("haggle_current", 0)
	self.haggle_max = 100
	
	-- Deny texts
	self.deny_text = {}
	
	self.deny_item = {}
	
	self.deny_sell = {}
	
	-- Genocide
	self.note = {
		"* Test note"
	}
	
	self.counter_money = 0
	self.steal_1 = "* You took "
	self.steal_2 = " from behind the counter."
	self.steal_nothing = "* Nothing left."
	
	-- Bonus card
	self.card_width = 5
	self.card_height = 3
	self.list = {1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0}
	self.images = {Assets.getTexture("ui/shop/scratch_card/fail"), Assets.getTexture("ui/shop/scratch_card/excellent"), Assets.getTexture("ui/shop/scratch_card/great"), Assets.getTexture("ui/shop/scratch_card/good"),}
	self.rewards = {0, 0.4, 0.2, 0.1}
	self.bonus_selected = false
	self.bonus_timer = 0
	self.bonus_money = 0
	self.bonus_game = false
	self.bonus_fail_dialogue = "* Too bad![wait:5]\n* Better luck next time!"
	self.bonus_win_dialogue_1 = "* Good job![wait:5] You got a rank "
	self.bonus_win_dialogue_2 = " win!"
	
	-- Stock Market
	self.stock_timer = 300
	self.stock_range = {0.6, 1.4}
	if not self:getFlag("stock_money") then
		self:setFlag("stock_money", 0)
		self:setFlag("stock_list", {nil, nil, nil, nil, nil})
	else
		if (Game.playtime / self.stock_timer) > (self:getFlag("last_time") / self.stock_timer) then
			self:handleStock()
		end
	end
	self.stock_add = 0
	self.stock_mode = 0
	
	-- Bounties
	self.bounties = {}
	
	-- Trading
	self.trades = {}
	self.current_trade_text = ""
    -- Shown when you enter the trade menu.
    self.trade_text = "Trade\ntext"
    -- Shown when you try to trade, but you don't have enough items.
    self.trade_fail = "Trade\nfail"
    -- Shown when you trade.
    self.trade_succeed = "Trade\nsucceed"
    -- Shown when you try to trade, but a trade isn't registered in the selected slot.
    self.trade_empty = "Trade\nempty"
	
	-- Loyalty Points
	if not self:getFlag("loyalty_points") then
		self:setFlag("loyalty_points", 0)
	end
	self.loyalty_increment = 1
	self.loyalty_items = {}
	self.loyalty_confirming = false
	self.loyalty_text = "LP"
	-- Shown when you're in the LOYALTY menu
    self.loyalty_menu_text = "Purchase\ntext\nLoyalty"
    -- Shown when you're about to buy something.
    self.loyalty_confirmation_text = "Buy it for\n%s " .. self.loyalty_text .. "?"
    -- Shown when you refuse to buy something
    self.loyalty_refuse_text = "Loyal\nrefused\ntext"
    -- Shown when you buy something
    self.loyalty_texti = "Loyal text"
    -- Shown when you buy something and it goes in your storage
    self.loyalty_storage_text = "Storage\nloyal text"
    -- Shown when you don't have enough money to buy something
    self.loyalty_too_expensive_text = "Not\nenough\n" .. self.loyalty_text .. "."
    -- Shown when you don't have enough space to buy something.
    self.loyalty_no_space_text = "You're\ncarrying\ntoo much."
end

function Shop:doHaggle(amount)
	self.haggle_current = self.haggle_current + amount
	self.haggle_current = math.min(math.max(self.haggle_current, 0), self.haggle_max)
	self:setFlag("haggle_current", self.haggle_current)
	
	self:updatePrices()
end

function Shop:registerBounty(name, info, flag, reward)
    self.bounties[#self.bounties + 1] = {
        name = name,
		info = info,
        flag = flag,
        reward = reward,
        claimed = Game:getFlag(flag .. "_claimed", false)
    }
end

function Shop:registerTrade(from, to, options)
	options = options or {}
	local to_name = Registry.createItem(to):getName()
	if options["item_name"] then
		to_name = options["item_name"]
	end
    self.trades[#self.trades + 1] = {
        from = from,
		to = to,
        fromname = Registry.createItem(from):getName(),
		toname = to_name,
    }
end

function Shop:updateHaggle()
	local mark_current = 0
	local did_mark = false
	for k,v in pairs(self.haggle_marks) do
		if v[1] > mark_current and self.haggle_current >= v[1] then
			mark_current = v[1]
			self.haggle_rate = v[2]
			self:setFlag("haggle_rate", v[2])
			did_mark = true
		end
	end
	if not did_mark then
		self.haggle_rate = 1
		self:setFlag("haggle_rate", 1)
	end
	for k,v in pairs(self.items) do
		v.options["price"] = math.floor(v.options["price"] * self.haggle_rate)
	end
end

function Shop:updateDiscounts()
	for k,v in pairs(self.items) do
		if v.options["discount"] then
			if Game:getFlag(v.options["discount"][1], false) then
				v.options["color"] = {0, 1, 1, 1}
				v.options["price"] = math.floor(v.options["price"] * v.options["discount"][2])
			else
				v.options["color"] = v.options["basecolor"]
			end
		end
	end
end

function Shop:resetPrices()
	for k,v in pairs(self.items) do
		v.options["price"] = v.options["baseprice"]
	end
end

function Shop:updatePrices()
	self:resetPrices()
	self:updateDiscounts()
	self:updateHaggle()
end

function Shop:denyDialogue(reason)
	self:setState("DIALOGUE")
	if type(self.deny_text[reason]) == "function" then
		self.deny_text[reason]()
	else
		local note = {}
		for k, v in pairs(self.deny_text[reason]) do
			note[k] = v
		end
		self:setDialogueText(note)
	end

    self.dialogue_text.advance_callback = (function()
        self:setState("MAINMENU", "DIALOGUE")
    end)
end

function Shop:denyItemDialogue(reason)
	self:setState("DIALOGUE")
	if type(self.deny_item[reason]) == "function" then
		self.deny_item[reason]()
	else
		local note = {}
		for k, v in pairs(self.deny_item[reason]) do
			note[k] = v
		end
		self:setDialogueText(note)
	end

    self.dialogue_text.advance_callback = (function()
        self:setState("BUYMENU", "DIALOGUE")
    end)
end

function Shop:denySellDialogue(reason)
	self:setState("DIALOGUE")
	if type(self.deny_sell[reason]) == "function" then
		self.deny_sell[reason]()
	else
		local note = {}
		for k, v in pairs(self.deny_sell[reason]) do
			note[k] = v
		end
		self:setDialogueText(note)
	end

	self.dialogue_text.advance_callback = (function()
		self:enterSellMenu(self.sell_options[self.sell_current_selecting])
	end)
end

function Shop:setState(state, reason)
	if self.deny_text[state] and self:doesDeny(state) then
		self:denyDialogue(state)
		return
	end
	
	super.setState(self, state, reason)
end

function Shop:doesDeny(state)
	return true
end

function Shop:replaceItem(index, item, options)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if item then
        options = options or {}
        options["name"]        = options["name"]        or item:getName()
        options["description"] = options["description"] or item:getShopDescription()
        options["baseprice"]   = options["price"]       or item:getBuyPrice()
        options["price"]       = (options["price"]      or item:getBuyPrice()) * self.haggle_rate
        options["bonuses"]     = options["bonuses"]     or item:getStatBonuses()
        options["discount"]    = options["discount"]    or (item.getDiscountPrice and item:getDiscountPrice(self.id)) or false -- {flag, decimal modifier}
        options["basecolor"]   = options["color"]       or {1, 1, 1, 1}
        options["color"]       = (options["discount"]   and Game:getFlag(options["discount"][1], false)    and {0, 1, 1, 1} or options["basecolor"])
        options["flag"]        = options["flag"]        or ("stock_" .. tostring(index) .. "_" .. item.id)
        options["loyalty"]     = options["loyalty"]     or self.loyalty_increment

        options["stock"] = self:getFlag(options["flag"], options["stock"])

        self.items[index] = {
            item = item,
            options = options
        }
        return true
    else
        return false
    end
end

function Shop:registerLoyaltyItem(item, options)
    return self:replaceLoyaltyItem(#self.loyalty_items + 1, item, options)
end

function Shop:replaceLoyaltyItem(index, item, options)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if item then
        options = options or {}
        options["name"]        = options["name"]        or item:getName()
        options["description"] = options["description"] or item:getShopDescription()
        options["price"]       = options["price"]       or item:getLoyaltyPrice()
        options["bonuses"]     = options["bonuses"]     or item:getStatBonuses()
        options["color"]       = options["color"]       or {1, 1, 1, 1}
        options["flag"]        = options["flag"]        or ("stock_" .. tostring(index) .. "_" .. item.id)

        options["stock"] = self:getFlag(options["flag"], options["stock"])

        self.loyalty_items[index] = {
            item = item,
            options = options
        }
        return true
    else
        return false
    end
end

function Shop:getNote()
	return self.note
end

function Shop:readNote()
	local note = {}
	local snote = self:getNote()
	
	if snote then
		for k, v in pairs(snote) do
			note[k] = v
		end
		
		self:setDialogueText(note)

		self.dialogue_text.advance_callback = (function()
			self:setState("MAINMENU", "READNOTE")
		end)
	end
end

function Shop:handleStealing()
	if self:getFlag("stole_from") then
		self:setDialogueText({self.steal_nothing})
	else
		Game.money = Game.money + self.counter_money
		self:setDialogueText({self.steal_1 .. string.format(self.currency_text, self.counter_money) .. self.steal_2})
		self:setFlag("stole_from", true)
	end

    self.dialogue_text.advance_callback = (function()
        self:setState("MAINMENU", "STEALFROMSHOP")
    end)
end

function Shop:handleStock()
	local mult = Utils.random(Utils.unpack(self.stock_range))
	self:setFlag("stock_money", Utils.round(self:getFlag("stock_money", 0) * mult, 1))
	-- "stock_list", {nil, nil, nil, nil, nil}
	mult = Utils.round(100 * mult, 1)
	mult = mult - 100
	local list = self:getFlag("stock_list", {nil, nil, nil, nil, nil})
	list[5] = list[4]
	list[4] = list[3]
	list[3] = list[2]
	list[2] = list[1]
	list[1] = mult
	self:setFlag("stock_list", list)
end

function Shop:processBuyConfirmInput()
    if Input.pressed("confirm") and self.deny_item[self.items[self.current_selected_item].item.id] then
		self:denyItemDialogue(self.items[self.current_selected_item].item.id)
		return
	end
	
	super.processBuyConfirmInput(self)
end

function Shop:processSellConfirmInput()
    if Input.pressed("confirm") and self.deny_sell[Game.inventory:getStorage(self.state_reason[2])[self.item_current_selected_item].id] then
		self:denySellDialogue(Game.inventory:getStorage(self.state_reason[2])[self.item_current_selected_item].id)
		return
	end
	
	super.processSellConfirmInput(self)
end

function Shop:processBonusInput()
	if not self.bonus_selected then
		if Input.pressed("confirm") then
			self.bonus_selected = true
		elseif Input.pressed("up") then
			self.current_y = self.current_y - 1
			if self.current_y < 1 then
				self.current_y = 1
			end
		elseif Input.pressed("down") then
			self.current_y = self.current_y + 1
			if self.current_y > self.card_height then
				self.current_y = self.card_height
			end
		elseif Input.pressed("left") then
			self.current_x = self.current_x - 1
			if self.current_x < 1 then
				self.current_x = 1
			end
		elseif Input.pressed("right") then
			self.current_x = self.current_x + 1
			if self.current_x > self.card_width then
				self.current_x = self.card_width
			end
		end
	end
end

function Shop:processBonusConfirmInput()
	if Input.pressed("confirm") and self.bonus_timer > 0.1 then
        if self.current_x == 1 then
			self:setState("BONUS")
		else
			self.bonus_money = 0
			self:setState("MAINMENU")
		end
	elseif Input.pressed("left") or Input.pressed("right") then
        self.current_x = self.current_x + 1
		if self.current_x > 2 then
			self.current_x = 1
		end
    end
end

function Shop:processStockViewInput()
	if Input.pressed("confirm") and self.bonus_timer > 0.1 then
        if self.stock_mode ~= 2 then
			self:setState("STOCKMODIFY")
		else
			self:setState("MAINMENU")
		end
	elseif Input.pressed("cancel") then
		self:setState("MAINMENU")
	elseif Input.pressed("up") then
        self.stock_mode = self.stock_mode - 1
		if self.stock_mode < 0 then
			self.stock_mode = 0
		end
	elseif Input.pressed("down") then
        self.stock_mode = self.stock_mode + 1
		if self.stock_mode > 2 then
			self.stock_mode = 2
		end
    end
end

function Shop:processStockModifyInput()
	if Input.pressed("confirm") and self.bonus_timer > 0.1 then
		if self.stock_mode == 0 then		-- Deposit
			local val = math.min(self.stock_add, Game.money)
			Game.money = Game.money - val
			self:setFlag("stock_money", self:getFlag("stock_money", 0) + val)
		elseif self.stock_mode == 1 then	-- Withdraw
			local val = math.min(self.stock_add, self:getFlag("stock_money", 0))
			Game.money = Game.money + val
			self:setFlag("stock_money", self:getFlag("stock_money", 0) - val)
		else								-- what???
			error("What??? Did you do??? (Super Shops Edition)")
		end
		self:setState("STOCKVIEW")
    elseif Input.pressed("menu") then
		if self.stock_mode == 0 then
			self.stock_add = Game.money
		elseif self.stock_mode == 1 then
			self.stock_add = self:getFlag("stock_money", 0)
		else
			error("What??? Did you do??? (Super Shops Edition)")
		end
	elseif Input.pressed("cancel") then
		self:setState("STOCKVIEW")
	elseif Input.pressed("up") then
        self.stock_add = self.stock_add + 10
		local maxval = Game.money
		if self.stock_mode == 1 then
			maxval = self:getFlag("stock_money", 0)
		end
		if self.stock_add > maxval then
			self.stock_add = maxval
		end
	elseif Input.pressed("down") then
        self.stock_add = self.stock_add - 10
		if self.stock_add < 0 then
			self.stock_add = 0
		end
	elseif Input.pressed("right") then
        self.stock_add = self.stock_add + 1
		local maxval = Game.money
		if self.stock_mode == 1 then
			maxval = self:getFlag("stock_money", 0)
		end
		if self.stock_add > maxval then
			self.stock_add = maxval
		end
	elseif Input.pressed("left") then
        self.stock_add = self.stock_add - 1
		if self.stock_add < 0 then
			self.stock_add = 0
		end
    end
end

function Shop:processBountiesInput()
	local old_selecting = self.current_selected_item
    if Input.pressed("confirm") and self.bonus_timer > 0.1 then
        if self.current_selected_item == math.max(#self.bounties, 4) + 1 then
            self:setState("MAINMENU")
        elseif self.bounties[self.current_selected_item] then
            if Game:getFlag(self.bounties[self.current_selected_item].flag) and not self.bounties[self.current_selected_item].claimed then
				Game:setFlag(self.bounties[self.current_selected_item].flag .. "_claimed", true)
				Game.money = Game.money + self.bounties[self.current_selected_item].reward
				self.bounties[self.current_selected_item].claimed = true
				Assets.playSound("locker")
			end
        end
    elseif Input.pressed("cancel") then
        self:setState("MAINMENU")
    elseif Input.pressed("up") then
        self.current_selected_item = self.current_selected_item - 1
        if (self.current_selected_item <= 0) then
            self.current_selected_item = math.max(#self.bounties, 4) + 1
        end
    elseif Input.pressed("down") then
        self.current_selected_item = self.current_selected_item + 1
        if (self.current_selected_item > math.max(#self.bounties, 4) + 1) then
            self.current_selected_item = 1
        end
    end
    if Input.pressed("up") or Input.pressed("down") then
        if self.current_selected_item >= #self.bounties + 1 then
            self.expand_box = false
        elseif (old_selecting >= #self.bounties + 1) and (self.current_selected_item <= #self.bounties) then
            self.expand_box = true
        end
    end
end

function Shop:processTradingInput()
	local old_selecting = self.current_selected_item
    if Input.pressed("confirm") and self.bonus_timer > 0.1 then
        if self.current_selected_item == math.max(#self.trades, 4) + 1 then
            self:setState("MAINMENU")
        elseif self.trades[self.current_selected_item] then
			if Game.inventory:hasItem(self.trades[self.current_selected_item].from) then
				Game.inventory:replaceItem(self.trades[self.current_selected_item].from, self.trades[self.current_selected_item].to)
				self.current_trade_text = self.trade_succeed
				Assets.playSound("locker")
			else
				self.current_trade_text = self.trade_fail
			end
		else
			self.current_trade_text = self.trade_empty
        end
    elseif Input.pressed("cancel") then
        self:setState("MAINMENU")
    elseif Input.pressed("up") then
        self.current_selected_item = self.current_selected_item - 1
        if (self.current_selected_item <= 0) then
            self.current_selected_item = math.max(#self.trades, 4) + 1
        end
    elseif Input.pressed("down") then
        self.current_selected_item = self.current_selected_item + 1
        if (self.current_selected_item > math.max(#self.trades, 4) + 1) then
            self.current_selected_item = 1
        end
    end
end

function Shop:processLoyaltyConfirmInput()
	if Input.pressed("confirm") and self.bonus_timer > 0.1 then
        self:setState("LOYALTYMENU")
        local current_item = self.loyalty_items[self.current_selected_item]
        if self.current_selecting_choice == 1 then
            self:buyItemLoyalty(current_item)
        else
            self:setRightText(self.buy_refuse_text)
        end
    elseif Input.pressed("cancel") then
        self:setState("LOYALTYMENU")
        self:setRightText(self.buy_refuse_text)
    elseif Input.pressed("up") or Input.pressed("down") then
        if self.current_selecting_choice == 1 then
            self.current_selecting_choice = 2
        else
            self.current_selecting_choice = 1
        end
    end
end

function Shop:processLoyaltyMenuInput()
    local old_selecting = self.current_selected_item

    if Input.pressed("confirm") and self.bonus_timer > 0.1 then
        if self.current_selected_item == math.max(#self.items, 4) + 1 then
            self:setState("MAINMENU")
        elseif self.items[self.current_selected_item] then
            if self.items[self.current_selected_item].options["stock"] then
                if self.items[self.current_selected_item].options["stock"] <= 0 then
                    return
                end
            end
            self:setState("LOYALTYCONFIRM")
            self.current_selecting_choice = 1
            self:setRightText("")
        end
	elseif Input.pressed("cancel") then
        self:setState("MAINMENU")
    elseif Input.pressed("up") then
        self.current_selected_item = self.current_selected_item - 1
        if (self.current_selected_item <= 0) then
            self.current_selected_item = math.max(#self.items, 4) + 1
        end
        self:adjustLoyaltyScroll()
    elseif Input.pressed("down") then
        self.current_selected_item = self.current_selected_item + 1
        if (self.current_selected_item > math.max(#self.items, 4) + 1) then
            self.current_selected_item = 1
        end
        self:adjustLoyaltyScroll()
    end
	if old_selecting ~= self.current_selected_item then
        if self.current_selected_item >= #self.items + 1 then
            self.expand_box = false
        elseif (old_selecting >= #self.items + 1) and (self.current_selected_item <= #self.items) then
            self.expand_box = true
        end
    end
end

function Shop:processInput()
	super.processInput(self)
	
	if self.state == "BONUS" then
		self:processBonusInput()
	elseif self.state == "BONUSCONFIRM" then
		self:processBonusConfirmInput()
	elseif self.state == "STOCKVIEW" then
		self:processStockViewInput()
	elseif self.state == "STOCKMODIFY" then
		self:processStockModifyInput()
	elseif self.state == "BOUNTIES" then
		self:processBountiesInput()
	elseif self.state == "TRADING" then
		self:processTradingInput()
	elseif self.state == "LOYALTYCONFIRM" then
		self:processLoyaltyConfirmInput()
	elseif self.state == "LOYALTYMENU" then
		self:processLoyaltyMenuInput()
	end
	
	self:updatePrices()
end

function Shop:onBonusConfirm(old)
	self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true
    self.dialogue_text.width = 372
    self.current_x = 1
	self:setDialogueText("")
	self:setRightText("")
	self.bonus_timer = 0
end

function Shop:onBonus(old)
	self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true
    self.dialogue_text.width = 372
	self.current_x = 1
	self.current_y = 1
	self:setDialogueText("")
	self:setRightText("Select a box!")
	self.list = Utils.shuffle(self.list)
	self.bonus_timer = 0
end

function Shop:onReadNote(old)
	self.large_box.visible = true
    self.left_box.visible = false
    self.right_box.visible = false
    self.dialogue_text.width = 598
	self:readNote()
end

function Shop:onStealFromShop(old)
	self.large_box.visible = true
    self.left_box.visible = false
    self.right_box.visible = false
    self.dialogue_text.width = 598
	self:handleStealing()
end

function Shop:onStockView(old)
	self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true
    self.dialogue_text.width = 372
    self:setDialogueText("")
    self:setRightText("")
	self.stock_selected = 0
	self.bonus_timer = 0
	self.stock_add = 0
end

function Shop:onStockModify(old)
    self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true
    self.dialogue_text.width = 372
    self:setDialogueText("")
    self:setRightText("")
	self.stock_selected = 0
	self.bonus_timer = 0
end

function Shop:onBounties(old)
	self:setDialogueText("")
    self:setRightText("")
    self.large_box.visible = true
    self.left_box.visible = false
    self.right_box.visible = false
    self.info_box.height = -8
    self.box_ease_timer = 0
    self.box_ease_beginning = -8
    self:showInfoBox()
    self.box_ease_method = "outExpo"
    self.box_ease_multiplier = 1
    self.current_selected_item = 1
	self.bonus_timer = 0
end

function Shop:onTrading(old)
	self:setDialogueText("")
    self:setRightText("")
    self.large_box.visible = true
    self.left_box.visible = false
    self.right_box.visible = false
    self.box_ease_timer = 0
    self.box_ease_beginning = -8
    self:showInfoBox()
    self.box_ease_method = "outExpo"
    self.box_ease_multiplier = 1
    self.current_selected_item = 1
	self.current_trade_text = self.trade_text
	self.bonus_timer = 0
end

function Shop:onLoyaltyMenu(old)
	self:setDialogueText("")
    self:setRightText(self.loyalty_menu_text)
    self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true
    self.box_ease_timer = 0
    self.box_ease_beginning = -8
    self:showInfoBox()
    self.box_ease_method = "outExpo"
    self.box_ease_multiplier = 1
    self.current_selected_item = 1
	self.loyalty_confirming = false
	self.bonus_timer = 0
end

function Shop:onLoyaltyConfirmState(old)
    self:setDialogueText("")
    self:setRightText("")
    self.large_box.visible = false
    self.left_box.visible = true
	self.bonus_timer = 0
    self:showInfoBox()
end

function Shop:onCutscene(old)
	self.large_box.visible = true
    self.left_box.visible = false
    self.right_box.visible = false
    self.info_box.visible = false
    self.dialogue_text.width = 598
    self:setDialogueText("")
    self:setRightText("")
	self.bonus_timer = 0
end

function Shop:onStateChange(old,new)
	Game.key_repeat = false
	super.onStateChange(self, old, new)
	if old == "BUYMENU" and new ~= "BUYCONFIRM" and self.bonus_money > 0 and self.bonus_game then
		self:setState("BONUSCONFIRM")
	end
	if new == "BONUSCONFIRM" then
		self:onBonusConfirm(old)
	elseif new == "BONUS" then
		self:onBonus(old)
	elseif old == "BONUSCONFIRM" or old == "BONUS" then
		self.bonus_selected = false
		self.current_x = 1
		self.current_y = 1
	elseif new == "READNOTE" then
		self:onReadNote(old)
	elseif new == "STEALFROMSHOP" then
		self:onStealFromShop(old)
	elseif new == "STOCKVIEW" then
        self:onStockView(old)
	elseif new == "STOCKMODIFY" then
		self:onStockModify(old)
    elseif new == "BOUNTIES" then
        self:onBounties(old)
	elseif new == "TRADING" then
        self:onTrading(old)
	elseif new == "LOYALTYMENU" then
        self:onLoyaltyMenu(old)
    elseif new == "LOYALTYCONFIRM" then
        self:onLoyaltyConfirmState(old)
	elseif new == "CUTSCENE" then
		self:onCutscene(old)
	end
end

function Shop:adjustLoyaltyScroll()
    local total = #self.items + 1
    local visible = 5

    self.item_offset = MathUtils.clamp(self.item_offset, self.current_selected_item - visible, self.current_selected_item - 1)

    -- clamp to valid range
    self.item_offset = MathUtils.clamp(self.item_offset, 0, total - visible)

    if total <= visible then
        self.item_offset = 0
    end
end

function Shop:updateStates()
	super.updateStates(self)
	
	-- if self.state == "LOYALTYMENU" or self.state == "LOYALTYCONFIRM" or self.state == "BOUNTIES" or self.state == "TRADING" then
        -- self:updateExpandingBox()

        -- if self.shopkeeper.slide then
            -- self:slideShopkeeper(true)
        -- end
    -- end
	
	if self.state == "BONUS" then
		if self.bonus_selected then
			self.bonus_timer = self.bonus_timer + DT
		end
		if self.bonus_timer >= 1 then
			self.prize_selected = self.list[self.current_x + (self.current_y-1)*self.card_width]
			Game.money = Game.money + self.bonus_money*self.rewards[self.prize_selected+1]
			if self.prize_selected == 0 then
				self:startDialogue({self.bonus_fail_dialogue},"MAINMENU")
			else
				self:startDialogue({self.bonus_win_dialogue_1 .. self.prize_selected .. self.bonus_win_dialogue_2 .. "\n* You win " .. string.format(self.currency_text, self.bonus_money*self.rewards[self.prize_selected+1]) .. " (" .. math.floor(self.rewards[self.prize_selected+1]*100) .. "%)."},"MAINMENU")
			end
			self.bonus_money = 0
		end
	elseif self.state == "BONUSCONFIRM" or self.state == "STOCKVIEW" or self.state == "STOCKMODIFY" or self.state == "BOUNTIES" or self.state == "TRADING" or self.state == "LOYALTYMENU" or self.state == "LOYALTYCONFIRM" then
		self.bonus_timer = self.bonus_timer + DT
	end
	
	if (Game.playtime - DT) % self.stock_timer > Game.playtime % self.stock_timer then
		self:handleStock()
	end
	
	self:setFlag("last_time", Game.playtime)
	if self.stock_mode == 1 then
		self.stock_add = math.min(self.stock_add, self:getFlag("stock_money", 0))
	end
	
	if self.cutscene then
        if not self.cutscene.ended then
            self.cutscene:update()
            if self.stage == nil then
                return
            end
        else
            self.cutscene = nil
        end
    end
end

function Shop:buyItem(current_item)
    if (current_item.options["price"] or 0) > self:getMoney() then
        -- Too expensive!
        self:setRightText(self.buy_too_expensive_text)
    else

        -- Add the item to the inventory
        local new_item = Registry.createItem(current_item.item.id)
        new_item:load(current_item.item:save())
        local main_storage_full = Game.inventory:isFull(Game.inventory:getDefaultStorage(new_item)["id"], false)
        if Game.inventory:addItem(new_item) then
            -- Successfully added the item, so...

            -- Decrement the stock
            if current_item.options["stock"] then
                current_item.options["stock"] = current_item.options["stock"] - 1
                self:setFlag(current_item.options["flag"], current_item.options["stock"])
            end

            -- Remove the money
            self:removeMoney(current_item.options["price"] or 0)
			
			-- Add the LP
            self:setFlag("loyalty_points", self:getFlag("loyalty_points") + current_item.options["loyalty"])
			
			-- Add to the prize pool
            if self.bonus_game then
                self.bonus_money = self.bonus_money + (current_item.options["price"] or 0)
            end

            -- Play the buy sound
            Assets.playSound("locker")

            -- Write the side text
            if main_storage_full then
                self:setRightText(self.buy_storage_text)
            else
                self:setRightText(self.buy_text)
            end
        else
            -- Not enough space, oops
            self:setRightText(self.buy_no_space_text)
        end
    end
end

function Shop:buyItemLoyalty(current_item)
    if (current_item.options["price"] or 0) > self:getFlag("loyalty_points") then
        -- Too expensive!
        self:setRightText(self.buy_too_expensive_text)
    else

        -- Add the item to the inventory
        local new_item = Registry.createItem(current_item.item.id)
        new_item:load(current_item.item:save())
        local main_storage_full = Game.inventory:isFull(Game.inventory:getDefaultStorage(new_item)["id"], false)
        if Game.inventory:addItem(new_item) then
            -- Successfully added the item, so...

            -- Decrement the stock
            if current_item.options["stock"] then
                current_item.options["stock"] = current_item.options["stock"] - 1
                self:setFlag(current_item.options["flag"], current_item.options["stock"])
            end

            -- Remove the LP
			self:setFlag("loyalty_points", self:getFlag("loyalty_points") - (current_item.options["price"] or 0))

            -- Play the buy sound
            Assets.playSound("locker")

            -- Write the side text
            if main_storage_full then
                self:setRightText(self.buy_storage_text)
            else
                self:setRightText(self.buy_text)
            end
        else
            -- Not enough space, oops
            self:setRightText(self.buy_no_space_text)
        end
    end
end

function Shop:drawBuyItems(draw_soul)
    local heart_pos = 30
    local text_pos = 60

    local total_items = #self.items + 1
    local visible_items = 5

    local first_item = 1 + self.item_offset
    local last_item = self.item_offset + visible_items

    local return_index = math.max(last_item, total_items)

    -- Show items
    for i = first_item, last_item do
        local y = 220 + ((i - self.item_offset) * 40)
        local item = self.items[i]

        if i == return_index then
            Draw.setColor(COLORS.white)
            love.graphics.print("Exit", text_pos, y)
        elseif item == nil then
            -- If there's no item there, show empty slot
            Draw.setColor(COLORS.dkgray)
            love.graphics.print("--------", text_pos, y)
        elseif item.options["stock"] and (item.options["stock"] <= 0) then
            -- If we've depleted the stock, show a "sold out" message
            Draw.setColor(COLORS.gray)
            love.graphics.print("--SOLD OUT--", text_pos, y)
        else
            -- Valid item, show it
            Draw.setColor(item.options["color"])
            love.graphics.print(item.options["name"], text_pos, y)
            if not self.hide_price then
                Draw.setColor(COLORS.white)
                love.graphics.print(string.format(self.currency_text, item.options["price"] or 0), 300, y)
				if item.options["discount"] and Game:getFlag(item.options["discount"][1]) then
					Draw.setColor({0.5,0.5,0.5})
					love.graphics.setFont(Assets.getFont("main", 16))
					love.graphics.print(math.floor((item.options["baseprice"] or 0) * self.haggle_rate), 302+self.font:getWidth(string.format(self.currency_text, item.options["price"] or 0)), y+13)
					love.graphics.setLineWidth(2)
					love.graphics.line( 302+self.font:getWidth(string.format(self.currency_text, item.options["price"] or 0)), y+22, 302+self.font:getWidth(string.format(self.currency_text, item.options["price"] or 0))+Assets.getFont("main", 16):getWidth(math.floor((item.options["baseprice"] or 0) * self.haggle_rate)), y+22)
				end
				love.graphics.setFont(Assets.getFont("main"))
            end
        end

        if draw_soul and (i == self.current_selected_item) then
            -- Draw the soul if we're selecting this option
            Draw.setColor(Game:getSoulColor())
            Draw.draw(self.heart_sprite, heart_pos, y + 10)
        end
    end
end

function Shop:drawLoyaltyItems(draw_soul)
    local heart_pos = 30
    local text_pos = 60

    local total_items = #self.loyalty_items + 1
    local visible_items = 5

    local first_item = 1 + self.item_offset
    local last_item = self.item_offset + visible_items

    local return_index = math.max(last_item, total_items)

    -- Show items
    for i = first_item, last_item do
        local y = 220 + ((i - self.item_offset) * 40)
        local item = self.loyalty_items[i]

        if i == return_index then
            Draw.setColor(COLORS.white)
            love.graphics.print("Exit", text_pos, y)
        elseif item == nil then
            -- If there's no item there, show empty slot
            Draw.setColor(COLORS.dkgray)
            love.graphics.print("--------", text_pos, y)
        elseif item.options["stock"] and (item.options["stock"] <= 0) then
            -- If we've depleted the stock, show a "sold out" message
            Draw.setColor(COLORS.gray)
            love.graphics.print("--SOLD OUT--", text_pos, y)
        else
            -- Valid item, show it
            Draw.setColor(item.options["color"])
            love.graphics.print(item.options["name"], text_pos, y)
            if not self.hide_price then
                Draw.setColor(COLORS.white)
                love.graphics.print(string.format(self.loyalty_text .. " %d", item.options["price"] or 0), 300, y)
            end
        end

        if draw_soul and (i == self.current_selected_item) then
            -- Draw the soul if we're selecting this option
            Draw.setColor(Game:getSoulColor())
            Draw.draw(self.heart_sprite, heart_pos, y + 10)
        end
    end
end

function Shop:drawLoyaltyConfirm()
    Draw.setColor(Game:getSoulColor())
    Draw.draw(self.heart_sprite, 450, 320 + (self.current_selecting_choice * 30))

    Draw.setColor(COLORS.white)

    local lines = StringUtils.split(
        string.format(
            self.buy_confirmation_text,
            string.format(
                self.loyalty_text .. " %d",
                self.loyalty_items[self.current_selected_item].options["price"] or 0
            )
        ),
        "\n"
    )

    for i = 1, #lines do
        love.graphics.print(lines[i], 460, 420 - 160 + ((i - 1) * 30))
    end

    love.graphics.print("Yes", 480, 420 - 80)
    love.graphics.print("No", 480, 420 - 80 + 30)
end

function Shop:drawLoyaltyItemDisplay()
    Draw.setColor(COLORS.white)

    local current_item = self.loyalty_items[self.current_selected_item]
    if current_item == nil then
        return
    end

    local box_left, box_top = self.info_box:getBorder()

    local left = self.info_box.x - math.floor(self.info_box.width) - (box_left / 2) * 1.5
    local top = self.info_box.y - math.floor(self.info_box.height) - (box_top / 2) * 1.5
    local width = math.floor(self.info_box.width) + box_left * 1.5
    local height = math.floor(self.info_box.height) + box_top * 1.5

    Draw.pushScissor()
    Draw.scissor(left, top, width, height)

    Draw.setColor(COLORS.white)
    love.graphics.print(current_item.options["description"], left + 32, top + 20)

    if current_item.item.type == "armor" or current_item.item.type == "weapon" then
        self:drawPartyBonusInfo(top, current_item.item, current_item.options)
    end

    Draw.popScissor()
end

function Shop:drawLoyalty()
    Draw.setColor(COLORS.white)
    love.graphics.setFont(self.font)
    love.graphics.print(string.format(self.loyalty_text .. " %d", self:getFlag("loyalty_points")), 440, 420)
end

function Shop:drawBonusConfirm()
	Draw.setColor(COLORS.white)
	love.graphics.setFont(Assets.getFont("main", 16))
	love.graphics.print("Prize pool: " .. string.format(self.currency_text, self.bonus_money), 30, 450)
	love.graphics.setFont(self.font)
	love.graphics.print("Scratch a bonus card?", 60, 300)
	love.graphics.print("Yes", 80, 360)
	love.graphics.print("No", 300, 360)
	Draw.setColor(Game:getSoulColor())
	if self.current_x == 1 then
		Draw.draw(self.heart_sprite, 60, 370)
	else
		Draw.draw(self.heart_sprite, 280, 370)
	end
end

function Shop:drawBonus()
	Draw.setColor(COLORS.white)
	love.graphics.setFont(Assets.getFont("main", 16))
	love.graphics.print("Prize pool: " .. string.format(self.currency_text, self.bonus_money), 30, 450)
	love.graphics.setFont(self.font)
	for i = 1, #self.list do -- 60, 280
		local x = 60 + 60*((i-1)%self.card_width)
		local y = 280 + 50*math.floor((i-1)/self.card_width)
		local xfind = i%self.card_width
		if xfind == 0 then
			xfind = 5
		end
		if (not self.bonus_selected) or self.current_x ~= xfind or self.current_y ~= math.ceil(i/self.card_width) then
			love.graphics.rectangle("fill", x, y, 46, 40)
		else
			Draw.draw(self.images[self.list[i]+1], x, y, 0, 2, 2)
		end
	end
	if not self.bonus_selected then
		Draw.setColor(Game:getSoulColor())
		Draw.draw(self.heart_sprite, 75 + 60*(self.current_x-1), 292 + 50*(self.current_y-1))
	end
end

function Shop:drawStockView()
	Draw.setColor(COLORS.white)
    love.graphics.print("Stock Cash", 440, 260)
    love.graphics.print(string.format(self.currency_text, self:getFlag("stock_money", 0)), 440, 300)
    love.graphics.print("Money", 440, 380)
		
	local list = self:getFlag("stock_list", {nil, nil, nil, nil, nil})
	for k,v in pairs(list) do
		if v ~= nil then
			local prefix = ""
			if v < 0 then
				Draw.setColor({1, 0, 0, (6-k) * 0.2})
			elseif v > 0 then
				Draw.setColor({0, 1, 0, (6-k) * 0.2})
				prefix = "+"
			else
				Draw.setColor({1, 1, 1, (6-k) * 0.2})
			end
			love.graphics.print(prefix .. v .. "%", 40, 220 + ((6-k) * 40))
		end
	end

	Draw.setColor(COLORS.white)
    love.graphics.setLineWidth(6)
    love.graphics.line(160, 250, 160, 470)
		
    for k,v in pairs({"Deposit", "Withdraw", "Exit"}) do
        love.graphics.print(v, 240, 220 + (k * 60))
    end
		
	Draw.setColor(Game:getSoulColor())
	Draw.draw(self.heart_sprite, 210, 290 + (self.stock_mode * 60))
end

function Shop:drawStockModify()
	Draw.setColor(COLORS.white)
    love.graphics.print("Stock Cash", 440, 260)
    love.graphics.print(string.format(self.currency_text, self:getFlag("stock_money", 0)), 440, 300)
    love.graphics.print("Money", 440, 380)
		
	local modes = {"Depositing", "Withdrawing"}
	love.graphics.printf(modes[self.stock_mode+1], 14, 280, 388, "center")
		
	love.graphics.printf("<   " .. self.stock_add .. "   >", 14, 360, 388, "center")
	Draw.draw(self.arrow_sprite, 201, 400)
	Draw.draw(self.arrow_sprite, 201, 355, 0, 1, -1)
	love.graphics.print(Input.getText("menu") .. ": Max", 40, 420)
end

function Shop:drawBounties()
	Draw.setColor(COLORS.white)
	for i = 1 + self.item_offset, self.item_offset + math.max(4, math.min(5, #self.bounties)) do
        if i == math.max(4, #self.items) + 1 then break end
        local y = 220 + ((i - self.item_offset) * 40)
        local bounty = self.bounties[i]
        if not bounty then
            Draw.setColor(COLORS.dkgray)
            love.graphics.print("--------", 60, y)
        elseif bounty.claimed then
            Draw.setColor(COLORS.white)
            love.graphics.print("COMPLETED", 60, y)
        else
            Draw.setColor(COLORS.white)
            love.graphics.print(bounty.name, 60, y)
            love.graphics.print("Reward: " .. string.format(self.currency_text, bounty.reward), 430, y)
        end
		love.graphics.setFont(self.font)
    end
    Draw.setColor(COLORS.white)
    if self.item_offset == math.max(4, #self.bounties) - 4 then
        love.graphics.print("Exit", 60, 220 + (math.max(4, #self.bounties) + 1 - self.item_offset) * 40)
    end
    Draw.setColor(Game:getSoulColor())
	Draw.draw(self.heart_sprite, 30, 230 + ((self.current_selected_item - self.item_offset) * 40))
		
    Draw.setColor(COLORS.white)
	if (self.current_selected_item <= #self.bounties) then
        local current_bounty = self.bounties[self.current_selected_item]
        local box_left, box_top = self.info_box:getBorder()

        local left = self.info_box.x - self.info_box.width - (box_left / 2) * 1.5
        local top = self.info_box.y - self.info_box.height - (box_top / 2) * 1.5
        local width = self.info_box.width + box_left * 1.5
        local height = self.info_box.height + box_top * 1.5

        Draw.pushScissor()
        Draw.scissor(left, top, width, height)

        Draw.setColor(COLORS.white)
        love.graphics.print("DESCRIPTION\n" .. current_bounty.info, left + 32, top + 20)
		Draw.popScissor()
	end
end

function Shop:drawTrading()
	Draw.setColor(COLORS.white)
	for i = 1 + self.item_offset, self.item_offset + math.max(4, math.min(5, #self.trades)) do
		if i == math.max(4, #self.trades) + 1 then break end
		local y = 220 + ((i - self.item_offset) * 40)
		local trade = self.trades[i]
		if not trade then
			Draw.setColor(COLORS.dkgray)
			love.graphics.print("--------", 60, y)
		else
			Draw.setColor(COLORS.white)
			love.graphics.print(trade.fromname, 60, y)
			love.graphics.print("-->  " .. trade.toname, 300, y)
		end
		love.graphics.setFont(self.font)
	end
	Draw.setColor(COLORS.white)
	if self.item_offset == math.max(4, #self.trades) - 4 then
		love.graphics.print("Exit", 60, 220 + (math.max(4, #self.trades) + 1 - self.item_offset) * 40)
	end
	Draw.setColor(Game:getSoulColor())
	Draw.draw(self.heart_sprite, 30, 230 + ((self.current_selected_item - self.item_offset) * 40))
	
	local current_bounty = self.bounties[self.current_selected_item]
	local box_left, box_top = self.info_box:getBorder()

	local left = self.info_box.x - self.info_box.width - (box_left / 2) * 1.5
	local top = self.info_box.y - self.info_box.height - (box_top / 2) * 1.5
	local width = self.info_box.width + box_left * 1.5
	local height = self.info_box.height + box_top * 1.5

	Draw.pushScissor()
	Draw.scissor(left, top, width, height)

	Draw.setColor(COLORS.white)
	love.graphics.print(self.current_trade_text, left + 32, top + 20)
	Draw.popScissor()
end

function Shop:drawStates()
    super.drawStates(self)
	
    if self.state == "LOYALTYMENU" then
        self:drawLoyaltyItems(true)
        self:drawLoyaltyItemDisplay()

        if not self.hide_storage_text then
            if Game:getConfig("newShopSpaceUI") then
                self:drawStorageDisplay()
            else
                self:drawOldStorageDisplay()
            end
        end
        self:drawLoyalty()
	elseif self.state == "LOYALTYCONFIRM" then
        self:drawLoyaltyItems(false)
        self:drawLoyaltyConfirm()
        self:drawLoyaltyItemDisplay()

        if not self.hide_storage_text then
            if Game:getConfig("newShopSpaceUI") then
                self:drawStorageDisplay()
            else
                self:drawOldStorageDisplay()
            end
        end
        self:drawLoyalty()
	elseif self.state == "BONUSCONFIRM" then
		self:drawBonusConfirm()
		self:drawMoney()
	elseif self.state == "BONUS" then
		self:drawBonus()
		self:drawMoney()
	elseif self.state == "STOCKVIEW" then
		self:drawStockView()
		self:drawMoney()
	elseif self.state == "STOCKMODIFY" then
		self:drawStockModify()
		self:drawMoney()
	elseif self.state == "BOUNTIES" then
		self:drawBounties()
	elseif self.state == "TRADING" then
		self:drawTrading()
    end
	
	if self.can_haggle then
		love.graphics.setColor({1, 1, 1})
		love.graphics.setFont(Assets.getFont("main", 16))
		love.graphics.rectangle("fill", 38, 18, 564, 14)
		love.graphics.print("Hag-O-Bar: " .. self.haggle_current .. "/" .. self.haggle_max .. " (" .. math.floor(self.haggle_rate * 100) .. "% Price)", 38, 2)
		love.graphics.setColor({0, 0, 0})
		love.graphics.rectangle("fill", 40, 20, 560, 10)
		love.graphics.setColor({0, 1, 0})
		love.graphics.rectangle("fill", 40, 20, 560 * self.haggle_current / self.haggle_max, 10)
		love.graphics.setColor({1, 1, 1})
		for k,v in pairs(self.haggle_marks) do
			love.graphics.rectangle("fill", 39 + 560 * v[1] / self.haggle_max, 23, 2, 4)
		end
	end
end

function Shop:startCutscene(group, id, ...)
	if self.cutscene and not self.cutscene.ended then
        local cutscene_name = ""
        if type(group) == "string" then
            cutscene_name = group
            if type(id) == "string" then
                cutscene_name = group.."."..id
            end
        elseif type(group) == "function" then
            cutscene_name = "<function>"
        end
        error("Attempt to start a cutscene "..cutscene_name.." while already in cutscene "..self.cutscene.id)
    end
    if Kristal.Console.is_open then
        Kristal.Console:close()
    end
    self.cutscene = ShopCutscene(group, id, ...)
    return self.cutscene
end

function Shop:hasCutscene()
    return self.cutscene and not self.cutscene.ended
end

function Shop:stopCutscene()
    if not self.cutscene then
        error("Attempt to stop a cutscene while none are active.")
    end
    self.cutscene:onEnd()
    coroutine.yield(self.cutscene)
    self.cutscene = nil
end

return Shop