require("tract")
require("slider")
require("qaudio")
--print console directly
io.stdout:setvbuf("no")


width = 1000
height = 640

globaltime = 0

timer = 0

t = 0
movt = 0 

env = 0

sample = 0

mouseX = 0
mouseY = 0
mousePX = 0
mousePY = 0
mouseX_ = 0
mouseY_ = 0

slomo = true

p = 0


lambda1 = 0
lambda2 = 0


fricativeNoise = 0
fricativeFilter = Filter()

--love.window.setMode(width,height,{vsync=true,fullscreen=true,fullscreentype = "desktop",borderless = true, y=0}) 
love.window.setMode(width,height,{vsync=true,fullscreen=false,fullscreentype = "desktop",borderless = false}) 

updateshape = true

function dsp(time)
	timer = timer + 1
	if(keyOn) then
		env = env + (1-env)*0.0005
	else
		env = env*0.9992
	end

	t = t + 1/44100

	movt = movt + sliderMove.val*1/44100
	

	mouseX_ = (mousePX*(1.0-lambda1) + mouseX*lambda1)/width
	mouseY_ = (mousePY*(1.0-lambda1) + mouseY*lambda1)/height
	mouseY_ = math.min(mouseY_*2,1)

	

	fricativeNoise = fricativeFilter.processBp(math.random()-0.5)

	--upsample x2
	local out = tract:update(lambda1)
	out = out + tract:update(lambda2)

	--bad interpolation by averaging two samples
	out = clip(out*0.5)

	return out
end


function love.load()
	math.randomseed(os.time())
	love.math.setRandomSeed(os.time())
	love.window.setTitle("creature synth")
	love.graphics.setLineWidth(1)

	
	

	fricativeFilter.update(800/44100,1)


	Quadio.load()
	Quadio.setCallback(dsp)

	sliders = {}
	sliderSize = Slider:new("size",height*0.6,"full",0.3,0,1)
	table.insert(sliders, sliderSize)
	sliderMove = Slider:new("movement",height*0.75,"left",1,-3,3)
	table.insert(sliders, sliderMove)
	sliderRes = Slider:new("resonance",height*0.75,"right",0.4,0.0,0.75)
	table.insert(sliders, sliderRes)
	sliderThroat = Slider:new("throat",height*0.9,"left",0.5,0.2,0.7)
	table.insert(sliders, sliderThroat)
	sliderReverb = Slider:new("reverb",height*0.9,"right",0.6,0.0,1.0)
	table.insert(sliders, sliderReverb)





	tract = Tract:new()
	tract:reshape()
end


function love.update(dt)
	--print(tract.sx,tract.sv)
	updateshape = false
	--print(resonator.root*44100)

	mousePX = mouseX
	mousePY = mouseY

	mouseX,mouseY = love.mouse.getPosition()


	globaltime = globaltime + dt
	
	for i,v in ipairs(sliders) do
		v:update()
	end

	if slomo then
		dsp()
	else
		Quadio.update()
	end

	if updateshape then
		tract:reshape()
	end

	keyOn = love.mouse.isDown(1)



	slomo = love.keyboard.isDown('s')

	
	
end


function love.draw()
	love.graphics.setBackgroundColor(0,0,0)
	love.graphics.setColor(1,1,1)

	tract:draw()

	love.graphics.line(0,height*0.5,width,height*0.5)

	for i,v in ipairs(sliders) do
		v:draw()
	end

	--love.graphics.print("FPS: "..tostring(love.timer.getFPS( )),10,20)
end


function love.keypressed(key)
	if key == "escape" then
		love.event.quit( )
	end
end

function love.keyreleased(key)
	
end


function love.mousepressed(x, y, button, istouch)
	for i,v in ipairs(sliders) do
		v:mousepressed(x,y)
	end
end

function love.mousereleased(x, y, button, istouch)
	for i,v in ipairs(sliders) do
		v:mousereleased(x,y)
	end
	if sliderReverb.val > 0.02 then
		love.audio.setEffect('reverb', {
			type = 'reverb',
			gain = 0.3 - sliderReverb.val*0.15,
			decaytime = sliderReverb.val*4.0,
		})
	else
		love.audio.setEffect('reverb', {
			type = 'reverb',
			gain = 0,
			decaytime = 1.0,
		})
	end
end
