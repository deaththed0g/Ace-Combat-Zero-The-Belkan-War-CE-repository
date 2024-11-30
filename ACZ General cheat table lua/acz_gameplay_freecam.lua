{$lua}

--[[
===================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - GAMEPLAY FREECAM SCRIPT ====
===================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v301124

TODO:
-- Redo everything
-- Shorten the code comments
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

-- Memory scanner
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

-- "X item exists in Y table" check function
local function value_exists(tab, val)

    for index, value in ipairs(tab) do
    
        if value == val then
        
            return true
            
        end
        
    end
    
    return false
    
end

-- Restore default values
function restore(AczFreecamGameplay_address_list, AczFreecamGameplay_data_list, resetXZY, resetXZY2, resetXZYCOCKPIT, resetPYR, hasTheUserDisabledTheScript)
    
    -- "AczFreecamGameplay_address_list" contents:
    ---- 1: HUD menu visibility flag
    ---- 2: Control input bytes
    ---- 3: Last used view
    
    -- Restore original camera XZY values
    if resetXZY then
        
        writeBytes(AczFreecamGameplay_address_list[2], unpack(AczFreecamGameplay_data_list[2], 1, 4))
        writeBytes(AczFreecamGameplay_address_list[2] + 0x4, unpack(AczFreecamGameplay_data_list[2], 5, 8))
        writeBytes(AczFreecamGameplay_address_list[2] + 0x8, unpack(AczFreecamGameplay_data_list[2], 9, 12))
        
    end
    
    -- Restore original camera XZY2 values
    if resetXZY2 then
        
        writeBytes(AczFreecamGameplay_address_list[2] + 0xC, unpack(AczFreecamGameplay_data_list[2], 13, 16))
        writeBytes(AczFreecamGameplay_address_list[2] + 0x10, unpack(AczFreecamGameplay_data_list[2], 17, 20))
        writeBytes(AczFreecamGameplay_address_list[2] + 0x14, unpack(AczFreecamGameplay_data_list[2], 21, 24))
        
    end
    
    -- Restore original cockpit view XZY values
    if resetXZYCOCKPIT then
        
        writeBytes(AczFreecamGameplay_address_list[2] + 0x18, unpack(AczFreecamGameplay_data_list[2], 25, 28))
        writeBytes(AczFreecamGameplay_address_list[2] + 0x1C, unpack(AczFreecamGameplay_data_list[2], 29, 32))
        writeBytes(AczFreecamGameplay_address_list[2] + 0x20, unpack(AczFreecamGameplay_data_list[2], 33, 36))
        
    end
    
    -- Reset camera PYR values
    if resetPYR then
        
        writeFloat(AczFreecamGameplay_address_list[2] + 0xF0, tonumber(0.0))
        writeFloat(AczFreecamGameplay_address_list[2] + 0xF4, tonumber(0.0))
        writeFloat(AczFreecamGameplay_address_list[2] + 0xF8, tonumber(0.0))
        
    end
    
    if hasTheUserDisabledTheScript then
        
        -- Restore pause menu graphics
        writeBytes(AczFreecamGameplay_address_list[1], AczFreecamGameplay_data_list[1])
        
        -- Restore opcodes
        
        if AczFreecamGameplay_pcsx2_id_ram_start[1] == 2 then -- If PCSX2-qt
        
            for i = 1, #acz_gameplay_aob_address_list do
            
                writeBytes(acz_gameplay_aob_address_list[i], 0x0F, 0x29, 0x09)
            
            end
        
        else -- If PCSX2 v1.6.0
        
            for i = 1, #acz_gameplay_aob_address_list do
            
                writeBytes(acz_gameplay_aob_address_list[i], 0x0F, 0x29, 0x11)
            
            end
        
        end
        
    end
    
    return
    
end

-- Pause flag and control input manipulation
function p_ci(pause_flag, disableController)
    
    -- Set pause flag
    writeBytes(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x7651E8, pause_flag)
    
    if disableController then
        
        -- Disable control input
        writeBytes(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x3F70B8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
        
        -- Disable the HUD
        writeBytes(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x3FFBCF, 0x00)
        
    else
        
        -- Restore control input
        writeBytes(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x3F70B8, 0x30, 0x7D, 0x69, 0x00, 0xC0, 0x7D, 0x69, 0x00)
        
        -- Restore the HUD
        writeBytes(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x3FFBCF, 0x01)
        
        -- Apply Right-stick analog "fix"
        writeBytes(rightStickAnalog_address[1] + 0x3, 0x4)
        
    end
    
    return
    
end

-- Third-person camera freecam
function checkKeys_viewCam1(timer)
    
    -- Check if PCSX2 is up and running. if not, disable script.
    
    if readInteger(AczFreecamGameplay_pcsx2_id_ram_start[2]) ~= nil then
    
        if (isKeyPressed(VK_A)) then   -- [TPS CAM 1] Move left
            writeFloat(AczFreecamGameplay_address_list[2], readFloat(AczFreecamGameplay_address_list[2]) + camera_base_speed)
        elseif (isKeyPressed(VK_D)) then -- [TPS CAM 1] Move right
            writeFloat(AczFreecamGameplay_address_list[2], readFloat(AczFreecamGameplay_address_list[2]) - camera_base_speed)
        elseif (isKeyPressed(VK_S)) then -- [TPS CAM 1] Move down
            writeFloat(AczFreecamGameplay_address_list[2] + 0x4, readFloat(AczFreecamGameplay_address_list[2] + 0x4) + camera_base_speed)
        elseif (isKeyPressed(VK_W)) then -- [TPS CAM 1] Move up
            writeFloat(AczFreecamGameplay_address_list[2] + 0x4, readFloat(AczFreecamGameplay_address_list[2] + 0x4) - camera_base_speed)
        elseif (isKeyPressed(VK_Q)) then -- [TPS CAM 1] Zoom in
            writeFloat(AczFreecamGameplay_address_list[2] + 0x8, readFloat(AczFreecamGameplay_address_list[2] + 0x8) - camera_base_speed)
        elseif (isKeyPressed(VK_E)) then -- [TPS CAM 1] Zoom out
            writeFloat(AczFreecamGameplay_address_list[2] + 0x8, readFloat(AczFreecamGameplay_address_list[2] + 0x8) + camera_base_speed)
        elseif (isKeyPressed(VK_J)) then -- [TPS CAM 2] Move left
            writeFloat(AczFreecamGameplay_address_list[2] + 0xC, readFloat(AczFreecamGameplay_address_list[2] + 0xC) + camera_base_speed)
        elseif (isKeyPressed(VK_L)) then -- [TPS CAM 2] Move right
            writeFloat(AczFreecamGameplay_address_list[2] + 0xC, readFloat(AczFreecamGameplay_address_list[2] + 0xC) - camera_base_speed)
        elseif (isKeyPressed(VK_K)) then -- [TPS CAM 2] Move down
            writeFloat(AczFreecamGameplay_address_list[2] + 0x10, readFloat(AczFreecamGameplay_address_list[2] + 0x10) + camera_base_speed)
        elseif (isKeyPressed(VK_I)) then -- [TPS CAM 2] Move up
            writeFloat(AczFreecamGameplay_address_list[2] + 0x10, readFloat(AczFreecamGameplay_address_list[2] + 0x10) - camera_base_speed)
        elseif (isKeyPressed(VK_O)) then -- [TPS CAM 2] Zoom out
            writeFloat(AczFreecamGameplay_address_list[2] + 0x14, readFloat(AczFreecamGameplay_address_list[2] + 0x14) - camera_base_speed)
        elseif (isKeyPressed(VK_U)) then -- [TPS CAM 2] Zoom in
            writeFloat(AczFreecamGameplay_address_list[2] + 0x14, readFloat(AczFreecamGameplay_address_list[2] + 0x14) + camera_base_speed)
        end
        
        -- PYR, zoom, reset
        
        if (isKeyPressed(VK_NUMPAD2)) then -- Pitch up
                writeFloat(AczFreecamGameplay_address_list[2] + 0xF0, readFloat(AczFreecamGameplay_address_list[2] + 0xF0) + rotation_base_speed)
        elseif (isKeyPressed(VK_NUMPAD5)) then -- Pitch down
            writeFloat(AczFreecamGameplay_address_list[2] + 0xF0, readFloat(AczFreecamGameplay_address_list[2] + 0xF0) - rotation_base_speed)
        elseif (isKeyPressed(VK_NUMPAD3)) then -- Yaw left
            writeFloat(AczFreecamGameplay_address_list[2] + 0xF4, readFloat(AczFreecamGameplay_address_list[2] + 0xF4) + rotation_base_speed)
        elseif (isKeyPressed(VK_NUMPAD1)) then -- Yaw right
            writeFloat(AczFreecamGameplay_address_list[2] + 0xF4, readFloat(AczFreecamGameplay_address_list[2] + 0xF4) - rotation_base_speed)
        elseif (isKeyPressed(VK_NUMPAD6)) then -- Roll left
            writeFloat(AczFreecamGameplay_address_list[2] + 0xF8, readFloat(AczFreecamGameplay_address_list[2] + 0xF8) + rotation_base_speed)
        elseif (isKeyPressed(VK_NUMPAD4)) then -- Roll right
            writeFloat(AczFreecamGameplay_address_list[2] + 0xF8, readFloat(AczFreecamGameplay_address_list[2] + 0xF8) - rotation_base_speed)
        elseif (isKeyPressed(VK_ADD)) then -- Increase camera XYZ speed
            camera_base_speed = camera_base_speed + camera_move_rate
        elseif (isKeyPressed(VK_SUBTRACT)) then -- Decrease camera XYZ speed
            camera_base_speed = camera_base_speed - camera_move_rate
        elseif (isKeyPressed(VK_NUMPAD7)) then -- reset XZY/resetXZYCOCKPIT
            restore(AczFreecamGameplay_address_list, AczFreecamGameplay_data_list, true, nil, nil, nil, nil)
        elseif (isKeyPressed(VK_NUMPAD8)) then -- resetXZY2
            restore(AczFreecamGameplay_address_list, AczFreecamGameplay_data_list, nil, true, nil, nil, nil)
        elseif (isKeyPressed(VK_NUMPAD9)) then -- resetPYR
            restore(AczFreecamGameplay_address_list, AczFreecamGameplay_data_list, nil, nil, nil, true, nil)
        elseif (isKeyPressed(VK_SPACE)) then -- Panic key
            restore(AczFreecamGameplay_address_list, AczFreecamGameplay_data_list, true, true, true, true, nil)
            camera_base_speed = 1
        elseif (camera_base_speed <= 0) then -- Reset camera speed value if it goes below 1.0
            camera_base_speed = camera_move_rate
        end
    
    else
        
        -- Self disable script.
        getAddressList().getMemoryRecordByDescription("Gameplay").Active = false
    
    end
    
    return

end

-- Cockpit camera freecam
function checkKeys_viewCam2(timer)
        
    -- Check if PCSX2 is up and running. if not, disable script.
    
    if readInteger(AczFreecamGameplay_pcsx2_id_ram_start[2]) ~= nil then
    
        if (isKeyPressed(VK_A)) then   -- [COCKPIT CAM] Move left
            writeFloat(AczFreecamGameplay_address_list[2] + 0x18, readFloat(AczFreecamGameplay_address_list[2] + 0x18) - camera_base_speed)
        elseif (isKeyPressed(VK_D)) then -- [COCKPIT CAM] Move right
            writeFloat(AczFreecamGameplay_address_list[2] + 0x18, readFloat(AczFreecamGameplay_address_list[2] + 0x18) + camera_base_speed)
        elseif (isKeyPressed(VK_Q)) then -- [COCKPIT CAM] Move down
            writeFloat(AczFreecamGameplay_address_list[2] + 0x1C, readFloat(AczFreecamGameplay_address_list[2] + 0x1C) - camera_base_speed)
        elseif (isKeyPressed(VK_E)) then -- [COCKPIT CAM] Move up
            writeFloat(AczFreecamGameplay_address_list[2] + 0x1C, readFloat(AczFreecamGameplay_address_list[2] + 0x1C) + camera_base_speed)
        elseif (isKeyPressed(VK_S)) then -- [COCKPIT CAM] Move backwards
            writeFloat(AczFreecamGameplay_address_list[2] + 0x20, readFloat(AczFreecamGameplay_address_list[2] + 0x20) + camera_base_speed)
        elseif (isKeyPressed(VK_W)) then -- [COCKPIT CAM] Move forward
            writeFloat(AczFreecamGameplay_address_list[2] + 0x20, readFloat(AczFreecamGameplay_address_list[2] + 0x20) - camera_base_speed)
        end
        
        -- PYR, zoom, reset
        
        if (isKeyPressed(VK_NUMPAD2)) then -- Pitch up
                writeFloat(AczFreecamGameplay_address_list[2] + 0xF0, readFloat(AczFreecamGameplay_address_list[2] + 0xF0) + rotation_base_speed)
        elseif (isKeyPressed(VK_NUMPAD5)) then -- Pitch down
            writeFloat(AczFreecamGameplay_address_list[2] + 0xF0, readFloat(AczFreecamGameplay_address_list[2] + 0xF0) - rotation_base_speed)
        elseif (isKeyPressed(VK_NUMPAD3)) then -- Yaw left
            writeFloat(AczFreecamGameplay_address_list[2] + 0xF4, readFloat(AczFreecamGameplay_address_list[2] + 0xF4) + rotation_base_speed)
        elseif (isKeyPressed(VK_NUMPAD1)) then -- Yaw right
            writeFloat(AczFreecamGameplay_address_list[2] + 0xF4, readFloat(AczFreecamGameplay_address_list[2] + 0xF4) - rotation_base_speed)
        elseif (isKeyPressed(VK_NUMPAD6)) then -- Roll left
            writeFloat(AczFreecamGameplay_address_list[2] + 0xF8, readFloat(AczFreecamGameplay_address_list[2] + 0xF8) + rotation_base_speed)
        elseif (isKeyPressed(VK_NUMPAD4)) then -- Roll right
            writeFloat(AczFreecamGameplay_address_list[2] + 0xF8, readFloat(AczFreecamGameplay_address_list[2] + 0xF8) - rotation_base_speed)
        elseif (isKeyPressed(VK_ADD)) then -- Increase camera XYZ speed
            camera_base_speed = camera_base_speed + camera_move_rate
        elseif (isKeyPressed(VK_SUBTRACT)) then -- Decrease camera XYZ speed
            camera_base_speed = camera_base_speed - camera_move_rate
        elseif (isKeyPressed(VK_NUMPAD7)) then -- reset XZY COCKPIT
            restore(AczFreecamGameplay_address_list, AczFreecamGameplay_data_list, nil, nil, true, nil, nil)
        elseif (isKeyPressed(VK_NUMPAD9)) then -- resetPYR
            restore(AczFreecamGameplay_address_list, AczFreecamGameplay_data_list, nil, nil, nil, true, nil)
        elseif (isKeyPressed(VK_SPACE)) then -- Panic key
            restore(AczFreecamGameplay_address_list, AczFreecamGameplay_data_list, true, true, true, true, nil)
            camera_base_speed = 1
        elseif (camera_base_speed <= 0) then -- Reset camera speed value if it goes below 1.0
            camera_base_speed = camera_move_rate
        end
    
    else
        
        -- Self disable script.
        getAddressList().getMemoryRecordByDescription("Gameplay").Active = false
    
    end
    
    return

end

------------------+
---- [TABLES] ----+
------------------+

local tbl = {}
rightStickAnalog_address = {}
acz_gameplay_aob_address_list = {}
AczFreecamGameplay_address_list = {}
AczFreecamGameplay_data_list = {}

local bytearrays_to_search = {
"?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? B0 C5 3C 00 ?? 01 00 ??",
"00 00 ?? 44 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 ?? ?? ?? 00 00 00 00 00 02 C0 01 00 00 80 3F FF FF 7F 4B 00 00 00 00 00 02 C0 01 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 3F ?? ?? ?? 43 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 00 00 00 00 00 00 00 C5 00 00 00 C5 ?? ?? ?? ?? 00 00 80 BF 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 ?? ?? ?? 3F 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? 80 BF 00 00 80 BF 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 45 00 00 00 45 CD CC ?? ?? ?? ?? ?? 3F 03 00 00 00 ?? ?? ?? ?? 01 00 00 ?? ?? ?? ?? ?? 00 00 00 15 00 01 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 ?? 44 00 00 ?? ??"
}

-----------------+
---- [CHECK] ----+
-----------------+

-- Check if any of the "HANGAR", "ADJUST THIRD PERSON CAMERA DISTANCE" or "FREE MOVEMENT MODE" scripts are active. If false continue with the next check.
if (not IsAczCamAdjustZEnabled) and (not IsAczFreecamGameplayEnabled) and (not IsAczFreeMoveEnabled) then
    
    -- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
    -- Set the working RAM region ranges based on emulator version.
    AczFreecamGameplay_pcsx2_id_ram_start = pcsx2_version_check()
    
    if (AczFreecamGameplay_pcsx2_id_ram_start[3] == nil) then
    
        -- Check if the emulator has the right game loaded.
        local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x300000, AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)
        
        if #SLUS_21346_check ~= 0 then
            
            -- Check if the player is currently in a mission.
            if (readBytes(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then
                
                -- Check if the player is NOT in a multiplayer match.
                if readBytes(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x3ACEA0, 1) == 13 then
                    
                    -- Check if the player is NOT taking off, landing, in a pre-rendered cutscene or has the game paused.
                    
                    -- if value_exists({3, 15, 23}, readBytes(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x76587C, 1)) and readByte(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x7651E8) == 4 then // Since the script no longer uses assembly to disable the camera's opcodes then there shouldnt be any harm in letting the player enable the script while in the pause state.
                    
                    if value_exists({3, 15, 23}, readBytes(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x76587C, 1)) then
                        
                        -- Pause app and look for the address containing the "right-stick analog" byte flag.
                        pause(getOpenedProcessID())
                        rightStickAnalog_address = memscan_func(soExactValue, vtByteArray, nil, "3C 0? 0? 0? ?? ?? ?? ?? ?? 0? 0? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 FF FF FF FF FF FF FF FF 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ??", nil, AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x800000, AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x1F00000, "", 2, "C", true, nil, nil, nil)
                        
                        -- // 8 bytes long
                        -- 3C 0? 0? 0? ?? ?? FF FF
                        -- // 144 bytes long
                        -- 3C 0? 0? 0? ?? ?? ?? ?? ?? 0? 0? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 FF FF FF FF FF FF FF FF 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ??

                        if #rightStickAnalog_address ~= 0 then
                        
                            -- Pause the game and look for the bytearrays needed by the script.
                            for i = 1, #bytearrays_to_search do
                            
                                local found_list = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[i], nil, AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x800000, AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x1F00000, "", 1, "4", true, nil, nil, nil)
                                tbl[#tbl + 1] = found_list[1]
                            
                            end
                        
                            -- If the search function returned the right amount of results then proceed to disable the camera's code
                            -- and continue with the rest of the script.
                            -- Else clean AA and unpause the game.
                        
                            if #tbl == 2 then
                                
                                -- Search for the address containing our camera's XZY coordinate opcode.
                                -- Change search values according to the emulator version attached.
                        
                                if AczFreecamGameplay_pcsx2_id_ram_start[1] == 2 then
                            
                                    local temp = memscan_func(soExactValue, vtByteArray, nil, "89 E9 81 C1 90 00 00 00 83 E1 F0 0F 29 05 ?? ?? ?? ?? 0F 28 C8 89 C8 C1 E8 0C 4C 8D 05 ?? ?? ?? F? 49 8B 04 C0 48 01 C1 78 05 0F 29 09 EB 05 E8 ?? ?? ?? FF 48 8B 0D ?? ?? ?? ?? 83 E1 F0 89 C8 C1 E8 0C 4C 8D 05 ?? ?? ?? F? 49 8B 04 C0 48 01 C1 78 05 0F 28 01 EB 05 E8 ?? ?? ?? FF 8B 0D ?? ?? ?? ?? 83 E1 F0 0F 29 05 ?? ?? ?? ?? 0F 28 C8 89 C8 C1 E8 0C 4C 8D 05 ?? ?? ?? F? 49 8B 04 C0 48 01 C1 78 05 0F 29 09 EB 05 E8 ?? ?? ?? FF 8B 0D ?? ?? ?? ?? 81 C1 4E 01 00 00 89 C8 C1 E8 0C 4C 8D 05 ??", nil, AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x9B00000, AczFreecamGameplay_pcsx2_id_ram_start[2] + 0xA300000, "", 0, "", true, nil, nil, nil)
                            
                                    if #temp ~= 0 then
                                
                                        for i = 1, #temp do
                                
                                            acz_gameplay_aob_address_list[#acz_gameplay_aob_address_list + 1] = temp[i] + 0x85
                                
                                        end
                                        
                                        p_ci(0x05, true)                                
                                        IsAczFreecamGameplayEnabled = true
                                        unpause(getOpenedProcessID())
                                
                                    else
                                
                                        if #temp == 0 or next(temp) == nil then
                                    
                                            showMessage("<< Unable to activate this script (acz_gameplay_aob search returned nil). >>")
                                            unpause(getOpenedProcessID())
                                
                                        elseif #temp > 1 then
                                    
                                            showMessage("<< Unable to activate this script (acz_gameplay_aob search returned more than a result). >>")
                                            unpause(getOpenedProcessID())
                                
                                        end
                            
                                    end
                    
                                else
                                
                                -- For PCSX2 1.6
                                -- Same as above, but different AoBs and addresses/ranges.
                                
                                    local temp = memscan_func(soExactValue, vtByteArray, nil, "0F 28 32 0F 29 31 BA ?0 ?? ?? 0? 8B 0D ?0 A? ?? 0? 83 C1 60 83 E1 F0 89 C8 C1 E8 0C 8B 04 85 30 ?0 ?? ?? BB ?? ?? ?? 30 01 C1 0F 88 ?? ?? ?? D? 0F 28 39 0F 29 3A BA ?0 ?? ?? 0? 8B 0D ?0 A? ?? 0? 81 C1 90 00 00 00 83 E1 F0 89 C8 C1 E8 0C 8B 04 85 30 ?0 ?? ?? BB ?? ?? ?? 30 01 C1 0F 88 ?? ?? ?? D? 0F 28 02 0F 29 01 BA ?0 ?? ?? 0? 8B 0D ?0 ?? ?? 0? 83 E1 F0 89 C8 C1 E8 0C 8B 04 85 30 ?0 ?? ?? BB ?? ?? ?? 30 01 C1 0F 88 ?? ?? ?? D? 0F 28 09 0F 29 0A BA ?0 ?? ?? 0? 8B 0D ?0 ?? ?? 0? 83 E1 F0 89 C8 C1 E8 0C 8B 04 85 30 ?0 ?? ?? BB ?? ?? ?? 30 01 C1 0F 88 ?? ?? ?? D? 0F 28 12 0F 29 11 8B 0D ?0 ?? ?? 0? 81 C1 4E 01 00 00 89 C8 C1 E8 0C 8B 04 85 30 ?0 ?? ?? BB ?? ?? ?? 30 01 C1 0F 88 ?? ?? ?? D? 0F B6 01", nil, AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x10000000, AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x20000000, "", 0, "", true, nil, nil, nil)
                                    
                                    if #temp ~= 0 then
                                        
                                        acz_gameplay_aob_address_list[#acz_gameplay_aob_address_list + 1] = temp[1] + 0xC0
                                        
                                        p_ci(0x05, true)
                                        IsAczFreecamGameplayEnabled = true
                                        unpause(getOpenedProcessID())
                                    
                                    else
                                        
                                        if #temp == 0 or next(temp) == nil then
                                            
                                            showMessage("<< Unable to activate this script (acz_gameplay_aob search returned nil). >>")
                                            unpause(getOpenedProcessID())
                                        
                                        elseif #temp > 1 then
                                            
                                            showMessage("<< Unable to activate this script (acz_gameplay_aob search returned more than a result). >>")
                                            unpause(getOpenedProcessID())
                                        
                                        end
                                    
                                    end
                        
                                end
                            
                            else
                            
                                showMessage("<< Unable to activate this script (tbl returned error). >>")
                                unpause(getOpenedProcessID())
                            
                            end
                        
                        else
                            
                            showMessage("<< Unable to activate this script (rightStickAnalog returned error). >>")
                            unpause(getOpenedProcessID())
                        
                        end
                        
                    else
                        
                        -- showMessage("<< The script won't work while paused, during cutscenes or special sequences. >>")
                        
                        showMessage("<< The script won't work while during cutscenes or special sequences. >>")
                        
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
        
        if AczFreecamGameplay_pcsx2_id_ram_start[3] == 1 then
            
            showMessage("<< Attach this table to a running instance of PCSX2 first. >>")
            
        elseif AczFreecamGameplay_pcsx2_id_ram_start[3] == 2 then
            
            showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")
            
        elseif AczFreecamGameplay_pcsx2_id_ram_start[3] == 3 then
            
            showMessage("<< PCSX2 has no ISO file loaded. >>")
            
        end
        
    end
    
else
    
    showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [HANGAR]".."\n- [ADJUST THIRD PERSON CAMERA DISTANCE]".."\n- [FREE MOVEMENT MODE]".."\n".."\nDeactivate them before activating this one first. >>")
    
end

----------------+
---- [MAIN] ----+
----------------+

if IsAczFreecamGameplayEnabled then
    
    -- Create a global header to attach the other sub-header and memory records that will be create on script activation.
    AczFreecamGameplay_main_header = create_header("[CAMERA] GAMEPLAY FREECAM", nil, nil)
    
    -- Read "HUD visibility" flag's current value, store it for later use then make the HUD invisible.
    AczFreecamGameplay_address_list[#AczFreecamGameplay_address_list + 1] = tbl[1] + 0x44
    AczFreecamGameplay_data_list[#AczFreecamGameplay_data_list + 1] = readBytes(tbl[1] + 0x44, 1, true)
    writeBytes(tbl[1] + 0x44, 0x00)
    
    -- Create a memory record to display the current value of "HUD visibility" flag.
    create_memory_record(AczFreecamGameplay_pcsx2_id_ram_start[2] + 0x3FFBCF, {0x0}, {vtByte}, {"HUD visibility"}, AczFreecamGameplay_main_header)
    
    -- Disable the code controlling the right-analog stick's input so we can can control the camera.
    for i = 1, #acz_gameplay_aob_address_list do
        
        writeBytes(acz_gameplay_aob_address_list[i], 0x90, 0x90, 0x90)
    
    end
    
    -- //[CAMERA XZY/PYR COORDINATES]//
    -- Set record descriptions and offsets according to current camera view.
    -- Create header and memory records to display the camera's current XYZ coordinates.
    -- Store camera's last XYZ coordinates previous to script activation to use it with the restore function.
    
    local camera_coordinates_header = create_header("Current camera coordinates", AczFreecamGameplay_main_header, true)
    local camera_coordinates_base_address = tbl[2] + 0xB30
    
    if readBytes(rightStickAnalog_address[1] + 0x2, 1) == 1 then
        
        local offset_list = {0x0, 0x4, 0x8, 0xC, 0x10, 0x14, 0xF0, 0xF4, 0xF8}
        local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "X coordinate (anchor)", "Y coordinate (anchor)", "Z coordinate (anchor)", "Pitch", "Yaw", "Roll"}
        local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}
        
        create_memory_record(camera_coordinates_base_address, offset_list, vt_list, description_list, camera_coordinates_header)
    
    elseif readBytes(rightStickAnalog_address[1] + 0x2, 1) == 2 then
        
        local offset_list = {0x18, 0x1C, 0x20, 0xF0, 0xF4, 0xF8}
        local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "Pitch", "Yaw", "Roll"}
        local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}
        
        create_memory_record(camera_coordinates_base_address, offset_list, vt_list, description_list, camera_coordinates_header)
    
    else
    
        create_header("<< The free camera won't work while using the HUD view. >>", camera_coordinates_header, nil)
    
    end
        
    AczFreecamGameplay_address_list[#AczFreecamGameplay_address_list + 1] = camera_coordinates_base_address
    AczFreecamGameplay_data_list[#AczFreecamGameplay_data_list + 1] = readBytes(camera_coordinates_base_address, 36, true)
    
    -- //[HOTKEYS]//
    -- Set base rotation speed.
    -- Before setting it check for the current camera view. HUD, cockpit views as well during landing/takeoff reverse the rotation speed value. Reversing the value will only work with the HUD/cockpit views only.
    -- Set action/movement hotkeys function.
    -- Create and enable timer on script activation.
    -- Camera views values:
    ---- 0 = HUD view
    ---- 1 = Third-person view
    ---- 2 = Cockpit view
    -- Abbreviations:
    ---- TPS: Third-Person Camera
    ---- CAM: Camera
    
    if readBytes(rightStickAnalog_address[1] + 0x2, 1) == 1 then
        
        camera_base_speed = 1.0
        camera_move_rate = 0.5
        rotation_base_speed = 0.1
        
        AczFreecamGameplay_hotkey_Timer = createTimer(nil, true) -- Create timer object
        AczFreecamGameplay_hotkey_Timer.Interval = 50 -- Set tick rate
        AczFreecamGameplay_hotkey_Timer.onTimer = checkKeys_viewCam1 -- Call this function every Nms value set in the ".Interval" parameter.
        AczFreecamGameplay_hotkey_Timer.Enabled = true -- Enable the timer object.
        
    elseif readBytes(rightStickAnalog_address[1] + 0x2, 1) == 2 then
        
        camera_base_speed = 0.1
        camera_move_rate = 0.125
        rotation_base_speed = -0.1
        
        AczFreecamGameplay_hotkey_Timer = createTimer(nil, true) -- Create timer object
        AczFreecamGameplay_hotkey_Timer.Interval = 50 -- Set tick rate
        AczFreecamGameplay_hotkey_Timer.onTimer = checkKeys_viewCam2 -- Call this function every Nms value set in the ".Interval" parameter.
        AczFreecamGameplay_hotkey_Timer.Enabled = true -- Enable the timer object.
        
    end
    
end

[DISABLE]

if syntaxcheck then return end

-- On deactivation, if the script activation was successful then:
---- Destroy hotkey timer
---- Restore modified values
---- Restored modified camera code
---- Clear tables
---- Exit script
-- Otherwise just skip to the next block of code.

   
if IsAczFreecamGameplayEnabled then
    
    if AczFreecamGameplay_hotkey_Timer then
        
        AczFreecamGameplay_hotkey_Timer.Enabled = false
        AczFreecamGameplay_hotkey_Timer.destroy()
        AczFreecamGameplay_hotkey_Timer = nil
        
    end
    
    AczFreecamGameplay_main_header.destroy()
    
    restore(AczFreecamGameplay_address_list, AczFreecamGameplay_data_list, true, true, true, true, true)
    
    p_ci(0x04, false)
    
    camera_base_speed = nil
    camera_move_rate = nil
    rotation_base_speed = nil
    
    acz_gameplay_aob_address_list = nil
    AczFreecamGameplay_address_list = nil
    AczFreecamGameplay_data_list = nil
    
    IsAczFreecamGameplayEnabled = nil

else

    unpause(getOpenedProcessID())

end

AczFreecamGameplay_pcsx2_id_ram_start = nil
rightStickAnalog_address = nil
