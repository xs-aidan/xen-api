(*
   Copyright (C) Citrix Systems Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License as published
   by the Free Software Foundation; version 2.1 only. with the special
   exception on linking described in file LICENSE.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License for more details.
 *)

let gc_compact ~__context ~host:_ = Gc.compact ()

let gc_stats ~__context ~host:_ =
  let stat = Gc.stat () in
  [
    ("minor_words", string_of_float stat.Gc.minor_words)
  ; ("promoted_words", string_of_float stat.Gc.promoted_words)
  ; ("major_words", string_of_float stat.Gc.major_words)
  ; ("minor_collections", string_of_int stat.Gc.minor_collections)
  ; ("major_collections", string_of_int stat.Gc.major_collections)
  ; ("heap_words", string_of_int stat.Gc.heap_words)
  ; ("heap_chunks", string_of_int stat.Gc.heap_chunks)
  ; ("live_words", string_of_int stat.Gc.live_words)
  ; ("live_blocks", string_of_int stat.Gc.live_blocks)
  ; ("free_words", string_of_int stat.Gc.free_words)
  ; ("free_blocks", string_of_int stat.Gc.free_blocks)
  ; ("largest_free", string_of_int stat.Gc.largest_free)
  ; ("fragments", string_of_int stat.Gc.fragments)
  ; ("compactions", string_of_int stat.Gc.compactions)
  ; ("top_heap_words", string_of_int stat.Gc.top_heap_words)
  ]

let db_stats ~__context =
  (* Use Printf.sprintf to keep format *)
  let open Xapi_database in
  let Db_lock.{count; avg_time; min_time; max_time} = Db_lock.report () in
  [
    ("n", Printf.sprintf "%d" count)
  ; ("avgtime", Printf.sprintf "%f" avg_time)
  ; ("min", Printf.sprintf "%f" min_time)
  ; ("max", Printf.sprintf "%f" max_time)
  ]

let network_stats ~__context ~host:_ ~params =
  let meth (m, _, _) =
    (not (List.mem_assoc "method" params))
    || String.lowercase_ascii (Http.string_of_method_t m)
       = String.lowercase_ascii (List.assoc "method" params)
  in
  let uri (_, u, _) =
    (not (List.mem_assoc "uri" params))
    || String.lowercase_ascii u
       = String.lowercase_ascii (List.assoc "uri" params)
  in
  let has_param x =
    (not (List.mem_assoc "params" params))
    || List.mem x (String.split_on_char ',' (List.assoc "params" params))
  in
  Http_svr.Server.all_stats Xapi_http.server
  |> List.filter meth
  |> List.filter uri
  |> List.map (fun (m, uri, stats) ->
         List.concat
           [
             (if has_param "method" then [Http.string_of_method_t m] else [])
           ; (if has_param "uri" then [uri] else [])
           ; ( if has_param "requests" then
                 [string_of_int stats.Http_svr.Stats.n_requests]
               else
                 []
             )
           ; ( if has_param "connections" then
                 [string_of_int stats.Http_svr.Stats.n_connections]
               else
                 []
             )
           ; ( if has_param "framed" then
                 [string_of_int stats.Http_svr.Stats.n_framed]
               else
                 []
             )
           ]
     )
