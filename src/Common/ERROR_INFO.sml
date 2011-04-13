(*$ERROR_INFO: ERROR_CODE*)
signature ERROR_INFO =         (* ErrorInfo is part of the ElabInfo.  See ELAB_INFO for an
				* overview of the different kinds of info.*)
  sig
    type TyName
    type TyVar
    type Type and TypeScheme
    type TypeFcn
    eqtype id
    eqtype lab
    eqtype tycon
    type longid
    type longtycon 
    type sigid
    type strid
    type longstrid 
    eqtype funid
    type SigMatchError
    type StringTree

    structure RefineErrorInfo : REFINE_ERROR_INFO (* where type longsortcon = longtycon *)
      sharing type RefineErrorInfo.longsortcon = longtycon

    datatype RepeatedId = ID_RID of id      (* Repeated identifier, syntax *)
			| LAB_RID of lab    (* errors *)
			| TYCON_RID of tycon
			| EXCON_RID of id
			| CON_RID of id
			| TYVAR_RID of TyVar
			| STRID_RID of strid
			| SIGID_RID of sigid
			| FUNID_RID of funid

    datatype ErrorInfo =
     (* Core errors: *)
	UNIFICATION of Type * Type
      | UNIFICATION_TEXT of string * Type * string * Type
      | UNIFICATION_RANK of Type * Type * TyVar * TyName
      | LOOKUP_LONGID of longid
      | LOOKUP_LONGTYCON of longtycon
      | NOTCONSTYPE of Type
      | QUALIFIED_ID of longid
      | UNGUARDED_TYVARS of TyVar list
      | UNGENERALISABLE_TYVARS of id list
      | WRONG_ARITY of {expected: int, actual: int}
      | FLEX_REC_NOT_RESOLVED 
      | REPEATED_IDS of RepeatedId list
      | TYVARS_NOT_IN_TYVARSEQ of TyVar list
      | DATATYPES_ESCAPE_SCOPE of TyName list
      | TYVARS_SCOPED_TWICE of TyVar list
      | REBINDING_TRUE_NIL_ETC of id list
      | REBINDING_IT
      | INCOMPATIBLE_TY of Type * Type
      | INCOMPATIBLE_TYSCH of TypeScheme * TypeScheme
      | TYGOAL
      | INTERSECTION_IN_TYPE

      (* Errors from REFDEC - Rowan 17jan02 *)
      | REFDEC of RefineErrorInfo.Error list

     (* General module errors: *)
      | SPECIFYING_TRUE_NIL_ETC of id list
      | SPECIFYING_IT
      | QUALIFIED_CON     (* strid in datatype *)
      | LOOKUP_SIGID of sigid
      | LOOKUP_LONGSTRID of longstrid
      | LOOKUP_FUNID of funid
      | EXDESC_SIDECONDITION
      | SHARING_TYPE_NOT_TYNAME of longtycon * TypeFcn
      | SHARING_TYPE_RIGID of longtycon * TyName
      | SHARING_TYPE_ARITY of TyName list 

      (*the following five errors come from rule 64, Definition 1997:*)
      | WHERE_TYPE_NOT_WELLFORMED of longtycon * TyName * Type
      | WHERE_TYPE_MULTIPLE_REFINEMENTS of longtycon * TyName
      | WHERE_TYPE_EQTYPE of longtycon * TyName * Type
      | WHERE_TYPE_RIGID of longtycon * TyName
      | WHERE_TYPE_NOT_TYNAME of longtycon * TypeFcn * Type
      | WHERE_TYPE_ARITY of TyVar list * (longtycon * TyName)

      (* Signature matching errors: *)
      | SIGMATCH_ERROR of SigMatchError

      (* Module unification errors: *)
      | CYCLE of longstrid
      | U_RIGIDTYCLASH of longtycon * longtycon
      | TYPESTRILLFORMEDNESS of longtycon * longtycon
      | U_CONFLICTING_DOMCE of longtycon * longtycon
      | U_CONFLICTINGARITY of longtycon * longtycon
      | RIGIDTYFUNEQERROR of longtycon * longtycon

    (* No need to print source info if this function returns true *)
    val errorIncludesSourceInfo : ErrorInfo -> bool

    type Report = RefineErrorInfo.Report
    val report : ErrorInfo -> Report

    structure ErrorCode : ERROR_CODE      (* Support for error testing and handling. *)
      sharing type ErrorCode.ErrorInfo = ErrorInfo
  end;
