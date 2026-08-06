<*
调用libgit2的函数处理从标准输入传入的每个目录
*>
module scan_git;
import std::io;
import proc;

fn int main(String[] argv)
{
	if (argv.len < 2){
		io::eprintn("必须有一个参数");
		return 1;
	}
	return proc::proc(argv[1]);
}
