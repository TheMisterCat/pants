-- === GitHub AUStream Playlist Player (Arrow Key UI + Safe Interrupt) ===
-- Works on all CC:Tweaked versions, cleanly stops playback on skip.

-- CONFIG ----------------------------
local user   = "TheMisterCat"
local repo   = "pants"
local branch = "main"
local path   = ""                -- folder inside repo ("" for root)
local tokenFile = "track_state.txt"
-------------------------------------

local json = textutils.unserializeJSON
local apiURL = string.format(
  "https://api.github.com/repos/%s/%s/contents/%s?ref=%s",
  user, repo, path, branch
)

print("Fetching playlist from GitHub...")
local res = http.get(apiURL, {["User-Agent"] = "ComputerCraft-Player"})
if not res then error("Failed to connect to GitHub API") end
local data = res.readAll()
res.close()

local files = json(data)
if type(files) ~= "table" then error("Invalid API response") end

local playlist = {}
for _, file in ipairs(files) do
  if file.name:match("%.dfpwm$") then
    table.insert(playlist, file.download_url)
  end
end

if #playlist == 0 then error("No .dfpwm files found!") end
table.sort(playlist)

-- Restore saved track
local currentTrack = 1
if fs.exists(tokenFile) then
  local f = fs.open(tokenFile, "r")
  local saved = tonumber(f.readAll())
  f.close()
  if saved and saved >= 1 and saved <= #playlist then
    currentTrack = saved
  end
end

local selection = currentTrack
local quit = false
local playing = false
local stopFlag = false

---------------------------------------
-- DRAW UI
---------------------------------------
local function drawUI()
  term.clear()
  term.setCursorPos(1, 1)
  print("🎧 GitHub AUStream Player")
  print("Use ↑↓ to navigate, [Enter] to play, [Q] to quit.")
  print("------------------------------------------")

  local _, height = term.getSize()
  local listStart = math.max(1, selection - math.floor((height - 5) / 2))
  local listEnd = math.min(#playlist, listStart + height - 6)

  for i = listStart, listEnd do
    local trackName = fs.getName(playlist[i])
    if i == currentTrack then
      term.setTextColor(colors.lime)
      write("> ")
    else
      write("  ")
    end
    if i == selection then
      term.setBackgroundColor(colors.gray)
      term.setTextColor(colors.white)
      print(trackName)
      term.setBackgroundColor(colors.black)
    else
      term.setTextColor(colors.white)
      print(trackName)
    end
  end
  term.setTextColor(colors.white)
end

---------------------------------------
-- PLAYBACK CONTROL
---------------------------------------
local function saveProgress()
  local f = fs.open(tokenFile, "w")
  f.write(tostring(currentTrack))
  f.close()
end

local function stopPlayback()
  stopFlag = true
end

local function playTrack(url)
  stopFlag = false
  playing = true
  parallel.waitForAny(
    function() shell.run("austream", url) end,
    function()
      while not stopFlag do sleep(0.1) end
    end
  )
  playing = false
end

---------------------------------------
-- PLAYER THREAD (auto advance)
---------------------------------------
local function playerLoop()
  while not quit do
    local url = playlist[currentTrack]
    drawUI()
    term.setCursorPos(1, select(2, term.getCursorPos()) + 1)
    print("▶ Now playing: " .. fs.getName(url))

    saveProgress()
    playTrack(url)

    if quit then break end
    if not stopFlag then
      currentTrack = currentTrack + 1
      if currentTrack > #playlist then currentTrack = 1 end
      selection = currentTrack
    end
  end
end

---------------------------------------
-- FRONTEND (key input)
---------------------------------------
local function frontend()
  drawUI()
  while not quit do
    local event, key = os.pullEvent("key")

    if key == keys.up then
      selection = selection - 1
      if selection < 1 then selection = #playlist end
      drawUI()

    elseif key == keys.down then
      selection = selection + 1
      if selection > #playlist then selection = 1 end
      drawUI()

    elseif key == keys.enter then
      stopPlayback()
      currentTrack = selection
      sleep(0.2) -- allow old playback to stop
      drawUI()

    elseif key == keys.q then
      quit = true
      stopPlayback()
      break
    end
  end
end

---------------------------------------
-- MAIN
---------------------------------------
parallel.waitForAny(playerLoop, frontend)
term.clear()
term.setCursorPos(1, 1)
print("Goodbye!")
