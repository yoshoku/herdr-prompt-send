local M = {}

local config = {
	submit = false, -- If true, send the prompt including the Enter using `agent prompt`.
}

local function agents()
	local out = vim.system({ "herdr", "agent", "list" }, { text = true }):wait()
	if out.code ~= 0 then
		vim.notify("herdr agent list failed: " .. (out.stderr or ""), vim.log.levels.ERROR)
		return nil
	end
	local ok, res = pcall(vim.json.decode, out.stdout)
	if not ok then
		vim.notify("failed to parse herdr JSON", vim.log.levels.ERROR)
		return nil
	end
	local self_pane = vim.env.HERDR_PANE_ID
	return vim.tbl_filter(function(a)
		return a.pane_id ~= self_pane
	end, res.result.agents or {})
end

local function deliver(target, text)
	local cmd = config.submit and { "herdr", "agent", "prompt", target.pane_id, text }
		or { "herdr", "pane", "send-text", target.pane_id, text }
	vim.system(cmd, { text = true }, function(r)
		vim.schedule(function()
			if r.code ~= 0 then
				vim.notify("herdr failed: " .. (r.stderr or ""), vim.log.levels.ERROR)
			else
				vim.notify("sent to " .. target.pane_id)
			end
		end)
	end)
end

function M.send(opts)
	opts = opts or {}
	local text
	if opts.reg and opts.reg ~= "" then
		text = vim.fn.getreg(opts.reg)
		text = text:gsub("\n$", "")
	elseif opts.range == 2 then
		text = table.concat(vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false), "\n")
	else
		text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	end
	if vim.trim(text) == "" then
		return vim.notify("nothing to send", vim.log.levels.WARN)
	end

	local list = agents()
	if not list then
		return
	end
	if #list == 0 then
		return vim.notify("no agent found", vim.log.levels.WARN)
	end
	if #list == 1 then
		return deliver(list[1], text)
	end

	vim.ui.select(list, {
		prompt = "Send prompt to:",
		format_item = function(a)
			return ("%s  %s  %s"):format(a.pane_id, a.agent or "?", a.agent_status or "")
		end,
	}, function(choice)
		if choice then
			deliver(choice, text)
		end
	end)
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
	vim.api.nvim_create_user_command("HerdrPromptSend", function(o)
		M.send({ reg = o.reg, range = o.range, line1 = o.line1, line2 = o.line2 })
	end, { range = true, register = true, desc = "Send buffer, range, or register to a Herdr agent" })
end

return M
