*********************************************************************
PROJECT: Mental Health and Injury
AUTHOR: B. Milne (adapted from S. D'Souza & L. Richmond-Rakerd)
IDI Refresh: IDI_Clean_20211020

Disclaimer: The results in this report are not official statistics. 
They have been created for research purposes from the Integrated Data 
Infrastructure (IDI), managed by Statistics New Zealand.
The opinions, findings, recommendations, and conclusions expressed in 
this report are those of the author, not Statistics NZ.
Access to the anonymised data used in this study was provided by 
Statistics NZ under the security and confidentiality provisions of 
the Statistics Act 1975. Only people authorised by the Statistics Act 
1975 are allowed to see data about a particular person, household, 
business, or organisation, and the results in this report have been 
confidentialised to protect these groups from identification and to 
keep their data safe. Careful consideration has been given to the privacy, security, and 
confidentiality issues associated with using administrative and 
survey data in the IDI. Further detail can be found in the Privacy 
impact assessment for the Integrated Data Infrastructure available 
from www.stats.govt.nz.
*********************************************************************;

libname moh ODBC dsn=idi_clean_20211020_srvprd schema=moh_clean;
libname file "/nas/DataLab/MAA/MAA2019-35/Accidents/Data" ;

*********************************************************************;
***INPUT DATASETS**
moh.pub_fund_hosp_discharges_event
moh.pub_fund_hosp_discharges_diag
file.coh2939h_22Aug22 
file.coh4049h_22Aug22 
file.coh5059h_22Aug22 
file.coh6069h_22Aug22 
file.coh7079h_22Aug22
;

***OUTPUT DATASETS***
file.hospital_diagnoses
file.diag
file.MHdiag_1989_2019_7Aug22 (diag6)
file.MHdiag_2000_2019_7Aug22 (diag7)
file.cohMH_22Aug22 (diag9)
;

*********************************************************************;


* Hospitalizations dataset;
* Limit to events between 1 July 1989 and 30 June 2019 (study period)
* NOTE 1: mental health hospitalizations may proceed acc events (which start 1 Jul 2000)
* NOTE 2: stopping in 2019 to avoid impact of covid;
* NOTE 3: USE START DATES. Admission must occur in observation period, discharge may be after;
data hospitalizations; set moh.pub_fund_hosp_discharges_event;
where '1JUL1989'd <= moh_evt_evst_date < '1JUL2019'd;
run;


data hospitalizations_2; set hospitalizations;
hosp_start = moh_evt_evst_date;
hosp_end = moh_evt_even_date;
event_id = moh_evt_event_id_nbr;
format hosp_start hosp_end date9.;
run;


/*
proc freq data=hospitalizations_2;
table hosp_start hosp_end;
run;
*/

data hospitalizations_3; set hospitalizations_2
(keep = snz_uid event_id snz_moh_uid snz_moh_evt_uid moh_evt_end_type_code moh_evt_agency_code hosp_start hosp_end);
run;

* NOTE: LONG FILE. Each hospitalization assigned a unique event number;

* inner join using event ID;
data clin_codes_1; set moh.pub_fund_hosp_discharges_diag;
run;

data clin_codes_2 (keep = event_id moh_dia_clinical_code moh_dia_clinical_sys_code moh_dia_diagnosis_type_code); 
set clin_codes_1;
event_id = moh_dia_event_id_nbr;
run;

proc sql;
create table hosp_join as
select hospitalizations_3.*, clin_codes_2.*
from hospitalizations_3, clin_codes_2
where hospitalizations_3.event_id = clin_codes_2.event_id;
quit;


* Limit to PRIMARY diagnoses (diagnosis type 'A'), EXTERNAL CAUSES (diagnosis type 'E'), and PROCEDURES (diagnosis type 'O');
* Only 1 primary diagnosis per event, but there can be multiple E codes per event;
* Procedure codes needed for physical-health diagnoses;
data hosp_join_1; set hosp_join;
if moh_dia_diagnosis_type_code = 'B' then delete;
run;


proc freq data=hosp_join_1; 
table moh_dia_clinical_sys_code;
run;

** ICD CODES: 
*  JUL 1989 - JUN 1999: ICD-9-CM;
*  JUL 1999 - JUN 2001: ICD-10-AM v1
*  JUL 2001 - JUN 2004: ICD-10-AM v2
*  JUL 2004 - JUN 2008: ICD-10-AM v3
*  JUL 2008 - JUN 2014: ICD-10-AM v6
*  JUL 2014 ON:         ICD-10-AM v8;
*  JUL 2019 ON?? 		ICD-10-AM v11

* Create ICD-9 v ICD-10 indicator;
data hosp_join_1; set hosp_join_1;
if moh_dia_clinical_sys_code = '06' then ICD = 9;
if moh_dia_clinical_sys_code in ('10','11','12','13','14','15') then ICD = 10;

if ICD = 10 then ICD10 = 1;	else ICD10 = 0;
if ICD = 9 then ICD9 = 1;	else ICD9 = 0;
run;


data file.hospital_diagnoses;
set hosp_join_1;
run;

data hosp_join_1; 
set file.hospital_diagnoses;
run;


*********************************** 
ASSIGN MENTAL-HEALTH DIAGNOSES

UTILIZE AN INCLUSIVE SCHEME
***********************************;
data diag; set hosp_join_1;
code = moh_dia_clinical_code;

format mh_diagnosis $30.;
label mh_diagnosis = 'Mental health diagnosis';

/********************************
* Self-harm: 
  ICD-10: X60 to X84 
  ICD-9:  E950 to E959 
  (coded as 950 and 959 in dataset), per MOH documentation
  ('masterb' back-conversion spreadsheet)
*********************************/
* NOTE: Exclude events with undetermined intent;
***********************************;

/*DO NOT INCLUDE SELF HARM MH ADMISSIONS - TO AVOID PREDICTOR-OUTCOME OVERLAP
if 'X60' le substr(code,1,3) le 'X84'   then do mh_diagnosis = 'SelfHarm';	output;	end;

if '950' le substr(code,1,3) le '959' 	then do mh_diagnosis = 'SelfHarm';	output;	end;

*DO NOT INCLUDE SELF HARM MH ADMISSIONS - TO AVOID PREDICTOR-OUTCOME OVERLAP/*
/*************************************************
* Substance use disorders: 

ICD-10:
F10 to F19

ICD-9:
2910,2911,2912,2918,2919,2920,29283,29289,2929,
30390,30400,30410,30420,30430,30440,30450,30460,
30480,30500,3051,30520,30530,30540,30550,30560,
30570,30590
**************************************************/
* NOTE: This includes nicotine dependence (a very small # of cases with a primary diagnosis);
if 'F10' le substr(code,1,3) le 'F19' then do mh_diagnosis = 'SUD';	output; end;


if code in ('2910','2911','2912','2918','2919','2920','29283','29289','2929',
'30390','30400','30410','30420','30430','30440','30450','30460',
'30480','30500','3051','30520','30530','30540','30550','30560',
'30570','30590') then do mh_diagnosis = 'SUD';	output; end;

/*************************************************
* Psychotic disorders

ICD-10:
F20 to F25, F28, F29

ICD-9:
29500,29510,29520,29530,29540,29550,29560,29570,
29580,29590,2971,2973,2978,2979,2983,2988,2989,3004
**************************************************/

* NOTE: Psychotic disorders due to substance use are included in the SUD category;
if ('F20' le substr(code,1,3) le 'F25') or ('F28' le substr(code,1,3) le 'F29') then do mh_diagnosis = 'Psychosis'; output; end;


if code in ('29500','29510','29520','29530','29540','29550','29560','29570',
'29580','29590','2971','2973','2978','2979','2983','2988','2989','3004') then do mh_diagnosis = 'Psychosis'; output; end;

/*************************************************
* Mood disorders
ICD-10:
F30 to F34, F39

ICD-9:
29600,29621,29622,29623,29624,29630,29631,29632,29633,
29634,29636,29640,29651,29653,29654,29660,2967,29682,29690,
29699,3004,30113,311
**************************************************/
if ('F30' le substr(code,1,3) le 'F34') or (substr(code,1,3) = 'F39') then do mh_diagnosis = 'Mood';	output; end;


if code in ('29600','29621','29622','29623','29624','29630','29631','29632','29633',
'29634','29636','29640','29651','29653','29654','29660','2967','29682','29690',
'29699','3004','30113','311') then do mh_diagnosis = 'Mood';	output; end;

/*************************************************
* Anxiety disorders

ICD-10:
F40 to F45, F48

ICD-9:
30000,30001,30002,30009,30011,30012,30013,30014,30015,30016,
30019,30020,30021,30022,30023,30029,3003,3004,3005,3006,3007,
30081,30089,3009,3061,3062,3064,30650,3068,3069,30780,30789,3083,
3089,30929
**************************************************/
if ('F40' le substr(code,1,3) le 'F45') or (substr(code,1,3) = 'F48') then do mh_diagnosis = 'Anxiety';	output; end;

if code in ('30000','30001','30002','30009','30011','30012','30013','30014','30015','30016',
'30019','30020','30021','30022','30023','30029','3003','3004','3005','3006','3007',
'30081','30089','3009','3061','3062','3064','30650','3068','3069','30780','30789','3083',
'3089','30929') then do mh_diagnosis = 'Anxiety';	output; end;

/***********************************************************
* Physiological disturbance disorders (e.g., eating, sleep)

ICD-10:
F50 to F55, F59

ICD-9:
30270,30272,30279,30289,30580,30590,3069,3071,30740,30741,
30744,30745,30746,30747,30750,30751,30754,30759,316,64844
************************************************************/
if ('F50' le substr(code,1,3) le 'F55') or (substr(code,1,3) = 'F59') then do mh_diagnosis = 'Physiol_Disturb';	output; end;


if code in ('30270','30272','30279','30289','30580','30590','3069','3071','30740','30741',
'30744','30745','30746','30747','30750','30751','30754','30759','316','64844') then do mh_diagnosis = 'Physiol_Disturb';	output; end;

/*************************************************
* Personality disorders

ICD-10:
F60, F63 to F66, F68, F69

ICD-9:
30019,3010,30120,3013,3014,30150,30151,3016,3017,30182,
30183,30189,3019,3022,3023,3024,30250,3026,30281,30283,
30289,3029,31230,31231,31233,31239
**************************************************/
if (substr(code,1,3) in ('F60', 'F68', 'F69')) or ('F63' le substr(code,1,3) le 'F66') then do mh_diagnosis = 'Personality';	output; end;

if code in ('30019','3010','30120','3013','3014','30150','30151','3016','3017','30182',
'30183','30189','3019','3022','3023','3024','30250','3026','30281','30283',
'30289','3029','31230','31231','31233','31239') then do mh_diagnosis = 'Personality';	output; end;

/*************************************************
* Intellectual disability

* NOTE: EXCLUDE intellectual disability from MH conditions
  (per Temi & Av 18 July) ;
**************************************************/

/*
if (substr(code,1,3) in ('F78', 'F79')) or ('F70' le substr(code,1,3) le 'F73') then mh_diagnosis = 'Intellectual';
*/

/*************************************************
* Developmental disorders (e.g., autism)

ICD-10:
F80 to F82, F84, F88, F89

ICD-9:
29900,29910,29980,29990,31500,3151,3152,31531,31539,
3154,3158,3159,3308
**************************************************/
if (substr(code,1,3) in ('F84', 'F88', 'F89')) or ('F80' le substr(code,1,3) le 'F82') then do mh_diagnosis = 'Developmental';	output; end;


if code in ('29900','29910','29980','29990','31500','3151','3152','31531','31539','3154','3158','3159','3308') then do mh_diagnosis = 'Developmental';	output; end;

/*************************************************
* Childhood-onset disorders (e.g., ADHD, CD)

ICD-10:
F90, F91, F93 to F95, F98

ICD-9:
3070,30720,30721,30722,30723,3073,30752,30759,3076,
3077,3079,30921,30983,31200,31220,31289,3129,3130,
31322,31389,3139,31400,3142,3148,3149
**************************************************/
if substr(code,1,3) in ('F90', 'F91', 'F93', 'F94', 'F95', 'F98') then do mh_diagnosis = 'ChildOnset';	output; end;


if code in ('3070','30720','30721','30722','30723','3073','30752','30759','3076','3077','3079','30921','30983',
'31200','31220','31289','3129','3130','31322','31389','3139','31400','3142','3148','3149') then do mh_diagnosis = 'ChildOnset';	output; end;

/*
* NOTE: Create 3 versions: ADHD, CD, other;
if substr(code,1,3) = 'F90' then mh_diagnosis = 'ChildOnset_ADHD';
if substr(code,1,3) = 'F91' then mh_diagnosis = 'ChildOnset_CD';
if substr(code,1,3) in ('F93', 'F94', 'F95', 'F98') then mh_diagnosis = 'ChildOnset_OtherDx';
*/

/*************************************************
* Unspecified
ICD-10: F99
ICD-9: 3009
**************************************************/
if substr(code,1,3) = 'F99' then do mh_diagnosis = 'Unspecified';	output; end;


if code = '3009' then do mh_diagnosis = 'Unspecified';	output; end;

/*************************************************
* No MH diagnosis
**************************************************/
if mh_diagnosis = '' then do mh_diagnosis = 'No MH dx';	output; end;
run;

proc freq data=diag; 
table moh_dia_diagnosis_type_code mh_diagnosis;
run;

**saving;
data file.diag; set diag; run;
**retrieving;
data diag; set file.diag; run;


* Drop E codes and  O codes;
* Previously kept E codes related to Self-harm but Self-harm MH events no longer included - 8 Aug 2022;
data diag_2; set diag;
if (moh_dia_diagnosis_type_code = 'E') then delete;
if (moh_dia_diagnosis_type_code = 'O') then delete;
run;


*check;
proc freq data=diag_2; 
table moh_dia_diagnosis_type_code mh_diagnosis;
run;


proc sort data=diag_2; by descending hosp_start; run;


* Retain ICD-9 diagnoses for July 1989 - June 1999 
  and ICD-10 diagnoses for July 1999 to June 2019;
data diag_3; set diag_2;
if (ICD = 10) and ('01JUL1989'd le hosp_start le '30JUN1999'd) then delete;
run;

data diag_4; set diag_3; 
if (ICD = 9) and ('01JUL1999'd le hosp_start le '30JUN2019'd) then delete;
run;

* Create global mental-health categories;
data diag_5; set diag_4;
if mh_diagnosis ne 'No MH dx' then AnyMH_dx = 1;
else AnyMH_dx = 0;
run;

*check;
proc freq data=diag_5; 
table mh_diagnosis AnyMH_dx;
run;


**keeping MH diagnoses only;
data diag_6;
set diag_5;
if AnyMH_dx = 1;
run;


*keeping MH diagnoses >=Jul 2000 for ACC analyses;
data diag_7;
set diag_6;
if hosp_start>= '1JUL2000'd;
run;


* save files;
data file.MHdiag_1989_2019_7Aug22;
set diag_6;
run;

data diag_6;
set file.MHdiag_1989_2019_7Aug22;
run;

data file.MHdiag_2000_2019_7Aug22;
set diag_7;
run;

data diag_7 ;
set file.MHdiag_2000_2019_7Aug22;
run;

***


*******************************************;
***CALCULATING EARLIEST DISORDER BY TYPE***;
*******************************************;
proc freq data=diag_6;
table mh_diagnosis;
run;

*Anxiety;
data anx (keep=snz_uid anx_start Anxiety); 
set diag_6; if mh_diagnosis="Anxiety"; Anxiety=1; 
anx_start=hosp_start;
format anx_start DATE9.;
run;

proc sort data=anx; by snz_uid anx_start; run;

data anx2; set anx; anxcount + 1;
by snz_uid; if first.snz_uid then anxcount = 1; run;

data anx3; set anx2; if anxcount=1; drop anxcount; run;

*ChildOnset;
data child (keep=snz_uid child_start ChildOnset); 
set diag_6; if mh_diagnosis="ChildOnset"; ChildOnset=1; 
child_start=hosp_start;
format child_start DATE9.;
run;

proc sort data=child; by snz_uid child_start; run;

data child2; set child; childcount + 1;
by snz_uid; if first.snz_uid then childcount = 1; run;

data child3; set child2; if childcount=1; drop childcount; run;

*Developmental;
data dev (keep=snz_uid dev_start Developmental); 
set diag_6; if mh_diagnosis="Developmental"; Developmental=1; 
dev_start=hosp_start;
format dev_start DATE9.;
run;

proc sort data=dev; by snz_uid dev_start; run;

data dev2; set dev; devcount + 1;
by snz_uid; if first.snz_uid then devcount = 1; run;

data dev3; set dev2; if devcount=1; drop devcount; run;

*Mood;
data Mood (keep=snz_uid Mood_start Mood); 
set diag_6; if mh_diagnosis="Mood"; Mood=1; 
Mood_start=hosp_start;
format Mood_start DATE9.;
run;

proc sort data=Mood; by snz_uid Mood_start; run;

data Mood2; set Mood; Moodcount + 1;
by snz_uid; if first.snz_uid then Moodcount = 1; run;

data Mood3; set Mood2; if Moodcount=1; drop Moodcount; run;

*Personality;
data Pers (keep=snz_uid Pers_start Personality); 
set diag_6; if mh_diagnosis="Personality"; Personality=1; 
Pers_start=hosp_start;
format Pers_start DATE9.;
run;

proc sort data=Pers; by snz_uid Pers_start; run;

data Pers2; set Pers; Perscount + 1;
by snz_uid; if first.snz_uid then Perscount = 1; run;

data Pers3; set Pers2; if Perscount=1; drop Perscount; run;

*Physiol_Disturb;
data Phys (keep=snz_uid Phys_start Physiol_Disturb); 
set diag_6; if mh_diagnosis="Physiol_Disturb"; Physiol_Disturb=1; 
Phys_start=hosp_start;
format Phys_start DATE9.;
run;

proc sort data=Phys; by snz_uid Phys_start; run;

data Phys2; set Phys; Physcount + 1;
by snz_uid; if first.snz_uid then Physcount = 1; run;

data Phys3; set Phys2; if Physcount=1; drop Physcount; run;

*Psychosis;
data Psychosis (keep=snz_uid Psychosis_start Psychosis); 
set diag_6; if mh_diagnosis="Psychosis"; Psychosis=1; 
Psychosis_start=hosp_start;
format Psychosis_start DATE9.;
run;

proc sort data=Psychosis; by snz_uid Psychosis_start; run;

data Psychosis2; set Psychosis; Psychosiscount + 1;
by snz_uid; if first.snz_uid then Psychosiscount = 1; run;

data Psychosis3; set Psychosis2; if Psychosiscount=1; drop Psychosiscount; run;

*SUD;
data SUD (keep=snz_uid SUD_start SUD); 
set diag_6; if mh_diagnosis="SUD"; SUD=1; 
SUD_start=hosp_start;
format SUD_start DATE9.;
run;

proc sort data=SUD; by snz_uid SUD_start; run;

data SUD2; set SUD; SUDcount + 1;
by snz_uid; if first.snz_uid then SUDcount = 1; run;

data SUD3; set SUD2; if SUDcount=1; drop SUDcount; run;

*Unspecified;
data uns (keep=snz_uid uns_start Unspecified); 
set diag_6; if mh_diagnosis="Unspecified"; Unspecified=1; 
uns_start=hosp_start;
format uns_start DATE9.;
run;

proc sort data=uns; by snz_uid uns_start; run;

data uns2; set uns; unscount + 1;
by snz_uid; if first.snz_uid then unscount = 1; run;

data uns3; set uns2; if unscount=1; drop unscount; run;


**Merging;
proc sort data=anx3; by snz_uid; run;
proc sort data=child3; by snz_uid; run;
proc sort data=dev3; by snz_uid; run;
proc sort data=Mood3; by snz_uid; run;
proc sort data=Pers3; by snz_uid; run;
proc sort data=Phys3; by snz_uid; run;
proc sort data=Psychosis3; by snz_uid; run;
proc sort data=SUD3; by snz_uid; run;
proc sort data=uns3; by snz_uid; run;

data diag8;
merge anx3 child3 dev3 Mood3 Pers3 Phys3 Psychosis3 SUD3 uns3;
by snz_uid;
MH=1;
MH_start=min(anx_start, child_start, dev_start, Mood_start, Pers_start, Phys_start, 
Psychosis_start, SUD_start, uns_start);
format MH_start DATE9.;
run;

*MERGING BACK WITH COHORT 1929-79;
data cohort (drop=res_pop_flag); 
set file.coh2939h_22Aug22 file.coh4049h_22Aug22 file.coh5059h_22Aug22 
file.coh6069h_22Aug22 file.coh7079h_22Aug22; 
if 1929<=dia_bir_birth_year_nbr<=1939 then coh=1;*1929-39;
if 1940<=dia_bir_birth_year_nbr<=1949 then coh=2;*1940-49;
if 1950<=dia_bir_birth_year_nbr<=1959 then coh=3;*1950-59;
if 1960<=dia_bir_birth_year_nbr<=1969 then coh=4;*1960-69;
if 1970<=dia_bir_birth_year_nbr<=1979 then coh=5;*1970-79;
run;

****NB. no exclusions based on res_pop flag. ;



proc sort data=cohort; by snz_uid; run;
proc sort data=DIAG8; by snz_uid; run;

data DIAG9;
merge COHORT DIAG8;
by SNZ_UID;
if coh~=.;
if MH=. then MH=0;
run;

proc freq data=diag9;
table MH MH_start dia_bir_birth_year_nbr death_date;
run;




**************************;
**************************;
**************************;
data file.cohMH_22Aug22;
set diag9;
run;

data diag9;
set file.cohMH_22Aug22;
run;

**************************;
**************************;
**************************;






