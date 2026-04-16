# Review: Protocol 01 — DOAC vs Warfarin and All-Cause Mortality in CKD (NHANES)

**Reviewer verdict: REVISE**

**Summary:** This is a well-constructed prevalent-user TTE protocol that is
refreshingly honest about its limitations. The target trial specification is
complete, the study design category is correct (Category A), and the
discussion of prevalent-user bias is thorough. However, the eGFR calculation
is missing the female sex multiplier from the CKD-EPI 2021 equation, the
income-to-poverty ratio is omitted from the PS model despite being a strong
confounder of DOAC vs warfarin choice (given the cost differential during
2013-2018), and there is a protocol-code discrepancy regarding MI history.
These are fixable issues; the protocol does not need to be rewritten.

---

## Detailed Findings

### 1. Target Trial Specification (7/7 elements present)

All seven elements are present and correctly specified:

| Element | Status | Notes |
|---------|--------|-------|
| Eligibility | OK | Operationalized with RIDSTATR, RXDDRUG, eGFR, ELIGSTAT |
| Treatment | OK | DOAC vs warfarin from RXDDRUG; dual users excluded |
| Assignment | OK | IPW; honest about non-randomization |
| Time zero | OK | MEC exam date; explicitly states "NOT treatment initiation" |
| Outcome | OK | NDI-linked all-cause mortality via MORTSTAT/PERMTH_EXM |
| Estimand | OK | ATE, appropriate for the prevalent-user framing |
| Causal contrast | OK | Survey-weighted IPW-adjusted HR |

**Time zero assessment:** No immortal time bias. Time zero is the exam date,
and follow-up begins immediately. There is no grace period or look-ahead
bias because treatment is determined cross-sectionally at the single visit.

### 2. eGFR Calculation — REVISE

**Issue:** The CKD-EPI 2021 race-free equation (Inker et al., NEJM 2021)
includes a sex-specific multiplier of **1.012 for females**:

```
eGFR = 142 × min(Scr/κ, 1)^α × max(Scr/κ, 1)^(-1.200) × 0.9938^Age × [1.012 if female]
```

Both the protocol text (Section 3) and the R code (lines 186-189) omit
this multiplier. The code computes:

```r
eGFR = 142 * pmin(LBXSCR / kappa, 1)^alpha *
             pmax(LBXSCR / kappa, 1)^(-1.200) *
             0.9938^RIDAGEYR
```

**Impact:** Female eGFR values are underestimated by ~1.2%. For participants
near the eGFR = 60 boundary, this could affect eligibility classification.
With a cohort of ~130 participants, even 1-2 misclassifications matter.

**Fix:** Add `× if_else(female == 1, 1.012, 1)` to the eGFR formula in both
the R code and the protocol text.

### 3. Income Omitted from PS Model — REVISE

**Issue:** The income-to-poverty ratio (INDFMPIR) is listed in the variable
mapping table (Section 3) but excluded from the PS model (Section 4.2). The
protocol justifies this by claiming income is "Not strong confounder of drug
class choice within anticoagulant users."

This justification is weak. During the study period (2013-2018), DOACs were
under patent and cost $400-500+/month vs. pennies for generic warfarin.
Insurance coverage and out-of-pocket costs are strong determinants of DOAC vs
warfarin prescribing, and income-to-poverty ratio is a proxy for this. Omitting
income introduces confounding by socioeconomic status — wealthier patients get
DOACs and independently have lower mortality.

**Fix:** Add INDFMPIR to `ps_candidates` in the R code with appropriate
handling for missing values. Given the small sample, consider including it as
a continuous variable (capped at 5.0 per NHANES design) rather than
categorizing it.

### 4. Protocol-Code Discrepancy: MI History — REVISE (minor)

**Issue:** The R code includes `mi_hx` (MCQ160E — prior myocardial infarction)
in the PS model candidates (line 245, 329), but MI is not listed in the
protocol's confounder table (Section 4.2). The protocol mentions CHF (MCQ160B),
CHD (MCQ160C), and stroke (MCQ160F) but not MI separately.

Including MI is defensible and arguably correct, but the protocol document
must match the code.

**Fix:** Add "Prior myocardial infarction" to the confounder table in Section
4.2 with rationale (e.g., "MI history influences anticoagulation intensity and
is a strong mortality predictor").

### 5. Table 1 Uses Unweighted Descriptives — Minor

**Issue:** The code creates a survey design object `tbl1_svy` (lines 510-513)
but never uses it. Table 1 (lines 515-543) uses unweighted `tbl_summary()`
rather than `tbl_svysummary()`. The survey design object was apparently
created with the intent to use it but was not passed to the summary function.

**Impact:** Low. Many NHANES publications present unweighted sample
characteristics in Table 1. However, since the intent appears to have been
weighted descriptives, this is likely an oversight.

**Fix:** Either (a) use `tbl_svysummary(tbl1_svy, ...)` for weighted
estimates, or (b) remove the unused `tbl1_svy` object and document that
Table 1 presents unweighted sample characteristics.

### 6. KM Curves Not Survey-Weighted — Minor

**Issue:** Lines 586-599 use `survfit()` with `weights = combined_wt` rather
than `svykm()` from the survey package. The weighted `survfit()` does not
account for stratification and clustering, so confidence intervals on the KM
curves will be incorrect.

**Impact:** Low — this is a presentation issue. The primary analysis
correctly uses `svycoxph()` with the full survey design. KM curves are
illustrative.

**Fix:** Add a comment noting that KM curves use approximate weighting and
that formal inference is from the `svycoxph()` model. Alternatively, use
`survey::svykm()` if survminer compatibility allows.

### 7. E-value rare Outcome Assumption — Note

The E-value computation uses `rare = TRUE` (line 444), which approximates
the HR as a risk ratio under the rare disease assumption. In a CKD cohort
with mean age ~70-75 and up to 6 years of mortality follow-up, the event
rate may exceed the 10% threshold where this approximation breaks down.

**Fix:** After computing the mortality rate, conditionally set `rare` based
on whether events/N < 0.10. Or use `rare = FALSE` as a sensitivity
analysis.

### 8. Effective Sample Size Concern — Note (not a REVISE item)

With ~35-45 DOAC users and 11+ PS model covariates, the events-per-variable
(EPV) ratio will be very low. The dynamic PS formula construction (dropping
zero-variance predictors) partially mitigates this, but extreme PS weights
and model instability are likely. The protocol acknowledges the small sample
(Section 6.4) but could explicitly discuss EPV.

---

## NHANES Conventions Compliance

| Convention | Status | Notes |
|-----------|--------|-------|
| Survey design (svydesign) | PASS | Correct use of SDMVPSU, SDMVSTRA, weights, nest=TRUE |
| Weight adjustment (WTMEC2YR / 3) | PASS | Line 287: `WTMEC6YR = WTMEC2YR / 3` |
| 3-cycle pooling (2013-2018) | PASS | H/I/J suffixes, cycle column for disambiguation |
| SEQN + cycle composite key | PASS | All joins use `by = c("SEQN", "cycle")` |
| Missing data codes (7/9 recoding) | PASS | Lines 229-238: na_if for questionnaire variables |
| quasibinomial for logistic | PASS | WeightIt handles this internally |
| Category A TTE labeling | PASS | Title includes "Prevalent-User Design" |
| Prevalent-user bias discussion | PASS | Three forms discussed in detail (Section 6.1) |
| TARGET compliance table | PASS | Section 6.7 with honest assessment |
| Age top-coding documented | PASS | Section 6.5 |
| UPPERCASE NHANES variables | PASS | All NHANES variables in uppercase |
| Fasting subsample weights | N/A | No fasting labs used |
| No _P cycle pooling | PASS | Only _H, _I, _J used |
| Multifactorial confounder model | PASS | DAG-justified, 11+ confounders |
| Research quality (not single-factor) | PASS | Multiple confounders with domain rationale |

---

## What Was Done Well

1. **Exceptionally honest limitations section.** The three-part prevalent-user
   bias discussion (Section 6.1) is more thorough than most published NHANES
   studies. The explicit statement "This is NOT a new-user design" in the
   clinical context is exactly right.

2. **Correct study design categorization.** Properly identified as Category A
   TTE with prevalent-user caveats, per NHANES conventions.

3. **No AF ascertainment note.** Many NHANES anticoagulation studies ignore the
   fact that NHANES has no AF diagnosis variable. This protocol explicitly
   addresses it (Section 2, "Note on AF Ascertainment," and Section 6.2).

4. **Dynamic PS formula construction.** The code handles edge cases (zero-variance
   predictors, single-level factors) that would crash a static model with this
   small sample. Good defensive coding.

5. **Proper mortality file handling.** Fixed-width parsing with correct column
   positions and error handling per cycle.

6. **Publication outputs in tryCatch.** Lines 498-636 are wrapped in a
   non-fatal tryCatch, so figure generation failures don't crash the analysis.

7. **Guard rails for empty cohorts.** Lines 305-322 check for zero patients
   and single treatment arms before proceeding.

8. **E-value in tryCatch.** Lines 443-456 handle the case where the CI crosses
   the null (E-value = 1 by definition).

---

## Required Changes for REVISE

1. **[MUST FIX]** Add the 1.012 female multiplier to the eGFR calculation in
   both the protocol text and R code.
2. **[MUST FIX]** Add INDFMPIR (income-to-poverty ratio) to the PS model with
   justification for its role as a confounder of DOAC vs warfarin choice.
3. **[MUST FIX]** Add MI history (MCQ160E) to the protocol's confounder table
   to match the R code.
4. **[SHOULD FIX]** Either use `tbl_svysummary()` for Table 1 or remove the
   unused `tbl1_svy` survey design object.
5. **[SHOULD FIX]** Conditionally set `rare` in E-value based on observed
   event rate.

---

**Verdict: REVISE** — The protocol is methodologically sound and the limitations
are well-characterized. The three MUST FIX items are straightforward corrections
that do not require rethinking the study design. Once addressed, this protocol
should be ACCEPT.
