return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	local Routine = env.Routine

	return {
		ViewCommands = {
			Prefix = Settings.Prefix;
			Commands = {"cmds", "commands"};
			Args = {};
			Description = "Lists all available commands";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local tab = {}
				local cmdCount = 0

				for _, cmd in Admin.SearchCommands(plr, "all") do
					local cmdAliases = table.create(#cmd.Commands)

					if cmd.Hidden or cmd.Disabled then
						continue
					end

					for _,alias in cmd.Commands do
						if #cmdAliases >= 6 and (#cmd.Commands - #cmdAliases) ~= 0 then
							table.insert(cmdAliases, `and {#cmd.Commands - #cmdAliases} more...`)
							break
						end

						table.insert(cmdAliases, alias)
					end

					table.remove(cmdAliases, 1)

					local permissionDesc = Admin.FormatCommandAdminLevel(cmd)
					table.insert(tab, {
						Text = Admin.FormatCommand(cmd),
						Desc = `[{permissionDesc}] {if #cmdAliases >= 1 then `\nAliases: {table.concat(cmdAliases, ", ")}` else ""} \n\n{cmd.Description or "(No description provided)"}`,
						Filter = permissionDesc
					})
					cmdCount += 1
				end

				for alias, command in Core.GetPlayer(plr).Aliases or {} do
					table.insert(tab, {
						Text = alias,
						Desc = `[User Alias] {command}`,
						Filter = command
					})
					cmdCount += 1
				end

				table.sort(tab, function(a, b) return a.Text < b.Text end)

				Remote.MakeGui(plr, "List", {
					Title = "Commands";
					Table = tab;
					TitleButtons = {
						{
							Text = "?";
							OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.PlayerPrefix}usage')`)
						}
					};
				})
			end
		};

		CommandInfo = {
			Prefix = Settings.Prefix;
			Commands = {"commandinfo", "commanddetails"};
			Args = {"command"};
			Description = "Shows you information about a specific command";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				assert(args[1], "No command provided")

				local cmd, ind
				for i, v in Admin.SearchCommands(plr, "all") do
					for _, p in v.Commands do
						if (if type(v.Prefix) == "table" then v.Prefix[1] else v.Prefix or "")..string.lower(p) == string.lower(args[1]) then
							cmd, ind = v, i
							break
						end
					end
					if ind then break end
				end
				assert(cmd, `Command '{args[1]}' is either not found or beyond your permission level`)

				local SanitizeXML = service.SanitizeXML

				local cmdArgs = Admin.FormatCommandArguments(cmd)

				local cmdAttribs = {}
				for _, key in {"Disabled", "Fun", "Hidden", "NoStudio", "NonChattable", "CrossServerDenied"} do
					if cmd[key] then
						table.insert(cmdAttribs, key)
					end
				end

				Remote.MakeGui(plr, "List", {
					Title = "Command Info";
					Icon = server.MatIcons.Info;
					Table = {
						{Text = `<b>Prefix:</b> {if type(cmd.Prefix) =="table" then table.concat(cmd.Prefix, ", ") else cmd.Prefix}`, Desc = "Prefix used to run the command"},
						{Text = `<b>Commands:</b> {SanitizeXML(table.concat(cmd.Commands, ", "))}`, Desc = "Valid default aliases for the command"},
						{Text = `<b>Arguments:</b> {if cmdArgs == "" then "-" else SanitizeXML(cmdArgs)}`, Desc = "Parameters taken by the command"},
						{Text = `<b>Admin Level:</b> {Admin.FormatCommandAdminLevel(cmd)}`, Desc = "Rank required to run the command"},
						{Text = `<b>Description:</b> {SanitizeXML(cmd.Description)}`, Desc = "Command description"},
						{Text = `<b>Attributes:</b> {if #cmdAttribs == 0 then "-" else table.concat(cmdAttribs, "; ")}`, Desc = "Extra data about the command"},
						{Text = `<b>Index:</b> {SanitizeXML(tostring(ind))}`, Desc = "The internal command index/identifier"},
					};
					RichText = true;
					Size = {400, 225};
				})
			end
		};

		Notepad = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"notepad", "stickynote"};
			Args = {"text (optional)"};
			Description = "Opens a textbox window for you to type into";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Notepad", {Text = args[1]})
			end
		};

		CommsPanel = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"notifications", "commspanel"};
			Args = {};
			Description = "Opens the communications panel, showing you all the Adonis messages you have recieved in a timeline";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "CommsPanel")
			end
		};

		ClientTab = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"client", "clientsettings", "playersettings"};
			Args = {};
			Description = "Opens the client settings panel";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Client"})
			end
		};

		ClientPerfStats = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"clientperformance", "clientstats"};
			Args = {};
			Description = "Shows you your client performance stats";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "PerfStats")
			end
		};

		ServerSpeed = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"serverspeed", "serverping", "serverfps", "serverlag", "tps"};
			Args = {};
			Description = "Shows you the FPS (speed) of the server";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Functions.Hint(`The server FPS is {math.round(service.Workspace:GetRealPhysicsFPS())}`, {plr})
			end
		};

		RequestHelp = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"help"};
			Args = {"reason"};
			Description = "Calls admins for help";
			Filter = true;
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				if Settings.HelpSystem == true then
					local num = 0
					local answered = false
					local pending = Variables.HelpRequests[plr.Name];
					local reason = args[1] or "No reason provided";

					if pending and os.time() - pending.Time < 30 then
						error("You can only send a help request once every 30 seconds.");
					elseif pending and pending.Pending then
						error("You already have a pending request")
					else
						service.TrackTask(`Thread: {plr} Help Request Handler`, function()
							Functions.Hint("Request sent", {plr})

							pending = {
								Time = os.time();
								Pending = true;
								Reason = reason;
							}

							Variables.HelpRequests[plr.Name] = pending;

							for ind, p in service.Players:GetPlayers() do
								Routine(function()
									if Admin.CheckAdmin(p) then
										local ret = Remote.MakeGuiGet(p, "Notification", {
											Title = "Help Request";
											Message = `{plr.Name} needs help! Reason: {pending.Reason}`;
											Icon = server.MatIcons.Mail;
											Time = 30;
											OnClick = Core.Bytecode("return true");
											OnClose = Core.Bytecode("return false");
											OnIgnore = Core.Bytecode("return false");
										})

										num += 1
										if ret then
											if not answered then
												answered = true
												Commands.Teleport.Function(plr, {p.Name, `@{plr.Name}`})
											else
												Remote.MakeGui(p, "Notification", {
													Title = "Help Request";
													Message = "Another admin has already responded to this request!";
													Icon = server.MatIcons.Mail;
													Time = 5;
												})
											end
										end
									end
								end)
							end

							local w = os.time()
							repeat task.wait(0.5) until os.time()-w>30 or answered

							pending.Pending = false;

							if not answered then
								Functions.Message('HelpSystem', "Help System", "Sorry but no one is available to help you right now", 'MatIcon://Warning', {plr})
							end
						end)
					end
				else
					Functions.Message('HelpSystem', "Help System", "The help system has been disabled by the place owner.", 'MatIcon://Error', {plr})
				end
			end
		};

		Rejoin = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"rejoin"};
			Args = {};
			Description = "Makes you rejoin the server";
			NoStudio = true; -- Commands which cannot be used in Roblox Studio (e.g. commands which use TeleportService)
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				assert(#(service.Players:GetPlayers()) < service.Players.MaxPlayers or not Variables.DisableRejoinAtMaxPlayers, "Cannot rejoin while server is at max capacity.")
				service.TeleportService:TeleportAsync(game.PlaceId, {plr}, service.New("TeleportOptions", {
					ServerInstanceId = game.JobId
				}))
			end
		};

		Credits = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"credits"};
			Args = {};
			Description = "Shows you Adonis development credits";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Credits")
			end
		};

		ChangeLog = {
			Prefix = Settings.Prefix;
			Commands = {"changelog"};
			Args = {};
			Description = "Shows you the script's changelog";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Change Log";
					Icon = server.MatIcons["Text snippet"];
					Table = server.FormattedChangelog;
					RichText = true;
					Size = {500, 400};
				})
			end
		};

		Usage = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"syntax"};
			Args = {};
			Description = "Shows you how to use some syntax related things";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local Prefix = if type(Settings.Prefix) == "table" then Settings.Prefix[1] else Settings.Prefix
				local usage = {
					"";
					"Mouse over things in lists to expand them";
					"You can also resize windows by dragging the edges";
					"";
					`Put <b>/e</b> in front to silence commands in chat (<b>/e {Prefix}kill scel</b>) or enable chat command hiding in client settings`;
					`Player commands can be used by anyone, these commands have <b>{Settings.PlayerPrefix}</b> infront, such as <b>{Settings.PlayerPrefix}info</b> and <b>{Settings.PlayerPrefix}rejoin</b>`;
					"";
					`<b>――――― Player Selectors ―――――</b>`;
					`Usage example: <b>{Prefix}kill {Settings.SpecialPrefix}all</b> (where <b>{Settings.SpecialPrefix}all</b> is the selector)`;
					`<b>{Settings.SpecialPrefix}me</b> - Yourself`;
					`<b>{Settings.SpecialPrefix}all</b> - Everyone in the server`;
					`<b>{Settings.SpecialPrefix}admins</b> - All admins in the server`;
					`<b>{Settings.SpecialPrefix}nonadmins</b> - Non-admins (normal players) in the server`;
					`<b>{Settings.SpecialPrefix}others</b> - Everyone except yourself`;
					`<b>{Settings.SpecialPrefix}random</b> - A random person in the server excluding those removed with -SELECTION`;
					`<b>@USERNAME</b> - Targets a specific player with that exact username Ex: <b>{Prefix}god @Sceleratis </b> would give a player with the username 'Sceleratis' god powers`;
					`<b>#NUM</b> - NUM random players in the server <b>{Prefix}ff #5</b> will ff 5 random players excluding those removed with -SELECTION.`;
					`<b>{Settings.SpecialPrefix}friends</b> - Your friends who are in the server`;
					`<b>%TEAMNAME</b> - Members of the team TEAMNAME Ex: {Prefix}kill %raiders`;
					`<b>$GROUPID</b> - Members of the group with ID GROUPID (number in the Roblox group webpage URL)`;
					`<b>-SELECTION</b> - Inverts the selection, ie. will remove SELECTION from list of players to run command on. {Prefix}kill all,-%TEAM will kill everyone except players on TEAM`;
					`<b>+SELECTION</b> - Readds the selection, ie. will readd SELECTION from list of players to run command on. {Prefix}kill all,-%TEAM,+Lethalitics will kill everyone except players on TEAM but also Lethalitics`;
					`<b>radius-NUM</b> -- Anyone within a NUM-stud radius of you. {Prefix}ff radius-5 will ff anyone within a 5-stud radius of you.`;
					"";
					`<b>――――― Repetition ―――――</b>`;
					`Multiple player selections - <b>{Prefix}kill me,noob1,noob2,{Settings.SpecialPrefix}random,%raiders,$123456,{Settings.SpecialPrefix}nonadmins,-scel</b>`;
					`Multiple Commands at a time - <b>{Prefix}ff me {Settings.BatchKey} {Prefix}sparkles me {Settings.BatchKey} {Prefix}rocket jim</b>`;
					`You can add a delay if you want; <b>{Prefix}ff me {Settings.BatchKey} !wait 10 {Settings.BatchKey} {Prefix}m hi we waited 10 seconds</b>`;
					`<b>{Prefix}repeat 10(how many times to run the cmd) 1(how long in between runs) {Prefix}respawn jim</b>`;
					"";
					`<b>――――― Reference Info ―――――</b>`;
					`<b>{Prefix}cmds</b> for a list of available commands`;
					`<b>{Prefix}cmdinfo &lt;command&gt;</b> for detailed info about a specific command`;
					`<b>{Settings.PlayerPrefix}brickcolors</b> for a list of BrickColors`;
					`<b>{Settings.PlayerPrefix}materials</b> for a list of materials`;
					"";
					`<b>{Prefix}capes</b> for a list of preset admin capes`;
					`<b>{Prefix}musiclist</b> for a list of preset audios`;
					`<b>{Prefix}insertlist</b> for a list of insertable assets using {Prefix}insert`;
				}
				Remote.MakeGui(plr, "List", {
					Title = "Usage";
					Tab = usage;
					Icon = server.MatIcons["Quick reference"];
					Size = {300, 250};
					RichText = true;
				})
			end
		};

		Theme = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"theme"};
			Args = {"theme name (leave blank to reset to default)"};
			Hidden = true;
			Description = "Changes the Adonis client UI theme";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local playerData = Core.GetPlayer(plr)
				local data = playerData.Client or {}
				data.CustomTheme = args[1]
				playerData.Client = data
				Core.SavePlayer(plr, playerData)
				Remote.MakeGui(plr, "Notification", {
					Title = "Theme Changed";
					Icon = server.MatIcons.Palette;
					Message = if args[1] then `UI theme set to '{args[1]}'!` else `UI theme reset to default.`;
					Time = 5;
				})
				Remote.Send(plr, "SetVariables", { CustomTheme = args[1] or false })
			end
		};

		ScriptInfo = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"info", "about", "userpanel"};
			Args = {};
			Description = "Shows info about the admin system (Adonis)";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Info";})
			end
		};

		Aliases = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"aliases", "addalias", "removealias", "newalias"};
			Args = {};
			Description = "Opens the alias manager";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Aliases";})
			end
		};

		Keybinds = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"keybinds", "binds"};
			Args = {};
			Description = "Opens the keybind manager";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "KeyBinds";})
			end
		};

		GetPlus = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"getplus", "purchaseplus", "robloxplus"};
			Args = {};
			Description = "Prompts you to purchase Roblox Plus";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				service.MarketplaceService:PromptRobloxSubscriptionPurchase(plr)
			end
		};

		InspectAvatar = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"inspectavatar", "avatarinspect", "viewavatar", "examineavatar"};
			Args = {"player"};
			Description = "Opens the Roblox avatar inspect menu for the specified player";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				for _, v: Player in service.GetPlayers(plr, args[1], {UseFakePlayer = true}) do
					if v.UserId > 0 then
						Remote.Send(plr, "Function", "InspectPlayerFromUserId", v.UserId)
					end
				end
			end
		};

		NumPlayers = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pnum", "numplayers", "playercount"};
			Args = {};
			Description = "Tells you how many players are in the server";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Functions.Hint(`There are {#service.Players:GetPlayers()} player(s)`, {plr})
			end
		};

		TimeDate = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"timedate"};
			Args = {};
			Description = "Shows the current time and date.";
			AdminLevel = "Players";
			Function = function(plr: Player)
				local now = os.time()
				Remote.MakeGui(plr, "List", {
					Title = "Time & Date";
					Table = {
						{Text = "Date: " .. os.date("%x", now)},
						{Text = "Time: " .. os.date("%H:%M", now)},
						{Text = "Timezone: " .. os.date("%Z", now)},
					};
					AutoUpdate = 60;
					Size = {260, 160};
				})
			end
		};

		ViewProfile = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"profile"};
			Args = {"player"};
			Description = "Shows comphrehensive information about a player";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local elevated: boolean = Admin.CheckAdmin(plr)
				local players = service.GetPlayers(plr, args[1], {NoSelectors = not elevated})

				if #players > 2 then
					Functions.Hint(string.format("Loading profile data for %d players... [This may take a while]", #players), {plr})
				end

				for _, v: Player in players do
					task.defer(function()
						local gameData
						local elevated = plr == v or elevated

						if elevated then
							local level, rank = Admin.GetLevel(v)
							gameData = {
								IsMuted = Admin.IsMuted(v);
								AdminLevel = `[{level}] {rank or "Unknown"}`;
								SourcePlaceId = v:GetJoinData().SourcePlaceId or "N/A"
							}

							local inputData = Remote.Get(v, "Function", "GetUserInputServiceData")
							if type(inputData) == "table" then
								for k, d in inputData do
									if type(k) ~= "string" then break end
									gameData[k] = d
								end
							end
						end

						local policyInfo = elevated and select(2, xpcall(service.PolicyService.GetPolicyInfoForPlayerAsync, function() return "[Error]" end, service.PolicyService, v))
						local hasSafeChat = if policyInfo then
							type(policyInfo) == "string" and policyInfo or table.find(policyInfo.AllowedExternalLinkReferences, "Discord") and "No" or "Yes"
							else "[Redacted]"

						local mailVerif = select(2, xpcall(service.MarketplaceService.PlayerOwnsAsset, function() return "[Error]" end, service.MarketplaceService, v, 102611803))
						local hasVerifiedMail = if elevated then
							type(mailVerif) == "string" and mailVerif or mailVerif and "Yes" or "No"
							else "[Redacted]"

						local idVerif = select(2, xpcall(v.IsVerified, function() return "[Error]" end, v))
						local hasVerifiedId = if elevated then
							type(idVerif) == "string" and idVerif or idVerif and "Yes" or "No"
							else "[Redacted]"

						Remote.RemoveGui(plr, `Profile_{v.UserId}`)
						Remote.MakeGui(plr, "Profile", {
							Target = v;
							SafeChat = hasSafeChat;
							CanChatGet = table.pack(pcall(service.Chat.CanUserChatAsync, service.Chat, v.UserId));
							MailVerified = hasVerifiedMail;
							IDVerified = hasVerifiedId;
							GameData = gameData;
							IsServerOwner = v.UserId == game.PrivateServerOwnerId;
							CmdPrefix = Functions.GetMainPrefix();
							CmdSplitKey = Settings.SplitKey;
							OnlineFriends = elevated and Remote.Get(v, "Function", "GetFriendsOnline");
						})
					end)
				end
			end
		};

		ServerDetails = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"serverinfo"};
			Args = {};
			Description = "Shows you details about the current server";
			AdminLevel = "Players";
			ListUpdater = function(plr: Player)

				local adminDictionary, workspaceInfo
				if Admin.CheckAdmin(plr) then
					adminDictionary = {}
					for _, v in service.GetPlayers() do
						local level, rank = Admin.GetLevel(v)
						if level > 0 then
							adminDictionary[v.Name] = rank or "Unknown"
						end
					end
					local nilPlayers = 0
					for _, v in service.NetworkServer:GetChildren() do
						if v:IsA("NetworkReplicator") and v:GetPlayer() and not service.Players:FindFirstChild(v:GetPlayer().Name) then
							nilPlayers += 1
						end
					end
					workspaceInfo = {
						ObjectCount = #Variables.Objects;
						CameraCount = #Variables.Cameras;
						NilPlayerCount = nilPlayers;
						HttpEnabled = HTTP.HttpEnabled;
						LoadstringEnabled = HTTP.LoadstringEnabled;
						ServerSpeed = workspace:GetRealPhysicsFPS();
					}
				end

				return {Admins = adminDictionary; WorkspaceInfo = workspaceInfo;}
			end;
			Function = function(plr: Player, args: {string})
				local elevated = Admin.CheckAdmin(plr)

				local serverInfo = select(2, xpcall(function()
					local res = Variables.IPInfo or Functions.FetchServerInfo()
					if not Variables.IPInfo then
						Variables.IPInfo = res
					end
					return {
						country = `{require(server.Dependencies.CountryRegionCodes)[res.country] or "N/A"} ({res.country})`,
						city = res.city,
						region = res.region,
						zipcode = res.postal or "N/A",
						timezone = "N/A",
						ip = elevated and res.ip or "[Redacted]",
						coords = elevated and string.format("LAT: %s, LON: %s", string.match(res.loc, "(.*),(.*)")) or "[Redacted]",
					}
				end, function() return end))

				Remote.MakeGui(plr, "ServerDetails", {
					CreatorId = game.CreatorId;
					PrivateServerId = game.PrivateServerId;
					PrivateServerOwnerId = game.PrivateServerOwnerId;
					ServerStartTime = server.ServerStartTime;
					ServerSpeed = workspace:GetRealPhysicsFPS();
					ServerAge = service.FormatTime(os.time() - server.ServerStartTime);
					ServerInternetInfo = serverInfo;
					Refreshables = Logs.ListUpdaters.ServerDetails(plr);
					CmdPrefix = if type(Settings.Prefix) == "table" then Settings.Prefix[1] else Settings.Prefix,
					CmdPlayerPrefix = Settings.PlayerPrefix;
					SplitKey = Settings.SplitKey;
				})
			end
		};

		AudioPlayer = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"ap", "audioplayer", "mp", "musicplayer"};
			Args = {"soundId?"};
			Description = "Opens the audio player";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Music", {
					Song = args[1],
					GlobalPerms = Commands.Music and Admin.CheckComLevel(Admin.GetLevel(plr), Commands.Music.AdminLevel);
				})
			end
		};

		Coordinates = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"coordinates", "coords", "position"};
			Args = {};
			Description = "Shows your current position in the game world";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Coords")
			end;
		};

		Wait = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"wait"};
			Args = {"time"};
			Description = "Waits for the desired amount of time in seconds. Only works with batch commands";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				task.wait(math.clamp(tonumber(args[1]) or 0, 0, 600))

				return args
			end
		};
	};
end
