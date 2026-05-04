while rawget(_G, "Hyperion") == nil do
	task.wait()
end
local execute = script:FindFirstChild("Execute")
local code, loadCode = rawget(_G, "Hyperion").Scripts.ExecutePermission(script, execute and execute.Value)
local canUseLoadstring = loadstring and pcall(loadstring, "local a = 5 local b = a + 5") or false
local env = getfenv()

if code then
	(canUseLoadstring and loadstring(code) or loadCode(code, env))()
end
