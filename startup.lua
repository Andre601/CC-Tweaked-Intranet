if os.getComputerLabel() == nil then
	print("Please enter hostname:")
	local hostname = read()
	os.setComputerLabel(hostname)
end

hostname = os.getComputerLabel()

rednet.open("left")
rednet.host("intranet", hostname)

local PAGE_DIR = "pages"

local pages = {}
local colors = {}
local index = {}

-- Load pages and color tables
local function loadPages()
    if not fs.exists(PAGE_DIR) then
        fs.makeDir(PAGE_DIR)
    end

    local files = fs.list(PAGE_DIR)
    
    for _, file in ipairs(files) do
        local name = file:gsub("%.%w+$", "")
        local path = fs.combine(PAGE_DIR, file)
        
           local handle = fs.open(path, "r")
           local content = handle.readAll()
           handle.close()
           
           pages[name] = content
           table.insert(index, name)
           
           print("Loaded page:", name)
           
           ::continue::
       end
   
           
end
local function gui()
    paintutils.drawLine(1,1, 51,1, colours.blue)
    term.setCursorPos(2,1)
    print(("%s Intranet Server"):format(hostname))
    paintutils.drawLine(1,2, 51,2, colours.grey)
    term.setBackgroundColor(colours.grey)
    term.setCursorPos(2,2)
    print("x Reload | x Flush | x Update | Terminate")
    
    term.setBackgroundColor(colours.black)
    log_window = window.create(term.current(), 1,3, 51, 17)
    term.redirect(log_window)

end
gui()
loadPages()


print("Intranet server active. Pages loaded:", #index)
print(hostname)


-- processes page requests and send payloads
local function page_request(id ,request)

    --type of request
    if request == "index" then
        --assembles index payload
        local payload_type = "index"
        local payload = {
        payload_type,
        index}
        
        --sends index payload, logs it
        os.sleep(0.5)
        rednet.send(id, payload, "intranet")
        print(("Sent index to %d"):format(id))

    elseif pages[request] then
        --assembles page payload
        local payload_type = "page"
        local payload = {
        payload_type,
        pages[request], 
        colors[request]}
        
    
        -- send payload, page + colors, logs it
        rednet.send(id, payload, "intranet")
        print(("Sent page '%s' text to %d"):format(request, id))

    else
        rednet.send(id, {"404 - Page not found"}, "intranet")
        rednet.send(id, {}, "intranet") -- empty color table
        print(("Unknown page request '%s' from %d"):format(tostring(request), id))
    end
end

local function shutdown()
    error(0)
end

local function receive_message()
while true do
    --receives message over intranet protocol
    -- message format:
    -- {message type, content}
    
    -- message types: page_request, click
    local id, message = rednet.receive("intranet")
    
    -- sort messages by type
    if message[1] == "page_request" then
        local request = message[2]
        -- starts function page_request with pars
        page_request(id, request)
        
    elseif message[1] == "button_press" then
        print(id, message[2])
    end
end
end



local function keystrokes()
while true do
    local event1, key1 = os.pullEvent("key")
    
    if key1 == keys.t then
        print("Are you sure to terminate? Y/N")
        local event, key = os.pullEvent("key")
        
        if key == keys.y or key == keys.z then
            error(0)
        end
    --elseif key1 == keys.r then
        --pages, colors, index = nil, nil, nil
        --loadPages()
    end
end
end

parallel.waitForAll(receive_message, keystrokes)

    
    
    
    
    


