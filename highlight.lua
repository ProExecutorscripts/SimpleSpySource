--[[
    higlight.lua v0.0.2 by exxtremewa#9394 & chatgpt

    Features:
     - uses the power of fancy syntax detection algorithms to convert a frame into a syntax highlighted high quality code box
     - is cool
]]

local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

--- The Highlight class
--- @class Highlight
local Highlight = {}

-- PRIVATE METHODS/PROPERTIES --

local parentFrame
local scrollingFrame
local textFrame
local lineNumbersFrame
local lines = {}

--- Contents of the table- array of char objects
local tableContents = {}

local line = 0
local largestX = 0

local lineSpace = 18
local font = Enum.Font.Code
local textSize = 14

local backgroundColor = Color3.fromRGB(40, 44, 52)
local operatorColor = Color3.fromRGB(187, 85, 255)
local functionColor = Color3.fromRGB(97, 175, 239)
local stringColor = Color3.fromRGB(152, 195, 121)
local numberColor = Color3.fromRGB(209, 154, 102)
local booleanColor = numberColor
local objectColor = Color3.fromRGB(229, 192, 123)
local defaultColor = Color3.fromRGB(224, 108, 117)
local commentColor = Color3.fromRGB(148, 148, 148)
local lineNumberColor = commentColor
local genericColor = Color3.fromRGB(240, 240, 240)

local operators = {"^(function)[^%w_]", "^(local)[^%w_]", "^(if)[^%w_]", "^(for)[^%w_]", "^(while)[^%w_]", "^(then)[^%w_]", "^(do)[^%w_]", "^(else)[^%w_]", "^(elseif)[^%w_]", "^(return)[^%w_]", "^(end)[^%w_]", "^(continue)[^%w_]", "^(and)[^%w_]", "^(not)[^%w_]", "^(or)[^%w_]", "[^%w_](or)[^%w_]", "[^%w_](and)[^%w_]", "[^%w_](not)[^%w_]", "[^%w_](continue)[^%w_]", "[^%w_](function)[^%w_]", "[^%w_](local)[^%w_]", "[^%w_](if)[^%w_]", "[^%w_](for)[^%w_]", "[^%w_](while)[^%w_]", "[^%w_](then)[^%w_]", "[^%w_](do)[^%w_]", "[^%w_](else)[^%w_]", "[^%w_](elseif)[^%w_]", "[^%w_](return)[^%w_]", "[^%w_](end)[^%w_]"}
--- In this case, patterns could not be used, so just the string characters are provided
local strings = {{"\"", "\""}, {"'", "'"}, {"%[%[", "%]%]", true}}
local comments = {"%-%-%[%[[^%]%]]+%]?%]?", "(%-%-[^\n]+)"}
local functions = {"[^%w_]([%a_][%a%d_]*)%s*%(", "^([%a_][%a%d_]*)%s*%(", "[:%.%(%[%p]([%a_][%a%d_]*)%s*%("}
local numbers = {"[^%w_](%d+[eE]?%d*)", "[^%w_](%.%d+[eE]?%d*)", "[^%w_](%d+%.%d+[eE]?%d*)", "^(%d+[eE]?%d*)", "^(%.%d+[eE]?%d*)", "^(%d+%.%d+[eE]?%d*)"}
local booleans = {"[^%w_](true)", "^(true)", "[^%w_](false)", "^(false)", "[^%w_](nil)", "^(nil)"}
local objects = {"[^%w_:]([%a_][%a%d_]*):", "^([%a_][%a%d_]*):"}
local other = {"[^_%s%w=>~<%-%+%*]", ">", "~", "<", "%-", "%+", "=", "%*"}
local offLimits = {}

--- Determines if index is in a string
local function isOffLimits(index)
    for _, v in pairs(offLimits) do
        if index >= v[1] and index <= v[2] then
            return true
        end
    end
    return false
end

--- Find iterator
local function gfind(str, pattern)
    return coroutine.wrap(function()
        local start = 0
        while true do
            local findStart, findEnd = str:find(pattern, start)
            if findStart then
                start = findEnd + 1
                coroutine.yield(findStart, findEnd)
            else
                return
            end
        end
    end)
end

--- Finds and highlights comments with `commentColor`
local function renderComments(str)
    local step = 1
    for _, pattern in pairs(comments) do
        for commentStart, commentEnd in gfind(str, pattern) do
            if step % 1000 == 0 then
                RunService.Heartbeat:Wait()
            end
            step += 1
            if not isOffLimits(commentStart) then
                table.insert(offLimits, {commentStart, commentEnd})
                for i = commentStart, commentEnd do
                    if tableContents[i] then
                        tableContents[i].Color = commentColor
                    end
                end
            end
        end
    end
end

-- Finds and highlights strings with `stringColor`
local function renderStrings(str)
    local stringType
    local stringEndType
    local ignoreBackslashes
    local stringStart
    local stringEnd
    local offLimitsIndex
    local skip = false

    for i, charData in pairs(tableContents) do
        local char = charData.Char

        if stringType then
            charData.Color = stringColor
            local possibleString = ""
            for k = stringStart, i do
                possibleString = possibleString .. tableContents[k].Char
            end
            if char:match(stringEndType) and not (ignoreBackslashes and possibleString:match("(\\*)" .. stringEndType .. "$") and #possibleString:match("(\\*)" .. stringEndType .. "$") % 2 ~= 0) then
                skip = true
                stringType = nil
                stringEndType = nil
                ignoreBackslashes = nil
                stringEnd = i
                offLimits[offLimitsIndex][2] = stringEnd
            end
        end

        if not skip then
            for _, v in pairs(strings) do
                if char:match(v[1]) and not isOffLimits(i) then
                    stringType = v[1]
                    stringEndType = v[2]
                    ignoreBackslashes = v[3]
                    charData.Color = stringColor
                    stringStart = i
                    offLimitsIndex = #offLimits + 1
                    table.insert(offLimits, {stringStart, math.huge})
                end
            end
        end
        skip = false
    end
end

--- Highlights the specified patterns with the specified color
--- @param patternArray string[]
---@param color userdata
local function highlightPattern(patternArray, color, str)
    local step = 1
    for _, pattern in pairs(patternArray) do
        for findStart, findEnd in gfind(str, pattern) do
            if step % 1000 == 0 then
                RunService.Heartbeat:Wait()
            end
            step += 1
            if not isOffLimits(findStart) and not isOffLimits(findEnd) then
                for i = findStart, findEnd do
                    if tableContents[i] then
                        tableContents[i].Color = color
                    end
                end
            end
        end
    end
end

--- Automatically replaces reserved chars with escape chars
--- @param s string
local function autoEscape(s)
    s = string.gsub(s, "&", "&")
    s = string.gsub(s, "<", "<")
    s = string.gsub(s, ">", ">")
    s = string.gsub(s, '"', """)
    s = string.gsub(s, "'", "'")
    return s
end

--- Main function for syntax highlighting tableContents
local function render()
    local str = Highlight:getRaw() -- Get the raw string once
    
    offLimits = {}
    tableContents = {}
    
    for i = 1, #str do
        table.insert(tableContents, {
            Char = str:sub(i, i),
            Color = defaultColor,
        })
    end

    highlightPattern(functions, functionColor, str)
    highlightPattern(numbers, numberColor, str)
    highlightPattern(operators, operatorColor, str)
    highlightPattern(objects, objectColor, str)
    highlightPattern(booleans, booleanColor, str)
    highlightPattern(other, genericColor, str)
    renderComments(str)
    renderStrings(str)

    
    textFrame:ClearAllChildren()
    lineNumbersFrame:ClearAllChildren()

    local lastColor
    local lineStr = ""
    local rawStr = "" -- This will hold the unescaped string for calculating text size
    largestX = 0
    line = 1

    for i = 1, #tableContents + 1 do
        local char = tableContents[i]
        if i == #tableContents + 1 or (char and char.Char == "\n") then
            lineStr = lineStr .. (lastColor and "</font>" or "")

            local lineText = Instance.new("TextLabel")
            local x = TextService:GetTextSize(rawStr, textSize, font, Vector2.new(math.huge, math.huge)).X + 60
            
            if x > largestX then
                largestX = x
            end

            lineText.TextXAlignment = Enum.TextXAlignment.Left
            lineText.TextYAlignment = Enum.TextYAlignment.Top
            lineText.Position = UDim2.new(0, 0, 0, (line -1) * lineSpace)
            lineText.Size = UDim2.new(0, x, 0, textSize)
            lineText.RichText = true
            lineText.Font = font
            lineText.TextSize = textSize
            lineText.BackgroundTransparency = 1
            lineText.Text = lineStr
            lineText.Parent = textFrame

            if i ~= #tableContents + 1 then
                local lineNumber = Instance.new("TextLabel")
                lineNumber.Text = line
                lineNumber.Font = font
                lineNumber.TextSize = textSize
                lineNumber.Size = UDim2.new(1, 0, 0, lineSpace)
                lineNumber.TextXAlignment = Enum.TextXAlignment.Right
                lineNumber.TextColor3 = lineNumberColor
                lineNumber.Position = UDim2.new(0, 0, 0, (line - 1) * lineSpace)
                lineNumber.BackgroundTransparency = 1
                lineNumber.Parent = lineNumbersFrame
            end

            lineStr = ""
            rawStr = ""
            lastColor = nil
            line += 1
            updateZIndex()
            updateCanvasSize()
            if line % 5 == 0 then
                RunService.Heartbeat:Wait()
            end
        elseif char.Char == " " then
            lineStr = lineStr .. " " -- Use non-breaking space for consistent spacing
            rawStr = rawStr .. " "
        elseif char.Char == "\t" then
            lineStr = lineStr .. string.rep(" ", 4) -- 4 spaces for a tab
            rawStr = rawStr .. "\t"
        else
            if char.Color == lastColor then
                lineStr = lineStr .. autoEscape(char.Char)
            else
                lineStr = lineStr .. string.format('%s<font color="rgb(%d,%d,%d)">%s', 
                                                   lastColor and "</font>" or "", 
                                                   char.Color.R * 255, 
                                                   char.Color.G * 255, 
                                                   char.Color.B * 255,
                                                   autoEscape(char.Char))
                lastColor = char.Color
            end
            rawStr = rawStr .. char.Char
        end
    end
    
    updateZIndex()
    updateCanvasSize()
end

local function onFrameSizeChange()
    local newSize = parentFrame.AbsoluteSize
    scrollingFrame.Size = UDim2.new(0, newSize.X, 0, newSize.Y)
    updateCanvasSize()
end

local function updateCanvasSize()
    scrollingFrame.CanvasSize = UDim2.new(0, largestX, 0, line * lineSpace)
end

local function updateZIndex()
    for _, v in pairs(parentFrame:GetDescendants()) do
        if v:IsA("GuiObject") then
            v.ZIndex = parentFrame.ZIndex + 1
        end
    end
    scrollingFrame.ZIndex = parentFrame.ZIndex
    textFrame.ZIndex = parentFrame.ZIndex + 1
    lineNumbersFrame.ZIndex = parentFrame.ZIndex + 1
end

-- PUBLIC METHODS --

--- Runs when a new object is instantiated
--- @param frame userdata
function Highlight:init(frame)
    if typeof(frame) == "Instance" and frame:IsA("Frame") then
        frame:ClearAllChildren()

        parentFrame = frame
        scrollingFrame = Instance.new("ScrollingFrame")
        textFrame = Instance.new("Frame")
        lineNumbersFrame = Instance.new("Frame")

        local parentSize = frame.AbsoluteSize
        scrollingFrame.Name = "HIGHLIGHT_IDE"
        scrollingFrame.Size = UDim2.new(0, parentSize.X, 0, parentSize.Y)
        scrollingFrame.BackgroundColor3 = backgroundColor
        scrollingFrame.BorderSizePixel = 0
        scrollingFrame.ScrollBarThickness = 4
        scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Both

        textFrame.Name = "TextFrame"
        textFrame.Size = UDim2.new(1, -40, 1, 0)
        textFrame.Position = UDim2.new(0, 40, 0, 0)
        textFrame.BackgroundTransparency = 1

        lineNumbersFrame.Name = "LineNumbersFrame"
        lineNumbersFrame.Size = UDim2.new(0, 25, 1, 0)
        lineNumbersFrame.BackgroundTransparency = 1

        textFrame.Parent = scrollingFrame
        lineNumbersFrame.Parent = scrollingFrame
        scrollingFrame.Parent = parentFrame

        parentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(onFrameSizeChange)
        parentFrame:GetPropertyChangedSignal("ZIndex"):Connect(updateZIndex)
    else
        error("Initialization error: argument " .. typeof(frame) .. " is not a Frame Instance")
    end
end

--- Sets the raw text of the code box (\n = new line, \t converted to spaces)
--- @param raw string
function Highlight:setRaw(raw)
    
    render()
    lines = {}
    for line in raw:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
end

--- Returns the (string) raw text of the code box (\n = new line). This includes placeholder characters so it should only be used internally.
--- @return string
function Highlight:getRaw()
    local result = ""
    for i, line in ipairs(lines) do
        result = result .. line
        if i < #lines then
            result = result .. "\n"
        end
    end
    return result
end

--- Returns the (string) text of the code box (\n = new line)
--- @return string
function Highlight:getString()
    local result = ""
    for i, line in ipairs(lines) do
        result = result .. line
        if i < #lines then
            result = result .. "\n"
        end
    end
    return result
end

--- Returns the (char[]) array that holds all the lines in order as strings
--- @return table[]
function Highlight:getTable()
    local charTable = {}
    for _, line in ipairs(lines) do
        local lineTable = {}
        for i = 1, #line do
            local char = line:sub(i, i)
            table.insert(lineTable, {
              Char = char,
              Color = Color3.new(1, 1, 1) -- Default color, update with syntax highlighting
            })
        end
        table.insert(charTable, lineTable)
    end
    return charTable
end

--- Returns the (int) number of lines in the code box
--- @return number
function Highlight:getSize()
    return #lines
end

--- Returns the (string) line of the specified line number
--- @param line_number number
--- @return string
function Highlight:getLine(line_number)
    if line_number >= 1 and line_number <= #lines then
        return lines[line_number]
    else
        return ""
    end
end

--- Replaces the specified line number with the specified string (\n will overwrite further lines)
--- @param line_number number
---@param text string
function Highlight:setLine(line_number, text)
    if line_number >= 1 and line_number <= #lines then
        lines[line_number] = text
        local newLines = {}
        for newLine in text:gmatch("[^\n]+") do
            table.insert(newLines, newLine)
        end
        if #newLines > 1 then
            table.remove(lines, line_number)
            for i = #newLines, 1, -1 do
              table.insert(lines, line_number, newLines[i])
            end
        end
        
        render()
    end
end

--- Inserts a line made from the specified string and moves all existing lines down (\n will insert further lines)
--- @param line_number number
---@param text string
function Highlight:insertLine(line_number, text)
    if line_number >= 1 and line_number <= #lines + 1 then
        local newLines = {}
        for newLine in text:gmatch("[^\n]+") do
            table.insert(newLines, newLine)
        end
        for i = #newLines, 1, -1 do
            table.insert(lines, line_number, newLines[i])
        end
        
        render()
    end
end

-- CONSTRUCTOR --

local constructor = {}
--- responsible for instantiation
function constructor.new(...)
    local class = Highlight
    local new = {}
    class.__index = class
    setmetatable(new, class)
    new:init(...)
    return new
end

return constructor
