(*
   Abstract type for a file path within a project.

   This avoids issues of Unix-style vs. Windows-style paths. All
   paths use '/' as a separator.

   The name of the module imitates Fpath.ml, but use Ppath.ml for
   Project path (instead of File path).
*)

type t = private {
  (* path segments within the project root *)
  segments : string list;
  (* internal *)
  string : string;
}

(*
   Return an absolute, normalized path relative to the project root.
   This is purely syntactic. It is recommended to work on physical paths
   as returned by 'realpath' to ensure that both paths share the longest
   common prefix.

     in_project ~root:(Fpath.v "/a") (Fpath.v "/a/b/c")

   equals

     Ok (of_string "/b/c")
*)
val in_project : root:Fpath.t -> Fpath.t -> (t, string) result

(* A slash-separated path. *)
val of_string : string -> t
val to_string : t -> string

(* Create a path from the list of segments. Segments may not contain
   slashes. *)
val create : string list -> t
val segments : t -> string list

(* Append a segment to a path. *)
val add_seg : t -> string -> t

(* Imitate File.Operators in libs/commons/ *)
module Operators : sig
  (* Same as append *)
  val ( / ) : t -> string -> t
end

val is_absolute : t -> bool
val is_relative : t -> bool

(* Turn foo/bar into /foo/bar *)
val make_absolute : t -> t

(*
   Syntactic path normalization.
   e.g. foo/../bar -> bar  (even if 'foo/' doesn't exist)

   Fail if the resulting path is absolute and refers to a file above the
   root e.g. '/..' or '/../..'.

   TODO: use filesystem path to the project root to perform a correct
   normalization.
*)
val normalize : t -> (t, string) result
val of_fpath : Fpath.t -> t

(* Convert back to a system path. *)
val to_fpath : root:Fpath.t -> t -> Fpath.t

(* / *)
val root : t
