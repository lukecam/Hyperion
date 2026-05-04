--// Originally written by Merely
--// Edited by GitHub@LolloDev5123 and Irreflexive
--// GitHub@Expertcoderz was here to make things look better
--// GitHub@annoynumus was here to patch the return teleport

return function(Vargs, GetEnv)
	local server = Vargs.Server
	local service = Vargs.Service

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	local TeleportService: TeleportService = service.TeleportService
	local Players: Players = service.Players
	local teleportedPlayers = setmetatable({}, {__mode = "k"})
	local isReservedServer = #game.PrivateServerId > 0 and game.PrivateServerOwnerId == 0

	local PARAMETER_NAME = "HYPERION_SOFTSHUTDOWN"
	local PARAMETER_2_NAME = "HYPERION_SHUTDOWN_REJOIN"
	local MAX_RETRIES = 4
	local RETRY_WAIT = 1.5

	TeleportService.TeleportInitFailed:Connect(function(player, result, message, placeId, options)
		if teleportedPlayers[player] and placeId == game.PlaceId and not table.find({Enum.TeleportResult.Success, Enum.TeleportResult.IsTeleporting}, result) then
			if teleportedPlayers[player] < MAX_RETRIES then
				task.wait(RETRY_WAIT * teleportedPlayers[player])
				teleportedPlayers[player] += 1
				Logs:AddLog("Script", `Failed to teleport {player.Name} {isReservedServer and "back to the main game" or "to a temporary softshutdown server"} due to {result.Name}. Retrying... Details: {message}`)
				Functions.Notification("Teleport failed", `SoftShutdown failed to teleport {isReservedServer and "back to the main game" or "to a temporary softshutdown server"}. Retrying...`, {player}, 10, "MatIcon://Warning")
				TeleportService:Teleport(game.PlaceId, player, {[PARAMETER_2_NAME] = true})
			else
				Logs:AddLog("Script", `Failed to teleport {player.Name} {isReservedServer and "back to the main game" or "to a temporary softshutdown server"} due to {result.Name}. Details: {message}`)
				Logs:AddLog("Errors", `Failed to teleport {player.Name} {isReservedServer and "back to the main game" or "to a temporary softshutdown server"} to {result.Name}. Details: {message}`)
				Functions.Notification("Teleport failed", `SoftShutdown failed to teleport {isReservedServer and "back to the main game" or "to a temporary softshutdown server"}. Details {message}`, {player}, 35, "MatIcon://Error")
			end
		end
	end)

	if isReservedServer then
		task.defer(function()
			local waitTime = 5
			local playersToTeleport = {}

			local jobid
			local startTask, TeleportTask = service.Threads.NewTask("Teleport Players", function()
				jobid = TeleportService:TeleportPartyAsync(game.PlaceId, playersToTeleport, {[PARAMETER_2_NAME] = true})
				Logs:AddLog("Script", `Teleported {#playersToTeleport} players back to the main game`)
			end)

			local function sendMessage(player)
				task.defer(function()
					repeat task.wait(0.25) until not player or not player.Parent or teleportedPlayers[player] or Remote.Clients[tostring(player.UserId)] and Remote.Clients[tostring(player.UserId)].FinishedLoading
					Functions.Message("Hyperion", Settings.SystemTitle, "Teleporting back to main game...", "MatIcon://Hourglass empty", {player}, false, 1000)
				end)
			end

			local function teleport(player)
				local joindata = player:GetJoinData()
				local data = type(joindata) == "table" and joindata.TeleportData

				if type(data) == "table" and data[PARAMETER_NAME] then
					sendMessage(player)
					task.wait(waitTime + 5)
					waitTime /= 2

					Logs:AddLog("Script", `Teleporting {player.Name} back to the main game`)
					teleportedPlayers[player] = 1
					table.insert(playersToTeleport, player)
				end
			end

			if #service.Players:GetPlayers() == 0 then
				service.Players.PlayerAdded:Wait()
			end

			service.Players.PlayerAdded:Connect(function(player)
				local joindata = player:GetJoinData()
				local data = type(joindata) == "table" and joindata.TeleportData

				if type(data) == "table" and data[PARAMETER_NAME] then
					if TeleportTask.Running or TeleportTask.R_Status == "Idle" then
						TeleportTask.Finished:wait()
					end

					if not jobid then
						repeat task.wait(1) until jobid ~= nil
					end

					if not player or not player.Parent then
						return
					end

					TeleportService:TeleportToPlaceInstance(game.PlaceId, jobid, player, "", {[PARAMETER_2_NAME] = true})
				end
			end)

			for _, player in service.Players:GetPlayers() do
				teleport(player)
			end

			if #playersToTeleport > 0 then
				Logs:AddLog("Script", `Teleporting {#playersToTeleport} players back to the main game`)
				task.wait(1)
				startTask()
			end
		end)
	end

	Remote.Terminal.Commands.SoftShutdown = {
		Usage = "restart";
		Command = "restart";
		Arguments = 0;
		Description = "Restart the server, placing all of the players in a reserved server and teleporting each of them to the new server";
		Function = function(p,args,data)
			if service.RunService:IsStudio() and not server.Core.DebugMode then return end
			if #Players:GetPlayers() == 0 then return end

			local newserver = TeleportService:ReserveServer(game.PlaceId)
			Functions.Message("Hyperion", Settings.SystemTitle, "The server is restarting, please wait...", "MatIcon://Hourglass empty", service.GetPlayers(), false, 1000)
		
			task.wait(2)

			for _, v in Players:GetPlayers() do
				teleportedPlayers[v] = 1
			end

			Logs:AddLog("Script", `Teleporting {#Players:GetPlayers()} players to a temporary softshutdown server`)
			TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, Players:GetPlayers(), "", {[PARAMETER_NAME] = true})
			Players.PlayerAdded:Connect(function(player)
				Logs:AddLog("Script", `Teleporting {player.Name} to a temporary softshutdown server`)
				teleportedPlayers[player] = 1
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[PARAMETER_NAME] = true})
			end)
			task.delay(60, function()
				Variables.ServerLock = true
			end)

			while #Players:GetPlayers() > 0 do
				Players.PlayerRemoving:Wait()
			end
		end
	}

	Logs:AddLog("Script", "Soft Shutdown Module Loaded");
end
