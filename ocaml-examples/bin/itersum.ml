open Effect
open Effect.Deep

type _ Effect.t += Yield : int -> unit Effect.t

let count_up n =
  for i = 1 to n do
    perform (Yield i)
  done

let () =
  let result = ref 0 in
  (match count_up 100000000 with
    | () -> ()
    | effect Yield n, k ->
        result := !result + n;
        continue k ()
    | exception exn -> raise exn);
    (* Todo: replace this with some output validation *)
    Printf.printf "Sum: %d\n" !result