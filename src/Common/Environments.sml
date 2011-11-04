(* Static semantic objects for the Core - Definition v3 page 17
   This functor also provides the Core objects needed by the
   Modules elaborator *)

(* Static semantic objects - Definition v3 page 17 *)

functor Environments(
             structure DecGrammar: DEC_GRAMMAR
             structure StrId: STRID

		     structure Ident: IDENT
		       where type strid = StrId.strid
		       where type longid = DecGrammar.longid
		       where type id = DecGrammar.id

		     structure TyCon: TYCON
		       sharing type TyCon.strid = StrId.strid

		     structure TyName: TYNAME
		       sharing type TyName.tycon = TyCon.tycon

		     structure StatObject: STATOBJECT
		       where type ExplicitTyVar = DecGrammar.tyvar
		       where type TyName = TyName.TyName
		       where type tycon = TyName.tycon

		     structure PP: PRETTYPRINT

		     structure Report: REPORT

		     structure SortedFinMap: SORTED_FINMAP
                where type Report = Report.Report

		     structure FinMap: FINMAP
                where type Report = Report.Report

		     structure Timestamp: TIMESTAMP

		     structure Flags: FLAGS
		     structure Crash: CRASH
		    ) : ENVIRONMENTS = struct

    structure ListPair = Edlib.ListPair
    structure FinMap = FinMap

    fun uncurry f (a,b) = f a b 

    fun impossible s = Crash.impossible ("Environments." ^ s)
    fun noSome NONE s = impossible s
      | noSome (SOME x) s = x
    fun map_opt f (SOME x) = SOME (f x)
      | map_opt f NONE = NONE

    fun member _ [] = false
      | member x (y::ys) = x=y orelse member x ys

    (*import from StatObject:*)
    type level             = StatObject.level

    type ExplicitTyVar     = StatObject.ExplicitTyVar
    type TyName            = StatObject.TyName.TyName
    type Type              = StatObject.Type
    type TypeScheme        = StatObject.TypeScheme
    type RecType           = StatObject.RecType
    type TypeFcn           = StatObject.TypeFcn
    type TyVar             = StatObject.TyVar
    type Substitution      = StatObject.Substitution
    type realisation       = StatObject.realisation
    structure Level        = StatObject.Level
    structure TyVar        = StatObject.TyVar
    structure TyName       = StatObject.TyName
    structure Type         = StatObject.Type
    structure TypeScheme   = StatObject.TypeScheme
    structure Substitution = StatObject.Substitution
    structure TypeFcn      = StatObject.TypeFcn
    structure Realisation  = StatObject.Realisation

    (*import from other modules:*)
    type id                = Ident.id
    type longid            = Ident.longid
    type valbind           = DecGrammar.valbind
    type tycon             = TyCon.tycon
    type longtycon         = TyCon.longtycon
    type strid             = StrId.strid
    type longstrid         = StrId.longstrid
    type pat               = DecGrammar.pat
    type ty                = DecGrammar.ty
    type Report            = Report.Report


(*TODO 02/02/1997 14:04. tho.   move these to StatObject.TyVar:
 Actually these are implemented using TyVar.eq which is
 TyVar.eq_free orelse eq_bound EQ_SIGNIFICANT, whilst those in
 StatObject are implemented using TyVar.eq_free.  I don't know what
 difference this makes, or whether it is intended.*)


    fun memberTyVarSet x set =
      List.exists (fn y => TyVar.eq (x,y)) set

    fun unionTyVarSet(set1, set2) =
	set1 @ 
	List.filter 
	  (fn x => not(memberTyVarSet x set1)) set2



    (********
     Syntactic type variables, and 
     function which finds the set of type variables in a ty abstract 
     syntax tree 
     ********)

    local
      open DecGrammar
    in
      fun ExplicitTyVarsTy ty =
	case ty of 
	  TYVARty(_, tyvar) => 
	    EqSet.singleton tyvar
	| RECORDty(_, NONE) => 
	    EqSet.empty
	| RECORDty(_, SOME tyrow) =>  
	    ExplicitTyVarsTyRow tyrow
	| CONty(_, tylist, _) => 
	    foldl (uncurry EqSet.union) EqSet.empty (map ExplicitTyVarsTy tylist)
        | INTERty (_, ty1, ty2) =>
	    EqSet.union (ExplicitTyVarsTy ty1)
	                (ExplicitTyVarsTy ty2)
	| FNty(_,ty1,ty2) => 
	    EqSet.union (ExplicitTyVarsTy ty1)
	                (ExplicitTyVarsTy ty2)
	| PARty(_,ty) => 
	    ExplicitTyVarsTy ty

      and ExplicitTyVarsTyRow (TYROW(_,_,ty,tyrowopt)) =
	EqSet.union 
	(ExplicitTyVarsTy ty) 
	(case tyrowopt of
	   NONE => EqSet.empty
	 | SOME tyrow => ExplicitTyVarsTyRow tyrow)
    end

    (* Type goals for valdecs, including TyCon-TyName pairs that may be "realised"
       at the actual valdec, but are opaque where the tygoal appears (e.g. in a signature) *)
    type ToRealise  = (tycon, TyName) FinMap.map
    structure ToRea = 
    struct
       val empty : ToRealise = FinMap.empty
       val singleton : tycon * TyName -> ToRealise = FinMap.singleton
       val add = FinMap.add
       val plus = FinMap.plus
       val layout = FinMap.layoutMap {start="", finish="",sep=", ", eq=" => "} 
				     (StringTree.LEAF o TyCon.pr_TyCon) TyName.layout
    end

    datatype TyGoals = TYGOALS of (id, ToRealise * TypeScheme) FinMap.map

    (* Finish this when we do the generation of TyGoals in ElabTopdec *)
    structure TG = 
      struct
	  val empty : TyGoals = TYGOALS FinMap.empty
	  val singleton : id * (ToRealise * TypeScheme) -> TyGoals = 
	      TYGOALS o FinMap.singleton
          fun singleton0 (id, sigma) = singleton (id, (ToRea.empty, sigma))
	  fun add (id, (torea, tysch), TYGOALS s) = TYGOALS (FinMap.add (id, (torea, tysch), s))
          fun add0 (id, sigma, TG) = add (id, (ToRea.empty, sigma), TG)
	  fun plus (TYGOALS s, TYGOALS s') : TyGoals = TYGOALS (FinMap.plus(s, s'))
	  fun lookup (TYGOALS map) (id : id) : (ToRealise * TypeScheme) option = 
            FinMap.lookup map id
	  fun layout (TYGOALS m) = 
 	    FinMap.layoutMap {start="", finish="",sep=", ", eq=" : "} 
		     (StringTree.LEAF o Ident.pr_id) (PP.layout_pair ToRea.layout TypeScheme.layout) m
      end

    fun layoutT T = TyName.Set.layoutSet {start ="{", sep=", ", finish="}"} TyName.layout T

    local

      infix ++
      fun set1 ++ set2 = set1 @ List.filter (fn x => not(member x set1)) set2

      fun unguarded_opt f (SOME x) = f x
	| unguarded_opt f (NONE  ) = []

      fun unguarded_list f [] = []
	| unguarded_list f (h::t) = f h ++ unguarded_list f t

      fun unguarded_atexp(DecGrammar.RECORDatexp(_,exprow_opt)) =
	  unguarded_opt unguarded_exprow exprow_opt
	| unguarded_atexp(DecGrammar.LETatexp(_,dec,exp)) =
	  unguarded_dec dec ++ unguarded_exp exp
	| unguarded_atexp(DecGrammar.PARatexp(_,exp)) =
	  unguarded_exp exp
	| unguarded_atexp(DecGrammar.INSTatexp(_,_,tys)) =
	  unguarded_list unguarded_ty tys
	| unguarded_atexp _ = []

      and unguarded_exprow(DecGrammar.EXPROW(_,_,exp,exprow_opt)) =
	  unguarded_exp exp ++ unguarded_opt unguarded_exprow exprow_opt

      and unguarded_exp(DecGrammar.ATEXPexp(_,atexp)) =
	  unguarded_atexp atexp
	| unguarded_exp(DecGrammar.APPexp(_,exp,atexp)) =
	  unguarded_exp exp ++ unguarded_atexp atexp
	| unguarded_exp(DecGrammar.TYPEDexp(_,exp,ty)) =
	  unguarded_exp exp ++ unguarded_ty ty
	| unguarded_exp(DecGrammar.SORTEDexp(_,exp,tys)) =
	  unguarded_exp exp ++ unguarded_list unguarded_ty tys
	| unguarded_exp(DecGrammar.HANDLEexp(_,exp,match)) =
	  unguarded_exp exp ++ unguarded_match match
	| unguarded_exp(DecGrammar.RAISEexp(_,exp)) =
	  unguarded_exp exp
	| unguarded_exp(DecGrammar.FNexp(_,match)) =
	  unguarded_match match
	| unguarded_exp(DecGrammar.UNRES_INFIXexp _) =
	    impossible "unguarded_exp(UNRES_INFIX)"

      and unguarded_match(DecGrammar.MATCH(_,mrule,match_opt)) =
	  unguarded_mrule mrule ++
	  unguarded_opt unguarded_match match_opt

      and unguarded_mrule(DecGrammar.MRULE(_,pat,exp)) =
	  unguarded_pat TG.empty pat ++
	  unguarded_exp exp

      and unguarded_dec(DecGrammar.EXCEPTIONdec(_,exbind)) =
	  unguarded_exbind exbind
	| unguarded_dec(DecGrammar.LOCALdec(_,dec1,dec2)) =
	  unguarded_dec dec1 ++ unguarded_dec dec2
	| unguarded_dec(DecGrammar.SEQdec(_,dec1,dec2)) =
	  unguarded_dec dec1 ++ unguarded_dec dec2
	| unguarded_dec _ = []

      and unguarded_valbind TG (DecGrammar.PLAINvalbind(_,pat,exp,valbind_opt)) =
	  unguarded_pat TG pat ++ unguarded_exp exp ++
	  unguarded_opt (unguarded_valbind TG) valbind_opt
	| unguarded_valbind TG (DecGrammar.RECvalbind(_,valbind)) =
	  unguarded_valbind TG valbind

      and unguarded_exbind(DecGrammar.EXBIND(_,_,ty_opt,exbind_opt)) =
	  unguarded_opt unguarded_ty ty_opt ++
	  unguarded_opt unguarded_exbind exbind_opt
	| unguarded_exbind(DecGrammar.EXEQUAL(_,_,_,exbind_opt)) =
	  unguarded_opt unguarded_exbind exbind_opt

      and unguarded_atpat TG (DecGrammar.RECORDatpat(_,patrow_opt)) =
	  unguarded_opt (unguarded_patrow TG) patrow_opt
	| unguarded_atpat TG (DecGrammar.PARatpat(_,pat)) =
	  unguarded_pat TG pat
(*	| unguarded_atpat TG (DecGrammar.LONGIDatpat(_, DecGrammar.OP_OPT(longid, _))) =
            (case Ident.decompose longid  of
	       ([], id) => (case TG.lookup TG id  of
		                NONE => []
			      | SOME ty => unguarded_ty ty)
              | _ => [])    - Rowan 29jan01 *)
	| unguarded_atpat _ _ = []

      and unguarded_patrow TG (DecGrammar.DOTDOTDOT(_)) = []
	| unguarded_patrow TG (DecGrammar.PATROW(_,_,pat,patrow_opt)) =
	  unguarded_pat TG pat ++
	  unguarded_opt (unguarded_patrow TG) patrow_opt

      and unguarded_pat TG (DecGrammar.ATPATpat(_,atpat)) =
	  unguarded_atpat TG atpat
	| unguarded_pat TG (DecGrammar.CONSpat(_,_,atpat)) =
	  unguarded_atpat TG atpat
	| unguarded_pat TG (DecGrammar.TYPEDpat(_,pat,ty)) =
	  unguarded_pat TG pat ++ unguarded_ty ty
	| unguarded_pat TG (DecGrammar.SORTEDpat(_,pat,tys)) =
	  unguarded_pat TG pat ++ unguarded_list unguarded_ty tys
	| unguarded_pat TG (DecGrammar.LAYEREDpat(_,_,ty_opt,pat)) =
	  unguarded_opt unguarded_ty ty_opt ++
	  unguarded_pat TG pat
	| unguarded_pat TG (DecGrammar.UNRES_INFIXpat _) =
	    impossible "unguarded_pat(UNRES_INFIX)"

      and unguarded_ty(DecGrammar.TYVARty(_,tyvar)) =
	  [tyvar]
	| unguarded_ty(DecGrammar.RECORDty(_,tyrow_opt)) =
	  unguarded_opt unguarded_tyrow tyrow_opt
	| unguarded_ty(DecGrammar.CONty(_,ty_list,_)) =
	  foldl (fn (ty, tyvarset) => unguarded_ty ty ++ tyvarset)
	  [] ty_list
	| unguarded_ty(DecGrammar.INTERty(_,ty1,ty2)) =
	  unguarded_ty ty1 ++ unguarded_ty ty2
	| unguarded_ty(DecGrammar.FNty(_,ty1,ty2)) =
	  unguarded_ty ty1 ++ unguarded_ty ty2
	| unguarded_ty(DecGrammar.PARty(_,ty)) =
	  unguarded_ty ty

      and unguarded_tyrow(DecGrammar.TYROW(_,_,ty,tyrow_opt)) =
	  unguarded_ty ty ++
	  unguarded_opt unguarded_tyrow tyrow_opt
    in
      val unguarded_valbind = unguarded_valbind
    end

    (*The type of items associated with identifiers in a VarEnv is actually
     a slightly richer private type which, for each constructor, remembers
     the fellow constructors in its type. The usual lookup functions
     return an ordinary VE.range.*)
	
    datatype range_private = LONGVARpriv of TypeScheme
                           | LONGCONpriv of TypeScheme * id list
			   | LONGEXCONpriv of Type

    (*the types Context, Env, StrEnv, TyEnv, TyStr, and VarEnv, and
     some layout and report functions for them.*)

    datatype Context = CONTEXT of {U : ExplicitTyVarEnv,
				   E : Env}
	 and Env = ENV of {SE : StrEnv, TE : TyEnv, VE : VarEnv, TG : TyGoals}
	 and StrEnv = STRENV of (strid, Env) FinMap.map
	 and TyEnv = TYENV of (tycon, TyStr) FinMap.map
	 and TyStr = TYSTR of {theta : TypeFcn, VE : VarEnv}
	 and VarEnv = VARENV of (id, range_private) FinMap.map
	 and ExplicitTyVarEnv = EXPLICITTYVARENV of (ExplicitTyVar,Type) FinMap.map

    fun layoutSE (STRENV m) = 
      FinMap.layoutMap {start="", finish="",sep=", ", eq=" : "} 
      (fn s => StringTree.LEAF ("structure " ^ StrId.pr_StrId s)) layoutEnv m
(*
          let val l = FinMap.Fold (op ::) nil m

	  fun format_strid strid =
	        concat["structure ", StrId.pr_StrId strid, " : "]

	  fun layoutPair (strid,S) =
	        PP.NODE {start=format_strid strid,
			 finish="",
			 indent=3,
			 children=[layoutEnv S],
			 childsep=PP.NOSEP}
	  in
	    PP.NODE {start="", finish="", indent=0, children=map layoutPair l,
		     childsep=PP.RIGHT " "}
	  end
*)

    and layoutTE (TYENV m) = 
      FinMap.layoutMap {start="", finish="",sep=", ", eq=" : "} 
      (fn t => StringTree.LEAF ("tycon " ^ TyCon.pr_TyCon t)) layoutTystr m
(*
          let val l = FinMap.Fold (op ::) nil m

	  fun layoutPair (tycon, tystr) =
	        PP.NODE {start=TyCon.pr_TyCon tycon ^ ":",
			 finish="", indent=0, children=[layoutTystr tystr],
			 childsep=PP.NOSEP}
	  in
	    PP.NODE {start="type ", finish="", indent=0,
		     children=map layoutPair l, childsep=PP.RIGHT " "}
	  end
*)

    and layoutVE (VARENV m) =
          let 
	    fun layout_id id = 
	      (fn s => StringTree.LEAF (s ^ Ident.pr_id id))
	      (case FinMap.lookup m id 
		 of SOME(LONGVARpriv _) => "val " 
		  | SOME(LONGCONpriv _) => "con "
		  | SOME(LONGEXCONpriv _) => "excon "
		  | NONE => impossible "layoutVE.format_id>")
		  
	    fun layoutRng(LONGVARpriv sigma) = TypeScheme.layout sigma
	      | layoutRng(LONGCONpriv(sigma, _)) = TypeScheme.layout sigma
	      | layoutRng(LONGEXCONpriv tau) = Type.layout tau
	  in
	    FinMap.layoutMap {start="", finish="",sep=", ", eq=" : "} layout_id layoutRng m
	  end
(*
	  fun layoutPair(id, rng) = 
	        PP.NODE {start=format_id id ^ " ", finish="", indent=3,
			 children=[layoutRng rng], childsep = PP.NOSEP}
	  in
	    PP.NODE {start="", finish="", indent=0,
		     children=map layoutPair l, childsep=PP.RIGHT " "}
	  end
*)
    and layoutTystr (TYSTR {theta, VE}) =
          StringTree.NODE {start="(", finish=")", indent=0,
		   children=[TypeFcn.layout theta, layoutVE VE],
		   childsep=StringTree.RIGHT ", "}

    and layoutTG TG = TG.layout TG

    and layoutEnv (ENV{SE, TE, VE, TG}) =
          StringTree.NODE {start="{", finish="}", indent=1,
		   children=[layoutSE SE, layoutTE TE, layoutVE VE, layoutTG TG],
		   childsep = StringTree.NOSEP}

    infix // val op // = Report.//



    (* Restriction functions; the code given here is also used to
     * restrict compilation environments (CompilerEnv)
     *)

    local  
      fun proj0 (expl: 'a -> strid list * 'b) 
	(impl: strid list * 'b -> 'a) 
	(longids:'a list) 
	(strid:strid) : 'a list =
	let fun loop ([],acc) = acc
	      | loop (longid::longids,acc) = case expl longid
					       of ([],_) => loop(longids,acc)
						| (strid'::strids,id) => 
						 if strid=strid' then loop(longids, impl(strids,id)::acc)
						 else loop(longids,acc)
	in loop (longids, [])
	end

      fun qual0 (expl: 'a -> strid list * 'b) 
	(longids : 'a list)
	(acc: strid list) : strid list =
	let fun loop ([], acc) = acc
	      | loop (longid::longids,acc) =
               case expl longid
		 of ([],_) => loop(longids,acc)
		  | (strid::_,_) => 
		   let fun ins [] = [strid]
			 | ins (all as strid'::strids) = if strid = strid' then all
							 else if StrId.<(strid,strid') then strid::all
							      else strid'::ins(strids)
		   in loop(longids,ins acc)
		   end
	in loop(longids,acc)
	end

      fun ids0 (expl: 'a -> (strid list * 'b)) (longids: 'a list) : 'b list =
	foldl (fn (longid, acc) => case expl longid
				     of ([], id) => id::acc
				      | _ => acc) [] longids
	
      fun proj ({longstrids,longtycons,longvids}, strid) =
	{longstrids = proj0 StrId.explode_longstrid StrId.implode_longstrid longstrids strid,
	 longtycons = proj0 TyCon.explode_LongTyCon TyCon.implode_LongTyCon longtycons strid,
	 longvids = proj0 Ident.decompose Ident.implode_LongId longvids strid}
       
      fun qual {longstrids,longtycons,longvids} =
	qual0 StrId.explode_longstrid longstrids
	(qual0 TyCon.explode_LongTyCon longtycons
	 (qual0 Ident.decompose longvids []))

      fun ids {longstrids,longtycons,longvids} : {vids: id list, tycons: tycon list, strids: strid list} =
	{vids = ids0 Ident.decompose longvids,
	 tycons = ids0 TyCon.explode_LongTyCon longtycons,
	 strids = ids0 StrId.explode_longstrid longstrids}
       
      fun setminus (s, []) = s       (* setminus(A,B) = A \ B *)
	| setminus (s, (x::xs)) = 
	let fun rem [] = []
	      | rem (y::ys) = if y=x then rem ys
			      else y::rem ys
	in setminus(rem s,xs)
	end

      type longids = {longstrids: longstrid list, longtycons: longtycon list, longvids: longid list}     
	
      fun split longids : {vids: id list, tycons: tycon list, strids: strid list,
			   rest: (strid * longids) list} =
	let val {vids, strids, tycons} = ids longids
	    val qual = setminus(qual longids, strids) (* remove strids from qualifier strids; restriction 
						       * preserves environments under strids. *)
	in {vids=vids, tycons=tycons, strids=strids,
	    rest=map (fn strid => (strid, proj(longids, strid))) qual}
	end

    in (*local*)

      datatype restricter = Restr of {strids: (strid * restricter) list,
				      vids: id list, tycons: tycon list}
	                  | Whole
	
      fun create_restricter (longids:longids) : restricter =
	let val {vids, tycons, strids, rest} = split longids
	in Restr {strids=map (fn strid => (strid,Whole)) strids @
		         map (fn (strid,rest) => (strid, create_restricter rest)) rest,
		  vids=vids, tycons=tycons}
	end      

    end (*local*)


    (*Now a structure for each kind of environment:*)


    structure VE = struct
      (*The type of items associated with identifiers in a VarEnv:*)
      datatype range = LONGVAR   of TypeScheme
	             | LONGCON   of TypeScheme
                     | LONGEXCON of Type            (* MEMO: why LONGxxx? *)

      val empty : VarEnv = VARENV FinMap.empty
      val bogus = empty
      val singleton : id * range_private -> VarEnv =
	    VARENV o FinMap.singleton
      fun singleton_var (id : Ident.id, sigma : TypeScheme) : VarEnv =
            singleton (id, LONGVARpriv sigma)
      fun singleton_con (id : Ident.id, sigma : TypeScheme, ids : id list)
            : VarEnv = singleton (id, LONGCONpriv (sigma, ids))
      fun singleton_excon (id : Ident.id, tau : Type) : VarEnv =
            singleton (id, LONGEXCONpriv tau)
      val add : VarEnv -> id -> range_private -> VarEnv =
	    fn VARENV v => fn id => fn range_private =>
	         VARENV (FinMap.add (id,range_private,v))
      fun plus (VARENV v, VARENV v') : VarEnv = 
	    VARENV (FinMap.plus (v, v'))
      fun range_private_to_range (LONGVARpriv sigma) = LONGVAR sigma
	| range_private_to_range (LONGCONpriv(sigma, _)) = LONGCON sigma
	| range_private_to_range (LONGEXCONpriv tau) = LONGEXCON tau
      fun lookup (VARENV v) id : range option =
            map_opt range_private_to_range (FinMap.lookup v id)
      fun dom (VARENV m) = FinMap.dom m
      fun is_empty (VARENV v) = FinMap.isEmpty v
      fun map (f : range_private -> range_private) (VARENV m) : VarEnv =
	    VARENV(FinMap.composemap f m)
      fun eq (VARENV v1, VARENV v2) : bool =
	    let val finmap_to_sorted_alist =
		      ListSort.sort
		        (fn (id1, _) => fn (id2, _) => Ident.< (id1,id2))
		      o FinMap.list
		val alist1 = finmap_to_sorted_alist v1
		val alist2 = finmap_to_sorted_alist v2
	    in
	      foldl
	        (fn (((id1, LONGCONpriv (sigma1, ids1)),
		     (id2, LONGCONpriv (sigma2, ids2))),
		     bool) =>
		      bool andalso
		      id1 = id2 andalso
		      TypeScheme.eq (sigma1,sigma2)
		   | _ => impossible "VE.eq: VE contains non-constructors")
		  true (ListPair.zip (alist1, alist2))
		  handle ListPair.Zip => false
	    end
      fun fold (f : range -> 'a -> 'a)
      	       (start : 'a)
	       (VARENV map) : 'a = 
	    FinMap.fold
	      (fn (range, a) => f (range_private_to_range range) a)
	        start map

      fun size (VARENV v1) : int = FinMap.fold (fn (_, a) => a + 1) 0 v1

      fun FoldPRIVATE (f : id * range_private -> 'a -> 'a)
      		      (start : 'a) (VARENV map) : 'a =
		        FinMap.Fold (uncurry f) start map
      fun Fold (f :   id * range -> 'a  -> 'a)
      	       (start : 'a)
	       (VARENV map) : 'a = 
	    FinMap.Fold (fn ((id, range), a) =>
			      f (id, range_private_to_range range) a)
	      start map

      fun apply (f : (id * range -> unit)) (VARENV map) : unit = 
	    List.app
	       (fn (id, range_private) =>
		      f (id, range_private_to_range range_private))
	          (FinMap.list map)

      (*CEfold f a VE = will crash if there is anything else than
       constructors in VE; fold f over the constructors in VE.  CEFold
       is similar*)

      fun CEfold (f : TypeScheme -> 'a -> 'a) : 'a -> VarEnv -> 'a =
	    fold
	      (fn range => fn a' =>
	       (case range of
		  LONGCON sigma => f sigma a'
		| _ => impossible "CEfold: VE contains non-constructors"))
      fun CEFold (f : id * TypeScheme -> 'a -> 'a) : 'a -> VarEnv -> 'a =
            Fold
	      (fn (id,range) => fn a =>
	       (case range of
		  LONGCON sigma => f (id,sigma) a
		| _ => impossible "CEFold: VE contains non-constructors"))
	    
      fun close (VE : VarEnv) : VarEnv =
	    FoldPRIVATE
	      (fn (id, range_private) => fn VE =>
	             add VE id
		       (case range_private of
			  LONGVARpriv sigma => LONGVARpriv (TypeScheme.close true sigma)
			| LONGCONpriv (sigma, ids) => LONGCONpriv (TypeScheme.close true sigma, ids)
			| LONGEXCONpriv tau => LONGEXCONpriv tau))
	         empty VE

      fun lookup_fellow_constructors (VARENV v) id : id list option =
	    (case FinMap.lookup v id of
	       SOME (LONGCONpriv(sigma, ids)) => SOME ids
	     | _ => NONE)

      fun on (S : Substitution, VE as VARENV m) : VarEnv = VE

      fun restrict (VARENV m,ids) =
	    VARENV (foldl
		      (fn (id, m_new) =>
		       let val r = case FinMap.lookup m id
				     of SOME r => r
				      | NONE => impossible ("VE.restrict: cannot find id " ^ Ident.pr_id id)
		       in FinMap.add(id,r,m_new)
		       end) FinMap.empty ids)

      (* Matching *)
      local
	fun match_scheme a = StatObject.TypeScheme.match a
	fun match_type a = StatObject.Type.match a

	fun match_range (LONGVAR sigma1, LONGVAR sigma2) = match_scheme (sigma1, sigma2)
	  | match_range (LONGCON sigma1, LONGCON sigma2) = match_scheme (sigma1, sigma2)
	  | match_range (LONGEXCON tau1, LONGEXCON tau2) = match_type (tau1, tau2)
	  | match_range _ = ()
      in
	fun match (VE,VE0) = Fold (fn (id,r) => fn () =>
				   (case lookup VE0 id 
				      of SOME r0 => match_range (r,r0)
				       | NONE => ())) () VE
      end

      fun report (f, VARENV m) =
	    FinMap.reportMapSORTED (Ident.<)
	      (fn (id, range_private) =>
	            f (id, range_private_to_range range_private)) m
      val layout = layoutVE
      fun tyvars_in_range (LONGVAR sigma) = TypeScheme.tyvars sigma
	| tyvars_in_range (LONGCON sigma) = TypeScheme.tyvars sigma
	| tyvars_in_range (LONGEXCON tau) = Type.tyvars tau
      val tyvars =
	      fold
		(fn range => fn T =>
		       unionTyVarSet (T, tyvars_in_range range))
		   []
      val tyvars' =
	      Fold
		(fn (id, range) => fn criminals =>
		       (case tyvars_in_range range of
			  [] => criminals
			| tyvars => (id, tyvars) :: criminals))
		    []
      fun tynames_in_range (LONGVAR sigma) = TypeScheme.tynames sigma
	| tynames_in_range (LONGCON sigma) = TypeScheme.tynames sigma
	| tynames_in_range (LONGEXCON tau) = Type.tynames tau

      val tynames = fold (TyName.Set.union o tynames_in_range) TyName.Set.empty

      fun ids_with_tyvar_in_type_scheme VE tyvar =
	    Fold (fn (id, range) => fn ids =>
		  if memberTyVarSet tyvar (tyvars_in_range range) then id :: ids
		  else ids) [] VE

    end (*VE*)




    (*Type structures*)

    structure TyStr = struct
      fun from_theta_and_VE (theta : TypeFcn, VE : VarEnv) : TyStr =
	    TYSTR {theta = theta, VE = VE}
      fun to_theta_and_VE (TYSTR {theta, VE}) : TypeFcn * VarEnv = (theta, VE)
      fun to_theta (TYSTR {theta, VE}) : TypeFcn = theta
      fun to_VE (TYSTR {theta, VE}) : VarEnv = VE
      fun eq (TYSTR {theta,VE}, TYSTR {theta=theta',VE=VE'}) =
	    TypeFcn.eq (theta,theta') andalso VE.eq (VE,VE')
      fun shares (TYSTR {theta=theta1, ...},
		  TYSTR {theta=theta2, ...}) : bool =
	    TypeFcn.eq (theta1,theta2)
      fun tynames (TYSTR {theta, VE}) =
	    TyName.Set.union (TypeFcn.tynames theta) (VE.tynames VE)
      val layout = layoutTystr

      (* Matching *)
      local 
	fun match_theta a = TypeFcn.match a
      in
	fun match (TYSTR{theta,VE}, TYSTR{theta=theta0,VE=VE0}) =
	  (match_theta(theta,theta0);
	   VE.match(VE,VE0))
      end
    end (*TyStr*)



    (*Type environments*)

    structure TE = struct 
      val empty : TyEnv = TYENV FinMap.empty
      val bogus = empty
      val singleton : tycon * TyStr -> TyEnv = TYENV o FinMap.singleton
      fun plus (TYENV t, TYENV t') : TyEnv = TYENV (FinMap.plus (t, t'))
      fun lookup (TYENV m) tycon : TyStr option = FinMap.lookup m tycon
      fun dom (TYENV map) = FinMap.dom map
      fun map (f : TyStr -> TyStr) (TYENV m) : TyEnv =
	    TYENV (FinMap.composemap f m)
      fun fold (f : TyStr -> 'a -> 'a) (start : 'a) (TYENV map) : 'a = 
	    FinMap.fold (uncurry f) start map
      fun Fold (f : tycon * TyStr -> 'a -> 'a) (start : 'a) (TYENV map)
	    : 'a = FinMap.Fold (uncurry f) start map
      fun apply (f : (tycon * TyStr -> unit)) (TYENV map) : unit = 
	    List.app f (FinMap.list map)
      fun size (TYENV v1) : int = FinMap.fold (fn (_, a) => a + 1) 0 v1

      (*equality_maximising_realisation TE = a realisation that maps all
       tynames in TE that have been found to respect equality to fresh
       tynames that admit equality.  equality_maximising_realisation is
       only used by maximise_equality below.  It works by first finding
       the set T of tynames that are tynames of datatypes that do not
       already admit equality (tynames_of_nonequality_datatypes).
       iterate then removes from T those tynames that do not respect
       equality, assuming all in T respect equality.  This is iterated
       until T does not change.  generate then makes a realisation from
       T.*)

      local
	fun tynames_of_nonequality_datatypes (TE : TyEnv) : TyName.Set.Set =
	      fold (fn TYSTR {theta, VE} => fn T =>
		          if VE.is_empty VE then T else
			  let val tyname =
			            noSome (TypeFcn.to_TyName theta)
				      "tynames_of_nonequality_datatypes"
			  in
			    if TyName.equality tyname then T
			    else TyName.Set.insert tyname T
			  end)
	               TyName.Set.empty TE

        fun iterate T TE =
	      let val T' = fold remove_a_tyname_maybe T TE
	      in
		if TyName.Set.eq T T' then T else iterate T' TE
	      end

	and remove_a_tyname_maybe (TYSTR {theta, VE}) T =
	      if VE.is_empty VE then T else
	      let val violates_equality =
		        VE.CEfold
			  (fn sigma => fn bool => 
			   TypeScheme.violates_equality T sigma orelse bool)
			       false VE
		  val tyname = noSome (TypeFcn.to_TyName theta)
			         "remove_a_tyname_maybe"
	      in
		if violates_equality then TyName.Set.remove tyname T
		else T
	      end

	(*generate T = a realisation that maps each t in T to a fresh t'
	 that admits equality*)

	fun generate (T : TyName.Set.Set) : realisation =
	      TyName.Set.fold
	        (fn tyname => fn phi => Realisation.oo (phi, generate0 tyname))
		  Realisation.Id T
	and generate0 tyname =
	      (if !Flags.DEBUG_TYPES then TextIO.output (TextIO.stdOut,"generate0\n")
	       else () ;
	       Realisation.singleton
	         (tyname, TypeFcn.from_TyName
		           (TyName.freshTyName
			     {tycon = TyName.tycon tyname,
			      arity = TyName.arity tyname, equality = true})))
      in
        fun equality_maximising_realisation (TE : TyEnv) : realisation =
	      generate (iterate (tynames_of_nonequality_datatypes TE) TE)
      end (*local*)    

      fun init' explicittyvars tycon =
	let val tyname = TyName.freshTyName {tycon=tycon, arity=List.length explicittyvars, equality=false}
	    val TE = singleton (tycon, TyStr.from_theta_and_VE (TypeFcn.from_TyName tyname, VE.empty))
	in (tyname, TE)
	end

      fun init explicittyvars tycon = #2 (init' explicittyvars tycon)

      val tynames = fold (TyName.Set.union o TyStr.tynames) TyName.Set.empty

      (* Restriction *)
      fun restrict (TE,tycons) = 
	foldl (fn (tycon, TEnew) =>
		    let val TyStr = (case lookup TE tycon 
				       of SOME TyStr => TyStr
					| NONE => impossible "TE.restrict: tycon not in env.")
		    in plus (TEnew, singleton (tycon,TyStr))
		    end) empty tycons

      (* Matching *)
      fun match (TE,TE0) = Fold (fn (tycon, TyStr) => fn () =>
				 (case lookup TE0 tycon 
				    of SOME TyStr0 => TyStr.match(TyStr,TyStr0)
				     | NONE => ())) () TE

      (*For the TE: report TyStrs with empty ConEnv as

	  type (tvs) ty

	and those with nonempty ConEnv as

	  datatype (tvs) ty
	    con C1 : tyscheme
	    con C2 : tyscheme

	This is a reasonable syntax for TE's both in bindings and in specs.
	(saying `type' for `datatype' wouldn't look too good in specs.)*)

      local
	fun reportCE (VARENV v) =
	      FinMap.reportMapSORTED
		Ident.<
		  (fn (id, range_private) =>
			(case range_private of
			   LONGCONpriv (sigma, ids) =>
			     Report.line ("con " ^ Ident.pr_id id ^ " : "
					  ^ TypeScheme.pretty_string
					      (StatObject.newTVNames ()) sigma)
			 | _ => impossible "reportCE"))
		    v
      in
	fun report {tyEnv=TYENV map, bindings} =
	      FinMap.reportMapSORTED
		TyCon.<
		  (fn (tycon, TYSTR {theta, VE as (VARENV v)}) =>
		   let
		     val names = StatObject.newTVNames()
		     val {vars, body} =
			     TypeFcn.pretty_string names theta
		     val vars' = (case vars of "" => "" | _ => vars ^ " ")
		   in
		     Report.line
		       (if FinMap.isEmpty v then
			  "type " ^ vars' ^ TyCon.pr_TyCon tycon
			  ^ (if bindings then " = " ^ body else "")
			else
			  "datatype " ^ vars' ^ TyCon.pr_TyCon tycon)
		     // Report.indent(2, reportCE VE)
		   end)
		     map
      end (*local*)
      val layout = layoutTE
    end (*TE*)

    structure SE = struct
      val empty : StrEnv = STRENV FinMap.empty
      val singleton : strid * Env -> StrEnv = STRENV o FinMap.singleton
      fun plus (STRENV s, STRENV s') : StrEnv =
	    STRENV(FinMap.plus(s, s'))
      fun lookup (STRENV map) (strid : strid) : Env option =
	    FinMap.lookup map strid
      fun dom (STRENV map) = FinMap.dom map
      fun is_empty (STRENV m) = FinMap.isEmpty m
      fun fold (f : Env -> 'a -> 'a) (start : 'a) (STRENV map) : 'a = 
	    FinMap.fold (uncurry f) start map
      fun Fold (f : strid * Env -> 'a -> 'a) (start : 'a) (STRENV map) : 'a = 
	    FinMap.Fold (uncurry f) start map
      fun apply (f : strid * Env -> unit) (STRENV map) : unit = 
	    List.app f (FinMap.list map)
      fun map (f : Env -> Env) (STRENV map) =
	    STRENV (FinMap.composemap f map)
      fun report (f, STRENV m) = FinMap.reportMapSORTED (StrId.<) f m

      fun size (STRENV v1) : int = FinMap.fold (fn (_, a) => a + 1) 0 v1

      (*since SE.tyvars and E.tyvars are mutually recursive, E.tyvars is defined
       in structure SE rather than structure E.  Similarly with tynames:*)
      fun E_tyvars (ENV {SE, VE, ...}) = unionTyVarSet (VE.tyvars VE, tyvars SE)
      and tyvars SE =
	    fold (fn E => fn tyvars => unionTyVarSet (tyvars, E_tyvars E))
		  [] SE
      fun E_tyvars' (ENV {SE, VE, ...}) = VE.tyvars' VE @ tyvars' SE
      and tyvars' SE =
	    fold (fn E => fn criminals => E_tyvars' E @ criminals) [] SE
      fun tynames SE =
	    fold (fn E => fn T => TyName.Set.union (E_tynames E) T)
	            TyName.Set.empty SE
      and E_tynames (ENV {VE, TE, SE, TG}) =
	      TyName.Set.union (tynames SE)
		(TyName.Set.union (VE.tynames VE) (TE.tynames TE))
      val layout = layoutSE
    end (*SE*)



    structure E = struct
      fun mk (SE, TE, VE) : Env = ENV {SE=SE, TE=TE, VE=VE, TG=TG.empty}  (* ignore TG here? *)
      fun un (ENV {SE, TE, VE, ...}) = (SE, TE, VE)
      fun from_VE_and_TE (VE, TE) = ENV {SE=SE.empty, TE=TE, VE=VE, TG=TG.empty}
      fun from_VE VE = ENV {SE=SE.empty, TE=TE.empty, VE=VE, TG=TG.empty}
      fun to_VE (ENV {VE, ...}) = VE
      fun from_TE TE = ENV {SE=SE.empty, TE=TE, VE=VE.empty, TG=TG.empty}
      fun to_TE (ENV {TE, ...}) = TE
      fun from_TG TG = ENV {SE=SE.empty, TE=TE.empty, VE=VE.empty, TG=TG}
      fun to_TG (ENV {TG, ...}) = TG
      fun from_SE SE = ENV {SE=SE, TE=TE.empty, VE=VE.empty, TG=TG.empty}
      fun to_SE (ENV {SE, ...}) = SE
      fun erase_TG (ENV {SE, TE, VE, TG}) = ENV {SE=SE, TE=TE, VE=VE, TG=TG.empty}
      fun plus (ENV {SE, TE, VE, TG}, ENV {SE=SE', TE=TE', VE=VE', TG=TG'}) =
	    ENV {SE = SE.plus (SE, SE'), TE = TE.plus (TE, TE'),
		 VE = VE.plus (VE, VE'), TG = TG.plus (TG, TG')}
      fun lookup_tycon (ENV {TE, ...}) tycon : TyStr option =
	    TE.lookup TE tycon
      fun lookup_strid (ENV {SE, ...}) strid : Env option =
	    SE.lookup SE strid
      fun lookup_strids E [] = SOME E
	| lookup_strids E (strid :: rest) =
	    (case lookup_strid E strid of
	       SOME E' => lookup_strids E' rest
	     | NONE => NONE)
      fun Rea_from_ToRea_elt TE (tycon, tyname) =   (* used in lookup_tygoal *)
	  case TE.lookup TE tycon of NONE => raise Match
             | SOME tystr => Realisation.singleton (tyname, TyStr.to_theta tystr)
      fun lookup_tygoal (ENV {TG, TE, ...}) id = 
	  case TG.lookup TG id of NONE => NONE
             | SOME (ToRealise, tyscheme) => 
		(* lookup each in ToRealise and subst, raise Match if not found *)
                SOME (Realisation.on_TypeScheme
		        (FinMap.fold Realisation.oo Realisation.Id 
		                     (FinMap.ComposeMap (Rea_from_ToRea_elt TE) ToRealise)  )
		        tyscheme  )

      (*`lookup_longsomething to_TE TE.lookup E ([strid1,strid2], tycon)'
       will look up `strid1.strid2.tycon'
       (or is it `strid2.strid1.tycon'?) in E:*)
      fun lookup_longsomething projection lookup E (strids, something) =
	    (case lookup_strids E strids of
	       NONE => NONE
	     | SOME E' => lookup (projection E') something)
      fun lookup_longid E longid = 
	    lookup_longsomething to_VE VE.lookup E (Ident.decompose longid)
      fun lookup_fellow_constructors E longid =
	    noSome (lookup_longsomething to_VE VE.lookup_fellow_constructors
		      E (Ident.decompose longid))
	      "lookup_fellow_constructors"
      fun lookup_longtycon E longtycon =
	    lookup_longsomething to_TE TE.lookup E
	      (TyCon.explode_LongTyCon longtycon)
      fun lookup_longstrid E longstrid =
	    lookup_longsomething to_SE SE.lookup E
	      (StrId.explode_longstrid longstrid)
      (*on: Note that only VE contains free type variables:*)
      fun on (S, ENV {SE, TE, VE, TG}) = ENV {SE=SE, TE=TE, VE=VE.on (S, VE), TG=TG}
      val empty = ENV {SE=SE.empty, TE=TE.empty, VE=VE.empty, TG=TG.empty}
      val bogus = empty
      val tyvars = SE.E_tyvars
      val tyvars' = SE.E_tyvars'
      val tynames = SE.E_tynames
      val layout = layoutEnv

      (*The following boring code builds the initial environment built-in
       types (`->', `int', `real', `string', `exn', `ref'), the constructor
       `ref', and the value `prim'. `prim' has type 'a -> 'b.  Moreover the
       overloaded values must be in the initial environment and therefore
       also the type `bool'.*)

      local
	fun mk_tystr (tyname, VE) =
	      TyStr.from_theta_and_VE
	        (TypeFcn.from_TyName tyname, VE)

	fun te (tycon, tyname) =
	      TE.singleton (tycon, mk_tystr(tyname, VE.empty))

	fun joinTE [] = TE.empty
	  | joinTE (TE :: rest) = TE.plus (TE, joinTE rest)

	val TE_int = te (TyCon.tycon_INT, TyName.tyName_INT)
	val TE_char = te (TyCon.tycon_CHAR, TyName.tyName_CHAR)
	val TE_word = te (TyCon.tycon_WORD, TyName.tyName_WORD)
	val TE_word8 = te (TyCon.tycon_WORD8, TyName.tyName_WORD8)
	val TE_real = te (TyCon.tycon_REAL, TyName.tyName_REAL)
	val TE_string = te (TyCon.tycon_STRING, TyName.tyName_STRING)
	val TE_exn = te (TyCon.tycon_EXN, TyName.tyName_EXN)

	val boolVE =
	      VE.plus (VE.singleton_con (Ident.id_TRUE, 
					 TypeScheme.from_Type Type.Bool,
					 [Ident.id_FALSE, Ident.id_TRUE]),
	               VE.singleton_con (Ident.id_FALSE,
					 TypeScheme.from_Type Type.Bool,
					 [Ident.id_FALSE, Ident.id_TRUE]))
	val TE_bool = TE.singleton (TyCon.tycon_BOOL,
				   mk_tystr (TyName.tyName_BOOL,
					     VE.close boolVE))

	(* constructor environments for ref type constructor *)

	local
	  val _ = Level.push()

	  val alpha = TyVar.fresh_normal ()
	  val alphaTy = Type.from_TyVar alpha

	  val refTy =
	        Type.mk_Arrow (alphaTy, Type.mk_Ref alphaTy)

	  val beta = TyVar.fresh_normal ()
	  val betaTy = Type.from_TyVar beta

	  val refTy_to_TE =
	        Type.mk_Arrow (betaTy, Type.mk_Ref betaTy)

	  val _ = Level.pop()
	in
	  val refVE = VE.singleton_con (Ident.id_REF,
					TypeScheme.from_Type refTy,
					[Ident.id_REF])
	  val refVE_to_TE = VE.singleton_con (Ident.id_REF, 
					      TypeScheme.from_Type
					        refTy_to_TE,
					      [Ident.id_REF])
	end

		 (* environments for list type constructor *)
	local
	  val _ = Level.push()

		 (* nil *)
	  val alpha1 = TyVar.fresh_normal ()
	  val alphaTy = Type.from_TyVar alpha1

	  val listTy =
		Type.from_ConsType
		  (Type.mk_ConsType ([alphaTy],TyName.tyName_LIST))

	  val nilVE = VE.singleton_con (Ident.id_NIL,
					TypeScheme.from_Type listTy,
					[Ident.id_CONS, Ident.id_NIL])

		 (* cons *)
	  val alpha1 = TyVar.fresh_normal ()

	  val alphaTy = Type.from_TyVar alpha1
	  val listTy = 
		Type.from_ConsType
		  (Type.mk_ConsType ([alphaTy],TyName.tyName_LIST))
	  val consTy = 
		Type.mk_Arrow
		  (Type.from_pair (alphaTy,listTy) , listTy)
	  val consVE = VE.singleton_con (Ident.id_CONS,
					 TypeScheme.from_Type consTy,
					 [Ident.id_CONS, Ident.id_NIL])
	  val listVE = VE.plus (consVE, nilVE)

	  (*Now the above bindings are repeated, to get fresh
	   variants of type schemes for cons and nil, for TE*)

		 (* nil *)
	  val alpha1 = TyVar.fresh_normal ()

	  val alphaTy = Type.from_TyVar alpha1

	  val listTy =
		Type.from_ConsType
		  (Type.mk_ConsType ([alphaTy],TyName.tyName_LIST))

	  val nilVE = VE.singleton_con (Ident.id_NIL,
					TypeScheme.from_Type listTy,
					[Ident.id_CONS, Ident.id_NIL])

		 (* cons *)
	  val alpha1 = TyVar.fresh_normal ()
	  val alphaTy = Type.from_TyVar alpha1
	  val listTy = 
		Type.from_ConsType
		  (Type.mk_ConsType ([alphaTy],TyName.tyName_LIST))
	  val consTy = 
		Type.mk_Arrow
		  (Type.from_pair (alphaTy,listTy) , listTy)
	  val consVE = VE.singleton_con (Ident.id_CONS,
					 TypeScheme.from_Type consTy,
					 [Ident.id_CONS, Ident.id_NIL])

	  val listVE_for_TE = VE.plus (consVE, nilVE)

	  val _ = Level.pop()
	in
	  val TE_list = TE.singleton (TyCon.tycon_LIST,
				     mk_tystr (TyName.tyName_LIST,
					       VE.close listVE_for_TE))
	  val listVE = listVE
	end

	       (* overloaded functions *)
	local
	  val _ = Level.push()
	  val alpha = TyVar.fresh_normal ()
	  val alphaTy = Type.from_TyVar alpha

	  val beta = TyVar.fresh_normal ()
	  val betaTy = Type.from_TyVar beta

	  val tau_alpha_to_beta = Type.mk_Arrow
			 (Type.from_triple (Type.String, Type.String, alphaTy), betaTy)

	  val sigma_alpha_to_beta = TypeScheme.from_Type tau_alpha_to_beta

	  val tyvar_num = TyVar.fresh_overloaded [TyName.tyName_INT,
						  TyName.tyName_WORD,
						  TyName.tyName_WORD8,
						  TyName.tyName_REAL]
	  val tau_num = Type.from_TyVar tyvar_num

	  val tau_num_X_num_to_num =
		Type.mk_Arrow (Type.from_pair (tau_num, tau_num), tau_num)

	  val tyvar_realint =
	        TyVar.fresh_overloaded [TyName.tyName_REAL, TyName.tyName_INT]
	  val tau_realint = Type.from_TyVar tyvar_realint

	  val tau_realint_to_realint = Type.mk_Arrow (tau_realint, tau_realint)

	  val tyvar_numtxt = TyVar.fresh_overloaded 
				[TyName.tyName_INT, TyName.tyName_WORD, TyName.tyName_WORD8,
				 TyName.tyName_REAL, TyName.tyName_CHAR,
				 TyName.tyName_STRING]
	  val tau_numtxt = Type.from_TyVar tyvar_numtxt
	  val tau_numtxt_X_numtxt_to_bool =
		Type.mk_Arrow (Type.from_pair (tau_numtxt, tau_numtxt),
			       Type.Bool)

	  val tyvar_wordint = TyVar.fresh_overloaded [TyName.tyName_INT,
						      TyName.tyName_WORD, TyName.tyName_WORD8]
	  val tau_wordint = Type.from_TyVar tyvar_wordint
	  val tau_wordint_X_wordint_to_wordint =
	        Type.mk_Arrow (Type.from_pair (tau_wordint, tau_wordint),
			       tau_wordint)

	  val _ = Level.pop()

	  (*overloaded types manually closed, to ensure closing of overloaded 
	   type variable:*)

	  val sigma_num_X_num_to_num = TypeScheme.close_overload tau_num_X_num_to_num
	  val sigma_realint_to_realint = TypeScheme.close_overload tau_realint_to_realint
	  val sigma_numtxt_X_numtxt_to_bool = TypeScheme.close_overload tau_numtxt_X_numtxt_to_bool
	  val sigma_wordint_X_wordint_to_wordint = TypeScheme.close_overload tau_wordint_X_wordint_to_wordint

	in
	  val primVE      = VE.singleton (Ident.id_PRIM,
					  LONGVARpriv sigma_alpha_to_beta)
	  val absVE       = VE.singleton (Ident.id_ABS, 
					  LONGVARpriv sigma_realint_to_realint)
	  val negVE       = VE.singleton (Ident.id_NEG,
					  LONGVARpriv sigma_realint_to_realint)
	  val divVE       = VE.singleton (Ident.id_DIV,
					  LONGVARpriv sigma_wordint_X_wordint_to_wordint)
	  val modVE       = VE.singleton (Ident.id_MOD,
					  LONGVARpriv sigma_wordint_X_wordint_to_wordint)
	  val plusVE      = VE.singleton (Ident.id_PLUS, 
					  LONGVARpriv sigma_num_X_num_to_num)
	  val minusVE     = VE.singleton (Ident.id_MINUS,
					  LONGVARpriv sigma_num_X_num_to_num)
	  val mulVE       = VE.singleton (Ident.id_MUL, 
					  LONGVARpriv sigma_num_X_num_to_num)
	  val lessVE      = VE.singleton (Ident.id_LESS, 
					  LONGVARpriv sigma_numtxt_X_numtxt_to_bool)
	  val greaterVE   = VE.singleton (Ident.id_GREATER, 
					  LONGVARpriv sigma_numtxt_X_numtxt_to_bool)
	  val lesseqVE    = VE.singleton (Ident.id_LESSEQ, 
					  LONGVARpriv sigma_numtxt_X_numtxt_to_bool)
	  val greatereqVE = VE.singleton (Ident.id_GREATEREQ, 
					  LONGVARpriv sigma_numtxt_X_numtxt_to_bool)

	  val DivVE       = VE.singleton (Ident.id_Div, LONGEXCONpriv Type.Exn)
	  val BindVE      = VE.singleton (Ident.id_Bind, LONGEXCONpriv Type.Exn)
	  val MatchVE     = VE.singleton (Ident.id_Match, LONGEXCONpriv Type.Exn)
	  val OverflowVE  = VE.singleton (Ident.id_Overflow, LONGEXCONpriv Type.Exn)

	  fun joinVE [] = VE.empty
	    | joinVE (VE :: rest) = VE.plus (VE, joinVE rest)
	end

	val TE_ref = TE.singleton (TyCon.tycon_REF,
				  mk_tystr (TyName.tyName_REF, VE.close refVE_to_TE))

	local   (* initial TE for unit *)
	  val theta_unit = TypeFcn.from_TyVars_and_Type ([], Type.Unit)
	  val VE_unit = VE.empty
	in
	  val TE_unit = TE.singleton (TyCon.tycon_UNIT,
				      TyStr.from_theta_and_VE (theta_unit, VE_unit))
	end

	val TE_word_table = te (TyCon.tycon_WORD_TABLE, TyName.tyName_WORD_TABLE)

	val TE_initial = joinTE [TE_unit, TE_int, TE_real,
				 TE_word, TE_word8, TE_char, 
				 TE_string, TE_exn, TE_ref, TE_bool, TE_list,
				 TE_word_table]
	local 
	  fun mk_sigma() = (*construct the type scheme: forall 'a.'a->unit*)
	    let val _ = Level.push()
		val alpha = TyVar.fresh_normal ()
		val alphaTy = Type.from_TyVar alpha
		val arrowType = Type.mk_Arrow (alphaTy, Type.Unit)
		val _ = Level.pop()
	    in 
	      TypeScheme.close_overload arrowType
	    end
	in 
	  val resetRegionsVE =  (* resetRegions: forall 'a . 'a -> unit *)
		  VE.singleton (Ident.resetRegions,LONGVARpriv (mk_sigma()))
	  val forceResettingVE = (* forceResetting: forall 'a . 'a -> unit *)
		  VE.singleton (Ident.forceResetting, LONGVARpriv (mk_sigma()))
	end

	(*notice VE.close must be applied outside the Level.push and Level.pop
	 calls:*)
	val VE_initial =
	      joinVE [VE.close refVE, VE.close boolVE, VE.close listVE,
		      VE.close primVE,
		      absVE, negVE, divVE, modVE, plusVE, minusVE, mulVE,
		      lessVE, greaterVE, lesseqVE, greatereqVE,
		      resetRegionsVE, forceResettingVE, DivVE, 
		      BindVE, MatchVE, OverflowVE]
      in
	val initial = ENV {SE=SE.empty, TE=TE_initial, VE=VE_initial, TG=TG.empty}
      end


      (* Support for recompilation *)

      fun equal_VarEnvRan (VE.LONGVAR s1, VE.LONGVAR s2) =
	    StatObject.TypeScheme.eq (s1,s2)
	| equal_VarEnvRan (VE.LONGCON s1, VE.LONGCON s2) =
	    StatObject.TypeScheme.eq (s1,s2)
	| equal_VarEnvRan (VE.LONGEXCON t1, VE.LONGEXCON t2) =
	    StatObject.Type.eq (t1,t2)
	| equal_VarEnvRan _ = false

      fun enrich_TyEnv (TE1,TE2) =
	    TE.Fold (fn (tycon2, TyStr2) => fn b => b andalso
		     case TE.lookup TE1 tycon2 of
		       SOME TyStr1 => TyStr.eq (TyStr1,TyStr2)
		     | NONE => false) true TE2

      fun enrich_VarEnv(VE1,VE2) =
	VE.Fold (fn (id2,r2) => fn b => b andalso
		 case VE.lookup VE1 id2 
		   of SOME r1 => equal_VarEnvRan(r1,r2)
		    | NONE => false) true VE2

      fun enrich_Env(E1,E2) =
	case (un E1, un E2)
	  of ((SE1, TE1, VE1), (SE2, TE2, VE2)) =>
	   enrich_StrEnv(SE1,SE2) andalso enrich_TyEnv(TE1,TE2) andalso 
	   enrich_VarEnv(VE1,VE2)

      and enrich_StrEnv(SE1,SE2) = SE.Fold (fn (strid2,S2) => fn b => b andalso
					    case SE.lookup SE1 strid2 
					      of SOME S1 => enrich_Env(S1,S2)
					       | NONE => false) true SE2

      fun equal_TyEnv(TE1,TE2) = TE.size TE1 = TE.size TE2 andalso enrich_TyEnv (TE1,TE2)
      fun equal_VarEnv(VE1,VE2) = VE.size VE1 = VE.size VE2 andalso enrich_VarEnv(VE1,VE2)

      fun equal_Env(E1,E2) =
	case (un E1, un E2)
	  of ((SE1, TE1, VE1), (SE2, TE2, VE2)) =>
	    equal_StrEnv(SE1,SE2) andalso equal_TyEnv(TE1,TE2) andalso 
	    equal_VarEnv(VE1,VE2)

      and equal_StrEnv(SE1,SE2) = SE.size SE1 = SE.size SE2 andalso  (* note: you cannot use enrich_StrEnv *)  
	SE.Fold (fn (strid2,S2) => fn b => b andalso
		 case SE.lookup SE1 strid2 
		   of SOME S1 => equal_Env(S1,S2)
		    | NONE => false) true SE2

      val enrich = enrich_Env
      val eq = equal_Env


      (* Restriction *)
      local
	fun restr_E(E,Whole) = E
	  | restr_E(E,Restr{strids,vids,tycons}) =
	  let val (SE,TE,VE) = un E
  	      val SE' = foldl (fn ((strid,restr), SEnew) =>
				    let val E = (case SE.lookup SE strid 
						   of SOME E => restr_E(E,restr)
						    | NONE => impossible "restrictE: strid not in env.")
				    in SE.plus (SEnew, SE.singleton (strid,E))
				    end) SE.empty strids
 	      val TE' = TE.restrict (TE, tycons)
	      val VE' = VE.restrict (VE, vids)
	  in mk (SE',TE',VE')
	  end
      in
	fun restrict(E,longids) = restr_E(E,create_restricter longids)
      end

      (* Matching*)

      fun match (E,E0) =
	let val (SE, TE, VE)  = un E
	    val (SE0,TE0,VE0) = un E0
	in
	  matchSE (SE, SE0) ; 
	  TE.match (TE, TE0) ;
	  VE.match (VE, VE0)
	end

      and matchSE (SE,SE0) = SE.Fold (fn (strid,E) => fn () => (case SE.lookup SE0 strid 
								  of SOME E0 => match (E,E0)
								   | NONE => ())) () SE
    end (* E *)




    structure C = struct
      (*ExplicitTyVarEnv*) 
      val U_empty = EXPLICITTYVARENV FinMap.empty
      fun plus_U' (CONTEXT {U = EXPLICITTYVARENV U,E},
		   ExplicitTyVars : ExplicitTyVar list) : TyVar list * Context =
	    let val (l,U) = foldr (fn (ExplicitTyVar, (l,m)) => 
				   let val tv = TyVar.from_ExplicitTyVar ExplicitTyVar
				       val ty = Type.from_TyVar tv
				   in (tv::l, FinMap.add (ExplicitTyVar, ty, m))
				   end) ([], U) ExplicitTyVars
	    in
	      (l, CONTEXT {U=EXPLICITTYVARENV U, E=E})
	    end
      fun plus_U a = #2 (plus_U' a)
      fun to_U (CONTEXT {U=EXPLICITTYVARENV m, E}) : ExplicitTyVar list =
	    EqSet.list(FinMap.dom m)
      fun ExplicitTyVar_lookup (CONTEXT{U=EXPLICITTYVARENV m,E}) ExplicitTyVar =
	    (case FinMap.lookup m ExplicitTyVar of
	       NONE => raise Match
	     | SOME Type => Type)
      fun to_E (CONTEXT {U, E}) = E
      fun plus_E (CONTEXT {U, E}, E') = CONTEXT {U=U, E=E.plus (E, E')}
      fun plus_TE(C,TE) = plus_E(C,E.from_TE TE)
      fun plus_VE_and_TE (C, (VE, TE)) = plus_E (C, E.from_VE_and_TE (VE,TE))
      fun plus_VE (CONTEXT {U, E as ENV {SE, TE, VE, TG}}, VE') =
	    CONTEXT {U=U, E=ENV {SE=SE, TE=TE, VE=VE.plus (VE, VE'), TG=TG}}
      fun from_E E = CONTEXT {U=U_empty, E=E}
      fun on (S : Substitution, C as CONTEXT {U, E}) = C
      fun erase_TG (CONTEXT {U, E}) = CONTEXT {U=U, E=(E.erase_TG E)}
      fun to_Uenv(CONTEXT {U, E}) : ExplicitTyVarEnv = U
      fun ExplicitTyVar_lookupU (EXPLICITTYVARENV m) ExplicitTyVar =
	    (case FinMap.lookup m ExplicitTyVar of
	       NONE => raise Match  (* not found *)
	     | SOME Type => Type)

      val lookup_longid              = E.lookup_longid              o to_E
      val lookup_fellow_constructors = E.lookup_fellow_constructors o to_E
      val lookup_longtycon           = E.lookup_longtycon           o to_E
      val lookup_longstrid           = E.lookup_longstrid           o to_E
      val lookup_tycon               = E.lookup_tycon               o to_E
      val lookup_tygoal              = E.lookup_tygoal              o to_E

      local open DecGrammar in
      fun dom_pat (C, pat : pat) : id list =
	    let
	      fun dom_patrow(patrow: patrow): id list =
		case patrow of
		  DOTDOTDOT _ =>
		    nil

		| PATROW(_, _, pat, NONE) =>
		    dom_pat' pat

		| PATROW(_, _, pat, SOME patrow') =>
		    dom_pat' pat @ dom_patrow patrow'

	      and dom_atpat(atpat: atpat): id list =
		case atpat of
		  WILDCARDatpat _ => nil
		| SCONatpat(_, _) => nil
		| RECORDatpat(_, NONE) => nil
		| RECORDatpat(_, SOME patrow) => dom_patrow patrow
		| PARatpat(_, pat) => dom_pat' pat

		| LONGIDatpat(i, OP_OPT(longid, _)) =>
		    (case lookup_longid C longid of
		       SOME (VE.LONGCON _) => []
		     | SOME (VE.LONGEXCON _) => []
		     | _ => (case Ident.decompose longid of
			       ([], id) => [id]
			     | _ => impossible "dom_atpat"))

	      and dom_pat'(pat: pat): id list =
		case pat of
		  ATPATpat(_, atpat) => dom_atpat atpat
		| CONSpat(_, _, atpat) => dom_atpat atpat
		| TYPEDpat(_, pat, _) => dom_pat' pat
		| SORTEDpat(_, pat, _) => dom_pat' pat
		| LAYEREDpat(_, OP_OPT(id, _), _, pat) => id :: dom_pat' pat
		| UNRES_INFIXpat _ => impossible "dom_pat'(UNRES_INFIX)"
	    in
	      dom_pat' pat
	    end

      val layout = E.layout o to_E
      end (*local*)



      local exception BoundTwice of VarEnv
              (*raised if an identifier is bound twice in the valbind ---
	       this has been spotted earlier, and we choose to refrain to
	       close any of the typeschemes in the VE, and C.close just
	       returns VE unmodified.*)
      in

	(* The returned tyvar list is a list of those tyvars that
	 * occur bound in the returned variable environment. *)

      fun close (C : Context, valbind : valbind, VE : VarEnv) : TyVar list * VarEnv =
	let
	  val CONTEXT {E=ENV{SE=SE, VE=VARENV ve_map, ...}, 
		       U=EXPLICITTYVARENV U} = C

	  open DecGrammar 

	  (*isExpansiveId valbind = a finmap which, for every
	   variable bound in a pattern in valbind, returns true
	   if the expression corresponding to the pattern is
	   expansive, otherwise false:*)

	  fun isExpansiveId (valbind : valbind) =
	    let 
	      fun makemap pat exp = 
		let
		  fun harmless_con longid =
		    case lookup_longid C longid 
		      of SOME(VE.LONGVAR _) => false
		       | SOME(VE.LONGCON _) => #2 (Ident.decompose longid) <> Ident.id_REF
		       | SOME(VE.LONGEXCON _) => true
		       | NONE => true
		  (*why `true' and not `false' or `impossible ...'?  see my diary
		   19/12/1996 14:17. tho.*)
		  val b = DecGrammar.expansive harmless_con exp
		in
		  foldr
		    (fn (id, m) => FinMap.add (id, b, m))
		       FinMap.empty
		         (dom_pat (C,pat))
		end  
	    in
	      case valbind 
		of PLAINvalbind (_, pat, exp, NONE) => makemap pat exp
		 | PLAINvalbind (_, pat, exp, SOME valbind) =>
		  let val m1 = makemap pat exp
		      val m2 = isExpansiveId valbind
		  in FinMap.mergeMap (fn (b1, b2) => raise BoundTwice VE) m1 m2
		  end
		 | RECvalbind (i, valbind) => isExpansiveId valbind
	    end
	  
	  val isExpansiveId_map = isExpansiveId valbind

	  (* isVar is true iff id is a variable in dom VE *)		     
	  fun remake isVar id (sigma : TypeScheme) : TyVar list * TypeScheme =
	    let val isExp = 
	          case FinMap.lookup isExpansiveId_map id 
		    of NONE => false
		     | SOME b => b
		val sigma = TypeScheme.close (not (isExp andalso isVar)) sigma
		val (tvs,_) = TypeScheme.to_TyVars_and_Type sigma
  	    in (tvs, sigma)
	    end 

	  val VARENV m = VE
	  val (bound_tyvars, m) = FinMap.Fold
	     (fn ((id, range), (bound_tyvars, m)) =>
	      case range 
		of LONGVARpriv sigma =>
		  let val (tvs,sigma) = remake true id sigma
                      val _ = if !Flags.DEBUG_TYPES then  
                                print (StatObject.TypeScheme.string sigma)
                              else ()
		      val bound_tyvars = StatObject.TyVar.unionTyVarSet(tvs,bound_tyvars)
		  in (bound_tyvars, FinMap.add (id, LONGVARpriv sigma, m))
		  end
		 | LONGCONpriv (sigma, cons) =>
		  let val (tvs,sigma) = remake false id sigma 
		      val bound_tyvars = StatObject.TyVar.unionTyVarSet(tvs,bound_tyvars)
		  in (bound_tyvars, FinMap.add (id, LONGCONpriv (sigma, cons), m))
		  end
		 | LONGEXCONpriv tau => ([], FinMap.add (id, LONGEXCONpriv tau, m)))
	     ([], FinMap.empty) m
	in
	  (bound_tyvars, VARENV m)
	end (*let*) handle BoundTwice VE => ([], VE)
      end (*local exception BoundTwice*)
    end (*C *)

    (*constructor_map --- see comment in signature*)
      
    type constructor_map = (id, TypeScheme) FinMap.map

    structure constructor_map = struct
      val empty = FinMap.empty : constructor_map
      fun add id sigma constructor_map =
            FinMap.add (id, sigma, constructor_map)
      fun in_dom id constructor_map =
            EqSet.member id (FinMap.dom constructor_map)
      fun to_VE (constructor_map : constructor_map) : VarEnv =
	    let val fellow_constructors =
		      (ListSort.sort (fn x => fn y => Ident.< (x,y)) o EqSet.list o FinMap.dom)
			constructor_map
	    in
	      FinMap.Fold
		(fn ((id,sigma), VE) =>
		      VE.add VE id (LONGCONpriv (sigma, fellow_constructors)))
		  VE.empty
		    constructor_map
	    end
    end (*constructor_map*)


    structure Realisation = struct
      open Realisation

      fun on_VarEnv (phi : realisation) (VE : VarEnv) =
	    VE.map (fn LONGVARpriv sigma =>
		         LONGVARpriv (on_TypeScheme phi sigma)
	             | LONGCONpriv (sigma, cons) =>
			 LONGCONpriv (on_TypeScheme phi sigma, cons)
		     | LONGEXCONpriv tau =>
			 LONGEXCONpriv (on_Type phi tau))  VE

      fun on_TyStr (phi : realisation) (TYSTR {theta, VE}) =
	    TYSTR {theta = on_TypeFcn phi theta, VE = on_VarEnv phi VE}

      fun on_TyEnv (phi : realisation) (TE : TyEnv) =
	    TE.map (on_TyStr phi) TE

      fun on_Env phi (E : Env) =
	    if is_Id phi then E else
	      let val (SE, TE, VE) = E.un E
	      in
		E.mk (on_StrEnv phi SE, on_TyEnv phi TE, on_VarEnv phi VE)
	      end

      and on_StrEnv phi (SE : StrEnv) =
	    if is_Id phi then SE else SE.map (on_Env phi) SE

    end (*Realisation*)

    (* ABS *)
    local
      open Realisation
      infix oo

      fun abstract_tystr (TYSTR {theta, ...}) =
	let val tyname = noSome (TypeFcn.to_TyName theta) "modifyTyStr"
	    val tyname_abs = TyName.freshTyName {tycon=TyName.tycon tyname,
						 arity=TyName.arity tyname,
						 equality=false}
	    val phi = singleton(tyname_abs, TypeFcn.from_TyName tyname)
	    val phi_inv = singleton(tyname, TypeFcn.from_TyName tyname_abs) 
	in (tyname_abs, phi, phi_inv)
	end
	
      fun abstract (TE: TyEnv) =
	TE.fold (fn tystr => fn (T,phi, phi_inv) =>
		 let val (t,phi', phi_inv') = abstract_tystr tystr
		 in (t::T,phi oo phi', phi_inv oo phi_inv')
		 end) ([],Id,Id) TE

      fun strip (TE : TyEnv) : TyEnv =
	TE.map (fn (TYSTR {theta, ...}) => TYSTR {theta = theta, VE = VE.empty}) TE
    in
      fun ABS (TE : TyEnv, E : Env) : TyName list * Env * realisation =
	    let val TE' = strip TE
	        val (T, phi, phi_inv) = abstract TE'
		val E' = E.plus (E.from_TE TE', E)
		val E' = on_Env phi_inv E'
	    in (T, E', phi)    (* The T is the new generated tynames *)
	    end
    end (*local*)

    (*maximise_equality_in_VE_and_TE (VE, TE) = maximise equality in TE.
     VE is also modified so that it contains the correct equality
     attributes.  Only used by ElabDec, rule 19 and 20, and ElabTopdec,
     rule 71.  The side condition in rules 19 and 71 demands that TE
     maximises equality.  In the implementation, the maximisation is done
     after the elaboration of the datbind or the datdesc, and means that
     the equality attributes of tynames in TE are changed.  This is done
     with a realisation.  The result of elaborating a datbind or a
     datdesc is not only a TE, but also a VE, and therefore the
     realisation must also be applied to the VE:*)

    fun maximise_equality_in_VE_and_TE (VE : VarEnv, TE : TyEnv)
          : VarEnv * TyEnv =
          let val phi = TE.equality_maximising_realisation TE
	  in
	    (Realisation.on_VarEnv phi VE, Realisation.on_TyEnv phi TE)
	  end

  end (*Environments*)


