structure MlbUtil :>
  sig
    val vchat0 : (unit -> bool) -> string -> unit
    val quot : string -> string
    val warn : string -> unit
    val error : string -> 'a
    val errors : string list -> 'a
    val pp_list : string -> string list -> string
  end =
    struct
	fun pp_list sep nil = ""
	  | pp_list sep [x] = x 
	  | pp_list sep (x::xs) = x ^ sep ^ pp_list sep xs
	    
	fun quot s = "'" ^ s ^ "'"

	fun warn (s : string) = print ("\nWarning: " ^ s ^ ".\n\n")
	    
	local
	    fun err s = print ("\nError: " ^ s ^ ".\n\n"); 
	in
	    fun error (s : string) = (err s; raise Fail "error")	    
	    fun errors (ss:string list) = 
		(app err ss; raise Fail "error")
	end
    
	fun vchat0 (verbose:unit -> bool) s = 
	    if verbose() then print (" ++ " ^ s ^ "\n") 
	    else ()
		
	fun system verbose cmd : unit = 
	    (vchat0 verbose ("Executing command: " ^ cmd) ;
	     let 
		 val status = OS.Process.system cmd
		     handle _ => error ("Command failed: " ^ quot cmd)
	     in if status = OS.Process.failure then
		 error ("Command failed: " ^ quot cmd)
		else ()
	     end
	     )
    end

