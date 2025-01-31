local Highlight = require(...)

local function newHighlight(parentFrame)
  local myHighlight = {}

  local lines = {} -- Table to store lines of code as strings
  local guiObjects = {} -- Table to store TextLabel objects for each character

  local function updateGUI()
    -- Clear existing GUI objects
    for _, obj in ipairs(guiObjects) do
      obj:Destroy()
    end
    guiObjects = {}

    local yOffset = 0
    for lineNumber, line in ipairs(lines) do
      local xOffset = 0
      for i = 1, #line do
        local char = line:sub(i, i)
        local charData = {
          Char = char,
          Color = Color3.new(1, 1, 1) -- Default color (white)
        }

        -- You'll likely add your syntax highlighting logic here to determine the correct color
        -- Example:
        -- if char == " " then
        --   charData.Color = Color3.new(0.8, 0.8, 0.8) -- Slightly darker for spaces
        -- elseif char == "-" then
        --   charData.Color = Color3.new(1, 0, 0) -- Example: red for hyphens
        -- end

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(0, 8, 0, 16) -- Adjust size as needed
        textLabel.Position = UDim2.new(0, xOffset, 0, yOffset)
        textLabel.Text = charData.Char
        textLabel.TextColor3 = charData.Color
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.Code -- Or your preferred monospaced font
        textLabel.TextSize = 14 -- Adjust size as needed
        textLabel.Parent = parentFrame
        
        table.insert(guiObjects, textLabel)

        xOffset = xOffset + textLabel.TextBounds.X + 2 -- Add spacing between characters
      end
      yOffset = yOffset + 18 -- Adjust line spacing as needed
    end
    parentFrame.Size = UDim2.new(1, 0, 0, yOffset) -- Adjust frame size
  end

  function myHighlight:setRaw(str)
    lines = {}
    for line in str:gmatch("[^\n]+") do
      table.insert(lines, line)
    end
    updateGUI()
  end

  function myHighlight:getRaw()
    return table.concat(lines, "\n")
  end

  function myHighlight:getTable()
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

  function myHighlight:getSize()
    return #lines
  end

  function myHighlight:getLine(lineNumber)
    if lineNumber >= 1 and lineNumber <= #lines then
      return lines[lineNumber]
    else
      return "" -- Or handle out-of-bounds error as you prefer
    end
  end

  function myHighlight:setLine(lineNumber, str)
    if lineNumber >= 1 and lineNumber <= #lines then
      lines[lineNumber] = str
      -- Handle \n within the string
      local newLines = {}
      for newLine in str:gmatch("[^\n]+") do
        table.insert(newLines, newLine)
      end
      if #newLines > 1 then
        table.remove(lines, lineNumber)
        for i = #newLines, 1, -1 do
          table.insert(lines, lineNumber, newLines[i])
        end
      end
      updateGUI()
    end
  end

  function myHighlight:insertLine(lineNumber, str)
    if lineNumber >= 1 and lineNumber <= #lines + 1 then
      -- Handle \n within the string
      local newLines = {}
      for newLine in str:gmatch("[^\n]+") do
        table.insert(newLines, newLine)
      end
      for i = #newLines, 1, -1 do
        table.insert(lines, lineNumber, newLines[i])
      end
      updateGUI()
    end
  end

  return myHighlight
end

-- Example Usage (replace with your actual implementation):
local myFrame = Instance.new("ScrollingFrame") -- Use a ScrollingFrame for longer code
myFrame.Size = UDim2.new(0.5, 0, 0.5, 0) -- Example size
myFrame.Position = UDim2.new(0.25, 0, 0.25, 0)
myFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Initially zero, will be set by updateGUI
myFrame.Parent = game.Players.LocalPlayer.PlayerGui -- Or your desired parent

local myHighlight = newHighlight(myFrame)

myHighlight:setRaw("local x = 10\nprint('Hello, world!')\n-- Comment")

-- myHighlight:insertLine(2, "print('Inserted line')")
-- myHighlight:setLine(1, "local y = 20")
