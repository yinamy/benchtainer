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
let rec tree_walker = 
  let sum = ref 0 in function
    | Leaf x -> perform (Yield x); x
    | Node (l, r) ->
        let left_sum = tree_walker l in
        let right_sum = tree_walker r in
          sum := left_sum + !sum;
          sum := right_sum + !sum;
          !sum

let () =
  let result = ref 0 in
  let mytree = build_tree(25) in
    (match tree_walker mytree with
      | a -> Printf.printf "Sum: %d\n" a
      | exception exn -> raise exn
      | effect Yield n, k ->
          result := !result + n;
          continue k ()
      );
    (* Todo: replace this with some output validation *)
    Printf.printf "Result: %d\n" !result