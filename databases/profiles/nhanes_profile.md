# NHANES — Data Profile

Recommended: Pool 3 cycles (2013-2018) for maximum statistical power.
Source: CDC National Center for Health Statistics
Access: Public download via nhanesA R package (no credentials required)

## 1. Overall Sample Size

**Pooled 3 cycles (2013-2018, RECOMMENDED):**
- ~29,400 total participants
- ~28,061 examined (MEC, RIDSTATR == 2)
- ~13,710 fasting subsample
- Weight adjustment: WTMEC6YR = WTMEC2YR / 3

**Per cycle:**

| Cycle | Suffix | Total Participants | Examined (MEC) | Fasting Subsample |
|-------|--------|--------------------|----------------|-------------------|
| 2013-2014 | _H | ~10,175 | ~9,813 | ~4,825 |
| 2015-2016 | _I | ~9,971 | ~9,544 | ~4,675 |
| 2017-2018 | _J | ~9,254 | ~8,704 | ~4,210 |
| 2017-Mar 2020 (pre-pandemic) | _P | ~15,560 | ~14,862 | ~7,080 |

Note: Exact counts vary slightly by component. Use RIDSTATR == 2 to filter
to participants who completed both interview and MEC examination. Do NOT
pool _P with _J (overlapping time periods).

## 2. Age Distribution (2017-2018, RIDSTATR == 2)

| Age Group | Approx N | % of MEC Sample |
|-----------|----------|-----------------|
| 0-5 | ~1,350 | ~15.5% |
| 6-11 | ~900 | ~10.3% |
| 12-17 | ~800 | ~9.2% |
| 18-39 | ~1,850 | ~21.3% |
| 40-59 | ~1,750 | ~20.1% |
| 60-79 | ~1,700 | ~19.5% |
| 80+ | ~350 | ~4.0% |

NHANES oversamples: Hispanic persons, non-Hispanic Black persons,
non-Hispanic Asian persons, persons aged 80+, and other groups at
increased risk. Survey weights correct for this oversampling.

## 3. Demographics (2017-2018)

### Sex
| Category | Approx N | Weighted % |
|----------|----------|------------|
| Male | ~4,400 | ~48.7% |
| Female | ~4,300 | ~51.3% |

### Race/Ethnicity (RIDRETH3)
| Category | Approx N | Weighted % |
|----------|----------|------------|
| Mexican American | ~1,400 | ~11% |
| Other Hispanic | ~900 | ~7% |
| Non-Hispanic White | ~2,750 | ~62% |
| Non-Hispanic Black | ~2,050 | ~12% |
| Non-Hispanic Asian | ~1,050 | ~6% |
| Other/Multi-Racial | ~550 | ~3% |

Note: Unweighted N reflects oversampling. Weighted % reflects US population.

### Education (adults 20+, DMDEDUC2)
| Level | Approx Weighted % |
|-------|-------------------|
| Less than 9th grade | ~5% |
| 9-11th grade | ~10% |
| High school/GED | ~23% |
| Some college/AA | ~32% |
| College graduate+ | ~31% |

### Income-to-Poverty Ratio (INDFMPIR)
| Range | Approx Weighted % |
|-------|-------------------|
| 0.00-0.99 (below poverty) | ~12% |
| 1.00-1.99 | ~17% |
| 2.00-3.99 | ~28% |
| 4.00-5.00 (capped) | ~43% |
| Missing | ~8% |

## 4. Laboratory Coverage (2017-2018)

### Full MEC Sample (WTMEC2YR)
| Lab Component | Table | Key Variable | Approx N |
|---------------|-------|-------------|----------|
| HbA1c | GHB_J | LBXGH | ~7,300 |
| Total cholesterol | TCHOL_J | LBXTC | ~7,100 |
| HDL cholesterol | HDL_J | LBDHDD | ~7,100 |
| Complete blood count | CBC_J | LBXWBCSI | ~7,400 |
| Biochemistry panel | BIOPRO_J | LBXSCR | ~7,100 |
| hs-CRP | HSCRP_J | LBXHSCRP | ~7,300 |
| Cotinine | COT_J | LBXCOT | ~7,300 |
| Urine albumin/creatinine | ALB_CR_J | URDACT | ~7,400 |
| Ferritin | FERTIN_J | LBXFER | ~7,000 |

### Fasting Subsample (WTSAF2YR — morning session only)
| Lab Component | Table | Key Variable | Approx N |
|---------------|-------|-------------|----------|
| Fasting glucose | GLU_J | LBXGLU | ~3,400 |
| Triglycerides | TRIGLY_J | LBXTR | ~3,400 |
| LDL cholesterol (calc) | TRIGLY_J | LBDLDL | ~3,100 |
| Insulin | INS_J | LBXIN | ~3,400 |

## 5. Examination Coverage (2017-2018)

| Component | Table | Approx N |
|-----------|-------|----------|
| Blood pressure (oscillometric) | BPXO_J | ~7,600 |
| Body measures (BMI, waist) | BMX_J | ~8,100 |

## 6. Key Questionnaire Coverage (2017-2018, adults 20+)

| Component | Table | Key Variable | Approx N (adults) |
|-----------|-------|--------------|--------------------|
| Smoking history | SMQ_J | SMQ020 | ~5,500 |
| Alcohol use | ALQ_J | ALQ121 | ~5,500 |
| Diabetes history | DIQ_J | DIQ010 | ~5,500 |
| Medical conditions | MCQ_J | MCQ160B-F | ~5,500 |
| BP/cholesterol Qs | BPQ_J | BPQ020 | ~5,500 |
| Depression (PHQ-9) | DPQ_J | DPQ010 | ~5,100 |
| Physical activity | PAQ_J | PAQ605 | ~5,500 |
| Rx medications (30-day) | RXQ_RX_J | RXDUSE | ~5,500 |
| Kidney conditions | KIQ_U_J | KIQ022 | ~5,500 |
| Cardiovascular | CDQ_J | CDQ001 | ~5,500 |
| Sleep | SLQ_J | SLD012 | ~5,500 |
| Health insurance | HIQ_J | HIQ011 | ~8,500 |
| Diet behavior | DBQ_J | DBD895 | ~5,500 |

## 7. Prescription Medications (RXQ_RX_J)

- ~5,500 adults interviewed; ~3,800 report taking ≥1 Rx medication
- Multiple rows per person (one per medication)
- ~17,000 total medication records across all participants
- Drug codes are Lexicon Plus (not RxNorm). Map via RXDDRUG (generic name).
- ICD-10-CM reason-for-use codes available (RXDRSC1-3)
- Top drug classes: antihypertensives, statins, metformin, proton pump inhibitors, SSRIs, thyroid hormones

## 8. Mortality Linkage

Available from NCHS Public-Use Linked Mortality Files:
- Separate download (not in nhanesA): https://www.cdc.gov/nchs/data-linkage/mortality-public.htm
- Follow-up through December 31, 2019 for all cycles
- Maximum follow-up by cycle: ~6 years (2013-2014), ~4 years (2015-2016), ~2 years (2017-2018)
- **Pooled 3-cycle advantage**: Earlier cycles contribute longer follow-up and more
  mortality events, substantially increasing statistical power for survival analyses
- Mortality rate: ~2-3% per cycle overall (higher in elderly subgroups); pooling
  triples the number of events
- Cause of death available as recode categories (heart disease, cancer, diabetes, etc.)
- Includes person-months of follow-up for survival analysis (PERMTH_INT, PERMTH_EXM)

## 9. Known Limitations for Target Trial Emulation

1. **Cross-sectional design**: Most exposure/outcome pairs measured simultaneously.
   Only mortality provides true prospective follow-up.
2. **No longitudinal clinical data**: No repeat visits, lab trends, or medication
   changes over time within NHANES.
3. **Self-reported medications**: 30-day recall, not pharmacy claims. Subject to
   recall bias and underreporting.
4. **Small sample per cycle**: ~8,700 examined participants per cycle. Pool
   3 cycles (~28,000 participants) for adequate power in most analyses.
5. **Age top-coding**: Ages ≥80 coded as 80. Limits geriatric subgroup analyses.
6. **No inpatient/claims data**: Cannot identify hospitalizations, procedures, or
   healthcare utilization details beyond self-report.
