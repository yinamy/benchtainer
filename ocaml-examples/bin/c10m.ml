open Effect
open Effect.Deep

type _ Effect.t += Yield : int -> unit Effect.t

(* TODO: This is a placeholder that doesn't actually use the stack *)
let stack_use total_kb =
  (* Make byte sequence containing zeroes *)
  let x = Bytes.make (total_kb * 1024) '\000' in
  (* Use some heap, I guess *)
  let result = ref Int32.zero in
  for i = 0 to total_kb - 1 do
    result := Int32.add !result (Int32.of_int (Char.code (Bytes.get x i)))
  done;
  Int32.add !result Int32.one

let async_worker total_kb =
  (* Yield back argument *)
  perform (Yield total_kb);
  (* Use stack and return *)
  stack_use total_kb
  
let () =
  (* Parameters *)
  let total_conn = 10000000 in
  let active_conn = 10000 in
  let stack_kb = 32 in
  (* Initialise array of continuations *)
  let rs = Array.make active_conn (fun i -> async_worker i) in
  (* Track total number of completed tasks, for validation *)
  let count = ref Int32.zero in

    (* Main loop *)
    for i = 0 to total_conn - 1 do
      let j = i mod active_conn in
        match_with rs.(j) stack_kb
          (* On return, increment number of completed tasks *)
        { retc = (fun (result : int32) -> 
            count := Int32.add !count result;
            if ((i + active_conn) < total_conn) then
              (* TODO: Check if this actually calls cont.new *)
              rs.(j) <- (fun i -> async_worker i)
            );
          exnc = raise;
          effc = fun (type a) (eff : a Effect.t) ->
            match eff with
              | Yield n -> Some (fun (k : (a, _) continuation) ->
                  assert (n = stack_kb);
                  continue k ())
              | _ -> None };
    done;
    (* TODO: replace this with some output validation *)
    Printf.printf "Sum: %d\n" (Int32.to_int !count)