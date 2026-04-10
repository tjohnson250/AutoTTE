# NHANES Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make NHANES a first-class AutoTTE data source with schema, profile, conventions, and YAML config so agents can design and execute target trial emulation protocols against NHANES data.

**Architecture:** Enrich the existing NHANES entry in `PUBLIC_DATASETS` (datasource_server.py) with paths to new schema/profile/conventions files. Create a separate YAML config for R executor online mode. No new code logic — just content files and three dictionary keys.

**Tech Stack:** Python (datasource server), R (nhanesA, DuckDB, survey), YAML, Markdown, pytest

**Spec:** `docs/superpowers/specs/2026-04-10-nhanes-integration-design.md`

---

### Task 1: Wire NHANES schema/profile/conventions into datasource server

**Files:**
- Modify: `tools/datasource_server.py:62-78` (PUBLIC_DATASETS NHANES entry)
- Modify: `tests/test_datasource_server.py` (add test)

- [ ] **Step 1: Write the failing test**

Add to `tests/test_datasource_server.py`:

```python
def test_nhanes_has_schema_profile_conventions():
    """NHANES public dataset entry must have paths to support files."""
    nhanes = get_details_by_id("nhanes", list(PUBLIC_DATASETS))
    assert nhanes is not None
    assert "schema_dump" in nhanes, "NHANES missing schema_dump path"
    assert "data_profile" in nhanes, "NHANES missing data_profile path"
    assert "conventions" in nhanes, "NHANES missing conventions path"
    # Paths should be non-empty strings
    assert nhanes["schema_dump"].endswith(".txt")
    assert nhanes["data_profile"].endswith(".md")
    assert nhanes["conventions"].endswith(".md")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/toddjohnson/Documents/GitHub/AutoTTE && python -m pytest tests/test_datasource_server.py::test_nhanes_has_schema_profile_conventions -v`

Expected: FAIL with `AssertionError: NHANES missing schema_dump path`

- [ ] **Step 3: Add paths to the NHANES PUBLIC_DATASETS entry**

In `tools/datasource_server.py`, modify the NHANES dict (lines 62-78) to add three keys after the `"url"` key:

```python
    {
        "id": "nhanes",
        "type": "public",
        "name": "NHANES",
        "description": "National Health and Nutrition Examination Survey. ~5k participants per 2-year cycle, nationally representative.",
        "domain": "population_health",
        "access": "Public download, no restrictions",
        "variables": [
            "demographics", "blood_pressure", "cholesterol", "hba1c",
            "bmi", "smoking", "medications_self_report", "diet",
            "physical_activity", "mortality_linked", "kidney_function",
            "liver_function", "mental_health",
        ],
        "strengths": ["Nationally representative", "Physical exam + lab data", "Mortality follow-up linkage"],
        "limitations": ["Cross-sectional (no longitudinal follow-up except mortality)", "Self-reported medications", "Small sample per cycle"],
        "url": "https://www.cdc.gov/nchs/nhanes/",
        "schema_dump": "databases/schemas/nhanes_schema.txt",
        "data_profile": "databases/profiles/nhanes_profile.md",
        "conventions": "databases/conventions/nhanes_conventions.md",
    },
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/toddjohnson/Documents/GitHub/AutoTTE && python -m pytest tests/test_datasource_server.py::test_nhanes_has_schema_profile_conventions -v`

Expected: PASS

- [ ] **Step 5: Run full test suite**

Run: `cd /Users/toddjohnson/Documents/GitHub/AutoTTE && python -m pytest tests/test_datasource_server.py -v`

Expected: All tests PASS (existing tests unaffected)

- [ ] **Step 6: Commit**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
git add tools/datasource_server.py tests/test_datasource_server.py
git commit -m "Wire NHANES schema/profile/conventions into datasource server"
```

---

### Task 2: Create NHANES schema file

**Files:**
- Create: `databases/schemas/nhanes_schema.txt`

- [ ] **Step 1: Create the schema file**

Write `databases/schemas/nhanes_schema.txt` with the following content. This documents ~25 key NHANES components for the 2017-2018 cycle (suffix _J). Each table lists the nhanesA table name, description, and key columns with types.

```
NHANES Schema Reference — 2017-2018 Cycle (suffix _J)
======================================================

Join key for all tables: SEQN (Respondent Sequence Number, INTEGER)
Load via nhanesA: nhanes('TABLE_NAME')
Full codebook: nhanesCodebook('TABLE_NAME')

Note: This lists KEY variables per component. Each table has additional
variables not listed here. Use nhanesCodebook() for the complete listing.

======================================================================
DEMOGRAPHICS
======================================================================

TABLE: DEMO_J (Demographics)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  RIDSTATR        INTEGER   Interview/exam status (1=Interview only, 2=Both)
  RIAGENDR        INTEGER   Gender (1=Male, 2=Female)
  RIDAGEYR        INTEGER   Age in years at screening (0-80, top-coded at 80)
  RIDRETH1        INTEGER   Race/Hispanic origin (1=Mexican American, 2=Other Hispanic, 3=NH White, 4=NH Black, 5=Other/Multi)
  RIDRETH3        INTEGER   Race/Hispanic origin w/ NH Asian (1=Mexican American, 2=Other Hispanic, 3=NH White, 4=NH Black, 6=NH Asian, 7=Other/Multi)
  DMDBORN4        INTEGER   Country of birth (1=Born in US, 2=Other)
  DMDEDUC2        INTEGER   Education level - adults 20+ (1=<9th grade, 2=9-11th, 3=HS/GED, 4=Some college/AA, 5=College+)
  DMDMARTZ        INTEGER   Marital status (1=Married/Living w/ partner, 2=Widowed/Divorced/Separated, 3=Never married, 77=Refused, 99=DK)
  INDHHIN2        INTEGER   Annual household income (1-10 range codes, 14=$75k-$100k, 15=$100k+, 77=Refused, 99=DK)
  INDFMPIR        DOUBLE    Ratio of family income to poverty (0.00-5.00, capped at 5)
  RIDEXMON        INTEGER   Six-month time period (1=Nov-Apr, 2=May-Oct)
  WTINT2YR        DOUBLE    Full sample 2-year interview weight
  WTMEC2YR        DOUBLE    Full sample 2-year MEC exam weight
  SDMVPSU         INTEGER   Masked variance pseudo-PSU
  SDMVSTRA        INTEGER   Masked variance pseudo-stratum

======================================================================
EXAMINATION
======================================================================

TABLE: BPXO_J (Blood Pressure - Oscillometric)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  BPXOSY1         INTEGER   Systolic BP - 1st reading (mmHg)
  BPXODI1         INTEGER   Diastolic BP - 1st reading (mmHg)
  BPXOSY2         INTEGER   Systolic BP - 2nd reading (mmHg)
  BPXODI2         INTEGER   Diastolic BP - 2nd reading (mmHg)
  BPXOSY3         INTEGER   Systolic BP - 3rd reading (mmHg)
  BPXODI3         INTEGER   Diastolic BP - 3rd reading (mmHg)
  BPXOPLS1        INTEGER   Pulse - 1st reading (bpm)
  BPXOPLS2        INTEGER   Pulse - 2nd reading (bpm)
  BPXOPLS3        INTEGER   Pulse - 3rd reading (bpm)

TABLE: BMX_J (Body Measures)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  BMXWT           DOUBLE    Weight (kg)
  BMXHT           DOUBLE    Standing height (cm)
  BMXBMI          DOUBLE    Body mass index (kg/m^2)
  BMXWAIST        DOUBLE    Waist circumference (cm)
  BMXHIP          DOUBLE    Hip circumference (cm)
  BMXARML         DOUBLE    Upper arm length (cm)
  BMXARMC         DOUBLE    Arm circumference (cm)

======================================================================
LABORATORY
======================================================================

TABLE: GHB_J (Glycohemoglobin / HbA1c)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXGH           DOUBLE    Glycohemoglobin (%)

TABLE: TCHOL_J (Total Cholesterol)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXTC           DOUBLE    Total cholesterol (mg/dL)

TABLE: HDL_J (HDL Cholesterol)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBDHDD          DOUBLE    Direct HDL-cholesterol (mg/dL)

TABLE: TRIGLY_J (Triglycerides) [FASTING SUBSAMPLE]
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXTR           DOUBLE    Triglycerides (mg/dL)
  LBDLDL          DOUBLE    LDL-cholesterol (Friedewald, mg/dL)
  WTSAF2YR        DOUBLE    Fasting subsample 2-year MEC weight

TABLE: GLU_J (Plasma Fasting Glucose) [FASTING SUBSAMPLE]
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXGLU          DOUBLE    Fasting glucose (mg/dL)
  WTSAF2YR        DOUBLE    Fasting subsample 2-year MEC weight

TABLE: INS_J (Insulin) [FASTING SUBSAMPLE]
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXIN           DOUBLE    Insulin (uU/mL)
  WTSAF2YR        DOUBLE    Fasting subsample 2-year MEC weight

TABLE: BIOPRO_J (Standard Biochemistry Profile)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXSATSI        DOUBLE    Alanine aminotransferase ALT (U/L)
  LBXSASSI        DOUBLE    Aspartate aminotransferase AST (U/L)
  LBXSAPSI        DOUBLE    Alkaline phosphatase ALP (U/L)
  LBXSAL          DOUBLE    Albumin (g/dL)
  LBXSBU          DOUBLE    Blood urea nitrogen (mg/dL)
  LBXSCR          DOUBLE    Creatinine (mg/dL)
  LBXSGL          DOUBLE    Glucose (mg/dL) — NOT fasting; use GLU_J for fasting
  LBXSTP          DOUBLE    Total protein (g/dL)
  LBXSTB          DOUBLE    Total bilirubin (mg/dL)
  LBXSUA          DOUBLE    Uric acid (mg/dL)
  LBXSPH          DOUBLE    Phosphorus (mg/dL)
  LBXSC3SI        DOUBLE    Bicarbonate (mmol/L)
  LBXSNASI        DOUBLE    Sodium (mmol/L)
  LBXSKSI         DOUBLE    Potassium (mmol/L)
  LBXSCLSI        DOUBLE    Chloride (mmol/L)
  LBXSGB          DOUBLE    Globulin (g/dL)
  LBXSOSSI        DOUBLE    Osmolality (mmol/Kg)
  LBXSCA          DOUBLE    Total calcium (mg/dL)
  LBXSCH          DOUBLE    Cholesterol (mg/dL) — same as TCHOL
  LBXSGTSI        DOUBLE    GGT (U/L)
  LBXSIR          DOUBLE    Iron (ug/dL)
  LBXSLDSI        DOUBLE    LDH (U/L)

TABLE: CBC_J (Complete Blood Count)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXWBCSI        DOUBLE    White blood cell count (1000 cells/uL)
  LBXRBCSI        DOUBLE    Red blood cell count (million cells/uL)
  LBXHGB          DOUBLE    Hemoglobin (g/dL)
  LBXHCT          DOUBLE    Hematocrit (%)
  LBXMCVSI        DOUBLE    Mean cell volume (fL)
  LBXPLTSI        DOUBLE    Platelet count (1000 cells/uL)
  LBXMPSI         DOUBLE    Mean platelet volume (fL)
  LBXNEPCT        DOUBLE    Segmented neutrophils percent (%)
  LBXLYPCT        DOUBLE    Lymphocyte percent (%)
  LBXMOPCT        DOUBLE    Monocyte percent (%)
  LBXEOPCT        DOUBLE    Eosinophil percent (%)
  LBXBAPCT        DOUBLE    Basophil percent (%)

TABLE: ALB_CR_J (Albumin & Creatinine, Urine)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  URXUMA          DOUBLE    Albumin, urine (ug/mL)
  URXUCR          DOUBLE    Creatinine, urine (mg/dL)
  URDACT          DOUBLE    Albumin-creatinine ratio (mg/g)

TABLE: HSCRP_J (High-Sensitivity C-Reactive Protein)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXHSCRP        DOUBLE    hs-CRP (mg/L)

TABLE: COT_J (Cotinine - Smoking Biomarker)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXCOT          DOUBLE    Serum cotinine (ng/mL)
  LBXHCO          DOUBLE    Serum hydroxycotinine (ng/mL)

TABLE: FERTIN_J (Ferritin)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXFER          DOUBLE    Ferritin (ng/mL)

TABLE: FETIB_J (Transferrin Receptor)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  LBXTFR          DOUBLE    Transferrin receptor (mg/L)

======================================================================
QUESTIONNAIRE
======================================================================

TABLE: SMQ_J (Smoking - Cigarette Use)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  SMQ020          INTEGER   Smoked at least 100 cigarettes in life (1=Yes, 2=No)
  SMQ040          INTEGER   Do you now smoke cigarettes (1=Every day, 2=Some days, 3=Not at all)
  SMD641          INTEGER   # cigarettes smoked per day (when smoking every day)
  SMD650          INTEGER   Avg # cigarettes per day during past 30 days

TABLE: ALQ_J (Alcohol Use)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  ALQ111          INTEGER   Ever had a drink of alcohol (1=Yes, 2=No)
  ALQ121          INTEGER   Past 12 mo how often drink (0=Never, 1-10 frequency codes)
  ALQ130          INTEGER   Avg # alcoholic drinks/day past 12 months
  ALQ142          INTEGER   # days have 4/5+ drinks past 12 mo

TABLE: BPQ_J (Blood Pressure & Cholesterol)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  BPQ020          INTEGER   Ever told you had high BP (1=Yes, 2=No)
  BPQ040A         INTEGER   Taking prescription for hypertension (1=Yes, 2=No)
  BPQ080          INTEGER   Doctor told you - high cholesterol (1=Yes, 2=No)
  BPQ090D         INTEGER   Told to take prescription for cholesterol (1=Yes, 2=No)
  BPQ100D         INTEGER   Now taking prescribed medicine (1=Yes, 2=No)

TABLE: DIQ_J (Diabetes)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  DIQ010          INTEGER   Doctor told you have diabetes (1=Yes, 2=No, 3=Borderline)
  DIQ050          INTEGER   Taking insulin now (1=Yes, 2=No)
  DIQ070          INTEGER   Taking diabetic pills to lower blood sugar (1=Yes, 2=No)
  DIQ160          INTEGER   Ever told you have prediabetes (1=Yes, 2=No)
  DIQ170          INTEGER   Ever told at risk for diabetes (1=Yes, 2=No)
  DIQ175A-G       INTEGER   Family history type flags

TABLE: MCQ_J (Medical Conditions)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  MCQ160A         INTEGER   Doctor ever said you had arthritis (1=Yes, 2=No)
  MCQ160B         INTEGER   Ever told had congestive heart failure (1=Yes, 2=No)
  MCQ160C         INTEGER   Ever told you had coronary heart disease (1=Yes, 2=No)
  MCQ160D         INTEGER   Ever told you had angina/angina pectoris (1=Yes, 2=No)
  MCQ160E         INTEGER   Ever told you had heart attack (1=Yes, 2=No)
  MCQ160F         INTEGER   Ever told you had a stroke (1=Yes, 2=No)
  MCQ160L         INTEGER   Ever told you had any liver condition (1=Yes, 2=No)
  MCQ160O         INTEGER   Ever told you had COPD (1=Yes, 2=No)
  MCQ220          INTEGER   Ever told you had cancer/malignancy (1=Yes, 2=No)
  MCQ160M         INTEGER   Ever told you had thyroid problem (1=Yes, 2=No)
  MCQ160N         INTEGER   Ever told you had gout (1=Yes, 2=No)
  MCQ160P         INTEGER   Ever told you had COPD, emphysema, ChB (1=Yes, 2=No)

TABLE: PAQ_J (Physical Activity)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  PAQ605          INTEGER   Vigorous work activity (1=Yes, 2=No)
  PAQ620          INTEGER   Moderate work activity (1=Yes, 2=No)
  PAQ635          INTEGER   Walk or bicycle (1=Yes, 2=No)
  PAQ650          INTEGER   Vigorous recreational activities (1=Yes, 2=No)
  PAQ665          INTEGER   Moderate recreational activities (1=Yes, 2=No)
  PAD680          INTEGER   Minutes sedentary activity per day

TABLE: RXQ_RX_J (Prescription Medications - 30 Day)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  RXDUSE          INTEGER   Taken prescription medicine past month (1=Yes, 2=No)
  RXDDRUG         VARCHAR   Generic drug name
  RXDDRGID        VARCHAR   Generic drug code (Lexicon Plus)
  RXDRSC1         INTEGER   ICD-10-CM code 1 (reason for use)
  RXDRSC2         INTEGER   ICD-10-CM code 2 (reason for use)
  RXDRSC3         INTEGER   ICD-10-CM code 3 (reason for use)
  RXDCOUNT        INTEGER   Number of prescription medicines taken
  Note: Multiple rows per participant (one per medication). Join on SEQN.

TABLE: DPQ_J (Mental Health - Depression Screener PHQ-9)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  DPQ010          INTEGER   Little interest in doing things (0=Not at all, 1=Several days, 2=More than half, 3=Nearly every day)
  DPQ020          INTEGER   Feeling down, depressed, hopeless (0-3)
  DPQ030          INTEGER   Trouble sleeping or sleeping too much (0-3)
  DPQ040          INTEGER   Feeling tired or having little energy (0-3)
  DPQ050          INTEGER   Poor appetite or overeating (0-3)
  DPQ060          INTEGER   Feeling bad about yourself (0-3)
  DPQ070          INTEGER   Trouble concentrating (0-3)
  DPQ080          INTEGER   Moving/speaking slowly or being fidgety (0-3)
  DPQ090          INTEGER   Thoughts of self-harm (0-3)
  DPQ100          INTEGER   Difficulty these problems have caused (0-3)
  Note: PHQ-9 total score = sum of DPQ010-DPQ090 (range 0-27).

TABLE: KIQ_U_J (Kidney Conditions - Urology)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  KIQ022          INTEGER   Ever told you had weak/failing kidneys (1=Yes, 2=No)
  KIQ025          INTEGER   Received dialysis in past 12 months (1=Yes, 2=No)
  KIQ005          INTEGER   How often have urinary leakage (1-5 scale)

TABLE: CDQ_J (Cardiovascular Health)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  CDQ001          INTEGER   Get pain/discomfort in chest on exertion (1=Yes, 2=No)
  CDQ002          INTEGER   Short of breath on stairs/incline (1=Yes, 2=No)
  CDQ004          INTEGER   Get chest pain walking on level (1=Yes, 2=No)
  CDQ008          INTEGER   Severe chest pain lasting 30+ min (1=Yes, 2=No)
  CDQ010          INTEGER   Shortness of breath lying down at night (1=Yes, 2=No)

TABLE: SLQ_J (Sleep Disorders)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  SLD012          DOUBLE    Sleep hours - weekdays/workdays
  SLD013          DOUBLE    Sleep hours - weekends
  SLQ050          INTEGER   Ever told doctor trouble sleeping (1=Yes, 2=No)
  SLQ120          INTEGER   How often feel overly sleepy during day (0-4 scale)

TABLE: HIQ_J (Health Insurance)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  HIQ011          INTEGER   Covered by health insurance (1=Yes, 2=No)
  HIQ031A         INTEGER   Covered by private insurance (1=Yes)
  HIQ031B         INTEGER   Covered by Medicare (1=Yes)
  HIQ031D         INTEGER   Covered by Medicaid/CHIP (1=Yes)
  HIQ031AA        INTEGER   No coverage (1=Yes)

TABLE: HUQ_J (Hospital Utilization & Access to Care)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  HUQ010          INTEGER   General health condition (1=Excellent, 2=Very good, 3=Good, 4=Fair, 5=Poor)
  HUQ020          INTEGER   Health now compared to 1 yr ago (1=Better, 2=Same, 3=Worse)
  HUQ030          INTEGER   Routine place to go for healthcare (1=Clinic, 2=Dr office, 3=ER, etc.)
  HUQ051          INTEGER   # times receive healthcare over past year (0=None, 1=1, 2=2-3, etc.)
  HUQ071          INTEGER   Overnight hospital patient in past year (1=Yes, 2=No)

======================================================================
DIETARY
======================================================================

TABLE: DR1TOT_J (Dietary Interview - Total Nutrient Intakes, Day 1)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  DR1TKCAL        DOUBLE    Energy (kcal)
  DR1TPROT        DOUBLE    Protein (gm)
  DR1TCARB        DOUBLE    Carbohydrate (gm)
  DR1TTFAT        DOUBLE    Total fat (gm)
  DR1TSFAT        DOUBLE    Total saturated fatty acids (gm)
  DR1TFIBE        DOUBLE    Dietary fiber (gm)
  DR1TSUGR        DOUBLE    Total sugars (gm)
  DR1TSODI        DOUBLE    Sodium (mg)
  DR1TALCO        DOUBLE    Alcohol (gm)
  DR1TCAFF        DOUBLE    Caffeine (mg)
  WTDRD1          DOUBLE    Dietary day 1 sample weight

TABLE: DR2TOT_J (Dietary Interview - Total Nutrient Intakes, Day 2)
  Same structure as DR1TOT_J with DR2 prefix. Use WTDR2D for day 2 weight.

TABLE: DBQ_J (Diet Behavior & Nutrition)
  Variable        Type      Description
  SEQN            INTEGER   Respondent sequence number
  DBD895          INTEGER   # meals not home prepared past 7 days
  DBD900          INTEGER   # meals from fast food past 7 days
  DBD905          INTEGER   # ready-to-eat foods past 30 days
  DBD910          INTEGER   # frozen meals/pizza past 30 days

======================================================================
MORTALITY (Separate from nhanesA — download from NCHS)
======================================================================

TABLE: NHANES_2017_2018_MORT_2019_PUBLIC (Linked Mortality)
  Variable              Type      Description
  SEQN                  INTEGER   Respondent sequence number
  ELIGSTAT              INTEGER   Eligibility status for mortality follow-up (1=Eligible, 2=Under age 18, 3=Ineligible)
  MORTSTAT              INTEGER   Final mortality status (0=Assumed alive, 1=Assumed deceased)
  UCOD_LEADING          VARCHAR   Underlying cause of death (recode)
  DIABETES              INTEGER   Diabetes flag (0=No, 1=Yes)
  HYPERTEN              INTEGER   Hypertension flag (0=No, 1=Yes)
  PERMTH_INT            INTEGER   Person-months of follow-up from interview
  PERMTH_EXM            INTEGER   Person-months of follow-up from MEC exam
  Note: Download from https://www.cdc.gov/nchs/data-linkage/mortality-public.htm
  Load as CSV. Merge on SEQN.
```

- [ ] **Step 2: Verify file is non-empty and well-formed**

Run: `wc -l databases/schemas/nhanes_schema.txt && head -3 databases/schemas/nhanes_schema.txt`

Expected: ~300+ lines, starts with "NHANES Schema Reference"

- [ ] **Step 3: Commit**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
git add databases/schemas/nhanes_schema.txt
git commit -m "Add NHANES schema reference for 2017-2018 cycle"
```

---

### Task 3: Create NHANES data profile

**Files:**
- Create: `databases/profiles/nhanes_profile.md`

- [ ] **Step 1: Create the profile file**

Write `databases/profiles/nhanes_profile.md`:

```markdown
# NHANES — Data Profile

Default cycle: 2017-2018 (suffix _J)
Source: CDC National Center for Health Statistics
Access: Public download via nhanesA R package (no credentials required)

## 1. Overall Sample Size

| Cycle | Suffix | Total Participants | Examined (MEC) | Fasting Subsample |
|-------|--------|--------------------|----------------|-------------------|
| 2013-2014 | _H | ~10,175 | ~9,813 | ~4,825 |
| 2015-2016 | _I | ~9,971 | ~9,544 | ~4,675 |
| 2017-2018 | _J | ~9,254 | ~8,704 | ~4,210 |
| 2017-Mar 2020 (pre-pandemic) | _P | ~15,560 | ~14,862 | ~7,080 |

Note: Exact counts vary slightly by component. Use RIDSTATR == 2 to filter
to participants who completed both interview and MEC examination.

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
- For 2017-2018 cycle: follow-up through December 31, 2019
- ~2-3 year maximum follow-up (short due to recent cycle)
- Mortality rate: ~2-3% overall (higher in elderly subgroups)
- Cause of death available as recode categories (heart disease, cancer, diabetes, etc.)
- Includes person-months of follow-up for survival analysis (PERMTH_INT, PERMTH_EXM)

## 9. Known Limitations for Target Trial Emulation

1. **Cross-sectional design**: Most exposure/outcome pairs measured simultaneously.
   Only mortality provides true prospective follow-up.
2. **No longitudinal clinical data**: No repeat visits, lab trends, or medication
   changes over time within NHANES.
3. **Self-reported medications**: 30-day recall, not pharmacy claims. Subject to
   recall bias and underreporting.
4. **Small sample per cycle**: ~8,700 examined participants limits statistical
   power for rare exposures or outcomes.
5. **Age top-coding**: Ages ≥80 coded as 80. Limits geriatric subgroup analyses.
6. **No inpatient/claims data**: Cannot identify hospitalizations, procedures, or
   healthcare utilization details beyond self-report.
```

- [ ] **Step 2: Verify file is non-empty and well-formed**

Run: `wc -l databases/profiles/nhanes_profile.md && head -5 databases/profiles/nhanes_profile.md`

Expected: ~160+ lines, starts with "# NHANES — Data Profile"

- [ ] **Step 3: Commit**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
git add databases/profiles/nhanes_profile.md
git commit -m "Add NHANES data profile for 2017-2018 cycle"
```

---

### Task 4: Create NHANES conventions

**Files:**
- Create: `databases/conventions/nhanes_conventions.md`

- [ ] **Step 1: Create the conventions file**

Write `databases/conventions/nhanes_conventions.md`:

```markdown
# NHANES — Database Conventions

These conventions are specific to NHANES data accessed via the nhanesA R package
and loaded into DuckDB in-memory. Agents MUST read and apply every convention
when writing R or SQL code targeting NHANES. Reviewers MUST check every
convention as a review item.

## Data Access: nhanesA + DuckDB

NHANES data is accessed via the `nhanesA` R package, which downloads SAS
transport (XPT) files from the CDC website and returns R data frames. In online
mode, these are loaded into a DuckDB in-memory database for SQL querying.

### Loading Tables

```r
# Load a table into DuckDB (lazy — fetches from CDC on first call)
load_nhanes("DEMO_J")

# Then query via SQL
query_db("SELECT * FROM DEMO_J WHERE RIDAGEYR >= 18")

# Or load directly in R without DuckDB
df <- nhanes("DEMO_J")
```

### Join Key

All tables join on `SEQN` (Respondent Sequence Number). SEQN is unique within
a cycle but NOT across cycles.

```sql
SELECT d.*, g.LBXGH
FROM DEMO_J d
INNER JOIN GHB_J g ON d.SEQN = g.SEQN
WHERE d.RIDSTATR = 2
```

## Survey Design (MANDATORY)

**CRITICAL: Every analysis producing population-level estimates MUST use the
`survey` package with the complex survey design.** Failing to do so produces
biased point estimates and incorrect standard errors/confidence intervals.

### Design Variables

| Variable | Purpose | When to Use |
|----------|---------|-------------|
| WTMEC2YR | MEC exam weight (2-year) | Exam or lab components |
| WTINT2YR | Interview weight (2-year) | Interview-only components |
| WTSAF2YR | Fasting subsample weight | Fasting labs (glucose, triglycerides, insulin) |
| SDMVSTRA | Masked variance pseudo-stratum | Always (design structure) |
| SDMVPSU | Masked variance pseudo-PSU | Always (design structure) |

### Required Pattern

```r
library(survey)

# Standard MEC design (exam + lab data)
des <- svydesign(
  ids = ~SDMVPSU,
  strata = ~SDMVSTRA,
  weights = ~WTMEC2YR,
  nest = TRUE,
  data = analytic_df
)

# Fasting subsample design (glucose, triglycerides, insulin)
des_fasting <- svydesign(
  ids = ~SDMVPSU,
  strata = ~SDMVSTRA,
  weights = ~WTSAF2YR,
  nest = TRUE,
  data = fasting_df
)
```

### Weighted Analysis Functions

Use survey-weighted versions of ALL statistical functions:

| Instead of | Use | Package |
|-----------|-----|---------|
| `mean()` | `svymean()` | survey |
| `glm()` | `svyglm()` | survey |
| `coxph()` | `svycoxph()` | survey |
| `chisq.test()` | `svychisq()` | survey |
| `t.test()` | `svyttest()` | survey |
| `quantile()` | `svyquantile()` | survey |
| `table()` | `svytable()` | survey |
| `lm()` | `svyglm(..., family = gaussian())` | survey |
| `logistic via glm()` | `svyglm(..., family = quasibinomial())` | survey |

**Note:** Use `quasibinomial()` not `binomial()` for logistic regression with
survey designs to avoid "non-integer successes" warnings.

### Exception

Internal validity analyses (e.g., within-sample prediction models, machine
learning) may omit survey weights with explicit justification documented in the
protocol. External generalizability claims still require weighting.

## Missing Data Codes (MANDATORY)

NHANES uses special numeric codes for non-response. These are NOT coded as NA
in the raw data and MUST be recoded before analysis.

| Code | Meaning |
|------|---------|
| 7, 77, 777, 7777 | Refused |
| 9, 99, 999, 9999 | Don't know |

The number of digits matches the field width. For example, a 2-digit field uses
77/99; a 4-digit field uses 7777/9999.

**Rule:** For every variable used in analysis, check the codebook for special
codes and recode to NA:

```r
# Per-variable approach (preferred — use exact codes from codebook)
df <- df |>
  mutate(
    INDHHIN2 = na_if(INDHHIN2, 77) |> na_if(99),
    DMDMARTZ = na_if(DMDMARTZ, 77) |> na_if(99),
    ALQ121   = na_if(ALQ121, 777) |> na_if(999)
  )
```

Do NOT blindly recode all 77s and 99s — some variables legitimately have these
values (e.g., lab results, continuous measures). Always check the codebook.

## Cycle Combining

When pooling multiple 2-year cycles:

1. **Adjust weights:** Divide 2-year weights by the number of cycles pooled.

```r
# Two cycles (e.g., 2015-2016 + 2017-2018)
combined$WTMEC4YR <- combined$WTMEC2YR / 2

# Three cycles
combined$WTMEC6YR <- combined$WTMEC2YR / 3
```

2. **Harmonize variable names:** Suffixes change per cycle. Strip or standardize.

```r
# Load and rename
demo_i <- nhanes("DEMO_I") |> mutate(cycle = "2015-2016")
demo_j <- nhanes("DEMO_J") |> mutate(cycle = "2017-2018")
combined <- bind_rows(demo_i, demo_j)
```

3. **Check for variable changes:** Some variables are added, removed, or recoded
   between cycles. Use `nhanesCodebook()` to compare. Common changes:
   - Blood pressure protocol changed from auscultatory to oscillometric in
     2017-2018 (BPX → BPXO). Cannot directly combine BP readings across this
     boundary.
   - Race variable RIDRETH3 (with NH Asian category) available from 2011-2012+.
     Earlier cycles only have RIDRETH1.

4. **Use single-cycle data by default.** Only combine cycles when sample size
   is insufficient for the research question.

## Fasting Subsample

Glucose, triglycerides, and insulin are measured only in participants examined
in the morning session after an overnight fast (~50% of MEC participants).

**Rules:**
- Use `WTSAF2YR` (not `WTMEC2YR`) as the weight variable for any analysis
  involving fasting labs
- Merge fasting weights from the fasting lab table (e.g., GLU_J has WTSAF2YR)
- Participants with WTSAF2YR == 0 or NA were not in the fasting subsample —
  exclude them
- BIOPRO_J glucose (LBXSGL) is NOT fasting — it is measured in all participants.
  Use GLU_J (LBXGLU) for fasting glucose.

```r
# Correct: fasting glucose with fasting weight
fasting_df <- demo |>
  inner_join(glu, by = "SEQN") |>
  filter(WTSAF2YR > 0 & !is.na(WTSAF2YR))

des_fasting <- svydesign(
  ids = ~SDMVPSU, strata = ~SDMVSTRA,
  weights = ~WTSAF2YR, nest = TRUE, data = fasting_df
)
```

## Age Top-Coding

Ages ≥80 are coded as 80 in `RIDAGEYR`. This is a disclosure protection
measure.

- Cannot distinguish 80-year-olds from 95-year-olds
- For elderly-focused protocols, document this ceiling effect as a limitation
- `RIDAGEMN` (age in months) is only available for children under 24 months

## Target Trial Emulation Design Constraints

NHANES is a cross-sectional survey. Exposure and outcome are typically measured
at the same time point. This fundamentally limits causal inference designs.

### Legitimate TTE Designs with NHANES

1. **Mortality outcomes (strongest design)**
   - Baseline: NHANES exam visit (exposure, confounders measured)
   - Follow-up: Linked mortality file (prospective outcome)
   - Time-to-event: PERMTH_EXM from mortality file
   - This is a true prospective design and the preferred approach

2. **Prevalent exposure → mortality**
   - Example: Current statin use → all-cause mortality
   - Treatment: self-reported or biomarker-confirmed at exam
   - Outcome: mortality follow-up
   - Limitation: prevalent user bias (survivors already selected)

3. **Cross-sectional with temporal reasoning (weaker)**
   - Example: "Ever diagnosed with diabetes" (past) → current HbA1c
   - Requires careful justification of temporal ordering
   - Cannot establish when exposure began relative to outcome

### Designs to AVOID

- Biomarker → same-visit biomarker (no temporal ordering)
- Self-reported condition → self-reported condition (both cross-sectional)
- Any design claiming incident (new-onset) outcomes from cross-sectional data

### Required Documentation

Every NHANES TTE protocol MUST include:
1. Explicit justification of temporal ordering between exposure and outcome
2. Statement of cross-sectional design limitations
3. Discussion of prevalent user bias if using current medication exposure
4. Sensitivity analysis for unmeasured time-varying confounding

## Prescription Medication Conventions

RXQ_RX_J contains 30-day prescription medication use.

- **Multiple rows per participant** — one row per medication. Always aggregate
  to participant level when building analytic cohorts.
- **Drug identification:** Use `RXDDRUG` (generic drug name string), not
  Lexicon Plus codes, for human-readable medication classification.
- **No RxNorm CUIs:** NHANES uses Lexicon Plus drug codes (RXDDRGID), not
  RxNorm. Match on generic drug name if mapping to RxNorm.
- **Self-reported:** Subject to recall bias and underreporting. Participants
  bring medication bottles to the interview, but compliance varies.
- **ICD-10-CM reason for use:** RXDRSC1-3 contain ICD-10 codes for why the
  medication was prescribed. Useful for indication-based cohort selection.

```r
# Example: Identify statin users
statin_names <- c("Atorvastatin", "Rosuvastatin", "Simvastatin",
                  "Pravastatin", "Lovastatin", "Fluvastatin", "Pitavastatin")

statin_users <- rxq |>
  filter(str_detect(toupper(RXDDRUG), paste(toupper(statin_names), collapse = "|"))) |>
  distinct(SEQN) |>
  mutate(statin_use = 1L)

analytic <- demo |>
  left_join(statin_users, by = "SEQN") |>
  mutate(statin_use = replace_na(statin_use, 0L))
```

## R Code Patterns

### Standard Analysis Setup

```r
library(nhanesA)
library(survey)
library(tidyverse)

# 1. Load and merge tables
load_nhanes("DEMO_J")
load_nhanes("GHB_J")
load_nhanes("BMX_J")
load_nhanes("BPQ_J")
load_nhanes("DIQ_J")

analytic <- query_db("
  SELECT d.SEQN, d.RIAGENDR, d.RIDAGEYR, d.RIDRETH3,
         d.DMDEDUC2, d.INDFMPIR,
         d.WTMEC2YR, d.SDMVSTRA, d.SDMVPSU,
         g.LBXGH,
         b.BMXBMI,
         bpq.BPQ020, bpq.BPQ040A,
         diq.DIQ010
  FROM DEMO_J d
  LEFT JOIN GHB_J g ON d.SEQN = g.SEQN
  LEFT JOIN BMX_J b ON d.SEQN = b.SEQN
  LEFT JOIN BPQ_J bpq ON d.SEQN = bpq.SEQN
  LEFT JOIN DIQ_J diq ON d.SEQN = diq.SEQN
  WHERE d.RIDSTATR = 2 AND d.RIDAGEYR >= 18
")

# 2. Recode missing data (per codebook)
analytic <- analytic |>
  mutate(
    DMDEDUC2 = na_if(DMDEDUC2, 7) |> na_if(9),
    BPQ020   = na_if(BPQ020, 7) |> na_if(9),
    BPQ040A  = na_if(BPQ040A, 7) |> na_if(9),
    DIQ010   = na_if(DIQ010, 7) |> na_if(9)
  )

# 3. Create survey design
des <- svydesign(
  ids = ~SDMVPSU, strata = ~SDMVSTRA,
  weights = ~WTMEC2YR, nest = TRUE, data = analytic
)

# 4. Survey-weighted analysis
fit <- svyglm(outcome ~ treatment + RIDAGEYR + factor(RIAGENDR) +
               factor(RIDRETH3) + DMDEDUC2 + INDFMPIR + BMXBMI,
               design = des, family = quasibinomial())
```

### Codebook Lookup

```r
# Get full codebook for a table (useful for verifying missing codes)
cb <- nhanesCodebook("DEMO_J")

# Translate coded values to labels
demo_labeled <- nhanesTranslate("DEMO_J",
  colnames = c("RIAGENDR", "RIDRETH3", "DMDEDUC2"))
```

### Mortality Analysis

```r
# Load mortality file (downloaded separately as CSV)
mort <- read_csv("NHANES_2017_2018_MORT_2019_PUBLIC.csv")

# Merge with NHANES
analytic_mort <- analytic |>
  inner_join(mort, by = "SEQN") |>
  filter(ELIGSTAT == 1)  # Eligible for follow-up

# Survey-weighted Cox model for mortality
des_mort <- svydesign(
  ids = ~SDMVPSU, strata = ~SDMVSTRA,
  weights = ~WTMEC2YR, nest = TRUE, data = analytic_mort
)

fit_cox <- svycoxph(
  Surv(PERMTH_EXM, MORTSTAT) ~ treatment + RIDAGEYR + factor(RIAGENDR),
  design = des_mort
)
```

## Column Handling

### Case Sensitivity

NHANES variables from nhanesA retain their original case (UPPERCASE). When
loaded into DuckDB, column names preserve case. Use UPPERCASE in SQL queries:

```sql
SELECT SEQN, RIDAGEYR, LBXGH FROM DEMO_J
```

In R code, also use UPPERCASE variable names to match:

```r
df |> filter(RIDAGEYR >= 18, RIAGENDR == 1)
```

### Derived Variables

Create derived variables with distinct lowercase names to avoid overwriting:

```r
analytic <- analytic |>
  mutate(
    age_cat = cut(RIDAGEYR, breaks = c(18, 40, 60, 80), right = FALSE,
                  labels = c("18-39", "40-59", "60-79")),
    obese = as.integer(BMXBMI >= 30),
    diabetes_status = case_when(
      DIQ010 == 1 ~ "diabetes",
      DIQ010 == 3 ~ "prediabetes",
      DIQ010 == 2 ~ "no_diabetes",
      TRUE ~ NA_character_
    )
  )
```

## Sample Size Considerations

NHANES has ~8,700 examined participants per 2-year cycle. Key implications:

- Subgroup analyses (e.g., NH Asian females age 60+ with diabetes) can quickly
  drop below meaningful sample sizes
- Survey variance estimation requires ≥2 PSUs per stratum. Dropping strata via
  aggressive subsetting can break `svydesign()`
- For rare exposures/outcomes, consider pooling 2-3 cycles (with weight adjustment)
- Treatment/control arms in TTE protocols may be imbalanced — check positivity
  before proceeding with propensity score methods
- Rule of thumb: minimum ~100 participants per treatment arm for weighted analyses
```

- [ ] **Step 2: Verify file is non-empty and well-formed**

Run: `wc -l databases/conventions/nhanes_conventions.md && head -5 databases/conventions/nhanes_conventions.md`

Expected: ~280+ lines, starts with "# NHANES — Database Conventions"

- [ ] **Step 3: Commit**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
git add databases/conventions/nhanes_conventions.md
git commit -m "Add NHANES conventions with survey design and TTE constraints"
```

---

### Task 5: Create NHANES YAML config

**Files:**
- Create: `databases/nhanes.yaml`

- [ ] **Step 1: Create the YAML config**

Write `databases/nhanes.yaml`:

```yaml
id: "nhanes"
name: "NHANES"
cdm: "nhanes"
engine: "duckdb"
online: true

connection:
  r_code: |
    library(nhanesA)
    library(duckdb)
    con <- dbConnect(duckdb::duckdb(), ":memory:")
    load_nhanes <- function(tbl) {
      if (!dbExistsTable(con, tbl)) {
        df <- nhanes(tbl)
        dbWriteTable(con, tbl, df)
        message(sprintf("Loaded %s: %d rows, %d cols", tbl, nrow(df), ncol(df)))
      }
      invisible(NULL)
    }

schema_prefix: ""
schema_dump: "databases/schemas/nhanes_schema.txt"
data_profile: "databases/profiles/nhanes_profile.md"
conventions: "databases/conventions/nhanes_conventions.md"
```

- [ ] **Step 2: Verify YAML parses correctly**

Run: `cd /Users/toddjohnson/Documents/GitHub/AutoTTE && python3 -c "import yaml; c = yaml.safe_load(open('databases/nhanes.yaml')); print(f'id={c[\"id\"]} cdm={c[\"cdm\"]} engine={c[\"engine\"]} online={c[\"online\"]}'); print(f'schema_dump={c[\"schema_dump\"]}'); print(f'r_code starts with: {c[\"connection\"][\"r_code\"][:30]}')"`

Expected:
```
id=nhanes cdm=nhanes engine=duckdb online=True
schema_dump=databases/schemas/nhanes_schema.txt
r_code starts with: library(nhanesA)
```

- [ ] **Step 3: Verify run.sh can parse it**

Run: `cd /Users/toddjohnson/Documents/GitHub/AutoTTE && python3 -c "
import yaml
with open('databases/nhanes.yaml') as f:
    c = yaml.safe_load(f)
print(f'DB_ID={c.get(\"id\", \"\")}')
print(f'DB_NAME=\"{c.get(\"name\", \"\")}\"')
print(f'DB_CDM={c.get(\"cdm\", \"\")}')
print(f'DB_ENGINE={c.get(\"engine\", \"\")}')
print(f'DB_SCHEMA_PREFIX=\"{c.get(\"schema_prefix\", \"\")}\"')
print(f'DB_ONLINE={str(c.get(\"online\", False)).lower()}')
"`

Expected:
```
DB_ID=nhanes
DB_NAME="NHANES"
DB_CDM=nhanes
DB_ENGINE=duckdb
DB_SCHEMA_PREFIX=""
DB_ONLINE=true
```

- [ ] **Step 4: Commit**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
git add databases/nhanes.yaml
git commit -m "Add NHANES YAML config for nhanesA + DuckDB online mode"
```

---

### Task 6: End-to-end verification

**Files:** None (verification only)

- [ ] **Step 1: Run full test suite**

Run: `cd /Users/toddjohnson/Documents/GitHub/AutoTTE && python -m pytest tests/ -v`

Expected: All tests PASS

- [ ] **Step 2: Verify datasource server resolves NHANES files**

Run: `cd /Users/toddjohnson/Documents/GitHub/AutoTTE && python3 -c "
from tools.datasource_server import PUBLIC_DATASETS, get_details_by_id, read_file_content, load_db_configs
from pathlib import Path

# Check public dataset entry
nhanes = get_details_by_id('nhanes', list(PUBLIC_DATASETS))
print(f'Found NHANES in PUBLIC_DATASETS: {nhanes is not None}')
print(f'schema_dump: {nhanes.get(\"schema_dump\", \"MISSING\")}')
print(f'data_profile: {nhanes.get(\"data_profile\", \"MISSING\")}')
print(f'conventions: {nhanes.get(\"conventions\", \"MISSING\")}')

# Check files exist and are non-empty
for key in ['schema_dump', 'data_profile', 'conventions']:
    path = nhanes[key]
    content = read_file_content(path)
    ok = not content.startswith('[File not found')
    print(f'{key} file exists: {ok} ({len(content)} chars)')

# Check YAML config also loaded
configs = load_db_configs('databases')
nhanes_db = get_details_by_id('nhanes', configs)
print(f'Found NHANES in YAML configs: {nhanes_db is not None}')
print(f'YAML has connection r_code: {bool(nhanes_db.get(\"connection\", {}).get(\"r_code\", \"\"))}')
"`

Expected:
```
Found NHANES in PUBLIC_DATASETS: True
schema_dump: databases/schemas/nhanes_schema.txt
data_profile: databases/profiles/nhanes_profile.md
conventions: databases/conventions/nhanes_conventions.md
schema_dump file exists: True (NNNN chars)
data_profile file exists: True (NNNN chars)
conventions file exists: True (NNNN chars)
Found NHANES in YAML configs: True
YAML has connection r_code: True
```

- [ ] **Step 3: Verify all files present**

Run: `ls -la databases/nhanes.yaml databases/schemas/nhanes_schema.txt databases/profiles/nhanes_profile.md databases/conventions/nhanes_conventions.md`

Expected: All 4 files exist with non-zero size
