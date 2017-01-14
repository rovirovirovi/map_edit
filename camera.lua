
camera = {}
camera.x = 0
camera.y = 0
camera.rotation = 0
camera.scaleX = 1
camera.scaleY = 1
camera.utils = require "utils"


function camera:set()
	love.graphics.push()
	love.graphics.rotate(-self.rotation)
	love.graphics.scale(1 / self.scaleX, 1 / self.scaleY)
	love.graphics.translate(-self.x, -self.y)
end

function camera:unset()
	love.graphics.pop()
end

function camera:setPosition(x, y)
	self.x = x or self.x
	self.y = y or self.y
end

function camera:setScale(x, y)
	self.scaleX = x or self.scaleX
	self.scaleY = y or self.scaleY
end

function camera:getMouseX()
	return love.mouse.getX() * self.scaleX + self.x
end

function camera:getMouseY()
	return love.mouse.getY() * self.scaleY + self.y
end

function camera:followObject(target)
	local tx, ty
	tx = target.x - love.graphics.getWidth() / 2 * self.scaleX + target.width / 2
	ty = target.y - love.graphics.getHeight() / 2 * self.scaleY + target.height / 2
	if love.timer.getDelta() ~= nil then
		--self.x = utils.lerp(self.x, tx, 100 * love.timer.getDelta())
		--self.y = utils.lerp(self.y, ty, 100 * love.timer.getDelta())
	end
	self:setPosition(tx, ty)
end