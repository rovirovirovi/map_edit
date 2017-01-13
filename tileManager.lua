[[
#   map_edit
#
#   Copyright (C) 2016-2017 Rosca Valentin
#
#   This project is free software; you can redistribute it and/or modify it
#   under the terms of the GNU v3 license. See LICENSE.md for details.
]]

require "camera"


tileManager = {}
tileManager.__index = tileManager

function tileManager.create(world)
	local self = {}
	setmetatable(self, tileManager)
	self.world = world
	self.blocks = {}
	self.tiles = {}
	self.isDrawing = false
	self.startX = 0
	self.startY = 0
	self.endX = 0
	self.endY = 0
	self.selectedTile = 1
	self.tileImage = love.graphics.newImage("tile.png")
	self.tileImage:setFilter("nearest", "nearest")
	self.blocksToBeDeleted = {}
	self.pressedSave = false
	self.pressedLoad = false

	self.buttons = {}
	self:addButton(1)
	self:addButton(2)
	self:addButton(3)
	return self
end

function tileManager:update(dt)
	if love.keyboard.isDown("q") then
		self.selectedTile = 1
	end
	if love.keyboard.isDown("e") then
		self.selectedTile = 2
	end
	
	if not self.pressedSave and love.keyboard.isDown("b") then
		self:saveTiles()
		self:saveCollisionBlocks()
		self.pressedSave = true
	end
	if self.pressedSave and not love.keyboard.isDown("b") then
		self.pressedSave = false

	end

	if not self.pressedLoad and love.keyboard.isDown("n") then
		self:loadTiles()
		self:loadCollisionBlocks()
		self.pressedLoad = true
	end
	if self.pressedLoad and not love.keyboard.isDown("n") then
		self.pressedLoad = false

	end

	if love.mouse.isDown("l") and not self.isDrawing then
		self.startX = math.floor(camera:getMouseX() / 16)
		self.startX = self.startX * 16
		self.startY = math.floor(camera:getMouseY() / 16)
		self.startY = self.startY * 16
		self.isDrawing = true
	end
	if not love.mouse.isDown("l") and self.isDrawing then
		self.endX = math.floor(camera:getMouseX() / 16)
		self.endX = self.endX * 16
		self.endY = math.floor(camera:getMouseY() / 16)
		self.endY = self.endY * 16
		self.isDrawing = false

		local x, y, w, h
		x = math.min(self.startX, self.endX)
		y = math.min(self.startY, self.endY)
		if x == self.startX then
			w = self.endX - self.startX
		else
			w = self.startX - self.endX
		end
		if y == self.startY then
			h = self.endY - self.startY
		else
			h = self.startY - self.endY
		end

		if w ~= 0 and h ~= 0 then
			self:fillTiles(x,y,w,h, self.selectedTile)
			self:addCollisionBlock(x,y,w,h)
		else
			self:checkClick()
		end
	end

	--Remove tiles
	if love.mouse.isDown("r") then
		self:removeTile(math.floor(camera:getMouseX() / 16) * 16, math.floor(camera:getMouseY() / 16) * 16)
	end

	if love.mouse.isDown("m") then
		for i, v in ipairs(self.blocks) do
			if camera:getMouseX() >= v.x and camera:getMouseX() <= v.x + v.w and camera:getMouseY() >= v.y and camera:getMouseY() <= v.y + v.h then
				v.inDeletion = 1
			else
				v.inDeletion = 0
			end
		end
	end

	for i = #self.blocks, 1, -1 do
		local v = self.blocks[i]
		if v.inDeletion == 1 and not love.mouse.isDown("m") then
			self.world:remove(self.blocks[i])
			table.remove(self.blocks, i)
		end
	end

	--Update the gui
	self:updateButtons(dt)
end

function tileManager:checkClick()
	for i, v in ipairs(self.buttons) do
		if camera:getMouseX() >= v.x and camera:getMouseX() <= v.x + v.w and camera:getMouseY() >= v.y and camera:getMouseY() <= v.y + v.h then
			self.selectedTile = v.id
			v.s = .7
		end
	end
end

function tileManager:addButton(id)
	local button = {x = 0, y = 0, ox = #self.buttons * 20 + 50, oy = 16, w = 16, h = 16, s = 1, id = id, quad = love.graphics.newQuad(id * 16 - 16, 0, 16, 16, self.tileImage:getDimensions())}
	table.insert(self.buttons, button)
end

function tileManager:drawButtons()
	for i, v in ipairs(self.buttons) do
		love.graphics.draw(self.tileImage, v.quad, v.x, v.y, 0, v.s, v.s)
	end
end

function tileManager:updateButtons(dt)
	for i, v in ipairs(self.buttons) do
		if love.mouse.getY() < 100 then
			if love.mouse.getX() < 50 then
				v.ox = utils.lerp(v.ox, v.ox + 32, dt * 5)
			end
			if love.mouse.getX() > love.window.getWidth() - 50 then
				v.ox = utils.lerp(v.ox, v.ox - 32, dt * 5)
			end
		end
		v.x = camera.x + v.ox
		v.y = camera.y + v.oy
		if v.s < 1 then
			v.s = v.s + dt * 10
		end
	end
end

function tileManager:saveTiles()
	local file = io.open("tiles.lua", "w+")
	io.output(file)
	for i, v in ipairs(self.tiles) do
		io.write("{\n"..v.x.."\n"..v.y.."\n"..v.id.."\n}\n")
	end
	file:close()
end

function tileManager:saveCollisionBlocks()
	local file = io.open("collBlocks.lua", "w+")
	io.output(file)
	for i, v in ipairs(self.blocks) do
		io.write("{\n"..v.x.."\n"..v.y.."\n"..v.w.."\n"..v.h.."\n"..v.inDeletion.."\n}\n")
	end
	file:close()
end

function tileManager:loadTiles()
	local file = io.open("tiles.lua", "r")
	self.tiles = {}
	io.input(file)
	local shouldRead = false
	local readcount = 0
	local x, y, id
	for line in io.lines() do 

		if line == "{" then
			shouldRead = true
		end
		if line == "}" then
			shouldRead = false
			local tile = {x=x,y=y,id=id,quad=love.graphics.newQuad(id*16-16,0,16,16,self.tileImage:getDimensions())}
			table.insert(self.tiles, tile)
			readcount = 0
		end
		if shouldRead then
			if readcount == 1 then
				x = tonumber(line)
			end
			if readcount == 2 then
				y = tonumber(line)
			end
			if readcount == 3 then
				id = tonumber(line)
			end
			readcount = readcount + 1
		end
	end
	file:close()


end

function tileManager:loadCollisionBlocks()
	local file = io.open("collBlocks.lua", "r")
	for i = 1, #self.blocks, 1 do
		self.world:remove(self.blocks[i])
	end
	self.blocks = {}
	io.input(file)
	local shouldRead = false
	local readcount = 0
	local x, y, w, h, inDeletion
	for line in io.lines() do 

		if line == "{" then
			shouldRead = true
		end
		if line == "}" then
			shouldRead = false
			local block = {x=x,y=y,w=w,h=h, inDeletion = inDeletion}
			table.insert(self.blocks, block)
			self.world:add(block, block.x, block.y, block.w, block.h)
			readcount = 0
		end
		if shouldRead then
			if readcount == 1 then
				x = tonumber(line)
			end
			if readcount == 2 then
				y = tonumber(line)
			end
			if readcount == 3 then
				w = tonumber(line)
			end
			if readcount == 4 then
				h = tonumber(line)
			end
			if readcount == 5 then
				inDeletion = tonumber(line)
			end
			readcount = readcount + 1
		end
	end
	file:close()

end

function tileManager:draw()



	--Draw the tiles
	if self.tiles ~= nil then
		for i, v in ipairs(self.tiles) do
			love.graphics.draw(self.tileImage, v.quad, v.x, v.y)
		end
	end
		
	--Draw the rectangle in making
	if love.mouse.isDown("l") then
		love.graphics.setColor(0,0,255)
		local ex = math.floor(camera:getMouseX() / 16)
		ex = ex * 16
		local ey = math.floor(camera:getMouseY() / 16)
		ey = ey * 16
		

		local x, y, w, h
		x = math.min(self.startX, ex)
		y = math.min(self.startY, ey)
		if x == self.startX then
			w = ex - self.startX
		else
			w = self.startX - ex
		end
		if y == self.startY then
			h = ey - self.startY
		else
			h = self.startY - ey
		end
		love.graphics.rectangle("line",x,y,w,h)
	end

	--Draw the collision rectangles
	love.graphics.setColor(0,255,0)
	if self.blocks ~= nil then
		for i, v in ipairs(self.blocks) do
			if v.inDeletion == 0 then
				love.graphics.rectangle("line", v.x, v.y, v.w, v.h)
			else
				love.graphics.setColor(255,0,0)
				love.graphics.rectangle("fill", v.x, v.y, v.w, v.h)
				love.graphics.setColor(0,255,0)
			end
		end
	end
	

	--Draw the gui
	love.graphics.setColor(50,50,50)
	love.graphics.rectangle("fill",camera.x, camera.y, love.window.getWidth() * camera.scaleX, 50)
	love.graphics.setColor(255,255,255)
	self:drawButtons()

end

function tileManager:addCollisionBlock(x, y, w, h)
	local block = {x=x, y=y, w=w, h=h, inDeletion = 0}
	table.insert(self.blocks, block)
	self.world:add(block, block.x, block.y, block.w, block.h)
end

function tileManager:addTile(x,y,id)
	local quad = love.graphics.newQuad(id * 16 - 16, 0, 16, 16, self.tileImage:getDimensions())
	local tile = {x=x,y=y, id=id, quad = quad}
	--self:removeTile(x,y)
	table.insert(self.tiles, tile)
end

function tileManager:removeTile(x, y)
	for i = #self.tiles, 1, -1 do
		local v = self.tiles[i]
		if v.x == x and v.y == y then
			table.remove(self.tiles, i)
		end
	end
end

function tileManager:fillTiles(x, y, w, h, id)
	for tx=1, math.floor(w/16) do
		for ty = 1, math.floor(h/16) do
			self:addTile(x + tx * 16 - 16, y + ty * 16 - 16, id)
		end
	end
end

