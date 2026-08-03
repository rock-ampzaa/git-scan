module git;
struct Repo  @cname("git_repositoy"){void* _data_;}
//typedef Repo = void*;
struct BranchIterator @cname("git_branch_iterator") {void* _data_;}
struct Reference @cname("git_reference") {void* _data_;}
constdef BranchT {
	GIT_BRANCH_LOCAL = 1,
	GIT_BRANCH_REMOTE = 2,
	GIT_BRANCH_ALL = GIT_BRANCH_LOCAL|GIT_BRANCH_REMOTE
}
constdef ObjectType @cname("git_object_t") {
	GIT_OBJECT_ANY =      -2, /**< Object can be any of the following */
	GIT_OBJECT_INVALID =  -1, /**< Object is invalid. */
	GIT_OBJECT_COMMIT =    1, /**< A commit object. */
	GIT_OBJECT_TREE =      2, /**< A tree (directory listing) object. */
	GIT_OBJECT_BLOB =      3, /**< A file revision object. */
	GIT_OBJECT_TAG =       4, /**< An annotated tag object. */
	GIT_OBJECT_OFS_DELTA = 6, /**< A delta, base is given by an offset. */
	GIT_OBJECT_REF_DELTA = 7  /**< A delta, base is given by object id. */
}
const String LIBGIT2_VERSION = "1.9.0";
//typedef Object = void*; // git_object
struct Object @cname("git_object") {void* _data_;}
typedef Oid = char[20]; //@cname("git_oid");


extern fn int init() @cname("git_libgit2_init");
extern fn int shutdown() @cname("git_libgit2_shutdown");

extern fn int version(int* m, int* i,int* r) @cname("git_libgit2_version");

extern fn int repository_open(Repo** out_, ZString path) @cname("git_repository_open");
//extern fn int repository_open(Repo* out_, ZString path) @cname("git_repository_open");
extern fn void repository_free(Repo* repo) @cname("git_repository_free");
extern fn int repository_is_bare(Repo* repo) @cname("git_repository_is_bare");
extern fn int repository_is_empty(Repo* repo) @cname("git_repository_is_empty");



struct GitError @cname("git_error") { 
	ZString message;
	int klass;
}
extern fn GitError* error_last() @cname("git_error_last");

extern fn int branch_iterator_new(BranchIterator** out, Repo* repo, BranchT list_flags) @cname("git_branch_iterator_new");
extern fn void branch_iterator_free(BranchIterator* iter) @cname("git_branch_iterator_free");
extern fn int branch_next(Reference** out, BranchT* out_type, BranchIterator* iter) @cname("git_branch_next");
extern fn int branch_name(ZString* out, Reference* ref) @cname("git_branch_name");
extern fn int branch_upstream(Reference** out, Reference* branch) @cname("git_branch_upstream");

extern fn void reference_free(Reference* ref) @cname("git_reference_free");
alias branch_free = reference_free;
extern fn int reference_peel(Object** out, Reference* ref, ObjectType type) @cname("git_reference_peel");

extern fn void object_free(Object* object) @cname("git_object_free");
extern fn Oid* object_id(Object* obj) @cname("git_object_id");

extern fn int oid_cmp( Oid* a,  Oid* b) @cname("git_oid_cmp");
