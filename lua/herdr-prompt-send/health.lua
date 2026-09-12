local M = {}

local health = vim.health

local function run(cmd)
	local ok, obj = pcall(vim.system, cmd, { text = true })
	if not ok then
		return nil, obj
	end
	local out = obj:wait(5000)
	if out.code == 124 then
		return nil, "timed out"
	end
	return out
end

local function check_executable()
	if vim.fn.executable("herdr") == 1 then
		health.ok("`herdr` executable found: " .. vim.fn.exepath("herdr"))
		return true
	end
	health.error("`herdr` executable not found in $PATH", { "Install herdr and make sure it is in $PATH" })
	return false
end

local function check_server()
	local out, err = run({ "herdr", "status", "server" })
	if not out then
		health.error("failed to run `herdr status server`: " .. tostring(err))
		return false
	end
	local status = out.stdout:match("status:%s*([^\n]+)")
	if out.code == 0 and status == "running" then
		health.ok("herdr server is running")
		return true
	end
	health.error("herdr server is not running (status: " .. (status or "unknown") .. ")", {
		"Run `herdr` to start or attach the server",
	})
	return false
end

local function check_agents()
	local out, err = run({ "herdr", "agent", "list" })
	if not out then
		health.error("failed to run `herdr agent list`: " .. tostring(err))
		return
	end
	local ok, res = pcall(vim.json.decode, out.stdout)
	if not ok or type(res) ~= "table" then
		health.error("failed to parse `herdr agent list` output as JSON", { vim.trim(out.stderr or "") })
		return
	end
	if out.code ~= 0 or res.error then
		local msg = res.error and res.error.message or vim.trim(out.stderr or "")
		health.error("`herdr agent list` failed: " .. msg)
		return
	end

	local self_pane = vim.env.HERDR_PANE_ID
	local agents = vim.tbl_filter(function(a)
		return a.pane_id ~= self_pane
	end, (res.result or {}).agents or {})
	if #agents == 0 then
		health.warn("no agent found", { "Start an AI coding agent in another herdr pane" })
		return
	end
	health.ok(("%d agent(s) found"):format(#agents))
	for _, a in ipairs(agents) do
		health.info(("%s  %s  %s"):format(a.pane_id, a.agent or "?", a.agent_status or ""))
	end
end

function M.check()
	health.start("herdr-prompt-send")

	if vim.fn.has("nvim-0.10") == 0 then
		health.error("Neovim 0.10 or later is required (uses `vim.system`)")
		return
	end

	if not check_executable() then
		return
	end
	if not check_server() then
		return
	end
	check_agents()
end

return M
