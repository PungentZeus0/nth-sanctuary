local MouseHole, super = Class(Shop)

function MouseHole:init()
    super.init(self)
    self.shop_music = "vape_shop"
    self.encounter_text = "[friend]* Hello, you alls.\nTake a load off.\n[wait:10]\n* Not like we've anything else to do."
    self.shop_text = "[friend][wave]* Take a load off."
    self.leaving_text = "[friend]* See you around."
    self.buy_menu_text = "[friend]What'll it be?"
    self.buy_confirmation_text = "Costs \n%s ."
    self.buy_refuse_text = "[friend]Maybe next time?"
    self.buy_text = "[friend]Thank you."
    self.buy_storage_text = "[friend]You'll find that in your storage."
    self.buy_too_expensive_text = "[friend]Not\nenough."
    self.buy_no_space_text = "[friend]You're\ncarrying\ntoo much, [wait:5]eh?"
    self.sell_no_price_text = "[friend]You should keep it."
    self.sell_menu_text = "[friend]Toss your junk."
    self.sell_nothing_text = "[friend]* Nothin' there."
    self.sell_confirmation_text = "I can pay\n%s ."
    self.sell_refuse_text = "[friend]Maybe next time?"
    -- Shown when you sell something
    self.sell_text = "Thank you."
    -- Shown when you have nothing in a storage
    self.sell_no_storage_text = "[friend]* Nothin' there."
    -- Shown when you enter the talk menu.
    self.talk_text = "[friend]Talk to me."

    self.sell_options_text = {}
    self.sell_options_text["items"]   = "[friend]* Let's see what you got."
    self.sell_options_text["weapons"] = "[friend]* Let's see what you got."
    self.sell_options_text["armors"]  = "[friend]* Let's see what you got."
    self.sell_options_text["storage"] = "[friend]* Let's see what you got."

    self.background = "shops/mousehole_background"
    self.background_speed = 5/30

    self.shopkeeper:setActor("shopkeepers/vaporguy")
    self.shopkeeper.sprite:setPosition(0, 8)
    self.shopkeeper.slide = true

    self:registerItem("tensionbit")
    for _, party in ipairs(Game.party) do
        self:registerItem("brews/"..party.id)
    end

    self:registerTalk("About Yourself")
    self:registerTalk("About Wall Guardian")
    self:registerTalk("Cheese Key")

    self:registerTalkAfter("Cheese?", 1)
    self:registerTalkAfter("Picture Frame", 2, "talk_2", 1)
    self:registerTalkAfter("Together", 2, "talk_2", 2)
end

function MouseHole:postInit()
    super.postInit(self)
    local a = VaporSun()
    a.x, a.y = SCREEN_WIDTH/2, a.height
    self:addChild(a)
    self.shopkeeper:setLayer(SHOP_LAYERS["above_boxes"])
end

function MouseHole:startTalk(talk)
    if talk == "About Yourself" then
        self:startDialogue({
            "[emote:idle]* Oh, there's not much to say about little old me.",
            "[emote:left]* I'm just a humble shopkeeper,[wait:5] is all.\n[wait:5]* Small business passed down through the generations,[wait:5] and I just happen to be the one running it now.",
            "[emote:explaining]* I mean, [wait:5]I really like seeing everything that passes through my shop.\n[wait:5]* There's always interesting things from outsiders!",
            "[emote:happy]* Some of the regulars even bring me a little snack from time to time.\n[wait:5]* It's really nice."
        })
    elseif talk == "Cheese?" then
        self:startDialogue({
            "[emote:idle]* You wanna talk about...[wait:5] cheese?",
            "[emote:left]* I mean, what is there to even say about it?\n[wait:5]* It's,[wait:5] well,[wait:5] just cheese.\n[wait:5]* The perfect food.",
            "[emote:explaining]* Wh-[wait:5]no, [wait:5]I'm not addicted, [wait:5]I can stop any time I want, [wait:5]alright?"
        })
    elseif talk == "About Wall Guardian" then
        self:setFlag("talk_2", 1)
        self:startDialogue({
            "[emote:left]* Wallie? [wait:5]He's a good friend of mine.",
            "* He's been here for...[wait:5] well,[wait:5] as long as I can remember.\n[wait:5]* He even showed me around when I first got here.",
            "[emote:idle]* Saying things like,[wait:5] \"Wall Here. No Wall over There.\"",
            "* He was a lot more helpful than it sounds,[wait:5] believe me."
        })
    elseif talk == "Picture Frame" then
        self:setFlag("talk_2", 2)
        self:startDialogue({
            "[emote:left]* Oh, [wait:5]that...?\n[wait:5]* I keep forgetting I put that there.",
            "[emote:idle]* Pay no attention to it,[wait:5] it's just..."
        })
    elseif talk == "Together" then
        self:startDialogue({
            "[emote:left]* U-us? [wait:5]No, [wait:5]we're not... [wait:5]I-I mean, [wait:5]I don't have much goin' for me.",
            "[emote:happy]* That's all!!"
        })
    elseif talk == "Cheese Key" then
        self:startDialogue({
            "[emote:idle]* Oh,[wait:5] why the shop's locked behind a key?",
            "[emote:left]* Well, [wait:5]we can't have just anyone coming in,[wait:5] cause we've had some nasty visitors in the past.",
            "[emote:idle]* That's why we give trusted customers a key to the shop.",
            "[emote:idle]* The littlest ones can come in without it,[wait:5] though.",
            "[emote:left]* I don't wanna turn anyone away,[wait:5]\nbut it's a system we've had for some time now.",
            "[emote:left]* The fact that you found one,[wait:5] though...",
            "[emote:idle]* Well,[wait:5] the fact you tried so hard to get in,[wait:5] I guess that means you can be trusted.",
            "[emote:happy]* Plus,[wait:5] I wanna see what you've got."
        })
    end
end

return MouseHole
