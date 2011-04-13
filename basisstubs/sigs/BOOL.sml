(*BOOL.sml*)

signature BOOL = sig
  eqtype bool
  val not : bool -> bool 
  val fromString : string -> bool option 
  val scan : (char, 'a) StringCvt.reader -> 'a -> (bool * 'a) option 
  val toString : bool -> string 
end; (*signature BOOL*)

(* 
   [not b] is the logical negation of b.

   [toString b] returns the string "false" or "true" according as b is
   false or true.

   [fromString s] scans a boolean b from the string s, after possible
   initial whitespace (blanks, tabs, newlines).  Returns (SOME b) if s
   has a prefix which is either "false" or "true"; the value b is the
   corresponding truth value; otherwise NONE is returned.

   [scan getc src] scans a boolean b from the stream src, using the
   stream accessor getc.  In case of success, returns SOME(b, rst)
   where b is the scanned boolean value and rst is the remainder of
   the stream; otherwise returns NONE.
*)
