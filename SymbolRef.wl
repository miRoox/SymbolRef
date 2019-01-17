(* ::Package:: *)

BeginPackage["SymbolRef`"]


(* ::Section:: *)
(*Interface*)


Unprotect[Ref,Deref,NullRef]


Ref::usage="Ref[sym] refers to sym."
Deref::usage="Deref[ref] dereference."
NullRef::usage="NullRef is a reference that refers to nothing."
RefQ::usage="RefQ[expr] check if expr is a reference."


SyntaxInformation[Ref]={"ArgumentsPattern"->{_}}
SyntaxInformation[Deref]={"ArgumentsPattern"->{_}}
SyntaxInformation[RefQ]={"ArgumentsPattern"->{_}}


(* ::Section:: *)
(*Implement*)


Begin["`Private`"]


Ref::nosym="`1` is not a symbol."
Deref::null="NullRef refers to NOTHING!"
Deref::noref="`1` is not a reference."


SetAttributes[ownValue,HoldFirst]
ownValue[sym_Symbol,warpper_:Unevaluated]:=warpper[sym]/.OwnValues[sym]


SetAttributes[embeddedUserSymbols,HoldFirst]
embeddedUserSymbols[expr_]:=
 Select[Internal`EmbeddedSymbols[expr],
  Function[sym,ContainsNone[Attributes[sym],{Locked,Protected}],HoldAll]
 ]/. {Hold[syms___]:>Hold[{syms}]}
SetAttributes[symbolSandbox,HoldFirst]
symbolSandbox[expr_]:=With[{syms=Unevaluated@@embeddedUserSymbols[expr]},
  Internal`InheritedBlock[syms,expr]
 ]


checkRefInsideDeref[Deref[r_?iRefQ]]:=Deref[r]
checkRefInsideDeref[Deref[expr_]]:=(Message[Deref::noref,expr];Throw[$Failed,Deref])


SetAttributes[RefQ,HoldFirst]
RefQ[expr_]:=iRefQ[symbolSandbox[expr]]
iRefQ[NullRef|_Ref]:=True
iRefQ[_]:=False


SetAttributes[Ref,HoldFirst]
Ref[ref_Ref]:=ref
Ref[NullRef]:=NullRef
Ref[expr:Except[_Symbol|_Ref|NullRef]]:=(Message[Ref::nosym,expr];NullRef)


Deref[HoldPattern[Ref[obj_]]]:=obj
Deref[NullRef]:=(Message[Deref::null];$Failed)
Deref[expr_]:=(Message[Deref::noref,expr];$Failed)


Unprotect[Set,SetDelayed];
Do[
 With[{set=set},
  Quiet[set[lhs_, rhs_]/;MemberQ[Unevaluated[lhs],_Deref,{0,Infinity}]=. ,Unset::norep];
  set[lhs_, rhs_]/;MemberQ[Unevaluated[lhs],_Deref,{0,Infinity}]:=
   With[{
    lhs1 = Block[{Deref},
      Hold[lhs]//.{
       Deref[NullRef] :> With[{e=(Message[Deref::null];Throw[$Failed,Deref])},e/;True],
       Deref@HoldPattern@Ref[sym_Symbol] :> sym,
       Deref[expr_] :> With[{e=checkRefInsideDeref[Deref[expr]]},e/;True]
      }]},
    Replace[Hold[set[lhs1, rhs]], Hold[set[Hold[lhs2_], rhs2_]]:>set[lhs2, rhs2]]
   ]//Catch[#,Deref]&
 ],{set,{Set,SetDelayed}}
]
Protect[Set,SetDelayed];


(* ::Section::Closed:: *)
(*End*)


End[]


Protect[Ref,Deref,NullRef]


EndPackage[]
