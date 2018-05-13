function Capsule(modules)
	local self = setmetatable({}, {})
	self.__ContainerContext = {
		__Modules = {},
	}
	
	self.getModuleCode = function(self, moduleName)
		local fileToModule = fileOpen(moduleName .. ".capsule")
		local moduleCode = "return function(context)\nlocal self = setmetatable(context, {})\n"
		local code = fileRead(fileToModule, fileGetSize(fileToModule))
		moduleCode = moduleCode .. code
		fileClose(fileToModule)
		moduleCode = moduleCode .. "\nreturn self\nend"
		
		return moduleCode
	end
	
	self.loadIntoContext = function(self, moduleName)		
		local moduleCode = self:getModuleCode(moduleName)
	
		self.__ContainerContext.__Modules[moduleName] = {
			__MODULENAME = moduleName,
			
			globalContext = self,
			
			getGlobalContext = function(self)
				return self.globalContext
			end,
			
			import = function(self, moduleName)
				if string.match(moduleName, "@std") then
					local moduleNameParts = split(moduleName, "/")
					local moduleCode = self:getGlobalContext():getModuleCode("stdlib/" .. moduleNameParts[2])
					return loadstring(moduleCode)(self)({})
				else
				local moduleCode = self:getGlobalContext():getModuleCode(moduleName)
				return loadstring(moduleCode)(self)(self)	
				end
			end,
		}
		
		local snippet = loadstring(moduleCode)()(self.__ContainerContext.__Modules[moduleName])
		local newSelf = setmetatable(self.__ContainerContext.__Modules[moduleName], snippet)
		snippet:init(newSelf)
				
		return newSelf
	end
	
	self.get = function(self, moduleName)
		return self.__ContainerContext.__Modules[moduleName]
	end
	
	for _, moduleData in pairs(modules) do
		self:loadIntoContext(moduleData.name, moduleData.code)
	end
	
	return self
end

local simpleModule = [[
return function(context)
	local self = setmetatable(context, {})
	self.value = 5
	
	self.init = function(self)
		outputDebugString(inspect(self.value))
	end

	return self
end
]]

local capsule = Capsule({
	{name = "test"},
}) 
--> Module 1 initialized.