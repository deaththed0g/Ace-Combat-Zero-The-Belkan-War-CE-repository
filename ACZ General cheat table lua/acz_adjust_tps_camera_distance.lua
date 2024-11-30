{$lua}

--[[
======================================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - ADJUST THIRD PERSON CAMERA DISTANCE SCRIPT ====
======================================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v301124
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

---------------------+
---- [FUNCTIONS] ----+
---------------------+

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

------------------+
---- [TABLES] ----+
------------------+

local tbl = {}
AczCamAdjustZ_data_list = {}

-----------------+
---- [CHECK] ----+
-----------------+

-- Check if any of the "HANGAR", "GAMEPLAY" or "FREE MOVEMENT MODE" scripts are active. If false continue with the next check.
if (not IsAczFreecamHangarEnabled) and (not IsAczCamAdjustZEnabled) and (not IsAczFreeMoveEnabled) then

    -- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
    -- Set the working RAM region ranges based on emulator version.
    AczCamAdjustZ_pcsx2_id_ram_start = pcsx2_version_check()
    
    if (AczCamAdjustZ_pcsx2_id_ram_start[3] == nil) then
    
        -- Check if the emulator has the right game loaded.
        local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, AczCamAdjustZ_pcsx2_id_ram_start[2] + 0x300000, AczCamAdjustZ_pcsx2_id_ram_start[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)
        
        if #SLUS_21346_check ~= 0 then
        
            -- Check if the player is currently in a mission.
            if (readBytes(AczCamAdjustZ_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then
            
                -- Check if the player is NOT in a multiplayer match.
                if readBytes(AczCamAdjustZ_pcsx2_id_ram_start[2] + 0x3ACEA0, 1) == 13 then
                
                    -- Check if the player is NOT taking off, landing, in a pre-rendered cutscene or has the game paused.
                    -- if value_exists({3, 15, 23}, readBytes(AczCamAdjustZ_pcsx2_id_ram_start[2] + 0x76587C), 1) and readByte(AczCamAdjustZ_pcsx2_id_ram_start[2] + 0x7651E8) == 4 then
                    
                    if value_exists({3, 15, 23}, readBytes(AczCamAdjustZ_pcsx2_id_ram_start[2] + 0x76587C), 1) then
                    
                        -- Look for the bytearray needed by the script.
                        tbl = memscan_func(soExactValue, vtByteArray, nil, "00 00 ?? 44 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 ?? ?? ?? 00 00 00 00 00 02 C0 01 00 00 80 3F FF FF 7F 4B 00 00 00 00 00 02 C0 01 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 3F ?? ?? ?? 43 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 00 00 00 00 00 00 00 C5 00 00 00 C5 ?? ?? ?? ?? 00 00 80 BF 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 ?? ?? ?? 3F 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? 80 BF 00 00 80 BF 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 45 00 00 00 45 CD CC ?? ?? ?? ?? ?? 3F 03 00 00 00 ?? ?? ?? ?? 01 00 00 ?? ?? ?? ?? ?? 00 00 00 15 00 01 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 ?? 44 00 00 ?? ??", nil, AczCamAdjustZ_pcsx2_id_ram_start[2] + 0x800000, AczCamAdjustZ_pcsx2_id_ram_start[2] + 0x1F00000, "", 1, "4", true, nil, nil, nil)
                        
                        -- If the search function returned the right amount of results then proceed with the rest of the script.
                        if tbl[1] ~= nil then
                        
                            IsAczCamAdjustZEnabled = true
                            
                        else
                        
                            showMessage("<< Unable to activate this script (memscan_func returned nil). >>")
                            
                        end
                        
                    else
                    
                        showMessage("<< The script will not work during cutscenes. >>")
                        
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
    
        if AczCamAdjustZ_pcsx2_id_ram_start[3] == 1 then
        
            showMessage("<< Attach this table to a running instance of PCSX2 first. >>")
            
        elseif AczCamAdjustZ_pcsx2_id_ram_start[3] == 2 then
        
            showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")
            
        elseif AczCamAdjustZ_pcsx2_id_ram_start[3] == 3 then
        
            showMessage("<< PCSX2 has no ISO file loaded. >>")
            
        end
        
    end
    
else

    showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [HANGAR]".."\n- [GAMEPLAY]".."\n- [FREE MOVEMENT MODE]".."\n".."\nDeactivate them before activating this one first. >>")
    
end

----------------+
---- [MAIN] ----+
----------------+

if IsAczCamAdjustZEnabled then

    -- //[CAMERA XZY/PYR COORDINATES]//
    -- Read and store the aircraft's third-person camera's Z coordinate to restore it on script deactivation.
    AczCamAdjustZ_data_list[#AczCamAdjustZ_data_list + 1] = tbl[1] + 0xB38
    AczCamAdjustZ_data_list[#AczCamAdjustZ_data_list + 1] = readBytes(tbl[1] + 0xB38, 4, true)
    
    -- //[HOTKEYS]//
    -- Store aircraft's Z camera position/coordinate previous to script activation to use it with the restore function later.
    -- Define hotkey function, speed modifier and create timer.
    
    local default_zcoord_value = readFloat(tbl[1] + 0xB38) -- Original camera's Z position value.
    local camera_base_speed = 5 -- Camera zoom speed.
    
    local function checkKeys(timer)
        
        -- Check if PCSX2 is up and running. if not, disable script.
        
        if readInteger(AczCamAdjustZ_pcsx2_id_ram_start[2]) ~= nil then
    
            if readFloat(AczCamAdjustZ_data_list[1]) < default_zcoord_value then -- Reset Z position if its current value is lower than the one stored in "default_zcoord_value".
            
                writeBytes(AczCamAdjustZ_data_list[1], AczCamAdjustZ_data_list[2])
                
            end
            
            if (isKeyPressed(VK_ADD)) then -- [TPS CAM 1] Zoom in if ADD NUMPAD is being pressed.
            
                writeFloat(AczCamAdjustZ_data_list[1], readFloat(AczCamAdjustZ_data_list[1]) - camera_base_speed)
                
            elseif (isKeyPressed(VK_SUBTRACT)) then -- [TPS CAM 1] Zoom out if SUBSTRACT NUMPAD is being pressed.
            
                writeFloat(AczCamAdjustZ_data_list[1], readFloat(AczCamAdjustZ_data_list[1]) + camera_base_speed)
                
            elseif (isKeyPressed(VK_NUMPAD0)) then -- Panic key (reset everything) if NUMPAD 0 was pressed.
            
                writeBytes(AczCamAdjustZ_data_list[1], AczCamAdjustZ_data_list[2])
                
            end
        
        else
            
            -- Self disable script.
            getAddressList().getMemoryRecordByDescription("Adjust third person camera distance").Active = false
        
        end
        
        return
        
    end
    
    -- Initialize timer object for the hotkey function.
    AczCamAdjustZ_hotkeyTimer = createTimer(nil, true) -- Create timer object
    AczCamAdjustZ_hotkeyTimer.Interval = 50 -- Set tick rate
    AczCamAdjustZ_hotkeyTimer.onTimer = checkKeys -- Call this function every Nms value set in the ".Interval" parameter.
    AczCamAdjustZ_hotkeyTimer.Enabled = true -- Enable the timer object.
    
end

[DISABLE]

if syntaxcheck then return end

-- On deactivation, if the script activation was successful then:
---- Destroy hotkey timer
---- Restore modified values
---- Clear tables
---- Exit script

if IsAczCamAdjustZEnabled then
    
    if AczCamAdjustZ_hotkeyTimer then
    
        AczCamAdjustZ_hotkeyTimer.destroy()
        AczCamAdjustZ_hotkeyTimer = nil
    
    end
    
    if (readBytes(AczCamAdjustZ_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then
    
        writeBytes(AczCamAdjustZ_data_list[1], AczCamAdjustZ_data_list[2])
        
    end
    
    AczCamAdjustZ_data_list = nil
    AczCamAdjustZ_pcsx2_id_ram_start = nil
    
    IsAczCamAdjustZEnabled = nil
    
end