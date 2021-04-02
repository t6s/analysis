# Changelog (unreleased)

## [Unreleased]

### Added
  
- in `topology.v`:
  + global instance `ball_filter`
  + module `regular_topology` with an `Exports` submodule
    * canonicals `pointedType`, `filteredType`, `topologicalType`,
      `uniformType`, `pseudoMetricType`
  + module `numFieldTopology` with an `Exports` submodule
    * many canonicals and coercions
  + global instance `Proper_nbhs'_regular_numFieldType`
- in `normedtype.v`:
  + definitions `ball_`, `pointed_of_zmodule`, `filtered_of_normedZmod`
  + lemmas `ball_norm_center`, `ball_norm_symmetric`, `ball_norm_triangle`
  + definition `pseudoMetric_of_normedDomain`
  + lemma `nbhs_ball_normE`
  + global instances `Proper_nbhs'_numFieldType`, `Proper_nbhs'_realType`
  + module `regular_topology` with an `Exports` submodule
    * canonicals `pseudoMetricNormedZmodType`, `normedModType`.
  + module `numFieldNormedType` with an `Exports` submodule
    * many canonicals and coercions
    * exports `Export numFieldTopology.Exports`
  + canonical `R_regular_completeType`, `R_regular_CompleteNormedModule`
- in `reals.v`:
  + lemmas `Rfloor_lt0`, `floor_lt0`, `ler_floor`, `ceil_gt0`, `ler_ceil`
- in `ereal.v`:
  + lemmas `ereal_ballN`, `le_ereal_ball`, `ereal_ball_ninfty_oversize`,
    `contract_ereal_ball_pinfty`, `expand_ereal_ball_pinfty`,
    `contract_ereal_ball_fin_le`, `contract_ereal_ball_fin_lt`,
    `expand_ereal_ball_fin_lt`, `ball_ereal_ball_fin_lt`, `ball_ereal_ball_fin_le`
- in `classical_sets.v`:
  + notation `[disjoint ... & ..]`
  + lemmas `mkset_nil`, `bigcup_mkset`, `bigcup_nonempty`, `bigcup0`, `bigcup0P`,
    `subset_bigcup_r`, `eqbigcup_r`
- in `ereal.v`:
  + lemmas `adde_undefC`, `real_of_erD`, `fin_num_add_undef`, `addeK`,
    `subeK`, `subee`, `sube_le0`, `lee_sub`
  + lemmas `addeACA`, `muleC`, `mule1`, `mul1e`, `abseN`
  + enable notation `x \is a fin_num`
    * definition `fin_num`, fact `fin_num_key`, lemmas `fin_numE`, `fin_numP`
  + definition `dense` and lemma `denseNE`
- in `measure.v`:
  + lemma `eq_bigcupB_of_bigsetU`
  + definition `caratheodory_measurable`, notation `... .-measurable`
  + lemmas `le_caratheodory_measurable`, `outer_measure_bigcup_lim`,
    `caratheodory_measurable_{set0,setC,setU_le,setU,bigsetU,setI,setD}`
    `disjoint_caratheodoryIU`, `caratheodory_additive`,
    `caratheodory_lim_lee`, `caratheodory_measurable_trivIset_bigcup`,
   `caratheodory_measurable_bigcup`
  + definitions `measurable`, `caratheodory_mixin`, `caratheodory_measurableType`
  + lemmas `caratheodory_measure0`, `caratheodory_measure_ge0`,
    `caratheodory_measure_sigma_additive`,
    defintions `caratheodory_measure_mixin`, `measure_of_outer_measure`,
    lemma `caratheodory_measure_complete`

### Changed

- in `ereal.v`:
  + generalize lemma `lee_sum_nneg_subfset`
- in `sequences.v`:
  + notations `\sum_(i <oo) F i`
  + lemmas `ereal_sum_lim_psum`, `lte_lim`

### Changed
- `topology.v` now imports `reals`
- `normedtype.v` now imports `vector`, `fieldext`, `falgebra`,
  `numFieldTopology.Exports`
- `derive.v` now imports `numFieldNormedType.Exports`
- `sequences.v` now imports `numFieldNormedType.Exports`
- in `ereal.v`:
  + lemmas `nbhs_oo_up_e1`, `nbhs_oo_down_e1`, `nbhs_oo_up_1e`, `nbhs_oo_down_1e`
    `nbhs_fin_out_above`, `nbhs_fin_out_below`, `nbhs_fin_out_above_below`
    `nbhs_fin_inbound`
- in `classical_sets.v`:
  + lemma `subset_bigsetU` generalized

### Renamed

### Removed

### Infrastructure

### Misc
