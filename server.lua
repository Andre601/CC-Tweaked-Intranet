local SERVER_DATA_FILE = "server.dat"

local server_data = {}
--[[ contains:
address = 
{
user
pass
display name = ... ,
keywords = ... ,
description = ... (stored separately)
}
]]
--------------------------------------------------
if os.getComputerLabel() == nil then
	print("Please enter hostname:")
	local hostname = read()
	os.setComputerLabel(hostname)
end



hostname = os.getComputerLabel()

peripheral.find("modem", rednet.open)
rednet.host("intranet", hostname)
rednet.host("intranet_admin", hostname)
local PAGE_DIR = "pages"
local ADDON_DIR = "addons"

local addons = {}
local addon_inputs = {}

local pages = {}
local colors = {}
local index = {}

local function read_server_data()
    
    local hostname = os.getComputerLabel()
    
    if not fs.exists(SERVER_DATA_FILE) then
        local file = fs.open(SERVER_DATA_FILE, "w")
        file.write([[
user=admin
pass=admin
display_name=Display name
keywords=keyword1,keyword2
description:
Your server description here.
It can have multiple lines.
]])
        file.close()
    end
    
    local file = fs.open(SERVER_DATA_FILE, "r")
    local content = file.readAll()
    file.close()
    
    local data = 
    {
    address = hostname,
    user = "",
    pass = "",
    display_name = "",
    keywords = {},
    description = ""}
    
    local in_description = false
    local desc_lines = {}
    
    for line in content:gmatch("[^\r\n]+") do
        if in_description then
            table.insert(desc_lines, line)
            
        elseif line:sub(1, 13) == "display_name=" then
            data.display_name = line:sub(14)

    	elseif line:sub(1, 5) == "user=" then
        	data.user = line:sub(6)

    	elseif line:sub(1, 5) == "pass=" then
        	data.pass = line:sub(6)
        
        elseif line:sub(1, 9) == "keywords" then
            local keyword_string = line:sub(10)
            for keyword in keyword_string:gmatch("[^,]+") do
                keyword = keyword:match("^%s*(.-)%s*$")
                if keyword ~= "" then
                    table.insert(data.keywords, keyword)
                end
            end
        
        elseif line == "description:" then
            in_description = true
        end
   end
   
   data.description = table.concat(desc_lines, "\n")
   
   return data
     
end


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
    print("Reload | Console | Terminate")
    
    term.setBackgroundColor(colours.black)
    log_window = window.create(term.current(), 1,3, 51, 17)
    term.redirect(log_window)

end

local function loadAddons()
    
    
    addons = {}
    addon_inputs = {}

    if not fs.exists(ADDON_DIR) then
        fs.makeDir(ADDON_DIR)
    end

    for _, file in ipairs(fs.list(ADDON_DIR)) do
        if file:sub(-4) == ".lua" then
            local addon_name = file:sub(1, -5)
            local require_path = ADDON_DIR .. "." .. addon_name

            package.loaded[require_path] = nil

            local ok, addon = pcall(require, require_path)

            if ok and type(addon) == "table" then
                addons[addon_name] = addon
                print("Loaded addon:", addon_name)

                if type(addon.input) == "function" then
                    local input_ok, inputs = pcall(addon.input)

                    if input_ok and type(inputs) == "table" then
                        for input_id, _ in pairs(inputs) do
                            addon_inputs[input_id] = addon
                        end

                        print("Loaded inputs for addon:", addon_name)
                    else
                        printError("Addon input() failed: " .. addon_name)
                        if not input_ok then
                            printError(inputs)
                        end
                    end
                end
            else
                printError("Failed to load addon: " .. addon_name)
                printError(addon)
            end
        end
    end
end

gui()
loadPages()
loadAddons()
read_server_data()

local function reload()
    pages = {}
    addons = {}
    addon_inputs = {}
    index = {}
    
    read_server_data()
    
    term.clear()
    term.redirect(term.native())
    gui()
    
    loadPages()
    loadAddons()
end

local function update_sw()
    fs.delete("startup.lua")
    shell.run("wget https://raw.githubusercontent.com/ArtMinerCZ/CC-Tweaked-Intranet/refs/heads/main/startup.lua startup.lua")
    shell.run("startup.lua")
end

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




local function process_admin(id, message)

    if message[1] == "fetch_file" then
        --requires file's path, eg pages/home.lua
        local file_path = message[2]
        
        
        ok, file_read = pcall(fs.open, file_path, "r")
        if fs.exists(file_path) then
            local file = file_read.readAll()
            file_read.close()
            
            rednet.send(id, {"fetch_file", file}, "intranet_admin")
        end    

    elseif message[1] == "upload_file" then
        
        local upload_file = message[2]
        local path = upload_file[1]
        local file = upload_file[2]
        
        if path and file then
            file_write = fs.open(path, "w")
            
            file_write.write(file)
            file_write.close()
            reload()
        end
    
    elseif message[1] == "update_sw" then
        update_sw()
    
    elseif message[1] == "reload" then
        reload()
        
    elseif message[1] == "data_request" then
        print("Sending server data")
        rednet.send(id, read_server_data(), "intranet_admin")
    
    elseif message[1] == "list_files" then
        local path = message[2] or "rom"
        
        local list = fs.list(path)
        
        rednet.send(id, {"list_files", list}, "intranet_admin")
    
    end
 
end

local function process_message(id, message)

    --receives message over intranet protocol
    -- message format:
    -- {message type, content}
    
    -- message types: page_request, click
    
    
    -- sort messages by type
    if message[1] == "page_request" then
        local request = message[2]
        -- starts function page_request with pars
        page_request(id, request)
    elseif message[1] == "indexer" then
    
        local info = read_server_data()
        
        local page_index = {
            info.address,
            info.keywords,
            info.display_name,
            info.description
            }
    
        
        
        rednet.send(id, page_index, "intranet")
                
    elseif message[1] == "button_press" then
        print(id, message[2])
	local button_input = message[2]
	local input_id = button_input
	local input_value = true
			
	print(id, button_input, "pressed")

	local addon = addon_inputs[input_id]

	if addon and addon.receive_input then
	    addon_output = addon.receive_input(id, input_id, input_value)
	    if type(addon_output) == "string" then
		rednet.send(id, {"page", addon_output}, "intranet")
	    end

		
	end



    elseif message[1] == "textbox_input" then
	local textbox_input = message[2]
	local input_id = textbox_input[1]
	local input_value = textbox_input[2]
			
	print(id, textbox_input[1], textbox_input[2])

	local addon = addon_inputs[input_id]

	if addon and addon.receive_input then
	    addon_output = addon.receive_input(id, input_id, input_value)
	    if type(addon_output) == "string" then
		rednet.send(id, {"page", addon_output}, "intranet")
	    end

		
	end
    
end
end

local function receive_message()
    while true do
    local id, message, protocol = rednet.receive()
    
    if protocol == "intranet" then
        process_message(id, message)
    elseif protocol == "intranet_admin" then
        print("Received admin message")
        
        local logins = message[2]
        
        local sec_user = read_server_data().user
        local sec_pass = read_server_data().pass
        
        
            process_admin(id, message)
            
        
   
    
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
    elseif key1 == keys.r then
        term.redirect(term.native())
        term.setCursorPos(1,1)
        reload()
    
    elseif key1 == keys.c then
        write("Console: ")
        local command = read()
        shell.run(tostring(command))
    
    elseif key1 == keys.u then
        print("Are you sure you want to update? Y/N")
        local event, key = os.pullEvent("key")
        if key == keys.y or key == keys.z then
            term.redirect(term.native())
            update_sw()
        end    
        
        
    end
end
end

parallel.waitForAll(receive_message, keystrokes)

    
    
    
    
    


