
functor ParseElab(structure Parse: PARSE
		  structure Timing : TIMING
		  structure ElabTopdec: ELABTOPDEC
		    sharing type ElabTopdec.PreElabTopdec = Parse.topdec

 	          structure ModuleEnvironments : MODULE_ENVIRONMENTS
		    sharing type ElabTopdec.StaticBasis = ModuleEnvironments.Basis
			  
		  structure PreElabTopdecGrammar: TOPDEC_GRAMMAR
		    sharing type PreElabTopdecGrammar.topdec
				      = ElabTopdec.PreElabTopdec
		  structure PostElabTopdecGrammar: TOPDEC_GRAMMAR
		    sharing type PostElabTopdecGrammar.topdec
				      = ElabTopdec.PostElabTopdec

		  structure ErrorTraverse: ERROR_TRAVERSE
		    sharing type ErrorTraverse.topdec
					= ElabTopdec.PostElabTopdec

		  structure RefineErrorInfo: REFINE_ERROR_INFO
                    sharing type RefineErrorInfo.Report = ErrorTraverse.Report

		  structure InfixBasis: INFIX_BASIS
		    sharing type InfixBasis.Basis = Parse.InfixBasis

		  structure TopLevelReport: TOP_LEVEL_REPORT
		    sharing type TopLevelReport.ElabBasis = ElabTopdec.StaticBasis
		    sharing type TopLevelReport.InfixBasis = InfixBasis.Basis

		  structure BasicIO: BASIC_IO

		  structure Report: REPORT
		    sharing type InfixBasis.Report
					= Parse.Report
					= ErrorTraverse.Report
					= TopLevelReport.Report
					= Report.Report

		  structure PP: PRETTYPRINT
		    sharing type PP.Report = Report.Report

		  structure Flags: FLAGS
		  structure Crash: CRASH
		    ) (* : PARSE_ELAB  [removed for debugging] *)  =
  struct

    (* local abbreviations *)

    structure ErrorCode = ErrorTraverse.ErrorCode
    structure rEnv = ModuleEnvironments.rEnv
    structure B = ModuleEnvironments.B
    structure Report = Report
    structure Parse = Parse

    type Report = Report.Report
    type topdec = PostElabTopdecGrammar.topdec

    type prjid = ModuleEnvironments.prjid

    fun log s = TextIO.output(!Flags.log, s)
    fun chat s = if !Flags.chat then log s else ()

    (* -----------------------------------------------------------------
     * Dynamic flags
     * ----------------------------------------------------------------- *)

    val report_file_sig = ref false  (** "true" leads to huge outputs sometimes. *)
    val _ = Flags.add_flag_to_menu
          (["Control"], "report_file_sig",
	   "report program unit signatures", report_file_sig)

    infix //
    val op // = Report.//

    type InfixBasis = InfixBasis.Basis
    type ElabBasis = ElabTopdec.StaticBasis

    datatype Result =
        SUCCESS of {report: Report, infB: InfixBasis, elabB: ElabBasis, topdec: topdec}
      | FAILURE of Report * ErrorCode.ErrorCode list

    fun elab (prjid : prjid, infB, elabB, topdec) : Result =
          let val debugParse =
	            if !Flags.DEBUG_PARSING then
		      PP.reportStringTree(PreElabTopdecGrammar.layoutTopdec topdec)
		      // PP.reportStringTree(InfixBasis.layoutBasis infB)
		    else Report.null
	      val (elabB', topdec') = ElabTopdec.elab_topdec (prjid, elabB, topdec)
	  in
	    (case ErrorTraverse.traverse topdec' of
	       ErrorTraverse.SUCCESS =>
		 let val debugElab =
		           if !Flags.DEBUG_ELABTOPDEC then
			     ((PP.reportStringTree(ElabTopdec.layoutStaticBasis elabB'))
			      // (PP.reportStringTree(PostElabTopdecGrammar.layoutTopdec topdec')))
			   else Report.null
                     val rT = rEnv.T_of_C (B.to_rC elabB)
                     val rT' = rEnv.T_of_C (B.to_rC elabB')
                     val full_rT = rEnv.T_plus_T (rT, rT')          (* Needed for reporting. *)
                     val elabBfull' = B.plus_rT (elabB', full_rT)
                     val _ = if !Flags.DEBUG_ELABTOPDEC then 
				 print "before TopLevelReport.report\n"
                             else ()
		     val report = if !report_file_sig then 
	                    TopLevelReport.report {infB=infB, elabB=elabBfull', bindings=false}
		            else Report.line "Sort checking succeeded."
                     val _ = if !Flags.DEBUG_ELABTOPDEC then 
				 print "after TopLevelReport.report\n"
                             else ()
		 in
		   SUCCESS {report = debugParse // debugElab // report,
			    infB = infB, elabB = elabB', topdec = topdec'}
		 end
	     | ErrorTraverse.FAILURE (error_report, error_codes) => 
                 FAILURE (debugParse // error_report, error_codes))
	  end

    exception Parse of Report.Report
    local
      (*append_topdec topdec topdec_opt = the topdec formed by putting
       topdec after topdec_opt.  Linear in the number of nested topdecs in
       the first argument.*)
      (* open PreElabTopdecGrammar *)
      fun append_topdecs [] = NONE
	| append_topdecs (topdec::topdecs) =
	SOME(case topdec
	       of PreElabTopdecGrammar.STRtopdec (i, strdec, NONE) => 
		  PreElabTopdecGrammar.STRtopdec(i, strdec, append_topdecs topdecs)
		| PreElabTopdecGrammar.STRtopdec (i, strdec, SOME topdec') => 
		  PreElabTopdecGrammar.STRtopdec(i, strdec, append_topdecs (topdec'::topdecs))
		| PreElabTopdecGrammar.SIGtopdec (i, sigdec, NONE) => 
		  PreElabTopdecGrammar.SIGtopdec(i, sigdec, append_topdecs topdecs)
		| PreElabTopdecGrammar.SIGtopdec (i, sigdec, SOME topdec') => 
		  PreElabTopdecGrammar.SIGtopdec(i, sigdec, append_topdecs (topdec'::topdecs))
		| PreElabTopdecGrammar.FUNtopdec (i, fundec, NONE) => 
		  PreElabTopdecGrammar.FUNtopdec(i, fundec, append_topdecs topdecs)
		| PreElabTopdecGrammar.FUNtopdec (i, fundec, SOME topdec') => 
		  PreElabTopdecGrammar.FUNtopdec(i, fundec, append_topdecs (topdec'::topdecs)))

      fun parse0 (infB, state) =
	case Parse.parse (infB, state) 
	  of Parse.SUCCESS (infB', topdec, state') =>
	    let val (infB'', topdecs) = parse0(InfixBasis.compose (infB, infB'), state')
	    in (InfixBasis.compose(infB', infB''), topdec::topdecs)
	    end
	   | Parse.ERROR report => raise Parse report
	   (* Parse ought to not return an ERROR but instead simply raise
	    * an exception, such that this checking for ERROR and raising here
	    * could be avoided.  26/03/1997 22:38. tho.*)
	   | Parse.LEGAL_EOF => (InfixBasis.emptyB, [])
    in
      (*parse may raise Parse*)

      fun parse (infB : InfixBasis, source : Parse.SourceReader)
	    : InfixBasis * PreElabTopdecGrammar.topdec option =
	    let val state = Parse.begin source
	        val (infB', topdecs) = parse0 (infB, state)
	    in (infB', append_topdecs topdecs)
	    end handle IO.Io {name,...} => raise Parse (Report.line name)
    end (*local*)

    val empty_success = SUCCESS{report=Report.null, infB=InfixBasis.emptyB,
				elabB=B.empty, topdec=PostElabTopdecGrammar.empty_topdec}

    fun parse_elab_source {infB: InfixBasis, elabB: ElabBasis, 
                    prjid: prjid, source: Parse.SourceReader} : Result =
      let val _ = chat "[parsing begin...]\n"
          val show_compiler_timings = (Flags.lookup_flag_entry "show_compiler_timings")
          val keep = !show_compiler_timings
          val _ = show_compiler_timings := false;
	  val _ = Timing.timing_begin()
	  val (infB2, topdec_opt) = (parse (infB, source)  (*may raise Parse*) 
			            handle E => (Timing.timing_end "Parse" ; raise E))
	  val _ = Timing.timing_end "Parse" 
	  val _ = chat "[parsing end...]\n"
          val _ = show_compiler_timings := keep
	  val _ = chat "[elaboration begin...]\n"
 	  val _ = Timing.timing_begin()
	  val elab_res = case topdec_opt
			   of SOME topdec => (elab (prjid, infB2, elabB, topdec) 
 		                              handle E => (Timing.timing_end "Elab" ; raise E) )
			    | NONE => empty_success
          val _ = Timing.timing_end_brief prjid
                  (* "Time for Elaboration and Sort Checking: " ^ prjid *)
	  val _ = chat "[elaboration end...]\n"
      in elab_res
      end handle Parse report => (chat "[parsing end...]\n"; 
				  FAILURE (report, [ErrorCode.error_code_parse]))

    (* To maintain compatability in case we use the Manager - Rowan 26jul01 *)
    fun parse_elab {infB: InfixBasis, elabB: ElabBasis, prjid: prjid, file: string} : Result = 
      parse_elab_source {infB=infB, elabB=elabB, prjid=prjid, source=Parse.sourceFromFile file}

  exception PARSE_ELAB_ERROR of ErrorCode.ErrorCode list

  val currentInfB = ref InfixBasis.emptyB  (* should this accumulate? *)
  val currentElabB = ref B.initial
(*  val currentRefB = ref RefinedEnvironments.initialB *)  (* RefB is now part of ElabB *)

  fun refine (prjid: prjid, source: Parse.SourceReader, print_flag : bool) : unit =
      let val (infB,elabB) = (!currentInfB, !currentElabB)
	  val _ = Flags.reset_warnings ()
          fun print_error_report report = 
            Report.print' (Report.// (Report.line "\n ***************** Errors *****************",
					report) )
							(!Flags.log)
	  fun print_result_report report = (Report.print' report (!Flags.log);
					    Flags.report_warnings ())
      in 
	  case parse_elab_source {prjid=prjid, infB=infB, elabB=elabB, source=source} 
	    of SUCCESS {report, infB=res_infB, elabB=res_elabB, topdec=res_topdec} => 
                (if print_flag then print_result_report report else ();
                         currentInfB := InfixBasis.compose (!currentInfB, res_infB);
                         currentElabB := B.plus (!currentElabB, B.erase_TG res_elabB))

	     | FAILURE (report, error_codes) => 
               (Flags.report_warnings();  (* Print warnings even if there are errors.  *)
		print_error_report report; 
                raise PARSE_ELAB_ERROR error_codes)	 
      end 

  fun refine_string (str) : unit = refine ("<STRING>", Parse.sourceFromString str, true)
  fun refine_stdin () : unit = refine ("<STDIN>", Parse.sourceFromStdIn (), true)
  fun refine_file (filename) : unit = 
        (TextIO.output (TextIO.stdErr, "Sort Checking file: " ^ filename ^ "\n");
         refine (filename, Parse.sourceFromFile filename, !report_file_sig) )
  fun refine_file_report flag filename = let val keep = !report_file_sig  in
                                           report_file_sig := flag;
				  	   refine_file filename;
					   report_file_sig := keep
				         end
  fun refine_basisfile (filename) : unit = refine (filename, Parse.sourceFromFile filename, false)

  val basisDir = "../../basisstubs/current/"

  val basisFiles = 
    ["GENERAL-sig.sml", "General.sml", "OPTION-sig.sml", "Option.sml", "LIST-sig.sml", "List.sml",
     "LIST_PAIR.sml", "ListPair.sml", "VECTOR-sig.sml", "Vector.sml",
     "ARRAY-sig.sml", "Array.sml", "STRING_CVT.sml", "StringCvt.sml", "INTEGER.sml", "WORD-sig.sml", 
     "STR_BASE.sml", "CHAR-sig.sml", "STRING-sig.sml", "SUBSTRING-sig.sml",
     "BOOL-sig.sml", "Bool.sml", "MATH-sig.sml", "Math.sml", "from-mlton/IEEE-real.sig", "from-mlton/IEEE-real.sml", 
     "REAL-sig.sml", "Real.sml", "IO-sig.sml", "TIME-sig.sml", "Time.sml", "OS_PATH.sml",
     "OS_FILE_SYS.sml", "OS_PROCESS.sml", "OS_IO.sml", "OS-sig.sml",
     "COMMAND_LINE.sml", "CommandLine.sml", "DATE-sig.sml", "Date.sml", "TIMER-sig.sml", "Timer.sml",
     "SML90-sig.sml", "BIT_FLAGS.sml", "BitFlags.sml", 
     "MONO_VECTOR.sml", "MONO_ARRAY.sml", "MONO_VECTOR_SLICE.sml", "MONO_ARRAY_SLICE.sml", 
     "BYTE-sig.sml", "Byte.sml",
     "CharVector.sml"] @
     (map (fn s => "from-mlton/" ^ s)
      ["array2.sig", "array2.sml", "vector-slice.sig", "array-slice.sig", 
      "int-inf.sig", "int-inf.sml", "mono-array2.sig", "mono-array2.fun", "pack-real.sig",
      "pack-word.sig", "text.sig", "text.sml", 
      "io/prim-io.sig", "io/bin-prim-io.sml", "io/text-prim-io.sml", "io/prim-io.fun", 
      "io/stream-io.sig", "io/stream-io.fun", "io/imperative-io.sig", "io/imperative-io.fun", 
      "io/text-stream-io.sig", "io/bin-io.sig",
      "io/text-io.sig", "unix.sig", "unix.sml", 

      "net/net-host-db.sig", "net/net-host-db.sml", "net/net-prot-db.sig", "net/net-prot-db.sml", 
      "net/net-serv-db.sig", "net/net-serv-db.sml", "net/socket.sig", "net/socket.sml", 
      "net/inet-sock.sig", "net/inet-sock.sml", 
      "net/unix-sock.sig", "net/unix-sock.sml",
      "net/generic-sock.sig", "net/generic-sock.sml" ]) @
     ["POSIX.sml", "windows.sml"]
   

  fun resetBasis () = 
      let val () = currentInfB := InfixBasis.emptyB
          val () = currentElabB := B.initial

          val () = if !Flags.load_prelude then 
                    (print "Loading basis files\n";
                     List.app (fn filename => refine_basisfile (basisDir ^ filename))
                              basisFiles)
                  else ()
       in ()
       end

  val () = resetBasis ()

  val _ = report_file_sig := true;
  val _ = (Flags.lookup_flag_entry "show_compiler_timings") := true;


end

