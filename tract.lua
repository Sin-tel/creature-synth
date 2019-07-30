require("filter")
Tract = {}

function Tract:new()
	local new = {}	
	setmetatable(new, self)
	self.__index = self

	--20 to 200
	new.n = 200--44    --20*math.pow(10,param)
	new.R = {}
	new.L = {}
	new.junctionR = {}
	new.junctionL = {}
	new.diameter = {}
	new.dRest = {}
	new.k = {}
	new.knew = {}

	new.glottalRefl = 0.75--0.75
	new.lipRefl = -.85

	new.lip = Filter()
	new.lip.update(200/44100,5)



	for i = 1,new.n+1 do
		new.R[i] = 0
		new.L[i] = 0
		new.junctionR[i] = 0
		new.junctionL[i] = 0
		
		local d = 0
		if i < 7*new.n/44 - 0.5 then
			d = 0.6
		elseif i < 12*new.n/44 then
			d = 1.1
		else
			d = 1.5
		end
		new.diameter[i] = d
		new.dRest[i] = d

		
		new.k[i] = 0
		new.knew[i] = 0
		
	end

	new.sv = 0
	new.sx = 0

	new.filter = 0
	new.filter2 = 0

	new.osc = 0

	return new
end

function Tract:reshape()
	self.n = math.floor(20*math.pow(10,sliderSize.val))

	for i = 1,self.n do
		local x = (mouseX_*(self.n+2))
		local f = math.exp(-10*(x-i)*(x-i)/self.n)
		local y = (1.0-mouseY_)*1.5

		
		local s = i*35/self.n*(i/self.n)
		local m = 0.5+0.5*math.tanh(10*(i/self.n-0.8))

		local d = (0.15+0.4*math.sin(0.2*s + movt*0.2) + 2*love.math.noise(0.08*s - movt*1) + 0.03*s*(1.0-mouseY_))*(1.0-m*(mouseY_))
		--local d = (0.14+0.5*math.sin(0.2*s + t*0.2) + 2*love.math.noise(0.08*s - t*0.2) + 0.03*s*(1.0-mouseY_))*(1.0-m*(mouseY_))
		local ff = 0.5+0.5*math.tanh(10*(i/self.n-0.2))
		self.diameter[i] = d*ff + sliderThroat.val*(1.0-ff)

		--self.diameter[i] = self.diameter[i]*(1.0-f) + y*f

		--self.diameter[i] = self.dRest[i]* (1.0 - math.exp(-20*(i/self.n - mouseX_)^2)*mouseY_) +0.1* love.math.noise( 5*i/self.n, t*2 )
		
	
		if(self.diameter[i] < 0.01) then
			self.diameter[i] = 0.01
		end
	end

	for i = 2,self.n do

		local A1 = self.diameter[i-1]*self.diameter[i-1]
		local A2 = self.diameter[i]*self.diameter[i]
		self.k[i] = self.knew[i]
		self.knew[i] = (A1-A2)/(A1+A2)
	end

	self.glottalRefl = sliderRes.val
end

function Tract:update(lambda)
	if(timer > 100) then
		--200 for largest, 800 for smallest
		local f = (200*math.pow(4,(1-sliderSize.val)))*mouseX_*(1.0 + 0.08*love.math.noise( t*8 ) + 0.03*love.math.noise( t*16 ))

		--f = 200
		--local f = 10*math.pow(2,6*mouseX_ + 0.2*love.math.noise( t*8 ) + 0.1*love.math.noise( t*16 ))

		self.lip.update(f/44100,15)
		timer = 0
	end

	updateshape = true

	--add turbulence noise
	for i = 1,self.n do
		local d = self.diameter[i]
		local r = self.R[i]
		local l = self.L[i]

		local flow = math.abs(r-l)/(d*d)
		local turb = math.min(math.max((flow-4)*0.05,0),1) * math.min(math.max(15*(d-0.05),0),1)
		turb = turb*0.05

		local noise = fricativeNoise--*0.05
		self.R[i] = self.R[i]*(1.0-turb) + noise*turb
		self.L[i] = self.L[i]*(1.0-turb) + noise*turb
	end

	--brass style model
	local r = self.L[1]*1.5

	local p = (1-mouseY_)*0.8*env*(1-0.5*mouseX_)*(1.6-sliderThroat.val)

	r = r + p 
	
	r = self.lip.process(r)
	r = r*r*p*2

	r = clip(r*2)

	self.osc = r 


	local a = 0.99--math.exp(-5*mouseY_)
	self.filter = self.filter*(1-a) + self.osc*a
	a = 0.01
	self.filter2 = self.filter2*(1-a) + self.filter*a
	--r = (self.filter - self.filter2)

	r = self.filter

	--local input  = (math.random() - 0.5)*0.2
	--local input  = math.sin(osc*math.pi*2 + 2*math.sin(osc*math.pi*2))*0.3
	local input  = r + self.L[1]*self.glottalRefl
	self.junctionR[1] = input
	self.junctionL[self.n+1] = self.R[self.n]*self.lipRefl

	for i = 2,self.n do
		local k = self.k[i]*(1.0-lambda) + self.knew[i]*lambda
		local w = k*(self.R[i-1] + self.L[i])
		self.junctionR[i] = self.R[i-1] - w
		self.junctionL[i] = self.L[i] + w		
	end

	for i = 1,self.n do
		self.R[i] = self.junctionR[i]
		self.L[i] = self.junctionL[i+1]
	end



 	local out = self.R[self.n]

	return out
end

function Tract:draw()
	love.graphics.push()
	love.graphics.translate(width*0.2,height*0.25)

	local ys = -50
	local xs = width*0.6/(self.n-1)

	for i = 1,self.n-1 do

		local d1 = self.diameter[i]
		local d2 = self.diameter[i+1]
		
		local r1 = self.R[i]
		local r2 = self.R[i+1]
		local l1 = self.L[i]
		local l2 = self.L[i+1]

		local flow1 = math.abs(r1-l1)/(d1*d1)
		local turb1 = math.min(math.max((flow1-4)*0.05,0),1) * math.min(math.max(15*(d1-0.05),0),1)

		local flow2 = math.abs(r2-l2)/(d2*d2)
		local turb2 = math.min(math.max((flow2-4)*0.05,0),1) * math.min(math.max(15*(d2-0.05),0),1)
		



		love.graphics.setColor(0,.8,0)
		--love.graphics.line(i*xs,r1*ys,(i+1)*xs,r2*ys)
		--love.graphics.setColor(.8,0,0)
		--love.graphics.line(i*xs,l1*ys,(i+1)*xs,l2*ys)

		
		--love.graphics.line(i*xs,(l1+r1)*ys,(i+1)*xs,(l2+r2)*ys)
		--love.graphics.line(i*xs,(r1-l1)*ys/(d1*d1),(i+1)*xs,(r2-l2)*ys/(d2*d2))
		love.graphics.line((i-1)*xs,turb1*ys,(i)*xs,turb2*ys)
		love.graphics.setColor(.8,0,0)
		love.graphics.line((i-1)*xs,(l1+r1)*ys/(d1),(i)*xs,(l2+r2)*ys/(d2))

		love.graphics.setColor(1,1,1)
		local s = 10
		love.graphics.line((i-1)*xs,d1*ys,(i)*xs,d2*ys)
		love.graphics.line((i-1)*xs,-d1*ys,(i)*xs,-d2*ys)

	end

	
	love.graphics.pop()

end


