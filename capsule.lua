function Capsule(modules)
	local self = setmetatable({}, {})
	self.__ContainerContext = {
		__Modules = {},
	}

	self.getModuleCode = function(self, moduleName)
		local codeTable = {
			"return function(context)\nlocal this = setmetatable({}, {})",
			"import = function(moduleName) return context:import(moduleName) end"
		}
		local fileToModule = fileOpen(moduleName .. ".capsule")
		local moduleCode = table.concat(codeTable, "\n")
		local code = fileRead(fileToModule, fileGetSize(fileToModule))
		moduleCode = moduleCode .. "\n" .. code

		-- TODO move this to its own function
		for k, v in moduleCode:gmatch("import .-\n") do
			local parts = split(k, " ")

			if parts[2] ~= "=" then
				local importCode = "local " .. parts[4]:gsub("\n", "") .. " = import(" .. parts[2] .. ")"
				moduleCode = moduleCode:gsub(k, importCode)
			end
		end

		moduleCode = moduleCode:gsub("->", ":")
		fileClose(fileToModule)
		moduleCode = moduleCode .. "\nreturn this\nend"
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
					return loadstring(moduleCode)({})(self)
				else
					local moduleCode = self:getGlobalContext():getModuleCode(moduleName)
					return loadstring(moduleCode)({})(self)
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

local capsule = Capsule({
	{name = "test"},
})