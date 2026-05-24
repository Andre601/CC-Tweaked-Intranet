peripheral.find("modem", rednet.open)

local servers_data = {}

local logged_id

local login_status = false

function search_servers()
    
    servers_data = {}
    
    local found_ids = { rednet.lookup("intranet_admin") }
    
    for i, id in ipairs(found_ids) do
        if id ~= os.getComputerID() then
        
        
        
        rednet.send(id, {"data_request"}, "intranet_admin")
        
        local id, data = rednet.receive("intranet_admin", 5)
        
        
        print(id, data.address)
        if i == 12 then term.setCursorPos(20,1) end
        
        servers_data[id] = data
        end
    end

end

function login()
    
    term.setCursorPos(1,13)
    
    print("Enter server id:")
    
    
    local login_id = tonumber(read())
    
    print("Enter username:")
    
    
    local login_user = read()
    
    print("Enter password:")
    
    
    local login_pass = read()
    
    if servers_data[login_id].user == login_user and servers_data[login_id].pass == login_pass then
        login_status = true
        logged_id = login_id
    end

end

function file_mng()

    term.clear()
    term.setCursorPos(1,1)
    
    print("File manager")
    print()
    print(" [A] Fetch file")
    print(" [B] Edit file")
    print(" [C] Delete file")
    print(" [D] Upload file")
    print(" [E] List files")
    print("")
    print(" [X] Cancel")
    
    local event, key = os.pullEvent("key")
    
    if key == keys.a then
    
        print("Enter file path")
        local path = read()
        fetch_file(logged_id, path)
    
    elseif key == keys.b then
        
        print("Enter file path")
        local path = read()
        if fetch_file(logged_id, path) == false then return end
        shell.run("edit "..logged_id.."/"..path)
        
        local read_file = fs.open(logged_id.."/"..path, "r")
        local file = read_file.readAll()
        read_file.close()
        
        upload_file(logged_id, path, file)
        
    elseif key == keys.c then
        
        print("Select file/path to delete:")
        local delete_path = read()
        
        print("Are you sure? Y/N")
        
        local _, key = os.pullEvent("key")
        
        if key == keys.y or key == keys.z then
            rednet.send(logged_id, {"delete_file", delete_path}, "intranet_admin")
        end
        
    elseif key == keys.d then
        local select_file
        local no_file = true
        while no_file do
            print("Select file to upload:")
            select_path = read()
            
            if (not fs.exists(select_path)) or fs.isDir(select_path) then
                print("File not found or a directory")
                
            else no_file = false
            end
        end    
            
            _, file_read = pcall(fs.open, select_path, "r")
            

            local file = file_read.readAll()
            
            print("Select upload path:")
            local upload_path = read()
            
            upload_file(logged_id, upload_path, file)
        
        
    elseif key == keys.e then
        print("Select path to list: (can be blank)")
        local list_path = read()
        
        rednet.send(logged_id, {"list_files", list_path}, "intranet_admin")
        local _, response = rednet.receive("intranet_admin", 10)
    
        local list = {}
        if response then list = response[2]
            for _, x in ipairs(list) do
                print(x)
            end    
        end
        read()    
    
    elseif key == keys.x then
        term.clear()
        gui()
    end
    
    gui()
end

function fetch_file(id, path)

    rednet.send(id, {"fetch_file", path}, "intranet_admin")
    
    local _, file = rednet.receive("intranet_admin", 10)
    
    if not file then return false end
    
    local save_file = fs.open(id.."/"..path, "w")
    save_file.write(file[2])
    save_file.close()
    if file then return true end

end

function upload_file(id, path, file)

    rednet.send(logged_id, {"upload_file", {path, file}}, "intranet_admin")
    print("Sent file")
end


function gui()

    term.clear()
    term.setCursorPos(1,1)
    print("Logged into server ID", logged_id)
    print()
    
    print(" [A] Server info")
    print(" [B] File manager")
    print(" [C] Reload server")
    print(" [D] Restart server")
    print(" [E] Update server software")
    
    print(" [X] Logout")

end

function controls() while login_status do

    local event, key = os.pullEvent("key")
    
    if key == keys.a then
    
        term.clear()
        term.setCursorPos(1,1)
        print(servers_data[logged_id].display_name)
        print(textutils.serialise(servers_data[logged_id].keywords))
        print(servers_data[logged_id].description)
        
        read()
        
        term.clear()
        gui()
        
    elseif key == keys.b then
        file_mng()
    elseif key == keys.c then
        rednet.send(logged_id, {"reload"}, "intranet_admin")
    elseif key == keys.d then
        rednet.send(logged_id, {"reboot"}, "intranet_admin")
    elseif key == keys.e then
        rednet.send(logged_id, {"update_sw"}, "intranet_admin")
    
    elseif key == keys.x then
        login_status = false
        logged_id = nil
        
        term.clear()
        term.setCursorPos(1,1)
        search_servers()
        login()
        gui()
    end
end end

search_servers()

while login_status == false do
    pcall(login)
    term.clear()    
end    
print("Login successful")

gui()
controls()

