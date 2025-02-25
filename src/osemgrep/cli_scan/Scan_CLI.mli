(*
   'semgrep scan' (and also 'semgrep ci') command-line parsing.
*)

(*
   The result of parsing a 'semgrep scan' command.
*)
type conf = {
  (* Main configuration options *)
  (* mix of --pattern/--lang/--replacement, --config *)
  rules_source : Rules_source.t;
  (* can be a list of files or directories *)
  target_roots : Fpath.t list;
  (* Rules/targets refinements *)
  rule_filtering_conf : Rule_filtering.conf;
  targeting_conf : Find_targets.conf;
  (* Other configuration options *)
  nosem : bool;
  autofix : bool;
  dryrun : bool;
  error_on_findings : bool;
  strict : bool;
  rewrite_rule_ids : bool;
  time_flag : bool;
  profile : bool;
  (* osemgrep-only: whether to keep pysemgrep behavior/limitations/errors *)
  legacy : bool;
  (* Performance options *)
  core_runner_conf : Core_runner.conf;
  (* Display options *)
  (* mix of --json, --emacs, --vim, etc. *)
  output_format : Output_format.t;
  (* mix of --debug, --quiet, --verbose *)
  logging_level : Logs.level option;
  force_color : bool;
  (* text output config (TODO: make a separate type gathering all of them) *)
  max_chars_per_line : int;
  max_lines_per_finding : int;
  (* Networking options *)
  metrics : Metrics_.config;
  registry_caching : bool; (* similar to core_runner_conf.ast_caching *)
  version_check : bool;
  (* Ugly: should be in separate subcommands *)
  version : bool;
  show_supported_languages : bool;
  dump : Dump_subcommand.conf option;
  validate : Validate_subcommand.conf option;
  test : Test_subcommand.conf option;
}
[@@deriving show]

(* Command-line defaults. *)
val default : conf

(*
   Usage: parse_argv [| "semgrep-scan"; <args> |]

   Turn argv into a conf structure.

   This function may raise an exn in case of an error parsing argv
   but this should be caught by CLI.safe_run.
*)
val parse_argv : string array -> conf

(* exported because used by Ci_CLI.ml too *)
val cmdline_term : conf Cmdliner.Term.t

(* exported because used by Interactive_CLI.ml too *)
val o_lang : string option Cmdliner.Term.t
val o_target_roots : string list Cmdliner.Term.t
val o_include : string list Cmdliner.Term.t
val o_exclude : string list Cmdliner.Term.t
val o_ast_caching : bool Cmdliner.Term.t
