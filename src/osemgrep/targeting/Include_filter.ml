(*
   Similar to Gitignore_filter but select paths to be kept rather than ignored.
*)

open Ppath.Operators

type t = {
  project_root : Fpath.t;
  glob_matchers : Glob.Match.compiled_pattern list;
  no_match_loc : Glob.Match.loc;
}

let check_nonnegated_pattern str =
  match Gitignore.remove_negator str with
  | None -> ()
  | Some _ -> failwith ("--include patterns cannot be negated: " ^ str)

let create ~project_root patterns =
  List.iter check_nonnegated_pattern patterns;
  let glob_matchers =
    Common.map
      (fun pat ->
        Parse_gitignore.parse_pattern
          ~source:
            (Glob.Match.string_loc ~source_name:"include pattern"
               ~source_kind:(Some "include") pat)
          ~anchor:Glob.Pattern.root_pattern pat)
      patterns
  in
  let no_match_loc =
    Glob.Match.string_loc ~source_name:"include patterns"
      ~source_kind:(Some "include")
      (Printf.sprintf "NOT (%s)" (String.concat " OR " patterns))
  in
  { project_root; glob_matchers; no_match_loc }

(* map + find_opt, stopping as early as possible *)
let rec find_first func xs =
  match xs with
  | [] -> None
  | x :: xs -> (
      match func x with
      | None -> find_first func xs
      | Some _ as res -> res)

(*
   Each pattern is matched not just against the given path but also against
   its parents:

     Path    /src/a.c
     Pattern /src/      --> will be tested against /src, /src/, and /src/a.c

   If any of the patterns matches on any variant of the path, the
   file is selected.
*)
let select t (full_git_path : Ppath.t) =
  let rec scan_segments matcher parent_path segments =
    (* add a segment to the path and check if it's selected *)
    match segments with
    | [] -> None
    | segment :: segments -> (
        (* check whether partial path should be gitignored *)
        let file_path = parent_path / segment in
        if Glob.Match.run matcher (Ppath.to_string file_path) then
          Some (Glob.Match.source matcher)
        else
          match segments with
          | []
          | [ "" ] ->
              None
          | _ :: _ ->
              (* add trailing slash to match directory-only patterns *)
              let dir_path = file_path / "" in
              if Glob.Match.run matcher (Ppath.to_string dir_path) then
                Some (Glob.Match.source matcher)
              else scan_segments matcher file_path segments)
  in
  let rel_segments =
    match full_git_path.segments with
    | "" :: xs -> xs
    | __else__ -> assert false
  in
  match
    t.glob_matchers
    |> find_first (fun matcher -> scan_segments matcher Ppath.root rel_segments)
  with
  | None -> (Gitignore.Ignored, [ Gitignore.Selected t.no_match_loc ])
  | Some loc ->
      (* !! Deselected for gitignore = not ignored !! *)
      (Gitignore.Not_ignored, [ Gitignore.Deselected loc ])
