local addon = {}

local intranet_index = {}

local result_header =
[[
Goggles
 +-[ Ponder: ]------------------------+
 I<textbox id="querry">                                ]></textbox>I
 +------------------------------------+

]]
local result_template =
[[
DISPLAY
  <link src="NAME">NAME</link>
  DESC
  Ponder score: DISTANCE
    
]]

function addon.input()
    return {
        querry = true
    }
end
--receives querry and returns result page
function addon.receive_input(sender_id, input_id, input_value)
    indexer()
    local results = search(input_value)
    
    local build_page = build_result_page(results)
    --debug:
    print(build_page)
    return build_page
end

function indexer()
    -- Clear old index before indexing again
    intranet_index = {}

    -- Indexes all hosting ids on intranet
    local index_ids = { rednet.lookup("intranet") }

    for _, id in ipairs(index_ids) do
        rednet.send(id, {"indexer"}, "intranet")

        local sender_id, server_index = rednet.receive("intranet", 1)

        -- Accept only response from the requested server
        -- and ignore accidental {"indexer"} messages
        if sender_id == id and type(server_index) == "table" and server_index[1] ~= "indexer" then
            intranet_index[id] = server_index
        end
    end
end
function search(query)

    local results = {}

    query = string.lower(tostring(query or ""))

    for server_id, server_data in pairs(intranet_index) do
        -- server_data format:
        -- { server_name, { keywords } }

        if type(server_data) == "table" then
            local server_name = tostring(server_data[1])
            local keywords = server_data[2] or {}
            local display_name = server_data[3] or server_name
            local desc = server_data[4] or " "

            local server_name_lower = string.lower(server_name)

            -- Base distance: query compared to server name
            local distance = string_distance(query, server_name_lower)

            -- Keyword bonus: query compared directly to each keyword
            for _, keyword in ipairs(keywords) do
                local keyword_lower = string.lower(tostring(keyword))

                if query == keyword_lower then
                    distance = distance - 5
                end
            end

            if distance < 0 then
                distance = 0
            end

            table.insert(results, {
                name = server_name,
                distance = distance,
                display_name = display_name,
                desc = desc
            })
        end
    end

    table.sort(results, function(a, b)
        return a.distance < b.distance
    end)

 
    return results
end

function build_result_page(results)
    local page = result_header

    for _, result in ipairs(results) do
        local result_block = result_template

        result_block = result_block:gsub("NAME", tostring(result.name))
        result_block = result_block:gsub("DISTANCE", tostring(result.distance))
        result_block = result_block:gsub("DISPLAY", tostring(result.display_name))
        result_block = result_block:gsub("DESC", tostring(result.desc))
    
        page = page .. result_block
    end

    return page
end
--Compares two strings
function string_distance(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local matrix = {}
	local cost = 0
	
        -- quick cut-offs to save time
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end
	
        -- initialise the base matrix values
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end
	
        -- actual Levenshtein algorithm
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (str1:byte(i) == str2:byte(j)) then
				cost = 0
			else
				cost = 1
			end
			
			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end
	
        -- return the last value - this is the Levenshtein distance
	return matrix[len1][len2]
end    
return addon
