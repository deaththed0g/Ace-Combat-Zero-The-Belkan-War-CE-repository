{$lua}

--[[
================================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - AIRCRAFT/SpW/COLOR RANDOMIZER SCRIPT ====
================================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
Written and best viewed in Notepad ++.
v301124
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

math.randomseed(os.time()) -- Grab seed

------------------+
---- [TABLES] ----+
------------------+

local aircraft_used = {}

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

-- Random number generator function.
local function randomizer()

    local new_aircraft_value = math.random(0, 35)
    local new_spw_value = math.random(0, 2)
    
    -- Initialize a table to store the COLOR (livery) ID of the aircraft.
    new_aircraft_color_value = nil
    
    
    -- Both the F-15C and F-16C have one extra livery than the usual five available for the rest of the
    -- aircraft roster (STANDARD, MERCENARY, SOLDIER, KNIGHT, SPECIAL). These are the PIXY and PJ colors. So if
    -- the number drawn for the aircraft ID is either 5 (F-15C ID's value) or 10 (F-16C's ID value) set the
    -- MAX limit to 5.
    
    if (new_aircraft_value == 5) or (new_aircraft_value == 10) then
    
        new_aircraft_color_value = math.random(0, 5)
        
    else
    
        new_aircraft_color_value = math.random(0, 4)
        
    end
    
    return {new_aircraft_value, new_spw_value, new_aircraft_color}
    
end

local function NotInSortie_function(NotInSortie_timer)
    
    -- Check if PCSX2 is up and running. if not, disable script.
    
    if AczAircraftSpwRandomizer_pcsx2_check[2] ~= nil then

        -- Check if the player is in or out of a sortie by reading a byte at address 0x203AC61C.
        -- If the byte flag is anything other than 0 then it means that the game is currently in a sortie (or loading the assets of it).
        -- This mean that we can proceed with the RNG function.
        
        if (readBytes(AczAircraftSpwRandomizer_pcsx2_check[2] + 0x3AC61C, 1) ~= 0) then
        
            -- Pause the timer that checks if the player is outside of a sortie.
            NotInSortie_timer.enabled = false
            
            -- Pause the emulator. This is done to give the script to check for existent items in the table.
            pause(getOpenedProcessID())
            
            -- In a infinite loop generate random numbers then check if they exist in a table.
            -- Break the loop if the number obtained is NOT in said table.
            -- Add the unique number to that table.
            new_values = nil
            
            while true do
            
                new_values = randomizer()
                
                if not value_exists(aircraft_used, new_values[1]) then
                
                    aircraft_used[#aircraft_used + 1] = new_values[1]
                    
                    break
                    
                end
                
            end
            
            -- Write the drawn values to their respective addresses.
            
            -- FREE MISSION/FLIGHT mode
            writeShortInteger(AczAircraftSpwRandomizer_pcsx2_check[2] + 0x3B9A40, new_values[1]) -- aircraft ID
            writeShortInteger(AczAircraftSpwRandomizer_pcsx2_check[2] + 0x3B9A50, new_values[2]) -- aircraft SpW ID
            writeShortInteger(AczAircraftSpwRandomizer_pcsx2_check[2] + 0x3B9A48, new_values[3]) -- aircraft COLOR ID
            
            -- CAMPAIGN/STORY mode
            writeShortInteger(AczAircraftSpwRandomizer_pcsx2_check[2] + 0x3B3AAC, new_values[1]) -- aircraft ID
            writeShortInteger(AczAircraftSpwRandomizer_pcsx2_check[2] + 0x3B3ABC, new_values[2]) -- aircraft SpW ID
            writeShortInteger(AczAircraftSpwRandomizer_pcsx2_check[2] + 0x3B3AB4, new_values[3]) -- aircraft COLOR ID
            
            -- If the "aircraft_used" table has 36 numbers stored in it then clear it and add the last drawn number.
            if #aircraft_used == 36 then
            
                aircraft_used = nil
                aircraft_used[#aircraft_used + 1] = new_values[1]
                
            end
            
            -- Unpause the emulator once everything is done.
            unpause(getOpenedProcessID())
            
            local function InSortie_function(InSortie_timer)
                
                if readInteger(AczAircraftSpwRandomizer_pcsx2_check[2]) ~= nil then
            
                    -- Every 1000ms check if the player is currently in a sortie.
                    -- The check will loop as long the value in the address AczAircraftSpwRandomizer_pcsx2_check[2] + 0x3AC61C is not equal to 0.
                    -- If the value becomes 0 again then exit this function and resume the "isPlayerNotInSortieCheck_tick" timer.
                    
                    if (readBytes(AczAircraftSpwRandomizer_pcsx2_check[2] + 0x3AC61C, 1) == 0) then
                    
                        NotInSortie_timer.enabled = true
                        InSortie.destroy()
                        InSortie = nil
                        
                    end
                
                else
                    
                    -- Self disable script.
                    getAddressList().getMemoryRecordByDescription("Aircraft/SpW/COLOR randomizer").Active = false
                
                end
                
                return
                
            end
            
            -- Initialize a timer function to check every 1000ms if the player IS in a sortie.
            InSortie = createTimer(nil, true)
            InSortie.Interval = 1000
            InSortie.OnTimer = InSortie_function
            
        end
    
    else
        
        -- Self disable script.
        getAddressList().getMemoryRecordByDescription("Aircraft/SpW/COLOR randomizer").Active = false
        
    end
    
    return
    
end


-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.

AczAircraftSpwRandomizer_pcsx2_check = pcsx2_version_check()

if (AczAircraftSpwRandomizer_pcsx2_check[3] == nil) then

    -- Check if the emulator has the right game loaded.
    local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, AczAircraftSpwRandomizer_pcsx2_check[2] + 0x300000, AczAircraftSpwRandomizer_pcsx2_check[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)
    
    if #SLUS_21346_check ~= 0 then
    
        -- Check if the player is in a stage compatible with this script.
        -- If true then proceed with the rest of the script.
        stage_id = readSmallInteger(AczAircraftSpwRandomizer_pcsx2_check[2] + 0x3BF740) -- Read the current mission ID value.
        
        if (stage_id >= 0 and stage_id <= 30) or (stage_id >= 78 and stage_id <= 108) then
        
            IsAczAircraftSpwRandomizerEnabled = true
            
        else
        
            showMessage("<< This mission or mode is not compatible with this script. >>")
            
        end
        
    else
    
        showMessage("<< This script is not compatible with the game you're currently emulating. >>")
        
    end
    
else

    if AczAircraftSpwRandomizer_pcsx2_check[3] == 1 then
    
        showMessage("<< Attach this table to a running instance of PCSX2 first. >>")
        
    elseif AczAircraftSpwRandomizer_pcsx2_check[3] == 2 then
    
        showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")
        
    elseif AczAircraftSpwRandomizer_pcsx2_check[3] == 3 then
    
        showMessage("<< PCSX2 has no ISO file loaded. >>")
        
    end
    
end

----------------+
---- [MAIN] ----+
----------------+

if IsAczAircraftSpwRandomizerEnabled then

    -- Initialize a timer function to check every 1000ms if the player is NOT in a sortie.
    NotInSortie = createTimer(nil, true)
    NotInSortie.Interval = 1000
    NotInSortie.OnTimer = NotInSortie_function
    
end

[DISABLE]

if syntaxcheck then return end

-- On exit destroy any timer object created so the randomizer will stop.

if NotInSortie or InSortie then

    if InSortie then

        InSortie.destroy()
        InSortie = nil
    
    end

    NotInSortie.destroy()
    NotInSortie = nil
    
end

IsAczAircraftSpwRandomizerEnabled = nil