## 运行时 GDScript 工具：编译源码、判断能否实例化。
class_name GDScriptUtils


## 从模型回复中取出纯 GDScript（去掉 ``` 代码围栏）。
static func extract_source(text: String) -> String:
	if StringUtils.is_blank(text):
		return StringUtils.EMPTY
	var code := FileUtils.normalize_line_endings_to_lf(text).strip_edges()
	if code.begins_with("```"):
		var first_newline := code.find("\n")
		if first_newline >= 0:
			code = code.substr(first_newline + 1)
		var fence := code.rfind("```")
		if fence >= 0:
			code = code.substr(0, fence)
		code = code.strip_edges()
	return code


## 编译源码。语法错误或无法实例化时返回 null。
static func compile(source: String) -> GDScript:
	if StringUtils.is_blank(source):
		Log.error("GDScriptUtils.compile empty source")
		return null
	var script := GDScript.new()
	script.source_code = source
	var err := script.reload()
	if err != OK:
		Log.error("GDScriptUtils.compile reload failed err:[{}]", err)
		return null
	if not script.can_instantiate():
		Log.error("GDScriptUtils.compile cannot instantiate")
		return null
	return script


## 从文件读取并编译。
static func compile_file(path: String) -> GDScript:
	var source := FileUtils.read_file_to_string(path)
	if StringUtils.is_blank(source):
		Log.error("GDScriptUtils.compile_file empty path:[{}]", path)
		return null
	return compile(source)
