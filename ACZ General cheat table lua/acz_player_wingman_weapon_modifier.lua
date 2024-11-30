{$lua}

--[[
=================================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - PLAYER/WINGMAN WEAPON MODIFIER SCRIPT ====
=================================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written in and is best viewed on Notepad++.
v301124
]]

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

------------------+
---- [TABLES] ----+
------------------+

AczPlayerWingmanWpn_data_list = {}
local tbl = {}

---------------------+
---- [FUNCTIONS] ----+
---------------------+

-- Create header 
local function create_header(header_name, header_appendtoentry, header_options)

    local header_memory_record_name = getAddressList().createMemoryRecord()
    header_memory_record_name.Description = header_name
    header_memory_record_name.isGroupHeader = true
    
    if header_appendtoentry ~= nil then
    
        header_memory_record_name.appendToEntry(header_appendtoentry)
        
    end
    
    if header_options then
        
        header_memory_record_name.options = "[moHideChildren, moAllowManualCollapseAndExpand, moManualExpandCollapse]"
        
    end
    
    return header_memory_record_name
    
end

-- Create memory record
local function create_memory_record(base_address, offset_list, vt_list, description_list, append_to_entry)

    for i = 1, #offset_list do
        
        local memory_record = getAddressList().createMemoryRecord()
        memory_record.Description = description_list[i]
        memory_record.setAddress(base_address + offset_list[i])
        
        if type(vt_list[i]) == "table" then
            
            if vt_list [i][1] == vtByteArray then
                
                memory_record.Type = vtByteArray
                memory_record.Aob.Size = vt_list[i][2]
                memory_record.ShowAsHex = true
                
            elseif vt_list [i][1] == vtString then
                
                memory_record.Type = vtString
                memory_record.String.Size = vt_list[i][2]
                
            end
            
        else
            
            memory_record.Type = vt_list[i]
            
        end
        
        memory_record.appendToEntry(append_to_entry)
        
    end
    
    return
    
end

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

-- MR generator
local function generate_mr(dat_base_address, header_name, parent_header_name, val)

    local dat_file_toc = retrieve_toc(dat_base_address)
    local base_address = dat_file_toc[val]
    AczPlayerWingmanWpn_data_list[#AczPlayerWingmanWpn_data_list + 1] = base_address
    AczPlayerWingmanWpn_data_list[#AczPlayerWingmanWpn_data_list + 1] = readBytes(base_address, 272, true)
    
    -- Header
    local entity_header = create_header(header_name, parent_header_name, true)
    
    -- Sub record
    local header_list = {"Ammo parameters", "SpW loadout", "GUN parameters", "Missile parameters"}
    local start_offset = {0x0, 0x30, 0x50, 0xB0}
    local offset_list = {{0x18, 0x1A, 0x1B, 0x1C, 0x1D}, {0x14, 0x15, 0x16}, {0x20, 0x24, 0x30, 0x34, 0x38, 0x40, 0x59}, {0x20, 0x24, 0x2C, 0x30, 0x34, 0x3C, 0x59} } local vt_list = { {vtWord, vtByte, vtByte, vtByte, vtByte}, {vtByte, vtByte, vtByte}, {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtByte}, {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtByte} } local description_list = { {"GUN starting amount", "Standard missile starting amount", "SpW 1 starting amount", "SpW 2 starting amount", "SpW 3 starting amount"}, {"SpW slot 1", "SpW slot 2", "SpW slot 3"}, {"Pipper range visibility", "Bullet travel distance", "Attack interval (affects wingman only)", "Fire rate", "Attack duration (affects wingman only)", "Fire dispersion", "Damage"}, {"Lock-on range", "Missile travel distance", "Launch delay (affects wingman only)", "Launch rate 1 (affects wingman only)", "Launch rate 2", "Accuracy", "Damage"}}
    
    for i = 1, 4 do
    
        local header = create_header(header_list[i], entity_header, true)
        create_memory_record(base_address + start_offset[i], offset_list[i], vt_list[i], description_list[i], header)
        
    end
    
    return
    
end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
AczPlayerWingmanWpn_pcsx2_id_ram_start = pcsx2_version_check()

if (AczPlayerWingmanWpn_pcsx2_id_ram_start[3] == nil) then

    -- Check if the emulator has the right game loaded.
    local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x300000, AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)
    
    if #SLUS_21346_check ~= 0 then
    
        -- Check if the player is currently in a mission.
        if (readBytes(AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then
        
            -- Check if the player is NOT in a multiplayer match.
            if readBytes(AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x3ACEA0, 1) == 13 then
            
                -- Look for the bytearray needed by the script.
                -- If the search function returned the right amount of results then proceed with the rest of the script.
                tbl = memscan_func(soExactValue, vtByteArray, nil, "11 00 00 00 50 00 00 00 ?0 0? 00 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 00 00 00 00 00 00 00 00 10 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00 00 00 00 00 04 00 00 00 20 00 00 00 60 00 00 00 B0 00 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", nil, AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x700000, AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x1f00000, "", 2, "0", true, nil, nil, nil)
                
                if #tbl == 1  then
                
                    IsAczPlayerWingmanWpnEnabled = true
                    
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

    if AczPlayerWingmanWpn_pcsx2_id_ram_start[3] == 1 then
    
        showMessage("<< Attach this table to a running instance of PCSX2 first. >>")
        
    elseif AczPlayerWingmanWpn_pcsx2_id_ram_start[3] == 2 then
    
        showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")
        
    elseif AczPlayerWingmanWpn_pcsx2_id_ram_start[3] == 3 then
    
        showMessage("<< PCSX2 has no ISO file loaded. >>")
        
    end
    
end

----------------+
---- [MAIN] ----+
----------------+

if IsAczPlayerWingmanWpnEnabled then

    -- Create a global header to hold this script's memory records.
    AczPlayerWingmanWpn_header_main = create_header("[MISC] WEAPON AND ATTACK SETTINGS", nil, nil)
    
    -- [Player]
    ---- Find the weapon data used by the player's aircraft.
    ---- Create headers and memory records to display said data.
    ---- Back up said data.
    generate_mr(tbl[1], "Player", AczPlayerWingmanWpn_header_main, 8)
    
    -- [Wingman]
    ---- Look up the current mission's entity index list.
    ---- Check if the wingman has an entry in it.
    ---- If yes then look up the wingman's asset file and read the weapon parameters from it.
    ---- Create a header and memory records to display said parameters. Also create a back up of them too.
    ---- Name the wingman's header accordingly.
    local acz_mission_dat_offset = memscan_func(soExactValue, vtByteArray, nil, "18 00 00 00 70 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 10 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 05 00 00 00 20 00 00 00", nil, AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x700000, AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x1f00000, "", 2, "0", true, nil, nil, nil)
    local acz_mission_dat_toc = retrieve_toc(acz_mission_dat_offset[1])
    local acz_mission_entity_table = retrieve_toc(acz_mission_dat_toc[1] + 0x60)
    
    if readBytes(acz_mission_entity_table[1] + 0x3C, 1) ~= 1 then
        
        tbl = memscan_func(soExactValue, vtByteArray, nil, "08 00 00 00 30 00 00 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 00 00 00 00 00 00 00 00 00 00 00 00 04 00 00 00 20 00 00 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 00 00 00 00 00 00 00 00", nil, AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x700000, AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x1f00000, "", 2, "0", true, nil, nil, nil)
        
        if tbl[1] ~= nil then
        
            if readBytes(AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x3B9A44, 1) == 5 then -- Check if Pixy is the wingman
            
                generate_mr(tbl[1], "Pixy", AczPlayerWingmanWpn_header_main, 3)
                
            elseif readBytes(AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x3B9A44, 1) == 10 then -- Check if PJ is the wingman
            
                generate_mr(tbl[1], "PJ", AczPlayerWingmanWpn_header_main, 3)
                
            end
            
        end
        
    end
    
    showMessage("<< Restart the mission once you've made your changes so they can take effect. >>")
    
end

[DISABLE]

if syntaxcheck then return end

-- On deactivation, if the script activation was successful then:
---- If the player disabled the script while in a mission then restore the modified data using the back up created previously
---- Clear tables
---- Destroy created memory records
-- else:
---- Clear tables
---- Destroy created memory records
---- Exit script

if IsAczPlayerWingmanWpnEnabled then

    AczPlayerWingmanWpn_header_main.destroy()
    
    if (readBytes(AczPlayerWingmanWpn_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then
    
        for i = 1, #AczPlayerWingmanWpn_data_list, 2 do
        
            writeBytes(AczPlayerWingmanWpn_data_list[i], AczPlayerWingmanWpn_data_list[i + 1])
            
        end
        
        if readInteger(AczPlayerWingmanWpn_pcsx2_id_ram_start[2]) ~= nil then
            
            showMessage("<< Restart the mission to fully revert the changes made. >>")
        
        end
        
    end
    
    AczPlayerWingmanWpn_pcsx2_id_ram_start = nil
    AczPlayerWingmanWpn_data_list = nil
    
    IsAczPlayerWingmanWpnEnabled = nil
    
end