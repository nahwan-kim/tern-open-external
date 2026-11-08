--!strict
-- ⌘⌥-click on a file link in an omp surface opens it outside Tern: a folder in
-- FOLDER_APP, a file in its default app (`open`). ⌘⇧ is not used: Tern's ⇧-click extends
-- the text selection on mouse-down, before any route sees the click. Every other click,
-- web links, links in remote panes and bare paths Tern finds itself (they reach
-- route.open without the modifiers) keep Tern's built-in handling.

local FOLDER_APP = "QSpace Pro"

-- $1 path, $2 folder app. `~` expands to this Mac's home; a trailing :LINE[:COL] that
-- names no file is dropped. A file no app claims (`.luau`) opens in the default text
-- editor (`open -t`). Exit 3: nothing there.
local OPEN_SH = [[
p=$1
case $p in "~" | "~/"*) p=$HOME${p#"~"} ;; esac
if [ ! -e "$p" ]; then
	q=$(printf '%s' "$p" | sed -E 's/(:[0-9]+){1,2}$//')
	[ -e "$q" ] || exit 3
	p=$q
fi
if [ -d "$p" ]; then exec open -a "$2" "$p"; fi
open "$p" 2>/dev/null || exec open -t "$p"
]]

local function decode(s: string): string
	return (s:gsub("%%(%x%x)", function(h: string): string
		return string.char(tonumber(h, 16) :: number)
	end))
end

-- The local path a link names, or nil for a non-file URL.
local function link_path(url: string, cwd: string?): string?
	local p: string
	if url:sub(1, 7):lower() == "file://" then
		-- file://HOST/path: the host part (empty, localhost or this Mac's name) is dropped.
		local rest = url:sub(8)
		local slash = rest:find("/", 1, true)
		if not slash then
			return nil
		end
		p = decode((rest:sub(slash):gsub("[?#].*$", "")))
	elseif url:match("^%a[%w+.-]*:") then
		return nil -- http:, mailto:, … (a bare path never has a scheme)
	else
		p = url
	end
	if p == "" then
		return nil
	end
	if p:sub(1, 1) ~= "/" and p:sub(1, 1) ~= "~" then
		if not cwd or cwd == "" then
			return nil
		end
		p = (cwd:gsub("/+$", "")) .. "/" .. p
	end
	return p
end

local function remote_pane(cx: WindowCx, pane: number): boolean
	for _, h in cx.hosts:list() do
		if h.kind == "remote" then
			for _, id in h.panes do
				if id == pane then
					return true
				end
			end
		end
	end
	return false
end

tern.route.link(function(link: LinkRequest, cx: WindowCx): RouteDecision?
	local m = link.mods
	if not (m.cmd and m.alt) or m.shift or m.ctrl then
		return nil
	end
	if remote_pane(cx, link.pane) then
		return nil
	end
	local info = cx.session:pane(link.pane)
	local path = link_path(link.url, if info then info.cwd else nil)
	if not path then
		return nil
	end
	tern.process.run({ "/bin/sh", "-c", OPEN_SH, "sh", path, FOLDER_APP }, { timeout_ms = 10000 },
		function(r: ProcessResult, wcx: WindowCx?)
			if r.status == 0 or not wcx then
				return
			end
			if r.status == 3 then
				wcx:toast("error", "파일을 찾지 못했어요", path)
			else
				wcx:toast("error", "열지 못했어요", if r.stderr ~= "" then r.stderr else path)
			end
		end)
	return { handled = true }
end)
