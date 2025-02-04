---------------------------------------------------------------------------
--- Utilities related to the keyboard and keybindings.
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2018-2019 Emmanuel Lepage Vallee
-- @inputmodule awful.keyboard
---------------------------------------------------------------------------

local capi   = {root = root, awesome = awesome}
local module = {}

--- Convert the modifiers into pc105 key names
local conversion = nil

local function generate_conversion_map()
    if conversion then return conversion end

    local mods = capi.awesome._modifiers
    assert(mods)

    conversion = {}

    for mod, keysyms in pairs(mods) do
        for _, keysym in ipairs(keysyms) do
            assert(keysym.keysym)
            conversion[mod] = conversion[mod] or keysym.keysym
            conversion[keysym.keysym] = mod
        end
    end

    return conversion
end

capi.awesome.connect_signal("xkb::map_changed", function() conversion = nil end)

--- Execute a key combination.
--
-- If an awesome keybinding is assigned to the combination, it should be
-- executed.
--
-- To limit the chances of accidentally leaving a modifier key locked when
-- calling this function from a keybinding, make sure is attached to the
-- release event and not the press event.
--
-- @see root.fake_input
-- @tparam table modifiers A modified table. Valid modifiers are: `Any`, `Mod1`,
--   `Mod2`, `Mod3`, `Mod4`, `Mod5`, `Shift`, `Lock` and `Control`.
-- @tparam string key The key.
-- @staticfct awful.keyboard.emulate_key_combination
function module.emulate_key_combination(modifiers, key)
    local modmap = generate_conversion_map()
    local active = capi.awesome._active_modifiers

    -- Release all modifiers
    for _, m in ipairs(active) do
        assert(modmap[m])
        capi.root.fake_input("key_release", modmap[m])
    end

    for _, v in ipairs(modifiers) do
        local m = modmap[v]
        if m then
            capi.root.fake_input("key_press", m)
        end
    end

    capi.root.fake_input("key_press"  , key)
    capi.root.fake_input("key_release", key)

    for _, v in ipairs(modifiers) do
        local m = modmap[v]
        if m then
            capi.root.fake_input("key_release", m)
        end
    end

    -- Restore the previous modifiers all modifiers. Please note that yes,
    -- there is a race condition if the user was fast enough to release the
    -- key during this operation.
    for _, m in ipairs(active) do
        capi.root.fake_input("key_press", modmap[m])
    end
end

--- Add an `awful.key` based keybinding to the global set.
--
-- A **global** keybinding is one which is always present, even when there is
-- no focused client. If your intent is too add a keybinding which acts on
-- the focused client do **not** use this.
--
-- @staticfct awful.keyboard.append_global_keybinding
-- @tparam awful.key key The key object.
-- @see awful.key
-- @see awful.keyboard.append_global_keybindings
-- @see awful.keyboard.remove_global_keybinding

function module.append_global_keybinding(key)
    capi.root._append_key(key)
end

--- Add multiple `awful.key` based keybindings to the global set.
--
-- A **global** keybinding is one which is always present, even when there is
-- no focused client. If your intent is too add a keybinding which acts on
-- the focused client do **not** use this
--
-- @tparam table keys A table of `awful.key` objects. Optionally, it can have
--  a `group` entry. If set, the `group` property will be set on all `awful.keys`
--  objects.
-- @see awful.key
-- @see awful.keyboard.append_global_keybinding
-- @see awful.keyboard.remove_global_keybinding

function module.append_global_keybindings(keys)
    local g = keys.group
    keys.group = nil

    -- Avoid the boilerplate. If the user is adding multiple keys at once, then
    -- they are probably related.
    if g then
        for _, k in ipairs(keys) do
            k.group = g
        end
    end

    capi.root._append_keys(keys)
    keys.group = g
end

--- Remove a keybinding from the global set.
--
-- @staticfct awful.keyboard.remove_global_keybinding
-- @tparam awful.key key The key object.
-- @see awful.key
-- @see awful.keyboard.append_global_keybinding

function module.remove_global_keybinding(key)
    capi.root._remove_key(key)
end

return module
