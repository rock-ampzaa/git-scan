<*
调用libgit2的函数处理从标准输入传入的每个目录
*>
module scan_git;
import std::io;
import git;

<* 引入libstring 中的函数 string_wide
@param input :"输入文字"
@return "返回多少个文字的显示宽度"
*>
extern fn uint wide(String input) @cname("string_wide");

fn int main(String[] args)
{
//      int major;
//      int minor;
//      int rev;
	//git::version(&major, &minor, &rev);
	//io::printfn("libgit2 version: %d.%d.%d", major, minor, rev);

//      @pool() {
//      	io::printn(string::tformat("版本号: %s", git::LIBGIT2_VERSION));
//      };
	if (args.len < 2){
		io::eprintn("必须有一个参数");
		return 1;
	}
	ZString path = args[1].zstr_copy(tmem);
	io::printfn("==========================================================================================================================================\n将要打开仓库: %s",
	     path);

	git::init();
	defer git::shutdown();
	Repo* tmp;
	if (0!=git::repository_open(&tmp, path)){
		GitError* e = git::error_last();
		io::printfn("\n打不开: %s", e.message);
		return 1;
	}
	io::printn();
	defer {
		//io::eprintn("defer repository");
		git::repository_free(tmp);
	}

	// 进行仓库是否为空检查
	if (1==git::repository_is_empty(tmp)) {
		// 因为是空仓库，不要检查
		io::printn("空仓库，不检查");
		return 1;
	}
	// 进行仓库是否为裸仓库检查, 如果是裸仓库则跳过下面的所有检查
	if (1== git::repository_is_bare(tmp)) {
		// 因为是裸仓库，不要检查
		io::printn("裸仓库，不检查");
		return 1;
	}
	BranchIterator* bi;
	if (0!= git::branch_iterator_new(&bi, tmp, git::BranchT.GIT_BRANCH_LOCAL)){
		// error process
		io::eprintn("无法创建branch iterator");
		return 1;
	}
	defer {
		if (bi){
			//io::eprintn("defer bi");
			git::branch_iterator_free(bi);
		}
	}

	// 检查 _deleted/_modified/_new/_typechange
	chk_status_change(tmp);

	chk_branch(bi);
	return 0;
}

<* 检查是否有变化
检查 renamed/deleted/modified/new/typechange 等状态变化
@param [&in] repo
@require repo != null
*>
fn void chk_status_change(Repo* repo)
{
	status::List* list;
	status::Options opts;
	status::options_init(&opts, status::GIT_STATUS_OPTIONS_VERSION);
	opts.show = status::ShowType.GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
	opts.flags = status::Opt_t.GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR | status::Opt_t.GIT_STATUS_OPT_INCLUDE_UNTRACKED| status::Opt_t.GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX;
	if (0 != status::list_new(&list, repo, &opts)) {
		// 如果不成功,则 
		io::eprintn("无法检查 worktree");
		return;
	}
	defer status::list_free(list);

	usz cnt = status::list_entrycount(list);
	for (usz i=0;i < cnt; i++) {
		Entry* entry = status::byindex(list, i);
		if (entry.status & status::Type.GIT_STATUS_WT_DELETED) {
			//该文件从worktree中删除了
			io::print(pad_right("删除了文件", 80));
			io::printn(string::tformat("[%s]", entry.index_to_workdir.old_file.path));
		}
		if (entry.status & status::Type.GIT_STATUS_INDEX_DELETED) {
			//该文件从index中删除了
			io::print(pad_right("删除了文件", 80));
			io::printn(string::tformat("[%s]", entry.head_to_index.old_file.path));
		}
		else if (entry.status & status::Type.GIT_STATUS_WT_NEW) {
			//新建文件
			io::print(pad_right("新增未管理文件:", 80));
			io::printn(string::tformat("[%s]", entry.index_to_workdir.old_file.path));
		}
		else if (entry.status & status::Type.GIT_STATUS_INDEX_NEW) {
			//新建文件
			io::print(pad_right("暂存了文件:", 80));
			io::printn(string::tformat("[%s]", entry.head_to_index.old_file.path));
		}
		else if (entry.status & status::Type.GIT_STATUS_WT_RENAMED) {
			// 改名
			io::print(pad_right("改名了文件:", 80));
			io::printn(string::tformat("[%s] -> [%s]", entry.index_to_workdir.old_file.path, entry.index_to_workdir.new_file.path));
		}
		else if (entry.status & status::Type.GIT_STATUS_INDEX_RENAMED) {
			// 改名
			io::print(pad_right("改名了文件:", 80));
			io::printn(string::tformat("[%s] -> [%s]", entry.head_to_index.old_file.path, entry.head_to_index.new_file.path));
		}
		else if (entry.status & GIT_STATUS_WT_MODIFIED) {
			// 修改过
			io::print(pad_right("修改了文件:", 80));
			io::printn(string::tformat("[%s]", entry.index_to_workdir.old_file.path));
		}
		else if (entry.status & GIT_STATUS_INDEX_MODIFIED) {
			// 修改过
			io::print(pad_right("修改了文件:", 80));
			io::printn(string::tformat("[%s]", entry.head_to_index.old_file.path));
		}
		else if (entry.status & GIT_STATUS_WT_TYPECHANGE) {
			// TODO:类型变化
		}
	}
}

<* 检查每个分支是否与对应的上游步调一致
以及是否存在完全没有上游分支的情况
@param bi :"分支遍历器"
@require bi != null : "不可为空"
*>
fn void chk_branch(BranchIterator* bi)
{
	bool has_upstream;
	ZString name, name1;
	Reference* b, upstream;
	while (0==git::branch_next(&b, &&git::BranchT.GIT_BRANCH_LOCAL, bi)) {
		if (0!=git::branch_name(&name, b)) continue;

		if (0==git::branch_upstream(&upstream, b)){
			if (!has_upstream) has_upstream = !has_upstream;


			git::branch_name(&name1, upstream);
			//io::printf("upstream name: %s ", pad_right(name.str_view(), 30));
			// 获取upstream oid, b oid
			git::Object* this_obj, upstream_obj;
			git::Oid* this_oid, upstream_oid;
			if (0==git::reference_peel(&this_obj, b, git::ObjectType.GIT_OBJECT_COMMIT)) {
				this_oid = git::object_id(this_obj);
			}
			if (0==git::reference_peel(&upstream_obj, upstream, git::ObjectType.GIT_OBJECT_COMMIT)) {
				upstream_oid = git::object_id(upstream_obj);
			}
			if ((this_oid && upstream_oid) && 0 != git::oid_cmp(this_oid, upstream_oid)) {
				io::print(pad_right(string::tformat("分支: %s",name.str_view()), 80));
				io::printfn("与上游[%s]不相同", name1.str_view());
			}
			else {
				//io::printn("与上游相同"); // NOTE:实际不用处理
			}
			if(this_obj) git::object_free(this_obj);
			if(upstream_obj) git::object_free(upstream_obj);
			if (upstream) git::branch_free(upstream);
		}
		//io::eprintn("free branch [b]variable");
		defer git::branch_free(b);
	}
	// 如果所有分支都没有上游分支，则要提示问题
	if (!has_upstream) {
		io::print(pad_right("全局", 80));
		io::printn("必须至少一个上游分支");
	}
}

<* 右填充左对齐
@param str :"待处理的文字"
@param len :"指定期望的长度"
@return "处理后的文字"
*>
fn String pad_right(String str, uint len)
{
	String result=str;
	while (wide(result) < len){
		result = result.concat(mem, " ");
	}
	return result;
}
<* 左填充右对齐
@param str :"待处理的文字"
@param len :"指定期望的长度"
@return "处理后的文字"
*>
fn String pad_left(String str, uint len)
{
	String result=str;
	while (wide(result) < len){
		result = " ".concat(mem, result);
	}
	return result;
}
