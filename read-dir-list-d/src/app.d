import std.stdio, std.getopt;
import std.path, std.file;
import std.algorithm.iteration : filter;
import core.stdc.stdlib : EXIT_SUCCESS, EXIT_FAILURE;
import std.process;
import std.range, std.string;
import std.algorithm.sorting;
import std.algorithm;

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
	//writefln("------------- %s -------------", "getopt");
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
		writeln("version 0.1.1");
	if (verbose)
		writeln("verbose on");
	//      if (from_file)
	//      	writeln("list file: ", from_file);
	//      if (dir_params)
	//      	foreach (dir; dir_params)
	//      		writeln("dir: ", dir);

	//      writeln("--------------------------");
	//      auto files = dirEntries(".", "*.txt", SpanMode.depth);
	//      foreach (f; files) {
	//      	writefln("file: %s. isExists: %s. isDir: %s. isFile: %s", f.name, f.exists, f.isDir, f.isFile);
	//      }

	//      writeln("-----------筛选出来的目录---------------");
	//      /// dirs = 筛选出来的目录
	//      auto dirs = dirEntries(".", "*", SpanMode.shallow).filter!(f => f.isDir);
	//      foreach (f; dirs) {
	//      	writefln("directory: %s. isExists: %s. isDir: %s. isFile: %s", f.name, f.exists, f.isDir, f.isFile);
	//      }

	//writeln("------------读取当前程序名称--------------");
	//      writeln("当前名称: ", args[0]);
	//      writeln("当前短名称: ", baseName(args[0]));
	//      prog_name = args[0].baseName();
	//      writeln("当前短名称: ", prog_name);

	//writeln("-------------处理命令行参数中的 dir -------------");
	foreach (dir; dir_params) {
		// 判断目录列表文件是否存在
		if (chk_dir_exists(dir))
			git_dir ~= expand_path(dir);
	}
	//writeln("-------------读取目录列表文件-------------");
	// 判断目录列表文件是否存在
	// 如果指定了目录列表文件，则 读取 目录列表文件
	// 检查该文件是否存在
	// 	不存在：报错
	// 展开 home目录
	// - 检验 每个目录是否都存在
	// 	- 去掉 `/*`之后的目录要检验. 确保父目录存在
	// 展开`/*`字符, 获取子目录
	// 去掉 exclude 
	//
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

	//	writeln("\n----------检查目录列表是否为空----------------");
	// 是否指定目录列表文件
	//	否. 使用当前目录
	// 	是. 使用 指定目录列表文件
	if (!git_dir) {
		//writeln("当前目录: ", getcwd);
		git_dir ~= getcwd;
	}
	//      // TODO:测试代码 
	//writeln("当前git_dir内容");
	foreach (line; git_dir)
		writeln(line);

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
