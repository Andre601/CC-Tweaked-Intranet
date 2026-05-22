local addon = {}

local orders = {} --stores order data until ready to print
--[[structure:
{
id = { order_name = ,
       order_items = {},   -table
       order_place = ,
       order_time =     -generated when order is sent
     }
}
]]
function addon.input()
    return {
        order_name = true, --who orders
        order_items = true, --what is ordered (can be a list)
        order_place = true, --where to deliver
        send_order = true, --button to finalise
        cancel_order = true --deletes sender's order data
    }
end

function addon.receive_input(sender_id, input_id, input_value)
    
    if orders[sender_id] == nil then
        orders[sender_id] = {} end
    
    
    
    if input_id == ("order_name" or "order_place") then
        orders[sender_id][input_id] = input_value   
        
        print(sender_id, "added", input_id, input_value)
        
    elseif input_id == "order_items" then
        if orders[sender_id].order_items == nil then
            orders[sender_id].order_items = {} end
        
        table.insert(orders[sender_id].order_items, input_value)
        
        print(sender_id, "added item:", input_value)
    
    elseif input_id == "cancel_order" then
        orders[sender_id] = nil
        
    elseif input_id == "send_order" then
        local printer = peripheral.find("printer")
        
        local p_name = orders[sender_id].order_name or "-"
        local p_items = orders[sender_id].order_items or "-"
        local p_place = orders[sender_id].order_place or "-"
        local p_time = os.date()
        
        
        if not printer.newPage() then
            printError("Cannot print") end
        
        printer.setPageTitle("Order from ".. p_name)
        
        printer.setCursorPos(1,1)
        printer.write("From: ".. p_name)
        printer.setCursorPos(1,2)
        printer.write("Deliver to: ".. p_place)
        printer.setCursorPos(1,3)
        printer.write("Date: ".. p_time)
        
        
        printer.setCursorPos(1,5)
        for i,item in ipairs(p_items) do
            printer.write(item)
            printer.setCursorPos(1,3+i)
        end
        
        printer.endPage()
        
        end    
                    
    return
end

return addon
