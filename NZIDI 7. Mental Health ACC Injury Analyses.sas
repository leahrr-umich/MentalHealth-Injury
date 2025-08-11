*********************************************************************
PROJECT: Mental Health and Injury
AUTHOR: S. D'Souza & B. Milne
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

libname acc ODBC dsn=idi_clean_20211020_srvprd schema=acc_clean;
libname file "/nas/DataLab/MAA/MAA2019-35/Accidents/Data" ;

**loading ACC claims;
data claims;
set acc.claims;
run;


**saving;
data file.claims; set claims; run;
**retrieving;
data claims; set file.claims; run;


****merging cohort file with claims file, keeping only claims for those in cohort;
****FIRST, delete all claims before 2000 (diagnostic coding only complete after 2000);
data claims2000;
set claims;
year_d = year(acc_cla_decision_date);
year_a = year(acc_cla_accident_date);
year_l = year(acc_cla_lodgement_date);
year_r = year(acc_cla_registration_date);
if (year_d>1999 or year_a>1999 or year_l>1999 or year_r>1999);
run;


proc freq data=claims2000;
table year_d year_a year_l year_r;
run;
*depending on date we choose, ~150K may still be dropped;


proc sort data=claims2000; by snz_uid; run;
proc sort data=file.ACCMH_22Aug22; by snz_uid; run;
data ACCMH_claims; merge file.ACCMH_22Aug22 claims2000; by snz_uid; if dia_bir_birth_year_nbr ~=.; run;

**saving;
data file.ACCMH_claims; set ACCMH_claims; run;
**retrieving;
data ACCMH_claims; set file.ACCMH_claims; run;

*******************NOTE*********************
****ONLY ACCEPTED CLAIMS ARE IN THE DATA****
********************************************

**assessing how many of the cohort have claims;
PROC MEANS data=ACCMH_claims;
var snz_uid snz_acc_uid snz_acc_claim_uid; 
run;


****checking self inflicted text;
PROC freq data=ACCMH_claims;
table acc_cla_wil_self_infl_stat_text; 
run;


proc freq data=ACCMH_claims noprint;
table snz_acc_claim_uid / out=xxx;
run;
proc freq data=xxx;
table count;
run;
*All claim IDs unique;









**************ACC MEDICAL**************;
data med;
set acc.medical_codes;
run;


**checking how many are duplicate claims ID;
proc freq data=med noprint;
table snz_acc_claim_uid / out=xxx;
run;
proc freq data=xxx;
table count;
run;


***merging with cohort;
**keeping just clinical vars and only cases with valid clinical data;
data med2 (keep=snz_acc_claim_uid acc_med_read_code acc_med_ICD9_code acc_med_ICD10_code);
set med;
if (acc_med_read_code~="" or acc_med_ICD9_code~="" or acc_med_ICD10_code~="");
run;


proc freq data=med2;
table acc_med_read_code;
RUN; 


**************self harm***************;
data med2a;
set med2;
acc_SH = 0;
if (acc_med_read_code in('14K1','SL...','SL90.','SL900','TK...','TK...','TK0..','TK00.',
'TK01.','TK02.','TK03.','TK04.','TK05.','TK06.','TK07.','TK08.','TK0Z.','TK1..',
'TK10.','TK11.','TK1Z.','TK2..','TK20.','TK21.','TK2Z.','TK3..','TK30.','TK31.',
'TK3Y.','TK3Z.','TK4..','TK5..','TK51.','TK54.','TK6..','TK60.','TK601','TK61.',
'TK6Z.','TK7..','TK71.','TK72.','TK7Z.','TKX..','TKX00','TKX1.','TKX2.','TKX3.',
'TKX4.','TKX5.','TKX7.','TKXY.','TKXZ.','TKY..','TKZ..','U2...','U20..','U200.',
'U2000','U2011','U202.','U204.','U205.','U205Y','U205Z','U206.','U206Y','U208.',
'U2080','U2086','U208Y','U20A0','U20AY','U20B.','U20BY','U20C.','U20C0','U20CY',
'U20Y.','U20Y0','U20Y3','U20Y4','U20Y6','U20YY','U20YZ','U21..','U210.','U211.',
'U212.','U216.','U217.','U21Y.','U21Z.','U22..','U22Z.','U23..','U231.','U24..',
'U24Y.','U24Z.','U25..','U26..','U27..','U270.','U271.','U27Y.','U27Z.','U28..',
'U280.','U29..','U290.','U291.','U295.','U296.','U29Y.','U29Z.','U2A..','U2A0.',
'U2A1.','U2A2.','U2BY.','U2BZ.','U2D..','U2D2.','U2D4.','U2DY.','U2E..','U2Y..',
'U2Y0.','U2Y1.','U2Y5.','U2YY.','U2YZ.','U2Z..','U2Z0.','U2ZY.','U2ZZ.','U41..')) 
then acc_SH = 1;
if (substr(acc_med_ICD9_code,1,3)) = "E95" then acc_SH = 1;
if (substr(acc_med_ICD10_code,1,2)) in ('X6','X7') then acc_SH = 1;
if (substr(acc_med_ICD10_code,1,3)) in ('X80','X81','X82','X83','X84') then acc_SH = 1;
run;

proc freq data=med2a;
table acc_SH;
run;


**checking how many are duplicate claims ID;
proc freq data=med2a noprint;
table snz_acc_claim_uid / out=xxx;
run;
proc freq data=xxx;
table count;
run;


proc freq data=med2a;
table acc_med_read_code acc_med_ICD9_code acc_med_ICD10_code;
run;



*counting & reshaping;
proc sort data=med2a; by snz_acc_claim_uid; run;
data med3;
set med2a;
rec + 1; by snz_acc_claim_uid;
if first.snz_acc_claim_uid then rec = 1;
run;

proc freq data=med3;
table rec;
run;





data rec1 (keep=snz_acc_claim_uid read_1 icd9_1 icd10_1 acc_SH_1); set med3; 
if rec=1; read_1 = acc_med_read_code; icd9_1 = acc_med_ICD9_code; icd10_1 = acc_med_ICD10_code; acc_SH_1 = acc_SH; run;
data rec2 (keep=snz_acc_claim_uid read_2 icd9_2 icd10_2 acc_SH_2); set med3; 
if rec=2; read_2 = acc_med_read_code; icd9_2 = acc_med_ICD9_code; icd10_2 = acc_med_ICD10_code; acc_SH_2 = acc_SH; run;
data rec3 (keep=snz_acc_claim_uid read_3 icd9_3 icd10_3 acc_SH_3); set med3; 
if rec=3; read_3 = acc_med_read_code; icd9_3 = acc_med_ICD9_code; icd10_3 = acc_med_ICD10_code; acc_SH_3 = acc_SH; run;
data rec4 (keep=snz_acc_claim_uid read_4 icd9_4 icd10_4 acc_SH_4); set med3; 
if rec=4; read_4 = acc_med_read_code; icd9_4 = acc_med_ICD9_code; icd10_4 = acc_med_ICD10_code; acc_SH_4 = acc_SH; run;
data rec5 (keep=snz_acc_claim_uid read_5 icd9_5 icd10_5 acc_SH_5); set med3; 
if rec=5; read_5 = acc_med_read_code; icd9_5 = acc_med_ICD9_code; icd10_5 = acc_med_ICD10_code; acc_SH_5 = acc_SH; run;
data rec6 (keep=snz_acc_claim_uid read_6 icd9_6 icd10_6 acc_SH_6); set med3; 
if rec=6; read_6 = acc_med_read_code; icd9_6 = acc_med_ICD9_code; icd10_6 = acc_med_ICD10_code; acc_SH_6 = acc_SH; run;
data rec7 (keep=snz_acc_claim_uid read_7 icd9_7 icd10_7 acc_SH_7); set med3; 
if rec=7; read_7 = acc_med_read_code; icd9_7 = acc_med_ICD9_code; icd10_7 = acc_med_ICD10_code; acc_SH_7 = acc_SH; run;
data rec8 (keep=snz_acc_claim_uid read_8 icd9_8 icd10_8 acc_SH_8); set med3; 
if rec=8; read_8 = acc_med_read_code; icd9_8 = acc_med_ICD9_code; icd10_8 = acc_med_ICD10_code; acc_SH_8 = acc_SH; run;
data rec9 (keep=snz_acc_claim_uid read_9 icd9_9 icd10_9 acc_SH_9); set med3; 
if rec=9; read_9 = acc_med_read_code; icd9_9 = acc_med_ICD9_code; icd10_9 = acc_med_ICD10_code; acc_SH_9 = acc_SH; run;
data rec10 (keep=snz_acc_claim_uid read_10 icd9_10 icd10_10 acc_SH_10); set med3; 
if rec=10; read_10 = acc_med_read_code; icd9_10 = acc_med_ICD9_code; icd10_10 = acc_med_ICD10_code; acc_SH_10 = acc_SH; run;
data rec11 (keep=snz_acc_claim_uid read_11 icd9_11 icd10_11 acc_SH_11); set med3; 
if rec=11; read_11 = acc_med_read_code; icd9_11 = acc_med_ICD9_code; icd10_11 = acc_med_ICD10_code; acc_SH_11 = acc_SH; run;
data rec12 (keep=snz_acc_claim_uid read_12 icd9_12 icd10_12 acc_SH_12); set med3; 
if rec=12; read_12 = acc_med_read_code; icd9_12 = acc_med_ICD9_code; icd10_12 = acc_med_ICD10_code; acc_SH_12 = acc_SH; run;
data rec13 (keep=snz_acc_claim_uid read_13 icd9_13 icd10_13 acc_SH_13); set med3; 
if rec=13; read_13 = acc_med_read_code; icd9_13 = acc_med_ICD9_code; icd10_13 = acc_med_ICD10_code; acc_SH_13 = acc_SH; run;
data rec14 (keep=snz_acc_claim_uid read_14 icd9_14 icd10_14 acc_SH_14); set med3; 
if rec=14; read_14 = acc_med_read_code; icd9_14 = acc_med_ICD9_code; icd10_14 = acc_med_ICD10_code; acc_SH_14 = acc_SH; run;
data rec15 (keep=snz_acc_claim_uid read_15 icd9_15 icd10_15 acc_SH_15); set med3; 
if rec=15; read_15 = acc_med_read_code; icd9_15 = acc_med_ICD9_code; icd10_15 = acc_med_ICD10_code; acc_SH_15 = acc_SH; run;
data rec16 (keep=snz_acc_claim_uid read_16 icd9_16 icd10_16 acc_SH_16); set med3; 
if rec=16; read_16 = acc_med_read_code; icd9_16 = acc_med_ICD9_code; icd10_16 = acc_med_ICD10_code; acc_SH_16 = acc_SH; run;
data rec17 (keep=snz_acc_claim_uid read_17 icd9_17 icd10_17 acc_SH_17); set med3; 
if rec=17; read_17 = acc_med_read_code; icd9_17 = acc_med_ICD9_code; icd10_17 = acc_med_ICD10_code; acc_SH_17 = acc_SH; run;
data rec18 (keep=snz_acc_claim_uid read_18 icd9_18 icd10_18 acc_SH_18); set med3; 
if rec=18; read_18 = acc_med_read_code; icd9_18 = acc_med_ICD9_code; icd10_18 = acc_med_ICD10_code; acc_SH_18 = acc_SH; run;
data rec19 (keep=snz_acc_claim_uid read_19 icd9_19 icd10_19 acc_SH_19); set med3; 
if rec=19; read_19 = acc_med_read_code; icd9_19 = acc_med_ICD9_code; icd10_19 = acc_med_ICD10_code; acc_SH_19 = acc_SH; run;
data rec20 (keep=snz_acc_claim_uid read_20 icd9_20 icd10_20 acc_SH_20); set med3; 
if rec=20; read_20 = acc_med_read_code; icd9_20 = acc_med_ICD9_code; icd10_20 = acc_med_ICD10_code; acc_SH_20 = acc_SH; run;
data rec21 (keep=snz_acc_claim_uid read_21 icd9_21 icd10_21 acc_SH_21); set med3; 
if rec=21; read_21 = acc_med_read_code; icd9_21 = acc_med_ICD9_code; icd10_21 = acc_med_ICD10_code; acc_SH_21 = acc_SH; run;
data rec22 (keep=snz_acc_claim_uid read_22 icd9_22 icd10_22 acc_SH_22); set med3; 
if rec=22; read_22 = acc_med_read_code; icd9_22 = acc_med_ICD9_code; icd10_22 = acc_med_ICD10_code; acc_SH_22 = acc_SH; run;
data rec23 (keep=snz_acc_claim_uid read_23 icd9_23 icd10_23 acc_SH_23); set med3; 
if rec=23; read_23 = acc_med_read_code; icd9_23 = acc_med_ICD9_code; icd10_23 = acc_med_ICD10_code; acc_SH_23 = acc_SH; run;
data rec24 (keep=snz_acc_claim_uid read_24 icd9_24 icd10_24 acc_SH_24); set med3; 
if rec=24; read_24 = acc_med_read_code; icd9_24 = acc_med_ICD9_code; icd10_24 = acc_med_ICD10_code; acc_SH_24 = acc_SH; run;

proc sort data=rec1; by snz_acc_claim_uid; run;
proc sort data=rec2; by snz_acc_claim_uid; run;
proc sort data=rec3; by snz_acc_claim_uid; run;
proc sort data=rec4; by snz_acc_claim_uid; run;
proc sort data=rec5; by snz_acc_claim_uid; run;
proc sort data=rec6; by snz_acc_claim_uid; run;
proc sort data=rec7; by snz_acc_claim_uid; run;
proc sort data=rec8; by snz_acc_claim_uid; run;
proc sort data=rec9; by snz_acc_claim_uid; run;
proc sort data=rec10; by snz_acc_claim_uid; run;
proc sort data=rec11; by snz_acc_claim_uid; run;
proc sort data=rec12; by snz_acc_claim_uid; run;
proc sort data=rec13; by snz_acc_claim_uid; run;
proc sort data=rec14; by snz_acc_claim_uid; run;
proc sort data=rec15; by snz_acc_claim_uid; run;
proc sort data=rec16; by snz_acc_claim_uid; run;
proc sort data=rec17; by snz_acc_claim_uid; run;
proc sort data=rec18; by snz_acc_claim_uid; run;
proc sort data=rec19; by snz_acc_claim_uid; run;
proc sort data=rec20; by snz_acc_claim_uid; run;
proc sort data=rec21; by snz_acc_claim_uid; run;
proc sort data=rec22; by snz_acc_claim_uid; run;
proc sort data=rec23; by snz_acc_claim_uid; run;
proc sort data=rec24; by snz_acc_claim_uid; run;

data rec (drop=acc_SH_1 acc_SH_2 acc_SH_3 acc_SH_4 acc_SH_5 acc_SH_6 acc_SH_7 acc_SH_8 acc_SH_9 acc_SH_10 acc_SH_11 acc_SH_12 
 acc_SH_13 acc_SH_14 acc_SH_15 acc_SH_1 acc_SH_17 acc_SH_18 acc_SH_19 acc_SH_20 acc_SH_21 acc_SH_22 acc_SH_23 acc_SH_24);
merge rec1 rec2 rec3 rec4 rec5 rec6 rec7 rec8 rec9 rec10 rec11 rec12 
rec13 rec14 rec15 rec16 rec17 rec18 rec19 rec20 rec21 rec22 rec23 rec24;
by snz_acc_claim_uid;  
rec=1;

if acc_SH_1=. then acc_SH_1=0;
if acc_SH_2=. then acc_SH_2=0;
if acc_SH_3=. then acc_SH_3=0;
if acc_SH_4=. then acc_SH_4=0;
if acc_SH_5=. then acc_SH_5=0;
if acc_SH_6=. then acc_SH_6=0;
if acc_SH_7=. then acc_SH_7=0;
if acc_SH_8=. then acc_SH_8=0;
if acc_SH_9=. then acc_SH_9=0;
if acc_SH_10=. then acc_SH_10=0;
if acc_SH_11=. then acc_SH_11=0;
if acc_SH_12=. then acc_SH_12=0;
if acc_SH_13=. then acc_SH_13=0;
if acc_SH_14=. then acc_SH_14=0;
if acc_SH_15=. then acc_SH_15=0;
if acc_SH_16=. then acc_SH_16=0;
if acc_SH_17=. then acc_SH_17=0;
if acc_SH_18=. then acc_SH_18=0;
if acc_SH_19=. then acc_SH_19=0;
if acc_SH_20=. then acc_SH_20=0;
if acc_SH_21=. then acc_SH_21=0;
if acc_SH_22=. then acc_SH_22=0;
if acc_SH_23=. then acc_SH_23=0;
if acc_SH_24=. then acc_SH_24=0;

acc_SH=acc_SH_1+acc_SH_2+acc_SH_3+acc_SH_4+acc_SH_5+acc_SH_6+acc_SH_7+acc_SH_8+acc_SH_9+acc_SH_10+acc_SH_11+acc_SH_12 
+acc_SH_13+acc_SH_14+acc_SH_15+acc_SH_1+acc_SH_17+acc_SH_18+acc_SH_19+acc_SH_20+acc_SH_21+acc_SH_22+acc_SH_23+acc_SH_24;
if 2<=acc_SH<=24 then acc_SH=1;
run; 

proc freq data=rec;
table acc_SH;
run;


**merging with cohort;
proc sort data=ACCMH_claims; by snz_acc_claim_uid; run;
proc sort data=rec; by snz_acc_claim_uid; run;

data all_claims2; 
merge ACCMH_claims rec; 
by snz_acc_claim_uid; 
if snz_uid~=.; 
class_code=0;
if acc_cla_icd10_code ~="" then class_code=1;
if acc_cla_icd9_code ~="" then class_code=1;
if acc_cla_read_code ~="" then class_code=1;
if rec=1 then class_code=1;
run; 


proc freq data=all_claims2;
table acc_SH acc_cla_wil_self_infl_stat_text acc_SH*acc_cla_wil_self_infl_stat_text;
run;

proc freq data=all_claims2; 
*table class_code; 
table read_18 read_19 read_20 read_21 read_22 read_23 read_24;
table icd9_18 icd9_19 icd9_20 icd9_21 icd9_22 icd9_23 icd9_24;
table icd10_18 icd10_19 icd10_20 icd10_21 icd10_22 icd10_23 icd10_24;
run;



data all_claims3 (drop=read_21 icd9_21 icd10_21 read_22 icd9_22 icd10_22 read_23 icd9_23 icd10_23 read_24 icd9_24 icd10_24);
set all_claims2;
year_d = year(acc_cla_decision_date);
year_a = year(acc_cla_accident_date);
year_l = year(acc_cla_lodgement_date);
year_r = year(acc_cla_registration_date);

miss_agency = 0;
if acc_cla_external_agency_text = "" then miss_agency = 1;
miss_cause = 0;
if acc_cla_cause_desc = "" then miss_cause = 1;
miss_scene = 0;
if acc_cla_scene_text = "" then miss_scene = 1;
run;


proc freq data=all_claims3;
table year_l*class_code;
run;

***************************************************************************;
******************ADDING IN DATA ON EXPOSURE MATCHING**********************;
***************************************************************************;
proc sort data=all_claims3; by snz_uid; run;

data accexpfile (keep=snz_uid start_date wgt expdays);
set file.acc_cohort_4;
run;
proc sort data=accexpfile; by snz_uid; run;
proc means data=accexpfile; run;

data all_claims4;
merge all_claims3 accexpfile;
by snz_uid;
run;

proc means data=all_claims4;
var snz_uid start_date wgt expdays;
run;


proc print data=all_claims4 (where=(start_date=.));
var snz_uid coh snz_sex_gender_code;
run;

* Dropping these cases (as per exposure matching file);
data all_claims4; set all_claims4; if start_date~=.; run;

***saving;
data file.all_claims4; set all_claims4; run;
data all_claims4; set file.all_claims4; run;


********************************************************************************;
********************************************************************************;
********************************************************************************;


PROC MEANS data=all_claims4;
var snz_uid snz_acc_uid snz_acc_claim_uid; 
run;

*checking sensitive claims;
proc freq data=all_claims4;
table acc_cla_sensitive_claim_ind acc_SH acc_cla_wil_self_infl_stat_text;
table acc_SH*acc_cla_wil_self_infl_stat_text /missing;
run;
proc freq data=all_claims4 (where=(acc_cla_sensitive_claim_ind="Y"));
table acc_SH*acc_cla_wil_self_infl_stat_text;
run;



**COUNTING & RESHAPING;
proc contents data=all_claims4  order=varnum; run;

data all_claims5;
set all_claims4;
if snz_acc_claim_uid~=.;
if acc_SH~=1;
if acc_cla_wil_self_infl_stat_text~="CONFIRMED";
drop dia_bir_birth_year_nbr dia_bir_birth_month_nbr death_date snz_sex_gender_code
coh Anxiety anx_start ChildOnset child_start Developmental dev_start Mood
Mood_start Personality Pers_start Physiol_Disturb Phys_start Psychosis
Psychosis_start SUD SUD_start Unspecified uns_start MH;
run;


*checking for duplicates by accident date;
proc sort data=all_claims5 dupout=accdatedup nodupkey; 
by snz_acc_claim_uid acc_cla_accident_date; run;
**none;

**Counting ALL injuries;
proc sort data=all_claims5; by snz_uid acc_cla_accident_date; run;
proc means data=all_claims5; var snz_uid acc_cla_accident_date start_date; run;

data all_claims6;
set all_claims5;
nclaims + 1; by snz_uid;
if first.snz_uid then nclaims = 1;
pre_inj=0;
if acc_cla_accident_date < start_date then pre_inj = 1;
post_inj = 1 - pre_inj;
run;

proc freq data=all_claims6;
table nclaims pre_inj post_inj;
run;


**Counting POST-MH injuries;
data post_claims (drop=nclaims);
set all_claims6;
if post_inj=1;
run;

proc sort data=post_claims; by snz_uid acc_cla_accident_date; run;
data post_claims2;
set post_claims;
npostclaims + 1; by snz_uid;
if first.snz_uid then npostclaims = 1;
run;

proc freq data=post_claims2;
table npostclaims;
run;



*keeping date of first (and total number, both across period and post MH);
***Across period;
data firstclaim (keep=snz_uid firstinj_date_d firstinj_date_a firstinj_date_l firstinj_date_r);
set all_claims6;
if nclaims=1;
firstinj_date_d=acc_cla_decision_date;
firstinj_date_a=acc_cla_accident_date;
firstinj_date_l=acc_cla_lodgement_date;
firstinj_date_r=acc_cla_registration_date;
run;

proc sort data=all_claims6; by snz_uid nclaims; run;
data nclaims (keep=snz_uid nclaims);
set all_claims6;
by snz_uid;
if last.snz_uid;
run;

proc freq data=nclaims;
table nclaims;
run;


***PostMH;
data firstpost (keep=snz_uid postinj_date_d postinj_date_a postinj_date_l postinj_date_r);
set post_claims2;
if npostclaims=1;
postinj_date_d=acc_cla_decision_date;
postinj_date_a=acc_cla_accident_date;
postinj_date_l=acc_cla_lodgement_date;
postinj_date_r=acc_cla_registration_date;
run;


proc sort data=post_claims2; by snz_uid npostclaims; run;
data npostclaims (keep=snz_uid npostclaims post_inj);
set post_claims2;
by snz_uid;
if last.snz_uid;
run;

proc freq data=npostclaims;
table npostclaims post_inj;
run;


**identifying pre_inj IDs;
data pre_inj;
set all_claims6;
if pre_inj=1;
run;

proc sort data=pre_inj; by snz_uid acc_cla_accident_date; run;
data pre_inj2 (keep=snz_uid pre_inj);
set pre_inj;
by snz_uid;
if first.snz_uid;
run;




************************************;
****MERGING BACK IN WITH MH DATA****;
************************************;
proc sort data=file.ACCMH_22Aug22; by snz_uid; run;
proc sort data=accexpfile; by snz_uid; run;
proc sort data=firstclaim; by snz_uid; run;
proc sort data=nclaims; by snz_uid; run;
proc sort data=firstpost; by snz_uid; run;
proc sort data=npostclaims; by snz_uid; run;
proc sort data=pre_inj2; by snz_uid; run;

data ACCMH_Analyses;
merge file.ACCMH_22Aug22 accexpfile firstclaim nclaims firstpost npostclaims pre_inj2;
by snz_uid;
anyACC=1;
if nclaims=. then nclaims=0;
if npostclaims=. then npostclaims=0;
if nclaims=0 then anyACC=0;
if pre_inj=. then pre_inj=0;
if post_inj=. then post_inj=0;
if snz_sex_gender_code~="";
run;

proc freq data=ACCMH_Analyses;
table MH anyACC post_inj pre_inj nclaims npostclaims;
table MH*anyACC MH*post_inj;
run;

****SAVING****;
data file.ACCMH_Analyses_19May2024; set ACCMH_Analyses; sex=snz_sex_gender_code*1; run;
data ACCMH_Analyses; set file.ACCMH_Analyses_19May2024; run;





**********************************************;
*****************DESCRIPTIVES*****************;
**********************************************;

**D1;
**any MH, any injury, any post-injury, any pre-injury, n injuries, n post-injury - by sex and cohort;
proc freq data=ACCMH_Analyses; table sex coh; run;  
proc sort data=ACCMH_Analyses; by sex coh; run;
proc freq data=ACCMH_Analyses; 
table MH anyACC post_inj pre_inj;
by sex coh; run;

proc means data=ACCMH_Analyses; 
var nclaims npostclaims;
by sex coh; run;

proc freq data=ACCMH_Analyses (where=(wgt>0)); 
table MH anyACC post_inj pre_inj;
run;

**D2;
**any injury, any post-injury, n injuries, n post-injury by MH - by sex and cohort;
proc sort data=ACCMH_Analyses; by sex coh MH; run;
proc freq data=ACCMH_Analyses; 
table MH *(anyACC post_inj);
by sex coh; run;

proc means data=ACCMH_Analyses; 
var nclaims npostclaims;
by sex coh MH; run;

**D3;
**Distributions of injuries and post-injuries;
proc sort data=ACCMH_Analyses; by sex coh; run;
proc freq data=ACCMH_Analyses; 
table nclaims npostclaims;
by sex coh; run;



**A1;
**MH-->INJ;
*Overall;
proc genmod data=ACCMH_Analyses;
model post_inj=MH pre_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;


*by sex;
proc sort data=ACCMH_Analyses; by sex coh; run;
proc genmod data=ACCMH_Analyses;
model post_inj=MH pre_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
by sex;
estimate 'Mental health beta' MH 1 / exp;
run;


*by sex & cohort;
proc genmod data=ACCMH_Analyses;
model post_inj=MH pre_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
by sex coh;
estimate 'Mental health beta' MH 1 / exp;
run;


**A2;
**MH-->N INJ;
**NBREG;
proc genmod data=ACCMH_Analyses; 
model npostclaims = MH pre_inj dia_bir_birth_year_nbr sex/ 
dist=negbin; weight wgt; 
estimate 'Mental health beta' MH 1 / exp; 
run; 

*by sex;
proc sort data=ACCMH_Analyses; by sex coh; run;
proc genmod data=ACCMH_Analyses; 
model npostclaims = MH pre_inj dia_bir_birth_year_nbr / 
dist=negbin; weight wgt; by sex;
estimate 'Mental health beta' MH 1 / exp; 
run;

*by sex & cohort;
proc genmod data=ACCMH_Analyses; 
model npostclaims = MH pre_inj dia_bir_birth_year_nbr / 
dist=negbin; weight wgt; by sex coh;
estimate 'Mental health beta' MH 1 / exp; 
run;


**A3;
**CONTROLLING FOR DEP;
data dep (keep=snz_uid dep1 dep1cat meandep); set file.totpop_dep; run;
proc means data=dep; var dep1 meandep;run;
proc freq data=dep; table dep1cat;run;

proc sort data=ACCMH_Analyses; by snz_uid; run;
proc sort data=dep; by snz_uid; run;

data ACCMH_dep;
merge ACCMH_Analyses dep;
by snz_uid; if start_date~=.; run;
proc means data=ACCMH_dep; var dep1 meandep;run;
proc freq data=ACCMH_dep; table dep1cat;run;


**A3 - GENMOD;
proc genmod data=ACCMH_dep;
class dep1cat (ref='Q1');
model post_inj=MH pre_inj dia_bir_birth_year_nbr sex dep1cat/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;


*by sex;
proc sort data=ACCMH_dep; by sex coh; run;
proc genmod data=ACCMH_dep;
class dep1cat (ref='Q1');
model post_inj=MH pre_inj dia_bir_birth_year_nbr dep1cat/ dist = poisson link = log;
weight wgt;
by sex;
estimate 'Mental health beta' MH 1 / exp;
run;


*by sex & cohort;
proc genmod data=ACCMH_dep;
class dep1cat (ref='Q1');
model post_inj=MH pre_inj dia_bir_birth_year_nbr dep1cat/ dist = poisson link = log;
weight wgt;
by sex coh;
estimate 'Mental health beta' MH 1 / exp;
run;


**A3 - NBREG;
proc genmod data=ACCMH_dep; 
class dep1cat (ref='Q1');
model npostclaims = MH pre_inj dia_bir_birth_year_nbr sex dep1cat/ 
dist=negbin; weight wgt; 
estimate 'Mental health beta' MH 1 / exp; 
run; 

*by sex;
proc sort data=ACCMH_dep; by sex coh; run;
proc genmod data=ACCMH_dep; 
class dep1cat (ref='Q1');
model npostclaims = MH pre_inj dia_bir_birth_year_nbr dep1cat/ 
dist=negbin; weight wgt; by sex;
estimate 'Mental health beta' MH 1 / exp; 
run;

*by sex & cohort;
proc genmod data=ACCMH_dep; 
class dep1cat (ref='Q1');
model npostclaims = MH pre_inj dia_bir_birth_year_nbr dep1cat/ 
dist=negbin; weight wgt; by sex coh;
estimate 'Mental health beta' MH 1 / exp; 
run;


**A4;
**EXCLUDING THOSE WITH A MENTAL HEALTH EVENT PRIOR TO JULY 2000;
data preMH (keep=snz_uid preMH);
set file.inj_analysis_17Feb2024;
if '1JAN1900'd<MH_start<'1JUL2000'd;
preMH=1;
run;

proc freq data=preMH;
table preMH; run;

proc sort data=ACCMH_dep; by snz_uid; run;
proc sort data=preMH; by snz_uid; run;

data ACC_preMHexcl;
merge ACCMH_dep preMH;
by snz_uid;
if preMH=. then preMH=0;
if start_date~=.;
run;

proc freq data=ACC_preMHexcl;
table preMH;
run;

*RISK RATIO;
proc genmod data=ACC_preMHexcl (where=(preMH=0));
model post_inj=MH pre_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;

**NBREG;
proc genmod data=ACC_preMHexcl (where=(preMH=0));
model npostclaims = MH pre_inj dia_bir_birth_year_nbr sex/ 
dist=negbin; weight wgt; 
estimate 'Mental health beta' MH 1 / exp; 
run; 










