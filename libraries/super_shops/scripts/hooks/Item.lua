local Item, super = Utils.hookScript(Item)

function Item:init()
	super.init(self)
	
	self.loyalty_price = 0
end

function Item:getLoyaltyPrice() return self.loyalty_price end

function Item:getDiscountPrice() return false end

return Item