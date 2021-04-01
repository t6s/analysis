(* mathcomp analysis (c) 2017 Inria and AIST. License: CeCILL-C.              *)
From Coq Require Import ssreflect ssrfun ssrbool.
From mathcomp Require Import ssrnat eqtype choice seq fintype order bigop.
From mathcomp Require Import ssralg ssrnum.
From mathcomp Require Import finmap.
Require Import boolp reals ereal classical_sets posnum topology normedtype.
Require Import sequences cardinality (*TODO: essayer de faire sans*).

(******************************************************************************)
(*       summation of non-negative extended reals over countable sets         *)
(*                                                                            *)
(* WIP.                                                                       *)
(*                                                                            *)
(* csum I f == where I is a classical set and f a function with codomain      *)
(*             included in the extended reals; it is 0 if I = set0 and o.w.   *)
(*             sup(\sum_F a) where F is a finite set included in I            *)
(*                                                                            *)
(******************************************************************************)

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import Order.TTheory GRing.Theory Num.Def Num.Theory.

Local Open Scope classical_set_scope.
Local Open Scope ring_scope.

Lemma ub_ereal_sup_adherent2 (R : realFieldType) (T : choiceType)
  (P : T -> Prop) (f : T -> {ereal R}) (e : {posnum R}) c :
  ereal_sup [set y | exists2 F, P F & (f F = y)%E] = c%:E ->
  exists F, P F /\ (c%:E - e%:num%:E < f F)%E.
Proof.
set S : set {ereal R} := (X in ereal_sup X) => Sc.
have : ~ ubound S (ereal_sup S - e%:num%:E)%E.
  move/ub_ereal_sup; apply/negP.
  by rewrite -ltNge Sc lte_subl_addr lte_fin ltr_addl.
move/asboolP; rewrite asbool_neg; case/existsp_asboolPn => /= x.
rewrite not_implyE => -[[A AJj <-{x}] AS].
by exists A; split => //; rewrite ltNge; apply/negP; rewrite subERFin -Sc.
Qed.

(*TODO: Pr to finmap in progress *)
Section FsetPartitions.

Variables T I : choiceType.
Implicit Types (x y z : T) (A B D X : {fset T}) (P Q : {fset {fset T}}).
Implicit Types (J : pred I) (F : I -> {fset T}).

Definition fcover P := (\bigcup_(B <- P) B)%fset.
Definition trivIfset P := (\sum_(B <- P) #|` B|)%N == #|` fcover P|.

Lemma leq_card_fsetU A B :
  ((#|` A `|` B|)%fset <= #|` A| + #|` B| ?= iff [disjoint A & B]%fset)%N.
Proof.
rewrite -(addn0 #|`_|) -fsetI_eq0 -cardfs_eq0 -cardfsUI eq_sym.
by rewrite (mono_leqif (leq_add2l _)).
Qed.

Lemma leq_card_fcover P :
  ((#|` fcover P|)%fset <= \sum_(A <- P) #|`A| ?= iff trivIfset P)%N.
Proof.
split; last exact: eq_sym.
rewrite /fcover; elim/big_rec2: _ => [|A n U _ leUn]; first by rewrite cardfs0.
by rewrite (leq_trans (leq_card_fsetU A U).1) ?leq_add2l.
Qed.

Lemma trivIfsetP P :
  reflect {in P &, forall A B, A != B -> [disjoint A & B]%fset} (trivIfset P).
Proof.
have [l Pl ul] : {l | enum_fset P =i l & uniq l} by exists (enum_fset P).
elim: l P Pl ul => [P P0 _|A e ih P PAe] /=.
  rewrite /trivIfset /fcover.
  have -> : P = fset0 by apply/fsetP => i; rewrite P0 !inE.
  rewrite !big_seq_fset0 cardfs0 eqxx.
  by left => x y; rewrite in_fset0.
have {PAe} -> : P = [fset x | x in A :: e]%fset.
  by apply/fsetP => i; rewrite !inE /= PAe inE.
move=> {P} /andP[]; rewrite fset_cons => Ae ue.
set E := [fset x | x in e]%fset; have Ee : E =i e by move=> x; rewrite !inE.
rewrite -Ee in Ae; move: (ih _ Ee ue) => {}ih.
rewrite /trivIfset /fcover !big_setU1 // eq_sym.
have := leq_card_fcover E; rewrite -(mono_leqif (leq_add2l #|` A|)).
move/(leqif_trans (leq_card_fsetU _ _)) => /= ->.
have [dAcE|dAcE]/= := boolP [disjoint A & fcover E]%fset; last first.
  right=> tI; move/negP : dAcE; apply.
  rewrite -fsetI_eq0; apply/eqP/fsetP => t; apply/idP/idP => //; apply/negP.
  rewrite inE => /andP[tA].
  rewrite /fcover => /bigfcupP[/= B]; rewrite andbT => BE tB.
  have AB : A != B by apply: contra Ae => /eqP ->.
  move: (tI A B).
  rewrite 2!inE eqxx /= => /(_ isT); rewrite 2!inE BE orbT => /(_ isT AB).
  by move/disjoint_fsetI0 => /fsetP /(_ t); rewrite inE tA tB inE.
apply: (iffP ih) => [tI B C|tI B C PB PC]; last first.
  by apply: tI; rewrite !inE /= -Ee ?(PB,PC) orbT.
rewrite 2!inE => /orP[/eqP->{B}|BE].
  rewrite 2!inE => /orP[/eqP->|{tI}]; first by rewrite eqxx.
  move: dAcE; rewrite -fsetI_eq0 => /eqP AE0 CE AC.
  rewrite -fsetI_eq0; apply/eqP/fsetP => t; apply/idP/idP; apply/negP.
  rewrite inE => /andP[tA tC].
  move/fsetP : AE0 => /(_ t); rewrite !inE tA /= => /negbT/negP; apply.
  by apply/bigfcupP; exists C => //; rewrite CE.
rewrite 2!inE => /orP[/eqP-> BA|]; last exact: tI.
rewrite -fsetI_eq0; apply/eqP/fsetP => t; apply/idP/idP; apply/negP.
rewrite inE => /andP[tB tA]; move: dAcE.
rewrite -fsetI_eq0 => /eqP/fsetP/(_ t); rewrite !inE tA /= => /negP; apply.
by apply/bigfcupP; exists B => //; rewrite BE.
Qed.

Lemma fcover_imfset (J : {fset I}) F (P : pred I) :
  fcover [fset F i | i in J & P i]%fset = (\bigcup_(i <- J | P i) F i)%fset.
Proof.
apply/fsetP=> x; apply/bigfcupP/bigfcupP => [[/= t]|[i /andP[iJ Pi xFi]]].
  by rewrite andbT => /imfsetP[i /= Ji -> xFi]; exists i.
exists (F i) => //; rewrite andbT; apply/imfsetP; exists i => //=.
by rewrite inE Pi andbT.
Qed.

Section FsetBigOps.

Variables (R : Type) (idx : R) (op : Monoid.com_law idx).
Let rhs_cond P K E :=
  (\big[op/idx]_(A <- P) \big[op/idx]_(x <- A | K x) E x)%fset.
Let rhs P E := (\big[op/idx]_(A <- P) \big[op/idx]_(x <- A) E x)%fset.

Lemma big_trivIfset P (E : T -> R) :
  trivIfset P -> \big[op/idx]_(x <- fcover P) E x = rhs P E.
Proof.
rewrite /rhs /fcover => /trivIfsetP tI.
have {tI} : {in enum_fset P &, forall A B, A != B -> [disjoint A & B]%fset}.
  by [].
elim: (enum_fset P) (fset_uniq P) => [_|h t ih /= /andP[ht ut] tP].
  by rewrite !big_nil.
rewrite !big_cons -ih //; last first.
  by move=> x y xt yt xy; apply tP => //; rewrite !inE ?(xt,yt) orbT.
rewrite {1}/fsetU big_imfset //= undup_cat /= big_cat !undup_id //.
congr (op _ _).
suff : [seq x <- h | x \notin (\bigcup_(j <- t) j)%fset] = h by move=>->.
rewrite -[RHS]filter_predT; apply eq_in_filter => x xh.
apply/negP/idP; apply/negP => /bigfcupP[/= A].
rewrite andbT => At xA.
have hA : h != A by move/negP : ht => /negP; apply: contra => /eqP ->.
move: (tP h A).
rewrite !inE eqxx => /(_ erefl);  rewrite At orbT => /(_ erefl hA).
by rewrite -fsetI_eq0 => /eqP /fsetP /(_ x); rewrite !inE xh xA.
Qed.

Lemma partition_disjoint_bigfcup (f : T -> R) (F : I -> {fset T})
  (K : {fset I}) :
  (forall i j, i != j -> [disjoint F i & F j])%fset ->
  \big[op/idx]_(i <- \big[fsetU/fset0]_(x <- K) (F x)) f i =
  \big[op/idx]_(k <- K) (\big[op/idx]_(i <- F k) f i).
Proof.
move=> disjF; pose P := [fset F i | i in K & F i != fset0]%fset.
have trivP : trivIfset P.
  apply/trivIfsetP => _ _ /imfsetP[i _ ->] /imfsetP[j _ ->] neqFij.
  by apply: disjF; apply: contraNneq neqFij => ->.
have -> : (\bigcup_(i <- K) F i)%fset = fcover P.
  apply/esym; rewrite /P fcover_imfset big_mkcond /=; apply eq_bigr => i _.
  by case: ifPn => // /negPn/eqP.
rewrite big_trivIfset // /rhs big_imfset => [|i j _ /andP[jK notFj0] eqFij] /=.
  rewrite big_filter big_mkcond; apply eq_bigr => i _.
  by case: ifPn => // /negPn /eqP ->;  rewrite big_seq_fset0.
by apply: contraNeq (disjF _ _) _; rewrite -fsetI_eq0 eqFij fsetIid.
Qed.

End FsetBigOps.

End FsetPartitions.
(* NB: end of PR to finmap in progress *)

Definition csum (R : realFieldType) (T : choiceType) (S : set T)
    (a : T -> {ereal R}) :=
  if pselect (S !=set0) is left _ then
    ereal_sup [set (\sum_(i <- F) a i)%E |
               F in [set F : {fset T} | [set i | i \in F] `<=` S]]
  else 0%:E.

Lemma csum0 (R : realFieldType) (T : choiceType) (a : T -> {ereal R}) :
  csum set0 a = 0%:E.
Proof. by rewrite /csum; case: pselect => // -[]. Qed.

Lemma csum_ge0 (R : realType) (T : choiceType) (a : T -> {ereal R})
    (a0 : forall x, (0%:E <= a x)%E) (I : set T) :
  (0%:E <= csum I a)%E.
Proof.
rewrite /csum; case: pselect => // -[] i Ii.
by apply: ereal_sup_ub; exists fset0 => //; rewrite big_nil.
Qed.

(* TODO: PR to classical_sets in progress *)
Definition trivIset T (A : nat -> set T) :=
  forall i j, i != j -> A i `&` A j = set0.

Lemma trivIset_bigUI T (A : nat -> set T) : trivIset A ->
  forall n m, (n <= m)%N -> \big[setU/set0]_(i < n) A i `&` A m = set0.
Proof.
move=> tA; elim => [|n ih m]; first by move=> m _; rewrite big_ord0 set0I.
by rewrite ltn_neqAle => /andP[? ?]; rewrite big_ord_recr setIUl tA ?setU0 ?ih.
Qed.

Lemma trivIset_setI T (A : nat -> set T) : trivIset A ->
  forall X, trivIset (fun n => X `&` A n).
Proof. by move=> tA X j i /tA; apply: subsetI_eq0; apply subIset; right. Qed.
(*NB: PR end*)

Lemma csum_fset (R : realType) (T : choiceType) (S : {fset T})
    (f : T -> {ereal R}) : (forall i, 0%:E <= f i)%E ->
  csum [set x | x \in S] f = (\sum_(i <- S) f i)%E.
Proof.
move=> f0; rewrite /csum; case: pselect => [S0|]; last first.
  move/set0P/negP/negPn; rewrite eq_set0_fset0 => /eqP ->.
  by rewrite big_seq_fset0.
apply/eqP; rewrite eq_le; apply/andP; split; last first.
  by apply ereal_sup_ub; exists S.
by apply ub_ereal_sup => /= ? -[F FS <-]; exact/lee_sum_nneg_subfset.
Qed.

(* TODO: move? *)
Lemma fset_maximum (A : {fset nat}) : A != fset0 ->
  (exists i, i \in A /\ forall j, j \in A -> j <= i)%nat.
Proof.
move=> A0; move/fset0Pn : (A0) => [a Aa].
set f := nth a (enum_fset A).
have [i [iA H]] := image_maximum (#|` A|.-1)%fset f.
exists (f i); split => [|j Aj].
  by rewrite /f mem_nth // -(@prednK #|` A|) ?ltnS // cardfs_gt0.
have [k [kA <-]] : exists k, (k < #|` A|)%N /\ f k = j.
  by exists (index j A); rewrite index_mem /f nth_index.
rewrite H //.
by move: kA; rewrite -(@prednK #|` A|) // cardfs_gt0.
Qed.

Lemma predeqP {T} (P Q : T -> Prop) : (P = Q) <-> (forall x, P x <-> Q x).
Proof. by split => [->//|?]; rewrite predeqE. Qed.

Lemma csum_countable (R : realType) (T : pointedType) (a : T -> {ereal R})
  (e : nat -> T) (P : pred nat) : (forall n, 0%:E <= a n)%E -> injective e ->
  csum [set e i | i in P] a = lim (fun n => (\sum_(i < n | P i) a (e i))%E).
Proof.
move=> a0 ie; rewrite /csum; case: pselect => [S0|]; last first.
  move=> P0; rewrite (_ : (fun _ => _) = fun=> 0%:E) ?lim_cst// funeqE => n.
  rewrite big1 // => i Pi; move/set0P/negP/negPn/eqP/image_set0_set0 : P0.
  by rewrite predeqE => /(_ i) [] /(_ Pi).
apply/eqP; rewrite eq_le; apply/andP; split; last first.
  apply: ereal_lim_le.
    by apply: (@is_cvg_ereal_nneg_series_cond _ (a \o e)) => *; exact: a0.
  near=> n; apply: ereal_sup_ub.
  exists (e @` [fset (nat_of_ord i) | i in 'I_n & P i])%fset.
    by move=> t /imfsetP[m /imfsetP[j]]; rewrite !inE /= => jP -> ->; exists j.
  rewrite big_imfset //=; last by move=> x y _ _ /ie.
  rewrite big_imfset /=; last by move=> x y _ _; exact: ord_inj.
  by rewrite big_filter big_enum_cond.
apply: ub_ereal_sup => _ [/= F FS <-].
have [/eqP ->|F0] := boolP (F == fset0).
  rewrite big_nil ereal_lim_ge //.
    by apply: (@is_cvg_ereal_nneg_series_cond _ (a \o e)) => *; exact: a0.
  by near=> n; apply: sume_ge0 => *; exact: a0.
have [n FnS] :
    exists n, (F `<=` [fset e (nat_of_ord i) | i in 'I_n & P i])%fset.
    have [n Fn] : exists n, forall x, x \in F -> forall i, e i = x -> (i <= n)%N.
(*      have eF0 : e @^-1` [set x | x \in F] !=set0.
        case/fset0Pn : F0 => t Ft.
        by have [i _ eit] := FS _ Ft; exists i; rewrite /preimage eit.
      have feF : set_finite (e @^-1` [set x | x \in F]).
        by apply: (set_finite_preimage _ (fset_set_finite _)) => ? ? ? ?; exact/ie.
      have [i []] := set_finite_maximum feF eF0.
      by move=> eiF K; exists i => t tF j ejt; apply K; rewrite /preimage ejt.*)
    have /set_finite_fset[eF eFE] : set_finite (e @^-1` [set x | x \in F]).
      by apply: (set_finite_preimage _ (fset_set_finite _)) => ? ? ? ?; exact/ie.
    have : eF != fset0.
      rewrite -eq_set0_fset0 eFE; apply/set0P.
      move: F0; rewrite -eq_set0_fset0 => /set0P[t tF].
      by move: (tF) => /FS[i Pi eit]; exists i; rewrite /preimage eit.
    move/fset_maximum => [i [ieF eFi]]; exists i => t tF j eji; apply eFi.
    by move/predeqP : eFE => /(_ j) /iffRL; apply; rewrite /preimage eji.
  exists n.+1; apply/fsubsetP => x Fx; apply/imfsetP => /=.
  have [j Pj ejx] := FS _ Fx.
  by exists (inord j); rewrite ?inE inordK // ltnS (Fn _ Fx).
apply ereal_lim_ge.
  by apply: (@is_cvg_ereal_nneg_series_cond _ (a \o e)) => *; exact: a0.
near=> m.
rewrite -(big_enum_cond _ 'I_m) -[X in (_ <= X)%E]big_filter /=.
rewrite [X in (_ <= X)%E](_ : _ =
    \sum_(i <- [fset e (nat_of_ord j) | j in 'I_m & P j]%fset) a i)%E; last first.
  by rewrite big_imfset //= => i j _ _ /ie/ord_inj.
apply: lee_sum_nneg_subfset => // x xF; apply/imfsetP.
have nm : (n <= m)%N by near: m; exists n.
move/fsubsetP : FnS => /(_ _ xF) => /imfsetP[/= j ? ejx].
by exists (widen_ord nm j).
Grab Existential Variables. all: end_near.
Qed.

Lemma csum_csum (R : realType) (T : pointedType) (K : set nat)
    (J : nat -> set T) (a : T -> {ereal R}) : (forall x, 0%:E <= a x)%E ->
  K !=set0 -> (forall k, J k !=set0) -> trivIset J ->
  csum (\bigcup_(k in K) (J k)) a = csum K (fun k => csum (J k) a).
Proof.
move=> a0 K0 J0 tJ; set I := \bigcup_(k in K) (J k).
have I0 : I !=set0 by case: K0 => k Kk; have [t Jkt] := J0 k; exists t; exists k.
apply/eqP; rewrite eq_le; apply/andP; split.
  rewrite {1}/csum; case: pselect => // _; apply ub_ereal_sup => /= _ [F FI <-].
  pose FJ := fun k => [fset x in F | x \in J k]%fset.
  have tFJ : forall i j, i != j -> [disjoint FJ i & FJ j]%fset.
    move=> i j ij; rewrite -fsetI_eq0; apply/eqP/fsetP => t; apply/idP/idP=> //.
    apply/negP; rewrite inE => /andP[]; rewrite !inE /= => /andP[Ft].
    rewrite in_setE => tJi /andP[_]; rewrite in_setE => tJj.
    by move: (tJ _ _ ij); rewrite predeqE => /(_ t) [] // /(_ (conj tJi tJj)).
  pose KFJ := [set k | K k /\ FJ k != fset0].
(* TODO:  pose g := fun t => xget 0%N [set n | t \in J n].
  have : [set k | FJ k != fset0] = [set k | k \in (g @` F)%fset].
    rewrite predeqE => i; split.
      move/fset0Pn => [t]; rewrite !inE /= => /andP[tF tJi].
      apply/imfsetP; exists t => //; rewrite /g.
      admit. (* utiliser les prop de triviset *)
    admit. *)
  have : set_finite KFJ.
    suff suppFJ : set_finite [set k | FJ k != fset0].
      have KFJsuppF : KFJ `<=` [set k | FJ k != fset0] by move=> t [].
      by have [] := set_finite_subset KFJsuppF _.
    pose g := fun t => xget 0%N [set n | t \in J n].
    have sur_g : surjective [set x | x \in F] [set k | FJ k != fset0] g.
      move=> i /fset0Pn[t]; rewrite /FJ !inE /= => /andP[Ft tJi].
      exists t; split => //; rewrite /g; case: xgetP; last by move/(_ i).
      move=> j _ tJj; apply/eqP/negPn/negP => /(tJ i j).
      rewrite predeqE => /(_ t); rewrite !in_setE in tJi, tJj.
      by case=> /(_ (conj tJi tJj)).
    by case: (surjective_set_finite sur_g (fset_set_finite F)).
  move/set_finite_fset => [L LKFJ].
  have LK : [set i | i \in L] `<=` K.
    by move=> /= i iL; move/predeqP : LKFJ => /(_ i) /iffLR /(_ iL) [].
  have -> : (\sum_(i <- F) a i = \sum_(k <- L) (\sum_(i <- FJ k) a i)%E)%E.
    suff -> : F = (\big[fsetU/fset0]_(x <- L) (FJ x))%fset.
      by apply/partition_disjoint_bigfcup; exact: tFJ.
    apply/fsetP => t; apply/idP/idP => [tF|/bigfcupP[i]]; last first.
      by rewrite andbT => iM; rewrite /FJ !inE => /andP[].
    have := FI _ tF; move=> -[i Ki Jit].
    apply/bigfcupP ; exists i; rewrite ?andbT.
      move/predeqP : LKFJ => /(_ i) /iffRL; apply; split => //.
      apply/negP => /eqP/fsetP/(_ t).
      by rewrite !inE /= => /negbT /negP; apply; rewrite tF /= in_setE.
    by rewrite /FJ !inE /= tF in_setE.
  apply: (@le_trans _ _ (\sum_(k <- L) (csum (J k) a))%E).
    apply: lee_sum => i iM; rewrite /csum; case: pselect => // _.
    apply: ereal_sup_ub; exists (FJ i) => // t.
    by rewrite /FJ !inE /= => /andP[_]; rewrite in_setE.
  rewrite [in X in (_ <= X)%E]/csum; case: pselect => // _.
  by apply ereal_sup_ub; exists L.
rewrite {1}[in X in (X <= _)%E]/csum; case: pselect => // _.
apply ub_ereal_sup => /= _ [L LK <-].
have [/eqP ->|L0] := boolP (L == fset0); first by rewrite big_nil csum_ge0.
have /gee0P[->|[r r0 csumIar]] := csum_ge0 a0 I; first by rewrite lee_pinfty.
apply lee_adde => e; rewrite -lee_subl_addr.
suff : (\sum_(i < #|` L |) csum (J (nth O L i)) a - (e)%:num%:E <= csum I a)%E.
  by apply: le_trans; apply: lee_add2r; rewrite (big_nth O) big_mkord lee_sum.
set P := (fun (Fj : {fset T}%fset) (j : 'I_#|`L|) =>
  [set x | x \in Fj] `<=` J (nth 0%N L j) /\
  (csum (J (nth 0%N L j)) a - (e%:num / #|` L |%:R)%:E < \sum_(s <- Fj) a s))%E.
have [Fj csumFj] : exists F, forall j, P (F j) j.
  suff : forall j, exists Fj, P Fj j.
    by case/(@choice _ _ (fun i F => P F i)) => Fj ?; exists Fj.
  move=> j; rewrite /P /csum; case: pselect => // _; set es := ereal_sup _.
  have [esoo|[c c0 esc]] : es = +oo%E \/ exists2 r, r >= 0 & es = r%:E.
    suff : (0%:E <= es)%E by move/gee0P.
    by apply ereal_sup_ub; exists fset0 => //; rewrite big_nil.
  - move: csumIar; rewrite /csum; case: pselect => // _.
    set es' := ereal_sup _ => es'r.
    suff : (es <= es')%E by rewrite esoo es'r.
    apply: le_ereal_sup => x [F FJ Fx]; exists F => //.
    move/subset_trans : FJ; apply => t Jt.
    by exists (nth 0%N L j) => //; apply LK; rewrite mem_nth.
  - have eL0 : 0 < e%:num / #|` L |%:R by rewrite divr_gt0 // ltr0n cardfs_gt0.
    rewrite (_ : e%:num / _ = (PosNum eL0)%:num) // esc.
    exact: ub_ereal_sup_adherent2.
pose F := \big[fsetU/fset0]_(i < #|`L|) Fj i.
apply: (@le_trans _ _ (\sum_(i <- F) a i)%E); last first.
  rewrite /csum; case pselect => // _; apply ereal_sup_ub; exists F => //.
  move=> t /bigfcupP[/= i _] /(proj1 (csumFj i)) Jt.
  by exists (nth 0%N L i) => //; apply LK; rewrite mem_nth.
apply: (@le_trans _ _ (\sum_(i < #|`L|) (\sum_(j <- Fj i) a j)%E)%E); last first.
  have tFj : (forall i j : 'I_#|`L|, i != j -> [disjoint Fj i & Fj j])%fset.
    move=> i j ij; rewrite -fsetI_eq0; rewrite -eq_set0_fset0.
    have Jij : J (nth 0%N L i) `&` J (nth 0%N L j) = set0.
      apply tJ; apply: contra ij => /eqP /(congr1 (fun x => index x L)).
      by rewrite index_uniq // index_uniq // => /ord_inj ->.
    apply/eqP; rewrite predeqE => t; split => //; rewrite inE => /andP[].
    by move=> /(proj1 (csumFj i)) ? /(proj1 (csumFj j)) ?; rewrite -Jij; split.
  rewrite le_eqVlt; apply/orP; left; apply/eqP/esym.
  pose IL := [fset i | i in 'I_#|`L|]%fset.
  have -> : F = (\bigcup_(i <- IL) Fj i)%fset
    by rewrite /IL big_imfset //= big_enum.
  transitivity ((\sum_(i <- IL) (\sum_(j <- Fj i) a j)%E)%E); last first.
    by rewrite /IL big_imfset //= big_enum.
  by apply partition_disjoint_bigfcup; exact: tFj.
rewrite (_ : e%:num = \sum_(i < #|`L|) (e%:num / #|`L|%:R)); last first.
  rewrite big_const iter_addr addr0 card_ord -mulr_natr.
  by rewrite -mulrA mulVr ?mulr1 // unitfE pnatr_eq0 cardfs_eq0.
rewrite -NERFin (@big_morph _ _ _ 0 _ _ _ (@opprD R)) ?oppr0 //.
rewrite (@big_morph _ _ _ 0%:E _ _ _ addERFin) // -big_split /=.
by apply: lee_sum => /= i _; exact: (ltW (proj2 (csumFj i))).
Qed.
