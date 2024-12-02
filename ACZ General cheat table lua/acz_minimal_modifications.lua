{$lua}

--[[
========================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - MINIMAL MODIFICATIONS SCRIPT ====
========================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written in and is best viewed on Notepad++.
v011224
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

---------------------+
---- [VARIABLES] ----+
---------------------+

stage_id = nil

------------------+
---- [TABLES] ----+
------------------+

local tbl = {}
AczEnvMinimal_data_list = {}
local stage_dat_file_toc = {}

-- List of *.DAT package arrays listed in the bytearraylist:
---- Stage
---- Mission
---- Missile asset 1/2/3/4
---- Player
---- Wingman

local AczEnvMinimal_bytearray_list = {
    "27 00 00 00 A0 00 00 00 A0 01 00 00",
    "18 00 00 00 70 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 10 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 05 00 00 00 20 00 00 00",
    "1B 00 00 00 70 00 00 00 60 50 00 00 50 A0 00 00 C0 A2 00 00 30 21 01 00 30 5A 16 00 E0 70 16 00 70 87 16 00 20 9E 16 00 D0 B4 16 00 80 CB 16 00 B0 EF 16 00 90 FA 16 00 20 2C 17 00 40 77 17 00",
    "11 00 00 00 50 00 00 00 ?0 0? 00 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 00 00 00 00 00 00 00 00 10 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00 00 00 00 00 04 00 00 00 20 00 00 00 60 00 00 00 B0 00 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00",
    "08 00 00 00 30 00 00 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 00 00 00 00 00 00 00 00 00 00 00 00 04 00 00 00 20 00 00 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 00 00 00 00 00 00 00 00 0B 00 00 00 30 00 00 00 50 00 00 00 ?0 ?? 00 00 ?0 ?? 0? 00 ?0 ?? 01 00 ?0 ?? 01 00 ?0 ?? 01 00 ?0 ?? 02 00 ?0 ?? 02 00 ?0 ?? 02 00 ?0 ?? 02 00 00 00 C8 43 00 00 48 44 00 00 ?? 44 00 ?? C? 45 00 00 48 46 00 00 00 00 00 00 00 00 00 00 00 00 41 43 4D 00 05 00 00 00 ?? ?? ?? 42 ?? ?? ?? 4?"
}

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

-- "X item exists in Y table" check function
local function value_exists(tab, val)

    for index, value in ipairs(tab) do
    
        if value == val then
        
            return true
            
        end
        
    end
    
    return false
    
end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check if the "Custom" version of the environment modifier script is enabled. If not, then proceed with the rest of the check.
if not IsAczEnvCustomEnabled then
    
    -- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
    -- Set the working RAM region ranges based on emulator version.
    AczEnvMinimal_pcsx2_id_ram_start = pcsx2_version_check()
    
    if (AczEnvMinimal_pcsx2_id_ram_start[3] == nil) then
        
        -- Check if the emulator has the right game loaded.
        local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x300000, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)
        
        if #SLUS_21346_check ~= 0 then
            
            -- Check if the player is currently in a mission.
            if (readBytes(AczEnvMinimal_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then
                
                -- Check if the player is in a stage compatible with this script.
                stage_id = readSmallInteger(AczEnvMinimal_pcsx2_id_ram_start[2] + 0x3BF740) -- Read the current mission ID value.
                
                if (stage_id >= 0 and stage_id <= 30) or (stage_id >= 78 and stage_id <= 108) then
                    
                    -- Look for the bytearrays needed by the script.
                    tbl = memscan_func(soExactValue, vtByteArray, nil, AczEnvMinimal_bytearray_list[1], nil, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x700000, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x1f00000, "", 2, "0", true, nil, nil, nil)
                    
                    -- If the search function returned the right amount of results then proceed with the rest of the script.
                    if #tbl == 1  then
                        
                        IsAczEnvMinimalEnabled = true
                        
                    else
                        
                        if tbl == nil then
                            
                            showMessage("<< Unable to activate this script (memscan_func returned nil). >>")
                            
                        elseif #tbl >= 1 then
                            
                            showMessage("<< Unable to activate this script (memscan_func returned more than one result). >>")
                            
                        end
                        
                    end
                    
                else
                    
                    showMessage("<< This mission or mode is not compatible with this script. >>")
                    
                end
                
            else
                
                showMessage("<< You'll need to be in a mission to use this script. >>")
                
            end
            
        else
            
            showMessage("<< This script is not compatible with the game you're currently emulating. >>")
            
        end
        
    else
        
        if AczEnvMinimal_pcsx2_id_ram_start[3] == 1 then
            
            showMessage("<< Attach this table to a running instance of PCSX2 first. >>")
            
        elseif AczEnvMinimal_pcsx2_id_ram_start[3] == 2 then
            
            showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")
            
        elseif AczEnvMinimal_pcsx2_id_ram_start[3] == 3 then
            
            showMessage("<< PCSX2 has no ISO file loaded. >>")
            
        end
        
    end
    
else
    
    showMessage("<< Disable the [EXTENDED MODIFICATIONS] script before activating this one first. >>")
    
end

----------------+
---- [MAIN] ----+
----------------+

if IsAczEnvMinimalEnabled then
    
    -- Get stage file ToC.
    stage_dat_file_toc = retrieve_toc(tbl[1])
    
    -- Read and store the address and bytearray data of the first stage environment set.
    AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = stage_dat_file_toc[19] -- address
    AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = readBytes(stage_dat_file_toc[19], 864, true) -- bytearray data
    
    -- Read and store the address and bytearray data of the second stage environment set.
    AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = stage_dat_file_toc[38]
    AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = readBytes(stage_dat_file_toc[38], 864, true)
    
    -- If the main stage file has a take-off/landing/refueling stage in it then also append its start offsets and environment data.
    if readBytes(stage_dat_file_toc[39], 1) == 38 then
        
        local sub_stage_dat_file_toc = retrieve_toc(stage_dat_file_toc[39])
        
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = sub_stage_dat_file_toc[19]
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = readBytes(sub_stage_dat_file_toc[19], 864, true)
        
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = sub_stage_dat_file_toc[38]
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = readBytes(sub_stage_dat_file_toc[38], 864, true)
        
        -- Clean sub-file ToC table
        for k, v in pairs(sub_stage_dat_file_toc) do sub_stage_dat_file_toc[k] = nil end
        
    else
    
        -- Clean the the ToC table just in case.
        stage_dat_file_toc = nil
        tbl = nil
        
    end
    
    -- //[ENVIRONMENT MODIFIERS]//
    -- Apply the modifications to all environment parameter sets found.
    
    for i = 1, #AczEnvMinimal_data_list, 2 do
        
        -- If the script detects it's attached to PCSX2 1.6.0 then apply some special fixes to disable some graphic effects
        -- that aren't properly rendered by this version the emulator when running the game in "Hardware Mode" graphic option
        -- as well using a custom resolution.
        if AczEnvMinimal_pcsx2_id_ram_start[1] == 1 then
            
            writeBytes(AczEnvMinimal_data_list[i], 16) -- Disable cloud shadowmap
            writeBytes(AczEnvMinimal_data_list[i] + 0x44, 0x0) -- Set screen blur multiplier to 0
            writeInteger(AczEnvMinimal_data_list[i] + 0x1FC, 0) -- Set cloud transparency to 0
            writeInteger(AczEnvMinimal_data_list[i] + 0x200, 0) -- Set cloud amount to 0
            writeBytes(AczEnvMinimal_data_list[i] + 0x300, 0x0) -- Set dynamic shadow flag to 0
            
        end
        
    end
    
    -- Global environment settings, companion to the environment mod.
    writeFloat(AczEnvMinimal_pcsx2_id_ram_start[2] + 0x3F8108, 128000.0) -- Increase stage geometry LoD value 1.
    writeFloat(AczEnvMinimal_pcsx2_id_ram_start[2] + 0x3F810C, 128000.0) -- Increase stage geometry LoD value 2.
    
    -- //[LoD MODIFIERS]//
    -- Increase the LoD level of all "interactable" 3D models and increase their spawn range.

    -- Retrieve ToC of mission file.
    local acz_mission_dat_offset = memscan_func(soExactValue, vtByteArray, nil, AczEnvMinimal_bytearray_list[2], nil, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x700000, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x1f00000, "", 2, "0", true, nil, nil, nil)
    local acz_mission_dat_toc = retrieve_toc(acz_mission_dat_offset[1])
    local acz_mission_entity_table = retrieve_toc(acz_mission_dat_toc[1] + 0x60)
    
    -- Entity spawn LoD range (?)
    for i = 1, #acz_mission_entity_table do
    
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = acz_mission_entity_table[i] + 0x30
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = (readBytes(acz_mission_entity_table[i] + 0x30, 12, true))
        
        for z = 1, 3 do
        
            writeFloat(acz_mission_entity_table[i] + 0x30 + ((4 * z) - 4), 128000)
            
        end
        
    end
    
    -- Entity LoD
    local acz_entity_assets_toc = retrieve_toc(acz_mission_dat_toc[2])
    
    for i = 1, #acz_entity_assets_toc do
    
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = acz_entity_assets_toc[i] + 0x30
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = (readBytes(acz_entity_assets_toc[i] + 0x30, 32, true))
        
        for z = 1, 5 do
        
            writeFloat((acz_entity_assets_toc[i] + 0x30) + ((4 * z) - 4), 128000)
            
        end
        
    end
    
    -- Generic missile LoDs
    local acz_unk_dat_offset = memscan_func(soExactValue, vtByteArray, nil, AczEnvMinimal_bytearray_list[3], nil, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x700000, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
    local acz_unk_dat_toc = retrieve_toc(acz_unk_dat_offset[1])
    local tbl = {13, 14, 15 ,16}
    
    for i = 1, #tbl do
    
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = acz_unk_dat_toc[tbl[i]] + 0x20
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = (readBytes(acz_unk_dat_toc[tbl[i]] + 0x20, 16, true))
        
        for z = 1, 4 do
        
            writeFloat(acz_unk_dat_toc[tbl[i]] + 0x20 + ((4 * z) - 4), 128000)
            
        end
        
    end
    
    -- Player Special Weapon model LoD
    local acz_player_dat_offset = memscan_func(soExactValue, vtByteArray, nil, AczEnvMinimal_bytearray_list[4], nil, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x700000, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
    local acz_player_dat_toc = retrieve_toc(acz_player_dat_offset[1])
    local acz_player_wpn_toc = retrieve_toc(acz_player_dat_toc[12])
    
    for i = 1, #acz_player_wpn_toc do
    
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = acz_player_wpn_toc[i] + 0x20
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = (readBytes(acz_player_wpn_toc[i] + 0x20, 16, true))
        
        for z = 1, 4 do
        
            writeFloat(acz_player_wpn_toc[i] + 0x20 + ((4 * z) - 4), 128000)
            
        end
        
    end
    
    -- Wingman aircraft and Special Weapon model LoD
    local acz_wingman_dat_offset = memscan_func(soExactValue, vtByteArray, nil, AczEnvMinimal_bytearray_list[5], nil, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x700000, AczEnvMinimal_pcsx2_id_ram_start[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
    local acz_wingman_dat_toc = retrieve_toc(acz_wingman_dat_offset[1])
    
    ---- Wingman aircraft and Special Weapon model LoD: Aircraft model LoD
    AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = acz_wingman_dat_toc[1] + 0x50
    AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = (readBytes(acz_wingman_dat_toc[1] + 0x50, 32, true))
    
    for z = 1, 5 do
    
        writeFloat(acz_wingman_dat_toc[1] + 0x50 + ((4 * z) - 4), 128000)
        
    end
    
    ---- Wingman aircraft and Special Weapon model LoD: SpW model LoD
    local acz_wingman_wpn_toc = retrieve_toc(acz_wingman_dat_toc[7])
    
    for i = 1, #acz_wingman_wpn_toc do
    
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = acz_wingman_wpn_toc[i] + 0x20
        AczEnvMinimal_data_list[#AczEnvMinimal_data_list + 1] = (readBytes(acz_wingman_wpn_toc[i] + 0x20, 16, true))
        
        for z = 1, 4 do
        
            writeFloat(acz_wingman_wpn_toc[i] + 0x20 + ((4 * z) - 4), 128000)
            
        end
        
    end
    
    -- Show message asking the user to restart the mission so the effects can take change.
    showMessage("<< Restart the mission to fully apply the changes. >>")
    
end

[DISABLE]

if syntaxcheck then return end

    -- On deactivation, if the script activation was successful then:
    ---- Check if the script was deactivated while in a mission. If true then:
        ---- Restore modified environment values
    ---- else
        ---- Restored modified global environment variables
        ---- Clear tables
        ---- Exit script

if IsAczEnvMinimalEnabled then
    
    if (readBytes(AczEnvMinimal_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then
    
        for i = 1, #AczEnvMinimal_data_list,2 do
        
            writeBytes(AczEnvMinimal_data_list[i], AczEnvMinimal_data_list[i + 1])
            
        end
        
        if readInteger(AczEnvMinimal_pcsx2_id_ram_start[2]) ~= nil then
            
            showMessage(" Restart the mission to fully revert the changes. >>")
        
        end
        
    end
    
    -- Restore default values for the global graphic settings.
    writeBytes(getAddress(AczEnvMinimal_pcsx2_id_ram_start[2] + 0x3F8108), 0x00, 0x00, 0x00, 0x47) -- Stage geometry LoD value 1.
    writeBytes(getAddress(AczEnvMinimal_pcsx2_id_ram_start[2] + 0x3F810C), 0x00, 0x00, 0xC0, 0x46) -- Stage geometry LoD value 2.
    
    -- Clean tables containing addresses and bytes
    AczEnvMinimal_pcsx2_id_ram_start = nil
    AczEnvMinimal_data_list = nil
    
    -- Set script's activation flag to false
    IsAczEnvMinimalEnabled = nil
    
end
