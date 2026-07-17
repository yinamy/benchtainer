open Effect
open Effect.Deep
open Array
open Printf

module type Scheduler = sig
  val async : (unit -> 'a) -> unit
  (* [async f] runs [f] concurrently *)
  val yield : unit -> unit
  (* yields control to another task *)
  val run   : (unit -> 'a) -> unit
  (* Runs the scheduler *)
end

(* Round-robin scheduler *)
module Scheduler : Scheduler = struct

  type _ Effect.t += Async : (unit -> 'a) -> unit Effect.t
                   | Yield : unit Effect.t

  let async f = perform (Async f)

  let yield () = perform Yield
  
  let q = Queue.create ()
  let enqueue t = Queue.push t q
  let dequeue () =
    if Queue.is_empty q then ()
    else Queue.pop q ()

  let rec run : 'a. (unit -> 'a) -> unit =
    fun main ->
      match_with main ()
      { retc = (fun _ -> dequeue ());
        exnc = (fun e -> raise e);
        effc = (fun (type b) (eff: b Effect.t) ->
            match eff with
            | Async f -> Some (fun (k: (b, _) continuation) ->
                    enqueue (continue k);
                    run f
            )
            | Yield -> Some (fun k ->
                    enqueue (continue k);
                    dequeue ()
            )
            | _ -> None
        )}
end

open Scheduler

(* Parameters *)
let yields = 50
let batch_size = 20000

let main () =

  (* Monte Carlo simulation *)
  let monte_carlo name () =
    let pi = ref 0.0 in
    let inside = ref 0 in
    let total = ref 0 in

      (* Monte Carlo loop *)
      for _ = 0 to yields do
      for _ = 0 to batch_size do
        let x = Random.float 1.0 in
        let y = Random.float 1.0 in
        let dist = x *. x +. y *. y in

        if abs_float (dist -. 1.0) < 1e-10 || dist < 1.0 then
          incr inside;

        incr total

      done;

        yield ();

      done;
      
      pi := 4.0 *. float_of_int !inside /. float_of_int !total;
      (* Printf.printf "%s: Estimated Pi = %f\n" name !pi *)

  in

  let arr = init 1000 (fun i -> sprintf "Task %d" i) in

  Random.init 42; (* Seed the random number generator for reproducibility *)
  iter (fun name -> async (monte_carlo name)) arr

let _ = run main