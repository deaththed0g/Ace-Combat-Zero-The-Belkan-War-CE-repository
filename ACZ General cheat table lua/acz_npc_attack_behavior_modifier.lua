{$lua}

--[[
===============================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - NPC ATTACK BEHAVIOR MODIFIER SCRIPT ====
===============================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v261124
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

------------------+
---- [TABLES] ----+
------------------+

AczNpcAttack_data_list = {}
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

AczNpcAttack_pcsx2_id_ram_start = pcsx2_version_check()

if (AczNpcAttack_pcsx2_id_ram_start[3] == nil) then

	-- Check if the emulator has the right game loaded.
	local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, AczNpcAttack_pcsx2_id_ram_start[2] + 0x300000, AczNpcAttack_pcsx2_id_ram_start[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)

	if #SLUS_21346_check ~= 0 then

		-- Check if the player is currently in a mission.
		if (readBytes(AczNpcAttack_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then

			-- Check if the player is NOT in a multiplayer match.
			if readBytes(AczNpcAttack_pcsx2_id_ram_start[2] + 0x3ACEA0, 1) == 13 then

				-- Look for the bytearray needed by the script.
				-- If the search function returned the right amount of results then proceed with the rest of the script.
				tbl = memscan_func(soExactValue, vtByteArray, nil, "18 00 00 00 70 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 10 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 05 00 00 00 20 00 00 00", nil, AczNpcAttack_pcsx2_id_ram_start[2] + 0x700000, AczNpcAttack_pcsx2_id_ram_start[2] + 0x1f00000, "", 2, "0", true, nil, nil, nil)

				if #tbl ~= nil and #tbl == 1  then

					IsAczNpcAttackEnabled = true

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

	if AczNpcAttack_pcsx2_id_ram_start[3] == 1 then

		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

	elseif AczNpcAttack_pcsx2_id_ram_start[3] == 2 then

		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

	elseif AczNpcAttack_pcsx2_id_ram_start[3] == 3 then

		showMessage("<< PCSX2 has no ISO file loaded. >>")

	end

end

----------------+
---- [MAIN] ----+
----------------+

if IsAczNpcAttackEnabled then

	-- Read the current mission's entity index list.
	-- Modify engagement and attack parameters for every NPC entity found in the current mission.
	-- Read and back up data for restoration later.

    local main_file_toc = retrieve_toc(tbl[1])
    local mission_file_toc = retrieve_toc(main_file_toc[1] + 0x20)
    local entity_file_toc = retrieve_toc(mission_file_toc[1] + 0x20)
	
    for i = 1, #entity_file_toc do
	
        if i ~= 1 then
		
            local current_entities_group = retrieve_toc(entity_file_toc[i] + 0x50)
			
            for i = 1, #current_entities_group do
			
                if readBytes(current_entities_group[i], 4) ~= 0 then
				
                    if i == 1 then
					
                        local current_script_toc = retrieve_toc(current_entities_group[1] + 0x50)
						
                        for i = 1, #current_script_toc do
						
							-- Engagement range
                            if readInteger(current_script_toc[i] + 0x10) == 2 then
							
                                AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_script_toc[i] + 0x60
                                AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_script_toc[i] + 0x60, 4, true)
                                writeFloat(current_script_toc[i] + 0x60, 12800000.0)
								
                            end
							
                        end
						
                    else
					
                        local current_entity_properties = retrieve_toc(current_entities_group[i] + 0xE0)
						
						-- Attack flags?
                        if readInteger(current_entity_properties[3]) ~= 0 then
						
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_entity_properties[3] + 0x10
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_entity_properties[3] + 0x10, 16, true)
							
                            for i = 1, 16 do
							
                                writeBytes(current_entity_properties[3] + 0x10 + ((i * 1) - 1), 100)
								
                            end
							
                        end
						
                        -- Gun attack parameters
                        if readInteger(current_entity_properties[4]) ~= 0 then
						
                            -- Attack interval
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_entity_properties[4] + 0x30
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_entity_properties[4] + 0x30, 4, true)
                            writeFloat(current_entity_properties[4] + 0x30, 3)
							
                            -- Fire rate
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_entity_properties[4] + 0x34
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_entity_properties[4] + 0x34, 4, true)
                            writeFloat(current_entity_properties[4] + 0x34, 0.1)
							
                            -- Attack duration
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_entity_properties[4] + 0x38
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_entity_properties[4] + 0x38, 4, true)
                            writeFloat(current_entity_properties[4] + 0x38, 1.5)
                            
							-- Fire spread
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_entity_properties[4] + 0x40
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_entity_properties[4] + 0x40, 4, true)
                            writeFloat(current_entity_properties[4] + 0x40, 0.3)
                            
							-- Damage per round
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_entity_properties[4] + 0x59
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_entity_properties[4] + 0x59, 1, true)
                            writeBytes(current_entity_properties[4] + 0x59,  12)
							
                        end
						
                        -- Missile attack parameters
                        if readInteger(current_entity_properties[5]) ~= 0 then
						
                            -- Missile attack interval
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_entity_properties[5] + 0x2C
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_entity_properties[5] + 0x2C, 4, true)
                            writeFloat(current_entity_properties[5] + 0x2C, 0.5)
							
                            -- Missile attack duration
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_entity_properties[5] + 0x30
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_entity_properties[5] + 0x30, 4, true)
                            writeFloat(current_entity_properties[5] + 0x30, 14.0)
							
                            -- Missile launch rate
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_entity_properties[5] + 0x34
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_entity_properties[5] + 0x34, 4, true)
                            writeFloat(current_entity_properties[5] + 0x34, 4.0)
                            
							-- Missile accuracy
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = current_entity_properties[5] + 0x3C
                            AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(current_entity_properties[5] + 0x3C, 4, true)
                            writeFloat(current_entity_properties[5] + 0x3C, 40.0)
							
                        end
						
                    end
					
                end
				
            end
			
        end
		
    end
	
	-- //[ALTITUDE LIMITS]
	-- Remove altitude limits for all NPCs, including wingmen.
	-- TODO
	---- I should find a way to read the terrain 3D model data and set its highest point as the minimum altitude limit value. Not all maps have the same elevation.
	
	local AczNpcAttack_altitueLimits = memscan_func(soExactValue, vtByteArray, nil, "CC CC 4C 42", nil, AczNpcAttack_pcsx2_id_ram_start[2] + 0x800000, AczNpcAttack_pcsx2_id_ram_start[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
	
	for i = 1, #AczNpcAttack_altitueLimits do
	
		AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = AczNpcAttack_altitueLimits[i] - 0x18C
		AczNpcAttack_data_list[#AczNpcAttack_data_list + 1] = readBytes(AczNpcAttack_altitueLimits[i] - 0x18C, 4, true)
		
		-- Filter garbage data/non entities
		if readFloat(AczNpcAttack_altitueLimits[i] - 0x18C) > 1.0 or AczNpcAttack_altitueLimits[i] - 0x18C < 51200.0 then
		
			writeFloat(AczNpcAttack_altitueLimits[i] - 0x18C, 1000.0)
			
		end
		
	end
	
end

[DISABLE]

if syntaxcheck then return end

-- If the script is disabled while in a mission then restore the modified values and clear tables.
-- Else just clear tables before exiting the script.

if IsAczNpcAttackEnabled then

    if (readBytes(AczNpcAttack_pcsx2_id_ram_start[2] + 0x3FFD1C, 1) ~= 255) then
	
        for i = 1, #AczNpcAttack_data_list, 2 do
		
            writeBytes(AczNpcAttack_data_list[i], AczNpcAttack_data_list[i + 1])
			
        end
		
    end
	
	AczNpcAttack_pcsx2_id_ram_start = nil
	AczNpcAttack_data_list = nil
	
	IsAczNpcAttackEnabled = nil
	
end