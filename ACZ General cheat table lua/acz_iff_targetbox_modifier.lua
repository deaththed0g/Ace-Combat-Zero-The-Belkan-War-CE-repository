{$lua}

--[[
==========================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - IFF/TARGET BOX MODIFIER SCRIPT ====
==========================================================================

By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written in and is best viewed on Notepad++.
v301124
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

------------------+
---- [TABLES] ----+
------------------+

AczHudMod_data_list = {}
local tbl = {}

---------------------+
---- [FUNCTIONS] ----+
---------------------+

-- Retrieve Table of Contents of a container file.
local function retrieve_toc(base_address)

    local table_name = {}
    local n = readBytes(base_address, 1)
    
    for i = 1, n do
    
        table_name[#table_name + 1] = base_address + (readInteger(base_address + (i * 4)))
        
    end
    
    return table_name
end

-- Check current version and amount of active instances of PCSX2, set working RAM region.
local function pcsx2_version_check()

    version_id = nil
    pcsx2_id_ram_start = nil
    error_flag = nil
    local process_found = {}
    
    for processID, processName in pairs(getProcessList()) do
    
        if processName == "pcsx2.exe" or processName == "pcsx2-qt.exe" then
        
            process_found[#process_found + 1] = processName
            process_found[#process_found + 1] = processID
            
        end
        
    end
    
    if process_found[1] ~= nil then
    
        if (process_found[2] == getOpenedProcessID()) then
        
            if process_found[1] == "pcsx2.exe" then
            
                version_id = 1
                pcsx2_id_ram_start = getAddress(0x20000000)
                
                if readInteger(pcsx2_id_ram_start) == nil then
                
                    error_flag = 3
                    
                end
                
            elseif process_found[1] == "pcsx2-qt.exe" then
            
                version_id = 2
                pcsx2_id_ram_start = getAddress(readPointer("pcsx2-qt.EEmem"))
                
                if readInteger(pcsx2_id_ram_start) == 0 then
                
                    error_flag = 3
                    
                end
                
            end
            
        else
        
            error_flag = 2
            
        end
        
    else
    
        error_flag = 1
        
    end
    
    return {version_id, pcsx2_id_ram_start, error_flag}
    
end

-- Memory scanner function
local function memscan_func(scanoption, vartype, roundingtype, input1, input2, startAddress, stopAddress, protectionflags, alignmenttype, alignmentparam, isHexadecimalInput, isNotABinaryString, isunicodescan, iscasesensitive)

    local memory_scan = createMemScan()
    memory_scan.firstScan(scanoption, vartype, roundingtype, input1, input2 ,startAddress ,stopAddress ,protectionflags ,alignmenttype, alignmentparam, isHexadecimalInput, isNotABinaryString, isunicodescan, iscasesensitive)
    memory_scan.waitTillDone()
    local found_list = createFoundList(memory_scan)
    found_list.initialize()
    local address_list = {}
    
    if (found_list ~= nil) then
    
        for i = 0, found_list.count - 1 do
        
            table.insert(address_list, getAddress(found_list[i]))
            
        end
        
    end
    
    found_list.deinitialize()
    found_list.destroy()
    found_list = nil
    
    return address_list
    
end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.

AczHudMod_pcsx2_id_ram_start = pcsx2_version_check()

if (AczHudMod_pcsx2_id_ram_start[3] == nil) then

    -- Check if the emulator has the right game loaded.
    local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, AczHudMod_pcsx2_id_ram_start[2] + 0x300000, AczHudMod_pcsx2_id_ram_start[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)
    
    if #SLUS_21346_check ~= 0 then
    
        -- Check if the player is currently in a mission.
        if (readBytes(AczHudMod_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then
        
            -- Check if the player is NOT in a multiplayer match.
            if readBytes(AczHudMod_pcsx2_id_ram_start[2] + 0x3ACEA0, 1) == 13 then
            
                -- Look for the bytearray needed by the script.
                -- If the search function returned the right amount of results then proceed with the rest of the script.
                tbl = memscan_func(soExactValue, vtByteArray, nil, "18 00 00 00 70 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 10 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 05 00 00 00 20 00 00 00", nil, AczHudMod_pcsx2_id_ram_start[2] + 0x700000, AczHudMod_pcsx2_id_ram_start[2] + 0x1f00000, "", 2, "0", true, nil, nil, nil)
                
                if #tbl ~= nil and #tbl == 1  then
                
                    IsAczHudModEnabled = true
                    
                else
                
                    if tbl == nil then
                    
                        showMessage("<< Unable to activate this script (memscan_func returned nil). >>")
                        
                    elseif #tbl >= 1 then
                    
                        showMessage("<< Unable to activate this script (memscan_func returned more than one result). >>")
                        
                    end
                    
                end
                
            else
            
                showMessage("<< The script won't work here. >>")
                
            end
            
        else
        
            showMessage("<< You'll need to be in a mission to use this script. >>")
            
        end
        
    else
    
        showMessage("<< This script is not compatible with the game you're currently emulating. >>")
        
    end
    
else

    if AczHudMod_pcsx2_id_ram_start[3] == 1 then
    
        showMessage("<< Attach this table to a running instance of PCSX2 first. >>")
        
    elseif AczHudMod_pcsx2_id_ram_start[3] == 2 then
    
        showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")
        
    elseif AczHudMod_pcsx2_id_ram_start[3] == 3 then
    
        showMessage("<< PCSX2 has no ISO file loaded. >>")
        
    end
    
end

----------------+
---- [MAIN] ----+
----------------+

if IsAczHudModEnabled then

    -- Increase the visibility range for the TGT boxes.
    writeFloat(AczHudMod_pcsx2_id_ram_start[2] + 0x3FC678, 128000)
    
    -- Look up the file asset that contains the current mission and entities' parameters.
    -- From that file read the entity index.
    -- For every entity entry in the index set their IFF tag to visible.

    local main_file = retrieve_toc(tbl[1])
    local mission_file = retrieve_toc(main_file[1] + 0x20)
    local entity_file = retrieve_toc(mission_file[1] + 0x20)
    
    for i = 1, #entity_file do
    
        if i ~= 1 then
        
            local current_entities_group = retrieve_toc(entity_file[i] + 0x50)
            
            for i = 1, #current_entities_group do
            
                if readBytes(current_entities_group[i], 4) ~= 0 then
                
                    if i ~= 1 then
                    
                       AczHudMod_data_list[#AczHudMod_data_list + 1] = current_entities_group[i] + 0xD5
                       AczHudMod_data_list[#AczHudMod_data_list + 1] = readBytes(current_entities_group[i] + 0xD5, 1)
                       
                       writeBytes(current_entities_group[i] + 0xD5, 0)
                       
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

[DISABLE]

if syntaxcheck then return end

-- On deactivation, if the script activation was successful then:
---- If the player disabled the script while in a mission then restore the modified data using the back up created previously.
---- Clear tables
-- else:
---- Clear tables
-- Then exit script.

if IsAczHudModEnabled then

    if (readBytes(AczHudMod_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then
    
        for i = 1, #AczHudMod_data_list, 2 do
        
            writeBytes(AczHudMod_data_list[i], AczHudMod_data_list[i + 1])
            
        end
        
        writeBytes(AczHudMod_pcsx2_id_ram_start[2] + 0x3FC678, 0x00, 0x00, 0x00, 0x47)
        
    end
    
    AczHudMod_pcsx2_id_ram_start = nil
    AczHudMod_data_list = nil
    
    IsAczHudModEnabled = nil
    
end