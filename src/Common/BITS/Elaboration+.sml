
signature TOOLS =
  sig
    structure BasicIO: BASIC_IO
    structure FinMap: FINMAP
    structure FinMapEq : FINMAPEQ
    structure SortedFinMap: SORTED_FINMAP
    structure IntFinMap : MONO_FINMAP where type dom = int

    structure PrettyPrint: PRETTYPRINT
      sharing type FinMap.StringTree
	           = FinMapEq.StringTree
		   = SortedFinMap.StringTree
		   = PrettyPrint.StringTree
	           = IntFinMap.StringTree

    structure Flags: FLAGS
            
    structure Report: REPORT
      sharing type FinMap.Report
		   = FinMapEq.Report
		   = SortedFinMap.Report
		   = PrettyPrint.Report
	           = Flags.Report
		   = Report.Report

    structure Timestamp: TIMESTAMP
    structure ListHacks: LIST_HACKS
    structure Crash: CRASH
    structure Timing: TIMING
  end;


functor Tools(): TOOLS =
  struct
    structure BasicIO = BasicIO()
    structure Crash = Crash(structure BasicIO = BasicIO)
    structure Report = Report(structure BasicIO = BasicIO)
    structure Flags = Flags(structure Crash = Crash
			    structure Report = Report)
    structure Timestamp = Timestamp()

    structure PrettyPrint = PrettyPrint(structure Report = Report
					structure Crash = Crash
                                        structure Flags = Flags
				       )
    structure IntFinMap = IntFinMap(structure Report = Report
				    structure PP = PrettyPrint
				   )

    structure FinMap = FinMap(structure Report = Report
			      structure PP = PrettyPrint
			     )

    structure FinMapEq = FinMapEq(structure Report = Report
				  structure PP = PrettyPrint
				    )

    structure SortedFinMap = SortedFinMap(structure Report = Report
					  structure PP = PrettyPrint
					 )

    structure Timing = Timing(structure Flags = Flags
			      structure Crash = Crash)
    structure ListHacks = ListHacks()
  end;



signature ALL_INFO =
  sig
    structure SourceInfo      : SOURCE_INFO
    structure DFInfo          : DF_INFO
    structure ParseInfo       : PARSE_INFO
      sharing ParseInfo.SourceInfo = SourceInfo
      sharing ParseInfo.DFInfo = DFInfo
    structure ErrorInfo       : ERROR_INFO
    structure TypeInfo        : TYPE_INFO
    structure OverloadingInfo : OVERLOADING_INFO
    structure ElabInfo : ELAB_INFO
      sharing ElabInfo.ParseInfo = ParseInfo
      sharing ElabInfo.ErrorInfo = ErrorInfo
      sharing ElabInfo.TypeInfo = TypeInfo
      sharing ElabInfo.OverloadingInfo = OverloadingInfo
    structure RefineErrorInfo : REFINE_ERROR_INFO
      sharing type RefineErrorInfo.SourceInfo = SourceInfo.SourceInfo
end;



signature BASICS =
  sig
    structure Tools : TOOLS 
    structure StrId : STRID

    structure Ident : IDENT
      sharing type Ident.strid = StrId.strid

    structure InfixBasis : INFIX_BASIS
      sharing type InfixBasis.id = Ident.id
      sharing type InfixBasis.Report = Tools.Report.Report
      sharing type InfixBasis.StringTree = Tools.PrettyPrint.StringTree

    structure SCon : SCON

    structure Lab : LAB
    structure TyVar : TYVAR

    structure TyCon : TYCON
      sharing type TyCon.strid = StrId.strid

    structure Name : NAME

    structure TyName : TYNAME
      sharing type TyName.tycon = TyCon.tycon
      sharing type TyName.name = Name.name
      sharing type TyName.StringTree = Tools.PrettyPrint.StringTree

(*    structure SortVar : SORTVAR *)

(*    structure SortCon : SORTCON
      sharing type SortCon.strid = StrId.strid
      sharing type SortCon.tycon = TyCon.tycon
      sharing type SortCon.longtycon = TyCon.longtycon
*)
    structure SortName : SORTNAME
      sharing type SortName.sortcon = TyCon.tycon
      sharing type SortName.TyName  = TyName.TyName
      sharing type SortName.Variance = TyVar.Variance

    structure StatObject : STATOBJECT
      sharing StatObject.TyName    = TyName
      sharing type StatObject.ExplicitTyVar = TyVar.SyntaxTyVar
      sharing type StatObject.strid     = StrId.strid
      sharing type StatObject.scon      = SCon.scon
      sharing type StatObject.lab       = Lab.lab
(*      sharing type StatObject.StringTree = Tools.PrettyPrint.StringTree *)

    structure RefObject : REFOBJECT
      sharing type RefObject.StringTree  = Tools.PrettyPrint.StringTree
      sharing type RefObject.SortName    = SortName.SortName
      sharing type RefObject.scon        = SCon.scon
      sharing type RefObject.lab         = Lab.lab
      sharing type RefObject.TyVar       = StatObject.TyVar
      sharing type RefObject.TypeFcn     = StatObject.TypeFcn
      sharing type RefObject.Type        = StatObject.Type
      sharing type RefObject.TVNames     = StatObject.TVNames
      sharing type RefObject.TyName      = StatObject.TyName
      sharing type RefObject.Variance    = TyVar.Variance
      sharing type RefObject.sortedFinMap = Tools.SortedFinMap.map

    structure SigId : SIGID
    structure FunId : FUNID

    structure LexBasics: LEX_BASICS
      sharing type LexBasics.Report = Tools.Report.Report
      sharing type LexBasics.StringTree = Tools.PrettyPrint.StringTree

    structure PreElabDecGrammar: DEC_GRAMMAR
      sharing type PreElabDecGrammar.StringTree     = Tools.PrettyPrint.StringTree
      sharing PreElabDecGrammar.Ident = Ident
      sharing PreElabDecGrammar.StrId = StrId
      sharing PreElabDecGrammar.TyCon = TyCon
      sharing PreElabDecGrammar.TyVar = TyVar
      sharing type PreElabDecGrammar.TyVar.Variance = TyVar.Variance
      sharing PreElabDecGrammar.Lab = Lab
      sharing PreElabDecGrammar.SCon = SCon

    structure Environments : ENVIRONMENTS
      sharing Environments.TyName       = StatObject.TyName
      sharing type Environments.Type         = StatObject.Type
      sharing type Environments.TyVar        = StatObject.TyVar
      sharing type Environments.TypeScheme   = StatObject.TypeScheme
      sharing type Environments.TypeFcn      = StatObject.TypeFcn
      sharing type Environments.realisation  = StatObject.realisation
      sharing type Environments.level        = StatObject.level
      sharing type Environments.id           = Ident.id
      sharing type Environments.longid       = Ident.longid
      sharing type Environments.Substitution = StatObject.Substitution
      sharing type Environments.ty           = PreElabDecGrammar.ty
      sharing type Environments.longtycon    = TyCon.longtycon
      sharing type Environments.longstrid    = StrId.longstrid
      sharing type Environments.ExplicitTyVar  = TyVar.SyntaxTyVar
      sharing type Environments.strid       = StrId.strid
      sharing type Environments.valbind = PreElabDecGrammar.valbind
      sharing type Environments.pat = PreElabDecGrammar.pat
      sharing Environments.FinMap = Tools.FinMap

    structure ModuleStatObject : MODULE_STATOBJECT
      sharing ModuleStatObject.TyName = TyName
      sharing type ModuleStatObject.Env = Environments.Env
      sharing type ModuleStatObject.realisation = StatObject.realisation
      sharing type ModuleStatObject.strid = StrId.strid
      sharing type ModuleStatObject.longstrid = StrId.longstrid
      sharing type ModuleStatObject.longtycon = TyCon.longtycon
      sharing type ModuleStatObject.Type = StatObject.Type
      sharing type ModuleStatObject.TypeScheme = StatObject.TypeScheme
      sharing type ModuleStatObject.TypeFcn = StatObject.TypeFcn
      sharing type ModuleStatObject.TyVar = StatObject.TyVar
      sharing type ModuleStatObject.id = Ident.id

    structure ModuleEnvironments : MODULE_ENVIRONMENTS
      sharing ModuleEnvironments.TyName = TyName
      sharing type ModuleEnvironments.realisation = StatObject.realisation
      sharing type ModuleEnvironments.longstrid = StrId.longstrid
      sharing type ModuleEnvironments.longtycon = TyCon.longtycon
      sharing type ModuleEnvironments.Context = Environments.Context
      sharing type ModuleEnvironments.FunSig = ModuleStatObject.FunSig
      sharing type ModuleEnvironments.TyStr = Environments.TyStr
      sharing type ModuleEnvironments.TyVar = StatObject.TyVar
      sharing type ModuleEnvironments.id = Ident.id
      sharing type ModuleEnvironments.longid = Ident.longid
      sharing type ModuleEnvironments.strid = StrId.strid
      sharing type ModuleEnvironments.sigid = SigId.sigid
      sharing type ModuleEnvironments.funid = FunId.funid
      sharing type ModuleEnvironments.Env = Environments.Env
      sharing type ModuleEnvironments.Sig = ModuleStatObject.Sig

    structure OpacityEnv : OPACITY_ENV
      sharing OpacityEnv.TyName = TyName
      sharing type OpacityEnv.funid = FunId.funid
      sharing type OpacityEnv.StringTree = Tools.PrettyPrint.StringTree

    structure AllInfo : ALL_INFO
      sharing type AllInfo.TypeInfo.Type = StatObject.Type
      sharing type AllInfo.TypeInfo.TyVar = StatObject.TyVar
      sharing type AllInfo.TypeInfo.TyEnv = Environments.TyEnv
      sharing type AllInfo.TypeInfo.longid = Ident.longid
      sharing type AllInfo.TypeInfo.realisation = StatObject.realisation
      sharing type AllInfo.TypeInfo.Env = Environments.Env
      sharing type AllInfo.TypeInfo.strid = StrId.strid
      sharing type AllInfo.TypeInfo.tycon = TyCon.tycon
      sharing type AllInfo.TypeInfo.id = Ident.id
      sharing AllInfo.TypeInfo.TyName = StatObject.TyName
      sharing type AllInfo.TypeInfo.Basis = ModuleEnvironments.Basis
      sharing type AllInfo.ElabInfo.TypeInfo.ExplicitTyVarEnv = Environments.ExplicitTyVarEnv
      sharing type AllInfo.ErrorInfo.Type = StatObject.Type
      sharing type AllInfo.ErrorInfo.TypeScheme = StatObject.TypeScheme
      sharing type AllInfo.ErrorInfo.TyVar = StatObject.TyVar
      sharing type AllInfo.ErrorInfo.TyName = TyName.TyName
      sharing type AllInfo.ErrorInfo.StringTree = Tools.PrettyPrint.StringTree
      sharing type AllInfo.ErrorInfo.TypeFcn = StatObject.TypeFcn
      sharing type AllInfo.ErrorInfo.lab = Lab.lab
      sharing type AllInfo.ErrorInfo.tycon = TyCon.tycon
      sharing type AllInfo.ErrorInfo.longid = Ident.longid
      sharing type AllInfo.ErrorInfo.longtycon = TyCon.longtycon
      sharing type AllInfo.ErrorInfo.strid = StrId.strid
      sharing type AllInfo.ErrorInfo.longstrid = StrId.longstrid
      sharing type AllInfo.ErrorInfo.sigid = SigId.sigid
      sharing type AllInfo.ErrorInfo.funid = FunId.funid
      sharing type AllInfo.ErrorInfo.id = Ident.id
      sharing type AllInfo.ErrorInfo.SigMatchError = ModuleStatObject.SigMatchError
      sharing type AllInfo.SourceInfo.pos = LexBasics.pos
      sharing type AllInfo.SourceInfo.Report = Tools.Report.Report
      sharing type AllInfo.ElabInfo.StringTree = Tools.PrettyPrint.StringTree
      sharing type AllInfo.OverloadingInfo.RecType = StatObject.RecType
      sharing type AllInfo.OverloadingInfo.TyVar = StatObject.TyVar
      sharing type AllInfo.OverloadingInfo.StringTree = Tools.PrettyPrint.StringTree
      sharing type AllInfo.ElabInfo.ParseInfo = PreElabDecGrammar.info
      sharing type AllInfo.ElabInfo.ParseInfo.DFInfo.InfixBasis = InfixBasis.Basis
      sharing type AllInfo.RefineErrorInfo.Sort = RefObject.Sort
      sharing type AllInfo.RefineErrorInfo.Type = StatObject.Type
      sharing type AllInfo.RefineErrorInfo.SortScheme = RefObject.SortScheme
      sharing type AllInfo.RefineErrorInfo.longid = Ident.longid
      sharing type AllInfo.RefineErrorInfo.longsortcon = TyCon.longtycon

    structure Comp : COMP 
      sharing type Comp.Error = AllInfo.RefineErrorInfo.Error
  end;




functor Basics(structure Tools: TOOLS): BASICS =
  struct
    structure Tools = Tools

    structure StrId = StrId(structure Timestamp = Tools.Timestamp
			    structure Crash = Tools.Crash
			   )

    structure Ident = Ident(structure StrId = StrId
			    structure Crash = Tools.Crash
			   )

    structure InfixBasis = InfixBasis
      (structure Ident = Ident
       structure FinMap = Tools.FinMap
       structure Report = Tools.Report
       structure PP = Tools.PrettyPrint)

    structure SigId = SigId()
          and FunId = FunId()
          and TyVar = TyVar(structure Crash = Tools.Crash)
(*          and SortVar = SortVar(structure Crash = Tools.Crash) *)
	  and Lab = Lab()
    	  and SCon = SCon()
    	  and TyCon = TyCon(structure StrId = StrId
			    structure Crash = Tools.Crash
			   )

(*     structure SortCon = SortCon(structure TyCon = TyCon
		  		 structure StrId = StrId
				 structure Crash = Tools.Crash
			        )
*)

    structure Name = Name (structure Crash = Tools.Crash)

    structure TyName = TyName(structure TyCon = TyCon
			      structure IntFinMap = Tools.IntFinMap
			      structure Crash = Tools.Crash
			      structure Name = Name
			      structure Flags = Tools.Flags
			      structure PrettyPrint = Tools.PrettyPrint
			      structure Report = Tools.Report)

    structure SortName = SortName(structure TyVar = TyVar  
				  structure TyCon = TyCon
			          structure TyName = TyName
				  structure Name = Name
				  structure Flags = Tools.Flags
                                  structure ListHacks = Tools.ListHacks
				  structure Crash = Tools.Crash
				 )

      structure StatObject : STATOBJECT = 
	StatObject(structure SortedFinMap  = Tools.SortedFinMap
		   structure Name = Name
		   structure IntFinMap = Tools.IntFinMap
		   structure Ident = Ident
		   structure Lab = Lab
		   structure SCon = SCon
		   structure TyName = TyName
		   structure TyCon = TyCon
		   structure ExplicitTyVar = TyVar
		   structure Flags = Tools.Flags
		   structure Report = Tools.Report
		   structure FinMap = Tools.FinMap
		   structure FinMapEq = Tools.FinMapEq
		   structure PP = Tools.PrettyPrint
		   structure Crash = Tools.Crash
		  )
   structure RefObject = RefObject(structure StatObject = StatObject
				   structure ExplicitTyVar = TyVar
				   structure SortName = SortName
				   structure Lab = Lab
				   structure Name = Name
				   structure Crash = Tools.Crash
				   structure FinMap = Tools.FinMap
				   structure SortedFinMap = Tools.SortedFinMap
				   structure Flags = Tools.Flags
				   structure SCon = SCon
				   structure ListHacks = Tools.ListHacks
				   structure Report = Tools.Report
				   structure PP = Tools.PrettyPrint
				  )		 

   (* LexBasics is needed by SourceInfo, as well as all the parsing
      stuff. *)

    structure LexBasics = LexBasics(structure BasicIO = Tools.BasicIO
				    structure Report = Tools.Report
				    structure PP = Tools.PrettyPrint
				    structure Flags = Tools.Flags
				    structure Crash = Tools.Crash
				   )

    structure DFInfo = DFInfo
      (structure PrettyPrint = Tools.PrettyPrint
       structure InfixBasis = InfixBasis)
      
    structure SourceInfo = SourceInfo
      (structure LexBasics = LexBasics
       structure PrettyPrint = Tools.PrettyPrint
       structure Crash = Tools.Crash)

    structure ParseInfo = ParseInfo
      (structure SourceInfo = SourceInfo
       structure DFInfo = DFInfo
       structure PrettyPrint = Tools.PrettyPrint
       structure Crash = Tools.Crash)

    structure PreElabDecGrammar = DecGrammar
      (structure GrammarInfo =
	 struct
	   type GrammarInfo = ParseInfo.ParseInfo
 	   val bogus_info = 
	     ParseInfo.from_SourceInfo(SourceInfo.from_positions LexBasics.DUMMY LexBasics.DUMMY)
	 end
       structure Lab = Lab
       structure SCon = SCon
       structure TyVar = TyVar
       structure TyCon = TyCon
       structure StrId = StrId
       structure Ident = Ident
       structure PrettyPrint = Tools.PrettyPrint)

    structure Environments : ENVIRONMENTS = Environments
      (structure DecGrammar = PreElabDecGrammar
       structure Ident = Ident
       structure TyCon = TyCon
       structure StrId = StrId
       structure StatObject = StatObject
       structure TyName = TyName
       structure PP = Tools.PrettyPrint
       structure SortedFinMap = Tools.SortedFinMap
       structure FinMap = Tools.FinMap
       structure Timestamp = Tools.Timestamp
       structure Report = Tools.Report
       structure Flags = Tools.Flags
       structure Crash = Tools.Crash) 



    structure ModuleStatObject =
      ModuleStatObject(structure StrId        = StrId
		       structure SigId        = SigId
		       structure FunId        = FunId
		       structure TyCon        = TyCon
		       structure TyName       = TyName
		       structure Name         = Name
		       structure StatObject   = StatObject
		       structure Environments = Environments
		       structure FinMap       = Tools.FinMap
		       structure PP           = Tools.PrettyPrint
		       structure Report       = Tools.Report
		       structure Flags        = Tools.Flags
		       structure Crash        = Tools.Crash
		      )


    structure ModuleEnvironments =
      ModuleEnvironments(structure StrId             = StrId
			 structure SigId             = SigId
			 structure FunId             = FunId
			 structure TyCon             = TyCon
			 structure Ident             = Ident
			 structure FinMap            = Tools.FinMap
			 structure FinMapEq          = Tools.FinMapEq
			 structure StatObject        = StatObject
			 structure Environments      = Environments
			 structure ModuleStatObject  = ModuleStatObject
			 structure PP                = Tools.PrettyPrint
			 structure Report	     = Tools.Report
			 structure Flags             = Tools.Flags
			 structure Crash             = Tools.Crash
			)

    structure OpacityEnv = OpacityEnv(structure FunId = FunId
                                      structure Crash = Tools.Crash                                     
                                      structure PP = Tools.PrettyPrint
                                      structure Report = Tools.Report
                                      structure Environments = Environments)

    structure AllInfo =
      struct
	structure SourceInfo = SourceInfo
	structure DFInfo = DFInfo
	structure ParseInfo = ParseInfo
	structure ErrorInfo = ErrorInfo
	  (structure StatObject = StatObject
	   structure ModuleStatObject = ModuleStatObject
	   structure Ident = Ident
	   structure Lab   = Lab
	   structure TyCon = TyCon
	   structure TyName = TyName
	   structure SigId = SigId
	   structure StrId = StrId
	   structure FunId = FunId
	   structure Report = Tools.Report
	   structure PrettyPrint = Tools.PrettyPrint)
	structure TypeInfo = TypeInfo
	  (structure Crash = Tools.Crash
	   structure Ident = Ident
	   structure ModuleEnvironments = ModuleEnvironments
	   structure StrId = StrId
	   structure TyCon = TyCon
	   structure StatObject=StatObject
	   structure Environments=Environments
	   structure PP = Tools.PrettyPrint
	   structure OpacityEnv = OpacityEnv)
	structure OverloadingInfo = OverloadingInfo
	  (structure StatObject = StatObject
	   structure PrettyPrint = Tools.PrettyPrint)
	structure ElabInfo = ElabInfo
	  (structure ParseInfo = ParseInfo
	   structure ErrorInfo = ErrorInfo
	   structure TypeInfo = TypeInfo
	   structure OverloadingInfo = OverloadingInfo
	   structure PrettyPrint = Tools.PrettyPrint
	   structure Crash = Tools.Crash)
	structure RefineErrorInfo =
	  RefineErrorInfo(structure RefObject = RefObject
                          structure StatObject = StatObject
			  structure Ident = Ident
                          structure TyCon = TyCon
                          structure Report = Tools.Report
                          structure SourceInfo = SourceInfo
                         )
     end

    structure Comp = Comp(type Error = AllInfo.RefineErrorInfo.Error) (* Computations *)

  end;



signature TOPDEC_PARSING =
  sig
    structure Basics: BASICS

    structure PreElabDecGrammar: DEC_GRAMMAR
      sharing PreElabDecGrammar = Basics.PreElabDecGrammar

    structure PreElabTopdecGrammar: TOPDEC_GRAMMAR
      sharing PreElabTopdecGrammar.DecGrammar = PreElabDecGrammar
      sharing PreElabTopdecGrammar.SigId = Basics.SigId
      sharing PreElabTopdecGrammar.FunId = Basics.FunId

    structure InfixBasis: INFIX_BASIS
      sharing InfixBasis = Basics.InfixBasis

    structure Parse: PARSE
      sharing type Parse.topdec = PreElabTopdecGrammar.topdec
      sharing type Parse.InfixBasis = InfixBasis.Basis
  end;



functor TopdecParsing(structure Basics: BASICS): TOPDEC_PARSING =
  struct
    structure Basics = Basics
    structure Tools = Basics.Tools
    structure AllInfo = Basics.AllInfo

    structure PreElabDecGrammar = Basics.PreElabDecGrammar

    structure PreElabTopdecGrammar : TOPDEC_GRAMMAR = TopdecGrammar
      (structure DecGrammar = PreElabDecGrammar
       structure SigId = Basics.SigId
       structure FunId = Basics.FunId
       structure PrettyPrint = Tools.PrettyPrint)

    structure InfixBasis = Basics.InfixBasis

    structure Parse = Parse
      (structure TopdecGrammar = PreElabTopdecGrammar
       structure LexBasics = Basics.LexBasics
       structure ParseInfo = AllInfo.ParseInfo
       structure InfixBasis = InfixBasis
       structure Report = Tools.Report
       structure PrettyPrint = Tools.PrettyPrint
       structure FinMap = Tools.FinMap
       structure BasicIO = Tools.BasicIO
       structure Flags = Tools.Flags
       structure Crash = Tools.Crash)
  end;



signature ELABORATION =
  sig
    structure Basics : BASICS

    structure ElabRepository : ELAB_REPOSITORY
      sharing type ElabRepository.funid = Basics.FunId.funid
      sharing type ElabRepository.name = Basics.Name.name
      sharing type ElabRepository.ElabBasis = Basics.ModuleEnvironments.Basis 
	    
    structure ElabTopdec : ELABTOPDEC
      sharing type ElabTopdec.StaticBasis = ElabRepository.ElabBasis

    structure PostElabDecGrammar : DEC_GRAMMAR
      sharing type PostElabDecGrammar.lab = Basics.Lab.lab
      sharing type PostElabDecGrammar.scon = Basics.SCon.scon
      sharing type PostElabDecGrammar.tycon = Basics.TyCon.tycon
      sharing type PostElabDecGrammar.longtycon = Basics.TyCon.longtycon
      sharing type PostElabDecGrammar.tyvar = Basics.TyVar.SyntaxTyVar
      sharing type PostElabDecGrammar.TyVar.Variance = Basics.TyVar.Variance
      sharing type PostElabDecGrammar.id = Basics.Ident.id
      sharing type PostElabDecGrammar.longid = Basics.Ident.longid = Basics.ModuleEnvironments.longid
      sharing type PostElabDecGrammar.info
		   = Basics.AllInfo.ElabInfo.ElabInfo
      sharing type PostElabDecGrammar.StringTree
	           = Basics.Tools.PrettyPrint.StringTree

    structure PostElabTopdecGrammar : TOPDEC_GRAMMAR
      sharing PostElabTopdecGrammar.DecGrammar = PostElabDecGrammar
      sharing PostElabTopdecGrammar.StrId = Basics.StrId
      sharing PostElabTopdecGrammar.SigId = Basics.SigId
      sharing PostElabTopdecGrammar.FunId = Basics.FunId
      sharing type PostElabTopdecGrammar.topdec = ElabTopdec.PostElabTopdec

    structure RefinedEnvironments : REFINED_ENVIRONMENTS
      sharing type RefinedEnvironments.id = Basics.Ident.id
          sharing type RefinedEnvironments.SortVar = Basics.RefObject.SortVar
          sharing type RefinedEnvironments.StringTree
	           = Basics.Tools.PrettyPrint.StringTree

    structure RefInfo : REF_INFO
       sharing RefInfo.REnv = RefinedEnvironments
       sharing RefInfo.Comp = Basics.Comp
       sharing RefInfo.RefObject = Basics.RefObject

    structure RefDecGrammar : DEC_GRAMMAR
	  sharing type RefDecGrammar.info
		   = RefInfo.RefInfo

    structure RefTopdecGrammar : TOPDEC_GRAMMAR
	  sharing type RefTopdecGrammar.dec = RefDecGrammar.dec
	  sharing type RefTopdecGrammar.info
	    	   = RefInfo.RefInfo

    structure RefTopdec : REFTOPDEC
  end;



functor Elaboration(structure TopdecParsing : TOPDEC_PARSING): ELABORATION =
  struct
    structure Basics     = TopdecParsing.Basics

    local
      structure Tools      = Basics.Tools
      structure AllInfo    = Basics.AllInfo
      structure ElabInfo   = AllInfo.ElabInfo
    in

      structure PostElabDecGrammar =
	DecGrammar(structure GrammarInfo =
		     struct
		       type GrammarInfo = ElabInfo.ElabInfo
		       val bogus_info = ElabInfo.from_ParseInfo TopdecParsing.PreElabDecGrammar.bogus_info
		     end
		   structure Lab         = Basics.Lab
		   structure SCon        = Basics.SCon
		   structure TyVar       = Basics.TyVar
		   structure TyCon       = Basics.TyCon
		   structure StrId       = Basics.StrId
		   structure Ident       = Basics.Ident
		   structure PrettyPrint = Tools.PrettyPrint
		  )

      structure PostElabTopdecGrammar =
	TopdecGrammar(structure DecGrammar = PostElabDecGrammar
		      structure SigId = Basics.SigId
		      structure FunId = Basics.FunId
		      structure PrettyPrint = Tools.PrettyPrint)

      structure ElabRepository = ElabRepository(structure Name = Basics.Name
						structure InfixBasis = TopdecParsing.InfixBasis
						structure TyName = Basics.TyName
						structure OpacityEnv = Basics.OpacityEnv
						structure Flags = Tools.Flags
						type funid = Basics.FunId.funid
						type ElabBasis = Basics.ModuleEnvironments.Basis
						type longstrid = Basics.StrId.longstrid
						structure Crash =  Tools.Crash
						structure FinMap = Tools.FinMap)


      structure RefinedEnvironments = RefinedEnvironments
	            (structure StrId = Basics.StrId
                     structure DecGrammar = Elaboration.PostElabDecGrammar
                     structure Ident = Basics.Ident
		     structure TyCon = Basics.TyCon
		     structure TyName = Basics.TyName
		     structure SortName = Basics.SortName
		     structure StatObject = Basics.StatObject
		     structure Environments = Basics.Environments
		     structure RefObject = Basics.RefObject
		     structure PP = Tools.PrettyPrint
		     structure SortedFinMap = Tools.SortedFinMap
		     structure FinMap = Tools.FinMap
		     structure FinMapEq = Tools.FinMapEq
		     structure Flags = Tools.Flags
		     structure Timestamp = Tools.Timestamp
		     structure ListHacks = Tools.ListHacks
		     structure Report = Tools.Report
		     structure Crash = Tools.Crash
		    )

        structure RefInfo = RefInfo
          (structure ElabInfo = AllInfo.ElabInfo
           structure REnv = RefinedEnvironments
	   structure RefObject = Basics.RefObject
           structure PP = Tools.PrettyPrint
           structure FinMapEq = Tools.FinMapEq
           structure Comp = Basics.Comp)

      structure RefDecGrammar =
	DecGrammar(structure GrammarInfo =
		     struct
		       type GrammarInfo = RefInfo.RefInfo
                       val bogus_info = 
                         RefInfo.from_ElabInfo PostElabDecGrammar.bogus_info
		     end
		   structure Lab         = Basics.Lab
		   structure SCon        = Basics.SCon
		   structure TyVar       = Basics.TyVar
		   structure TyCon       = Basics.TyCon
		   structure StrId       = Basics.StrId
		   structure Ident       = Basics.Ident
		   structure PrettyPrint = Tools.PrettyPrint
		  )

      structure RefTopdecGrammar =
	TopdecGrammar(structure DecGrammar =  RefDecGrammar
         	      structure SigId = Basics.SigId
		      structure FunId = Basics.FunId
		      structure PrettyPrint = Tools.PrettyPrint)

      structure ElabTopdec =
	ElabTopdec(structure PrettyPrint = Tools.PrettyPrint
		   structure IG = TopdecParsing.PreElabTopdecGrammar
		   structure OG = PostElabTopdecGrammar
		   structure Environments = Basics.Environments
		   structure ModuleEnvironments = Basics.ModuleEnvironments
		   structure StatObject = Basics.StatObject
		   structure ModuleStatObject = Basics.ModuleStatObject
		   structure Name = Basics.Name
		   structure ElabRep = ElabRepository
		   structure ElabDec =
		     ElabDec (structure ParseInfo = AllInfo.ParseInfo
			      structure ElabInfo = AllInfo.ElabInfo
			      structure IG = TopdecParsing.PreElabDecGrammar
			      structure OG = PostElabDecGrammar
			      structure Environments = Basics.Environments
			      structure Ident = Basics.Ident
			      structure Lab = Basics.Lab
			      structure StatObject = Basics.StatObject
			      structure FinMap = Tools.FinMap
			      structure Report = Tools.Report
			      structure PP = Tools.PrettyPrint
			      structure Flags = Tools.Flags
			      structure Crash = Tools.Crash)

		   structure StrId = Basics.StrId
		   structure SigId = Basics.SigId
		   structure ParseInfo = AllInfo.ParseInfo
		   structure ElabInfo = AllInfo.ElabInfo
		   structure BasicIO = Tools.BasicIO
		   structure Report = Tools.Report
		   structure Ident = Basics.Ident
		   structure PP = Tools.PrettyPrint
		   structure FinMap = Tools.FinMap
		   structure Flags = Tools.Flags
		   structure Crash = Tools.Crash)

      structure MapDecEtoR = MapDecInfo(structure IG = PostElabDecGrammar
					structure OG = RefDecGrammar)

      structure MapDecRtoE = MapDecInfo(structure IG = RefDecGrammar
					structure OG = PostElabDecGrammar)

      structure RefTopdec =
        RefTopdec( structure IG = PostElabTopdecGrammar
                   structure RG = RefTopdecGrammar
                   structure RefinedEnvironments = RefinedEnvironments
                   structure RefDec =
                     RefDec( structure IG = PostElabDecGrammar
                             structure RG = RefDecGrammar
                             structure RefInfo = RefInfo
                             structure MapDecEtoR = MapDecEtoR
                             structure MapDecRtoE = MapDecRtoE
                             structure RefinedEnvironments = RefinedEnvironments
                             structure StatObject = Basics.StatObject
                             structure RefObject = Basics.RefObject
                             structure Lab = Basics.Lab
                             structure Ident = Basics.Ident
                             structure TyName = Basics.TyName
                             structure TyVar = Basics.TyVar
                             structure SortName = Basics.SortName
                             structure TyCon = Basics.TyCon
                             structure ElabInfo = AllInfo.ElabInfo
                             structure RefineErrorInfo = AllInfo.RefineErrorInfo
                             structure FinMap = Tools.FinMap
                             structure FinMapEq = Tools.FinMapEq
                             structure SortedFinMap = Tools.SortedFinMap
                             structure Report = Tools.Report
                             structure PP = Tools.PrettyPrint
                             structure Flags = Tools.Flags
                             structure Crash = Tools.Crash
                             structure Comp = Basics.Comp
                            )
                   structure RefineErrorInfo = AllInfo.RefineErrorInfo
                   structure StrId = Basics.StrId
                   structure SigId = Basics.SigId
                   structure BasicIO = Tools.BasicIO
                   structure Report = Tools.Report
                   structure PP = Tools.PrettyPrint
                   structure Crash = Tools.Crash
                   structure Comp = Basics.Comp
                  )

    end
  end;


