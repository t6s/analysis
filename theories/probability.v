(* mathcomp analysis (c) 2022 Inria and AIST. License: CeCILL-C.              *)
From mathcomp Require Import all_ssreflect.
From mathcomp Require Import ssralg poly ssrnum ssrint interval finmap.
From mathcomp Require Import mathcomp_extra boolp classical_sets functions.
From mathcomp Require Import cardinality fsbigop.
From HB Require Import structures.
From mathcomp Require Import exp numfun lebesgue_measure lebesgue_integral.
From mathcomp Require Import reals ereal signed topology normedtype sequences.
From mathcomp Require Import esum measure exp numfun lebesgue_measure.
From mathcomp Require Import lebesgue_integral kernel hoelder derive.

(**md**************************************************************************)
(* # Probability                                                              *)
(*                                                                            *)
(* This file provides basic notions of probability theory. See measure.v for  *)
(* the type probability T R (a measure that sums to 1).                       *)
(*                                                                            *)
(* ```                                                                        *)
(*         {RV P >-> R} == real random variable: a measurable function from   *)
(*                         the measurableType of the probability P to R       *)
(*     distribution P X == measure image of the probability measure P by the  *)
(*                         random variable X : {RV P -> R}                    *)
(*                         P as type probability T R with T of type           *)
(*                         measurableType.                                    *)
(*                         Declared as an instance of probability measure.    *)
(*              'E_P[X] == expectation of the real measurable function X      *)
(*       covariance X Y == covariance between real random variable X and Y    *)
(*              'V_P[X] == variance of the real random variable X             *)
(*        mmt_gen_fun X == moment generating function of the random variable  *)
(*                         X                                                  *)
(*      {dmfun T >-> R} == type of discrete real-valued measurable functions  *)
(*        {dRV P >-> R} == real-valued discrete random variable               *)
(*            dRV_dom X == domain of the discrete random variable X           *)
(*           dRV_enum X == bijection between the domain and the range of X    *)
(*             pmf X r := fine (P (X @^-1` [set r]))                          *)
(*        enum_prob X k == probability of the kth value in the range of X     *)
(* ```                                                                        *)
(*                                                                            *)
(* ```                                                                        *)
(*      bernoulli_pmf p == Bernoulli pmf                                      *)
(*          bernoulli p == Bernoulli probability measure when 0 <= p <= 1     *)
(*                         and \d_false otherwise                             *)
(*     binomial_pmf n p == binomial pmf                                       *)
(*    binomial_prob n p == binomial probability measure when 0 <= p <= 1      *)
(*                         and \d_0%N otherwise                               *)
(*       bin_prob n k p == $\binom{n}{k}p^k (1-p)^(n-k)$                      *)
(*                         Computes a binomial distribution term for          *)
(*                         k successes in n trials with success rate p        *)
(*      uniform_pdf a b == uniform pdf                                        *)
(*  uniform_prob a b ab == uniform probability over the interval [a,b]        *)
(*                         with ab0 a proof that 0 < b - a                    *)
(* ```                                                                        *)
(*                                                                            *)
(******************************************************************************)

Reserved Notation "'{' 'RV' P >-> R '}'"
  (at level 0, format "'{' 'RV'  P  '>->'  R '}'").
Reserved Notation "''E_' P [ X ]" (format "''E_' P [ X ]", at level 5).
Reserved Notation "''V_' P [ X ]" (format "''V_' P [ X ]", at level 5).
Reserved Notation "' P [ A | B ]".
Reserved Notation "{ 'dmfun' aT >-> T }"
  (at level 0, format "{ 'dmfun'  aT  >->  T }").
Reserved Notation "'{' 'dRV' P >-> R '}'"
  (at level 0, format "'{' 'dRV'  P  '>->'  R '}'").

Notation "\prod_ ( i <- r | P ) F" :=
  (\big[*%E/1%:E]_(i <- r | P%B) F%E) : ereal_scope.
Notation "\prod_ ( i <- r ) F" :=
  (\big[*%E/1%:E]_(i <- r) F%E) : ereal_scope.
Notation "\prod_ ( m <= i < n | P ) F" :=
  (\big[*%E/1%:E]_(m <= i < n | P%B) F%E) : ereal_scope.
Notation "\prod_ ( m <= i < n ) F" :=
  (\big[*%E/1%:E]_(m <= i < n) F%E) : ereal_scope.
Notation "\prod_ ( i | P ) F" :=
  (\big[*%E/1%:E]_(i | P%B) F%E) : ereal_scope.
Notation "\prod_ i F" :=
  (\big[*%E/1%:E]_i F%E) : ereal_scope.
Notation "\prod_ ( i : t | P ) F" :=
  (\big[*%E/1%:E]_(i : t | P%B) F%E) (only parsing) : ereal_scope.
Notation "\prod_ ( i : t ) F" :=
  (\big[*%E/1%:E]_(i : t) F%E) (only parsing) : ereal_scope.
Notation "\prod_ ( i < n | P ) F" :=
  (\big[*%E/1%:E]_(i < n | P%B) F%E) : ereal_scope.
Notation "\prod_ ( i < n ) F" :=
  (\big[*%E/1%:E]_(i < n) F%E) : ereal_scope.
Notation "\prod_ ( i 'in' A | P ) F" :=
  (\big[*%E/1%:E]_(i in A | P%B) F%E) : ereal_scope.
Notation "\prod_ ( i 'in' A ) F" :=
  (\big[*%E/1%:E]_(i in A) F%E) : ereal_scope.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import Order.TTheory GRing.Theory Num.Def Num.Theory.
Import numFieldTopology.Exports.

Local Open Scope classical_set_scope.
Local Open Scope ring_scope.

Definition random_variable (d d' : _) (T : measurableType d) (R : realType) (U : measurableType d')
  (P : probability T R) := {mfun T >-> U}.

Notation "{ 'RV' P >-> U }" := (@random_variable _ _ _ _ U P) : form_scope.

Lemma notin_range_measure d d' (T : measurableType d) (R : realType) (U : measurableType d')
    (P : {measure set T -> \bar R}) (X : T -> U) r :
  r \notin range X -> P (X @^-1` [set r]) = 0%E.
Proof. by rewrite notin_setE => hr; rewrite preimage10. Qed.

Lemma probability_range d d' (T : measurableType d) (R : realType) (U : measurableType d')
  (P : probability T R) (X : {RV P >-> U}) : P (X @^-1` range X) = 1%E.
Proof. by rewrite preimage_range probability_setT. Qed.

Definition distribution d d' (T : measurableType d) (R : realType) (U : measurableType d')
    (P : probability T R) (X : {mfun T >-> U}) : set U -> \bar R :=
  pushforward P (@measurable_funP _ _ _ _ X).

Section distribution_is_probability.
Context d d' (T : measurableType d) (U : measurableType d') (R : realType) (P : probability T R)
        (X : {mfun T >-> U}).

Let distribution0 : distribution P X set0 = 0%E.
Proof. exact: measure0. Qed.

Let distribution_ge0 A : (0 <= distribution P X A)%E.
Proof. exact: measure_ge0. Qed.

Let distribution_sigma_additive : semi_sigma_additive (distribution P X).
Proof. exact: measure_semi_sigma_additive. Qed.

HB.instance Definition _ := isMeasure.Build _ _ _ (distribution P X)
  distribution0 distribution_ge0 distribution_sigma_additive.

Let distribution_is_probability : distribution P X [set: _] = 1%:E.
Proof.
by rewrite /distribution /= /pushforward /= preimage_setT probability_setT.
Qed.

HB.instance Definition _ := Measure_isProbability.Build _ _ _
  (distribution P X) distribution_is_probability.

End distribution_is_probability.

Section probability.
Local Open Scope ereal_scope.
Context d (T : measurableType d) (R : realType) (P : probability T R).

Lemma probability_setC A : d.-measurable A -> P (~` A) = 1 - P A.
Proof.
move=> mA; rewrite -(@probability_setT _ _ _ P) -[in RHS](setTI A) -measureD ?setTD ?setCK//.
by rewrite [ltLHS](@probability_setT _ _ _ P) ltry.
Qed.

Lemma probability_setC' A : d.-measurable A -> P A = 1 - P (~` A).
Proof.
move=> mA. rewrite -(@probability_setT _ _ _ P) -[in RHS](setTI (~` A)) -measureD ?setTD ?setCK//; first exact: measurableC.
by rewrite [ltLHS](@probability_setT _ _ _ P) ltry.
Qed.

Lemma probability_fin_num A : d.-measurable A -> P A \is a fin_num.
Proof.
move=> mA.
rewrite fin_numElt.
rewrite (le_lt_trans (probability_le1 P mA) (ltry _)).
by rewrite (lt_le_trans ltNy0 (measure_ge0 P _)).
Qed.

End probability.

Section transfer_probability.
Local Open Scope ereal_scope.
Context d d' (T : measurableType d) (U : measurableType d') (R : realType) (P : probability T R).

Lemma probability_distribution (X : {RV P >-> U}) r :
  P [set x | X x = r] = distribution P X [set r].
Proof. by []. Qed.

Lemma integral_distribution (X : {RV P >-> U}) (f : U -> \bar R) :
    measurable_fun [set: U] f -> (forall y, 0 <= f y) ->
  \int[distribution P X]_y f y = \int[P]_x (f \o X) x.
Proof. by move=> mf f0; rewrite ge0_integral_pushforward. Qed.

End transfer_probability.

HB.lock Definition expectation {d} {T : measurableType d} {R : realType}
  (P : probability T R) (X : T -> R) := (\int[P]_w (X w)%:E)%E.
Canonical expectation_unlockable := Unlockable expectation.unlock.
Arguments expectation {d T R} P _%_R.
Notation "''E_' P [ X ]" := (@expectation _ _ _ P X) : ereal_scope.

Section expectation_lemmas.
Local Open Scope ereal_scope.
Context d (T : measurableType d) (R : realType) (P : probability T R).

Lemma expectation_fin_num (X : {RV P >-> R}) : P.-integrable setT (EFin \o X) ->
  'E_P[X] \is a fin_num.
Proof. by move=> ?; rewrite unlock integral_fune_fin_num. Qed.

Lemma expectation_cst r : 'E_P[cst r] = r%:E.
Proof. by rewrite unlock/= integral_cst//= probability_setT mule1. Qed.

Lemma expectation_indic (A : set T) (mA : measurable A) : 'E_P[\1_A] = P A.
Proof. by rewrite unlock integral_indic// setIT. Qed.

Lemma integrable_expectation (X : {RV P >-> R})
  (iX : P.-integrable [set: T] (EFin \o X)) : `| 'E_P[X] | < +oo.
Proof.
move: iX => /integrableP[? Xoo]; rewrite (le_lt_trans _ Xoo)// unlock.
exact: le_trans (le_abse_integral _ _ _).
Qed.

Lemma expectationM (X : {RV P >-> R}) (iX : P.-integrable [set: T] (EFin \o X))
  (k : R) : 'E_P[k \o* X] = k%:E * 'E_P [X].
Proof. by rewrite unlock muleC -integralZr. Qed.

Lemma expectation_ge0 (X : {RV P >-> R}) :
  (forall x, 0 <= X x)%R -> 0 <= 'E_P[X].
Proof.
by move=> ?; rewrite unlock integral_ge0// => x _; rewrite lee_fin.
Qed.

Lemma expectation_le (X Y : T -> R) :
    measurable_fun [set: T] X -> measurable_fun [set: T] Y ->
    (forall x, 0 <= X x)%R -> (forall x, 0 <= Y x)%R ->
  {ae P, (forall x, X x <= Y x)%R} -> 'E_P[X] <= 'E_P[Y].
Proof.
move=> mX mY X0 Y0 XY; rewrite unlock ae_ge0_le_integral => //.
- by move=> t _; apply: X0.
- exact/measurable_EFinP.
- by move=> t _; apply: Y0.
- exact/measurable_EFinP.
- move: XY => [N [mN PN XYN]]; exists N; split => // t /= h.
  by apply: XYN => /=; apply: contra_not h; rewrite lee_fin.
Qed.

Lemma expectationD (X Y : {RV P >-> R}) :
    P.-integrable [set: T] (EFin \o X) -> P.-integrable [set: T] (EFin \o Y) ->
  'E_P[X \+ Y] = 'E_P[X] + 'E_P[Y].
Proof. by move=> ? ?; rewrite unlock integralD_EFin. Qed.

Lemma expectationB (X Y : {RV P >-> R}) :
    P.-integrable [set: T] (EFin \o X) -> P.-integrable [set: T] (EFin \o Y) ->
  'E_P[X \- Y] = 'E_P[X] - 'E_P[Y].
Proof. by move=> ? ?; rewrite unlock integralB_EFin. Qed.

Lemma expectation_sum (X : seq {RV P >-> R}) :
    (forall Xi, Xi \in X -> P.-integrable [set: T] (EFin \o Xi)) ->
  'E_P[\sum_(Xi <- X) Xi] = \sum_(Xi <- X) 'E_P[Xi].
Proof.
elim: X => [|X0 X IHX] intX; first by rewrite !big_nil expectation_cst.
have intX0 : P.-integrable [set: T] (EFin \o X0).
  by apply: intX; rewrite in_cons eqxx.
have {}intX Xi : Xi \in X -> P.-integrable [set: T] (EFin \o Xi).
  by move=> XiX; apply: intX; rewrite in_cons XiX orbT.
rewrite !big_cons expectationD ?IHX// (_ : _ \o _ = fun x =>
    \sum_(f <- map (fun x : {RV P >-> R} => EFin \o x) X) f x).
  by apply: integrable_sum => // _ /mapP[h hX ->]; exact: intX.
by apply/funext => t/=; rewrite big_map sumEFin mfun_sum.
Qed.

Lemma sum_RV_ge0 (X : seq {RV P >-> R}) x :
    (forall Xi, Xi \in X -> 0 <= Xi x)%R ->
    (0 <= (\sum_(Xi <- X) Xi) x)%R.
Proof.
elim: X => [|X0 X IHX] Xi_ge0; first by rewrite big_nil.
rewrite big_cons.
rewrite addr_ge0//=; first by rewrite Xi_ge0// in_cons eq_refl.
by rewrite IHX// => Xi XiX; rewrite Xi_ge0// in_cons XiX orbT.
Qed.

End expectation_lemmas.




(* Section product_lebesgue_measure. *)
(* Context {R : realType}. *)

(* Definition p := [the sigma_finite_measure _ _ of *)
(*   ([the sigma_finite_measure _ _ of (@lebesgue_measure R)] \x *)
(*    [the sigma_finite_measure _ _ of (@lebesgue_measure R)])]%E. *)

(* Fixpoint iter_mprod (n : nat) : {d & measurableType d} := *)
(*   match n with *)
(*   | 0%N => existT measurableType _ (salgebraType R.-ocitv.-measurable) *)
(*   | n'.+1 => let t' := iter_mprod n' in *)
(*     let a := existT measurableType _ (salgebraType R.-ocitv.-measurable) in *)
(*     existT _ _ [the measurableType (projT1 a, projT1 t').-prod of *)
(*                 (projT2 a * projT2 t')%type] *)
(*   end. *)

(* Fixpoint measurable_of_typ (t : typ) : {d & measurableType d} := *)
(*   match t with *)
(*   | Unit => existT _ _ munit *)
(*   | Bool => existT _ _ mbool *)
(*   | Nat => existT _ _ (nat : measurableType _) *)
(*   | Real => existT _ _ *)
(*     [the measurableType _ of (@measurableTypeR R)] *)
(*   end. *)

(* Set Printing All. *)

(* Fixpoint measurable_of_typ (d : nat) : {d & measurableType d} := *)
(*   match d with *)
(*   | O => existT _ _ (@lebesgue_measure R) *)
(*   | d'.+1 => existT _ _ *)
(*       [the measurableType (projT1 (@lebesgue_measure R), *)
(*                            projT1 (measurable_of_typ d')).-prod%mdisp of *)
(*       ((@lebesgue_measure R) \x *)
(*        projT2 (measurable_of_typ d'))%E] *)
(*   end. *)

(* Definition mtyp_disp t : measure_display := projT1 (measurable_of_typ t). *)

(* Definition mtyp t : measurableType (mtyp_disp t) := *)
(*   projT2 (measurable_of_typ t). *)

(* Definition measurable_of_seq (l : seq typ) : {d & measurableType d} := *)
(*   iter_mprod (map measurable_of_typ l). *)


(* Fixpoint leb_meas (d : nat) := *)
(*   match d with *)
(*   | 0%N => @lebesgue_measure R *)
(*   | d'.+1 => *)
(*     ((leb_meas d') \x (@lebesgue_measure R))%E *)
(*   end. *)





(* End product_lebesgue_measure. *)

(* independent class of events, klenke def 2.11, p.59 *)
Section independent_class.
Context {d : measure_display} {T : measurableType d} {R : realType}
        {P : probability T R}.
Variable (I : choiceType) (E : I -> set (set T)).
Hypothesis mE : forall i, E i `<=` measurable.

Definition independent_class :=
  forall J : {fset I},
    forall e : I -> set T, (forall i, (E i) (e i)) ->
      P (\big[setI/setT]_(i <- J) e i) = (\prod_(i <- J) P (e i))%E.

End independent_class.

Section independent_events.
Context d (T : measurableType d) (R : realType) (P : probability T R).
Local Open Scope ereal_scope.

Definition mutually_independent (I : choiceType) (A : set I) (E : I -> set T) :=
  (forall i, A i -> measurable (E i)) /\
  forall B : {fset I}, [set` B] `<=` A ->
    P (\bigcap_(i in [set` B]) E i) = \prod_(i <- B) P (E i).

Lemma sub_mutually_independent (I : choiceType) (A B : set I) (E : I -> set T) :
  A `<=` B -> mutually_independent B E -> mutually_independent A E.
Proof.
by move=> AB [mE h]; split=> [i /AB/mE//|C CA]; apply: h; apply: subset_trans AB.
Qed.

Definition kwise_independent (I : choiceType) (A : set I) (E : I -> set T) k :=
  (forall i, A i -> measurable (E i)) /\
  forall B : {fset I}, [set` B] `<=` A -> (#|` B | <= k)%nat ->
    P (\bigcap_(i in [set` B]) E i) = \prod_(i <- B) P (E i).

Lemma sub_kwise_independent (I : choiceType) (A B : set I) (E : I -> set T) k :
  A `<=` B -> kwise_independent B E k -> kwise_independent A E k.
Proof.
by move=> AB [mE h]; split=> [i /AB/mE//|C CA]; apply: h; apply: subset_trans AB.
Qed.

Lemma mutual_indep_is_kwise_indep (I : choiceType) (A : set I) (E : I -> set T) k :
  mutually_independent A E -> kwise_independent A E k.
Proof.
rewrite/mutually_independent/kwise_independent.
move=> [mE miE]; split=> // B BleA _.
exact: miE.
Qed.

Lemma nwise_indep_is_mutual_indep (I : choiceType) (A : {fset I}) (E : I -> set T) n :
  #|` A | = n -> kwise_independent [set` A] E n -> mutually_independent [set` A] E.
Proof.
rewrite/mutually_independent/kwise_independent.
move=> nA [mE miE]; split=> // B BleA.
apply: miE => //; rewrite -nA fsubset_leq_card//.
by apply/fsubsetP => x xB; exact: (BleA x).
Qed.

Lemma mutually_independent_weak (I : choiceType) (E : I -> set T) (B : set I) :
  (forall b, ~ B b -> E b = setT) ->
  mutually_independent [set: I] E <->
  mutually_independent B E.
Proof.
move=> BE; split; first exact: sub_mutually_independent.
move=> [mE h]; split=> [i _|C _].
  by have [Bi|Bi] := pselect (B i); [exact: mE|rewrite BE].
have [CB|CB] := pselect ([set` C] `<=` B); first by rewrite h.
rewrite -(setIT [set` C]) -(setUv B) setIUr bigcap_setU.
rewrite (@bigcapT _ _ (_ `&` ~` _)) ?setIT//; last by move=> i [_ /BE].
have [D CBD] : exists D : {fset I}, [set` C] `&` B = [set` D].
  exists (fset_set ([set` C] `&` B)).
  by rewrite fset_setK//; exact: finite_setIl.
rewrite CBD h; last first.
  rewrite -CBD; exact: subIsetr.
rewrite [RHS]fsbig_seq//= [RHS](fsbigID B)//=.
rewrite [X in _ * X](_ : _ = 1) ?mule1; last first.
  by rewrite fsbig1// => m [_ /BE] ->; rewrite probability_setT.
by rewrite CBD -fsbig_seq.
Qed.

Lemma kwise_independent_weak (I : choiceType) (E : I -> set T) (B : set I) k :
  (forall b, ~ B b -> E b = setT) ->
  kwise_independent [set: I] E k <->
  kwise_independent B E k.
Proof.
move=> BE; split; first exact: sub_kwise_independent.
move=> [mE h]; split=> [i _|C _ Ck].
  by have [Bi|Bi] := pselect (B i); [exact: mE|rewrite BE].
have [CB|CB] := pselect ([set` C] `<=` B); first by rewrite h.
rewrite -(setIT [set` C]) -(setUv B) setIUr bigcap_setU.
rewrite (@bigcapT _ _ (_ `&` ~` _)) ?setIT//; last by move=> i [_ /BE].
have [D CBD] : exists D : {fset I}, [set` C] `&` B = [set` D].
  exists (fset_set ([set` C] `&` B)).
  by rewrite fset_setK//; exact: finite_setIl.
rewrite CBD h; last 2 first.
  - rewrite -CBD; exact: subIsetr.
  - rewrite (leq_trans _ Ck)// fsubset_leq_card// -(set_fsetK D) -(set_fsetK C).
    by rewrite -fset_set_sub// -CBD; exact: subIsetl.
rewrite [RHS]fsbig_seq//= [RHS](fsbigID B)//=.
rewrite [X in _ * X](_ : _ = 1) ?mule1; last first.
  by rewrite fsbig1// => m [_ /BE] ->; rewrite probability_setT.
by rewrite CBD -fsbig_seq.
Qed.

Lemma kwise_independent_weak01 E1 E2 :
  kwise_independent [set: nat] (bigcap2 E1 E2) 2%N <->
  kwise_independent [set 0%N; 1%N] (bigcap2 E1 E2) 2%N.
Proof.
apply: kwise_independent_weak.
by move=> n /= /not_orP[/eqP /negbTE -> /eqP /negbTE ->].
Qed.

Lemma mutually_independent_weak' (I : choiceType) (E : I -> set T) (B : set I) :
  (forall b, ~ B b -> E b = setT) ->
  mutually_independent [set: I] E <->
  mutually_independent B E.
Proof.
move=> BE; split; first exact: sub_mutually_independent.
move=> [mE h]; split=> [i _|C CI].
  by have [Bi|Bi] := pselect (B i); [exact: mE|rewrite BE].
have [CB|CB] := pselect ([set` C] `<=` B); first by rewrite h.
rewrite -(setIT [set` C]) -(setUv B) setIUr bigcap_setU.
rewrite (@bigcapT _ _ (_ `&` ~` _)) ?setIT//; last by move=> i [_ /BE].
have [D CBD] : exists D : {fset I}, [set` C] `&` B = [set` D].
  exists (fset_set ([set` C] `&` B)).
  by rewrite fset_setK//; exact: finite_setIl.
rewrite CBD h; last first.
  - rewrite -CBD; exact: subIsetr.
rewrite [RHS]fsbig_seq//= [RHS](fsbigID B)//=.
rewrite [X in _ * X](_ : _ = 1) ?mule1; last first.
  by rewrite fsbig1// => m [_ /BE] ->; rewrite probability_setT.
by rewrite CBD -fsbig_seq.
Qed.

Definition pairwise_independent E1 E2 :=
  kwise_independent [set 0; 1]%N (bigcap2 E1 E2) 2.

Lemma pairwise_independentM_old (E1 E2 : set T) :
  pairwise_independent E1 E2 <->
  [/\ d.-measurable E1, d.-measurable E2 & P (E1 `&` E2) = P E1 * P E2].
Proof.
split.
- move=> [mE1E2 /(_ [fset 0%N; 1%N]%fset)].
  rewrite bigcap_fset !big_fsetU1 ?inE//= !big_seq_fset1/= => ->; last 2 first.
  + by rewrite set_fsetU !set_fset1; exact: subset_refl.
  + rewrite cardfs2//.
  split => //.
  + by apply: (mE1E2 0%N) => /=; left.
  + by apply: (mE1E2 1%N) => /=; right.
- move=> [mE1 mE2 E1E2M].
  split => //=.
  + by move=> [| [| [|]]]//=.
  + move=> B _; have [B0|B0] := boolP (0%N \in B); last first.
      have [B1|B1] := boolP (1%N \in B); last first.
        rewrite big1_fset; last first.
          move=> k kB _; rewrite /bigcap2.
          move: kB B0; case: ifPn => [/eqP -> ->//|k0 kB B0].
          move: kB B1; case: ifPn => [/eqP -> ->//|_ _ _].
          by rewrite probability_setT.
        rewrite bigcapT ?probability_setT// => k/= kB.
        move: kB B0 B1; case: ifPn => [/eqP -> ->//|k0].
        by case: ifPn => [/eqP -> ->|].
      rewrite (bigcap_setD1 1%N _ [set` B])//=.
      rewrite bigcapT ?setIT; last first.
        move=> k [/= kB /eqP /negbTE ->].
        by move: kB B0; case: ifPn => [/eqP -> ->|].
      rewrite (big_fsetD1 1%N)//= big1_fset ?mule1// => k.
      rewrite !inE => /andP[/negbTE -> kB] _.
      move: kB B0; case: ifPn => [/eqP -> ->//|k0 kB B0].
      by rewrite probability_setT.
    rewrite (bigcap_setD1 0%N _ [set` B])//.
    have [B1|B1] := boolP (1%N \in B); last first.
      rewrite bigcapT ?setIT; last first.
        move=> k [/= kB /eqP /negbTE ->].
        by move: kB B1; case: ifPn => [/eqP -> ->|].
      rewrite (big_fsetD1 0%N)//= big1_fset ?mule1// => k.
      rewrite !inE => /andP[/negbTE -> kB] _.
      move: kB B1; case: ifPn => [/eqP -> ->//|k1 kB B1].
      by rewrite probability_setT.
    rewrite (bigcap_setD1 1%N _ ([set` B] `\ 0%N))// bigcapT ?setIT; last first.
      by move=> n/= [[nB]/eqP/negbTE -> /eqP/negbTE ->].
    rewrite E1E2M (big_fsetD1 0%N)//= (big_fsetD1 1%N)/=; last by rewrite !inE B1.
    rewrite big1_fset ?mule1//= => k.
    rewrite !inE => -/and3P[/negbTE -> /negbTE -> kB] _;
    by rewrite probability_setT.
Qed.

Lemma pairwise_independentM (E1 E2 : set T) :
  pairwise_independent E1 E2 <->
  [/\ d.-measurable E1, d.-measurable E2 & P (E1 `&` E2) = P E1 * P E2].
Proof.
split.
- move=> [mE1E2 /(_ [fset 0%N; 1%N]%fset)].
  rewrite bigcap_fset !big_fsetU1 ?inE//= !big_seq_fset1/= => ->; last 2 first.
  + by rewrite set_fsetU !set_fset1; exact: subset_refl.
  + by rewrite cardfs2.
  split => //.
  + by apply: (mE1E2 0%N) => /=; left.
  + by apply: (mE1E2 1%N) => /=; right.
- move=> [mE1 mE2 E1E2M].
  rewrite /pairwise_independent.
  split.
  + by move=> [| [| [|]]]//=.
  + move=> B B01 B2.
    have [B_set0|B_set0|B_set1|B_set01] := subset_set2 B01.
    * rewrite B_set0.
      move: B_set0 => /eqP; rewrite set_fset_eq0 => /eqP ->.
      by rewrite big_nil bigcap_set0 probability_setT.
    * rewrite B_set0 bigcap_set1 /=.
      by rewrite fsbig_seq//= B_set0 fsbig_set1/=.
    * rewrite B_set1 bigcap_set1 /=.
      by rewrite fsbig_seq//= B_set1 fsbig_set1/=.
    * rewrite B_set01 bigcap_setU1 bigcap_set1/=.
      rewrite fsbig_seq//= B_set01.
      rewrite fsbigU//=; last first.
        by move=> n [/= ->].
      by rewrite !fsbig_set1//=.
Qed.

Lemma pairwise_independent_setC (E1 E2 : set T) :
  pairwise_independent E1 E2 -> pairwise_independent E1 (~` E2).
Proof.
rewrite/pairwise_independent.
move/pairwise_independentM=> [mE1 mE2 h].
apply/pairwise_independentM; split=> //.
- exact: measurableC.
- rewrite -setDE measureD//; last first.
    exact: (le_lt_trans (probability_le1 P mE1) (ltry _)).
  rewrite probability_setC// muleBr// ?mule1 -?h//.
  exact: probability_fin_num.
Qed.

Lemma pairwise_independentC (E1 E2 : set T) :
  pairwise_independent E1 E2 -> pairwise_independent E2 E1.
Proof.
rewrite/pairwise_independent/kwise_independent; move=> [mE1E2 /(_ [fset 0%N; 1%N]%fset)].
rewrite bigcap_fset !big_fsetU1 ?inE//= !big_seq_fset1/= => h.
split.
- case=> [_|[_|]]//=.
  + by apply: (mE1E2 1%N) => /=; right.
  + by apply: (mE1E2 0%N) => /=; left.
- move=> B B01 B2.
  have [B_set0|B_set0|B_set1|B_set01] := subset_set2 B01.
  + rewrite B_set0.
    move: B_set0 => /eqP; rewrite set_fset_eq0 => /eqP ->.
    by rewrite big_nil bigcap_set0 probability_setT.
  + rewrite B_set0 bigcap_set1 /=.
    by rewrite fsbig_seq//= B_set0 fsbig_set1/=.
  + rewrite B_set1 bigcap_set1 /=.
    by rewrite fsbig_seq//= B_set1 fsbig_set1/=.
  + rewrite B_set01 bigcap_setU1 bigcap_set1/=.
    rewrite fsbig_seq//= B_set01.
    rewrite fsbigU//=; last first.
    by move=> n [/= ->].
    rewrite !fsbig_set1//= muleC setIC.
    apply: h.
    * by rewrite set_fsetU !set_fset1; exact: subset_refl.
    * by rewrite cardfs2.
Qed.
(* ale: maybe interesting is thm 8.3 and exercise 8.6 from shoup/ntb at this point *)

End independent_events.

Section conditional_probability.
Context d (T : measurableType d) (R : realType).
Local Open Scope ereal_scope.

Definition conditional_probability (P : probability T R) E1 E2 := (fine (P (E1 `&` E2)) / fine (P E2))%:E.
Local Notation "' P [ E1 | E2 ]" := (conditional_probability P E1 E2).

Lemma conditional_independence (P : probability T R) E1 E2 :
  P E2 != 0 -> pairwise_independent P E1 E2 -> 'P [ E1 | E2 ] = P E1.
Proof.
move=> PE2ne0 iE12.
have /= mE1 := (iE12.1 0%N).
have /= mE2 := (iE12.1 1%N).
rewrite/conditional_probability.
have [_ _ ->] := (pairwise_independentM _ _ _).1 iE12.
rewrite fineM ?probability_fin_num//; [|apply: mE1; left=>//|apply: mE2; right=>//].
rewrite -mulrA mulfV ?mulr1 ?fineK// ?probability_fin_num//; first by apply: mE1; left.
by rewrite fine_eq0// probability_fin_num//; apply: mE2; right.
Qed.

(* TODO (klenke thm 8.4): if P B > 0 then 'P[.|B] is a probability measure *)

Lemma conditional_independent_is_pairwise_independent (P : probability T R) E1 E2 :
  d.-measurable E1 -> d.-measurable E2 ->
  P E2 != 0 ->
    'P[E1 | E2] = P E1 -> pairwise_independent P E1 E2.
Proof.
rewrite /conditional_probability/pairwise_independent=> mE1 mE2 pE20 pE1E2.
split.
- by case=> [|[|]]//=.
- move=> B B01 B2; have [B_set0|B_set0|B_set1|B_set01] := subset_set2 B01.
  + rewrite B_set0.
    move: B_set0 => /eqP; rewrite set_fset_eq0 => /eqP ->.
    by rewrite big_nil bigcap_set0 probability_setT.
  + rewrite B_set0 bigcap_set1 /=.
    by rewrite fsbig_seq//= B_set0 fsbig_set1/=.
  + rewrite B_set1 bigcap_set1 /=.
    by rewrite fsbig_seq//= B_set1 fsbig_set1/=.
  + rewrite B_set01 bigcap_setU1 bigcap_set1/=.
    rewrite fsbig_seq//= B_set01.
    rewrite fsbigU//=; last first.
    by move=> n [/= ->].
    rewrite !fsbig_set1//= -pE1E2 -{2}(@fineK _ (P E2)).
    rewrite -EFinM -mulrA mulVf ?mulr1 ?fine_eq0// ?fineK//.
    all: by apply: probability_fin_num => //; apply: measurableI.
Qed.

Lemma conditional_independentC (P : probability T R) E1 E2 :
  d.-measurable E1 -> d.-measurable E2 ->
  P E1 != 0 -> P E2 != 0 ->
    reflect ('P[E1 | E2] == P E1) ('P[E2 | E1] == P E2).
Proof.
move=> mE1 mE2 pE10 pE20.
apply/(iffP idP)=>/eqP.
+ move/(@conditional_independent_is_pairwise_independent _ _ _ mE2 mE1 pE10).
  move/pairwise_independentC.
  by move/(conditional_independence pE20)/eqP.
+ move/(@conditional_independent_is_pairwise_independent _ _ _ mE1 mE2 pE20).
  move/pairwise_independentC.
  by move/(conditional_independence pE10)/eqP.
Qed.

(* Lemma summation (I : choiceType) (A : {fset I}) E F (P : probability T R) : *)
(*   (* the sets are disjoint *) *)
(*   P (\bigcap_(i in [set` A]) F i) = 1 -> P E = \prod_(i <- A) ('P [E | F i] * P (F i)). *)
(* Proof. *)
(* move=> pF1. *)

Lemma bayes (P : probability T R) E F :
  d.-measurable E -> d.-measurable F ->
  'P[ E | F ] = ((fine ('P[F | E] * P E)) / (fine (P F)))%:E.
Proof.
rewrite /conditional_probability => mE mF.
have [PE0|PE0] := eqVneq (P E) 0.
  have -> : P (E `&` F) = 0.
    by apply/eqP; rewrite eq_le -{1}PE0 (@measureIl _ _ _ P E F mE mF)/= measure_ge0.
  by rewrite PE0 fine0 invr0 mulr0 mule0 mul0r.
by rewrite -{2}(@fineK _ (P E)) -?EFinM -?(mulrA (fine _)) ?mulVf ?fine_eq0 ?probability_fin_num// mul1r setIC//.
Qed.

End conditional_probability.
Notation "' P [ E1 | E2 ]" := (conditional_probability P E1 E2).

From mathcomp Require Import real_interval.

Section independent_RVs.
Context d (T : measurableType d) (R : realType) (P : probability T R).
Local Open Scope ereal_scope.

Definition pairwise_independent_RV (X Y : {RV P >-> R}) :=
  forall s t, pairwise_independent P (X @^-1` s) (Y @^-1` t).

Lemma conditional_independent_RV (X Y : {RV P >-> R}) :
  pairwise_independent_RV X Y ->
  forall s t, P (Y @^-1` t) != 0 -> 'P [X @^-1` s | Y @^-1` t] = P (X @^-1` s).
Proof.
move=> iRVXY s t PYtne0.
exact: conditional_independence.
Qed.

Definition mutually_independent_RV (I : choiceType) (A : set I) (X : I -> {RV P >-> R}) :=
  forall x_ : I -> R, mutually_independent P A (fun i => X i @^-1` `[(x_ i), +oo[%classic).

Definition kwise_independent_RV (I : choiceType) (A : set I) (X : I -> {RV P >-> R}) k :=
  forall x_ : I -> R, kwise_independent P A (fun i => X i @^-1` `[(x_ i), +oo[%classic) k.

Lemma nwise_indep_is_mutual_indep_RV (I : choiceType) (A : {fset I}) (X : I -> {RV P >-> R}) n :
  #|` A | = n -> kwise_independent_RV [set` A] X n -> mutually_independent_RV [set` A] X.
Proof.
rewrite/mutually_independent_RV/kwise_independent_RV=> nA kwX s.
by apply: nwise_indep_is_mutual_indep; rewrite ?nA.
Qed.

(* alternative formalization
Definition inde_RV (I : choiceType) (A : set I) (X : I -> {RV P >-> R}) :=
  forall (s : I -> set R), mutually_independent P A (fun i => X i @^-1` s i).

Definition kwise_independent_RV (I : choiceType) (A : set I) (X : I -> {RV P >-> R}) k :=
  forall (s : I -> set R), kwise_independent P A (fun i => X i @^-1` s i) k.

this should be equivalent according to wikipedia https://en.wikipedia.org/wiki/Independence_(probability_theory)#For_real_valued_random_variables
*)

(* Remark 2.15 (i) *)
Lemma prob_inde_RV (I : choiceType) (A : set I) (X : I -> {RV P >-> R}) :
  mutually_independent_RV A X ->
    forall J : {fset I}, [set` J] `<=` A ->
      forall x_ : I -> R,
        P (\bigcap_(i in [set` J]) X i @^-1` `[(x_ i), +oo[%classic) =
          \prod_(i <- J) P (X i @^-1` `[(x_ i), +oo[%classic).
Proof.
move=> iRVX J JleA x_.
apply: (iRVX _).2 => //.
Qed.

Lemma inde_expectation (I : choiceType) (A : set I) (X : I -> {RV P >-> R}) :
  mutually_independent_RV A X ->
    forall B : {fset I}, [set` B] `<=` A ->
    'E_P[\prod_(i <- B) X i] = \prod_(i <- B) 'E_P[X i].
Proof.
move=> AX B BA.
rewrite [in LHS]unlock.
rewrite /mutually_independent_RV in AX.
rewrite /mutually_independent in AX.
Admitted.

End independent_RVs.

HB.lock Definition covariance {d} {T : measurableType d} {R : realType}
    (P : probability T R) (X Y : T -> R) :=
  'E_P[(X \- cst (fine 'E_P[X])) * (Y \- cst (fine 'E_P[Y]))]%E.
Canonical covariance_unlockable := Unlockable covariance.unlock.
Arguments covariance {d T R} P _%_R _%_R.

Section covariance_lemmas.
Local Open Scope ereal_scope.
Context d (T : measurableType d) (R : realType) (P : probability T R).

Lemma covarianceE (X Y : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) ->
    P.-integrable setT (EFin \o Y) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
  covariance P X Y = 'E_P[X * Y] - 'E_P[X] * 'E_P[Y].
Proof.
move=> X1 Y1 XY1.
have ? : 'E_P[X] \is a fin_num by rewrite fin_num_abs// integrable_expectation.
have ? : 'E_P[Y] \is a fin_num by rewrite fin_num_abs// integrable_expectation.
rewrite unlock [X in 'E_P[X]](_ : _ = (X \* Y \- fine 'E_P[X] \o* Y
    \- fine 'E_P[Y] \o* X \+ fine ('E_P[X] * 'E_P[Y]) \o* cst 1)%R); last first.
  apply/funeqP => x /=; rewrite mulrDr !mulrDl/= mul1r fineM// mulrNN addrA.
  by rewrite mulrN mulNr [Z in (X x * Y x - Z)%R]mulrC.
have ? : P.-integrable [set: T] (EFin \o (X \* Y \- fine 'E_P[X] \o* Y)%R).
  by rewrite compreBr ?integrableB// compre_scale ?integrableZl.
rewrite expectationD/=; last 2 first.
  - by rewrite compreBr// integrableB// compre_scale ?integrableZl.
  - by rewrite compre_scale// integrableZl// finite_measure_integrable_cst.
rewrite 2?expectationB//= ?compre_scale// ?integrableZl//.
rewrite 3?expectationM//= ?finite_measure_integrable_cst//.
by rewrite expectation_cst mule1 fineM// EFinM !fineK// muleC subeK ?fin_numM.
Qed.

Lemma covarianceC (X Y : T -> R) : covariance P X Y = covariance P Y X.
Proof.
by rewrite unlock; congr expectation; apply/funeqP => x /=; rewrite mulrC.
Qed.

Lemma covariance_fin_num (X Y : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) ->
    P.-integrable setT (EFin \o Y) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
  covariance P X Y \is a fin_num.
Proof.
by move=> X1 Y1 XY1; rewrite covarianceE// fin_numB fin_numM expectation_fin_num.
Qed.

Lemma covariance_cst_l c (X : {RV P >-> R}) : covariance P (cst c) X = 0.
Proof.
rewrite unlock expectation_cst/=.
rewrite [X in 'E_P[X]](_ : _ = cst 0%R) ?expectation_cst//.
by apply/funeqP => x; rewrite /GRing.mul/= subrr mul0r.
Qed.

Lemma covariance_cst_r (X : {RV P >-> R}) c : covariance P X (cst c) = 0.
Proof. by rewrite covarianceC covariance_cst_l. Qed.

Lemma covarianceZl a (X Y : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) ->
    P.-integrable setT (EFin \o Y) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
  covariance P (a \o* X)%R Y = a%:E * covariance P X Y.
Proof.
move=> X1 Y1 XY1.
have aXY : (a \o* X * Y = a \o* (X * Y))%R.
  by apply/funeqP => x; rewrite mulrAC.
rewrite [LHS]covarianceE => [||//|] /=; last 2 first.
- by rewrite compre_scale ?integrableZl.
- by rewrite aXY compre_scale ?integrableZl.
rewrite covarianceE// aXY !expectationM//.
by rewrite -muleA -muleBr// fin_num_adde_defr// expectation_fin_num.
Qed.

Lemma covarianceZr a (X Y : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) ->
    P.-integrable setT (EFin \o Y) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
  covariance P X (a \o* Y)%R = a%:E * covariance P X Y.
Proof.
move=> X1 Y1 XY1.
by rewrite [in RHS]covarianceC covarianceC covarianceZl; last rewrite mulrC.
Qed.

Lemma covarianceNl (X Y : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) ->
    P.-integrable setT (EFin \o Y) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
  covariance P (\- X)%R Y = - covariance P X Y.
Proof.
move=> X1 Y1 XY1.
have -> : (\- X = -1 \o* X)%R by apply/funeqP => x /=; rewrite mulrN mulr1.
by rewrite covarianceZl// EFinN mulNe mul1e.
Qed.

Lemma covarianceNr (X Y : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) ->
    P.-integrable setT (EFin \o Y) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
  covariance P X (\- Y)%R = - covariance P X Y.
Proof. by move=> X1 Y1 XY1; rewrite !(covarianceC X) covarianceNl 1?mulrC. Qed.

Lemma covarianceNN (X Y : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) ->
    P.-integrable setT (EFin \o Y) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
  covariance P (\- X)%R (\- Y)%R = covariance P X Y.
Proof.
move=> X1 Y1 XY1.
have NY : P.-integrable setT (EFin \o (\- Y)%R) by rewrite compreN ?integrableN.
by rewrite covarianceNl ?covarianceNr ?oppeK//= mulrN compreN ?integrableN.
Qed.

Lemma covarianceDl (X Y Z : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
    P.-integrable setT (EFin \o Y) -> P.-integrable setT (EFin \o (Y ^+ 2)%R) ->
    P.-integrable setT (EFin \o Z) -> P.-integrable setT (EFin \o (Z ^+ 2)%R) ->
    P.-integrable setT (EFin \o (X * Z)%R) ->
    P.-integrable setT (EFin \o (Y * Z)%R) ->
  covariance P (X \+ Y)%R Z = covariance P X Z + covariance P Y Z.
Proof.
move=> X1 X2 Y1 Y2 Z1 Z2 XZ1 YZ1.
rewrite [LHS]covarianceE//= ?mulrDl ?compreDr// ?integrableD//.
rewrite 2?expectationD//=.
rewrite muleDl ?fin_num_adde_defr ?expectation_fin_num//.
rewrite oppeD ?fin_num_adde_defr ?fin_numM ?expectation_fin_num//.
by rewrite addeACA 2?covarianceE.
Qed.

Lemma covarianceDr (X Y Z : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
    P.-integrable setT (EFin \o Y) -> P.-integrable setT (EFin \o (Y ^+ 2)%R) ->
    P.-integrable setT (EFin \o Z) -> P.-integrable setT (EFin \o (Z ^+ 2)%R) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
    P.-integrable setT (EFin \o (X * Z)%R) ->
  covariance P X (Y \+ Z)%R = covariance P X Y + covariance P X Z.
Proof.
move=> X1 X2 Y1 Y2 Z1 Z2 XY1 XZ1.
by rewrite covarianceC covarianceDl ?(covarianceC X) 1?mulrC.
Qed.

Lemma covarianceBl (X Y Z : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
    P.-integrable setT (EFin \o Y) -> P.-integrable setT (EFin \o (Y ^+ 2)%R) ->
    P.-integrable setT (EFin \o Z) -> P.-integrable setT (EFin \o (Z ^+ 2)%R) ->
    P.-integrable setT (EFin \o (X * Z)%R) ->
    P.-integrable setT (EFin \o (Y * Z)%R) ->
  covariance P (X \- Y)%R Z = covariance P X Z - covariance P Y Z.
Proof.
move=> X1 X2 Y1 Y2 Z1 Z2 XZ1 YZ1.
rewrite -[(X \- Y)%R]/(X \+ (\- Y))%R covarianceDl ?covarianceNl//=.
- by rewrite compreN// integrableN.
- by rewrite mulrNN.
- by rewrite mulNr compreN// integrableN.
Qed.

Lemma covarianceBr (X Y Z : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
    P.-integrable setT (EFin \o Y) -> P.-integrable setT (EFin \o (Y ^+ 2)%R) ->
    P.-integrable setT (EFin \o Z) -> P.-integrable setT (EFin \o (Z ^+ 2)%R) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
    P.-integrable setT (EFin \o (X * Z)%R) ->
  covariance P X (Y \- Z)%R = covariance P X Y - covariance P X Z.
Proof.
move=> X1 X2 Y1 Y2 Z1 Z2 XY1 XZ1.
by rewrite !(covarianceC X) covarianceBl 1?(mulrC _ X).
Qed.

End covariance_lemmas.

Section variance.
Local Open Scope ereal_scope.
Context d (T : measurableType d) (R : realType) (P : probability T R).

Definition variance (X : T -> R) := covariance P X X.
Local Notation "''V_' P [ X ]" := (variance X).

Lemma varianceE (X : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
  'V_P[X] = 'E_P[X ^+ 2] - ('E_P[X]) ^+ 2.
Proof. by move=> X1 X2; rewrite /variance covarianceE. Qed.

Lemma variance_fin_num (X : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o X ^+ 2)%R ->
  'V_P[X] \is a fin_num.
Proof. by move=> /[dup]; apply: covariance_fin_num. Qed.

Lemma variance_ge0 (X : {RV P >-> R}) : (0 <= 'V_P[X])%E.
Proof.
by rewrite /variance unlock; apply: expectation_ge0 => x; apply: sqr_ge0.
Qed.

Lemma variance_cst r : 'V_P[cst r] = 0%E.
Proof.
rewrite /variance unlock expectation_cst/=.
rewrite [X in 'E_P[X]](_ : _ = cst 0%R) ?expectation_cst//.
by apply/funext => x; rewrite /GRing.exp/GRing.mul/= subrr mulr0.
Qed.

Lemma varianceZ a (X : {RV P >-> R}) :
  P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
  'V_P[(a \o* X)%R] = (a ^+ 2)%:E * 'V_P[X].
Proof.
move=> X1 X2; rewrite /variance covarianceZl//=.
- by rewrite covarianceZr// muleA.
- by rewrite compre_scale// integrableZl.
- rewrite [X in EFin \o X](_ : _ = (a \o* X ^+ 2)%R); last first.
    by apply/funeqP => x; rewrite mulrA.
  by rewrite compre_scale// integrableZl.
Qed.

Lemma varianceN (X : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
  'V_P[(\- X)%R] = 'V_P[X].
Proof. by move=> X1 X2; rewrite /variance covarianceNN. Qed.

Lemma varianceD (X Y : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
    P.-integrable setT (EFin \o Y) -> P.-integrable setT (EFin \o (Y ^+ 2)%R) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
  'V_P[X \+ Y]%R = 'V_P[X] + 'V_P[Y] + 2%:E * covariance P X Y.
Proof.
move=> X1 X2 Y1 Y2 XY1.
rewrite -['V_P[_]]/(covariance P (X \+ Y)%R (X \+ Y)%R).
have XY : P.-integrable [set: T] (EFin \o (X \+ Y)%R).
  by rewrite compreDr// integrableD.
rewrite covarianceDl//=; last 3 first.
- rewrite -expr2 sqrrD compreDr ?integrableD// compreDr// integrableD//.
  rewrite -mulr_natr -[(_ * 2)%R]/(2 \o* (X * Y))%R compre_scale//.
  exact: integrableZl.
- by rewrite mulrDr compreDr ?integrableD.
- by rewrite mulrDr mulrC compreDr ?integrableD.
rewrite covarianceDr// covarianceDr; [|by []..|by rewrite mulrC |exact: Y2].
rewrite (covarianceC P Y X) [LHS]addeA [LHS](ACl (1*4*(2*3)))/=.
by rewrite -[2%R]/(1 + 1)%R EFinD muleDl ?mul1e// covariance_fin_num.
Qed.

Lemma varianceB (X Y : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
    P.-integrable setT (EFin \o Y) -> P.-integrable setT (EFin \o (Y ^+ 2)%R) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
  'V_P[(X \- Y)%R] = 'V_P[X] + 'V_P[Y] - 2%:E * covariance P X Y.
Proof.
move=> X1 X2 Y1 Y2 XY1.
rewrite -[(X \- Y)%R]/(X \+ (\- Y))%R.
rewrite varianceD/= ?varianceN ?covarianceNr ?muleN//.
- by rewrite compreN ?integrableN.
- by rewrite mulrNN.
- by rewrite mulrN compreN ?integrableN.
Qed.

Lemma varianceD_cst_l c (X : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
  'V_P[(cst c \+ X)%R] = 'V_P[X].
Proof.
move=> X1 X2.
rewrite varianceD//=; last 3 first.
- exact: finite_measure_integrable_cst.
- by rewrite compre_scale// integrableZl// finite_measure_integrable_cst.
- by rewrite mulrC compre_scale ?integrableZl.
by rewrite variance_cst add0e covariance_cst_l mule0 adde0.
Qed.

Lemma varianceD_cst_r (X : {RV P >-> R}) c :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
  'V_P[(X \+ cst c)%R] = 'V_P[X].
Proof.
move=> X1 X2.
have -> : (X \+ cst c = cst c \+ X)%R by apply/funeqP => x /=; rewrite addrC.
exact: varianceD_cst_l.
Qed.

Lemma varianceB_cst_l c (X : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
  'V_P[(cst c \- X)%R] = 'V_P[X].
Proof.
move=> X1 X2.
rewrite -[(cst c \- X)%R]/(cst c \+ (\- X))%R varianceD_cst_l/=; last 2 first.
- by rewrite compreN ?integrableN.
- by rewrite mulrNN; apply: X2.
by rewrite varianceN.
Qed.

Lemma varianceB_cst_r (X : {RV P >-> R}) c :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
  'V_P[(X \- cst c)%R] = 'V_P[X].
Proof.
by move=> X1 X2; rewrite -[(X \- cst c)%R]/(X \+ (cst (- c)))%R varianceD_cst_r.
Qed.

Lemma covariance_le (X Y : {RV P >-> R}) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
    P.-integrable setT (EFin \o Y) -> P.-integrable setT (EFin \o (Y ^+ 2)%R) ->
    P.-integrable setT (EFin \o (X * Y)%R) ->
  covariance P X Y <= sqrte 'V_P[X] * sqrte 'V_P[Y].
Proof.
move=> X1 X2 Y1 Y2 XY1.
rewrite -sqrteM ?variance_ge0//.
rewrite lee_sqrE ?sqrte_ge0// sqr_sqrte ?mule_ge0 ?variance_ge0//.
rewrite -(fineK (variance_fin_num X1 X2)) -(fineK (variance_fin_num Y1 Y2)).
rewrite -(fineK (covariance_fin_num X1 Y1 XY1)).
rewrite -EFin_expe -EFinM lee_fin -(@ler_pM2l _ 4) ?ltr0n// [leRHS]mulrA.
rewrite [in leLHS](_ : 4 = 2 * 2)%R -natrM// [in leLHS]natrM mulrACA -expr2.
rewrite -subr_le0; apply: deg_le2_ge0 => r; rewrite -lee_fin !EFinD.
rewrite EFinM fineK ?variance_fin_num// muleC -varianceZ//.
rewrite 2!EFinM ?fineK ?variance_fin_num// ?covariance_fin_num//.
rewrite -muleA [_ * r%:E]muleC -covarianceZl//.
rewrite addeAC -varianceD ?variance_ge0//=.
- by rewrite compre_scale ?integrableZl.
- rewrite [X in EFin \o X](_ : _ = r ^+2 \o* X ^+ 2)%R 1?mulrACA//.
  by rewrite compre_scale ?integrableZl.
- by rewrite -mulrAC compre_scale// integrableZl.
Qed.

End variance.
Notation "'V_ P [ X ]" := (variance P X).

Section markov_chebyshev_cantelli.
Local Open Scope ereal_scope.
Context d (T : measurableType d) (R : realType) (P : probability T R).

Lemma markov (X : {RV P >-> R}) (f : R -> R) (eps : R) :
    (0 < eps)%R ->
    measurable_fun [set: R] f -> (forall r, 0 <= r -> 0 <= f r)%R ->
    {in Num.nneg &, {homo f : x y / x <= y}}%R ->
  (f eps)%:E * P [set x | eps%:E <= `| (X x)%:E | ] <=
    'E_P[f \o (fun x => `| x |%R) \o X].
Proof.
move=> e0 mf f0 f_nd; rewrite -(setTI [set _ | _]).
apply: (le_trans (@le_integral_comp_abse _ _ _ P _ measurableT (EFin \o X)
  eps (er_map f) _ _ _ _ e0)) => //=.
- exact: measurable_er_map.
- by case => //= r _; exact: f0.
- move=> [x| |] [y| |]; rewrite !inE/= !in_itv/= ?andbT ?lee_fin ?leey//.
  by move=> ? ? ?; rewrite f_nd.
- exact/measurable_EFinP.
- by rewrite unlock.
Qed.

Definition mmt_gen_fun (X : {RV P >-> R}) (t : R) := 'E_P[expR \o t \o* X].
Definition nth_mmt (X : {RV P >-> R}) (n : nat) := 'E_P[X^+n].

Lemma chernoff (X : {RV P >-> R}) (r a : R) : (0 < r)%R ->
  P [set x | X x >= a]%R <= mmt_gen_fun X r * (expR (- (r * a)))%:E.
Proof.
move=> t0.
rewrite /mmt_gen_fun; have -> : expR \o r \o* X =
    (normr \o normr) \o [the {mfun T >-> R} of expR \o r \o* X].
  by apply: funext => t /=; rewrite normr_id ger0_norm ?expR_ge0.
rewrite expRN lee_pdivlMr ?expR_gt0//.
rewrite (le_trans _ (markov _ (expR_gt0 (r * a)) _ _ _))//; last first.
  exact: (monoW_in (@ger0_le_norm _)).
rewrite ger0_norm ?expR_ge0// muleC lee_pmul2l// ?lte_fin ?expR_gt0//.
rewrite [X in _ <= P X](_ : _ = [set x | a <= X x]%R)//; apply: eq_set => t/=.
by rewrite ger0_norm ?expR_ge0// lee_fin ler_expR  mulrC ler_pM2r.
Qed.

Lemma chebyshev (X : {RV P >-> R}) (eps : R) : (0 < eps)%R ->
  P [set x | (eps <= `| X x - fine ('E_P[X])|)%R ] <= (eps ^- 2)%:E * 'V_P[X].
Proof.
move => heps; have [->|hv] := eqVneq 'V_P[X] +oo.
  by rewrite mulr_infty gtr0_sg ?mul1e// ?leey// invr_gt0// exprn_gt0.
have h (Y : {RV P >-> R}) :
    P [set x | (eps <= `|Y x|)%R] <= (eps ^- 2)%:E * 'E_P[Y ^+ 2].
  rewrite -lee_pdivrMl; last by rewrite invr_gt0// exprn_gt0.
  rewrite exprnN expfV exprz_inv opprK -exprnP.
  apply: (@le_trans _ _ ('E_P[(@GRing.exp R ^~ 2%N \o normr) \o Y])).
    apply: (@markov Y (@GRing.exp R ^~ 2%N)) => //.
    - by move=> r _; exact: sqr_ge0.
    - move=> x y; rewrite !nnegrE => x0 y0.
      by rewrite ler_sqr.
  apply: expectation_le => //.
    - by apply: measurableT_comp => //; exact: measurableT_comp.
  - by move=> x /=; exact: sqr_ge0.
  - by move=> x /=; exact: sqr_ge0.
  - by apply/aeW => t /=; rewrite real_normK// num_real.
have := h [the {mfun T >-> R} of (X \- cst (fine ('E_P[X])))%R].
by move=> /le_trans; apply; rewrite /variance [in leRHS]unlock.
Qed.

Lemma cantelli (X : {RV P >-> R}) (lambda : R) :
    P.-integrable setT (EFin \o X) -> P.-integrable setT (EFin \o (X ^+ 2)%R) ->
    (0 < lambda)%R ->
  P [set x | lambda%:E <= (X x)%:E - 'E_P[X]]
  <= (fine 'V_P[X] / (fine 'V_P[X] + lambda^2))%:E.
Proof.
move=> X1 X2 lambda_gt0.
have finEK : (fine 'E_P[X])%:E = 'E_P[X].
  by rewrite fineK ?unlock ?integral_fune_fin_num.
have finVK : (fine 'V_P[X])%:E = 'V_P[X] by rewrite fineK ?variance_fin_num.
pose Y := (X \- cst (fine 'E_P[X]))%R.
have Y1 : P.-integrable [set: T] (EFin \o Y).
  rewrite compreBr => [|//]; apply: integrableB X1 _ => [//|].
  exact: finite_measure_integrable_cst.
have Y2 : P.-integrable [set: T] (EFin \o (Y ^+ 2)%R).
  rewrite sqrrD/= compreDr => [|//].
  apply: integrableD => [//||]; last first.
    rewrite -[(_ ^+ 2)%R]/(cst ((- fine 'E_P[X]) ^+ 2)%R).
    exact: finite_measure_integrable_cst.
  rewrite compreDr => [|//]; apply: integrableD X2 _ => [//|].
  rewrite [X in EFin \o X](_ : _ = (- fine 'E_P[X] * 2) \o* X)%R; last first.
    by apply/funeqP => x /=; rewrite -mulr_natl mulrC mulrA.
  by rewrite compre_scale => [|//]; apply: integrableZl X1.
have EY : 'E_P[Y] = 0.
  rewrite expectationB/= ?finite_measure_integrable_cst//.
  rewrite expectation_cst finEK subee//.
  by rewrite unlock; apply: integral_fune_fin_num X1.
have VY : 'V_P[Y] = 'V_P[X] by rewrite varianceB_cst_r.
have le (u : R) : (0 <= u)%R ->
    P [set x | lambda%:E <= (X x)%:E - 'E_P[X]]
    <= ((fine 'V_P[X] + u^2) / (lambda + u)^2)%:E.
  move=> uge0; rewrite EFinM.
  have YU1 : P.-integrable [set: T] (EFin \o (Y \+ cst u)%R).
    rewrite compreDr => [|//]; apply: integrableD Y1 _ => [//|].
    exact: finite_measure_integrable_cst.
  have YU2 : P.-integrable [set: T] (EFin \o ((Y \+ cst u) ^+ 2)%R).
    rewrite sqrrD/= compreDr => [|//].
    apply: integrableD => [//||]; last first.
      rewrite -[(_ ^+ 2)%R]/(cst (u ^+ 2))%R.
      exact: finite_measure_integrable_cst.
    rewrite compreDr => [|//]; apply: integrableD Y2 _ => [//|].
    rewrite [X in EFin \o X](_ : _ = (2 * u) \o* Y)%R; last first.
      by apply/funeqP => x /=; rewrite -mulr_natl mulrCA.
    by rewrite compre_scale => [|//]; apply: integrableZl Y1.
  have -> : (fine 'V_P[X] + u^2)%:E = 'E_P[(Y \+ cst u)^+2]%R.
    rewrite -VY -[RHS](@subeK _ _ (('E_P[(Y \+ cst u)%R])^+2)); last first.
      by rewrite fin_numX ?unlock ?integral_fune_fin_num.
    rewrite -varianceE/= -/Y -?expe2//.
    rewrite expectationD/= ?EY ?add0e ?expectation_cst -?EFinM; last 2 first.
    - rewrite compreBr => [|//]; apply: integrableB X1 _ => [//|].
      exact: finite_measure_integrable_cst.
    - exact: finite_measure_integrable_cst.
    by rewrite (varianceD_cst_r _ Y1 Y2) EFinD fineK ?(variance_fin_num Y1 Y2).
  have le : [set x | lambda%:E <= (X x)%:E - 'E_P[X]]
      `<=` [set x | ((lambda + u)^2)%:E <= ((Y x + u)^+2)%:E].
    move=> x /= le; rewrite lee_fin; apply: lerXn2r.
    - exact: addr_ge0 (ltW lambda_gt0) _.
    - apply/(addr_ge0 _ uge0)/(le_trans (ltW lambda_gt0) _).
      by rewrite -lee_fin EFinB finEK.
    - by rewrite lerD2r -lee_fin EFinB finEK.
  apply: (le_trans (le_measure _ _ _ le)).
  - rewrite -[[set _ | _]]setTI inE; apply: emeasurable_fun_c_infty => [//|].
    by apply: emeasurable_funB => //; exact: measurable_int X1.
  - rewrite -[[set _ | _]]setTI inE; apply: emeasurable_fun_c_infty => [//|].
    rewrite measurable_EFinP [X in measurable_fun _ X](_ : _ =
      (fun x => x ^+ 2) \o (fun x => Y x + u))%R//.
    by apply/measurableT_comp => //; apply/measurable_funD.
  set eps := ((lambda + u) ^ 2)%R.
  have peps : (0 < eps)%R by rewrite exprz_gt0 ?ltr_wpDr.
  rewrite (lee_pdivlMr _ _ peps) muleC.
  under eq_set => x.
    rewrite -[leRHS]gee0_abs ?lee_fin ?sqr_ge0 -?lee_fin => [|//].
    rewrite -[(_ ^+ 2)%R]/(((Y \+ cst u) ^+ 2) x)%R; over.
  rewrite -[X in X%:E * _]gtr0_norm => [|//].
  apply: (le_trans (markov _ peps _ _ _)) => //=.
    by move=> x y /[!nnegrE] /ger0_norm-> /ger0_norm->.
  rewrite -/Y le_eqVlt; apply/orP; left; apply/eqP; congr expectation.
  by apply/funeqP => x /=; rewrite -expr2 normr_id ger0_norm ?sqr_ge0.
pose u0 := (fine 'V_P[X] / lambda)%R.
have u0ge0 : (0 <= u0)%R.
  by apply: divr_ge0 (ltW lambda_gt0); rewrite -lee_fin finVK variance_ge0.
apply: le_trans (le _ u0ge0) _; rewrite lee_fin le_eqVlt; apply/orP; left.
rewrite eqr_div; [|apply: lt0r_neq0..]; last 2 first.
- by rewrite exprz_gt0 -1?[ltLHS]addr0 ?ltr_leD.
- by rewrite ltr_wpDl ?fine_ge0 ?variance_ge0 ?exprz_gt0.
apply/eqP; have -> : fine 'V_P[X] = (u0 * lambda)%R.
  by rewrite /u0 -mulrA mulVr ?mulr1 ?unitfE ?gt_eqF.
by rewrite -mulrDl -mulrDr (addrC u0) [in RHS](mulrAC u0) -exprnP expr2 !mulrA.
Qed.

End markov_chebyshev_cantelli.

HB.mixin Record MeasurableFun_isDiscrete d d' (T : measurableType d) (U : measurableType d')
    (X : T -> U) of @MeasurableFun d _ T U X := {
  countable_range : countable (range X)
}.

HB.structure Definition discreteMeasurableFun d d' (T : measurableType d)
    (U : measurableType d') := {
  X of isMeasurableFun d d' T U X & MeasurableFun_isDiscrete d d' T U X
}.

Notation "{ 'dmfun' aT >-> T }" :=
  (@discreteMeasurableFun.type _ _ aT T) : form_scope.

Definition discrete_random_variable (d d' : _) (T : measurableType d)
  (U : measurableType d') (R : realType) (P : probability T R) := {dmfun T >-> U}.

Notation "{ 'dRV' P >-> U }" :=
  (@discrete_random_variable _ _ _ U _ P) : form_scope.

Section dRV_definitions.
Context d d' (T : measurableType d) (U : measurableType d') (R : realType) (P : probability T R).

Definition dRV_dom_enum (X : {dRV P >-> U}) :
  { B : set nat & {splitbij B >-> range X}}.
Proof.
have /countable_bijP/cid[B] := @countable_range _ _ _ _ X.
move/card_esym/ppcard_eqP/unsquash => f.
exists B; exact: f.
Qed.

Definition dRV_dom (X : {dRV P >-> U}) : set nat := projT1 (dRV_dom_enum X).

Definition dRV_enum (X : {dRV P >-> U}) : {splitbij (dRV_dom X) >-> range X} :=
  projT2 (dRV_dom_enum X).

Definition enum_prob (X : {dRV P >-> U}) :=
  (fun k => P (X @^-1` [set dRV_enum X k])) \_ (dRV_dom X).

End dRV_definitions.

Section distribution_dRV.
Local Open Scope ereal_scope.
Context d d' (T : measurableType d) (U : measurableType d') (R : realType) (P : probability T R).
Variable X : {dRV P >-> U}.

Lemma distribution_dRV_enum (n : nat) : n \in dRV_dom X ->
  distribution P X [set dRV_enum X n] = enum_prob X n.
Proof.
by move=> nX; rewrite /distribution/= /enum_prob/= patchE nX.
Qed.

Lemma distribution_dRV A : measurable A ->
  distribution P X A = \sum_(k <oo) enum_prob X k * \d_ (dRV_enum X k) A.
Proof.
move=> mA; rewrite /distribution /pushforward.
have mAX i : dRV_dom X i -> measurable (X @^-1` (A `&` [set dRV_enum X i])).
  move=> _; rewrite preimage_setI; apply: measurableI => //.
  (* exact/measurable_sfunP. *)
  admit. admit.
have tAX : trivIset (dRV_dom X) (fun k => X @^-1` (A `&` [set dRV_enum X k])).
  under eq_fun do rewrite preimage_setI; rewrite -/(trivIset _ _).
  apply: trivIset_setIl; apply/trivIsetP => i j iX jX /eqP ij.
  rewrite -preimage_setI (_ : _ `&` _ = set0)//.
  by apply/seteqP; split => //= x [] -> {x} /inj; rewrite inE inE => /(_ iX jX).
have := measure_bigcup P _ (fun k => X @^-1` (A `&` [set dRV_enum X k])) mAX tAX.
rewrite -preimage_bigcup => {mAX tAX}PXU.
rewrite -{1}(setIT A) -(setUv (\bigcup_(i in dRV_dom X) [set dRV_enum X i])).
rewrite setIUr preimage_setU measureU; last 3 first.
  - rewrite preimage_setI; apply: measurableI => //.
      (* exact: measurable_sfunP. *)
      admit.
    (* by apply: measurable_sfunP; exact: bigcup_measurable. *)
    admit.
  - (* apply: measurable_sfunP; apply: measurableI => //. *)
    (* by apply: measurableC; exact: bigcup_measurable. *)
    admit.
  - rewrite 2!preimage_setI setIACA -!setIA -preimage_setI.
    by rewrite setICr preimage_set0 2!setI0.
rewrite [X in _ + X = _](_ : _ = 0) ?adde0; last first.
  rewrite (_ : _ @^-1` _ = set0) ?measure0//; apply/disjoints_subset => x AXx.
  rewrite setCK /bigcup /=; exists ((dRV_enum X)^-1 (X x))%function.
    exact: funS.
  by rewrite invK// inE.
rewrite setI_bigcupr; etransitivity; first exact: PXU.
rewrite eseries_mkcond; apply: eq_eseriesr => k _.
rewrite /enum_prob patchE; case: ifPn => nX; rewrite ?mul0e//.
rewrite diracE; have [kA|] := boolP (_ \in A).
  by rewrite mule1 setIidr// => _ /= ->; exact: set_mem.
rewrite notin_setE => kA.
rewrite mule0 (disjoints_subset _ _).2 ?preimage_set0 ?measure0//.
by apply: subsetCr; rewrite sub1set inE.
Admitted.

Lemma sum_enum_prob : \sum_(n <oo) (enum_prob X) n = 1.
Proof.
have := distribution_dRV measurableT.
rewrite probability_setT/= => /esym; apply: eq_trans.
by rewrite [RHS]eseries_mkcond; apply: eq_eseriesr => k _; rewrite diracT mule1.
Qed.

End distribution_dRV.

Section discrete_distribution.
Local Open Scope ereal_scope.
Context d (T : measurableType d) (R : realType) (P : probability T R).

Lemma dRV_expectation (X : {dRV P >-> R}) :
  P.-integrable [set: T] (EFin \o X) ->
  'E_P[X] = \sum_(n <oo) enum_prob X n * (dRV_enum X n)%:E.
Proof.
move=> ix; rewrite unlock.
rewrite -[in LHS](_ : \bigcup_k (if k \in dRV_dom X then
    X @^-1` [set dRV_enum X k] else set0) = setT); last first.
  apply/seteqP; split => // t _.
  exists ((dRV_enum X)^-1%function (X t)) => //.
  case: ifPn=> [_|].
    by rewrite invK// inE.
  by rewrite notin_setE/=; apply; apply: funS.
have tA : trivIset (dRV_dom X) (fun k => [set dRV_enum X k]).
  by move=> i j iX jX [r [/= ->{r}]] /inj; rewrite !inE; exact.
have {tA}/trivIset_mkcond tXA :
    trivIset (dRV_dom X) (fun k => X @^-1` [set dRV_enum X k]).
  apply/trivIsetP => /= i j iX jX ij.
  move/trivIsetP : tA => /(_ i j iX jX) Aij.
  by rewrite -preimage_setI Aij ?preimage_set0.
rewrite integral_bigcup //; last 2 first.
  - by move=> k; case: ifPn.
  - apply: (integrableS measurableT) => //.
    by rewrite -bigcup_mkcond; exact: bigcup_measurable.
transitivity (\sum_(i <oo)
  \int[P]_(x in (if i \in dRV_dom X then X @^-1` [set dRV_enum X i] else set0))
    (dRV_enum X i)%:E).
  apply: eq_eseriesr => i _; case: ifPn => iX.
    by apply: eq_integral => t; rewrite in_setE/= => ->.
  by rewrite !integral_set0.
transitivity (\sum_(i <oo) (dRV_enum X i)%:E *
  \int[P]_(x in (if i \in dRV_dom X then X @^-1` [set dRV_enum X i] else set0))
    1).
  apply: eq_eseriesr => i _; rewrite -integralZl//; last 2 first.
    - by case: ifPn.
    - apply/integrableP; split => //.
      rewrite (eq_integral (cst 1%E)); last by move=> x _; rewrite abse1.
      rewrite integral_cst//; last by case: ifPn.
      rewrite mul1e (@le_lt_trans _ _ 1%E) ?ltey//.
      by case: ifPn => // _; exact: probability_le1.
  by apply: eq_integral => y _; rewrite mule1.
apply: eq_eseriesr => k _; case: ifPn => kX.
  rewrite /= integral_cst//= mul1e probability_distribution muleC.
  by rewrite distribution_dRV_enum.
by rewrite integral_set0 mule0 /enum_prob patchE (negbTE kX) mul0e.
Qed.

Definition pmf (X : {RV P >-> R}) (r : R) : R := fine (P (X @^-1` [set r])).

Lemma expectation_pmf (X : {dRV P >-> R}) :
    P.-integrable [set: T] (EFin \o X) -> 'E_P[X] =
  \sum_(n <oo | n \in dRV_dom X) (pmf X (dRV_enum X n))%:E * (dRV_enum X n)%:E.
Proof.
move=> iX; rewrite dRV_expectation// [in RHS]eseries_mkcond.
apply: eq_eseriesr => k _.
rewrite /enum_prob patchE; case: ifPn => kX; last by rewrite mul0e.
by rewrite /pmf fineK// fin_num_measure.
Qed.

End discrete_distribution.

Section bernoulli_pmf.
Context {R : realType} (p : R).
Local Open Scope ring_scope.

Definition bernoulli_pmf b := if b then p else 1 - p.

Lemma bernoulli_pmf_ge0 (p01 : 0 <= p <= 1) b : 0 <= bernoulli_pmf b.
Proof.
rewrite /bernoulli_pmf.
by move: p01 => /andP[p0 p1]; case: ifPn => // _; rewrite subr_ge0.
Qed.

Lemma bernoulli_pmf1 (p01 : 0 <= p <= 1) :
  \sum_(i \in [set: bool]) (bernoulli_pmf i)%:E = 1%E.
Proof.
rewrite setT_bool fsbigU//=; last by move=> x [/= ->].
by rewrite !fsbig_set1/= -EFinD addrCA subrr addr0.
Qed.

End bernoulli_pmf.

Lemma measurable_bernoulli_pmf {R : realType} D n :
  measurable_fun D (@bernoulli_pmf R ^~ n).
Proof.
by apply/measurable_funTS/measurable_fun_if => //=; exact: measurable_funB.
Qed.

Definition bernoulli {R : realType} (p : R) : set bool -> \bar R := fun A =>
  if (0 <= p <= 1)%R then \sum_(b \in A) (bernoulli_pmf p b)%:E else \d_false A.

Section bernoulli.
Context {R : realType} (p : R).

Local Notation bernoulli := (bernoulli p).

Let bernoulli0 : bernoulli set0 = 0.
Proof.
by rewrite /bernoulli; case: ifPn => // p01; rewrite fsbig_set0.
Qed.

Let bernoulli_ge0 U : (0 <= bernoulli U)%E.
Proof.
rewrite /bernoulli; case: ifPn => // p01.
rewrite fsbig_finite//= sumEFin lee_fin.
by apply: sumr_ge0 => /= b _; exact: bernoulli_pmf_ge0.
Qed.

Let bernoulli_sigma_additive : semi_sigma_additive bernoulli.
Proof.
move=> F mF tF mUF; rewrite /bernoulli; case: ifPn => p01; last first.
  exact: measure_semi_sigma_additive.
apply: cvg_toP.
  apply: ereal_nondecreasing_is_cvgn => m n mn.
  apply: lee_sum_nneg_natr => // k _ _.
  rewrite fsbig_finite//= sumEFin lee_fin.
  by apply: sumr_ge0 => /= b _; exact: bernoulli_pmf_ge0.
transitivity (\sum_(0 <= i <oo) (\esum_(j in F i) (bernoulli_pmf p j)%:E)%R)%E.
apply: eq_eseriesr => k _; rewrite esum_fset//= => b _.
  by rewrite lee_fin bernoulli_pmf_ge0.
rewrite -nneseries_sum_bigcup//=; last first.
  by move=> b; rewrite lee_fin bernoulli_pmf_ge0.
by rewrite esum_fset//= => b _; rewrite lee_fin bernoulli_pmf_ge0.
Qed.

HB.instance Definition _ := isMeasure.Build _ _ _ bernoulli
  bernoulli0 bernoulli_ge0 bernoulli_sigma_additive.

Let bernoulli_setT : bernoulli [set: _] = 1%E.
Proof.
rewrite /bernoulli/=; case: ifPn => p01; last by rewrite probability_setT.
by rewrite bernoulli_pmf1.
Qed.

HB.instance Definition _ :=
  @Measure_isProbability.Build _ _ R bernoulli bernoulli_setT.

End bernoulli.

Section bernoulli_measure.
Context {R : realType}.
Variables (p : R) (p0 : (0 <= p)%R) (p1 : ((NngNum p0)%:num <= 1)%R).

Lemma bernoulli_dirac : bernoulli p = measure_add
  (mscale (NngNum p0) \d_true) (mscale (onem_nonneg p1) \d_false).
Proof.
apply/funext => U; rewrite /bernoulli; case: ifPn => [p01|]; last first.
  by rewrite p0/= p1.
rewrite measure_addE/= /mscale/=.
have := @subsetT _ U; rewrite setT_bool => UT.
have [->|->|->|->] /= := subset_set2 UT.
- rewrite -esum_fset//=; last by move=> b; rewrite lee_fin bernoulli_pmf_ge0.
  by rewrite esum_set0 2!measure0 2!mule0 adde0.
- rewrite -esum_fset//=; last by move=> b; rewrite lee_fin bernoulli_pmf_ge0.
  rewrite esum_set1/= ?lee_fin// 2!diracE mem_set//= memNset//= mule0 adde0.
  by rewrite mule1.
- rewrite -esum_fset//=; last by move=> b; rewrite lee_fin bernoulli_pmf_ge0.
  rewrite esum_set1/= ?lee_fin ?subr_ge0// 2!diracE memNset//= mem_set//=.
  by rewrite mule0 add0e mule1.
- rewrite fsbigU//=; last by move=> x [->].
  by rewrite 2!fsbig_set1/= -setT_bool 2!diracT !mule1.
Qed.

End bernoulli_measure.
Arguments bernoulli {R}.

Section integral_bernoulli.
Context {R : realType}.
Variables (p : R) (p01 : (0 <= p <= 1)%R).
Local Open Scope ereal_scope.

Lemma bernoulliE A : bernoulli p A = p%:E * \d_true A + (`1-p)%:E * \d_false A.
Proof. by case/andP : p01 => p0 p1; rewrite bernoulli_dirac// measure_addE. Qed.

Lemma integral_bernoulli (f : bool -> \bar R) : (forall x, 0 <= f x) ->
  \int[bernoulli p]_y (f y) = p%:E * f true + (`1-p)%:E * f false.
Proof.
move=> f0; case/andP : p01 => p0 p1; rewrite bernoulli_dirac/=.
rewrite ge0_integral_measure_sum// 2!big_ord_recl/= big_ord0 adde0/=.
by rewrite !ge0_integral_mscale//= !integral_dirac//= !diracT !mul1e.
Qed.

End integral_bernoulli.

Section measurable_bernoulli.
Local Open Scope ring_scope.
Variable R : realType.
Implicit Type p : R.

Lemma measurable_bernoulli :
  measurable_fun setT (bernoulli : R -> pprobability bool R).
Proof.
apply: (@measurability _ _ _ _ _ _
  (@pset _ _ _ : set (set (pprobability _ R)))) => //.
move=> _ -[_ [r r01] [Ys mYs <-]] <-; apply: emeasurable_fun_infty_o => //=.
apply: measurable_fun_if => //=.
  by apply: measurable_and => //; exact: measurable_fun_ler.
apply: (eq_measurable_fun (fun t =>
    \sum_(b <- fset_set Ys) (bernoulli_pmf t b)%:E)).
  move=> x /set_mem[_/= x01].
  by rewrite fsbig_finite//=.
apply: emeasurable_fun_sum => n.
move=> k Ysk; apply/measurableT_comp => //.
exact: measurable_bernoulli_pmf.
Qed.

Lemma measurable_bernoulli2 U : measurable U ->
  measurable_fun setT (bernoulli ^~ U : R -> \bar R).
Proof.
by move=> ?; exact: (measurable_kernel (kprobability measurable_bernoulli)).
Qed.

End measurable_bernoulli.
Arguments measurable_bernoulli {R}.

Section binomial_pmf.
Local Open Scope ring_scope.
Context {R : realType} (n : nat) (p : R).

Definition binomial_pmf k := p ^+ k * (`1-p) ^+ (n - k) *+ 'C(n, k).

Lemma binomial_pmf_ge0 k (p01 : (0 <= p <= 1)%R) : 0 <= binomial_pmf k.
Proof.
move: p01 => /andP[p0 p1]; rewrite mulrn_wge0// mulr_ge0// ?exprn_ge0//.
exact: onem_ge0.
Qed.

End binomial_pmf.

Lemma measurable_binomial_pmf {R : realType} D n k :
  measurable_fun D (@binomial_pmf R n ^~ k).
Proof.
apply: (@measurableT_comp _ _ _ _ _ _ (fun x : R => x *+ 'C(n, k))%R) => /=.
  exact: natmul_measurable.
by apply: measurable_funM => //; apply: measurable_funX; exact: measurable_funB.
Qed.

Definition binomial_prob {R : realType} (n : nat) (p : R) : set nat -> \bar R :=
  fun U => if (0 <= p <= 1)%R then
    \esum_(k in U) (binomial_pmf n p k)%:E else \d_0%N U.

Section binomial.
Context {R : realType} (n : nat) (p : R).
Local Open Scope ereal_scope.

Local Notation binomial := (binomial_prob n p).

Let binomial0 : binomial set0 = 0.
Proof. by rewrite /binomial measure0; case: ifPn => //; rewrite esum_set0. Qed.

Let binomial_ge0 U : 0 <= binomial U.
Proof.
rewrite /binomial; case: ifPn => // p01; apply: esum_ge0 => /= k Uk.
by rewrite lee_fin binomial_pmf_ge0.
Qed.

Let binomial_sigma_additive : semi_sigma_additive binomial.
Proof.
move=> F mF tF mUF; rewrite /binomial; case: ifPn => p01; last first.
  exact: measure_semi_sigma_additive.
apply: cvg_toP.
  apply: ereal_nondecreasing_is_cvgn => a b ab.
  apply: lee_sum_nneg_natr => // k _ _.
  by apply: esum_ge0 => /= ? _; exact: binomial_pmf_ge0.
by rewrite nneseries_sum_bigcup// => i; rewrite lee_fin binomial_pmf_ge0.
Qed.

HB.instance Definition _ := isMeasure.Build _ _ _ binomial
  binomial0 binomial_ge0 binomial_sigma_additive.

Let binomial_setT : binomial [set: _] = 1.
Proof.
rewrite /binomial; case: ifPn; last by move=> _; rewrite probability_setT.
move=> p01; rewrite /binomial_pmf.
have pkn k : 0%R <= (p ^+ k * `1-p ^+ (n - k) *+ 'C(n, k))%:E.
  case/andP : p01 => p0 p1.
  by rewrite lee_fin mulrn_wge0// mulr_ge0 ?exprn_ge0 ?subr_ge0.
rewrite (esumID `I_n.+1)// [X in _ + X]esum1 ?adde0; last first.
  by move=> /= k [_ /negP]; rewrite -leqNgt => nk; rewrite bin_small.
rewrite setTI esum_fset// -fsbig_ord//=.
under eq_bigr do rewrite mulrC.
rewrite sumEFin -exprDn_comm; last exact: mulrC.
by rewrite addrC add_onemK expr1n.
Qed.

HB.instance Definition _ :=
  @Measure_isProbability.Build _ _ R binomial binomial_setT.

End binomial.

Section binomial_probability.
Local Open Scope ring_scope.
Context {R : realType} (n : nat) (p : R)
        (p0 : (0 <= p)%R) (p1 : ((NngNum p0)%:num <= 1)%R).

Definition bin_prob (k : nat) : {nonneg R} :=
  ((NngNum p0)%:num ^+ k * (NngNum (onem_ge0 p1))%:num ^+ (n - k)%N *+ 'C(n, k))%:nng.

Lemma bin_prob0 : bin_prob 0 = ((NngNum (onem_ge0 p1))%:num^+n)%:nng.
Proof.
rewrite /bin_prob bin0 subn0/=; apply/val_inj => /=.
by rewrite expr0 mul1r mulr1n.
Qed.

Lemma bin_prob1 : bin_prob 1 =
  ((NngNum p0)%:num * (NngNum (onem_ge0 p1))%:num ^+ n.-1 *+ n)%:nng.
Proof.
by rewrite /bin_prob bin1/=; apply/val_inj => /=; rewrite expr1 subn1.
Qed.

Lemma binomial_msum :
  binomial_prob n p = msum (fun k => mscale (bin_prob k) \d_k) n.+1.
Proof.
apply/funext => U.
rewrite /binomial_prob; case: ifPn => [_|]; last by rewrite p1 p0.
rewrite /msum/= /mscale/= /binomial_pmf.
have pkn k : (0%R <= (p ^+ k * `1-p ^+ (n - k) *+ 'C(n, k))%:E)%E.
  by rewrite lee_fin mulrn_wge0// mulr_ge0 ?exprn_ge0 ?subr_ge0.
rewrite (esumID `I_n.+1)//= [X in _ + X]esum1 ?adde0; last first.
  by move=> /= k [_ /negP]; rewrite -leqNgt => nk; rewrite bin_small.
rewrite esum_mkcondl esum_fset//; last by move=> i /= _; case: ifPn.
rewrite -fsbig_ord//=; apply: eq_bigr => i _.
by rewrite diracE; case: ifPn => /= iU; [rewrite mule1|rewrite mule0].
Qed.

Lemma binomial_probE U : binomial_prob n p U =
  (\sum_(k < n.+1) (bin_prob k)%:num%:E * (\d_(nat_of_ord k) U))%E.
Proof. by rewrite binomial_msum. Qed.

Lemma integral_binomial (f : nat -> \bar R) : (forall x, 0 <= f x)%E ->
  (\int[binomial_prob n p]_y (f y) =
   \sum_(k < n.+1) (bin_prob k)%:num%:E * f k)%E.
Proof.
move=> f0; rewrite binomial_msum ge0_integral_measure_sum//=.
apply: eq_bigr => i _.
by rewrite ge0_integral_mscale//= integral_dirac//= diracT mul1e.
Qed.

End binomial_probability.

Lemma integral_binomial_prob (R : realType) n p U : (0 <= p <= 1)%R ->
  (\int[binomial_prob n p]_y \d_(0 < y)%N U =
  bernoulli (1 - `1-p ^+ n) U :> \bar R)%E.
Proof.
move=> /andP[p0 p1]; rewrite bernoulliE//=; last first.
  rewrite subr_ge0 exprn_ile1//=; [|exact/onem_ge0|exact/onem_le1].
  by rewrite lerBlDr addrC -lerBlDr subrr; exact/exprn_ge0/onem_ge0.
rewrite (@integral_binomial _ n p _ _ (fun y => \d_(1 <= y)%N U))//.
rewrite !big_ord_recl/=.
rewrite expr0 mul1r subn0 bin0 ltnn mulr1n addrC.
rewrite onemD opprK onem1 add0r; congr +%E.
rewrite /bump; under eq_bigr do rewrite leq0n add1n ltnS leq0n.
rewrite -ge0_sume_distrl; last first.
  move=> i _.
  by apply/mulrn_wge0/mulr_ge0; apply/exprn_ge0 => //; exact/onem_ge0.
congr *%E.
transitivity (\sum_(i < n.+1) (`1-p ^+ (n - i) * p ^+ i *+ 'C(n, i))%:E -
              (`1-p ^+ n)%:E)%E.
  rewrite big_ord_recl/=.
  rewrite expr0 mulr1 subn0 bin0 mulr1n addrAC -EFinD subrr add0e.
  by rewrite /bump; under [RHS]eq_bigr do rewrite leq0n add1n mulrC.
rewrite sumEFin -(@exprDn_comm _ `1-p p n)//.
  by rewrite subrK expr1n.
by rewrite /GRing.comm/onem mulrC.
Qed.

Lemma measurable_binomial_prob (R : realType) (n : nat) :
  measurable_fun setT (binomial_prob n : R -> pprobability _ _).
Proof.
apply: (@measurability _ _ _ _ _ _
  (@pset _ _ _ : set (set (pprobability _ R)))) => //.
move=> _ -[_ [r r01] [Ys mYs <-]] <-; apply: emeasurable_fun_infty_o => //=.
rewrite /binomial_prob/=.
set f := (X in measurable_fun _ X).
apply: measurable_fun_if => //=.
  by apply: measurable_and => //; exact: measurable_fun_ler.
apply: (eq_measurable_fun (fun t =>
    \sum_(k <oo | k \in Ys) (binomial_pmf n t k)%:E))%E.
  move=> x /set_mem[_/= x01].
  rewrite nneseries_esum// -1?[in RHS](set_mem_set Ys)// => k kYs.
  by rewrite lee_fin binomial_pmf_ge0.
apply: ge0_emeasurable_fun_sum.
  by move=> k x/= [_ x01] _; rewrite lee_fin binomial_pmf_ge0.
move=> k Ysk; apply/measurableT_comp => //.
exact: measurable_binomial_pmf.
Qed.

Section uniform_probability.
Local Open Scope ring_scope.
Context (R : realType) (a b : R).

Definition uniform_pdf x := if a <= x <= b then (b - a)^-1 else 0.

Lemma uniform_pdf_ge0 x : a < b -> 0 <= uniform_pdf x.
Proof.
move=> ab; rewrite /uniform_pdf; case: ifPn => // axb.
by rewrite invr_ge0// ltW// subr_gt0.
Qed.

Lemma measurable_uniform_pdf : measurable_fun setT uniform_pdf.
Proof.
rewrite /uniform_pdf /=; apply: measurable_fun_if => //=.
by apply: measurable_and => //; exact: measurable_fun_ler.
Qed.

Local Notation mu := lebesgue_measure.

Lemma integral_uniform_pdf U :
  (\int[mu]_(x in U) (uniform_pdf x)%:E =
   \int[mu]_(x in U `&` `[a, b]) (uniform_pdf x)%:E)%E.
Proof.
rewrite [RHS]integral_mkcondr/=; apply: eq_integral => x xU.
rewrite patchE; case: ifPn => //.
rewrite notin_setE/= in_itv/= => /negP/negbTE xab.
by rewrite /uniform_pdf xab.
Qed.

Lemma integral_uniform_pdf1 A (ab : a < b) : `[a, b] `<=` A ->
  (\int[mu]_(x in A) (uniform_pdf x)%:E = 1)%E.
Proof.
move=> abA; rewrite integral_uniform_pdf setIidr//.
rewrite (eq_integral (fun=> (b - a)^-1%:E)); last first.
  by move=> x; rewrite inE/= in_itv/= /uniform_pdf => ->.
rewrite integral_cst//= lebesgue_measure_itv/= lte_fin.
by rewrite ab -EFinD -EFinM mulVf// gt_eqF// subr_gt0.
Qed.

Definition uniform_prob (ab : a < b) : set _ -> \bar R :=
  fun U => (\int[mu]_(x in U) (uniform_pdf x)%:E)%E.

Hypothesis ab : (a < b)%R.

Let uniform0 : uniform_prob ab set0 = 0.
Proof. by rewrite /uniform_prob integral_set0. Qed.

Let uniform_ge0 U : (0 <= uniform_prob ab U)%E.
Proof.
by apply: integral_ge0 => /= x Ux; rewrite lee_fin uniform_pdf_ge0.
Qed.

Lemma integrable_uniform_pdf :
  mu.-integrable setT (fun x => (uniform_pdf x)%:E).
Proof.
apply/integrableP; split.
  by apply: measurableT_comp => //; exact: measurable_uniform_pdf.
under eq_integral.
  move=> x _; rewrite gee0_abs//; last by rewrite lee_fin uniform_pdf_ge0.
  over.
by rewrite /= integral_uniform_pdf1 ?ltry// -subr_gt0.
Qed.

Let uniform_sigma_additive : semi_sigma_additive (uniform_prob ab).
Proof.
move=> /= F mF tF mUF; rewrite /uniform_prob; apply: cvg_toP.
  apply: ereal_nondecreasing_is_cvgn => m n mn.
  apply: lee_sum_nneg_natr => // k _ _.
  by apply: integral_ge0 => /= x Fkx; rewrite lee_fin uniform_pdf_ge0.
rewrite ge0_integral_bigcup//=.
- apply: measurable_funTS; apply: measurableT_comp => //.
  exact: measurable_uniform_pdf.
- by move=> x _; rewrite lee_fin uniform_pdf_ge0.
Qed.

HB.instance Definition _ := isMeasure.Build _ _ _ (uniform_prob ab)
  uniform0 uniform_ge0 uniform_sigma_additive.

Let uniform_setT : uniform_prob ab [set: _] = 1%:E.
Proof. by rewrite /uniform_prob /mscale/= integral_uniform_pdf1. Qed.

HB.instance Definition _ := @Measure_isProbability.Build _ _ R
  (uniform_prob ab) uniform_setT.

Lemma dominates_uniform_prob : uniform_prob ab `<< mu.
Proof.
move=> A mA muA0; rewrite /uniform_prob integral_uniform_pdf.
apply/eqP; rewrite eq_le; apply/andP; split; last first.
  apply: integral_ge0 => x [Ax /=]; rewrite in_itv /= => xab.
  by rewrite lee_fin uniform_pdf_ge0.
apply: (@le_trans _ _
    (\int[mu]_(x in A `&` `[a, b]%classic) (b - a)^-1%:E))%E; last first.
  rewrite integral_cst//= ?mul1e//.
    by rewrite pmule_rle0 ?lte_fin ?invr_gt0// ?subr_gt0// -muA0 measureIl.
  exact: measurableI.
apply: ge0_le_integral => //=.
- exact: measurableI.
- by move=> x [Ax]; rewrite /= in_itv/= => axb; rewrite lee_fin uniform_pdf_ge0.
- by apply/measurable_EFinP/measurable_funTS; exact: measurable_uniform_pdf.
- by move=> x [Ax _]; rewrite lee_fin invr_ge0// ltW// subr_gt0.
- by move=> x [Ax]; rewrite in_itv/= /uniform_pdf => ->.
Qed.

Let integral_uniform_indic E : measurable E ->
  (\int[uniform_prob ab]_x (\1_E x)%:E =
   (b - a)^-1%:E * \int[mu]_(x in `[a, b]) (\1_E x)%:E)%E.
Proof.
move=> mE; rewrite integral_indic//= /uniform_prob setIT -ge0_integralZl//=.
- rewrite [LHS]integral_mkcond/= [RHS]integral_mkcond/=.
  apply: eq_integral => x _; rewrite !patchE; case: ifPn => xE.
    case: ifPn.
      rewrite inE/= in_itv/= => xab.
      by rewrite /uniform_pdf xab indicE xE mule1.
    by rewrite notin_setE/= in_itv/= => /negP/negbTE; rewrite /uniform_pdf => ->.
  case: ifPn => //.
  by rewrite inE/= in_itv/= => axb; rewrite indicE (negbTE xE) mule0.
- exact/measurable_EFinP/measurable_indic.
- by move=> x _; rewrite lee_fin.
- by rewrite lee_fin invr_ge0// ltW// subr_gt0.
Qed.

Import HBNNSimple.

Let integral_uniform_nnsfun (f : {nnsfun _ >-> R}) :
  (\int[uniform_prob ab]_x (f x)%:E =
   (b - a)^-1%:E * \int[mu]_(x in `[a, b]) (f x)%:E)%E.
Proof.
under [LHS]eq_integral do rewrite fimfunE -fsumEFin//.
rewrite [LHS]ge0_integral_fsum//; last 2 first.
  - by move=> r; exact/measurable_EFinP/measurableT_comp.
  - by move=> n x _; rewrite EFinM nnfun_muleindic_ge0.
rewrite -[RHS]ge0_integralZl//; last 3 first.
  - exact/measurable_EFinP/measurable_funTS.
  - by move=> x _; rewrite lee_fin.
  - by rewrite lee_fin invr_ge0// ltW// subr_gt0.
under [RHS]eq_integral.
  move=> x xD; rewrite fimfunE -fsumEFin// ge0_mule_fsumr; last first.
    by move=> r; rewrite EFinM nnfun_muleindic_ge0.
  over.
rewrite [RHS]ge0_integral_fsum//; last 2 first.
  - by move=> r; apply/measurable_EFinP; do 2 apply/measurableT_comp => //.
  - move=> n x _; rewrite EFinM mule_ge0//; last by rewrite nnfun_muleindic_ge0.
    by rewrite lee_fin invr_ge0// ltW// subr_gt0.
apply: eq_fsbigr => r _; rewrite ge0_integralZl//.
- by rewrite !integralZl_indic_nnsfun//= integral_uniform_indic// muleCA.
- exact/measurable_EFinP/measurableT_comp.
- by move=> t _; rewrite nnfun_muleindic_ge0.
- by rewrite lee_fin invr_ge0// ltW// subr_gt0.
Qed.

Lemma integral_uniform (f : _ -> \bar R) :
  measurable_fun setT f -> (forall x, 0 <= f x)%E ->
  (\int[uniform_prob ab]_x f x = (b - a)^-1%:E * \int[mu]_(x in `[a, b]) f x)%E.
Proof.
move=> mf f0.
have [f_ [ndf_ f_f]] := approximation measurableT mf (fun y _ => f0 y).
transitivity (lim (\int[uniform_prob ab]_x (f_ n x)%:E @[n --> \oo])%E).
  rewrite -monotone_convergence//=.
  - apply: eq_integral => ? /[!inE] xD; apply/esym/cvg_lim => //=.
    exact: f_f.
  - by move=> n; exact/measurable_EFinP/measurable_funTS.
  - by move=> n ? _; rewrite lee_fin.
  - by move=> ? _ ? ? mn; rewrite lee_fin; exact/lefP/ndf_.
rewrite [X in _ = (_ * X)%E](_ : _ = lim
    (\int[mu]_(x in `[a, b]) (f_ n x)%:E @[n --> \oo])%E); last first.
  rewrite -monotone_convergence//=.
  - by apply: eq_integral => ? /[!inE] xD; apply/esym/cvg_lim => //; exact: f_f.
  - by move=> n; exact/measurable_EFinP/measurable_funTS.
  - by move=> n ? _; rewrite lee_fin.
  - by move=> ? _ ? ? /ndf_ /lefP; rewrite lee_fin.
rewrite -limeMl//.
  by apply: congr_lim; apply/funext => n /=; exact: integral_uniform_nnsfun.
apply/ereal_nondecreasing_is_cvgn => x y xy; apply: ge0_le_integral => //=.
- by move=> ? _; rewrite lee_fin.
- exact/measurable_EFinP/measurable_funTS.
- by move=> ? _; rewrite lee_fin.
- exact/measurable_EFinP/measurable_funTS.
- by move=> ? _; rewrite lee_fin; move/ndf_ : xy => /lefP.
Qed.

End uniform_probability.

(* Section bernoulli. *)
(* Variables (R : realType) (p : {nonneg R}) (p1 : (p%:num <= 1)%R). *)
(* Local Open Scope ring_scope. *)

(* Definition bernoulli : set _ -> \bar R := *)
(*   measure_add *)
(*     [the measure _ _ of mscale p [the measure _ _ of dirac (1%R:R)]] *)
(*     [the measure _ _ of mscale (NngNum (onem_ge0 p1)) [the measure _ _ of dirac (0%R:R)]]. *)

(* HB.instance Definition _ := Measure.on bernoulli. *)

(* Local Close Scope ring_scope. *)

(* Let bernoulli_setT : bernoulli [set: _] = 1%E. *)
(* Proof. *)
(* rewrite /bernoulli/= /measure_add/= /msum 2!big_ord_recr/= big_ord0 add0e/=. *)
(* by rewrite /mscale/= !diracT !mule1 -EFinD add_onemK. *)
(* Qed. *)

(* HB.instance Definition _ := *)
(*   @Measure_isProbability.Build _ _ R bernoulli bernoulli_setT. *)

(* End bernoulli. *)

(* Section bernoulli_RV. *)
(* Context d (T : measurableType d) (R : realType) (P : probability T R). *)

(* Definition bernoulli_RV (p : R) : {RV P >-> R} :=  *)

(* End bernoulli_RV. *)

(* Local Open Scope ereal_scope. *)
(* Lemma integral_bernoulli {R : realType} *)
(*     (p : {nonneg R}) (p1 : (p%:num <= 1)%R) (f : R -> \bar R) : *)
(*   measurable_fun setT f -> *)
(*   (forall x, 0 <= f x) -> *)
(*   \int[bernoulli p1]_y (f y) = p%:num%:E * f 1%R + (`1-(p%:num))%:E * f 0%R. *)
(* Proof. *)
(* move=> mf f0. *)
(* rewrite ge0_integral_measure_sum//= 2!big_ord_recl/= big_ord0 adde0/=. *)
(* by rewrite !ge0_integral_mscale//= !integral_dirac//= 2!diracT 2!mul1e. *)
(* Qed. *)

Section integrable_comp.
Context d1 d2 (X : measurableType d1) (Y : measurableType d2) (R : realType).
Variable phi : X -> Y.
Hypothesis mphi : measurable_fun [set: X] phi.
Variable mu : {measure set X -> \bar R}.
Variable f : Y -> \bar R.
Hypothesis mf : measurable_fun [set: Y] f.
Hypothesis intf : mu.-integrable [set: X] (f \o phi).
Local Open Scope ereal_scope.

Lemma integrable_comp_funeneg : (pushforward mu mphi).-integrable [set: Y] f^\-.
Proof.
apply/integrableP; split.
  exact: measurable_funeneg.
move/integrableP : (intf) => [_].
apply: le_lt_trans.
rewrite ge0_integral_pushforward//=; last first.
  apply: measurableT_comp => //=.
  exact: measurable_funeneg.
apply: ge0_le_integral => //=.
apply: measurableT_comp => //=.
apply: measurableT_comp => //=.
exact: measurable_funeneg.
apply: measurableT_comp => //=.
apply: measurableT_comp => //=.
move=> x _.
rewrite -/((abse \o (f \o phi)) x).
rewrite (fune_abse (f \o phi)) /=.
rewrite gee0_abs//.
by rewrite lee_addr//.
Qed.

Lemma integrable_comp_funepos : (pushforward mu mphi).-integrable [set: Y] f^\+.
Proof.
apply/integrableP; split.
  exact: measurable_funepos.
move/integrableP : (intf) => [_].
apply: le_lt_trans.
rewrite ge0_integral_pushforward//=; last first.
  apply: measurableT_comp => //=.
  exact: measurable_funepos.
apply: ge0_le_integral => //=.
apply: measurableT_comp => //=.
apply: measurableT_comp => //=.
exact: measurable_funepos.
apply: measurableT_comp => //=.
apply: measurableT_comp => //=.
move=> x _.
rewrite -/((abse \o (f \o phi)) x).
rewrite (fune_abse (f \o phi)) /=.
rewrite gee0_abs//.
by rewrite lee_addl//.
Qed.

End integrable_comp.

Section transfer.
Local Open Scope ereal_scope.
Context d1 d2 (X : measurableType d1) (Y : measurableType d2) (R : realType).
Variables (phi : X -> Y) (mphi : measurable_fun setT phi).
Variables (mu : {measure set X -> \bar R}).

Lemma integral_pushforward_new (f : Y -> \bar R) :
  measurable_fun setT f ->
  mu.-integrable setT (f \o phi) ->
  \int[pushforward mu mphi]_y f y = \int[mu]_x (f \o phi) x.
Proof.
move=> mf intf.
transitivity (\int[mu]_y ((f^\+ \o phi) \- (f^\- \o phi)) y); last first.
  by apply: eq_integral => x _; rewrite [in RHS](funeposneg (f \o phi)).
rewrite integralB//; [|exact: integrable_funepos|exact: integrable_funeneg].
rewrite -[X in _ = X - _]ge0_integral_pushforward//; last first.
  exact: measurable_funepos.
rewrite -[X in _ = _ - X]ge0_integral_pushforward//; last first.
  exact: measurable_funeneg.
rewrite -integralB//=; last first.
- apply: integrable_comp_funepos => //.
    exact: measurableT_comp.
  exact: integrableN.
- exact: integrable_comp_funepos.
- apply/eq_integral => x _.
  by rewrite /= [in LHS](funeposneg f).
Qed.

End transfer.

Section transfer_probability.
Local Open Scope ereal_scope.
Context d d' (T : measurableType d) (U : measurableType d') (R : realType) (P : probability T R).

Lemma integral_distribution_new (X : {RV P >-> U}) (f : U -> \bar R) :
    measurable_fun setT f ->
    P.-integrable [set: T] (f \o X) ->
  \int[distribution P X]_y f y = \int[P]_x (f \o X) x.
Proof. by move=> mf intf; rewrite integral_pushforward_new. Qed.

End transfer_probability.

Section integral_measure_add_new.
Context d (T : measurableType d) (R : realType)
  (m1 m2 : {measure set T -> \bar R}) (D : set T).
Hypothesis mD : measurable D.
Variable f : T -> \bar R.
Hypothesis intf1 : m1.-integrable D f.
Hypothesis intf2 : m2.-integrable D f.
Hypothesis mf : measurable_fun D f.

Local Open Scope ereal_scope.

Lemma integral_measure_add_new :
  \int[measure_add m1 m2]_(x in D) f x = \int[m1]_(x in D) f x + \int[m2]_(x in D) f x.
transitivity (\int[m1]_(x in D) (f^\+ \- f^\-) x +
              \int[m2]_(x in D) (f^\+ \- f^\-) x); last first.
  by congr +%E; apply: eq_integral => x _; rewrite [in RHS](funeposneg f).
rewrite integralB//; last 2 first.
  exact: integrable_funepos.
  exact: integrable_funeneg.
rewrite integralB//; last 2 first.
  exact: integrable_funepos.
  exact: integrable_funeneg.
rewrite addeACA.
rewrite -ge0_integral_measure_add//; last first.
  apply: measurable_funepos.
  exact: measurable_int intf1.
rewrite -oppeD; last first.
  by rewrite ge0_adde_def// inE integral_ge0.
rewrite -ge0_integral_measure_add//; last first.
  apply: measurable_funeneg.
  exact: measurable_int intf1.
by rewrite integralE.
Qed.

End integral_measure_add_new.

Lemma fiberwise_finite_preimage {T U} (B : set U) (f : T -> U) :
  (forall b, B b -> finite_set (f @^-1` [set b])) ->
             finite_set B -> finite_set (f @^-1` B).
Proof.
move=> *.
rewrite -(image_id B) -bigcup_imset1 preimage_bigcup.
exact: bigcup_finite.
Qed.

(* TODO : PR in progress *)
Lemma countable_measurable d {T : measurableType d} (S : set T) :
  (forall (a : T), measurable [set a]) -> countable S -> measurable S.
Proof.
move=> ma.
move/countable_injP => [f injf].
have [->//|/set0P[a Sa]] := eqVneq S set0.
rewrite -(injpinv_image (fun=> a) injf).
rewrite [X in _ X](_ :_= \bigcup_(x in f @` S) [set 'pinv_(fun=> a) S f x]); last first.
  rewrite eqEsubset; split => x/=.
    move=> [n [xn Sxn xnn nx]].
    exists n => //=.
    by exists xn.
  move=> [n [xn Sxn xnn] /= xinvn].
  exists n => //=.
  by exists xn.
apply: bigcup_measurable => n _.
apply: ma.
Qed.

Section independent_events.
Context {R : realType} d {T : measurableType d}.
Variable P : probability T R.
Local Open Scope ereal_scope.

Definition independent_events (I0 : choiceType) (I : set I0) (A : I0 -> set T) :=
  forall J : {fset I0}, [set` J] `<=` I ->
    P (\bigcap_(i in [set` J]) A i) = \prod_(i <- J) P (A i).

End independent_events.

Section independent_classes.
Context {R : realType} d {T : measurableType d}.
Variable P : probability T R.
Local Open Scope ereal_scope.

Definition independent_classes (I0 : choiceType) (I : set I0)
    (F : I0 -> set (set T)) :=
  (forall i : I0, I i -> F i `<=` @measurable _ T) /\
  forall J : {fset I0},
    [set` J] `<=` I ->
    forall E : I0 -> set T,
      (forall i : I0, i \in J -> E i \in F i) ->
        P (\big[setI/setT]_(j <- J) E j) = \prod_(j <- J) P (E j).

End independent_classes.

Definition g_sigma_algebra_mappingType d' (T : pointedType)
  (T' : measurableType d') (f : T -> T') : Type := T.

Definition g_sigma_algebra_mapping d' (T : pointedType)
    (T' : measurableType d') (f : T -> T') :=
  preimage_class setT f (@measurable _ T').

Section generated_sigma_algebra.
Context {d'} (T : pointedType) (T' : measurableType d').
Variable f : T -> T'.

Let g_sigma_algebra_mapping_set0 : g_sigma_algebra_mapping f set0.
Proof.
rewrite /g_sigma_algebra_mapping /preimage_class/=.
by exists set0 => //; rewrite preimage_set0 setI0.
Qed.

Let g_sigma_algebra_mapping_setC A :
  g_sigma_algebra_mapping f A -> g_sigma_algebra_mapping f (~` A).
Proof.
rewrite /g_sigma_algebra_mapping /preimage_class/= => -[B mB] <-{A}.
by exists (~` B); [exact: measurableC|rewrite !setTI preimage_setC].
Qed.

Let g_sigma_algebra_mapping_bigcup (F : (set T)^nat) :
  (forall i, g_sigma_algebra_mapping f (F i)) ->
  g_sigma_algebra_mapping f (\bigcup_i (F i)).
Proof.
move=> mF; rewrite /g_sigma_algebra_mapping /preimage_class/=.
pose g := fun i => sval (cid2 (mF i)).
pose mg := fun i => svalP (cid2 (mF i)).
exists (\bigcup_i g i).
  by apply: bigcup_measurable => k; case: (mg k).
  rewrite setTI /g preimage_bigcup; apply: eq_bigcupr => k _.
by case: (mg k) => _; rewrite setTI.
Qed.

HB.instance Definition _ := Pointed.on (g_sigma_algebra_mappingType f).

HB.instance Definition _ := @isMeasurable.Build default_measure_display
  (g_sigma_algebra_mappingType f) (g_sigma_algebra_mapping f)
  g_sigma_algebra_mapping_set0 g_sigma_algebra_mapping_setC
  g_sigma_algebra_mapping_bigcup.

End generated_sigma_algebra.

Section generated_sigma_algebra_RV.
Context {R : realType} d d' (T : measurableType d) (T' : measurableType d').
Variable P : probability T R.

Definition independent_RVs (I0 : choiceType) (I : set I0) (X : I0 -> {mfun T >-> T'}) : Prop :=
  independent_classes P I (fun i => g_sigma_algebra_mapping (X i)).

End generated_sigma_algebra_RV.

Section independent_RVs2.
Context {R : realType} d d' (T : measurableType d) (T' : measurableType d').
Variable P : probability T R.

Definition independent_RVs2 (X Y : {mfun T >-> T'}) :=
  independent_RVs P [set 0%N; 1%N] [eta (fun=> cst point) with 0%N |-> X, 1%N |-> Y].

End independent_RVs2.


Section bool_to_real.
Context d (T : measurableType d) (R : realType) (P : probability T R) (f : {mfun T >-> bool}).
Definition bool_to_real : T -> R := (fun x => x%:R) \o (f : T -> bool).

Lemma measurable_bool_to_real : measurable_fun [set: T] bool_to_real.
Proof.
rewrite /bool_to_real.
apply: measurableT_comp => //=.
exact: (@measurable_funP _ _ _ _ f).
Qed.
(* HB.about isMeasurableFun.Build. *)
HB.instance Definition _ :=
  isMeasurableFun.Build _ _ _ _ bool_to_real measurable_bool_to_real.

Definition btr : {RV P >-> R} := bool_to_real.

End bool_to_real.

(* Section measurable_fun. *)
(* Local Open Scope ereal_scope. *)
(* Context d (T : measurableType d) (R : realType). *)
(* Implicit Types (D : set T) (f g : T -> R). *)

(* Lemma measurable_funD D f g : *)
(*   measurable_fun D f -> measurable_fun D g -> measurable_fun D (f \+ g). *)
(* Proof. *)
(* move=> /measurable_EFinP mf /measurable_EFinP mg. *)
(* by have /measurable_EFinP := emeasurable_funD mf mg. *)
(* Qed. *)

(* Lemma measurable_fun_sum D I s (h : I -> (T -> R)) : *)
(*   (forall n, measurable_fun D (h n)) -> *)
(*   measurable_fun D (fun x => \sum_(i <- s) h i x)%R. *)
(* Proof. *)
(* move=> mh. *)
(* apply/measurable_EFinP. *)
(* rewrite (_ : _ \o _ = (fun t => (\sum_(i <- s) (h i t)%:E))); last first. *)
(*   by apply/funext => t/=; rewrite -sumEFin. *)
(* apply/emeasurable_fun_sum => i. *)
(* exact/measurable_EFinP. *)
(* Qed. *)

(* End measurable_fun. *)

Section bernoulli.

Local Open Scope ereal_scope.
Context d (T : measurableType d) (R : realType) (P : probability T R).
Variable p : R.
Hypothesis p01 : (0 <= p <= 1)%R.

Definition bernoulli_RV (X : {dRV P >-> bool}) :=
  distribution P X = bernoulli p.

Lemma bernoulli_RV1 (X : {dRV P >-> bool}) : bernoulli_RV X ->
  P [set i | X i == 1%R] == p%:E.
Proof.
move=> [[/(congr1 (fun f => f [set 1%:R]))]].
rewrite bernoulliE//.
rewrite /mscale/=.
rewrite diracE/= mem_set// mule1// diracE/= memNset//.
rewrite mule0 adde0.
rewrite /distribution /= => <-.
apply/eqP; congr (P _).
rewrite /preimage/=.
by apply/seteqP; split => [x /eqP H//|x /eqP].
Qed.

Lemma bernoulli_RV2 (X : {dRV P >-> bool}) : bernoulli_RV X ->
  P [set i | X i == 0%R] == (`1-p)%:E.
Proof.
move=> [[/(congr1 (fun f => f [set 0%:R]))]].
rewrite bernoulliE//.
rewrite /mscale/=.
rewrite diracE/= memNset//.
rewrite mule0// diracE/= mem_set// add0e mule1.
rewrite /distribution /= => <-.
apply/eqP; congr (P _).
rewrite /preimage/=.
by apply/seteqP; split => [x /eqP H//|x /eqP].
Qed.

Lemma bernoulli_expectation (X : {dRV P >-> bool}) :
  bernoulli_RV X -> 'E_P[btr P X] = p%:E.
Proof.
move=> bX.
rewrite unlock /btr.
rewrite -(@integral_distribution _ _ _ _ _ _ X (EFin \o [eta GRing.natmul 1]))//; last first.
  by move=> y //=.
rewrite /bernoulli/=.
rewrite (@eq_measure_integral _ _ _ _ (bernoulli p)); last first.
  by move=> A mA _/=; rewrite (_ : distribution P X = bernoulli p).
rewrite integral_bernoulli//=.
by rewrite -!EFinM -EFinD mulr0 addr0 mulr1.
Qed.

Lemma integrable_bernoulli (X : {dRV P >-> bool}) :
  bernoulli_RV X -> P.-integrable [set: T] (EFin \o btr P X).
Proof.
move=> bX.
apply/integrableP; split; first by apply: measurableT_comp => //; exact: measurable_bool_to_real.
have -> : \int[P]_x `|(EFin \o btr P X) x| = 'E_P[btr P X].
  rewrite unlock /expectation.
  apply: eq_integral => x _.
  by rewrite gee0_abs //= lee_fin.
by rewrite bernoulli_expectation// ltry.
Qed.

Lemma bool_RV_sqr (X : {dRV P >-> bool}) :
  ((btr P X ^+ 2) = btr P X :> (T -> R))%R.
Proof.
apply: funext => x /=.
rewrite /GRing.exp /btr/bool_to_real /GRing.mul/=.
by case: (X x) => /=; rewrite ?mulr1 ?mulr0.
Qed.

Lemma bernoulli_variance (X : {dRV P >-> bool}) :
  bernoulli_RV X -> 'V_P[btr P X] = (p * (`1-p))%:E.
Proof.
move=> b.
rewrite (@varianceE _ _ _ _ (btr P X));
  [|rewrite ?[X in _ \o X]bool_RV_sqr; exact: integrable_bernoulli..].
rewrite [X in 'E_P[X]]bool_RV_sqr !bernoulli_expectation//.
by rewrite expe2 -EFinD onemMr.
Qed.

Definition is_bernoulli_trial n (X : {dRV P >-> bool}^nat) :=
  (forall i, (i < n)%nat -> bernoulli_RV (X i)) /\ independent_RVs P `I_n X.

Definition bernoulli_trial n (X : {dRV P >-> bool}^nat) : {RV P >-> R} :=
  (\sum_(i<n) (btr P (X i)))%R. (* TODO: add HB instance measurablefun sum*)

Lemma expectation_bernoulli_trial (X : {dRV P >-> bool}^nat) n :
  is_bernoulli_trial n X -> 'E_P[@bernoulli_trial n X] = (n%:R * p)%:E.
Proof.
move=> bRV. rewrite /bernoulli_trial.
transitivity ('E_P[\sum_(s <- map (btr P \o X) (iota 0 n)) s]).
  by rewrite big_map -[in RHS](subn0 n) big_mkord.
rewrite expectation_sum; last first.
  by move=> Xi; move/mapP=> [k kn] ->; apply: integrable_bernoulli; apply bRV; rewrite mem_iota leq0n in kn.
rewrite big_map -[in LHS](subn0 n) big_mkord.
transitivity (\sum_(i < n) p%:E).
  apply: eq_bigr => k _.
  rewrite bernoulli_expectation//.
  apply bRV.
  by [].
by rewrite sumEFin big_const_ord iter_addr addr0 mulrC mulr_natr.
Qed.

Definition sumrfct (s : seq {mfun T >-> R}) := (fun x => \sum_(f <- s) f x)%R.

Lemma measurable_sumrfct s : measurable_fun setT (sumrfct s).
Proof.
rewrite /sumrfct.
pose n := size s.
apply/measurable_EFinP => /=.
have -> : (EFin \o (fun x : T => (\sum_(f <- s) f x)%R)) = (fun x : T => \sum_(i < n) (s`_i x)%:E)%R.
  apply: funext => x /=.
  rewrite sumEFin.
  congr (_%:E).
  rewrite big_tnth//.
  apply: eq_bigr => i _ /=.
  by rewrite (tnth_nth 0%R).
apply: emeasurable_fun_sum => i.
by apply/measurable_EFinP.
Qed.

HB.about isMeasurableFun.Build.
HB.instance Definition _ s :=
  isMeasurableFun.Build _ _ _ _ (sumrfct s) (measurable_sumrfct s).

Lemma sumrfctE' (s : seq {mfun T >-> R}) x :
  ((\sum_(f <- s) f) x = sumrfct s x)%R.
Proof. by rewrite/sumrfct; elim/big_ind2 : _ => //= u a v b <- <-. Qed.

Lemma bernoulli_trial_ge0 (X : {dRV P >-> bool}^nat) n : is_bernoulli_trial n X ->
  (forall t, 0 <= bernoulli_trial n X t)%R.
Proof.
move=> [bRV Xn] t.
rewrite /bernoulli_trial.
have -> : (\sum_(i < n) btr P (X i))%R = (\sum_(s <- map (btr P \o X) (iota 0 n)) s)%R.
  by rewrite big_map -[in RHS](subn0 n) big_mkord.
have -> : (\sum_(s <- [seq (btr P \o X) i | i <- iota 0 n]) s)%R t = (\sum_(s <- [seq (btr P \o X) i | i <- iota 0 n]) s t)%R.
  by rewrite sumrfctE'.
rewrite big_map.
by apply: sumr_ge0 => i _/=; rewrite /bool_to_real/= ler0n.
Qed.

(* this seems to be provable like in https://www.cs.purdue.edu/homes/spa/courses/pg17/mu-book.pdf page 65 *)
Axiom taylor_ln_le : forall (delta : R), ((1 + delta) * ln (1 + delta) >= delta + delta^+2 / 3)%R.

Lemma expR_prod d' {U : measurableType d'} (X : seq {mfun U >-> R}) (f : {mfun U >-> R} -> R) :
  (\prod_(x <- X) expR (f x) = expR (\sum_(x <- X) f x))%R.
Proof.
elim: X => [|h t ih]; first by rewrite !big_nil expR0.
by rewrite !big_cons ih expRD.
Qed.

Lemma expR_sum U l Q (f : U -> R) : (expR (\sum_(i <- l | Q i) f i) = \prod_(i <- l | Q i) expR (f i))%R.
Proof.
elim: l; first by rewrite !big_nil expR0.
move=> a l ih.
rewrite !big_cons.
case: ifP => //= aQ.
by rewrite expRD ih.
Qed.

Lemma sumr_map U d' (V : measurableType d') (l : seq U) Q (f : U -> {mfun V >-> R}) (x : V) :
  ((\sum_(i <- l | Q i) f i) x = \sum_(i <- l | Q i) f i x)%R.
Proof.
elim: l; first by rewrite !big_nil.
move=> a l ih.
rewrite !big_cons.
case: ifP => aQ//=.
by rewrite -ih.
Qed.

Lemma prodr_map U d' (V : measurableType d') (l : seq U) Q (f : U -> {mfun V >-> R}) (x : V) :
  ((\prod_(i <- l | Q i) f i) x = \prod_(i <- l | Q i) f i x)%R.
Proof.
elim: l; first by rewrite !big_nil.
move=> a l ih.
rewrite !big_cons.
case: ifP => aQ//=.
by rewrite -ih.
Qed.

Lemma independent_mmt_gen_fun (X : {dRV P >-> bool}^nat) n t :
  let mmtX (i : nat) : {RV P >-> R} := expR \o t \o* (btr P (X i)) in
  independent_RVs P `I_n X -> independent_RVs P `I_n mmtX.
Admitted.

Lemma expectation_prod_independent_RVs (X : {RV P >-> R}^nat) n :
  independent_RVs P `I_n X ->
  'E_P[\prod_(i < n) (X i)] = \prod_(i < n) 'E_P[X i].
Admitted.

Lemma bernoulli_trial_mmt_gen_fun (X_ : {dRV P >-> bool}^nat) n (t : R) :
  is_bernoulli_trial n X_ ->
  let X := bernoulli_trial n X_ in
  mmt_gen_fun X t = \prod_(i < n) mmt_gen_fun (btr P (X_ i)) t.
Proof.
move=> []bRVX iRVX /=.
rewrite /bernoulli_trial/mmt_gen_fun.
pose mmtX (i : nat) : {RV P >-> R} := expR \o t \o* (btr P (X_ i)).
have iRV_mmtX : independent_RVs P `I_n mmtX.
  exact: independent_mmt_gen_fun.
transitivity ('E_P[\prod_(i < n) mmtX i])%R.
  congr ('E_P[_]).
  apply: funext => x/=.
  rewrite sumr_map mulr_suml expR_sum prodr_map.
  exact: eq_bigr.
exact: expectation_prod_independent_RVs.
Qed.

Lemma bernoulli_mmt_gen_fun (X : {dRV P >-> bool}) (t : R) :
  bernoulli_RV X -> mmt_gen_fun (btr P X : {RV P >-> R}) t = (p * expR t + (1-p))%:E.
Proof.
move=> bX. rewrite/mmt_gen_fun.
transitivity ((expR (t * 1))%:E * P [set x | X x == true] + (expR (t * 0))%:E * P [set x | X x == false]).
  (* something from dRV *)
  admit.
rewrite mulr1 mulr0 expR0 mul1e.
rewrite (eqP (bernoulli_RV1 bX)) (eqP (bernoulli_RV2 bX)).
by rewrite -EFinM -EFinD mulrC.
Admitted.

Lemma iter_mule (n : nat) (x y : \bar R) : iter n ( *%E x) y = (x ^+ n * y)%E.
Proof. by elim: n => [|n ih]; rewrite ?mul1e// [LHS]/= ih expeS muleA. Qed.

Lemma binomial_mmt_gen_fun (X_ : {dRV P >-> bool}^nat) n (t : R) :
  is_bernoulli_trial n X_ ->
  let X := bernoulli_trial n X_ : {RV P >-> R} in
  mmt_gen_fun X t = ((p * expR t + (1-p))`^(n%:R))%:E.
Proof.
move: p01 => /andP[p0 p1] bX/=.
rewrite bernoulli_trial_mmt_gen_fun//.
under eq_bigr => i _.
  rewrite bernoulli_mmt_gen_fun; last exact: bX.1.
  over.
rewrite big_const iter_mule mule1 cardT size_enum_ord -EFin_expe powR_mulrn//.
by rewrite addr_ge0// ?subr_ge0// mulr_ge0// expR_ge0.
Qed.

Lemma prod_EFin U l Q (f : U -> R) : \prod_(i <- l | Q i) ((f i)%:E) = (\prod_(i <- l | Q i) f i)%:E.
Proof.
elim: l; first by rewrite !big_nil.
move=> a l ih.
rewrite !big_cons.
case: ifP => //= aQ.
by rewrite EFinM ih.
Qed.

Lemma lm23 (X_ : {dRV P >-> bool}^nat) (t : R) n :
  (0 <= t)%R ->
  is_bernoulli_trial n X_ ->
  let X := bernoulli_trial n X_ : {RV P >-> R} in
  mmt_gen_fun X t <= (expR (fine 'E_P[X] * (expR t - 1)))%:E.
Proof.
move=> t0 bX/=.
have /andP[p0 p1] := p01.
rewrite binomial_mmt_gen_fun// lee_fin.
rewrite expectation_bernoulli_trial//.
rewrite addrCA -{2}(mulr1 p) -mulrN -mulrDr.
rewrite -mulrA (mulrC (n%:R)) expRM ge0_ler_powR// ?nnegrE ?expR_ge0//.
  by rewrite addr_ge0// mulr_ge0// subr_ge0 -expR0 ler_expR.
exact: expR_ge1Dx.
Qed.

Lemma expR_powR (x y : R) : (expR (x * y) = (expR x) `^ y)%R.
Proof. by rewrite /powR gt_eqF ?expR_gt0// expRK mulrC. Qed.

Lemma end_thm24 (X_ : {dRV P >-> bool}^nat) n (t delta : R) :
  is_bernoulli_trial n X_ ->
  (0 < delta)%R ->
  let X := @bernoulli_trial n X_ in
  let mu := 'E_P[X] in
  let t := ln (1 + delta) in
  (expR (expR t - 1) `^ fine mu)%:E *
    (expR (- t * (1 + delta)) `^ fine mu)%:E <=
    ((expR delta / (1 + delta) `^ (1 + delta)) `^ fine mu)%:E.
Proof.
move=> bX d0 /=.
rewrite -EFinM lee_fin -powRM ?expR_ge0// ge0_ler_powR ?nnegrE//.
- by rewrite fine_ge0// expectation_ge0// => x; exact: (bernoulli_trial_ge0 bX).
- by rewrite mulr_ge0// expR_ge0.
- by rewrite divr_ge0 ?expR_ge0// powR_ge0.
- rewrite lnK ?posrE ?addr_gt0// addrAC subrr add0r ler_wpmul2l ?expR_ge0//.
  by rewrite -powRN mulNr -mulrN expR_powR lnK// posrE addr_gt0.
Qed.

(* theorem 2.4 Rajani / thm 4.4.(2) mu-book *)
Theorem thm24 (X_ : {dRV P >-> bool}^nat) n (delta : R) :
  is_bernoulli_trial n X_ ->
  (0 < delta)%R ->
  let X := @bernoulli_trial n X_ in
  let mu := 'E_P[X] in
  P [set i | X i >= (1 + delta) * fine mu]%R <=
  ((expR delta / ((1 + delta) `^ (1 + delta))) `^ (fine mu))%:E.
Proof.
rewrite /= => bX delta0.
set X := @bernoulli_trial n X_.
set mu := 'E_P[X].
set t := ln (1 + delta).
have t0 : (0 < t)%R by rewrite ln_gt0// ltr_addl.
apply: (le_trans (chernoff _ _ t0)).
apply: (@le_trans _ _ ((expR (fine mu * (expR t - 1)))%:E *
                       (expR (- (t * ((1 + delta) * fine mu))))%:E)).
  rewrite lee_pmul2r ?lte_fin ?expR_gt0//.
  by apply: (lm23 _ bX); rewrite le_eqVlt t0 orbT.
rewrite mulrC expR_powR -mulNr mulrA expR_powR.
exact: (end_thm24 _ bX).
Qed.

(* theorem 2.5 *)
Theorem poisson_ineq (X : {dRV P >-> bool}^nat) (delta : R) n :
  is_bernoulli_trial n X ->
  let X' := @bernoulli_trial n X in
  let mu := 'E_P[X'] in
  (0 < n)%nat ->
  (0 < delta < 1)%R ->
  P [set i | X' i >= (1 + delta) * fine mu]%R <=
  (expR (- (fine mu * delta ^+ 2) / 3))%:E.
Proof.
move=> bX X' mu n0 /andP[delta0 _].
apply: (@le_trans _ _ (expR ((delta - (1 + delta) * ln (1 + delta)) * fine mu))%:E).
  rewrite expR_powR expRB (mulrC _ (ln _)) expR_powR lnK; last rewrite posrE addr_gt0//.
  apply: (thm24 bX) => //.
apply: (@le_trans _ _ (expR ((delta - (delta + delta ^+ 2 / 3)) * fine mu))%:E).
  rewrite lee_fin ler_expR ler_wpmul2r//.
    by rewrite fine_ge0//; apply: expectation_ge0 => t; exact: (bernoulli_trial_ge0 bX).
  rewrite ler_sub//.
  exact: taylor_ln_le.
rewrite le_eqVlt; apply/orP; left; apply/eqP; congr (expR _)%:E.
by rewrite opprD addrA subrr add0r mulrC mulrN mulNr mulrA.
Qed.

(* TODO: move *)
Lemma ln_div : {in Num.pos &, {morph ln (R:=R) : x y / (x / y)%R >-> (x - y)%R}}.
Proof.
by move=> x y; rewrite !posrE => x0 y0; rewrite lnM ?posrE ?invr_gt0// lnV ?posrE.
Qed.

Lemma norm_expR : normr \o expR = (expR : R -> R).
Proof. by apply/funext => x /=; rewrite ger0_norm ?expR_ge0. Qed.

(* Rajani thm 2.6 / mu-book thm 4.5.(2) *)
Theorem thm26 (X : {dRV P >-> bool}^nat) (delta : R) n :
  is_bernoulli_trial n X -> (0 < delta < 1)%R ->
  let X' := @bernoulli_trial n X : {RV P >-> R} in
  let mu := 'E_P[X'] in
  P [set i | X' i <= (1 - delta) * fine mu]%R <= (expR (-(fine mu * delta ^+ 2) / 2)%R)%:E.
Proof.
move=> bX /andP[delta0 delta1] /=.
set X' := @bernoulli_trial n X : {RV P >-> R}.
set mu := 'E_P[X'].
have /andP[p0 p1] := p01.
apply: (@le_trans _ _ (((expR (- delta) / ((1 - delta) `^ (1 - delta))) `^ (fine mu))%:E)).
  (* using Markov's inequality somewhere, see mu's book page 66 *)
  have H1 t : (t < 0)%R ->
    P [set i | (X' i <= (1 - delta) * fine mu)%R] = P [set i | `|(expR \o t \o* X') i|%:E >= (expR (t * (1 - delta) * fine mu))%:E].
    move=> t0; apply: congr1; apply: eq_set => x /=.
    rewrite lee_fin ger0_norm ?expR_ge0// ler_expR (mulrC _ t) -mulrA.
    by rewrite -[in RHS]ler_ndivr_mull// mulrA mulVf ?lt_eqF// mul1r.
  set t := ln (1 - delta).
  have ln1delta : (t < 0)%R.
    (* TODO: lacking a lemma here *)
    rewrite -oppr0 ltr_oppr -lnV ?posrE ?subr_gt0// ln_gt0//.
    by rewrite invf_gt1// ?subr_gt0// ltr_subl_addr ltr_addl.
  have {H1}-> := H1 _ ln1delta.
  apply: (@le_trans _ _ (((fine 'E_P[normr \o expR \o t \o* X']) / (expR (t * (1 - delta) * fine mu))))%:E).
    rewrite EFinM lee_pdivl_mulr ?expR_gt0// muleC fineK.
    apply: (@markov _ _ _ P (expR \o t \o* X' : {RV P >-> R}) id (expR (t * (1 - delta) * fine mu))%R _ _ _ _) => //.
    - apply: expR_gt0.
    - rewrite norm_expR.
      have -> : 'E_P[expR \o t \o* X'] = mmt_gen_fun X' t by [].
      by rewrite (binomial_mmt_gen_fun _ bX).
  apply: (@le_trans _ _ (((expR ((expR t - 1) * fine mu)) / (expR (t * (1 - delta) * fine mu))))%:E).
    rewrite norm_expR lee_fin ler_wpmul2r ?invr_ge0 ?expR_ge0//.
    have -> : 'E_P[expR \o t \o* X'] = mmt_gen_fun X' t by [].
    rewrite (binomial_mmt_gen_fun _ bX)/=.
    rewrite /mu /X' (expectation_bernoulli_trial bX)/=.
    rewrite !lnK ?posrE ?subr_gt0//.
    rewrite expR_powR powRrM powRAC.
    rewrite ge0_ler_powR ?ler0n// ?nnegrE ?powR_ge0//.
      by rewrite addr_ge0 ?mulr_ge0// subr_ge0// ltW.
    rewrite addrAC subrr sub0r -expR_powR.
    rewrite addrCA -{2}(mulr1 p) -mulrBr addrAC subrr sub0r mulrC mulNr.
    by apply: expR_ge1Dx.
  rewrite !lnK ?posrE ?subr_gt0//.
  rewrite -addrAC subrr sub0r -mulrA [X in (_ / X)%R]expR_powR lnK ?posrE ?subr_gt0//.
  rewrite -[in leRHS]powR_inv1 ?powR_ge0// powRM// ?expR_ge0 ?invr_ge0 ?powR_ge0//.
  by rewrite powRAC powR_inv1 ?powR_ge0// powRrM expR_powR.
rewrite lee_fin.
rewrite -mulrN -mulrA [in leRHS]mulrC expR_powR ge0_ler_powR// ?nnegrE.
- by rewrite fine_ge0// expectation_ge0// => x; exact: (bernoulli_trial_ge0 bX).
- by rewrite divr_ge0 ?expR_ge0// powR_ge0.
- by rewrite expR_ge0.
- rewrite -ler_ln ?posrE ?divr_gt0 ?expR_gt0 ?powR_gt0 ?subr_gt0//.
  rewrite expRK// ln_div ?posrE ?expR_gt0 ?powR_gt0 ?subr_gt0//.
  rewrite expRK//.
  rewrite /powR (*TODO: lemma ln of powR*) gt_eqF ?subr_gt0// expRK.
  (* requires analytical argument: see p.66 of mu's book *)
  admit.
Admitted.

Lemma measurable_fun_le D (f g : T -> R) : d.-measurable D -> measurable_fun D f ->
  measurable_fun D g -> measurable (D `&` [set x | f x <= g x]%R).
Proof.
move=> mD mf mg.
under eq_set => x do rewrite -lee_fin.
apply: emeasurable_fun_le => //; apply: measurableT_comp => //.
Qed.

(* Rajani -> corollary 2.7 / mu-book -> corollary 4.7 *)
Corollary cor27 (X : {dRV P >-> bool}^nat) (delta : R) n :
  is_bernoulli_trial n X -> (0 < delta < 1)%R ->
  (0 < n)%nat ->
  (0 < p)%R ->
  let X' := @bernoulli_trial n X in
  let mu := 'E_P[X'] in
  P [set i | `|X' i - fine mu | >=  delta * fine mu]%R <=
  (expR (- (fine mu * delta ^+ 2) / 3)%R *+ 2)%:E.
Proof.
move=> bX /andP[d0 d1] n0 p0 /=.
set X' := @bernoulli_trial n X.
set mu := 'E_P[X'].
under eq_set => x.
  rewrite ler_normr.
  rewrite ler_subr_addl opprD opprK -{1}(mul1r (fine mu)) -mulrDl.
  rewrite -ler_sub_addr -(ler_opp2 (- _)%R) opprK opprB.
  rewrite -{2}(mul1r (fine mu)) -mulrBl.
  rewrite -!lee_fin.
  over.
rewrite /=.
rewrite set_orb.
rewrite measureU; last 3 first.
- rewrite -(@setIidr _ setT [set _ | _]) ?subsetT//.
  apply: emeasurable_fun_le => //.
  apply: measurableT_comp => //.
- rewrite -(@setIidr _ setT [set _ | _]) ?subsetT//.
  apply: emeasurable_fun_le => //.
  apply: measurableT_comp => //.
- rewrite disjoints_subset => x /=.
  rewrite /mem /in_mem/= => X0; apply/negP.
  rewrite -ltNge.
  apply: (@lt_le_trans _ _ _ _ _ _ X0).
  rewrite !EFinM.
  rewrite lte_pmul2r//; first by rewrite lte_fin ltr_add2l gt0_cp.
  by rewrite fineK /mu/X' (expectation_bernoulli_trial bX)// lte_fin  mulr_gt0 ?ltr0n.
rewrite mulr2n EFinD lee_add//=.
- by apply: (poisson_ineq bX); rewrite //d0 d1.
- apply: (le_trans (@thm26 _ delta _ bX _)); first by rewrite d0 d1.
  rewrite lee_fin ler_expR !mulNr ler_opp2.
  rewrite ler_pmul//; last by rewrite lef_pinv ?posrE ?ler_nat.
  rewrite mulr_ge0 ?fine_ge0 ?sqr_ge0//.
  rewrite /mu unlock /expectation integral_ge0// => x _.
  by rewrite /X' lee_fin; apply: (bernoulli_trial_ge0 bX).
Qed.

(* Rajani thm 3.1 / mu-book thm 4.7 *)
Theorem sampling (X : {dRV P >-> bool}^nat) n (theta delta : R) :
  let X_sum := bernoulli_trial n X in
  let X' x := (X_sum x) / n%:R in
  (0 < p)%R ->
  is_bernoulli_trial n X ->
  (0 < delta <= 1)%R -> (0 < theta < p)%R -> (0 < n)%nat ->
  (3 / theta ^+ 2 * ln (2 / delta) <= n%:R)%R ->
  P [set i | `| X' i - p | <= theta]%R >= 1 - delta%:E.
Proof.
move=> X_sum X' p0 bX /andP[delta0 delta1] /andP[theta0 thetap] n0 tdn.
have E_X_sum: 'E_P[X_sum] = (p * n%:R)%:E.
  by rewrite /X_sum expectation_bernoulli_trial// mulrC.
have /andP[_ p1] := p01.
set epsilon := theta / p.
have epsilon01 : (0 < epsilon < 1)%R.
  by rewrite /epsilon ?ltr_pdivr_mulr ?divr_gt0 ?mul1r.
have thetaE : theta = (epsilon * p)%R.
  by rewrite /epsilon -mulrA mulVf ?mulr1// gt_eqF.
have step1 : P [set i | `| X' i - p | >= epsilon * p]%R <=
    ((expR (- (p * n%:R * (epsilon ^+ 2)) / 3)) *+ 2)%:E.
  rewrite [X in P X <= _](_ : _ =
      [set i | `| X_sum i - p * n%:R | >= epsilon * p * n%:R]%R); last first.
    apply/seteqP; split => [t|t]/=.
      move/(@ler_wpmul2r _ n%:R (ler0n _ _)) => /le_trans; apply.
      rewrite -[X in (_ * X)%R](@ger0_norm _ n%:R)// -normrM mulrBl.
      by rewrite -mulrA mulVf ?mulr1// gt_eqF ?ltr0n.
    move/(@ler_wpmul2r _ n%:R^-1); rewrite invr_ge0// ler0n => /(_ erefl).
    rewrite -(mulrA _ _ n%:R^-1) divff ?mulr1 ?gt_eqF ?ltr0n//.
    move=> /le_trans; apply.
    rewrite -[X in (_ * X)%R](@ger0_norm _ n%:R^-1)// -normrM mulrBl.
    by rewrite -mulrA divff ?mulr1// gt_eqF// ltr0n.
  rewrite -mulrA.
  have -> : (p * n%:R)%R = fine (p * n%:R)%:E by [].
  rewrite -E_X_sum.
  by apply: (@cor27 X epsilon _ bX).
have step2 : P [set i | `| X' i - p | >= theta]%R <=
    ((expR (- (n%:R * theta ^+ 2) / 3)) *+ 2)%:E.
  rewrite thetaE; move/le_trans : step1; apply.
  rewrite lee_fin ler_wmuln2r// ler_expR mulNr ler_oppl mulNr opprK.
  rewrite -2![in leRHS]mulrA [in leRHS]mulrCA.
  rewrite /epsilon -mulrA mulVf ?gt_eqF// mulr1 -!mulrA !ler_wpM2l ?(ltW theta0)//.
  rewrite mulrCA ler_wpM2l ?(ltW theta0)//.
  rewrite [X in (_ * X)%R]mulrA mulVf ?gt_eqF// -[leLHS]mul1r [in leRHS]mul1r.
  by rewrite ler_wpM2r// invf_ge1.
suff : delta%:E >= P [set i | (`|X' i - p| >=(*NB: this >= in the pdf *) theta)%R].
  rewrite [X in P X <= _ -> _](_ : _ = ~` [set i | (`|X' i - p| < theta)%R]); last first.
    apply/seteqP; split => [t|t]/=.
      by rewrite leNgt => /negP.
    by rewrite ltNge => /negP/negPn.
  have ? : measurable [set i | (`|X' i - p| < theta)%R].
    under eq_set => x do rewrite -lte_fin.
    rewrite -(@setIidr _ setT [set _ | _]) ?subsetT /X'//.
    by apply: emeasurable_fun_lt => //; apply: measurableT_comp => //;
      apply: measurableT_comp => //; apply: measurable_funD => //;
      apply: measurable_funM.
  rewrite probability_setC// lee_subel_addr//.
  rewrite -lee_subel_addl//; last by rewrite fin_num_measure.
  move=> /le_trans; apply.
  rewrite le_measure ?inE//.
    under eq_set => x do rewrite -lee_fin.
    rewrite -(@setIidr _ setT [set _ | _]) ?subsetT /X'//.
    by apply: emeasurable_fun_le => //; apply: measurableT_comp => //;
      apply: measurableT_comp => //; apply: measurable_funD => //;
      apply: measurable_funM.
  by move=> t/= /ltW.
(* NB: last step in the pdf *)
apply: (le_trans step2).
rewrite lee_fin -(mulr_natr _ 2) -ler_pdivl_mulr//.
rewrite -(@lnK _ (delta / 2)); last by rewrite posrE divr_gt0.
rewrite ler_expR mulNr ler_oppl -lnV; last by rewrite posrE divr_gt0.
rewrite invf_div ler_pdivl_mulr// mulrC.
rewrite -ler_pdivr_mulr; last by rewrite exprn_gt0.
by rewrite mulrAC.
Qed.

End bernoulli.
