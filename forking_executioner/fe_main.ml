open Fe_debug

let setup sock cmdargs id_to_fd_map env =
  let fd_sock_path = Printf.sprintf "/var/xapi/forker/fd_%s" 
    (Uuid.to_string (Uuid.make_uuid ())) in
  let fd_sock = Fecomms.open_unix_domain_sock () in
  Unixext.unlink_safe fd_sock_path;
  debug "About to bind to %s" fd_sock_path;
  Unix.bind fd_sock (Unix.ADDR_UNIX fd_sock_path);
  Unix.listen fd_sock 5;
  debug "bound, listening";
  let result = Unix.fork () in
  if result=0 
  then begin
    debug "Child here!";
    let result2 = Unix.fork () in
    if result2=0 then begin
      debug "Grandchild here!";
      (* Grandchild *)
      let state = {
	Child.cmdargs=cmdargs; 
	env=env;
	id_to_fd_map=id_to_fd_map; 
	ids_received=[];
	fd_sock2=None;
	finished=false;
      } in
      Child.run state sock fd_sock fd_sock_path
    end else begin
      (* Child *)
      exit 0;
    end
  end else begin
    (* Parent *)
    debug "Waiting for process %d to exit" result;
    ignore(Unix.waitpid [] result);
    Unix.close fd_sock;
    Some {Fe.fd_sock_path=fd_sock_path}
  end

let _ =
  (* Unixext.daemonize ();*)
  Sys.set_signal Sys.sigpipe (Sys.Signal_ignore);

  let main_sock = Fecomms.open_unix_domain_sock_server "/var/xapi/forker/main" in

  while true do
    try
      let (sock,addr) = Unix.accept main_sock in
      reset ();
      let cmd = Fecomms.read_raw_rpc sock in
      match cmd with
	| Fe.Setup s ->
	    let result = setup sock s.Fe.cmdargs s.Fe.id_to_fd_map s.Fe.env in
	    (match result with
	      | Some response ->
		  Fecomms.write_raw_rpc sock (Fe.Setup_response response);
		  Unix.close sock;
	      | _ -> ())
	| _ -> 
	    debug "Ignoring invalid message";
	    Unix.close sock
    with e -> 
      debug "Caught exception at top level: %s" (Printexc.to_string e);
  done
      
    
      
