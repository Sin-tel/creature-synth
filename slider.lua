Slider = {}

function Slider:new(label,y,t,def,min,max)
	local new = {}	
	setmetatable(new, self)
	self.__index = self


	if t == "full" then
		new.x = width*0.15
		new.y = y
		new.w = width*0.7
	elseif t == "left" then
		new.x = width*0.15
		new.y = y
		new.w = width*0.3
	elseif t == "right" then
		new.x = width*0.55
		new.y = y
		new.w = width*0.3
	end

	new.val = def or 0

	new.min = min or 0
	new.max = max or 1

	new.label = label or ""

	new.selected = false

	new.hover = false

	return new
end

function Slider:checkDist(x,y)
	local fr = (self.val - self.min)/(self.max-self.min)
	local sx = self.x + self.w*fr
	local sy = self.y

	local dist = math.sqrt((sx-x)^2 + (sy-y)^2)
	if dist < 25 then
		return true
	end
	return false
end

function Slider:mousepressed(x,y)
	self.selected = self:checkDist(x,y)
end

function Slider:mousereleased()
	self.selected = false
end

function Slider:update()
	if self.selected then
		local f = (mouseX-self.x)/self.w

		--print(f)

		self.val = f*(self.max-self.min) + self.min

		print(self.val)
	end

	self.hover = self:checkDist(mouseX,mouseY)

	self.val = math.min(math.max(self.val,self.min),self.max)
end

function Slider:draw()
	love.graphics.setColor(1,1,1)
	
	love.graphics.line(self.x,self.y,self.x+self.w,self.y)
	local c = 0
	if self.selected then
		c = 1.0
	elseif self.hover then
		c = 0.4
	end

	local fr = (self.val - self.min)/(self.max-self.min)

	love.graphics.setColor(c,c,c)
	love.graphics.circle("fill", self.x + self.w*fr, self.y, 15,30)
	love.graphics.setColor(1,1,1)
	love.graphics.circle("line", self.x + self.w*fr, self.y, 15, 30)

	--love.graphics.print(math.floor(self.val*100)/100, self.x + self.w + 20 , self.y-8)
	love.graphics.print(self.label, self.x + 0 , self.y-32)
end