import std.stdio, std.getopt;
import std.path, std.file;
import std.algorithm.iteration : filter;
import core.stdc.stdlib : EXIT_SUCCESS, EXIT_FAILURE;
import std.process;
import std.range, std.string;
import std.algorithm.sorting;
import std.algorithm;
import std.string;

extern (C) int proc__proc(const(char)* path);
/// 状态码
enum ERROR_CODE : int {
	PARAMETER_INVALID = 0x10,
	CONFIG_FILE_NOT_FOUND = 0x11,
}

/** 主函数
* Params:
*  args= 命令行参数
*  Returns: void
*/
int main(string[] args)
{
	string[] dir_params, git_dir;
	string from_file, prog_name;
	bool verbose = false;
	bool ver, must_upstream;

	auto opt = getopt(args,
			config.bundling, config.caseSensitive,
			"d|git-dir", &dir_params,
			"f|from-file", &from_file,
			"V|verbose", &verbose,
			"v|versioin", &ver,
			"u|must-upstream", &must_upstream,
	);
	if (opt.helpWanted)
		defaultGetoptPrinter("测试用", opt.options);

	if (ver)
		writeln("version 2.0.0");
	if (verbose)
		writeln("verbose on");

	prog_name = args[0].baseName();
	if (prog_name == "scan-need-git-op") {
		from_file ~= environment.get("HOME") ~ "/git-scan-dirs";
	}

	foreach (dir; dir_params) {
		// 判断目录列表文件是否存在
		if (chk_dir_exists(dir))
			git_dir ~= expand_path(dir);
	}

	if (from_file) {
		// 读取目录列表文件
		if (!exists(from_file)) {
			stderr.writefln("[%s]文件不存在", from_file);
			return ERROR_CODE.CONFIG_FILE_NOT_FOUND;
		}
		auto dirs_file = File(from_file, "r");
		scope (exit)
			dirs_file.close();
		proc_list_file(dirs_file, git_dir);
	}

	if (!git_dir) {
		//writeln("当前目录: ", getcwd);
		git_dir ~= getcwd;
	}
	foreach (line; git_dir) {
		// 这里循环调用c3函数
		proc__proc(toStringz(line));
	}
	return EXIT_SUCCESS;
}
/** 扩展路径
* 中的 '`' '$HOME' '.' 这类缩写
* Param:
* 	path = 待扩展路径
* Return: 扩展之后的文字列
*/
string expand_path(string path)
{
	if (path.empty())
		return path;
	else if (path[0] == '~') {
		string home = environment.get("HOME");
		if (path.length == 1)
			return home;
		else
			return home ~ path[1 .. $];
	} else if (path == ".")
		return getcwd();
	else if (path[0] == '.' && path[1] == '/')
		return getcwd ~ path[1 .. $];
	else if (path.length > 1 && path[0 .. 3] == "../")
		return getcwd ~ path[3 .. $];
	return path;
}

bool chk_dir_exists(string path)
{
	// 检查 该路径是否存在
	if (!exists(path))
		return false;
	// 检查路径 是否为目录
	return (isDir(path));
}

string[] get_subdir(string path)
{
	if (!chk_dir_exists(path)) {
		return [];
	}
	// 获取其下的子目录
	auto subdirs = dirEntries(path, "*", SpanMode.shallow).filter!(f => f.isDir && !f.name.endsWith("/.git"));
	return subdirs.map!(a => a.name).array();
}

/** 处理 目录列表文件内容
* Params: 
* 	dirs_file = 目录列表文件
* 	git_dir = 容纳处理后目录列表的数组
* Returns: void
*/
void proc_list_file(File dirs_file, ref string[] git_dir)
{
	auto tmp = sort_list_file(dirs_file);
	foreach (line_; tmp) {
		//writeln(line_);
		if (line_[0] == '!') {
			string _t = line_[1 .. $];
			//stderr.writeln("exclude: ", _t);
			// 在已有的git_dir 中排除匹配的内容
			for (int i = 0; i < git_dir.length; ++i) {
				//writeln("curent: ", git_dir[i], " exclude: ", line_);
				if (globMatch(git_dir[i], _t)) {
					//stderr.writeln("find exclude: ", git_dir[i]);
					// DONE:路径匹配，在 git_dir中删除
					git_dir[i] = "#";
					//stderr.writeln("process exclude: ", git_dir[i]);
				}
			}
		} else if (line_[$ - 2 .. $] == "/*") {
			// 检查末尾有'/*'的目录 去掉'/*'之后是否存在.
			// 再获取它的所有子目录
			//writeln(line_[$ - 2 .. $]);

			//writeln("DEBUG: ", line_[$ - 2 .. $]);
			auto subdirs = get_subdir(line_[0 .. $ - 2]);
			if (subdirs.empty)
				continue;
			//writeln("subdirs isnt empty");
			git_dir ~= subdirs;
		} else if (chk_dir_exists(line_)) {
			// 如果是指定的目录(末尾没有'/*'), 检查该目录是否存在, 如存在则加入git_dir
			//writefln("[%s]目录存在 ", line_);
			git_dir ~= line_;
		}
	}
	git_dir = git_dir.filter!(a => a != "#").array;
}

/** 目录列表文件内容排序
* Params:
* 	dirs_file = 目录列表文件
* Returns: 完成排序的数组
*/
string[] sort_list_file(File dirs_file)
{
	string[] result, result_;
	foreach (line; dirs_file.byLineCopy) {
		string s = line.strip;
		if (s.length == 0)
			continue;
		if (s[$ - 1] == '/')
			s = s[0 .. $ - 1];
		if (s[0] != '#') {
			if (s[0] == '!')
				result ~= '!' ~ expand_path(s[1 .. $]);
			else
				result ~= expand_path(s);
		}
	}
	void normalize(ref string s)
	{
		if (s[0] == '!')
			s = s[1 .. $];
		if (s[$ - 1] == '*')
			s = s[0 .. $ - 1];
		if (s[$ - 1] == '/')
			s = s[0 .. $ - 1];
	}

	bool _sort(string a, string b)
	{
		string _a, _b;
		_a = a.strip();
		_b = b.strip;
		if (_a.length == 0 && _b.length == 0) {
			return true;
		} else if (_b.length == 0) {
			return false;
		}
		normalize(_a);
		normalize(_b);
		return _a.length < _b.length;
	}
	// 排序
	foreach (line; sort!(_sort)(result)) {
		result_ ~= line;
		//stderr.writeln("sort: ", line);
	}
	return result_;
}
