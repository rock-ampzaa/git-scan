module git::delta;
constdef Type @cname("git_delta_t") {
	GIT_DELTA_UNMODIFIED = 0,  /**< no changes */
	GIT_DELTA_ADDED = 1,	   /**< entry does not exist in old version */
	GIT_DELTA_DELETED = 2,	   /**< entry does not exist in new version */
	GIT_DELTA_MODIFIED = 3,    /**< entry content changed between old and new */
	GIT_DELTA_RENAMED = 4,     /**< entry was renamed between old and new */
	GIT_DELTA_COPIED = 5,      /**< entry was copied from another old entry */
	GIT_DELTA_IGNORED = 6,     /**< entry is ignored item in workdir */
	GIT_DELTA_UNTRACKED = 7,   /**< entry is untracked item in workdir */
	GIT_DELTA_TYPECHANGE = 8,  /**< type of entry changed between old and new */
	GIT_DELTA_UNREADABLE = 9,  /**< entry is unreadable */
	GIT_DELTA_CONFLICTED = 10  /**< entry in the index is conflicted */
}
alias Object_size = ulong;
struct File @cname("git_diff_file") {
	/**
	 * The `git_oid` of the item.  If the entry represents an
	 * absent side of a diff (e.g. the `old_file` of a `GIT_DELTA_ADDED` delta),
	 * then the oid will be zeroes.
	 */
	Oid            id;

	/**
	 * The NUL-terminated path to the entry relative to the working
	 * directory of the repository.
	 */
	ZString        path;

	/**
	 * The size of the entry in bytes.
	 */
	Object_size  size;

	/**
	 * A combination of the `git_diff_flag_t` types
	 */
	uint           flags;

	/**
	 * Roughly, the stat() `st_mode` value for the item.  This will
	 * be restricted to one of the `git_filemode_t` values.
	 */
	ushort           mode;

	/**
	 * Represents the known length of the `id` field, when
	 * converted to a hex string.  It is generally `GIT_OID_SHA1_HEXSIZE`, unless this
	 * delta was created from reading a patch file, in which case it may be
	 * abbreviated to something reasonable, like 7 characters.
	 */
	ushort           id_abbrev;
}

<* 应该放到 git::diff去
*>
struct Delta @cname("git_diff_delta"){
	Type	status;
	uint    flags;	   /**< git_diff_flag_t values */
	ushort  similarity;  /**< for RENAMED and COPIED, value 0-100 */
	ushort  nfiles;	   /**< number of files in this delta */
	File    old_file;
	File    new_file;
}
