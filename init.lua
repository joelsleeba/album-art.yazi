local M = {}

function M:peek()
	local start, cache = os.clock(), ya.file_cache(self)
	if not cache or self:preload() ~= 1 then
		return
	end

	ya.sleep(math.max(0, PREVIEW.image_delay / 1000 + start - os.clock()))
	ya.image_show(cache, self.area)
	ya.preview_widgets(self, {})
end

function M:seek(units) end

function M:preload()
	local cache = ya.file_cache(self)
	if not cache or fs.cha(cache) then
		return 1
	end

	function get_extension(filename)
		return filename:match("^.+(%..+)$")
	end

	local extension = get_extension(tostring(self.file.url))

	local output = ""
	if extension == ".ogg" then
		output = Command("ffmpegthumbnailer")
			:args({
				"-q 6",
				"-s 0",
				"-c jpeg",
				"-i",
				tostring(self.file.url),
				"-o /dev/stdout",
			})
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()
	else
		output = Command("exiftool")
		args({
				"-b",
				"-Coverart",
				"-Picture",
				tostring(self.file.url),
			})
			:stdout(Command.PIPED)
			:stderr(Command.PIPED)
			:output()
	end

	if not output then
		return 0
	elseif not output.status.success then
		local pages = tonumber(output.stderr:match("the last page %((%d+)%)")) or 0
		if self.skip > 0 and pages > 0 then
			ya.manager_emit("peek", { math.max(0, pages - 1), only_if = self.file.url, upper_bound = true })
		end
		return 0
	end

	return fs.write(cache, output.stdout) and 1 or 2
end

return M
