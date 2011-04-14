(*TyVar, tau in Type, FunType, ConsType, RecType, sigma in
 TypeScheme, theta in TypeFcn, Definition 1997, fig. 10, p. 16;
 phi in realisation, �5.2, p. 29.  Also Level and Substitution.*)

signature STATOBJECT =
  sig 
    (*types provided by this module:*)
    type level
    type TVNames
    type TyVar 
    type Type
    type FunType
    type ConsType
    type RecType
    type Substitution
    type TypeScheme
    type TypeFcn
    type realisation(*tyrea*)

    (*types from other modules:*)
    eqtype ExplicitTyVar (*the type of type variables explicit in the source*)
    type TyName
    eqtype tycon 
    structure TyName : TYNAME 
       where type TyName = TyName 
       where type tycon = tycon
    eqtype lab 
    type scon
    type strid



    (*Level: for an explanation of type inference using `let levels'
     see Martin Elsman: A Portable Standard ML Implementation.
     Master's Thesis, Tech. Univ. of Denmark, Dept. of C. S. 1994.*)

    structure Level :
      sig
	val push                    : unit -> unit
	val pop                     : unit -> unit
	val GENERIC                 : level
	val current                 : unit -> level
        val pr                      : level -> string
      end



    (*Association list for the printing of type variables:*)
    val newTVNames                  : unit -> TVNames	

    structure TyVar :
      sig
	val eq                      : TyVar * TyVar -> bool 
	val equality                : TyVar -> bool
	val fresh_normal            : unit -> TyVar
	val fresh_overloaded        : TyName list -> TyVar
	  (*fresh_overloaded bla = get a socalled overloaded tyvar that is overloaded
	   to the types indicated by `bla'.*)
	val from_ExplicitTyVar      : ExplicitTyVar -> TyVar
	val is_overloaded           : TyVar -> bool
	val string                  : TyVar -> string
	val string'                 : (Type -> string) -> TyVar -> string
	val pretty_string           : TVNames -> TyVar -> string
	val layout                  : TyVar -> StringTree.t

	(*TODO 26/01/1997 14:17. tho.: ugly ad hoc set functions:*)
	val intersectTyVarSet       : TyVar list * TyVar list -> TyVar list
	val unionTyVarSet           : TyVar list * TyVar list -> TyVar list
      end (*TyVar*)



    structure Type :
      sig
	val eq                      : Type * Type -> bool
	val fresh_normal            : unit -> Type (*fresh_normal () = a fresh tyvar*)
	val tyvars                  : Type -> TyVar list
	val tynames                 : Type -> TyName.Set.Set
	val string                  : Type -> string
	val pretty_string           : TVNames -> Type -> string
	val string_as_ty            : Type * Type -> string
	      (*The second type is a guide for printing*)
	val pretty_string_as_ty     : TVNames -> (Type*Type) -> string
	val layout                  : Type -> StringTree.t
	val from_TyVar              : TyVar -> Type
	val to_TyVar                : Type -> TyVar option

	(*record types*)
	val from_RecType            : RecType -> Type
	val to_RecType              : Type -> RecType option
	val contains_row_variable   : Type -> bool
	    (*contains_row_variable rho = true iff there exists a 
	     row variable in the type rho*)
	structure RecType :
	  sig
	    val empty               : RecType			(* "{}" *)
	    val dotdotdot           : unit -> RecType    	(* "{...}" *)
	    val add_field           : lab * Type -> RecType -> RecType
	    val sorted_labs         : RecType -> lab list (* Needed by compiler. *)
	    val to_list             : RecType -> (lab * Type) list
	          (*needed by compiler. the returned list is sorted
		   (non-ascending) with respect to Lab.<*)
	    val to_pair             : RecType -> Type * Type
	  end
	val from_pair               : Type * Type -> Type
	val from_triple             : Type * Type * Type -> Type
	val Unit                    : Type

	(*function types*)
	val from_FunType            : FunType -> Type
	val to_FunType              : Type -> FunType option
	val mk_FunType              : Type * Type -> FunType
	val un_FunType              : FunType -> (Type * Type) option

	(*constructed types*)
	val from_ConsType           : ConsType -> Type
	val to_ConsType             : Type -> ConsType option
	val mk_ConsType             : Type list * TyName -> ConsType
	val un_ConsType             : ConsType -> (Type list * TyName) option

	val Exn                     : Type
	val is_Exn                  : Type -> bool
	val mk_Arrow                : Type * Type -> Type
	val un_Arrow                : Type -> (Type * Type) option
	val is_Arrow                : Type -> bool
	val mk_Ref                  : Type -> Type

	val Int                     : Type   (* special constants *)
	val Real                    : Type
	val Bool                    : Type   (* needed for initial TE and VE *)
	val String                  : Type
	val Char                    : Type
	val Word8                   : Type
	val Word                    : Type
	val of_scon                 : scon -> {type_scon: Type, overloading : TyVar option}

	datatype unify_result = UnifyOk (* of Substitution *)
                              | UnifyFail 
                              | UnifyRankError of TyVar * TyName

	val unify                   : Type * Type -> unify_result
	val instantiate_arbitrarily : TyVar -> unit

	(* instantiate_arbitrarily tyvar; instantiate tyvar to some
	 * arbitrary type (int). Used by ElabTopdec.elab_topdec when
	 * tyvar is free in a topdec.*)

	val match : Type * Type -> unit   (* for compilation manager *)

      end (*Type*)



    structure TypeScheme :
      sig
	val eq                      : TypeScheme * TypeScheme -> bool
	val to_TyVars_and_Type      : TypeScheme -> TyVar list * Type      (* for the compiler *)
	(*Make a type into a typescheme with no bound variables:*)
	val from_Type               : Type -> TypeScheme
	val tyvars                  : TypeScheme -> TyVar list
	val tynames                 : TypeScheme -> TyName.Set.Set
	val string                  : TypeScheme -> string
	val pretty_string           : TVNames -> TypeScheme -> string
	val layout                  : TypeScheme -> StringTree.t

	(* Get an instance of a TypeScheme; instance' also gives
	 * the list of types to which the generic type variables of the type
	 * scheme have been instantiated to.*)

	val instance                : TypeScheme -> Type
	val instance'               : TypeScheme -> Type * Type list 
        (* generalises_TypeScheme depends on generic tyvars all being explicit *)
	val generalises_TypeScheme  : TypeScheme * TypeScheme -> bool
	val generalises_Type        : TypeScheme * Type -> bool

	(* close imp sigma = generalise generic type variables in
	 * sigma except overload tyvars; used by Environment. The bool
	 * should be true for generalisation proper and false if the
	 * type scheme stems from a valbind that is expansive. *)

	val close : bool -> TypeScheme -> TypeScheme

	(* close_overload tau = generalise generic type variables also
	 * overloaded tyvars. *)

	val close_overload : Type -> TypeScheme

	(*violates_equality T sigma = false, iff, assuming the tynames in
	 T admit equality, sigma admits equality, i.e., violates_equality
	 T sigma = non((all t in T admit equality) => sigma admits
	 equality).  violates_equality is used when maximising equality in
	 a TE (in TE.maximise_TE_equality).  T will be those datatypes in
	 TE we tentatively assume to admit equality, and sigma will be the
	 type scheme of a constructor.*)

	val violates_equality       : TyName.Set.Set -> TypeScheme -> bool

	(*for compilation manager:*)
	val match : TypeScheme * TypeScheme -> unit

      end (*TypeScheme*)



    structure Substitution :
      sig
	val Id                      : Substitution
	val oo                      : Substitution * Substitution -> Substitution
	val on                      : Substitution * Type  -> Type
	val onScheme                : Substitution * TypeScheme -> TypeScheme
      end (*Substitution*)



    structure TypeFcn :
      sig
	val eq                      : TypeFcn * TypeFcn -> bool
	val from_TyVars_and_Type    : TyVar list * Type   -> TypeFcn
	val apply                   : TypeFcn * Type list -> Type
	val arity                   : TypeFcn -> int
	val admits_equality         : TypeFcn -> bool
	val grounded                : TypeFcn * TyName.Set.Set -> bool
	val from_TyName             : TyName  -> TypeFcn
	val to_TyName               : TypeFcn -> TyName option
	val is_TyName               : TypeFcn -> bool
	val tynames                 : TypeFcn -> TyName.Set.Set

	(*pretty_string returns two strings. This is because
	 something like

           type ('a, 'b) Foo = int

         maps Foo to "/\('a, 'b).int" and we need to take this apart to get
	 the correct printout.  pretty_string' will print it as the
	 last-mentioned string.*)

	val pretty_string : TVNames -> TypeFcn -> {vars: string, body: string}
	val pretty_string' : TVNames -> TypeFcn -> string
	val layout : TypeFcn -> StringTree.t

	(*for compilation manager:*)
	val match : TypeFcn * TypeFcn -> unit

      end (*TypeFcn*)



    (*Realisation --- used during elaboration to apply a realisation on
     recorded type information.  Notice there is a Realisation structure
     in Environments as well.  It extends this Realisation structure.*)

    structure Realisation :
      sig
	val on_TyName               : realisation -> TyName -> TypeFcn
	val on_TyName_set           : realisation -> TyName.Set.Set -> TyName.Set.Set
	val on_Type                 : realisation -> Type -> Type
	val on_TypeFcn              : realisation -> TypeFcn -> TypeFcn
	val on_TypeScheme           : realisation -> TypeScheme -> TypeScheme
	val Id                      : realisation
	val is_Id                   : realisation -> bool
	val oo                      : realisation * realisation -> realisation
	val singleton               : TyName * TypeFcn -> realisation

	(*from_T_and_tyname (T, t0) = the realisation {t |-> t0 | t in T} *)
	val from_T_and_tyname       : TyName.Set.Set * TyName -> realisation
	val restrict                : TyName.Set.Set -> realisation -> realisation
	val restrict_from           : TyName.Set.Set -> realisation -> realisation
	val renaming                : TyName.Set.Set -> realisation
	val renaming'               : TyName.Set.Set -> TyName.Set.Set * realisation
	val inverse                 : realisation -> realisation option
	val enrich                  : realisation * (realisation * TyName.Set.Set) -> bool
	val match                   : realisation * realisation -> unit
	val dom                     : realisation -> TyName.Set.Set
	val eq                      : realisation * realisation -> bool
	val layout                  : realisation -> StringTree.t

      end (*Realisation*)

  end;

