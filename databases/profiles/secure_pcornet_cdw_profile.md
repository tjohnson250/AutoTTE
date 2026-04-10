# CDW Data Profile for AutoTTE
# Generated: 2026-04-05 12:39:33.990965
# Schema: dbo
# NOTE: This file contains ONLY aggregate counts. No PHI (PATIDs, dates
#       of service, etc.) is included. Counts < 11 are suppressed.

---
## 1. Overall CDW Size and Temporal Coverage

Total distinct patients in DEMOGRAPHIC: 10,091,847

| Table | Distinct Patients | Rows | Earliest (YYYY-MM) | Latest (YYYY-MM) |
|-------|-------------------|------|---------------------|-------------------|
| ENCOUNTER | 5,315,029 | 211,822,838 | 1820-11 | 3019-03 |
| DIAGNOSIS | 4,394,248 | 152,125,158 | 1899-12 | 2034-03 |
| PROCEDURES | 4,475,979 | 158,790,455 | 1900-01 | 2033-08 |
| PRESCRIBING | 1,293,303 | 16,514,110 | 2004-04 | 2026-04 |
| DISPENSING | 1,271,915 | 64,151,827 | 2006-12 | 2026-04 |
| LAB_RESULT_CM | 1,466,580 | 182,979,640 | 1900-01 | 2026-04 |
| VITAL | 2,549,495 | 39,508,053 | 1754-01 | 2026-06 |
| MED_ADMIN | 156,993 | 4,869,369 | 2021-04 | 2026-04 |
| CONDITION | 1,480,087 | 26,830,777 | 1842-01 | 2026-04 |
| DEATH | 113,105 | 131,406 | 1926-12 | 2026-04 |
| ENROLLMENT | 5,314,626 | 5,314,626 | 2000-01 | 2026-04 |

---
## 2. Year-by-Year Patient Volume (ENCOUNTER)

This shows how many distinct patients have at least one encounter per year.

| Year | Distinct Patients | Encounters |
|------|-------------------|------------|
| 1820 | <11 | 1 |
| 1899 | <11 | 1 |
| 1900 | 40,438 | 334,295 |
| 1901 | <11 | 1 |
| 1902 | <11 | 3 |
| 1904 | <11 | 1 |
| 1907 | <11 | 1 |
| 1910 | <11 | 2 |
| 1911 | <11 | 5 |
| 1912 | 16 | 16 |
| 1913 | <11 | 7 |
| 1914 | 17 | 19 |
| 1915 | <11 | 11 |
| 1916 | <11 | 8 |
| 1917 | 11 | 11 |
| 1918 | <11 | 6 |
| 1919 | <11 | 4 |
| 1920 | 19 | 20 |
| 1921 | 14 | 14 |
| 1922 | 25 | 26 |
| 1923 | 11 | 11 |
| 1924 | <11 | 6 |
| 1925 | 18 | 19 |
| 1926 | 22 | 23 |
| 1927 | <11 | 7 |
| 1928 | <11 | 8 |
| 1929 | 11 | 13 |
| 1930 | 16 | 22 |
| 1931 | 18 | 23 |
| 1932 | <11 | 4 |
| 1933 | 11 | 11 |
| 1934 | <11 | 9 |
| 1935 | <11 | 8 |
| 1936 | 12 | 14 |
| 1937 | <11 | 7 |
| 1938 | <11 | 15 |
| 1939 | <11 | 5 |
| 1940 | 11 | 11 |
| 1941 | 12 | 12 |
| 1942 | 17 | 20 |
| 1943 | 12 | 12 |
| 1944 | 16 | 16 |
| 1945 | 17 | 17 |
| 1946 | 20 | 20 |
| 1947 | 21 | 21 |
| 1948 | 19 | 20 |
| 1949 | 16 | 17 |
| 1950 | 20 | 22 |
| 1951 | 19 | 19 |
| 1952 | 17 | 17 |
| 1953 | 20 | 25 |
| 1954 | 24 | 27 |
| 1955 | 17 | 19 |
| 1956 | 29 | 31 |
| 1957 | 22 | 22 |
| 1958 | 24 | 28 |
| 1959 | 17 | 19 |
| 1960 | 12 | 15 |
| 1961 | 21 | 27 |
| 1962 | 16 | 16 |
| 1963 | 19 | 19 |
| 1964 | <11 | 11 |
| 1965 | 11 | 14 |
| 1966 | 17 | 18 |
| 1967 | <11 | 6 |
| 1968 | 14 | 16 |
| 1969 | 20 | 21 |
| 1970 | 19 | 35 |
| 1971 | 18 | 18 |
| 1972 | 13 | 21 |
| 1973 | 14 | 15 |
| 1974 | 15 | 23 |
| 1975 | <11 | 11 |
| 1976 | 16 | 16 |
| 1977 | 20 | 24 |
| 1978 | 16 | 21 |
| 1979 | 18 | 22 |
| 1980 | 34 | 57 |
| 1981 | 22 | 34 |
| 1982 | 21 | 62 |
| 1983 | 38 | 62 |
| 1984 | 44 | 71 |
| 1985 | 42 | 72 |
| 1986 | 53 | 104 |
| 1987 | 61 | 139 |
| 1988 | 92 | 227 |
| 1989 | 111 | 227 |
| 1990 | 138 | 371 |
| 1991 | 181 | 532 |
| 1992 | 245 | 874 |
| 1993 | 415 | 1,693 |
| 1994 | 634 | 2,865 |
| 1995 | 778 | 3,243 |
| 1996 | 1,149 | 4,645 |
| 1997 | 1,420 | 6,192 |
| 1998 | 1,956 | 9,127 |
| 1999 | 3,218 | 13,040 |
| 2000 | 13,201 | 46,039 |
| 2001 | 29,830 | 121,250 |
| 2002 | 61,358 | 233,943 |
| 2003 | 75,610 | 302,126 |
| 2004 | 122,508 | 530,403 |
| 2005 | 224,219 | 1,331,821 |
| 2006 | 278,579 | 2,178,748 |
| 2007 | 289,209 | 2,861,888 |
| 2008 | 299,803 | 2,454,882 |
| 2009 | 327,460 | 2,566,870 |
| 2010 | 342,855 | 2,751,793 |
| 2011 | 366,203 | 3,126,240 |
| 2012 | 405,360 | 3,659,639 |
| 2013 | 481,777 | 4,754,855 |
| 2014 | 566,838 | 5,577,338 |
| 2015 | 627,471 | 6,568,100 |
| 2016 | 697,381 | 8,741,076 |
| 2017 | 772,831 | 13,012,540 |
| 2018 | 830,825 | 16,071,317 |
| 2019 | 854,455 | 18,498,589 |
| 2020 | 799,767 | 15,561,299 |
| 2021 | 2,766,068 | 21,103,777 |
| 2022 | 1,040,333 | 18,163,637 |
| 2023 | 1,060,490 | 19,024,175 |
| 2024 | 1,073,226 | 19,560,720 |
| 2025 | 1,104,536 | 17,359,480 |
| 2026 | 570,972 | 5,255,129 |
| 2027 | 15,907 | 25,461 |
| 2028 | 64 | 123 |
| 2029 | 50 | 88 |
| 2030 | 20 | 21 |
| 2031 | <11 | 4 |
| 2032 | <11 | 6 |
| 2033 | 23 | 55 |
| 2034 | <11 | 7 |
| 2035 | <11 | 4 |
| 2036 | <11 | 8 |
| 2038 | <11 | 2 |
| 2040 | <11 | 4 |
| 2041 | <11 | 2 |
| 2042 | <11 | 3 |
| 2043 | <11 | 2 |
| 2044 | 17 | 34 |
| 2045 | <11 | 12 |
| 2046 | <11 | 7 |
| 2047 | <11 | 21 |
| 2048 | <11 | 2 |
| 2049 | <11 | 1 |
| 2050 | <11 | 2 |
| 2051 | <11 | 3 |
| 2052 | <11 | 6 |
| 2054 | <11 | 2 |
| 2055 | 28 | 51 |
| 2056 | 15 | 26 |
| 2058 | <11 | 6 |
| 2059 | <11 | 1 |
| 2060 | <11 | 1 |
| 2061 | <11 | 1 |
| 2063 | <11 | 1 |
| 2064 | <11 | 1 |
| 2065 | <11 | 3 |
| 2066 | 20 | 41 |
| 2067 | <11 | 7 |
| 2068 | <11 | 5 |
| 2069 | <11 | 5 |
| 2070 | <11 | 1 |
| 2071 | <11 | 1 |
| 2072 | <11 | 3 |
| 2075 | <11 | 12 |
| 2076 | <11 | 9 |
| 2077 | 16 | 36 |
| 2078 | <11 | 10 |
| 2079 | <11 | 3 |
| 2088 | <11 | 1 |
| 3019 | <11 | 1 |

---
## 3. Legacy Encounters, EHR Migration, and Record Duplication

### Background: AllScripts <U+2192> Epic Migration

This CDW contains data from TWO EHR eras:
1. **AllScripts era** — original EHR data fed directly into the CDW.
2. **Epic era** — after migration, Epic became the primary EHR feed.

During the Epic go-live, some AllScripts records were imported INTO Epic.
The Epic feed then sent those imported records back into the CDW, creating
**duplicate records**: the original AllScripts version AND the re-imported
Epic version of the same clinical event.

These duplicates are identifiable via two columns in the ENCOUNTER table:
- `RAW_ENC_TYPE = 'Legacy Encounter'` — the Epic-side label for imported
  AllScripts encounters that were re-fed into the CDW.
- `IS_LEGACY_IMPORT = 'Y'` — a CDW-level flag for the same records.

**Default rule: ALWAYS filter out legacy encounters** unless you have a
specific reason to keep them. Including them causes double-counting of
encounters, diagnoses, procedures, and other linked records from the
pre-Epic period.

```sql
-- Standard filter to exclude duplicate legacy encounters:
INNER JOIN CDW.dbo.ENCOUNTER e ON ...
  AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
```

### 3a. RAW_ENC_TYPE Distribution

This is the primary column for identifying legacy duplicates.

| RAW_ENC_TYPE | Patients | Encounters |
|--------------|----------|------------|
| OUTPATIENT | 2,472,737 | 25,428,170 |
| [TX:PB] | 1,545,129 | 20,823,436 |
| Appointment | 2,362,370 | 18,523,832 |
| CDA | 792,315 | 14,868,953 |
| Legacy Encounter | 1,251,487 | 12,782,001 |
| INPATIENT | 896,943 | 10,153,795 |
| Image Encounter | 1,307,532 | 9,751,118 |
| EXT HHS OP | 400,863 | 8,641,152 |
| History | 3,124,804 | 7,804,437 |
| Lab Encounter | 761,100 | 6,895,577 |
| Travel | 1,033,389 | 6,352,044 |
| Chart Update | 634,228 | 5,932,707 |
| [IMM] | 678,631 | 5,017,539 |
| Telephone | 737,798 | 4,209,805 |
| EMERGENCY ROOM | 1,012,060 | 4,111,045 |
| EXT MHH OP | 863,922 | 3,868,358 |
| Reconciled Outside Data | 1,076,290 | 3,770,553 |
| Transcription Encounter | 865,980 | 3,754,563 |
| Office Visit | 899,164 | 3,748,702 |
| AUDIT | 460,211 | 3,446,932 |
| Orders Only | 586,603 | 2,682,639 |
| Result Review | 500,509 | 2,512,004 |
| Patient Message | 382,155 | 2,344,020 |
| Refill | 300,929 | 2,291,310 |
| Scanned Document | 505,809 | 2,195,634 |
| EXT MHH ED | 880,857 | 1,757,386 |
| Telephone Call | 443,098 | 1,687,880 |
| Wait List | 654,355 | 1,662,115 |
| Result Charge | 104,655 | 1,622,863 |
| Rx Renewal | 170,599 | 1,490,637 |
| EXT MHH IP | 395,382 | 1,420,752 |
| Procedure Pass | 493,874 | 1,412,984 |
| Ancillary Procedure | 458,635 | 1,213,434 |
| Non-Appointment | 57,966 | 731,074 |
| Billing Encounter | 204,551 | 553,947 |
| Letter (Out) | 224,143 | 474,306 |
| EXT HHS ED | 197,517 | 394,222 |
| Patient Outreach | 74,876 | 358,583 |
| Transcribe Orders | 250,666 | 349,907 |
| Other | 146,726 | 335,984 |
| Results Follow-Up | 160,913 | 331,091 |
| Telemedicine | 103,353 | 303,790 |
| Clinical Encounter | 121,616 | 278,463 |
| Abstract | 136,561 | 250,852 |
| Documentation | 123,131 | 247,009 |
| (NULL) | 110,903 | 240,226 |
| [PROBLEM] | 42,866 | 212,623 |
| OurPractice Advisory | 151,584 | 204,452 |
| Message | 78,005 | 195,292 |
| Ancillary Orders | 99,606 | 187,445 |
| Nurse Triage | 76,015 | 185,813 |
| Procedure Visit | 79,688 | 168,099 |
| Hospital Encounter | 75,545 | 153,389 |
| Routine Prenatal | 22,900 | 147,407 |
| Form Encounter | 85,039 | 142,956 |
| Chart Copy | 53,506 | 123,953 |
| Plan of Care Documentation | 28,244 | 113,177 |
| EXT MHHS PR | 87,219 | 105,443 |
| External Contact | 47,448 | 100,270 |
| Intake | 55,922 | 97,716 |
| Clinical Documentation Only | 65,027 | 78,591 |
| Nurse Only | 40,574 | 65,788 |
| Rx Change | 23,068 | 60,278 |
| EXT HHS IP | 23,173 | 45,130 |
| Immunization | 25,841 | 36,429 |
| Consult | 29,886 | 34,630 |
| Telephonic Encounter | 24,774 | 34,471 |
| Clinical Support | 17,526 | 32,810 |
| Postpartum Visit | 17,605 | 29,105 |
| Nutrition | 11,433 | 24,822 |
| Initial Prenatal | 21,115 | 24,094 |
| Education | 15,815 | 22,072 |
| Questionnaire Series Submission | 8,537 | 21,860 |
| Social Work | 6,078 | 20,633 |
| External Contacts | 17,245 | 20,434 |
| Diabetes Education | 7,634 | 17,012 |
| Outside Procedure | 8,212 | 11,914 |
| EXT MHHS NP | 9,578 | 11,913 |
| Evaluation | 8,676 | 11,540 |
| Charges | 6,747 | 9,789 |
| Employee Health | 4,703 | 6,012 |
| EMPTY | 4,994 | 5,785 |
| Medication Management | 1,445 | 5,022 |
| Treatment | 1,836 | 3,643 |
| E Health Visit Old | 3,154 | 3,557 |
| Contact Moved | 402 | 3,553 |
| Lab Requisition | 2,782 | 3,229 |
| External Hospital Admission | 2,303 | 2,897 |
| Lab | 2,366 | 2,876 |
|  | 1,471 | 1,517 |
| Remote Monitoring Data Collection | 448 | 1,510 |
| Prep for Procedure | 1,095 | 1,175 |
| Community Orders | 631 | 845 |
| Home Monitoring | 48 | 368 |
| Patient Self-Triage | 227 | 279 |
| ADMINISTRATIVE UNAPP ACCOUNT | 78 | 248 |
| IPat Visit | 137 | 193 |
| Anticoagulation - Warfarin Visit | 90 | 155 |
| Unmerge | 145 | 155 |
| Cardiology Conference | 111 | 125 |
| Post Mortem Documentation | 93 | 110 |
| E-Visit | 87 | 99 |
| Recurring Plan | 19 | 93 |
| Mother Baby Link | 87 | 88 |
| Anticoagulation - Other Visit (DOAC) | 31 | 32 |
| Biometric Visit | 17 | 23 |
| Lactation Encounter | 20 | 20 |
| Multidisciplinary Visit | 12 | 12 |
| E-Consult | <11 | 8 |
| Hospice F2F Visit | <11 | 6 |
| Specialty Pharmacy | <11 | 6 |
| Lactation Consult | <11 | 6 |
| Episode Changes | <11 | 3 |
| EXT HHS NP | <11 | 2 |
| Deleted | <11 | 2 |
| Consent Form | <11 | 1 |
| Canceled | <11 | 1 |
| Hospital | <11 | 1 |

### 3b. IS_LEGACY_IMPORT Distribution

| IS_LEGACY_IMPORT | Patients | Encounters |
|------------------|----------|------------|
| N | 5,315,029 | 200,427,548 |
| Y | 1,078,826 | 11,395,290 |

### Cross-tab: RAW_ENC_TYPE vs IS_LEGACY_IMPORT

Verifies whether the two legacy flags align.

| RAW_ENC_TYPE | IS_LEGACY_IMPORT | Encounters |
|--------------|------------------|------------|
| History | Y | 11,424 |
| Legacy Encounter | N | 1,398,135 |
| Legacy Encounter | Y | 11,383,866 |

### 3c. CDW_Source Distribution (ENCOUNTER)

Shows which source system feeds each encounter. Multiple CDW_Source
values in the same year range may indicate overlapping feeds.

| CDW_Source | Patients | Encounters | Earliest | Latest |
|-----------|----------|------------|----------|--------|
| EPIC | 4,114,316 | 108,056,563 | 1900-01 | 2088-12 |
| ALLSCRIPTS | 2,147,040 | 64,007,047 | 1820-11 | 3019-03 |
| GECBI | 3,087,258 | 39,759,228 | 1899-12 | 2022-08 |

### 3d. Legacy vs Non-Legacy Encounters by Year

Shows when the duplicate legacy records appear and when they stop.
Years with BOTH Legacy and Non-Legacy rows indicate the overlap
period where double-counting occurs if legacy records are not filtered.

| Year | Category | Patients | Encounters |
|------|----------|----------|------------|
| 1820 | Non-Legacy | <11 | 1 |
| 1899 | Non-Legacy | <11 | 1 |
| 1900 | Non-Legacy | 40,438 | 334,295 |
| 1901 | Non-Legacy | <11 | 1 |
| 1902 | Non-Legacy | <11 | 3 |
| 1904 | Non-Legacy | <11 | 1 |
| 1907 | Non-Legacy | <11 | 1 |
| 1910 | Non-Legacy | <11 | 2 |
| 1911 | Non-Legacy | <11 | 5 |
| 1912 | Non-Legacy | 16 | 16 |
| 1913 | Non-Legacy | <11 | 7 |
| 1914 | Non-Legacy | 17 | 19 |
| 1915 | Non-Legacy | <11 | 11 |
| 1916 | Non-Legacy | <11 | 8 |
| 1917 | Non-Legacy | 11 | 11 |
| 1918 | Non-Legacy | <11 | 6 |
| 1919 | Non-Legacy | <11 | 4 |
| 1920 | Non-Legacy | 19 | 20 |
| 1921 | Legacy | <11 | 1 |
| 1921 | Non-Legacy | 13 | 13 |
| 1922 | Non-Legacy | 25 | 26 |
| 1923 | Non-Legacy | 11 | 11 |
| 1924 | Non-Legacy | <11 | 6 |
| 1925 | Non-Legacy | 18 | 19 |
| 1926 | Non-Legacy | 22 | 23 |
| 1927 | Non-Legacy | <11 | 7 |
| 1928 | Non-Legacy | <11 | 8 |
| 1929 | Non-Legacy | 11 | 13 |
| 1930 | Non-Legacy | 16 | 22 |
| 1931 | Non-Legacy | 18 | 23 |
| 1932 | Non-Legacy | <11 | 4 |
| 1933 | Non-Legacy | 11 | 11 |
| 1934 | Non-Legacy | <11 | 9 |
| 1935 | Non-Legacy | <11 | 8 |
| 1936 | Non-Legacy | 12 | 14 |
| 1937 | Non-Legacy | <11 | 7 |
| 1938 | Non-Legacy | <11 | 15 |
| 1939 | Non-Legacy | <11 | 5 |
| 1940 | Non-Legacy | 11 | 11 |
| 1941 | Non-Legacy | 12 | 12 |
| 1942 | Legacy | <11 | 1 |
| 1942 | Non-Legacy | 16 | 19 |
| 1943 | Legacy | <11 | 1 |
| 1943 | Non-Legacy | 11 | 11 |
| 1944 | Non-Legacy | 16 | 16 |
| 1945 | Non-Legacy | 17 | 17 |
| 1946 | Non-Legacy | 20 | 20 |
| 1947 | Non-Legacy | 21 | 21 |
| 1948 | Non-Legacy | 19 | 20 |
| 1949 | Non-Legacy | 16 | 17 |
| 1950 | Legacy | <11 | 1 |
| 1950 | Non-Legacy | 19 | 21 |
| 1951 | Non-Legacy | 19 | 19 |
| 1952 | Non-Legacy | 17 | 17 |
| 1953 | Non-Legacy | 20 | 25 |
| 1954 | Legacy | <11 | 1 |
| 1954 | Non-Legacy | 23 | 26 |
| 1955 | Non-Legacy | 17 | 19 |
| 1956 | Legacy | <11 | 1 |
| 1956 | Non-Legacy | 28 | 30 |
| 1957 | Non-Legacy | 22 | 22 |
| 1958 | Non-Legacy | 24 | 28 |
| 1959 | Non-Legacy | 17 | 19 |
| 1960 | Non-Legacy | 12 | 15 |
| 1961 | Legacy | <11 | 1 |
| 1961 | Non-Legacy | 21 | 26 |
| 1962 | Non-Legacy | 16 | 16 |
| 1963 | Non-Legacy | 19 | 19 |
| 1964 | Non-Legacy | <11 | 11 |
| 1965 | Legacy | <11 | 2 |
| 1965 | Non-Legacy | <11 | 12 |
| 1966 | Non-Legacy | 17 | 18 |
| 1967 | Non-Legacy | <11 | 6 |
| 1968 | Legacy | <11 | 1 |
| 1968 | Non-Legacy | 13 | 15 |
| 1969 | Legacy | <11 | 2 |
| 1969 | Non-Legacy | 18 | 19 |
| 1970 | Non-Legacy | 19 | 35 |
| 1971 | Legacy | <11 | 2 |
| 1971 | Non-Legacy | 16 | 16 |
| 1972 | Legacy | <11 | 1 |
| 1972 | Non-Legacy | 13 | 20 |
| 1973 | Non-Legacy | 14 | 15 |
| 1974 | Non-Legacy | 15 | 23 |
| 1975 | Non-Legacy | <11 | 11 |
| 1976 | Non-Legacy | 16 | 16 |
| 1977 | Non-Legacy | 20 | 24 |
| 1978 | Non-Legacy | 16 | 21 |
| 1979 | Legacy | <11 | 1 |
| 1979 | Non-Legacy | 17 | 21 |
| 1980 | Legacy | <11 | 1 |
| 1980 | Non-Legacy | 33 | 56 |
| 1981 | Legacy | <11 | 1 |
| 1981 | Non-Legacy | 22 | 33 |
| 1982 | Legacy | <11 | 1 |
| 1982 | Non-Legacy | 20 | 61 |
| 1983 | Legacy | <11 | 1 |
| 1983 | Non-Legacy | 37 | 61 |
| 1984 | Legacy | <11 | 1 |
| 1984 | Non-Legacy | 43 | 70 |
| 1985 | Non-Legacy | 42 | 72 |
| 1986 | Non-Legacy | 53 | 104 |
| 1987 | Non-Legacy | 61 | 139 |
| 1988 | Non-Legacy | 92 | 227 |
| 1989 | Non-Legacy | 111 | 227 |
| 1990 | Non-Legacy | 138 | 371 |
| 1991 | Non-Legacy | 181 | 532 |
| 1992 | Non-Legacy | 245 | 874 |
| 1993 | Non-Legacy | 415 | 1,693 |
| 1994 | Non-Legacy | 634 | 2,865 |
| 1995 | Non-Legacy | 778 | 3,243 |
| 1996 | Non-Legacy | 1,149 | 4,645 |
| 1997 | Non-Legacy | 1,420 | 6,192 |
| 1998 | Non-Legacy | 1,956 | 9,127 |
| 1999 | Non-Legacy | 3,218 | 13,040 |
| 2000 | Legacy | <11 | 2 |
| 2000 | Non-Legacy | 13,199 | 46,037 |
| 2001 | Legacy | <11 | 1 |
| 2001 | Non-Legacy | 29,830 | 121,249 |
| 2002 | Legacy | <11 | 3 |
| 2002 | Non-Legacy | 61,355 | 233,940 |
| 2003 | Legacy | <11 | 2 |
| 2003 | Non-Legacy | 75,608 | 302,124 |
| 2004 | Legacy | <11 | 3 |
| 2004 | Non-Legacy | 122,505 | 530,400 |
| 2005 | Legacy | 545 | 556 |
| 2005 | Non-Legacy | 224,178 | 1,331,265 |
| 2006 | Legacy | 1,059 | 1,100 |
| 2006 | Non-Legacy | 278,484 | 2,177,648 |
| 2007 | Legacy | 2,035 | 2,179 |
| 2007 | Non-Legacy | 289,059 | 2,859,709 |
| 2008 | Legacy | 1,826 | 1,935 |
| 2008 | Non-Legacy | 299,684 | 2,452,947 |
| 2009 | Legacy | 1,660 | 1,741 |
| 2009 | Non-Legacy | 327,326 | 2,565,129 |
| 2010 | Legacy | 2,130 | 2,902 |
| 2010 | Non-Legacy | 342,718 | 2,748,891 |
| 2011 | Legacy | 2,985 | 4,096 |
| 2011 | Non-Legacy | 366,023 | 3,122,144 |
| 2012 | Legacy | 4,171 | 6,393 |
| 2012 | Non-Legacy | 405,104 | 3,653,246 |
| 2013 | Legacy | 5,665 | 8,938 |
| 2013 | Non-Legacy | 481,390 | 4,745,917 |
| 2014 | Legacy | 8,520 | 13,282 |
| 2014 | Non-Legacy | 566,233 | 5,564,056 |
| 2015 | Legacy | 11,367 | 18,163 |
| 2015 | Non-Legacy | 626,818 | 6,549,937 |
| 2016 | Legacy | 231,872 | 652,606 |
| 2016 | Non-Legacy | 684,639 | 8,088,470 |
| 2017 | Legacy | 340,016 | 1,209,970 |
| 2017 | Non-Legacy | 751,010 | 11,802,570 |
| 2018 | Legacy | 430,714 | 2,692,085 |
| 2018 | Non-Legacy | 802,133 | 13,379,232 |
| 2019 | Legacy | 455,292 | 3,406,587 |
| 2019 | Non-Legacy | 820,888 | 15,092,002 |
| 2020 | Legacy | 440,403 | 3,220,224 |
| 2020 | Non-Legacy | 761,377 | 12,341,075 |
| 2021 | Legacy | 389,315 | 1,493,930 |
| 2021 | Non-Legacy | 2,759,641 | 19,609,847 |
| 2022 | Legacy | 13,874 | 16,530 |
| 2022 | Non-Legacy | 1,032,155 | 18,147,107 |
| 2023 | Legacy | 12,148 | 14,504 |
| 2023 | Non-Legacy | 1,051,360 | 19,009,671 |
| 2024 | Legacy | 8,542 | 9,714 |
| 2024 | Non-Legacy | 1,066,929 | 19,551,006 |
| 2025 | Legacy | 4,108 | 4,306 |
| 2025 | Non-Legacy | 1,101,616 | 17,355,174 |
| 2026 | Legacy | 16 | 21 |
| 2026 | Non-Legacy | 570,972 | 5,255,108 |
| 2027 | Legacy | 12 | 15 |
| 2027 | Non-Legacy | 15,907 | 25,446 |
| 2028 | Legacy | 26 | 35 |
| 2028 | Non-Legacy | 63 | 88 |
| 2029 | Legacy | 13 | 17 |
| 2029 | Non-Legacy | 49 | 71 |
| 2030 | Legacy | <11 | 3 |
| 2030 | Non-Legacy | 18 | 18 |
| 2031 | Non-Legacy | <11 | 4 |
| 2032 | Legacy | <11 | 1 |
| 2032 | Non-Legacy | <11 | 5 |
| 2033 | Legacy | 14 | 19 |
| 2033 | Non-Legacy | 23 | 36 |
| 2034 | Legacy | <11 | 1 |
| 2034 | Non-Legacy | <11 | 6 |
| 2035 | Legacy | <11 | 1 |
| 2035 | Non-Legacy | <11 | 3 |
| 2036 | Legacy | <11 | 2 |
| 2036 | Non-Legacy | <11 | 6 |
| 2038 | Legacy | <11 | 1 |
| 2038 | Non-Legacy | <11 | 1 |
| 2040 | Legacy | <11 | 1 |
| 2040 | Non-Legacy | <11 | 3 |
| 2041 | Legacy | <11 | 1 |
| 2041 | Non-Legacy | <11 | 1 |
| 2042 | Non-Legacy | <11 | 3 |
| 2043 | Legacy | <11 | 1 |
| 2043 | Non-Legacy | <11 | 1 |
| 2044 | Legacy | 13 | 14 |
| 2044 | Non-Legacy | 17 | 20 |
| 2045 | Legacy | <11 | 4 |
| 2045 | Non-Legacy | <11 | 8 |
| 2046 | Legacy | <11 | 2 |
| 2046 | Non-Legacy | <11 | 5 |
| 2047 | Legacy | <11 | 8 |
| 2047 | Non-Legacy | <11 | 13 |
| 2048 | Non-Legacy | <11 | 2 |
| 2049 | Non-Legacy | <11 | 1 |
| 2050 | Legacy | <11 | 1 |
| 2050 | Non-Legacy | <11 | 1 |
| 2051 | Legacy | <11 | 1 |
| 2051 | Non-Legacy | <11 | 2 |
| 2052 | Legacy | <11 | 3 |
| 2052 | Non-Legacy | <11 | 3 |
| 2054 | Non-Legacy | <11 | 2 |
| 2055 | Legacy | 21 | 24 |
| 2055 | Non-Legacy | 24 | 27 |
| 2056 | Legacy | <11 | 9 |
| 2056 | Non-Legacy | 15 | 17 |
| 2058 | Legacy | <11 | 2 |
| 2058 | Non-Legacy | <11 | 4 |
| 2059 | Non-Legacy | <11 | 1 |
| 2060 | Non-Legacy | <11 | 1 |
| 2061 | Non-Legacy | <11 | 1 |
| 2063 | Non-Legacy | <11 | 1 |
| 2064 | Non-Legacy | <11 | 1 |
| 2065 | Legacy | <11 | 1 |
| 2065 | Non-Legacy | <11 | 2 |
| 2066 | Legacy | <11 | 10 |
| 2066 | Non-Legacy | 17 | 31 |
| 2067 | Legacy | <11 | 3 |
| 2067 | Non-Legacy | <11 | 4 |
| 2068 | Legacy | <11 | 2 |
| 2068 | Non-Legacy | <11 | 3 |
| 2069 | Legacy | <11 | 2 |
| 2069 | Non-Legacy | <11 | 3 |
| 2070 | Non-Legacy | <11 | 1 |
| 2071 | Non-Legacy | <11 | 1 |
| 2072 | Legacy | <11 | 1 |
| 2072 | Non-Legacy | <11 | 2 |
| 2075 | Legacy | <11 | 6 |
| 2075 | Non-Legacy | <11 | 6 |
| 2076 | Legacy | <11 | 2 |
| 2076 | Non-Legacy | <11 | 7 |
| 2077 | Legacy | <11 | 12 |
| 2077 | Non-Legacy | 14 | 24 |
| 2078 | Legacy | <11 | 2 |
| 2078 | Non-Legacy | <11 | 8 |
| 2079 | Non-Legacy | <11 | 3 |
| 2088 | Non-Legacy | <11 | 1 |
| 3019 | Non-Legacy | <11 | 1 |

### 3e. Data Completeness: Legacy vs Non-Legacy

Percentage of encounters with non-NULL values for key fields.
Differences may indicate what data was carried over in the migration
vs what was left behind.

| Column | Legacy % Non-NULL | Non-Legacy % Non-NULL |
|--------|-------------------|----------------------|
| DISCHARGE_DATE | 100%% | 100%% |
| DISCHARGE_DISPOSITION | 100%% | 67.8%% |
| DISCHARGE_STATUS | 100%% | 100%% |
| PAYER_TYPE_PRIMARY | 0%% | 0%% |
| FACILITY_LOCATION | 100%% | 47.9%% |

### 3f. Linked Data Availability for Legacy Encounters

Do legacy encounters have associated records in other tables?
If legacy encounters DO have linked diagnoses/procedures, that confirms
they are duplicates of the original AllScripts records (not empty shells).

| Linked Table | Legacy Enc w/ Records | Non-Legacy Enc w/ Records |
|--------------|----------------------|--------------------------|
| DIAGNOSIS | 33.4%% | 30.8%% |
| PROCEDURES | 33.2%% | 30.7%% |
| PRESCRIBING | 0%% | 4.4%% |
| LAB_RESULT_CM | 24.4%% | 5.3%% |
| VITAL | 22%% | 7.1%% |

### 3g. Patient EHR Source Coverage

Patients with ALLSCRIPTS_PERSON_ID vs EPIC_PAT_ID in DEMOGRAPHIC,
showing how many patients come from each source system. Patients with
BOTH IDs are those whose AllScripts records were linked to Epic.

| Category | Patients |
|----------|----------|
| Total in DEMOGRAPHIC | 10,091,847 |
| Has ALLSCRIPTS_PERSON_ID | 5,135,058 |
| Has EPIC_PAT_ID | 4,795,014 |
| Has BOTH (linked across systems) | 2,708,310 |

---
## 4. Diagnosis Coding Systems by Year (ICD-9 vs ICD-10)

DX_TYPE values: '09' = ICD-9-CM, '10' = ICD-10-CM, 'SM' = SNOMED, etc.
The US transitioned from ICD-9 to ICD-10 on 2015-10-01. Knowing which
years have which coding system is essential for writing correct SQL.

| Year | DX_TYPE | Distinct Patients | Rows |
|------|---------|-------------------|------|
| 1899 | 09 | <11 | 2 |
| 1900 | 10 | 21,399 | 73,080 |
| 1914 | 09 | <11 | 10 |
| 1917 | 09 | <11 | 2 |
| 1917 | 10 | <11 | 5 |
| 1918 | 09 | <11 | 4 |
| 1918 | 10 | <11 | 7 |
| 1919 | 09 | <11 | 4 |
| 1919 | 10 | <11 | 2 |
| 1920 | 09 | 13 | 31 |
| 1920 | 10 | <11 | 25 |
| 1922 | 09 | <11 | 24 |
| 1923 | 09 | <11 | 9 |
| 1925 | 09 | <11 | 11 |
| 1925 | 10 | <11 | 2 |
| 1926 | 09 | <11 | 1 |
| 1926 | 10 | 13 | 46 |
| 1927 | 09 | <11 | 5 |
| 1928 | 10 | <11 | 4 |
| 1929 | 09 | <11 | 6 |
| 1929 | 10 | <11 | 19 |
| 1930 | 09 | <11 | 5 |
| 1930 | 10 | <11 | 34 |
| 1931 | 09 | <11 | 30 |
| 1931 | 10 | <11 | 13 |
| 1933 | 09 | <11 | 4 |
| 1933 | 10 | <11 | 1 |
| 1934 | 09 | <11 | 5 |
| 1934 | 10 | <11 | 3 |
| 1935 | 09 | <11 | 1 |
| 1935 | 10 | <11 | 6 |
| 1936 | 09 | <11 | 5 |
| 1936 | 10 | <11 | 5 |
| 1937 | 10 | <11 | 2 |
| 1939 | 10 | <11 | 1 |
| 1940 | 09 | <11 | 3 |
| 1941 | 10 | <11 | 1 |
| 1942 | 10 | <11 | 7 |
| 1944 | 10 | <11 | 8 |
| 1945 | 10 | <11 | 6 |
| 1946 | 10 | <11 | 19 |
| 1947 | 09 | <11 | 8 |
| 1947 | 10 | <11 | 2 |
| 1948 | 09 | <11 | 3 |
| 1948 | 10 | <11 | 13 |
| 1949 | 09 | <11 | 3 |
| 1949 | 10 | <11 | 17 |
| 1950 | 09 | <11 | 16 |
| 1950 | 10 | <11 | 3 |
| 1951 | 09 | <11 | 8 |
| 1951 | 10 | <11 | 1 |
| 1952 | 10 | <11 | 14 |
| 1953 | 09 | <11 | 12 |
| 1953 | 10 | <11 | 3 |
| 1954 | 09 | <11 | 3 |
| 1955 | 09 | <11 | 13 |
| 1956 | 09 | <11 | 2 |
| 1956 | 10 | <11 | 11 |
| 1957 | 09 | <11 | 3 |
| 1957 | 10 | <11 | 3 |
| 1958 | 09 | <11 | 2 |
| 1958 | 10 | <11 | 2 |
| 1959 | 10 | <11 | 1 |
| 1960 | 09 | <11 | 7 |
| 1960 | 10 | <11 | 24 |
| 1961 | 10 | <11 | 6 |
| 1962 | 10 | <11 | 1 |
| 1963 | 09 | <11 | 5 |
| 1963 | 10 | <11 | 12 |
| 1965 | 10 | <11 | 4 |
| 1966 | 09 | <11 | 9 |
| 1968 | 10 | <11 | 3 |
| 1969 | 09 | <11 | 5 |
| 1969 | 10 | <11 | 2 |
| 1970 | 10 | <11 | 8 |
| 1971 | 09 | <11 | 2 |
| 1971 | 10 | <11 | 5 |
| 1973 | 09 | <11 | 8 |
| 1974 | 09 | <11 | 4 |
| 1974 | 10 | <11 | 4 |
| 1975 | 09 | <11 | 2 |
| 1976 | 10 | <11 | 3 |
| 1977 | 10 | <11 | 5 |
| 1978 | 10 | <11 | 1 |
| 1979 | 10 | <11 | 1 |
| 1980 | 10 | <11 | 2 |
| 1981 | 09 | <11 | 4 |
| 1981 | 10 | <11 | 7 |
| 1983 | 10 | <11 | 6 |
| 1984 | 09 | <11 | 1 |
| 1984 | 10 | <11 | 2 |
| 1986 | 10 | <11 | 1 |
| 1987 | 09 | <11 | 6 |
| 1987 | 10 | <11 | 1 |
| 1988 | 09 | <11 | 1 |
| 1989 | 09 | <11 | 7 |
| 1989 | 10 | <11 | 1 |
| 1990 | 09 | <11 | 8 |
| 1990 | 10 | <11 | 4 |
| 1991 | 09 | <11 | 5 |
| 1991 | 10 | <11 | 6 |
| 1992 | 09 | <11 | 7 |
| 1992 | 10 | <11 | 3 |
| 1995 | 10 | <11 | 2 |
| 1996 | 09 | <11 | 5 |
| 1997 | 09 | <11 | 1 |
| 1997 | 10 | <11 | 4 |
| 1998 | 09 | <11 | 21 |
| 1999 | 09 | 22 | 67 |
| 2000 | 09 | 8,612 | 36,909 |
| 2000 | 10 | 39 | 127 |
| 2001 | 09 | 20,280 | 104,703 |
| 2001 | 10 | 50 | 152 |
| 2002 | 09 | 45,409 | 208,207 |
| 2002 | 10 | 39 | 154 |
| 2003 | 09 | 47,897 | 209,646 |
| 2003 | 10 | <11 | 7 |
| 2004 | 09 | 62,524 | 297,596 |
| 2004 | 10 | <11 | 10 |
| 2005 | 09 | 180,430 | 1,354,584 |
| 2005 | 10 | 19 | 40 |
| 2006 | 09 | 245,071 | 2,406,082 |
| 2006 | 10 | 82 | 282 |
| 2007 | 09 | 247,056 | 2,497,078 |
| 2007 | 10 | 52 | 164 |
| 2008 | 09 | 257,665 | 2,406,784 |
| 2008 | 10 | 33 | 98 |
| 2009 | 09 | 280,861 | 2,668,128 |
| 2009 | 10 | 32 | 73 |
| 2010 | 09 | 290,218 | 3,011,472 |
| 2010 | 10 | 26 | 64 |
| 2011 | 09 | 300,564 | 3,281,771 |
| 2011 | 10 | 6,058 | 11,672 |
| 2012 | 09 | 345,715 | 3,714,457 |
| 2012 | 10 | 5,965 | 11,282 |
| 2013 | 09 | 409,955 | 4,656,449 |
| 2013 | 10 | 6,597 | 12,744 |
| 2014 | 09 | 478,950 | 5,463,451 |
| 2014 | 10 | 6,407 | 12,815 |
| 2015 | 09 | 448,294 | 4,609,463 |
| 2015 | 10 | 238,043 | 1,771,887 |
| 2015 | UN | <11 | 4 |
| 2016 | 09 | 36 | 52 |
| 2016 | 10 | 591,526 | 8,448,111 |
| 2017 | 09 | 15 | 24 |
| 2017 | 10 | 615,792 | 9,498,540 |
| 2018 | 09 | <11 | 17 |
| 2018 | 10 | 642,083 | 10,460,025 |
| 2019 | 09 | <11 | 10 |
| 2019 | 10 | 654,187 | 11,738,255 |
| 2020 | 09 | <11 | 8 |
| 2020 | 10 | 605,259 | 11,160,792 |
| 2021 | 09 | <11 | 6 |
| 2021 | 10 | 742,480 | 10,822,775 |
| 2022 | 10 | 731,558 | 10,818,513 |
| 2023 | 10 | 767,003 | 11,278,072 |
| 2024 | 10 | 806,221 | 11,713,924 |
| 2025 | 10 | 906,134 | 13,694,524 |
| 2026 | 10 | 428,905 | 3,669,241 |
| 2027 | 10 | 16 | 16 |
| 2028 | 10 | <11 | 2 |
| 2033 | 10 | <11 | 1 |
| 2034 | 10 | <11 | 1 |

---
## 5. Procedure Coding Systems

PX_TYPE values: 'CH' = CPT/HCPCS, '10' = ICD-10-PCS, '09' = ICD-9-CM, 'RE' = Revenue, etc.

| PX_TYPE | Distinct Patients | Rows | Earliest | Latest |
|---------|-------------------|------|----------|--------|
| CH | 4,179,491 | 75,189,598 | 1900-01 | 2026-04 |
| OT | 2,446,313 | 83,600,857 | 1921-05 | 2033-08 |

---
## 6. Lab Results — Top 50 LOINCs by Patient Count

| LAB_LOINC | Patients | Results | Mean | Min | Max |
|-----------|----------|---------|------|-----|-----|
|  | 1,250,042 | 45,393,532 | 2173.49 | -846 | 9999999 |
| 718-7 | 604,651 | 2,890,124 | 12.35 | 0 | 454555 |
| 787-2 | 604,509 | 2,772,910 | 89.5 | 0 | 8109 |
| 2345-7 | 590,036 | 3,308,906 | 115.82 | 0 | 379992 |
| 2160-0 | 572,583 | 3,007,734 | 1.24 | 0.01 | 2175 |
| 3094-0 | 571,138 | 3,004,905 | 18.66 | 0 | 313 |
| 17861-6 | 570,923 | 3,014,397 | 9.26 | 0.8 | 934 |
| 2951-2 | 569,816 | 3,013,991 | 138.83 | 1 | 200 |
| 2823-3 | 569,683 | 3,032,948 | 4.21 | 0 | 307 |
| 2075-0 | 569,683 | 2,995,556 | 102.84 | 0.69 | 1014 |
| 2028-9 | 569,448 | 2,994,443 | 25.62 | 1 | 99 |
| 786-4 | 565,618 | 2,517,595 | 32.67 | 2 | 258.5 |
| 785-6 | 561,488 | 2,506,074 | 29.28 | 1 | 2935 |
| 1975-2 | 554,750 | 2,351,615 | 0.65 | -4 | 212 |
| 2885-2 | 551,604 | 2,361,584 | 7.13 | 0.1 | 2500 |
| 1759-0 | 535,319 | 2,081,312 | 1.31 | -8.3 | 1254 |
| 1751-7 | 534,130 | 2,250,389 | 4.38 | 0 | 5419 |
| 4544-3 | 514,347 | 2,583,605 | 37.14 | 0 | 156 |
| 788-0 | 486,242 | 1,521,743 | 13.94 | 1 | 339 |
| 1742-6 | 484,206 | 1,952,555 | 29.15 | 0 | 123456 |
| 6768-6 | 479,376 | 1,922,708 | 93.28 | 0 | 16251 |
| 6690-2 | 442,262 | 1,525,750 | 7.01 | 0 | 495.5 |
| 789-8 | 440,880 | 1,357,042 | 4.45 | 0 | 2530 |
| 1920-8 | 432,663 | 1,684,334 | 32.6 | 1 | 51573 |
| 706-2 | 424,325 | 1,192,879 | 0.64 | 0 | 71 |
| 3097-3 | 411,232 | 1,246,059 | 17.44 | 0 | 650 |
| 26485-3 | 408,917 | 2,000,718 | 8.26 | 0 | 90.2 |
| 10834-0 | 406,937 | 1,238,604 | 3.02 | -22.5 | 302 |
| 26515-7 | 365,921 | 1,802,094 | 244.42 | 0 | 8682 |
| 32623-1 | 365,616 | 1,798,326 | 10.02 | 0.3 | 298 |
| 777-3 | 355,519 | 1,118,949 | 267.41 | 1 | 3285 |
| 26478-8 | 351,692 | 1,769,628 | 23.74 | 0 | 100 |
| 26511-6 | 351,670 | 1,769,313 | 52.41 | 0 | 445 |
| 26450-7 | 350,864 | 1,760,188 | 2.27 | 0 | 100 |
| 33037-3 | 344,674 | 1,841,669 | 11.57 | -66 | 72 |
| 711-2 | 342,653 | 949,504 | 113.4 | 0 | 20948 |
| 704-7 | 342,631 | 949,445 | 29.19 | 0 | 8600 |
| 742-7 | 342,630 | 949,330 | 365.52 | 0 | 21860 |
| 751-8 | 342,627 | 949,373 | 2.89 | 0 | 166.08 |
| 2093-3 | 337,620 | 1,158,138 | 178.83 | 1 | 8000 |
| 2571-8 | 337,485 | 1,157,751 | 129.68 | 0 | 33333 |
| 4548-4 | 332,556 | 1,164,877 | 6.53 | 0 | 99999 |
| 2085-9 | 332,287 | 960,780 | 54.11 | 0 | 789 |
| 731-0 | 313,844 | 828,990 | 1.58 | 0 | 266.64 |
| 770-8 | 309,618 | 831,853 | 57.87 | 0 | 4896 |
| 713-8 | 278,779 | 707,192 | 2.52 | 0 | 75.9 |
| 736-9 | 278,778 | 701,720 | 30.72 | 0 | 97 |
| 5778-6 | 278,456 | 705,614 | 275.17 | 0 | 5464 |
| 5905-5 | 278,291 | 685,091 | 7.89 | 0 | 339 |
| 20454-5 | 262,402 | 636,131 | 72.09 | 0 | 379992 |

---
## 7. Prescribing — Top 50 Medications (RXNORM_CUI) by Patient Count

| RXNORM_CUI | Patients | Prescriptions | Earliest | Latest |
|------------|----------|---------------|----------|--------|
| 835603 | 117,546 | 203,928 | 2005-05 | 2026-04 |
| 152695 | 98,347 | 170,266 | 2006-08 | 2026-04 |
| 259966 | 94,569 | 131,475 | 2005-06 | 2026-04 |
| 833036 | 68,894 | 149,649 | 2005-04 | 2026-04 |
| 310431 | 67,237 | 139,774 | 2005-06 | 2026-04 |
| 1367410 | 66,050 | 121,581 | 2006-04 | 2026-04 |
| 311681 | 65,389 | 106,898 | 2005-05 | 2026-04 |
| 1010671 | 62,887 | 135,423 | 2006-09 | 2026-04 |
| 311486 | 54,143 | 87,082 | 2006-09 | 2026-04 |
| 1085754 | 52,855 | 111,728 | 2008-05 | 2026-04 |
| 308460 | 50,447 | 83,615 | 2005-12 | 2026-04 |
| 861007 | 49,076 | 146,138 | 2005-05 | 2026-04 |
| 562508 | 48,431 | 73,185 | 2005-07 | 2026-04 |
| 828348 | 46,492 | 73,321 | 2005-05 | 2026-04 |
| 896321 | 44,967 | 55,501 | 2006-05 | 2022-02 |
| 243670 | 44,873 | 47,301 | 2005-04 | 2026-03 |
| 198014 | 44,413 | 65,173 | 2005-04 | 2026-04 |
| 197699 | 43,908 | 79,985 | 2005-06 | 2026-04 |
| 197807 | 42,660 | 62,933 | 2005-05 | 2026-04 |
| 197361 | 41,765 | 89,783 | 2007-04 | 2026-04 |
| 198052 | 41,706 | 55,083 | 2007-02 | 2026-04 |
| 1358610 | 41,222 | 72,019 | 2007-07 | 2026-04 |
| 198334 | 40,638 | 58,395 | 2005-09 | 2026-04 |
| 197806 | 40,141 | 50,157 | 2005-04 | 2026-04 |
| 308416 | 38,357 | 52,511 | 2005-08 | 2026-04 |
| 855633 | 38,265 | 56,144 | 2010-03 | 2026-04 |
| 995258 | 37,669 | 69,326 | 2005-08 | 2026-04 |
| 969588 | 37,436 | 81,344 | 2009-10 | 2026-04 |
| 314200 | 37,256 | 78,492 | 2008-02 | 2026-04 |
| 617310 | 36,678 | 93,251 | 2011-12 | 2026-04 |
| 205323 | 36,554 | 78,952 | 2014-12 | 2026-04 |
| 309114 | 35,747 | 45,658 | 2005-04 | 2026-04 |
| 856377 | 35,484 | 75,241 | 2005-05 | 2026-04 |
| 866924 | 35,410 | 81,793 | 2005-09 | 2026-04 |
| 307782 | 34,896 | 80,702 | 2005-04 | 2026-04 |
| 993781 | 34,456 | 61,462 | 2007-08 | 2026-04 |
| 310430 | 32,838 | 61,161 | 2005-06 | 2026-04 |
| 993890 | 32,611 | 42,454 | 2005-04 | 2022-01 |
| 200329 | 31,945 | 63,040 | 2008-09 | 2026-04 |
| 198145   | 31,840 | 62,772 | 2005-05 | 2026-04 |
| 866514 | 31,320 | 61,593 | 2005-05 | 2026-04 |
| 106346 | 31,234 | 40,542 | 2005-07 | 2026-04 |
| 1012404 | 30,831 | 62,866 | 2012-08 | 2026-04 |
| 312615 | 29,437 | 45,345 | 2005-05 | 2026-04 |
| 308135 | 29,038 | 77,786 | 2007-04 | 2026-04 |
| 309309 | 28,802 | 40,307 | 2005-08 | 2026-04 |
| 617311 | 28,669 | 84,329 | 2011-12 | 2026-04 |
| 198051 | 28,431 | 51,611 | 2005-05 | 2026-04 |
| 313782 | 28,028 | 45,960 | 2005-05 | 2026-04 |
| 253017 | 27,217 | 41,773 | 2006-01 | 2026-04 |

---
## 8. Demographic Distributions

### SEX

| Value | Patients |
|-------|----------|
| F | 5,379,107 |
| M | 4,641,235 |
| NI | 61,957 |
| UN | 9,405 |
| OT | 143 |

### RACE

| Value | Patients |
|-------|----------|
| 05 | 3,211,542 |
| OT | 2,509,231 |
| 03 | 1,517,616 |
| UN | 1,205,507 |
| NI | 1,080,414 |
| 02 | 393,491 |
| 07 | 132,911 |
| 01 | 26,737 |
| 04 | 14,398 |

### HISPANIC

| Value | Patients |
|-------|----------|
| N | 4,929,304 |
| OT | 1,857,350 |
| Y | 1,520,369 |
| NI | 1,093,554 |
| UN | 479,986 |
| R | 211,284 |

---
## 9. Encounter Types

PCORnet ENC_TYPE: AV=Ambulatory, ED=Emergency, EI=ED-to-Inpatient,
IP=Inpatient, IS=Institutional, OS=Outpt Surgery, OA=Other Ambulatory,
TH=Telehealth, NI=No info, UN=Unknown, OT=Other

| ENC_TYPE | Patients | Encounters |
|----------|----------|------------|
| OT | 3,903,053 | 79,826,741 |
| AV | 3,755,017 | 61,016,208 |
| OA | 2,464,599 | 39,275,706 |
| ED | 1,862,539 | 6,262,653 |
| UN | 1,326,034 | 13,022,227 |
| IP | 1,288,344 | 11,776,157 |
| TH | 230,066 | 643,146 |

---
## 10. Vital Signs Completeness

- **HT**: 894,447 patients (4,321,489 measurements)
- **WT**: 914,514 patients (4,776,990 measurements)
- **ORIGINAL_BMI**: 2,360,297 patients (15,468,113 measurements)
- **SYSTOLIC**: 1,223,569 patients (10,117,914 measurements)
- **DIASTOLIC**: 1,223,570 patients (10,117,900 measurements)
- **SMOKING**: 2,549,495 patients (39,508,053 measurements)

### SMOKING Values

| SMOKING | Patients |
|---------|----------|
| UN | 2,544,961 |
| NI | 928,783 |
| 05 | 5,035 |
| OT | 188 |

---
## 11. Death Records

Distinct patients with death records: 113,105
Total rows (may have duplicates per patient): 131,406

### DEATH_SOURCE Values

| DEATH_SOURCE | Patients |
|--------------|----------|
| L | 64,393 |
| D | 38,831 |
| N | 28,182 |

---
## 12. Column Completeness — Key Tables

Percentage of rows where the column is NOT NULL.

### DEMOGRAPHIC (10,091,847 rows)

| Column | % Non-NULL |
|--------|-----------|
| BIRTH_DATE | 100%% |
| SEX | 100%% |
| RACE | 100%% |
| HISPANIC | 100%% |

### PRESCRIBING (16,514,110 rows)

| Column | % Non-NULL |
|--------|-----------|
| RXNORM_CUI | 98.6%% |
| RX_ORDER_DATE | 100%% |
| RX_START_DATE | 100%% |
| RX_END_DATE | 47.6%% |
| RX_QUANTITY | 73.3%% |
| RX_DAYS_SUPPLY | 42.8%% |
| RX_DOSE_ORDERED | 87.5%% |

### DIAGNOSIS (152,125,158 rows)

| Column | % Non-NULL |
|--------|-----------|
| DX | 100%% |
| DX_TYPE | 100%% |
| ADMIT_DATE | 100%% |
| DX_DATE | 91.7%% |
| DX_SOURCE | 100%% |

### LAB_RESULT_CM (182,979,640 rows)

| Column | % Non-NULL |
|--------|-----------|
| LAB_LOINC | 100%% |
| RESULT_NUM | 79.8%% |
| RESULT_QUAL | 100%% |
| RESULT_DATE | 100%% |
| NORM_RANGE_LOW | 65.8%% |
| NORM_RANGE_HIGH | 66.9%% |

---
## 13. Top 30 ICD-10 Diagnosis Codes by Patient Count

| ICD-10 Code | Patients |
|-------------|----------|
| Z23 | 538,499 |
| Z00.00 | 477,110 |
| I10 | 470,276 |
| R07.9 | 250,718 |
| E78.5 | 246,519 |
| Z71.3 | 238,710 |
| Z12.11 | 229,648 |
| M25.561 | 208,054 |
| R94.31 | 202,566 |
| E11.9 | 200,001 |
| K21.9 | 187,109 |
| Z01.419 | 183,238 |
| Z71.82 | 182,791 |
| M25.562 | 178,589 |
| Z12.31 | 177,832 |
| E55.9 | 174,182 |
| R10.9 | 173,367 |
| R06.02 | 161,863 |
| Z00.129 | 160,227 |
| G89.29 | 149,303 |
| Z98.890 | 136,599 |
| K59.00 | 136,140 |
| M54.50 | 133,668 |
| Z09 | 130,719 |
| D64.9 | 127,424 |
| R91.8 | 127,182 |
| R42 | 127,043 |
| J06.9 | 126,227 |
| F41.9 | 126,187 |
| R79.89 | 123,436 |

---
## 14. Prevalence of Clinically Important Conditions

Patient counts for conditions commonly used in TTE study design.
Counts use ICD-10 codes (DX_TYPE = '10'). Patients may appear in
multiple categories.

| Condition | Patients |
|-----------|----------|
| Atrial fibrillation (I48.x) | 86,308 |
| Heart failure (I50.x) | 105,812 |
| Ischemic stroke (I63.x) | 65,747 |
| Type 2 diabetes (E11.x) | 242,522 |
| CKD stage 3 (N18.3x) | 38,009 |
| CKD stage 4 (N18.4) | 13,766 |
| CKD stage 5 (N18.5) | 7,008 |
| ESRD / dialysis (N18.6, Z99.2) | 31,705 |
| Hypertension (I10-I16) | 487,523 |
| COPD (J44.x) | 38,756 |
| Sepsis (R65.2x, A41.x) | 59,018 |
| Dementia (F01-F03, G30) | 29,093 |
| Liver cirrhosis (K74.x) | 21,126 |
| VTE / PE (I26.x, I82.x) | 48,396 |
| Major bleeding (various) | 10,580 |
| Obesity (E66.x) | 242,404 |

---
## 15. Key Medication Classes — Patient Counts

Based on RXNORM_CUI in PRESCRIBING table. Counts are distinct patients
with at least one prescription record.

Search column: **RAW_RX_MED_NAME**

| Medication | Patients | Prescriptions |
|------------|----------|---------------|
| Apixaban | 6,664 | 16,263 |
| Rivaroxaban | 3,410 | 7,652 |
| Dabigatran | 160 | 436 |
| Edoxaban | <11 | 13 |
| Warfarin | 9,689 | 19,130 |
| Amiodarone | 9,070 | 16,291 |
| Flecainide | 3,438 | 8,828 |
| Sotalol | 2,001 | 4,672 |
| Dronedarone | 148 | 335 |
| Dapagliflozin | 3,165 | 9,585 |
| Empagliflozin | 6,526 | 20,145 |
| Canagliflozin | 142 | 380 |
| Metformin | 84,280 | 241,943 |
| Metoprolol | 69,216 | 169,143 |
| Diltiazem | 6,626 | 13,259 |
| Digoxin | 5,069 | 7,754 |
| Semaglutide | 7,053 | 17,373 |

---
## 16. Key Lab LOINCs for TTE Confounders

Patient counts for specific LOINCs commonly needed as confounders or
eligibility criteria in target trial emulations.

| LOINC | Lab Test | Patients | Results |
|-------|----------|----------|---------|
| 2160-0 | Serum creatinine | 572,583 | 3,007,734 |
| 48642-3 | eGFR (CKD-EPI) | 167,036 | 837,059 |
| 33914-3 | eGFR (MDRD) | 36,067 | 98,391 |
| 4548-4 | HbA1c | 332,556 | 1,164,877 |
| 2093-3 | Total cholesterol | 337,620 | 1,158,138 |
| 2571-8 | Triglycerides | 337,485 | 1,157,751 |
| 2085-9 | HDL cholesterol | 332,287 | 960,780 |
| 13457-7 | LDL cholesterol (calc) | 242,238 | 744,557 |
| 718-7 | Hemoglobin | 604,651 | 2,890,124 |
| 777-3 | Platelets | 355,519 | 1,118,949 |
| 6299-2 | BUN | 2,915 | 3,719 |
| 2823-3 | Potassium | 569,683 | 3,032,948 |
| 2951-2 | Sodium | 569,816 | 3,013,991 |
| 1742-6 | ALT | 484,206 | 1,952,555 |
| 1920-8 | AST | 432,663 | 1,684,334 |
| 1975-2 | Total bilirubin | 554,750 | 2,351,615 |
| 6598-7 | Troponin T | 297 | 345 |
| 49563-0 | Troponin I (HS) | <11 | 0 |
| 30313-1 | INR | <11 | 0 |
| 33762-6 | NT-proBNP | 4,714 | 9,286 |

