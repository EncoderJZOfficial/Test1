--[[ Tool Log — CLEANED v2 ]]

local Menu = gg.prompt({
  "📄 Select script"
}, {
  string.gsub(gg.getFile(), "/[^/] $", "")
}, {
  "file"
})
if not Menu then return end

local Path = string.gsub(Menu[1], "[^%.] $", "") .. "#Log.lua"
local DataLog = io.output(Path)
DataLog:write("--[[ Log ]]\n")

local function Conv(...)
  local t = {}
  for _, v in ipairs({...}) do
    if type(v) == "string" then
      v = string.gsub(v, "\"", "\\\"")
      v = string.gsub(v, "\n", "\\n")
      t[#t 1] = "\"" .. v .. "\""
    elseif type(v) == "table" then
      t[#t 1] = "table"  -- не разворачиваем таблицы
    else
      t[#t 1] = tostring(v)
    end
  end
  return table.concat(t, ", ")
end

-- Только gg.* логируем
local Alert = gg.alert
gg.alert = function (...)
  DataLog:write("\ngg.alert(" .. Conv(...) .. ")")
  return Alert(...)
end

local Toast = gg.toast
gg.toast = function (...)
  DataLog:write("\ngg.toast(" .. Conv(...) .. ")")
  return Toast(...)
end

local SearchNumber = gg.searchNumber
gg.searchNumber = function (...)
  DataLog:write("\ngg.searchNumber(" .. Conv(...) .. ")")
  return SearchNumber(...)
end

local RefineNumber = gg.refineNumber
gg.refineNumber = function (...)
  DataLog:write("\ngg.refineNumber(" .. Conv(...) .. ")")
  return RefineNumber(...)
end

local GetResults = gg.getResults
gg.getResults = function (...)
  DataLog:write("\ngg.getResults(" .. Conv(...) .. ")")
  return GetResults(...)
end

local EditAll = gg.editAll
gg.editAll = function (...)
  DataLog:write("\ngg.editAll(" .. Conv(...) .. ")")
  return EditAll(...)
end

local ClearResults = gg.clearResults
gg.clearResults = function (...)
  DataLog:write("\ngg.clearResults(" .. Conv(...) .. ")")
  return ClearResults(...)
end

local SetValues = gg.setValues
gg.setValues = function (...)
  DataLog:write("\ngg.setValues(" .. Conv(...) .. ")")
  return SetValues(...)
end

local Prompt = gg.prompt
gg.prompt = function (...)
  DataLog:write("\ngg.prompt(" .. Conv(...) .. ")")
  return Prompt(...)
end

local Choice = gg.choice
gg.choice = function (...)
  DataLog:write("\ngg.choice(" .. Conv(...) .. ")")
  return Choice(...)
end

local MultiChoice = gg.multiChoice
gg.multiChoice = function (...)
  DataLog:write("\ngg.multiChoice(" .. Conv(...) .. ")")
  return MultiChoice(...)
end

local SetRanges = gg.setRanges
gg.setRanges = function (...)
  DataLog:write("\ngg.setRanges(" .. Conv(...) .. ")")
  return SetRanges(...)
end


local f = io.open(Menu[1], "r")
if f then
    local code = f:read("*a")
    f:close()
    local chunk = load(code, "@" .. Menu[1])
    if chunk then
        chunk()
    else
        gg.alert("Load failed")
    end
end