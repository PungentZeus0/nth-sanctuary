local BattleUI, super = HookSystem.hookScript(BattleUI)

function BattleUI:draw()
    super.draw(self)
    love.graphics.translate(0,30)
    if Game.battle.state == "DEFENDING" then
        self.adraw2 = self.adraw2 + 4*DT
        self.adraw2 = MathUtils.clamp(self.adraw2, 0, 1)
        for e, party in ipairs(Game.battle.party) do
            if e > 3 then
                local col = (e - 4) % 5        -- 0,1,2,3,4, 0,1,2,3,4...
                local row = math.floor((e - 4) / 5)  -- 0,0,0,0,0, 1,1,1,1,1...

                local x = 130 * col
                local y = 10 + 40 * row

                local tex = self.action_boxes[e].head_sprite.texture
                local col = (e - 4) % 5        -- 0,1,2,3,4, 0,1,2,3,4...
                local row = math.floor((e - 4) / 5)  -- 0,0,0,0,0, 1,1,1,1,1...

                local x = 130 * col
                local y = 10 + 40 * row

                Draw.setColor(1, 1, 1, self.adraw2)
				if party.chara.id == "lobby_man" then
					local static_shader = Assets.getShader("static_bullet")
					static_shader:send("time", Kristal.getTime())
					static_shader:send("brightness", 0.5)
					love.graphics.setShader(static_shader)
				end
                Draw.draw(tex, x, y)
				love.graphics.setShader()

                local health = (party.chara:getHealth() / party.chara:getStat("health")) * 100
                local color
                if health <= 0 then
                    color = {1, 0, 0, self.adraw2}
                elseif (party.chara:getHealth() <= (party.chara:getStat("health") / 4)) then
                    color = {1, 1, 0, self.adraw2}
                else
                    color = {1, 1, 1, self.adraw2}
                end

                Draw.setColor(color)
                love.graphics.setFont(Assets.getFont("smallnumbers"))
                love.graphics.print(party.chara.health.."/"..party.chara.stats.health, x + tex:getWidth() + 5, y + 10)
            end
        end
    else
        self.adraw2 = 0
    end

    love.graphics.translate(0,-360)
    if Input.down("showhealth") then
        self.adraw = self.adraw + 4*DT
        self.adraw = MathUtils.clamp(self.adraw, 0, 1)
        Draw.setColor(0,0,0,self.adraw-0.6)
        Draw.rectangle("fill",0,0,SCREEN_WIDTH, (#Game.battle.party * 30)+ 13)
        for k, party in ipairs(Game.battle.party) do
            local head = Assets.getTexture(party.chara:getHeadIcons().."/head")
            local name = Assets.getTexture(party.chara:getNameSprite())
            Draw.setColor(1,1,1,self.adraw)
			if party.chara.id == "lobby_man" then
				local static_shader = Assets.getShader("static_bullet")
				static_shader:send("time", Kristal.getTime())
				static_shader:send("brightness", 0.5)
				love.graphics.setShader(static_shader)
			end
            Draw.draw(head, 15, 10 + 30*(k-1))
			love.graphics.setShader()
            Draw.draw(name, 65, 15 + 30*(k-1))

			local health_bg_col = PALETTE["action_health_bg"]
			if party.chara.id == "lobby_man" then
				health_bg_col = COLORS.dkgray
			end
            Draw.setColor(health_bg_col)
            Draw.rectangle("fill", 140, (30*(k-1))+name:getHeight()+3, 100, 10)
            local health = (party.chara:getHealth() / party.chara:getStat("health")) * 100
            Draw.setColor(party.chara.color[1], party.chara.color[2], party.chara.color[3], self.adraw)
			if party.chara.id == "lobby_man" then
				Draw.setColor(1, 1, 1, self.adraw)
				local static_shader = Assets.getShader("static_bullet")
				static_shader:send("time", Kristal.getTime())
				static_shader:send("brightness", 1)
				love.graphics.setShader(static_shader)
			end
            if health > 0 then
                Draw.rectangle("fill", 140, (30*(k-1))+name:getHeight()+3, math.ceil(health), 10)
            end
			love.graphics.setShader()

            local g = Assets.getFont("smallnumbers")
            local h = (30*(k-1))+name:getHeight()+3

            love.graphics.setFont(g)
            local color = PALETTE["action_health_text"]

            if health <= 0 then
                color = PALETTE["action_health_text_down"]
            elseif (party.chara:getHealth() <= (party.chara:getStat("health") / 4)) then
                color = PALETTE["action_health_text_low"]
            else
                color = PALETTE["action_health_text"]
            end

            local health_offset = (#tostring(party.chara:getHealth()) - 1) * 8

            Draw.setColor(color[1], color[2], color[3], self.adraw)
            love.graphics.print(party.chara:getHealth(), 250, h)
            Draw.setColor(PALETTE["action_health_text"])
            love.graphics.print("/", (260+health_offset), h)
            local string_width = g:getWidth(tostring(party.chara:getStat("health")))
            Draw.setColor(color[1], color[2], color[3], self.adraw)
            love.graphics.print(party.chara:getStat("health"), (280 + health_offset), h)
        end
    else
        self.adraw = 0
    end
end

function BattleUI:drawState()
	super.drawState(self)
    if Game.battle.state == "MENUSELECT" then
        local page = math.ceil(Game.battle.current_menu_y / 3) - 1
        local max_page = math.ceil(#Game.battle.menu_items / 6) - 1

        local x = 0
        local y = 0
        local font = Assets.getFont("main")
        love.graphics.setFont(font)

        local page_offset = page * 6
        for i = page_offset + 1, math.min(page_offset + 6, #Game.battle.menu_items) do
            local item = Game.battle.menu_items[i]

            Draw.setColor(1, 1, 1, 1)
            local text_offset = 0
            -- Are we able to select this?
            local able = Game.battle:canSelectMenuItem(item)
            if item.party then
                if not able then
                    -- We're not able to select this, so make the heads gray.
                    Draw.setColor(COLORS.gray)
                end

                for index, party_id in ipairs(item.party) do
                    local chara = Game:getPartyMember(party_id)

                    -- Draw head only if it isn't the currently selected character
                    if Game.battle:getPartyIndex(party_id) ~= Game.battle.current_selecting then
						if chara.id == "lobby_man" then
							local static_shader = Assets.getShader("static_bullet")
							static_shader:send("time", Kristal.getTime())
							static_shader:send("brightness", 0.5)
							love.graphics.setShader(static_shader)
						end
                        local ox, oy = chara:getHeadIconOffset()
                        Draw.draw(Assets.getTexture(chara:getHeadIcons() .. "/head"), text_offset + 30 + (x * 230) + ox, 50 + (y * 30) + oy)
						love.graphics.setShader()
                        text_offset = text_offset + 30
                    end
                end
            end

            if item.icons then
                for _, icon in ipairs(item.icons) do
                    if type(icon) == "string" then
                        icon = { icon, false, 0, 0, lobby_man }
                    end
                    if not icon[2] then
                        local texture = Assets.getTexture(icon[1])
                        text_offset = text_offset + (icon[5] or texture:getWidth())
                    end
                end
            end

            if able then
                -- Using color like a function feels wrong... should this be called getColor?
                Draw.setColor(item:color() or { 1, 1, 1, 1 })
				if item.name == Game.battle.party[Game.battle.current_selecting].chara:getXActName() and Game.battle.party[Game.battle.current_selecting].chara.id == "lobby_man" then
					local static_shader = Assets.getShader("static_bullet")
					static_shader:send("time", Kristal.getTime())
					static_shader:send("brightness", 0.3)
					love.graphics.setShader(static_shader)
				end
            else
                Draw.setColor(COLORS.gray)
            end
            love.graphics.print(item.name, text_offset + 30 + (x * 230), 50 + (y * 30))
            text_offset = text_offset + font:getWidth(item.name)
			love.graphics.setShader()

            if item.icons then
                if able then
                    Draw.setColor(1, 1, 1)
                end
                for _, icon in ipairs(item.icons) do
                    if type(icon) == "string" then
                        icon = { icon, false, 0, 0, lobby_man }
                    end
                    if icon[2] then
                        local texture = Assets.getTexture(icon[1])
                        text_offset = text_offset + (icon[5] or texture:getWidth())
                    end
                end
            end

            if x == 0 then
                x = 1
            else
                x = 0
                y = y + 1
            end
        end
	elseif Game.battle.state == "ENEMYSELECT" then 
		local enemies = Game.battle.enemies_index
        local page = math.ceil(Game.battle.current_menu_y / 3) - 1
        local max_page = math.ceil(#enemies / 3) - 1
        local page_offset = page * 3
        Draw.setColor(1, 1, 1, 1)
        local font = Assets.getFont("main")
        love.graphics.setFont(font)
        local draw_mercy = Game:getConfig("mercyBar")
        local draw_percents = Game:getConfig("enemyBarPercentages")
        for index = page_offset + 1, math.min(page_offset + 3, #enemies) do
            local enemy = enemies[index]
            local y_off = (index - page_offset - 1) * 30

            if enemy then
                if Game.battle.state_reason == "XACT" then
					if Game.battle.party[Game.battle.current_selecting].chara.id == "lobby_man" then
						Draw.setColor(COLORS.white)
						local static_shader = Assets.getShader("static_bullet")
						static_shader:send("time", Kristal.getTime())
						static_shader:send("brightness", 0.3)
						love.graphics.setShader(static_shader)
					else
						Draw.setColor(Game.battle.party[Game.battle.current_selecting].chara:getXActColor())					
					end
                    if Game.battle.selected_xaction.id == 0 then
                        love.graphics.print(enemy:getXAction(Game.battle.party[Game.battle.current_selecting]), self.xact_x_pos, 50 + y_off)
                    else
                        love.graphics.print(Game.battle.selected_xaction.name, self.xact_x_pos, 50 + y_off)
                    end
					love.graphics.setShader()
				else
                    local hp_percent = enemy.health / enemy.max_health

                    local hp_x = draw_mercy and 420 or 510

                    if enemy.selectable and enemy.static_hp then
                        -- Draw the enemy's HP
                        Draw.setColor(COLORS.dkgray)
                        love.graphics.rectangle("fill", hp_x, 55 + y_off, 81, 16)

                        Draw.setColor(COLORS.white)
						local static_shader = Assets.getShader("static_bullet")
						static_shader:send("time", Kristal.getTime())
						static_shader:send("brightness", 1)
                        love.graphics.setShader(static_shader)
                        love.graphics.rectangle("fill", hp_x, 55 + y_off, math.ceil(hp_percent * 81), 16)
                        love.graphics.setShader()

                        if draw_percents then
							love.graphics.stencil(function()
								local last_shader = love.graphics.getShader()
								love.graphics.setShader(Kristal.Shaders["Mask"])
								love.graphics.rectangle("fill", hp_x, 55 + y_off, math.ceil(hp_percent * 81), 16)
								love.graphics.setShader(last_shader)
							end, "replace", 1)
							love.graphics.setStencilTest("greater", 0)
                            Draw.setColor(COLORS.black)
                            love.graphics.print(enemy:getHealthDisplay(), hp_x + 4, 55 + y_off, 0, 1, 0.5)
							love.graphics.setStencilTest("less", 1)
                            Draw.setColor(COLORS.white)
                            love.graphics.print(enemy:getHealthDisplay(), hp_x + 4, 55 + y_off, 0, 1, 0.5)
							love.graphics.setStencilTest()
                        end
                    end
                end
			end
        end
    elseif Game.battle.state == "PARTYSELECT" then
        local page = math.ceil(Game.battle.current_menu_y / 3) - 1
        local max_page = math.ceil(#Game.battle.party / 3) - 1
        local page_offset = page * 3

        local font = Assets.getFont("main")
        love.graphics.setFont(font)

        for index = page_offset + 1, math.min(page_offset + 3, #Game.battle.party) do
            if Game.battle.party[index].chara.id == "lobby_man" then
				Draw.setColor(COLORS.dkgray)
				love.graphics.rectangle("fill", 400, 55 + ((index - page_offset - 1) * 30), 101, 16)

				local percentage = Game.battle.party[index].chara:getHealth() / Game.battle.party[index].chara:getStat("health")
				-- Chapter 3 introduces this lower limit, but all chapters in Kristal might as well have it
				-- Swooning is the only time you can ever see it this low
				percentage = math.max(-1, percentage)
				Draw.setColor(COLORS.white)
				local static_shader = Assets.getShader("static_bullet")
				static_shader:send("time", Kristal.getTime())
				static_shader:send("brightness", 1)
				love.graphics.setShader(static_shader)
				love.graphics.rectangle("fill", 400, 55 + ((index - page_offset - 1) * 30), math.ceil(percentage * 101), 16)
				love.graphics.setShader()
			end
			if Game.battle.party[index].chara:hasAssist() then
				Draw.setColor(PALETTE["action_health_bg"])
				love.graphics.rectangle("fill", 400, 55 + ((index - page_offset - 1) * 30), 101, 8)
				
				local percentage = Game.battle.party[index].chara:getAssistHealth() / Game.battle.party[index].chara:getStat("assist_health")
				percentage = math.max(-1, percentage)
				Draw.setColor(Game.battle.party[index].chara.assist_color)
				love.graphics.rectangle("fill", 400, 55 + ((index - page_offset - 1) * 30), math.ceil(percentage * 101), 8)
			end
        end
    end
end

return BattleUI