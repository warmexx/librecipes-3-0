local MAJOR = "LibRecipes-3.0"
local MINOR = 27 -- Should be manually increased
assert(LibStub, MAJOR .. " requires LibStub")

local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end -- No upgrade needed

lib.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
lib.IsEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
lib.IsBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
lib.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC

local type = type
local tonumber = tonumber
local error = error
local getn = getn
local pairs = pairs

local recipes = lib.recipes or {}
local spells = lib.spells or {}
local items = lib.items or {}
lib.recipes, lib.spells, lib.items = recipes, spells, items

--------------------------------------------------------------------------------
-- Internals                                                                  --
--------------------------------------------------------------------------------

local function AsNumber(value)
    local valueType = type(value)
    if valueType == "number" then
        return value
    elseif valueType == "string" then
        return tonumber(value)
    end
end

local function Flatten(t, i)
    if t == nil then
        return nil
    elseif i == nil then
        i = 1
        local f = {}
        for k, v in pairs(t) do
            f[i] = k
            f[i+1] = v
            i = i + 2
        end
        return Flatten(f, 1)
    elseif i <= getn(t) then
        return t[i], t[i+1] or nil, Flatten(t, i+2)
    end
end

--------------------------------------------------------------------------------
-- Public API                                                                 --
--------------------------------------------------------------------------------

--- Count total number of recipes loaded
-- @usage -- LibStub("LibRecipes-3.0"):GetCount()
-- @return Number of recipes
function lib:GetCount()
    local count = 0
    for _ in pairs(recipes) do count = count + 1 end
    return count
end

--- Register a recipe
-- @param recipeId Id of the recipe
-- @param spellId Id of the spell learned
-- @param itemId Id of the item created by casting the spell
-- @usage -- item:2553  Recipe: Elixir of Minor Agility
-- <br/>-- spell:3230 Elixir of Minor Agility
-- <br/>-- item:2457  Elixir of Minor Agility
-- <br/>LibStub("LibRecipes-3.0"):AddRecipe(2553, 3230, 2457)
-- @return nil
function lib:AddRecipe(recipeId, spellId, itemId)
    recipeId = AsNumber(recipeId)
    if recipeId == nil then
        error("invalid recipe id")
    end
    spellId = AsNumber(spellId)
    if spellId == nil then
        error("invalid spell id")
    end
    -- a craft spell usually creates an item
    itemId = AsNumber(itemId) or false

    -- recipe can provide multiple spells (e.g. "Plans: Balanced Trillium Ingot and Its Uses")
    local recipe = recipes[recipeId]
    if recipe == nil then
        recipes[recipeId] = {}
        recipe = recipes[recipeId]
    end
    recipe[spellId] = itemId

    -- multiple recipes can provide the same spell (e.g. "Design: Rigid Star of Elune")
    local spell = spells[spellId]
    if spell == nil then
        spells[spellId] = {}
        spell = spells[spellId]
    end
    spell[recipeId] = itemId

    -- multiple recipes can lead to the same item (e.g. "Smoking Heart of the Mountain")
    if itemId then
        local item = items[itemId]
        if item == nil then
            items[itemId] = {}
            item = items[itemId]
        end
        item[recipeId] = spellId
    end
end

--- Retrieves the spell and item id related to the specified recipe; repeats in case of multiple spells (spell1, item1, spell2, item2, ...)
-- @param recipeId Id of the recipe
-- @usage local spellId, itemId = LibStub("LibRecipes-3.0"):GetRecipeInfo(2553)
-- <br/>-- spellId = 3230
-- <br/>-- itemId = 2457
-- @return Id of the spell that is learned
-- @return Id of the item that is created by the spell or nil if not applicable
function lib:GetRecipeInfo(recipeId)
    recipeId = AsNumber(recipeId)
    if recipeId == nil then
        error("invalid recipe id")
    end
    return Flatten(recipes[recipeId])
end

--- Retrieves the recipe and item id related to the specified spell; repeats in case of multiple recipes (recipe1, item1, recipe2, item2, ...)
-- @param spellId Id of the spell
-- @usage local recipeId, itemId = LibStub("LibRecipes-3.0"):GetSpellInfo(3230)
-- <br/>-- recipeId = 2553
-- <br/>-- itemId = 2457
-- @return Id of the recipe that learns the spell
-- @return Id of the item that is created by the spell or nil if not applicable
function lib:GetSpellInfo(spellId)
    spellId = AsNumber(spellId)
    if spellId == nil then
        error("invalid spell id")
    end
    return Flatten(spells[spellId])
end

--- Retrieves the recipe and spell id related to the specified item; repeats in case of multiple recipes (recipe1, spell1, recipe2, spell2, ...)
-- @param itemId Id of the item that is created by a recipe spell
-- @usage local recipeId, spellId = LibStub("LibRecipes-3.0"):GetItemInfo(2457)
-- <br/>-- recipeId = 2553
-- <br/>-- spellId = 3230
-- @return Id of the recipe that learns the spell that creates the item
-- @return Id of the spell that creates the item
function lib:GetItemInfo(itemId)
    itemId = AsNumber(itemId)
    if itemId == nil then
        error("invalid item id")
    end
    return Flatten(items[itemId])
end

--- Determines if a spell is taught by a recipe
-- @param spellId Id of the spell
-- @param recipeId Id of the recipe
-- @usage local taughtBy = LibStub("LibRecipes-3.0"):TaughtBy(3230, 2553)
-- <br/>-- taughtBy = true
-- @return true if the recipe teaches the spell; otherwise false
function lib:TaughtBy(spellId, recipeId)
    spellId = AsNumber(spellId)
    if spellId == nil then
        error("invalid spell id")
    end
    recipeId = AsNumber(recipeId)
    if recipeId == nil then
        error("invalid recipe id")
    end
   return spells[spellId] and spells[spellId][recipeId] ~= nil or false
end

--- Determines if a recipe teaches a spell
-- @param recipeId Id of the recipe
-- @param spellId Id of the spell
-- @usage local teaches = LibStub("LibRecipes-3.0"):Teaches(2553, 3230)
-- <br/>-- teaches = true
-- @return true if the spell is taught by the recipe; otherwise false
function lib:Teaches(recipeId, spellId)
    recipeId = AsNumber(recipeId)
    if recipeId == nil then
        error("invalid recipe id")
    end
    spellId = AsNumber(spellId)
    if spellId == nil then
        error("invalid spell id")
    end
    return recipes[recipeId] and recipes[recipeId][spellId] ~= nil or false
end
