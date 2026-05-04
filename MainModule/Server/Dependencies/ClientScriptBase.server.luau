while rawget(_G, "Hyperion") == nil do
	task.wait()
end
local execute = script:FindFirstChild("Execute")
local code, loadCode = rawget(_G, "Hyperion").Scripts.ExecutePermission(script, execute and execute.Value)
local env = getfenv()

if code then
	loadCode(code, env)()
end
