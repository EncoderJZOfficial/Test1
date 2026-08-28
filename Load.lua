local o = gg.searchNumber; gg.searchNumber = function(q, t) if q == "999" then gg.alert(q) return end return o(q, t) end 
local o = gg.getResults; gg.getResults = function(q, t) if q == "1000" then gg.toast(q) return end return o(q, t) end
local o = gg.editAll; gg.editAll = function(q, t) if q == "119" then gg.searchNumber("118",q,16,16) return end return o(q, t) end




gg.searchNumber("999", gg.TYPE_DWORD)
gg.getResults(1000)
gg.editAll("119", gg.TYPE_DWORD)

