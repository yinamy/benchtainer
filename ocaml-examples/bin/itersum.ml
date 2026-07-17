open Effect
open Effect.Deep

type _ Effect.t += Yield : int -> unit Effect.t

let count_up n =
  for i = 1 to n do
    perform (Yield i)
  done

let () =
  let result = ref 0 in
    match_with count_up 100000000
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