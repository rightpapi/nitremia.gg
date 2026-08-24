-- ============================================================
--  Nitremia.gg | Auto Loader
--  Creator: rightpapi
-- ============================================================

local BASE_URL = "https://raw.githubusercontent.com/rightpapi/nitremia.gg/master/Source/Games/"

-- PlaceId → filename inside Source/Games/
local PLACES = {
    [4282985734] = "Combat Warriors.lua",
}

-- UniverseId / GameId → filename inside Source/Games/
local GAMES = {
    [1390601379] = "Combat Warriors.lua",
}

local placeId = game.PlaceId
local gameId = game.GameId

local fileName = PLACES[placeId] or GAMES[gameId]

if not fileName then
    warn(string.format(
        "[Nitremia] No script for PlaceId: %s | GameId: %s",
        tostring(placeId),
        tostring(gameId)
    ))
    return
end

local ok, err = pcall(function()
    loadstring(game:HttpGet(BASE_URL .. fileName))()
end)

if not ok then
    warn(string.format(
        "[Nitremia] Failed to load %s:\n%s",
        fileName,
        tostring(err)
    ))
end
