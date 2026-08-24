-- ============================================================
--  Nitremia.gg | Auto Loader
--  Creator: rightpapi
-- ============================================================

local BASE_URL = "https://raw.githubusercontent.com/rightpapi/nitremia.gg/master/Source/Games/"

-- GameId → filename inside Source/Games/
local GAMES = {
    [3272915504] = "Combat Warriors.lua",
}

local gameId = game.GameId
local fileName = GAMES[gameId]

if not fileName then
    warn(string.format("[Nitremia] No script for GameId: %d", gameId))
    return
end

local ok, err = pcall(function()
    loadstring(game:HttpGet(BASE_URL .. fileName))()
end)

if not ok then
    warn(string.format("[Nitremia] Failed to load %s:\n%s", fileName, tostring(err)))
end
