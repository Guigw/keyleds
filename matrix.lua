-- Matrix!
lineDefs = {
    {
        "ESC", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10",
        "F11", "F12", "SYSRQ", "SCROLLLOCK", "PAUSE"
    }
}

columnDefs = {
    {"ESC", "GRAVE", "TAB", "CAPSLOCK", "LSHIFT", "LCTRL"},
    {"F1", "2", "Q", "A", "102ND", "LMETA"}, {"F2", "3", "W", "S", "Z", "LALT"},
    {"F3", "4", "E", "D", "C", "SPACE"}, {"F4", "5", "R", "F", "V", "SPACE"},
    {"F5", "6", "T", "G", "B", "SPACE"}, {"F6", "7", "Y", "H", "N", "SPACE"},
    {"F7", "8", "U", "J", "N", "SPACE"}, {"F8", "9", "I", "K", "M", "SPACE"},
    {"F9", "MINUS", "P", "L", "COMMA", "RALT"},
    {"F10", "EQUAL", "LBRACE", "SEMICOLON", "DOT", "FN"},
    {"F11", "BACKSPACE", "RBRACE", "APOSTROPHE", "SLASH", "COMPOSE"},
    {"F12", "BACKSPACE", "ENTER", "RSHIFT", "RCTRL"},
    {"SYSRQ", "INSERT", "DELETE", "LEFT"},
    {"SCROLLLOCK", "HOME", "END", "UP", "DOWN"},
    {"PAUSE", "PAGEUP", "PAGEDOWN", "RIGHT"}
}

-- Lookup all names into key entries, eliminating unavailable ones
function initLines()
    lines = {}
    for i, lineDef in ipairs(lineDefs) do
        local line = {}
        for j, def in ipairs(lineDef) do
            if def == 0 then
                line[#line + 1] = 0
            else
                local key = keyleds.db:findName(def)
                if key then line[#line + 1] = key end
            end
        end
        lines[#lines + 1] = line
    end
    return lines
end

-- Lookup all names into key entries, eliminating unavailable ones
function initColumns()
    columns = {}
    for i, columnDef in ipairs(columnDefs) do
        local column = {}
        for j, def in ipairs(columnDef) do
            if def == 0 then
                column[#column + 1] = 0
            else
                local key = keyleds.db:findName(def)
                if key then column[#column + 1] = key end
            end
        end
        columns[#columns + 1] = column
    end
    return columns
end

-- set the color to the background
function endOfLine(buffer, column, duration, background)
    for i = #column -1, 1, -1 do
        buffer[column[i]] = fade(duration, background)
    end
end

-- display the falling animation
function displayAnim(buffer, column, index, colors, duration)
    -- for each color in the falling effect
    for i, color in ipairs(colors) do
        -- for the last key in the column, we just do an animation from the first color to the last one
        if index == #column then
            buffer[column[index]] = fade(duration * 3, colors[1], colors[#colors])
            endOfLine(buffer, column, duration, colors[#colors])
            -- for the first key light
        elseif i == 1 then
            buffer[column[index]] = fade(duration, colors[1], colors[2])
            -- standard effect : fade from the current color to the next
        elseif (index >= i) then
            buffer[column[index - i + 1]] = fade(duration, color)
        end
    end
    wait(duration)
end

-- recursive calling of the animation for all the keys in a cdefined columns
function recursiveColumnsCalls(buffer, column, index, config)
    displayAnim(buffer, column, index, config.colors, config.delay)
    local next = index + 1
    if next <= #column then
        recursiveColumnsCalls(buffer, column, next, config)
    end
end

-- we search for the right column to call
function initDisplayLines(buffer, key, columns, config)
    for i in pairs(columns) do
        if columns[i][1].keyCode == key.keyCode then
            recursiveColumnsCalls(buffer, columns[i], 1, config)
            break
        end
    end
end

-- main thread function with random calling on the columns
function downfall(buffer, lines, columns, delay, config)
    wait(delay)
    local line = lines[1]
    while true do
        initDisplayLines(buffer, line[math.random(#line)], columns, config)
    end
end

-- thread function for the highlight effect
function hello(buffer, key, color, background)
    buffer[key] = fade(0.5, color)
    wait(2)
    buffer[key] = fade(0.5, background)
end

-- initial configuration

background = tocolor(keyleds.config.background) or tocolor(0, 0.15, 0, 1)
config = {
    delay = (tonumber(keyleds.config.delay) or 0.5), -- in s in config
    number = tonumber(keyleds.config.number) or 3, -- 
    highlight = tocolor(keyleds.config.highlight) or tocolor("white"),
    background = background,
    colors = {
        tocolor("green"), tocolor(0, 0.80, 0, 1), tocolor(0, 0.50, 0, 1),
        background
    }
}

buffer = RenderTarget:new()
lastClass = "";
-- Don't forget running init code
for i = 0, config.number, 1 do
    thread(downfall, buffer, initLines(), initColumns(), i, config)
end

function onKeyEvent(key, isPress)
    if isPress then
        thread(hello, buffer, key, config.highlight, config.background)
    end
end

function onGenericEvent(data)
    print("onGenericEvent ", data)
    if data.effect ~= "matrix" then return end
    newcolor = tocolor(data.color)
    if newcolor then color = newcolor end
end

function onContextChange(context)
    -- we restart the layout when we change class
    if context.class ~= lastClass then
        buffer:fill(config.background)
        lastClass = context.class
    end
end

function render(ms, target) target:blend(buffer) end
