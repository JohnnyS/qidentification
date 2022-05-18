-- This file manages the main menu parts of the code. 
-- I separated it here becuase it relies on nh-context and nh-keyboard and you may wish to replace it with your own method, maybe using ESX Menu Default? 

-- The event called by the qtarget to open the menu
RegisterNetEvent('qidentification:requestLicense')
AddEventHandler('qidentification:requestLicense',function()
	lib.registerContext({
		id = 'RequestLicense',
		title = 'Request a License',
		menu = 'requestLicense',
		options = {
			['ID Card'] = {
                description = 'Request a ID Card',
                arrow = true,
                event = 'qidentification:applyForLicense',
                args = {value1 = 'identification', value2 = 500}
            },
			['Drivers License'] = {
                description = 'Request a Drivers License',
                arrow = true,
                event = 'qidentification:applyForLicense',
                args = {value1 = 'drivers_license', value2 = 1500}
            },
			['Firearms License'] = {
                description = 'Request a Firearms License',
                arrow = true,
                event = 'qidentification:applyForLicense',
				args = {value1 = 'firearms_license', value2 = 2500}
            }
		}
	})
	lib.showContext('RequestLicense')
end)


-- the event that handles applying for license
RegisterNetEvent('qidentification:applyForLicense')
AddEventHandler('qidentification:applyForLicense',function(data)
	local identificationData = data.value1
	local identificationDataPrice = data.value2
	local mugshotURL = nil

	if Config.CustomMugshots then 
		local data = exports.ox_inventory:Keyboard('Custom Mugshot URL (Leave blank for default)', {'Direct Image URL (link foto)'})
	
		if data then
			mugshotURL = data[1]
		else
			print('No value was entered into the field!')
		end
	else
		if Config.MugshotsBase64 then
			mugshotURL = exports[Config.MugshotScriptName]:GetMugShotBase64(PlayerPedId(), false)
		else
			local p = promise.new() -- Make sure we wait for the mugshot is created
			exports[Config.MugshotScriptName]:getMugshotUrl(PlayerPedId(), function(url)
				mugshotURL = url
				p:resolve()
			end)
			Citizen.Await(p)		
		end
	end 
	local hasCard = exports.ox_inventory:Search('count', identificationData)
	if identificationData ~= 'identification' then
		if identificationData == 'firearms_license' then identificationData = 'weapon' end
		if identificationData == 'drivers_license' then identificationData = 'drive' end
		ESX.TriggerServerCallback('esx_license:checkLicense', function(hasLicense)
			if hasLicense then
				if identificationData == 'weapon' then identificationData = 'firearms_license'  end
				if identificationData == 'drive' then identificationData = 'drivers_license' end
					
				if hasCard >= 1 then
					exports['t-notify']:Custom({
						style  =  'error',
						duration  =  5000,
						message  =  'You already have an existing card on you.',
						sound  =  true
					})
				else
					TriggerServerEvent('qidentification:server:payForLicense',identificationData,identificationDataPrice,mugshotURL) 
				end
			else
				exports['t-notify']:Custom({
					style  =  'error',
					duration  =  5000,
					message  =  'Missing License, go get it',
					sound  =  true
				})
			end
		end, GetPlayerServerId(PlayerId()), identificationData)
		--
	else
		if hasCard >= 1 then
			exports['t-notify']:Custom({
				style  =  'error',
				duration  =  5000,
				message  =  'You already own a ID card',
				sound  =  true
			})
		else
			TriggerServerEvent('qidentification:server:payForLicense',identificationData,identificationDataPrice,mugshotURL)
		end
	end
end)
