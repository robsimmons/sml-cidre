
let val cidreDir = OS.FileSys.getDir()
in 
  OS.FileSys.chDir "src/Cidre";
  CM.make "cidre.cm";
  if (SMLofNJ.exportML "../../bin/.heap/sml-cidre") then 
      case Compiler.version of {system, version_id=major::minor::_,...} =>
      (print (system ^ " " ^ Int.toString major ^ "." ^ Int.toString minor ^ "\n" ^
             "with SML-CIDRE 0.99d\n\n");
       "CIDRED")
  else 
(print "CIDRE exported!\n";

  let val smlCidre = TextIO.openOut "../../bin/sml-cidre" 
      val smlCidreBat = TextIO.openOut "../../bin/sml-cidre.bat" 
  in
    TextIO.output (smlCidre, "#! /bin/sh\nsml @SMLload=\"" ^ cidreDir ^ "/bin/.heap/sml-cidre\"");
    TextIO.output (smlCidreBat, "sml @SMLload=\"" ^ cidreDir ^ "/bin/.heap/sml-cidre\"");
    TextIO.closeOut smlCidre;
    ""
  end
)
end
