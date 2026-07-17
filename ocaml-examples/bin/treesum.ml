open Effect
open Effect.Deep

type _ Effect.t += Yield : int -> unit Effect.t

type 'a tree =
  | Leaf of 'a
  | Node of 'a tree * 'a tree

(* Build a tree of depth n with the number 1 stored in each leaf *)
let rec build_tree n =
  if n = 0 then Leaf 25
    else let subtree = build_tree (n - 1) in Node (subtree, subtree)

(* Traverse the tree *)
let rec tree_walker = function
  | Leaf x -> perform (Yield x)
  | Node (l, r) ->
    tree_walker l;
    tree_walker r

let () =
  let result = ref 0 in
  let mytree = build_tree(25) in
    match_with tree_walker mytree
    { retc = (fun () -> ());
      exnc = raise;
      effc = fun (type a) (eff : a Effect.t) ->
        match eff with
          | Yield n -> Some (fun (k : (a, _) continuation) ->
          result := !result + n;
          continue k ())
          | _ -> None };
    (* Todo: replace this with some output validation *)
    Printf.printf "Sum: %d\n" !result