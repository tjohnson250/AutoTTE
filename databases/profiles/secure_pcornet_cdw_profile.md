# CDW Data Profile for AutoTTE
# Generated: 2026-04-20 22:22:45.952115
# Schema: dbo
# NOTE: This file contains ONLY aggregate counts. No PHI (PATIDs, dates
#       of service, etc.) is included. Counts < 11 are suppressed.

---
## 1. Overall CDW Size and Temporal Coverage

Total distinct patients in DEMOGRAPHIC: 10,115,953

| Table | Distinct Patients | Rows | Earliest (YYYY-MM) | Latest (YYYY-MM) |
|-------|-------------------|------|---------------------|-------------------|
| ENCOUNTER | 5,328,788 | 212,662,728 | 1820-11 | 3019-03 |
| DIAGNOSIS | 4,406,750 | 152,762,547 | 1899-12 | 2034-03 |
| PROCEDURES | 4,488,078 | 159,962,108 | 1900-01 | 2033-08 |
| PRESCRIBING | 1,297,960 | 16,616,419 | 2004-04 | 2026-04 |
| DISPENSING | 1,280,825 | 64,779,762 | 2006-12 | 2026-04 |
| LAB_RESULT_CM | 1,472,172 | 184,098,068 | 1900-01 | 2026-04 |
| VITAL | 2,562,931 | 39,607,699 | 1754-01 | 2026-06 |
| MED_ADMIN | 159,760 | 4,930,942 | 2021-04 | 2026-04 |
| CONDITION | 1,482,895 | 26,872,118 | 1842-01 | 2026-04 |
| DEATH | 113,415 | 131,720 | 1926-12 | 2026-04 |
| ENROLLMENT | 5,327,758 | 5,327,758 | 2000-01 | 2026-04 |

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
| 2011 | 366,203 | 3,126,241 |
| 2012 | 405,360 | 3,659,639 |
| 2013 | 481,777 | 4,754,855 |
| 2014 | 566,838 | 5,577,338 |
| 2015 | 627,471 | 6,568,100 |
| 2016 | 697,382 | 8,741,077 |
| 2017 | 772,831 | 13,012,540 |
| 2018 | 830,825 | 16,071,317 |
| 2019 | 854,455 | 18,498,589 |
| 2020 | 799,776 | 15,561,312 |
| 2021 | 2,766,077 | 21,103,804 |
| 2022 | 1,040,368 | 18,163,698 |
| 2023 | 1,060,570 | 19,024,329 |
| 2024 | 1,073,327 | 19,560,880 |
| 2025 | 1,104,676 | 17,361,926 |
| 2026 | 610,754 | 6,086,962 |
| 2027 | 18,916 | 30,653 |
| 2028 | 65 | 124 |
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
| 2066 | 21 | 42 |
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
| [TX:PB] | 1,546,902 | 20,834,893 |
| Appointment | 2,371,372 | 18,668,758 |
| CDA | 792,315 | 14,868,953 |
| Legacy Encounter | 1,251,510 | 12,782,057 |
| INPATIENT | 896,943 | 10,153,795 |
| Image Encounter | 1,307,532 | 9,751,118 |
| EXT HHS OP | 402,840 | 8,721,706 |
| History | 3,130,372 | 7,869,251 |
| Lab Encounter | 761,100 | 6,895,577 |
| Travel | 1,040,850 | 6,418,817 |
| Chart Update | 634,228 | 5,932,707 |
| [IMM] | 682,314 | 5,046,758 |
| Telephone | 743,587 | 4,251,386 |
| EMERGENCY ROOM | 1,012,060 | 4,111,045 |
| EXT MHH OP | 869,183 | 3,919,988 |
| Reconciled Outside Data | 1,087,396 | 3,824,495 |
| Transcription Encounter | 865,980 | 3,754,563 |
| Office Visit | 901,036 | 3,753,217 |
| AUDIT | 460,211 | 3,446,932 |
| Orders Only | 591,063 | 2,711,063 |
| Result Review | 500,509 | 2,512,004 |
| Patient Message | 386,965 | 2,379,626 |
| Refill | 302,962 | 2,313,739 |
| Scanned Document | 510,429 | 2,219,035 |
| EXT MHH ED | 886,864 | 1,777,639 |
| Wait List | 664,988 | 1,715,462 |
| Telephone Call | 443,098 | 1,687,880 |
| Result Charge | 104,655 | 1,622,863 |
| Rx Renewal | 170,599 | 1,490,637 |
| Procedure Pass | 501,406 | 1,445,351 |
| EXT MHH IP | 399,025 | 1,439,860 |
| Ancillary Procedure | 461,138 | 1,220,788 |
| Non-Appointment | 57,966 | 731,074 |
| Billing Encounter | 206,870 | 557,197 |
| Letter (Out) | 226,307 | 479,144 |
| EXT HHS ED | 199,042 | 397,968 |
| Patient Outreach | 75,159 | 360,646 |
| Transcribe Orders | 254,094 | 354,777 |
| Results Follow-Up | 164,266 | 342,593 |
| Other | 146,726 | 335,984 |
| Telemedicine | 103,546 | 304,137 |
| Clinical Encounter | 121,616 | 278,463 |
| Abstract | 137,204 | 252,518 |
| Documentation | 124,203 | 249,647 |
| (NULL) | 110,903 | 240,226 |
| [PROBLEM] | 42,866 | 212,623 |
| OurPractice Advisory | 153,625 | 207,014 |
| Message | 78,005 | 195,292 |
| Ancillary Orders | 100,710 | 189,690 |
| Nurse Triage | 76,403 | 186,989 |
| Procedure Visit | 79,823 | 168,304 |
| Hospital Encounter | 75,867 | 154,051 |
| Routine Prenatal | 22,955 | 147,488 |
| Form Encounter | 85,039 | 142,956 |
| Chart Copy | 53,506 | 123,953 |
| Plan of Care Documentation | 28,586 | 114,506 |
| EXT MHHS PR | 87,219 | 105,443 |
| External Contact | 47,448 | 100,270 |
| Intake | 56,512 | 98,850 |
| Clinical Documentation Only | 65,725 | 79,494 |
| Nurse Only | 40,710 | 65,993 |
| Rx Change | 23,068 | 60,278 |
| EXT HHS IP | 23,377 | 45,568 |
| Immunization | 25,842 | 36,430 |
| Consult | 29,918 | 34,666 |
| Telephonic Encounter | 24,826 | 34,537 |
| Clinical Support | 17,598 | 32,968 |
| Postpartum Visit | 17,625 | 29,132 |
| Nutrition | 11,448 | 24,858 |
| Initial Prenatal | 21,138 | 24,121 |
| Questionnaire Series Submission | 8,677 | 22,237 |
| Education | 15,852 | 22,112 |
| External Contacts | 17,629 | 20,910 |
| Social Work | 6,112 | 20,684 |
| Diabetes Education | 7,649 | 17,034 |
| Outside Procedure | 8,296 | 12,046 |
| EXT MHHS NP | 9,578 | 11,913 |
| Evaluation | 8,698 | 11,564 |
| Charges | 6,815 | 9,912 |
| Employee Health | 4,733 | 6,045 |
| EMPTY | 5,088 | 5,890 |
| Medication Management | 1,448 | 5,029 |
| Treatment | 1,838 | 3,645 |
| Lab Requisition | 3,111 | 3,589 |
| Contact Moved | 407 | 3,587 |
| E Health Visit Old | 3,154 | 3,557 |
| External Hospital Admission | 2,303 | 2,897 |
| Lab | 2,366 | 2,876 |
| Remote Monitoring Data Collection | 464 | 1,549 |
|  | 1,471 | 1,517 |
| Prep for Procedure | 1,100 | 1,181 |
| Community Orders | 667 | 891 |
| Home Monitoring | 49 | 409 |
| Patient Self-Triage | 227 | 279 |
| ADMINISTRATIVE UNAPP ACCOUNT | 78 | 248 |
| IPat Visit | 137 | 193 |
| Anticoagulation - Warfarin Visit | 90 | 155 |
| Unmerge | 145 | 155 |
| Cardiology Conference | 111 | 125 |
| Post Mortem Documentation | 94 | 111 |
| E-Visit | 87 | 99 |
| Recurring Plan | 19 | 95 |
| Mother Baby Link | 89 | 90 |
| Anticoagulation - Other Visit (DOAC) | 31 | 32 |
| Biometric Visit | 17 | 23 |
| Lactation Encounter | 20 | 20 |
| Multidisciplinary Visit | 12 | 12 |
| E-Consult | <11 | 8 |
| Lactation Consult | <11 | 6 |
| Hospice F2F Visit | <11 | 6 |
| Specialty Pharmacy | <11 | 6 |
| Episode Changes | <11 | 3 |
| EXT HHS NP | <11 | 2 |
| Deleted | <11 | 2 |
| Consent Form | <11 | 1 |
| Canceled | <11 | 1 |
| Hospital | <11 | 1 |

### 3b. IS_LEGACY_IMPORT Distribution

| IS_LEGACY_IMPORT | Patients | Encounters |
|------------------|----------|------------|
| N | 5,328,788 | 201,267,436 |
| Y | 1,078,826 | 11,395,292 |

### Cross-tab: RAW_ENC_TYPE vs IS_LEGACY_IMPORT

Verifies whether the two legacy flags align.

| RAW_ENC_TYPE | IS_LEGACY_IMPORT | Encounters |
|--------------|------------------|------------|
| History | Y | 11,424 |
| Legacy Encounter | N | 1,398,189 |
| Legacy Encounter | Y | 11,383,868 |

### 3c. CDW_Source Distribution (ENCOUNTER)

Shows which source system feeds each encounter. Multiple CDW_Source
values in the same year range may indicate overlapping feeds.

| CDW_Source | Patients | Encounters | Earliest | Latest |
|-----------|----------|------------|----------|--------|
| EPIC | 4,129,040 | 108,896,453 | 1900-01 | 2088-12 |
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
| 2011 | Non-Legacy | 366,023 | 3,122,145 |
| 2012 | Legacy | 4,171 | 6,393 |
| 2012 | Non-Legacy | 405,104 | 3,653,246 |
| 2013 | Legacy | 5,665 | 8,938 |
| 2013 | Non-Legacy | 481,390 | 4,745,917 |
| 2014 | Legacy | 8,520 | 13,282 |
| 2014 | Non-Legacy | 566,233 | 5,564,056 |
| 2015 | Legacy | 11,367 | 18,163 |
| 2015 | Non-Legacy | 626,818 | 6,549,937 |
| 2016 | Legacy | 231,872 | 652,606 |
| 2016 | Non-Legacy | 684,640 | 8,088,471 |
| 2017 | Legacy | 340,016 | 1,209,970 |
| 2017 | Non-Legacy | 751,010 | 11,802,570 |
| 2018 | Legacy | 430,714 | 2,692,085 |
| 2018 | Non-Legacy | 802,133 | 13,379,232 |
| 2019 | Legacy | 455,292 | 3,406,587 |
| 2019 | Non-Legacy | 820,888 | 15,092,002 |
| 2020 | Legacy | 440,405 | 3,220,228 |
| 2020 | Non-Legacy | 761,385 | 12,341,084 |
| 2021 | Legacy | 389,317 | 1,493,932 |
| 2021 | Non-Legacy | 2,759,650 | 19,609,872 |
| 2022 | Legacy | 13,879 | 16,542 |
| 2022 | Non-Legacy | 1,032,187 | 18,147,156 |
| 2023 | Legacy | 12,165 | 14,527 |
| 2023 | Non-Legacy | 1,051,427 | 19,009,802 |
| 2024 | Legacy | 8,552 | 9,724 |
| 2024 | Non-Legacy | 1,067,021 | 19,551,156 |
| 2025 | Legacy | 4,111 | 4,311 |
| 2025 | Non-Legacy | 1,101,753 | 17,357,615 |
| 2026 | Legacy | 16 | 21 |
| 2026 | Non-Legacy | 610,754 | 6,086,941 |
| 2027 | Legacy | 12 | 15 |
| 2027 | Non-Legacy | 18,916 | 30,638 |
| 2028 | Legacy | 26 | 35 |
| 2028 | Non-Legacy | 64 | 89 |
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
| 2066 | Non-Legacy | 18 | 32 |
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
| DISCHARGE_DISPOSITION | 100%% | 68%% |
| DISCHARGE_STATUS | 100%% | 100%% |
| PAYER_TYPE_PRIMARY | 0%% | 0%% |
| FACILITY_LOCATION | 100%% | 48.1%% |

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
| VITAL | 22%% | 7.2%% |

### 3g. Patient EHR Source Coverage

Patients with ALLSCRIPTS_PERSON_ID vs EPIC_PAT_ID in DEMOGRAPHIC,
showing how many patients come from each source system. Patients with
BOTH IDs are those whose AllScripts records were linked to Epic.

| Category | Patients |
|----------|----------|
| Total in DEMOGRAPHIC | 10,115,953 |
| Has ALLSCRIPTS_PERSON_ID | 5,135,058 |
| Has EPIC_PAT_ID | 4,812,201 |
| Has BOTH (linked across systems) | 2,710,780 |

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
| 2021 | 10 | 742,480 | 10,822,928 |
| 2022 | 10 | 731,559 | 10,818,746 |
| 2023 | 10 | 767,015 | 11,278,403 |
| 2024 | 10 | 806,227 | 11,714,281 |
| 2025 | 10 | 906,148 | 13,695,512 |
| 2026 | 10 | 468,217 | 4,304,556 |
| 2027 | 10 | 23 | 28 |
| 2028 | 10 | <11 | 2 |
| 2033 | 10 | <11 | 1 |
| 2034 | 10 | <11 | 1 |

---
## 5. Procedure Coding Systems

PX_TYPE values: 'CH' = CPT/HCPCS, '10' = ICD-10-PCS, '09' = ICD-9-CM, 'RE' = Revenue, etc.

| PX_TYPE | Distinct Patients | Rows | Earliest | Latest |
|---------|-------------------|------|----------|--------|
| CH | 4,189,612 | 75,445,764 | 1900-01 | 2026-04 |
| OT | 2,459,246 | 84,516,344 | 1921-05 | 2033-08 |

---
## 6. Lab Results — Top 50 LOINCs by Patient Count

| LAB_LOINC | Patients | Results | Mean | Min | Max |
|-----------|----------|---------|------|-----|-----|
|  | 1,253,559 | 45,487,675 | 2173.48 | -846 | 9999999 |
| 718-7 | 607,799 | 2,912,112 | 12.35 | 0 | 454555 |
| 787-2 | 607,599 | 2,794,111 | 89.5 | 0 | 8109 |
| 2345-7 | 593,296 | 3,336,731 | 115.84 | 0 | 379992 |
| 2160-0 | 575,817 | 3,034,279 | 1.24 | 0.01 | 2175 |
| 3094-0 | 574,374 | 3,031,315 | 18.68 | 0 | 313 |
| 17861-6 | 574,151 | 3,040,876 | 9.26 | 0.8 | 934 |
| 2951-2 | 573,048 | 3,040,626 | 138.83 | 1 | 200 |
| 2075-0 | 572,916 | 3,021,914 | 102.84 | 0.69 | 1014 |
| 2823-3 | 572,914 | 3,059,953 | 4.21 | 0 | 307 |
| 2028-9 | 572,678 | 3,020,810 | 25.62 | 1 | 99 |
| 786-4 | 568,750 | 2,538,712 | 32.67 | 2 | 258.5 |
| 785-6 | 564,623 | 2,527,275 | 29.28 | 1 | 2935 |
| 1975-2 | 557,881 | 2,370,586 | 0.65 | -4 | 212 |
| 2885-2 | 554,734 | 2,380,708 | 7.13 | 0.1 | 2500 |
| 1759-0 | 538,248 | 2,098,083 | 1.31 | -8.3 | 1254 |
| 1751-7 | 536,854 | 2,266,390 | 4.38 | 0 | 5419 |
| 4544-3 | 517,555 | 2,605,656 | 37.13 | 0 | 156 |
| 788-0 | 488,263 | 1,530,551 | 13.93 | 1 | 339 |
| 1742-6 | 487,414 | 1,971,818 | 29.18 | 0 | 123456 |
| 6768-6 | 482,541 | 1,941,723 | 93.31 | 0 | 16251 |
| 6690-2 | 443,977 | 1,533,069 | 7.01 | 0 | 495.5 |
| 789-8 | 442,597 | 1,364,437 | 4.45 | 0 | 2530 |
| 1920-8 | 435,934 | 1,703,603 | 32.7 | 1 | 51573 |
| 706-2 | 426,296 | 1,200,958 | 0.64 | 0 | 71 |
| 3097-3 | 413,065 | 1,253,965 | 17.44 | 0 | 650 |
| 26485-3 | 410,535 | 2,014,041 | 8.26 | 0 | 90.2 |
| 10834-0 | 408,743 | 1,246,211 | 3.01 | -22.5 | 302 |
| 26515-7 | 367,637 | 1,815,850 | 244.38 | 0 | 8682 |
| 32623-1 | 367,332 | 1,812,057 | 10.03 | 0.3 | 298 |
| 777-3 | 357,287 | 1,126,344 | 267.48 | 1 | 3285 |
| 26478-8 | 353,331 | 1,782,951 | 23.73 | 0 | 100 |
| 26511-6 | 353,309 | 1,782,636 | 52.52 | 0 | 445 |
| 26450-7 | 352,503 | 1,773,501 | 2.27 | 0 | 100 |
| 33037-3 | 346,660 | 1,859,891 | 11.56 | -66 | 72 |
| 711-2 | 344,699 | 957,917 | 113.2 | 0 | 20948 |
| 704-7 | 344,677 | 957,857 | 29.12 | 0 | 8600 |
| 742-7 | 344,676 | 957,742 | 364.77 | 0 | 21860 |
| 751-8 | 344,673 | 957,785 | 2.89 | 0 | 166.08 |
| 2093-3 | 338,974 | 1,163,109 | 178.83 | 1 | 8000 |
| 2571-8 | 338,878 | 1,162,846 | 129.65 | 0 | 33333 |
| 4548-4 | 335,392 | 1,172,747 | 6.52 | 0 | 99999 |
| 2085-9 | 333,649 | 965,742 | 54.11 | 0 | 789 |
| 731-0 | 315,253 | 833,944 | 1.58 | 0 | 266.64 |
| 770-8 | 311,392 | 839,043 | 57.88 | 0 | 4896 |
| 713-8 | 280,606 | 714,438 | 2.52 | 0 | 75.9 |
| 736-9 | 280,605 | 708,909 | 30.71 | 0 | 97 |
| 5905-5 | 280,118 | 692,337 | 7.89 | 0 | 339 |
| 5778-6 | 279,401 | 708,253 | 275.17 | 0 | 5464 |
| 20454-5 | 263,629 | 640,042 | 72.08 | 0 | 379992 |

---
## 7. Prescribing — Top 50 Medications (RXNORM_CUI) by Patient Count

| RXNORM_CUI | Patients | Prescriptions | Earliest | Latest |
|------------|----------|---------------|----------|--------|
| 835603 | 117,898 | 204,801 | 2005-05 | 2026-04 |
| 152695 | 98,825 | 171,403 | 2006-08 | 2026-04 |
| 259966 | 95,052 | 132,223 | 2005-06 | 2026-04 |
| 833036 | 69,303 | 150,738 | 2005-04 | 2026-04 |
| 310431 | 67,553 | 140,775 | 2005-06 | 2026-04 |
| 1367410 | 66,339 | 122,247 | 2006-04 | 2026-04 |
| 311681 | 65,659 | 107,449 | 2005-05 | 2026-04 |
| 1010671 | 63,352 | 136,608 | 2006-09 | 2026-04 |
| 311486 | 54,355 | 87,498 | 2006-09 | 2026-04 |
| 1085754 | 53,333 | 112,979 | 2008-05 | 2026-04 |
| 308460 | 50,557 | 83,856 | 2005-12 | 2026-04 |
| 861007 | 49,248 | 147,228 | 2005-05 | 2026-04 |
| 562508 | 48,681 | 73,634 | 2005-07 | 2026-04 |
| 828348 | 46,629 | 73,656 | 2005-05 | 2026-04 |
| 896321 | 44,967 | 55,501 | 2006-05 | 2022-02 |
| 243670 | 44,873 | 47,301 | 2005-04 | 2026-03 |
| 198014 | 44,538 | 65,449 | 2005-04 | 2026-04 |
| 197699 | 44,103 | 80,461 | 2005-06 | 2026-04 |
| 197807 | 42,813 | 63,235 | 2005-05 | 2026-04 |
| 198052 | 41,952 | 55,482 | 2007-02 | 2026-04 |
| 197361 | 41,872 | 90,323 | 2007-04 | 2026-04 |
| 1358610 | 41,402 | 72,389 | 2007-07 | 2026-04 |
| 198334 | 40,843 | 58,727 | 2005-09 | 2026-04 |
| 197806 | 40,313 | 50,444 | 2005-04 | 2026-04 |
| 308416 | 38,514 | 52,812 | 2005-08 | 2026-04 |
| 855633 | 38,415 | 56,377 | 2010-03 | 2026-04 |
| 995258 | 38,027 | 70,152 | 2005-08 | 2026-04 |
| 969588 | 37,830 | 82,263 | 2009-10 | 2026-04 |
| 314200 | 37,405 | 79,046 | 2008-02 | 2026-04 |
| 205323 | 36,808 | 79,649 | 2014-12 | 2026-04 |
| 617310 | 36,769 | 93,854 | 2011-12 | 2026-04 |
| 309114 | 35,909 | 45,900 | 2005-04 | 2026-04 |
| 856377 | 35,713 | 75,920 | 2005-05 | 2026-04 |
| 866924 | 35,495 | 82,286 | 2005-09 | 2026-04 |
| 307782 | 35,089 | 81,324 | 2005-04 | 2026-04 |
| 993781 | 34,658 | 61,883 | 2007-08 | 2026-04 |
| 310430 | 33,016 | 61,636 | 2005-06 | 2026-04 |
| 993890 | 32,611 | 42,454 | 2005-04 | 2022-01 |
| 200329 | 32,074 | 63,483 | 2008-09 | 2026-04 |
| 198145   | 31,943 | 62,979 | 2005-05 | 2026-04 |
| 106346 | 31,373 | 40,773 | 2005-07 | 2026-04 |
| 866514 | 31,356 | 61,869 | 2005-05 | 2026-04 |
| 1012404 | 31,017 | 63,364 | 2012-08 | 2026-04 |
| 312615 | 29,533 | 45,556 | 2005-05 | 2026-04 |
| 308135 | 29,106 | 78,247 | 2007-04 | 2026-04 |
| 309309 | 28,865 | 40,424 | 2005-08 | 2026-04 |
| 617311 | 28,779 | 84,954 | 2011-12 | 2026-04 |
| 198051 | 28,518 | 51,904 | 2005-05 | 2026-04 |
| 313782 | 28,338 | 46,551 | 2005-05 | 2026-04 |
| 253017 | 27,520 | 42,301 | 2006-01 | 2026-04 |

---
## 8. Demographic Distributions

### SEX

| Value | Patients |
|-------|----------|
| F | 5,391,765 |
| M | 4,652,440 |
| NI | 62,198 |
| UN | 9,407 |
| OT | 143 |

### RACE

| Value | Patients |
|-------|----------|
| 05 | 3,216,143 |
| OT | 2,518,361 |
| 03 | 1,521,123 |
| UN | 1,207,618 |
| NI | 1,086,976 |
| 02 | 394,468 |
| 07 | 130,178 |
| 01 | 26,634 |
| 04 | 14,452 |

### HISPANIC

| Value | Patients |
|-------|----------|
| N | 4,927,021 |
| OT | 1,872,682 |
| Y | 1,523,184 |
| NI | 1,102,110 |
| UN | 479,672 |
| R | 211,284 |

---
## 9. Encounter Types

PCORnet ENC_TYPE: AV=Ambulatory, ED=Emergency, EI=ED-to-Inpatient,
IP=Inpatient, IS=Institutional, OS=Outpt Surgery, OA=Other Ambulatory,
TH=Telehealth, NI=No info, UN=Unknown, OT=Other

| ENC_TYPE | Patients | Encounters |
|----------|----------|------------|
| OT | 3,913,370 | 80,271,142 |
| AV | 3,765,234 | 61,299,436 |
| OA | 2,470,546 | 39,341,274 |
| ED | 1,868,769 | 6,286,652 |
| UN | 1,326,055 | 13,022,283 |
| IP | 1,292,098 | 11,796,365 |
| TH | 231,055 | 645,576 |

---
## 10. Vital Signs Completeness

- **HT**: 894,447 patients (4,321,489 measurements)
- **WT**: 914,514 patients (4,776,990 measurements)
- **ORIGINAL_BMI**: 2,373,048 patients (15,562,994 measurements)
- **SYSTOLIC**: 1,227,884 patients (10,150,761 measurements)
- **DIASTOLIC**: 1,227,885 patients (10,150,747 measurements)
- **SMOKING**: 2,562,931 patients (39,607,699 measurements)

### SMOKING Values

| SMOKING | Patients |
|---------|----------|
| UN | 2,558,402 |
| NI | 928,783 |
| 05 | 5,035 |
| OT | 188 |

---
## 11. Death Records

Distinct patients with death records: 113,415
Total rows (may have duplicates per patient): 131,720

### DEATH_SOURCE Values

| DEATH_SOURCE | Patients |
|--------------|----------|
| L | 64,707 |
| D | 38,831 |
| N | 28,182 |

### DEATH_CAUSE Table

Distinct patients with cause-of-death records: <11
Total rows: 0
Coverage vs DEATH: 0.0% of deceased patients have = 1 DEATH_CAUSE row

---
## 12. Column Completeness — Key Tables

Percentage of rows where the column is NOT NULL.

### DEMOGRAPHIC (10,115,953 rows)

| Column | % Non-NULL |
|--------|-----------|
| BIRTH_DATE | 100%% |
| SEX | 100%% |
| RACE | 100%% |
| HISPANIC | 100%% |

### PRESCRIBING (16,616,419 rows)

| Column | % Non-NULL |
|--------|-----------|
| RXNORM_CUI | 98.6%% |
| RX_ORDER_DATE | 100%% |
| RX_START_DATE | 100%% |
| RX_END_DATE | 47.6%% |
| RX_QUANTITY | 73.3%% |
| RX_DAYS_SUPPLY | 42.5%% |
| RX_DOSE_ORDERED | 87.5%% |

### DIAGNOSIS (152,762,547 rows)

| Column | % Non-NULL |
|--------|-----------|
| DX | 100%% |
| DX_TYPE | 100%% |
| ADMIT_DATE | 100%% |
| DX_DATE | 91.7%% |
| DX_SOURCE | 100%% |

### LAB_RESULT_CM (184,098,068 rows)

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
| Z23 | 539,761 |
| Z00.00 | 478,690 |
| I10 | 471,736 |
| R07.9 | 251,989 |
| E78.5 | 247,360 |
| Z71.3 | 239,665 |
| Z12.11 | 230,913 |
| M25.561 | 209,017 |
| R94.31 | 202,745 |
| E11.9 | 200,524 |
| K21.9 | 187,845 |
| Z01.419 | 184,079 |
| Z71.82 | 183,619 |
| M25.562 | 179,370 |
| Z12.31 | 178,638 |
| E55.9 | 175,063 |
| R10.9 | 174,055 |
| R06.02 | 162,657 |
| Z00.129 | 160,538 |
| G89.29 | 150,241 |
| Z98.890 | 137,413 |
| K59.00 | 136,838 |
| M54.50 | 134,650 |
| Z09 | 131,374 |
| D64.9 | 128,118 |
| R42 | 127,990 |
| R91.8 | 127,290 |
| F41.9 | 126,800 |
| J06.9 | 126,761 |
| R79.89 | 124,416 |

---
## 14. Prevalence of Clinically Important Conditions

Patient counts for conditions commonly used in TTE study design.
Counts use ICD-10 codes (DX_TYPE = '10'). Patients may appear in
multiple categories.

| Condition | Patients |
|-----------|----------|
| Atrial fibrillation (I48.x) | 86,675 |
| Heart failure (I50.x) | 106,440 |
| Ischemic stroke (I63.x) | 66,107 |
| Type 2 diabetes (E11.x) | 243,267 |
| CKD stage 3 (N18.3x) | 38,237 |
| CKD stage 4 (N18.4) | 13,833 |
| CKD stage 5 (N18.5) | 7,048 |
| ESRD / dialysis (N18.6, Z99.2) | 31,836 |
| Hypertension (I10-I16) | 489,069 |
| COPD (J44.x) | 38,898 |
| Sepsis (R65.2x, A41.x) | 59,459 |
| Dementia (F01-F03, G30) | 29,270 |
| Liver cirrhosis (K74.x) | 21,237 |
| VTE / PE (I26.x, I82.x) | 48,658 |
| Major bleeding (various) | 10,640 |
| Obesity (E66.x) | 243,544 |

---
## 15. Key Medication Classes — Patient Counts

Based on RXNORM_CUI in PRESCRIBING table. Counts are distinct patients
with at least one prescription record.

Search column: **RAW_RX_MED_NAME**

| Medication | Patients | Prescriptions |
|------------|----------|---------------|
| Apixaban | 6,735 | 16,462 |
| Rivaroxaban | 3,423 | 7,700 |
| Dabigatran | 163 | 444 |
| Edoxaban | <11 | 13 |
| Warfarin | 9,692 | 19,160 |
| Amiodarone | 9,100 | 16,384 |
| Flecainide | 3,445 | 8,873 |
| Sotalol | 2,002 | 4,704 |
| Dronedarone | 150 | 338 |
| Dapagliflozin | 3,194 | 9,699 |
| Empagliflozin | 6,591 | 20,398 |
| Canagliflozin | 142 | 380 |
| Metformin | 84,460 | 243,404 |
| Metoprolol | 69,323 | 170,037 |
| Diltiazem | 6,639 | 13,307 |
| Digoxin | 5,073 | 7,774 |
| Semaglutide | 7,175 | 17,674 |

---
## 16. Key Lab LOINCs for TTE Confounders

Patient counts for specific LOINCs commonly needed as confounders or
eligibility criteria in target trial emulations.

| LOINC | Lab Test | Patients | Results |
|-------|----------|----------|---------|
| 2160-0 | Serum creatinine | 575,817 | 3,034,279 |
| 48642-3 | eGFR (CKD-EPI) | 167,744 | 840,787 |
| 33914-3 | eGFR (MDRD) | 36,269 | 98,966 |
| 4548-4 | HbA1c | 335,392 | 1,172,747 |
| 2093-3 | Total cholesterol | 338,974 | 1,163,109 |
| 2571-8 | Triglycerides | 338,878 | 1,162,846 |
| 2085-9 | HDL cholesterol | 333,649 | 965,742 |
| 13457-7 | LDL cholesterol (calc) | 243,407 | 749,076 |
| 718-7 | Hemoglobin | 607,799 | 2,912,112 |
| 777-3 | Platelets | 357,287 | 1,126,344 |
| 6299-2 | BUN | 2,948 | 3,768 |
| 2823-3 | Potassium | 572,914 | 3,059,953 |
| 2951-2 | Sodium | 573,048 | 3,040,626 |
| 1742-6 | ALT | 487,414 | 1,971,818 |
| 1920-8 | AST | 435,934 | 1,703,603 |
| 1975-2 | Total bilirubin | 557,881 | 2,370,586 |
| 6598-7 | Troponin T | 301 | 349 |
| 49563-0 | Troponin I (HS) | <11 | 0 |
| 30313-1 | INR | <11 | 0 |
| 33762-6 | NT-proBNP | 4,777 | 9,396 |


---
# MPI Database (linkage and source coverage)
# Generated: 2026-04-21 06:04:47.422449
# Schema: dbo
# NOTE: This section contains ONLY aggregate counts and source-system
#       definitions. Patient-identifying columns (name, SSN, DOB,
#       address, phone) are NEVER queried. Counts < 11 are suppressed.

## M1. MPI Table Row Counts

| Table | Rows |
|-------|------|
| EnterpriseRecords | 15,884,973 |
| EnterpriseRecords_Ext | 10,115,910 |
| Mpi | 36,925,795 |
| MPI_Src | 15 |

## M2. Source-System Inventory (MPI_Src)

Full dump of MPI_Src — this table holds source-system definitions,
not patient records.

```

```

## M3. Distinct Patients (Uid)

Distinct Uids in EnterpriseRecords: 15,884,973

## M4. Source-System ID Coverage (EnterpriseRecords_Ext)

Percentage of EnterpriseRecords_Ext rows with a non-NULL source ID.

Total rows: 10,115,910

| Source ID Column | Non-NULL Rows | % Coverage |
|------------------|---------------|------------|
| EPIC_PAT_ID | 4,827,200 | 47.7% |
| ALLSCRIPTS_PERSON_ID | 5,135,058 | 50.8% |
| MHH_MRN | 6,941,748 | 68.6% |
| UTP_MRN | 7,336,385 | 72.5% |

## M5. EPIC × ALLSCRIPTS Overlap

Counts of EnterpriseRecords_Ext patients by which legacy/current EHR
system they appear in. Drives expectations for legacy-encounter
filtering in CDW queries.

| Category | Patients |
|----------|----------|
| Has EPIC and ALLSCRIPTS  | 2,720,910 |
| Has EPIC only            | 2,106,290 |
| Has ALLSCRIPTS only      | 2,414,148 |
| Has neither              | 2,874,562 |
