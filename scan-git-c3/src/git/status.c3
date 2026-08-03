module git::status;
import git::delta;

constdef ShowType @cname("git_status_show_t") {
	/**
	 * The default. This roughly matches `git status --porcelain` regarding
	 * which files are included and in what order.
	 */
	GIT_STATUS_SHOW_INDEX_AND_WORKDIR = 0,

	/**
	 * Only gives status based on HEAD to index comparison, not looking at
	 * working directory changes.
	 */
	GIT_STATUS_SHOW_INDEX_ONLY = 1,

	/**
	 * Only gives status based on index to working directory comparison,
	 * not comparing the index to the HEAD.
	 */
	GIT_STATUS_SHOW_WORKDIR_ONLY = 2
}
<*  cname("git_status_opt_t")
*>
constdef Opt_t : inline uint {
	/**
	 * Says that callbacks should be made on untracked files.
	 * These will only be made if the workdir files are included in the status
	 * "show" option.
	 */
	GIT_STATUS_OPT_INCLUDE_UNTRACKED                = (1u << 0),

	/**
	 * Says that ignored files get callbacks.
	 * Again, these callbacks will only be made if the workdir files are
	 * included in the status "show" option.
	 */
	GIT_STATUS_OPT_INCLUDE_IGNORED                  = (1u << 1),

	/**
	 * Indicates that callback should be made even on unmodified files.
	 */
	GIT_STATUS_OPT_INCLUDE_UNMODIFIED               = (1u << 2),

	/**
	 * Indicates that submodules should be skipped.
	 * This only applies if there are no pending typechanges to the submodule
	 * (either from or to another type).
	 */
	GIT_STATUS_OPT_EXCLUDE_SUBMODULES               = (1u << 3),

	/**
	 * Indicates that all files in untracked directories should be included.
	 * Normally if an entire directory is new, then just the top-level
	 * directory is included (with a trailing slash on the entry name).
	 * This flag says to include all of the individual files in the directory
	 * instead.
	 */
	GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS           = (1u << 4),

	/**
	 * Indicates that the given path should be treated as a literal path,
	 * and not as a pathspec pattern.
	 */
	GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH           = (1u << 5),

	/**
	 * Indicates that the contents of ignored directories should be included
	 * in the status. This is like doing `git ls-files -o -i --exclude-standard`
	 * with core git.
	 */
	GIT_STATUS_OPT_RECURSE_IGNORED_DIRS             = (1u << 6),

	/**
	 * Indicates that rename detection should be processed between the head and
	 * the index and enables the GIT_STATUS_INDEX_RENAMED as a possible status
	 * flag.
	 */
	GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX            = (1u << 7),

	/**
	 * Indicates that rename detection should be run between the index and the
	 * working directory and enabled GIT_STATUS_WT_RENAMED as a possible status
	 * flag.
	 */
	GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR         = (1u << 8),

	/**
	 * Overrides the native case sensitivity for the file system and forces
	 * the output to be in case-sensitive order.
	 */
	GIT_STATUS_OPT_SORT_CASE_SENSITIVELY            = (1u << 9),

	/**
	 * Overrides the native case sensitivity for the file system and forces
	 * the output to be in case-insensitive order.
	 */
	GIT_STATUS_OPT_SORT_CASE_INSENSITIVELY          = (1u << 10),

	/**
	 * Iindicates that rename detection should include rewritten files.
	 */
	GIT_STATUS_OPT_RENAMES_FROM_REWRITES            = (1u << 11),

	/**
	 * Bypasses the default status behavior of doing a "soft" index reload
	 * (i.e. reloading the index data if the file on disk has been modified
	 * outside libgit2).
	 */
	GIT_STATUS_OPT_NO_REFRESH                       = (1u << 12),

	/**
	 * Tells libgit2 to refresh the stat cache in the index for files that are
	 * unchanged but have out of date stat einformation in the index.
	 * It will result in less work being done on subsequent calls to get status.
	 * This is mutually exclusive with the NO_REFRESH option.
	 */
	GIT_STATUS_OPT_UPDATE_INDEX                     = (1u << 13),

	/**
	 * Normally files that cannot be opened or read are ignored as
	 * these are often transient files; this option will return
	 * unreadable files as `GIT_STATUS_WT_UNREADABLE`.
	 */
	GIT_STATUS_OPT_INCLUDE_UNREADABLE               = (1u << 14),

	/**
	 * Unreadable files will be detected and given the status
	 * untracked instead of unreadable.
	 */
	GIT_STATUS_OPT_INCLUDE_UNREADABLE_AS_UNTRACKED  = (1u << 15)
}

<* 应该放到 strarray 去 *>
struct Strarray @cname("git_strarray"){
	ZString[]	strings;
	sz	count;
}

<* 应该放到 tree *>
struct Tree @cname("git_tree") {void* _data_;}

struct List @cname("git_status_list") {void* _data_;}

struct  Options @cname("git_status_options") {
	/**
	 * The struct version; pass `GIT_STATUS_OPTIONS_VERSION`.
	 */
	uint version;

	/**
	 * The `show` value is one of the `git_status_show_t` constants that
	 * control which files to scan and in what order. The default is
	 * `GIT_STATUS_SHOW_INDEX_AND_WORKDIR`.
	 */
	ShowType show;

	/**
	 * The `flags` value is an OR'ed combination of the
	 * `git_status_opt_t` values above. The default is
	 * `GIT_STATUS_OPT_DEFAULTS`, which matches git's default
	 * behavior.
	 */
	uint      flags;

	/**
	 * The `pathspec` is an array of path patterns to match (using
	 * fnmatch-style matching), or just an array of paths to match
	 * exactly if `GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH` is specified
	 * in the flags.
	 */
	Strarray      pathspec;

	/**
	 * The `baseline` is the tree to be used for comparison to the
	 * working directory and index; defaults to HEAD.
	 */
	Tree*	baseline;

	/**
	 * Threshold above which similar files will be considered renames.
	 * This is equivalent to the -M option. Defaults to 50.
	 */
	ushort          rename_threshold;
}
constdef Type @cname("git_status_t") {
	GIT_STATUS_CURRENT = 0,

	GIT_STATUS_INDEX_NEW        = (1u << 0),
	GIT_STATUS_INDEX_MODIFIED   = (1u << 1),
	GIT_STATUS_INDEX_DELETED    = (1u << 2),
	GIT_STATUS_INDEX_RENAMED    = (1u << 3),
	GIT_STATUS_INDEX_TYPECHANGE = (1u << 4),

	GIT_STATUS_WT_NEW           = (1u << 7),
	GIT_STATUS_WT_MODIFIED      = (1u << 8),
	GIT_STATUS_WT_DELETED       = (1u << 9),
	GIT_STATUS_WT_TYPECHANGE    = (1u << 10),
	GIT_STATUS_WT_RENAMED       = (1u << 11),
	GIT_STATUS_WT_UNREADABLE    = (1u << 12),

	GIT_STATUS_IGNORED          = (1u << 14),
	GIT_STATUS_CONFLICTED       = (1u << 15)
}
struct Entry @cname("git_status_entry") {
	Type	status;
	delta::Delta*	head_to_index;
	delta::Delta*	index_to_workdir;
}
const uint GIT_STATUS_OPTIONS_VERSION = 1;

extern fn int list_new(List** out, git::Repo* repo, Options* opts) @cname("git_status_list_new");
extern fn void list_free(List* statuslist) @cname("git_status_list_free");
extern fn usz list_entrycount(List* statuslist) @cname("git_status_list_entrycount");
extern fn Entry* byindex(List* statuslist, usz idx) @cname("git_status_byindex");
extern fn int options_init(Options* opts, uint version) @cname("git_status_options_init");

