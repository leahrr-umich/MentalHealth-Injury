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
file.hospital_diagnoses
file.COHORT_4
;

***OUTPUT DATASETS***
FILE.COHORT
FILE.MATRIX9E
FILE.MATRIX_WIDE
FILE.MATRICES2
FILE.INJURIES
prev_inj
FILE.INJALL_WIDE2
FILE.INJ_AT_WIDE2
file.inj_analysis_17Feb2024
;

*********************************************************************;


*************************************************************************;
************USING HOSPITAL DIAGNOSIS FILE - SAME AS FOR MH DX************;
*************************************************************************;


data hosdiag;
set file.hospital_diagnoses;
run;

proc freq data=hosdiag;
table moh_dia_diagnosis_type_code icd hosp_start;
run;


**ONLY USE ICD9 FOR MATRIX. CAN USE EITHER ICD10 OR ICD9 FOR IDENTIFYING INJURIES USING PRIMARY DX;




************************************************************************************;
**keeping events with primary diagnosis injury codes*;
************************************************************************************;
**icd9 800- 995;
data accprim9 (keep=snz_uid event_id hosp_start moh_dia_diagnosis_type_code icd9 icd9code);
set hosdiag;
if moh_dia_diagnosis_type_code="A";
if ICD=9;
icd9=1;
icd9code = moh_dia_clinical_code;
if ((substr(icd9code,1,1) = "8") or 
(substr(icd9code,1,2) in ('90','91','92','93','94','95','96','97','98')) or
(substr(icd9code,1,3) in ('990','991','992','993','994','995')));
run;
**IDC10 S00-S79;
data accprim10 (keep=snz_uid event_id hosp_start moh_dia_diagnosis_type_code icd10 icd10code);
set hosdiag;
if moh_dia_diagnosis_type_code="A";
if ICD=10;
icd10=1;
icd10code = moh_dia_clinical_code;
if ((substr(icd10code,1,1) = "S") or 
(substr(icd10code,1,2) in ('T0','T1','T2','T3','T4','T5','T6')) or
(substr(icd10code,1,3) in ('T70','T71','T72','T73','T74','T75','T76','T77','T78','T79')));
run;

proc freq data=accprim9;
table icd9code;
run;


proc freq data=accprim10;
table icd10code;
run;



*keeping unique event_ids;
proc sort data=accprim9 nodupkey out=accprim9a; by event_id; run;
proc sort data=accprim10 nodupkey out=accprim10a; by event_id; run;
*all unique - as only 1 primary diagnosis per event;

data accprim;
merge accprim9a accprim10a;
by event_id; 
if icd9=. then icd9=0;
if icd10=. then icd10=0;
run;

proc freq data=accprim;
table icd9*icd10;
run;
**NO cases where there is an icd10 code but no icd9 code!!;

**Adding e-codes;
data ecode9 (keep=event_id ecode9);
set hosdiag;
if moh_dia_diagnosis_type_code="E";
if ICD=9;
ecode9=moh_dia_clinical_code;
run;

*Merging with primary diagnosis, and deleting ecode duplicates;
proc sort data = accprim; by event_id; run;
proc sort data = ecode9 nodup; by event_id; run;

data accprim_ecode;
merge accprim ecode9;
by event_id;
if snz_uid~=.;
run;



**create variable for count of events from earliest to latest;
proc sort data=accprim_ecode;
by snz_uid hosp_start;
run;

data accprim_ecode2;
merge accprim_ecode;
event_nbr + 1;
by snz_uid;
if first.snz_uid then event_nbr = 1;
run;

proc freq data=accprim_ecode2;
table event_nbr;
run;


*checking how many missing ecodes;
proc freq data=accprim_ecode2;
table ecode9;
run;


**create variable for count of ecodes;
proc sort data=accprim_ecode2;
by event_id;
run;

data accprim_ecode3;
set accprim_ecode2;
ecode_nbr + 1;
by event_id;
if first.event_id then ecode_nbr = 1;
run;

proc freq data=accprim_ecode3;
table ecode_nbr;
run;



**reducing to cohort of interest and then reshaping wide;
data cohort (drop=res_pop_flag snz_sex_gender_code); 
set file.coh2939h_22Aug22 file.coh4049h_22Aug22 file.coh5059h_22Aug22 
file.coh6069h_22Aug22 file.coh7079h_22Aug22; 
if 1929<=dia_bir_birth_year_nbr<=1939 then coh=1;*1929-39;
if 1940<=dia_bir_birth_year_nbr<=1949 then coh=2;*1940-49;
if 1950<=dia_bir_birth_year_nbr<=1959 then coh=3;*1950-59;
if 1960<=dia_bir_birth_year_nbr<=1969 then coh=4;*1960-69;
if 1970<=dia_bir_birth_year_nbr<=1979 then coh=5;*1970-79;
sex=snz_sex_gender_code;
if sex~=.;
run;

proc sort data=cohort; by snz_uid; run;
proc sort data=accprim_ecode3; by snz_uid; run;


*creating file including events only for those in cohort, and adding field for matrix coding;
data coh_inj (drop=XX YY PI B3 B4 B5 DD);
merge cohort accprim_ecode3;
by snz_uid;
if sex~=.;
if event_id ~= .;

*external cause;
XX = substr(ecode9,1,3);*CAUSEDET: 3 DIGIT ECODE for morbidity data;
YY = substr(ecode9,1,4);*CAUSEDT4: 4 DIGIT ECODE for morbidity data; 
PI = substr(ecode9,4,1);*PERSINJ:  4TH DIGIT OF THE ECODE ;
CAUSEDET = XX*1;
CAUSEDT4 = YY*1; 
PERSINJ = PI*1;

*barell;
B3 = substr(icd9code,1,3);*DX13: 3 DIGIT ICD CODE for morbidity data;
B4 = substr(icd9code,1,4);*DX14: 4 DIGIT ICD CODE for morbidity data; 
B5 = substr(icd9code,1,5);*DX15: 5 DIGIT ICD CODE for morbidity data;
DD = substr(icd9code,5,1);*D5:     5TH DIGIT OF THE ICD CODE ;
DX13 = B3*1;
DX14 = B4*1;
if B4<1000 then DX14 = B4*10;
DX15 = B5*1;
if B5<10000 then DX15 = B5*10;
if B5<1000 then DX15 = B5*100;
D5 = DD*1;
if D5=. then D5=0;
run;

proc freq data=coh_inj;
table ecode_nbr;
run;

proc means data=coh_inj;
var snz_uid event_id causedet causedt4 persinj dx13 dx14 dx15 d5;
run;


*deleting duplicates on variables required for CAUSE X INTENT coding;
proc sort data=coh_inj nodupkey out=coh_inj2;
by snz_uid event_id causedet causedt4 persinj;
run;


*deleting duplicates on variables required for SITE X TYPE coding;
proc sort data=coh_inj nodupkey out=coh_inj3;
by snz_uid event_id dx13 dx14 dx15 d5;
run;

proc freq data=coh_inj3;
table ecode_nbr;
run;


*double checking if any events have been lost;
proc freq data=coh_inj noprint; table event_id /out=a; run;
proc freq data=coh_inj2 noprint; table event_id /out=b; run;
proc freq data=coh_inj3 noprint; table event_id /out=c; run;


*none have, dropping ecode_nbr event_nbr var (to be computed later in a file with line per event);
data coh_inj2 (drop=event_nbr ecode_nbr dx13 dx14 dx15 d5); set coh_inj2; run;
data coh_inj3 (drop=event_nbr ecode_nbr causedet causedt4 persinj); set coh_inj3; run;

proc means data=coh_inj2;
var snz_uid event_id causedet causedt4 persinj;
run;






*************************************************************************;
******************************ICD9 MATRICES******************************;
*************************************************************************;

/*SAS Input Statements for External Cause of Injury Morbidity Matrix */

/*Following are the SAS statements containing ICD-9 CM codes to be used to program the external cause of injury morbidity matrix.
Please cut and paste the SAS codes provided into your SAS programs.


Variable names used in the SAS statements 
CAUSEDET: 3 DIGIT ICD CODE fields for morbidity data
CAUSEDT4: 4 DIGIT ICD CODE field for morbidity data
PERSINJ:  4TH DIGIT OF THE ICD CODE */


/* INPUT VARIABLES FOR BARELL MATRIX
DX13 [3 digit code for first-listed ICD-9 CM diagnosis]
DX14 [4 digit code for first-listed diagnosis]
DX15 [5 digit code for first-listed diagnosis]
D5 [5th digit of code]
OUTPUT VARIABLES 
ISRCODE
ISRSITE
ISRSITE2
ISRSITE3 
*/


*********************************************;
***********CAUSE BY INTENT MATRIX************;
*********************************************;

*checking matric input variables;
proc freq data=coh_inj2;
table causedet causedt4 persinj; 
run;


data Matrix9E;
set coh_inj2;


 LABEL CAUSE='MECHANISM/CAUSE'
       INJ='MANNER/INTENT'       ;

   /* EXTERNAL CAUSE CODING MATRIX FOR INJURY MORBIDITY DATA*/

   /* MECHANISM-CAUSE CODING */

   /*CAUSE=MVT*/
   IF (CAUSEDET GE 810 AND CAUSEDET LE 819) OR 
	   CAUSEDT4 = 9585 OR CAUSEDT4 = 9685 OR CAUSEDT4 = 9885 THEN 
MVT=1;

   IF MVT=1 THEN CAUSE=1;

		 /*Person Type in MVT*/
   			/*OCCUPANT*/
	     IF (CAUSEDET GE 810 AND CAUSEDET LE 819) AND
   			(PERSINJ=0 OR PERSINJ=1) THEN MVTPER=1;
			/*MC*/
 		 IF (CAUSEDET GE 810 AND CAUSEDET LE 819) AND
   			(PERSINJ=2 OR PERSINJ=3) THEN MVTPER=2;
			/*PEDAL*/
  		 IF (CAUSEDET GE 810 AND CAUSEDET LE 819) AND 
			PERSINJ=6 THEN MVTPER=3;
			/*PEDEST*/
  		 IF (CAUSEDET GE 810 AND CAUSEDET LE 819) AND 
			PERSINJ=7 THEN MVTPER=4;
			/*UNKNOWN*/
  		 IF (CAUSEDET GE 810 AND CAUSEDET LE 819) AND 
			PERSINJ=9 THEN MVTPER=5;
			/*OTHER*/
  		 IF (CAUSEDET GE 810 AND CAUSEDET LE 819) AND
  		    (PERSINJ=4 OR PERSINJ=5 OR PERSINJ=8) THEN MVTPER=6;

  /*CAUSE=OTHER PEDAL CYC*/
  IF (CAUSEDET GE 800 AND CAUSEDET LE 807) AND PERSINJ=3 THEN NTB=1;
  IF (CAUSEDET GE 820 AND CAUSEDET LE 825) AND PERSINJ=6 THEN NTB=2;
  IF CAUSEDT4=8261 OR CAUSEDT4=8269 THEN NTB=3;
  IF (CAUSEDET GE 827 AND CAUSEDET LE 829) AND PERSINJ=1 THEN NTB=4;
  IF NTB GE 1 AND NTB LE 4 THEN OTHPEDAL=1;

  IF OTHPEDAL=1 THEN CAUSE=11;

  /*COUNT ALL PEDAL CYC; NOT INLCUDED AS ONE OF THE CAUSE*/
  IF MVTPER=3 OR OTHPEDAL=1 THEN PEDALALL=1;

  /*CAUSE=OTHER PEDESTRIAN*/
  IF (CAUSEDET GE 800 AND CAUSEDET LE 807) AND (PERSINJ=2) THEN 
PEDEST=1;
  IF (CAUSEDET GE 820 AND CAUSEDET LE 825) AND (PERSINJ=7) THEN 
PEDEST=2;
  IF (CAUSEDET GE 826 AND CAUSEDET LE 829) AND (PERSINJ=0) THEN 
PEDEST=3;
  IF PEDEST =1 OR PEDEST=2 OR PEDEST=3 THEN OTHPEDST=1;

  IF OTHPEDST=1 THEN CAUSE=12;
  /*CAUSE=OTHER TRANS*/
  IF (CAUSEDET GE 800 AND CAUSEDET LE 807) AND (PERSINJ=0 OR
  	  PERSINJ=1 OR PERSINJ=8 OR PERSINJ=9) THEN OT=1;
  IF  CAUSEDET=826 AND (PERSINJ GE 2 AND PERSINJ LE 8) THEN OT=2;
  IF ((CAUSEDET GE 827 AND CAUSEDET LE 829) AND
  	 (PERSINJ GE 2 AND PERSINJ LE 9)) OR CAUSEDET=831 OR 
	 (CAUSEDET GE 833 AND CAUSEDET LE 845) THEN OT=3;
  IF (CAUSEDET GE 820 AND CAUSEDET LE 825) AND ((PERSINJ GE 0 AND
  	  PERSINJ LE 5) OR (PERSINJ=8 OR PERSINJ=9)) THEN OT=4;
  IF CAUSEDT4=9586 OR CAUSEDT4=9886 THEN OT=5;

  IF OT =1 OR OT=2 OR OT=3 OR OT=4 OR OT=5 THEN OTHTRANS=1;

  IF OTHTRANS=1 THEN CAUSE=13;

  /*CAUSE=FIREARM*/
  IF (CAUSEDT4 GE 9220 and CAUSEDT4 LE 9223) OR CAUSEDT4=9228 OR 
CAUSEDT4=9229 OR 
	 (CAUSEDT4 GE 9550 AND CAUSEDT4 LE 9554) OR
	 (CAUSEDT4 GE 9650 AND CAUSEDT4 LE 9654) OR 
	  CAUSEDET = 970 OR
	 (CAUSEDT4 GE 9850 AND CAUSEDT4 LE 9854) OR
 	  CAUSEDT4 = 9794 THEN FIREARM=1;

  IF FIREARM=1 THEN CAUSE=2;

  /*CAUSE=POISONING*/
  IF (CAUSEDET GE 850 AND CAUSEDET LE 869) OR
	 (CAUSEDET GE 950 AND CAUSEDET LE 952) OR
	  CAUSEDET =962 OR CAUSEDET = 972 OR
  	 (CAUSEDET GE 980 AND CAUSEDET LE 982) OR (CAUSEDT4=9796 OR
CAUSEDT4=9797) THEN POISON=1;

  IF POISON=1 THEN CAUSE=3;

  /*CAUSE=FALLS*/
  IF (CAUSEDET GE 880 AND CAUSEDET LE 886) OR 
	  CAUSEDET = 888 OR 
	  CAUSEDET = 957 OR 
	  CAUSEDT4 = 9681 OR
	  CAUSEDET = 987  THEN FALL=1;

  IF FALL=1 THEN CAUSE=4;

  /*CAUSE=SUFFOCATION*/
  IF CAUSEDET = 911 OR CAUSEDET = 912 OR CAUSEDET=913 OR
	 CAUSEDET = 953 OR 
	 CAUSEDET = 963 OR 
	 CAUSEDET = 983 THEN SUFFOC=1;

  IF SUFFOC=1 THEN CAUSE=5;

  /*CAUSE=DROWNING*/
  IF CAUSEDET = 830 OR CAUSEDET = 832 OR 
	 CAUSEDET = 910 OR
	 CAUSEDET = 954 OR 
	 CAUSEDET = 964  OR 
	 CAUSEDET = 984 THEN DROWNING=1;

  IF DROWNING=1 THEN CAUSE=6;

  /*CAUSE=FIRE/BURN*/
  IF (CAUSEDET GE 890 AND CAUSEDET LE 899) OR
	  CAUSEDT4 = 9581 OR
	  CAUSEDT4 = 9680 OR 
	  CAUSEDT4 = 9881 OR 
 	  CAUSEDT4 = 9793 THEN FIRE =1;

  IF CAUSEDET = 924 OR 
	 CAUSEDT4 = 9582 OR CAUSEDT4 = 9587 OR
  	 CAUSEDET = 961 OR CAUSEDT4 = 9683 OR 
	 CAUSEDT4 = 9882 OR CAUSEDT4 = 9887 THEN BURN=1;

  IF FIRE=1 OR BURN =1 THEN FIREBURN=1;

  IF FIREBURN=1 THEN CAUSE=7;

  /*CAUSE=CUT/PIERCE*/
  IF CAUSEDET = 920 OR 
	 CAUSEDET = 956 OR 
	 CAUSEDET = 966 OR
	 CAUSEDET = 974 OR 
	 CAUSEDET = 986 THEN CUT=1;

  IF CUT=1 THEN CAUSE=8;

  /*CAUSE=STRUCK BY/AGAINST*/
  IF CAUSEDET = 916 OR CAUSEDET = 917 OR
	 CAUSEDT4 = 9682 OR CAUSEDT4 = 9600 OR
	 CAUSEDET = 973 OR CAUSEDET=975 THEN STRUCK=1;

  IF STRUCK=1 THEN CAUSE=9;

  /*CAUSE=MACHINERY*/
  IF CAUSEDET = 919 THEN MACH=1;

  IF MACH=1 THEN CAUSE=10;

  /*CAUSE=NATURAL/ENVIR*/
  IF (CAUSEDET GE 900 AND CAUSEDET LE 909) OR
	  CAUSEDT4 = 9280 OR CAUSEDT4 = 9281 OR CAUSEDT4= 9282 OR
	  CAUSEDT4 = 9583 OR CAUSEDT4 = 9883 THEN NATENV=1;

  IF NATENV=1 THEN CAUSE=14;

  /*COUNT ALL BITESTNG; NOT INLCUDED AS ONE OF THE CAUSE*/
  IF (CAUSEDT4 GE 9050 AND CAUSEDT4 LE 9056) OR CAUSEDT4=9059 THEN 
BS=1;
  IF (CAUSEDT4 GE 9060 AND CAUSEDT4 LE 9065) OR CAUSEDT4=9069 THEN 
BS=2;
  IF BS=1 OR BS=2 THEN BITESTNG=1;

  /*CAUSE=OVEREXERTION*/
  IF CAUSEDET=927 THEN OVEREXER=1;

  IF OVEREXER=1 THEN CAUSE=15;

  /*CAUSE=OTHER SPEC*/
  IF (CAUSEDET GE 846 AND CAUSEDET LE 848) OR
	  CAUSEDET = 914  OR CAUSEDET = 915  OR CAUSEDET = 918 OR 
	  CAUSEDET = 921  OR  CAUSEDET = 923 OR CAUSEDET = 925 OR 
	  CAUSEDET = 926  OR  (CAUSEDT4 GE 9290 AND CAUSEDT4 LE 9295) OR 
	  CAUSEDT4 = 9555 OR CAUSEDT4 = 9559 OR 
	  CAUSEDT4 = 9580 OR CAUSEDT4 = 9584 OR
	  CAUSEDT4 = 9601 OR (CAUSEDT4 GE 9655 AND CAUSEDT4 LE 9659) OR 
	  CAUSEDET = 967  OR CAUSEDT4 = 9684 OR 
	  CAUSEDET = 971  OR CAUSEDET = 978 OR
	  CAUSEDT4 = 9855 OR
 	  CAUSEDT4 = 9880 OR CAUSEDT4 = 9884 OR 
	 (CAUSEDET GE 990 AND CAUSEDET LE 994) OR CAUSEDET = 996 OR 
	  CAUSEDT4 = 9970 OR CAUSEDT4 = 9971 OR CAUSEDT4 = 9972 OR
	  CAUSEDT4 = 9224 OR CAUSEDT4 = 9225 OR 
      CAUSEDT4 = 9283 OR CAUSEDT4 = 9284 OR CAUSEDT4 = 9285 OR CAUSEDT4 = 9286 OR 
	  CAUSEDT4 = 9556 OR CAUSEDT4 = 9557 OR
      CAUSEDT4 = 9686 OR CAUSEDT4 = 9687 OR
	  CAUSEDT4 = 9856 OR CAUSEDT4 = 9857 OR
	 (CAUSEDET = 979 AND (CAUSEDT4 NOT IN (9793, 9794, 9796, 9797))) 
THEN OTHER=1;

  IF OTHER =1 THEN CAUSE=16;

  /*CAUSE=NEC*/
  IF CAUSEDT4 = 9288 OR CAUSEDT4 = 9298 OR 
	 CAUSEDT4 = 9588 OR CAUSEDET = 959  OR 
	 CAUSEDT4 = 9688 OR CAUSEDET = 969  OR
	 CAUSEDET = 995  OR CAUSEDT4 = 9978 OR 
	 CAUSEDET = 977  OR 
	 CAUSEDET = 998  OR CAUSEDET = 999 OR
	 CAUSEDT4 = 9888 OR CAUSEDET = 989 THEN NEC=1;

  IF NEC=1 THEN CAUSE=17;

  /*CAUSE=NOT SPECIFIED*/
  IF CAUSEDET = 887 OR CAUSEDT4 = 9289 OR CAUSEDT4 = 9299 OR
	 CAUSEDT4 = 9589 OR 
	 CAUSEDT4 = 9689 OR 
	 CAUSEDET = 976 OR CAUSEDT4 = 9979 OR 
	 CAUSEDT4 = 9889  THEN NOTSPEC=1;

  IF NOTSPEC=1 THEN CAUSE=18;

  /*COUNT ALL ADVERSE EFFECTS; NOT INLCUDED AS ONE OF THE CAUSE*/
  IF (CAUSEDET GE 870 AND CAUSEDET LE 879) THEN MEDCARE=1;

  IF (CAUSEDET GE 930 AND CAUSEDET LE 949) THEN DRUGS=1;

  IF MEDCARE=1 OR DRUGS=1 THEN ADVERSE=1;

    /* MANNER-INTENT CODING */
		/*UNINT*/
  IF (CAUSEDET GE 800 AND CAUSEDET LE 869) OR 
	 (CAUSEDET GE 880 AND CAUSEDET LE 929) THEN INJ=1;
	 	/*SUI*/
  IF  CAUSEDET GE 950 AND CAUSEDET LE 959 THEN INJ=2;
  		/*HOM*/
  IF  CAUSEDET GE 960 AND CAUSEDET LE 969 OR 
	  CAUSEDET = 979 OR CAUSEDT4= 9991 THEN INJ=3;
  		/*OTHER*/
  IF (CAUSEDET GE 970 AND CAUSEDET LE 978) OR
	 (CAUSEDT4 GE 9900 AND CAUSEDT4 LE 9990) THEN INJ=4;
	 	/*UNDETERMINED*/
  IF (CAUSEDET GE 980 AND CAUSEDET LE 989) THEN INJ=5;
  run;


proc sort data=matrix9e nodupkey;
by snz_uid event_id cause inj;
run;


**recreate variable for count of ecodes;
proc sort data=matrix9e;
by event_id;
run;

data matrix9e;
set matrix9e;
ecode_nbr + 1;
by event_id;
if first.event_id then ecode_nbr = 1;
run;

proc freq data=matrix9e;
table ecode_nbr;
run;




PROC FORMAT;
VALUE CM 1='MVT'
         11='OTHER PEDAL CYC'
         12='OTHER PEDESTRIAN'
         13='OTHER TRANS'
         2='FIREARM'
         3='POISONING'
         4='FALLS'
         5='SUFFOCATION'
         6='DROWNING'
         7='FIRE/BURN'
         8='CUT/PIERCE'
         9='STRUCK BY/AGAINST'
         10='MACHINERY'
         14='NATURAL/ENVIR'
         15='OVEREXERTION'
         16='OTHER SPEC'
         17='NEC'
         18='NOT SPECIFIED' ;
VALUE MVPM 1='OCCUPANT'
            2='MOTORCYCLIST'
            3='PEDAL CYCLIST'
            4='PEDESTRIAN'
            5='UNKNOWN'
            6='OTHER' ;
VALUE INJM 1='UNINTENTIONAL'
           2='SELF-INFLICTED'
           3='ASSAULT'
           4='OTHER'
           5='UNDETERMINED';
		   run;

PROC FREQ data=matrix9e;
  TABLES   CAUSE INJ CAUSE*INJ;
  TITLE    INJURY MORTALITY MATRIX;
  FORMAT    INJ INJM. CAUSE CM. ;
  run;


*making wide;
  data inj1 (keep=snz_uid event_id cause1 inj1);
  set matrix9e;
  if ecode_nbr=1;
  cause1=cause;
  inj1=inj;
  run;
  data inj2 (keep=snz_uid event_id cause2 inj2);
  set matrix9e;
  if ecode_nbr=2;
  cause2=cause;
  inj2=inj;
  run;
  data inj3 (keep=snz_uid event_id cause3 inj3);
  set matrix9e;
  if ecode_nbr=3;
  cause3=cause;
  inj3=inj;
  run;
  data inj4 (keep=snz_uid event_id cause4 inj4);
  set matrix9e;
  if ecode_nbr=4;
  cause4=cause;
  inj4=inj;
  run;
  data inj5 (keep=snz_uid event_id cause5 inj5);
  set matrix9e;
  if ecode_nbr=5;
  cause5=cause;
  inj5=inj;
  run;
  data inj6 (keep=snz_uid event_id cause6 inj6);
  set matrix9e;
  if ecode_nbr=6;
  cause6=cause;
  inj6=inj;
  run;

proc sort data=inj1; by event_id; run;
proc sort data=inj2; by event_id; run;
proc sort data=inj3; by event_id; run;
proc sort data=inj4; by event_id; run;
proc sort data=inj5; by event_id; run;
proc sort data=inj6; by event_id; run;
data matrix_wide;
merge inj1 inj2 inj3 inj4 inj5 inj6;
by event_id;
run;
proc means data=matrix_wide;
run;






*********************************************;
*************SITE BY TYPE MATRIX*************;
*********************************************;
**checking matrix input variables;
proc freq data=coh_inj3;
table dx13 dx14 dx15 d5;
run;

DATA BARELL;
set coh_inj3; 
*********************************;
**RESTRICT TO PRIMARY DIAGNOSIS**;
*IF DIAGTYPE = 'A'; * only primary diagnoses included, see lines 37-62 above; 
*********************************;
IF ('800' <=DX13<= '829') THEN ISRCODE=1;
IF DX13 GE '830' AND DX13 LE '839' THEN ISRCODE=2;
IF DX13 GE '840' AND DX13 LE '848' THEN ISRCODE=3;
IF ('860'<=DX13<='869') OR ('850'<=DX13<='854') OR DX13='952' OR DX15='99555' THEN ISRCODE=4;                    
IF ('870' <=DX13<= '884') OR ('890' <=DX13<= '894') THEN ISRCODE=5;
IF ('885' <=DX13<= '887') OR ('895' <=DX13<= '897') THEN ISRCODE=6;
IF DX13 GE '900' AND DX13 LE '904' THEN ISRCODE=7;
IF DX13 GE '910' AND DX13 LE '924' THEN ISRCODE=8;
IF DX13 GE '925' AND DX13 LE '929' THEN ISRCODE=9;
IF DX13 GE '940' AND DX13 LE '949' THEN ISRCODE=10;
IF (DX13 GE '950' AND DX13 LE '951') OR ('953'<=DX13<='957') THEN ISRCODE=11;
IF DX13= '959' THEN ISRCODE=12;
IF ('930'<=DX13<='939') OR ('960'<=DX13<='994') OR ('905'<=DX13
<='908') OR ('9090'<=DX14<='9092') OR DX13='958' OR              
('99550'<=DX15<='99554') OR DX15='99559'                        
OR DX14='9094' OR DX14='9099'                                    
OR ('99580'<=DX15<='99585') THEN ISRCODE=13;          
IF ('8001'<=DX14<='8004') OR ('8006'<=DX14<='8009') OR              ('80003'<=DX15<='80005') OR ('80053'<=DX15<='80055') OR       
('8011'<=DX14<='8014') OR ('8016'<=DX14<='8019') OR                 ('80103'<=DX15<='80105') OR ('80153'<=DX15<='80155') OR       
('8031'<=DX14<='8034') OR ('8036'<=DX14<='8039') OR              
('80303'<=DX15<='80305') OR ('80353'<=DX15<='80355') OR       
('8041'<=DX14<='8044') OR ('8046'<=DX14<='8049') OR                ('80403'<=DX15<='80405') OR ('80453'<=DX15<='80455') OR         ('8502'<=DX14<='8504') OR ('851'<=DX13<='854') OR                 ('9501'<=DX14<='9503') OR DX15='99555' THEN ISRSITE=1;
IF DX15='80000' OR DX15='80002' OR DX15='80006' OR DX15='80009' OR
DX15='80100' OR DX15='80102' OR DX15='80106' OR DX15='80109' OR
DX15='80300' OR DX15='80302' OR DX15='80306' OR DX15='80309' OR
DX15='80400' OR DX15='80402' OR DX15='80406' OR DX15='80409' OR 
DX15='80050' OR DX15='80052' OR DX15='80056' OR DX15='80059' OR 
DX15='80150' OR DX15='80152' OR DX15='80156' OR DX15='80159' OR  
DX15='80350' OR DX15='80352' OR DX15='80356' OR DX15='80359' OR 
DX15='80450' OR DX15='80452' OR DX15='80456' OR DX15='80459' OR 
DX14='8500' OR DX14='8501' OR DX14='8505' OR DX14='8509' THEN ISRSITE=2;       
IF DX15='80001' OR DX15='80051' OR                               
DX15='80101' OR DX15='80151' OR                             
DX15='80301' OR DX15='80351' OR                                  
DX15='80401' OR DX15='80451' THEN ISRSITE=3;                                                         
IF (DX13='951') OR (DX14='8730' OR DX14='8731' OR DX14='8738'
OR DX14='8739') OR (DX13='941' AND D5='6')
OR DX15='95901' THEN ISRSITE=4; 
IF DX13='802' OR DX13='830' OR DX14='8480' OR DX14='8481' OR
DX13='872' OR ('8732'<=DX14<='8737') OR
(DX13='941' AND D5='1') OR (DX13='941' AND '3'<=D5<='5') OR
(DX13='941' AND D5='7') THEN ISRSITE=5; 
IF DX14='9500' OR DX14='9509' OR ('870'<=DX13<='871') OR
DX13='921' OR DX13='918' OR DX13='940' OR (DX13='941'
AND D5='2') THEN ISRSITE=6; 
IF ('8075'<=DX14<='8076') OR DX14='8482' OR DX14='9252'
OR DX14='9530' OR DX14='9540' OR DX13='874' OR
(DX13='941' AND D5='8') THEN ISRSITE=7; 
IF DX14='9251' OR DX13='900' OR DX14='9570' OR DX13='910'
OR DX13='920' OR DX14='9470' OR DX15='95909' OR
(DX13='941' AND (D5='0' OR D5='9')) THEN ISRSITE=8;
IF ('8060'<=DX14<='8061') OR (DX14='9520') THEN ISRSITE=9;
IF ('8062'<=DX14<='8063') OR (DX14='9521') THEN ISRSITE=10;
IF ('8064'<=DX14<='8065') OR (DX14='9522') THEN ISRSITE=11;
IF ('8066'<=DX14<='8067') OR ('9523'<=DX14<='9524') THEN ISRSITE=12;
IF ('8068'<=DX14<='8069') OR ('9528'<=DX14<='9529') THEN ISRSITE=13;
IF ('8050'<=DX14<='8051') OR ('8390'<=DX14<='8391') OR DX14='8470'
THEN ISRSITE=14;
IF ('8052'<=DX14<='8053') OR ('83921'=DX15 OR '83931'=DX15) OR
DX14='8471' THEN ISRSITE=15;
IF ('8054'<=DX14<='8055') OR ('83920'=DX15 OR '83930'=DX15) OR
DX14='8472' THEN ISRSITE=16;
IF ('8056'<=DX14<='8057') OR ('83941'=DX15 OR '83942'=DX15)OR ('83951'<=DX15<='83952') OR ('8473'<=DX14<='8474') THEN ISRSITE=17;
IF ('8058'<=DX14<='8059') OR ('83940'=DX15 OR '83949'=DX15)
OR ('83950'=DX15 OR DX15='83959') THEN ISRSITE=18;
IF ('8070'<=DX14<='8074') OR DX15='83961' OR DX15='83971' OR
('8483'<=DX14<='8484') OR DX15='92619' OR ('860'<=DX13<='862')
OR DX13='901' OR DX14='9531' OR DX13='875' OR DX14='8790' OR
DX14='8791' OR DX14='9220' OR DX14='9221' OR DX15='92233'
OR (DX13='942' AND (D5='1' OR D5='2')) THEN ISRSITE=19; 
IF ('863'<=DX13<='866') OR DX13='868' OR ('9020'<=DX14<='9024')
OR DX14='9532' OR DX14='9535' OR ('8792'<=DX14<='8795') OR
DX14='9222' OR (DX13='942' AND D5='3') OR DX14='9473'
THEN ISRSITE=20; 
IF DX13='808' OR DX15='83969' OR DX15='83979' OR DX13='846' OR
DX14='8485' OR DX14='9260' OR DX15='92612' OR DX13='867' OR
DX14='9025' OR ('90281'<=DX15<='90282') OR DX14='9533' OR ('877'
<=DX13<='878') OR DX14='9224' OR (DX13='942' AND D5='5') OR
DX14='9474' THEN ISRSITE=21; 
IF DX13='809' OR ('9268'<=DX14<='9269') OR DX14='9541' OR
('9548'<=DX14<='9549') OR ('8796'<=DX14<='8797') OR
('9228'<=DX14<='9229') OR DX13='911' OR (DX13='942' AND D5='0')
OR (DX13='942' AND D5='9') OR DX14='9591' THEN ISRSITE=22; 
IF DX14='8479' OR DX15='92611' OR DX13='876' OR DX15='92232'
OR DX15='92231' OR (DX13='942' AND D5='4') THEN ISRSITE=23; 
IF ('810'<=DX13<='812') OR DX13='831' OR DX13='840' OR DX13='880' OR '8872'<=DX14<='8873' OR (DX13='943' AND '3'<=D5<='6') OR DX13='912' OR DX14='9230' OR DX14='9270' OR DX14='9592' THEN ISRSITE=24;
IF DX13='813' OR DX13='832' OR DX13='841' OR (DX13='881' AND '0'<=D5<='1') OR ('8870'<=DX14<='8871') OR DX14='9231' OR DX14='9271' OR (DX13='943' AND '1'<=D5<='2') THEN ISRSITE=25;
IF ('814'<=DX13<='817') OR ('833'<=DX13<='834') OR DX13='842' OR (DX13='881' AND D5='2') OR '882'<=DX13<='883' OR '885'<=DX13<='886' OR '914'<=DX13<='915' OR '9232'<=DX14<='9233' OR '9272'<=DX14<='9273' OR DX13='944' OR '9594'<=DX14<='9595' THEN ISRSITE=26;
IF DX13='818' OR DX13='884' OR '8874'<=DX14<='8877' OR DX13='903' OR DX13='913' OR DX14='9593' OR '9238'<=DX14<='9239' OR '9278'<=DX14<='9279' OR DX14='9534' OR DX13='955' OR (DX13='943' AND (D5='0' OR D5='9')) THEN ISRSITE=27;
IF DX13='820' OR DX13='835' OR DX13='843' OR DX15='92401' OR DX15='92801' THEN ISRSITE=28; 
IF DX13='821' OR '8972'<=DX14<='8973' OR DX15='92400' OR DX15='92800' OR (DX13='945' AND D5='6') THEN ISRSITE=29;
IF DX13='822' OR DX13='836' OR '8440'<=DX14<='8443' OR DX15='92411' OR DX15='92811' OR (DX13='945' AND D5='5') THEN ISRSITE=30;    
IF '823'<=DX13<='824' OR '8970'<=DX14<='8971' OR DX13='837' OR DX14='8450' OR DX15='92410' OR DX15='92421' OR DX15='92810' OR DX15='92821' OR (DX13='945' AND '3'<=D5<='4') THEN ISRSITE=31;
IF '825'<=DX13<='826' OR DX13='838' OR DX14='8451' OR '892'<=DX13<= '893' OR '895'<=DX13<='896' OR DX13='917' OR DX15='92420' OR DX14= '9243' OR DX15='92820' OR DX14='9283' OR (DX13='945' AND '1'<=D5<='2') THEN ISRSITE=32;
IF DX13='827' OR '8448'<=DX14<='8449' OR '890'<=DX13<='891' OR DX13='894' OR '8974'<=DX14<='8977' OR '9040'<=DX14<='9048' OR DX13='916' OR '9244'<=DX14<='9245' OR DX14='9288' OR DX14='9289' OR '9596'<=DX14<='9597' OR (DX13='945' AND (D5='0' OR D5='9')) THEN ISRSITE=33;
IF DX13='828' OR DX13='819' OR DX15='90287' OR DX15='90289' OR DX14='9538' OR '9471'<=DX14<='9472' OR DX13='956' THEN ISRSITE=34; 
IF DX13='829' OR '8398'<=DX14<='8399' OR '8488'<=DX14<='8489' OR DX13='869' OR ('8798'<=DX14<='8799') OR DX14='9029' OR DX14='9049' OR DX13='919' OR '9248'<=DX14<='9249' OR DX13='929' OR DX13='946' OR '9478'<=DX14<='9479' OR '948'<=DX13<='949' OR DX14='9539' OR DX14='9571' OR '9578'<=DX14<='9579' OR '9598'<=DX14<='9599' THEN ISRSITE=35;
IF ('930'<=DX13<='939') OR ('960'<=DX13<='994') OR ('905'<=DX13 <='908') OR ('9090'<=DX14<='9092') OR DX13='958' OR ('99550'<=DX15 <='99554') OR DX15='99559' OR DX14='9094' OR DX14='9099' OR ('99580'<=DX15<='99585') THEN ISRSITE=36; 
IF ISRSITE >=1 AND ISRSITE <=3 THEN ISRSITE2=1; 
IF ISRSITE >=4 AND ISRSITE <=8 THEN ISRSITE2=2;
IF ISRSITE >=9 AND ISRSITE <=13 THEN ISRSITE2=3;
IF ISRSITE >=14 AND ISRSITE <=18 THEN ISRSITE2=4;
IF ISRSITE >=19 AND ISRSITE <=23 THEN ISRSITE2=5; 
IF ISRSITE >=24 AND ISRSITE <=27 THEN ISRSITE2=6;
IF ISRSITE >=28 AND ISRSITE <=33 THEN ISRSITE2=7;
IF ISRSITE >=34 AND ISRSITE <=35 THEN ISRSITE2=8;
IF ISRSITE = 36 THEN ISRSITE2 = 9;
IF ISRSITE >=1 AND ISRSITE <=8 THEN ISRSITE3=1; 
IF ISRSITE >=9 AND ISRSITE <=18 THEN ISRSITE3=2;
IF ISRSITE >=19 AND ISRSITE <=23 THEN ISRSITE3=3;
IF ISRSITE >=24 AND ISRSITE <=33 THEN ISRSITE3=4;
IF ISRSITE >=34 AND ISRSITE <=36 THEN ISRSITE3 = 5;
RUN;

PROC FORMAT;
VALUE ISM
1='TYPE 1 TBI'
2='TYPE 2 TBI'
3='TYPE 3 TBI'
4='OTHER HEAD'
5='FACE'
6='EYE' 
7='NECK'
8='HEAD,FACE,NECK UNSPEC'
9='CERVICAL SCI'
10='THORACIC/DORSAL SCI'
11='LUMBAR SCI'
12='SACRUM COCCYX SCI'
13='SPINE+BACK UNSPEC SCI'
14='CERVICAL VCI'
15='THORACIC/DORSAL VCI' 
16='LUMBAR VCI'
17='SACRUM COCCYX VCI'
18='SPINE,BACK UNSPEC VCI'
19='CHEST'
20='ABDOMEN'
21='PELVIS+UROGENITAL'
22='TRUNK'
23='BACK+BUTTOCK'
24='SHOULDER&UPPER ARM'
25='FOREARM&ELBOW'
26='HAND&WRIST&FINGERS'            
27='OTHER&UNSPEC UPPER EXTREM'    
28='HIP' 
29='UPPER LEG&THIGH'
30='KNEE'
31='LOWER LEG&ANKLE'              
32='FOOT&TOES'  
33='OTHER&UNSPEC LOWER EXTREM'                   
34='OTHER,MULTIPLE,NEC'
35='UNSPECIFIED'
36='SYSTEM WIDE & LATE EFFECTS';
VALUE I2M
1='TBI'                 
2='OTH HEAD,FACE,NECK'              
3='SCI'                             
4='VCI '                                    
5='TORSO'             
6='UPPER EXTREMITY'                         
7='LOWER EXTREMITY'                         
8='OTHER & UNSPECIFIED'                       
9='SYSTEM WIDE & LATE EFFECTS' ;
VALUE I3M
1='HEAD&NECK' 
2='SPINE&BACK'
3='TORSO'
4='EXTREMITIES' 
5='UNCLASSIFIABLE BY SITE'; 
VALUE INM
1='FRACTURES '
2='DISLOCATION'
3='SPRAINS&STRAINS'
4='INTERNAL ORGAN '
5='OPEN WOUNDS'
6='AMPUTATIONS'
7='BLOOD VESSELS'
8='SUPERFIC/CONT'
9='CRUSHING'
10='BURNS'
11='NERVES'
12='UNSPECIFIED'
13='SYSTEM WIDE & LATE EFFECTS'; 
RUN;

PROC FREQ DATA=BARELL;
TABLES ISRCODE ISRSITE ISRSITE2 ISRSITE*ISRSITE2 (ISRSITE ISRSITE2)*ISRCODE ;
TITLE DX MATRIX FOR ALL INJURIES;
FORMAT ISRCODE INM. ISRSITE2 I2M. ISRSITE ISM. ;
RUN; 


proc freq data=barell (where=(isrcode=.));
table icd9code;
run;


proc freq data=barell (where=(isrsite=.));
table icd9code;
run;





***********************************************;
**adding cause x intent matric to barell matrix;
***********************************************;
proc sort data=barell; by event_id; run;
proc sort data=matrix_wide; by event_id; run;

data matrices (KEEP=snz_uid event_id hosp_start icd9code icd10code ecode9 ISRCODE ISRSITE ISRSITE2
cause1 inj1 cause2 inj2 cause3 inj3 cause4 inj4 cause5 inj5 cause6 inj6);
merge barell matrix_wide;
by event_id; 
run;

*checking missingness pattern;
proc means data=matrices (where=(ISRCODE=.)); run;*some with cause & inj data (up to 3);
proc means data=matrices (where=(ISRSITE=.)); run;
proc means data=matrices (where=(cause1=.)); run;
proc means data=matrices (where=(inj1=.)); run;

**dropping those without ISRCODE;
data matrices2;
set matrices;
if ISRCODE~=.;
run;

proc means data=matrices2;
var snz_uid event_id ISRCODE inj1;
run;












**************************************************************************************;
*******************************ADDING EXPOSURE DATES**********************************;
**************************************************************************************;
proc sort data=matrices2; by snz_uid hosp_start; run;
proc sort data=COHORT_4; by snz_uid; run;

data injuries;
merge matrices2 cohort_4;
by snz_uid;
if event_id ~=.;
if hosp_start < start_date then inj_order = 1; *PRIOR TO MH event or matched start date;
if ((year(hosp_start) = year(start_date)) & (month(hosp_start) = month(start_date))) 
then inj_order = 2; *IN SAME MONTH AS MH event or matched start date;
if inj_order = . then inj_order = 3; *AFTER MH event or matched start date;
run;


proc means data=injuries;
var snz_uid event_id ISRCODE inj1;
run;

proc freq data=injuries;
table inj_order MH*inj_order;
run;


**Checking if MH diagnosis is associated with 'same month' hospitalization;
proc freq data=injuries (where=(Anxiety=1));table inj_order;run; *4.0%;
proc freq data=injuries (where=(ChildOnset=1));table inj_order;run; *1.4%;
proc freq data=injuries (where=(Mood=1));table inj_order;run; *5.3%;
proc freq data=injuries (where=(Personality=1));table inj_order;run; *2.6%;
proc freq data=injuries (where=(Physiol_Disturb=1));table inj_order;run; *2.1%;
proc freq data=injuries (where=(Psychosis=1));table inj_order;run; *2.5%;
proc freq data=injuries (where=(SUD=1));table inj_order;run; *2.2%;
proc freq data=injuries (where=(Unspecified=1));table inj_order;run; *2.6%;
*All disproportionately in same month, Anxiety and Mood especially so;

**Creating previous hospitalization indicator, 
counting only hospitalizations that happened in the subsequent month;

proc freq data=injuries (where=(inj_order=1 or inj_order=2)) noprint;
table snz_uid /out=temp;
run;


data prev_inj (keep=snz_uid prev_inj n_prev_inj);
set temp;
prev_inj=1;
n_prev_inj = count;
run;


proc format;
VALUE site6m
1='TBI'                 
2='OTH HEAD,FACE,NECK'              
3='SPINE&BACK'
4='TORSO'
5='EXTREMITIES' 
6='UNCLASSIFIABLE BY SITE';
run;

data temp2 (keep=snz_uid hosp_start start_date inj_order inj1-inj6 isrsite3);
set injuries;
if inj_order=3;
if isrsite2=1 then isrsite3=1;
if isrsite2=2 then isrsite3=2;
if isrsite2=3 then isrsite3=3;
if isrsite2=4 then isrsite3=3;
if isrsite2=5 then isrsite3=4;
if isrsite2=6 then isrsite3=5;
if isrsite2=7 then isrsite3=5;
if isrsite2=8 then isrsite3=6;
if isrsite2=9 then isrsite3=6;
if isrsite2=. then isrsite3=6;
format isrsite3 site6m.;
run;



*keeping first injury;
proc sort data=temp2;
by snz_uid hosp_start;
run;

data temp3;
set temp2;
by snz_uid;
if first.snz_uid;
inj_unint=0;
inj_self=0;
inj_assault=0;
inj_other=0;
inj_undet=0;
if (inj1=1 | inj2=1 | inj3=1 | inj4=1 | inj5=1 | inj6=1) then inj_unint=1; 
if (inj1=2 | inj2=2 | inj3=2 | inj4=2 | inj5=2 | inj6=2) then inj_self=1; 
if (inj1=3 | inj2=3 | inj3=3 | inj4=3 | inj5=3 | inj6=3) then inj_assault=1; 
if (inj1=4 | inj2=4 | inj3=4 | inj4=4 | inj5=4 | inj6=4) then inj_other=1; 
if (inj1=5 | inj2=5 | inj3=5 | inj4=5 | inj5=5 | inj6=5) then inj_undet=1; 
injtype_nbr = inj_unint + inj_self + inj_assault + inj_other + inj_undet;
run;

proc freq data=temp3;
table inj_unint inj_self inj_assault inj_other inj_undet injtype_nbr isrsite3;
run; 

proc freq data=temp3 (where=(injtype_nbr>1));
table inj_unint inj_self inj_assault inj_other inj_undet;
run; 
*mostly unintentional with assault/self-harm, by the looks;
*PRIORITISING: self, then assault, then unint, then other, remainder=undetermined;

data temp4 (drop= start_date inj_order inj1-inj6 injtype_nbr);
set temp3;
inj=5;
if inj_other=1 then inj=4;
if inj_unint=1 then inj=1;
if inj_assault=1 then inj=3;
if inj_self=1 then inj=2;
FORMAT    INJ INJM.;
run;

proc freq data=temp4;
table inj;
run;


proc freq data=injuries (where=(inj_order=3)) noprint;
table snz_uid /out=temp5;
run;

proc freq data=temp5; table count; run;



******************************************************************;
************************NEW CODE 2 FEB 2024***********************;
*************NUMBER OF INJURIES EXCLUDING SELF HARM***************;
******************************************************************;

data nonsh;
set injuries;
if inj_order=3;
if (inj1~=2 & inj2~=2 & inj3~=2 & inj4~=2 & inj5~=2 & inj6~=2);
run;


proc freq data=nonsh noprint;
table snz_uid /out=temp6;
run;


data temp7 (drop=count percent);
set temp6;
nsh_post_inj=1;
nsh_n_post_inj = count;
run;

proc freq data=temp7; table nsh_n_post_inj; run;

proc sort data=temp4; by snz_uid; run;
proc sort data=temp5; by snz_uid; run;
proc sort data=temp7; by snz_uid; run;

data post_inj (drop=count percent);
merge temp4 temp5 temp7;
by snz_uid;
post_inj=1;
n_post_inj = count;
run;





******************************************************************************;
****************************NEW CODE 17 FEB 2024******************************;
****CAPTURING ALL INJURY TYPES TO ENABLE ALL NON-SH INJURIES TO BE ANALYSED***;
******************************************************************************;

data injall;
set temp2;
inj_unint=0;
inj_self=0;
inj_assault=0;
inj_other=0;
inj_undet=0;
if (inj1=1 | inj2=1 | inj3=1 | inj4=1 | inj5=1 | inj6=1) then inj_unint=1; 
if (inj1=2 | inj2=2 | inj3=2 | inj4=2 | inj5=2 | inj6=2) then inj_self=1; 
if (inj1=3 | inj2=3 | inj3=3 | inj4=3 | inj5=3 | inj6=3) then inj_assault=1; 
if (inj1=4 | inj2=4 | inj3=4 | inj4=4 | inj5=4 | inj6=4) then inj_other=1; 
if (inj1=5 | inj2=5 | inj3=5 | inj4=5 | inj5=5 | inj6=5) then inj_undet=1; 
injtype_nbr = inj_unint + inj_self + inj_assault + inj_other + inj_undet;
run;


proc freq data=injall;
table inj_unint inj_self inj_assault inj_other inj_undet injtype_nbr isrsite3;
run;


proc freq data=injall (where=(injtype_nbr>1));
table inj_unint inj_self inj_assault inj_other inj_undet ;
run;
*mostly unintentional with assault/self-harm;
*PRIORITISING: self, then assault, then unint, then other, 
remainder (including where not specified)=undetermined;

data injall2;
set injall;
if injtype_nbr=0 then inj_undet=1;
if inj_self= 1 then do;
inj_assault=0; inj_unint=0; inj_other=0; inj_undet=0;
end;
if inj_assault= 1 then do;
inj_unint=0; inj_other=0; inj_undet=0;
end;
if inj_unint= 1 then do;
inj_other=0; inj_undet=0;
end;
if inj_other=1 then inj_undet=0;
injtype_nbr_2 = inj_unint + inj_self + inj_assault + inj_other + inj_undet;
run;

proc freq data=injall2;
table inj_unint inj_self inj_assault inj_other inj_undet injtype_nbr injtype_nbr_2 isrsite3;
run;
****ALL INJURIES NOW HAVE ONE AND ONLY ONE TYPE****;

***CREATING A PERSON-LEVEL FILE WITH INDICATOR FOR EACH POST_INJ TYPE/SITE;

*unintentional;
proc freq data=injall2 (where=(inj_unint=1)) noprint;
table snz_uid / out= unint; run;
data unint2 (keep=snz_uid inj_unint); set unint; inj_unint=1; run;


*self harm;
proc freq data=injall2 (where=(inj_self=1)) noprint;
table snz_uid / out= sh; run;
data sh2 (keep=snz_uid inj_self); set sh; inj_self=1; run;


*assault;
proc freq data=injall2 (where=(inj_assault=1)) noprint;
table snz_uid / out= assault; run;
data assault2 (keep=snz_uid inj_assault); set assault; inj_assault=1; run;


*other;
proc freq data=injall2 (where=(inj_other=1)) noprint;
table snz_uid / out= other; run;
data other2 (keep=snz_uid inj_other); set other; inj_other=1; run;


*undetermined;
proc freq data=injall2 (where=(inj_undet=1)) noprint;
table snz_uid / out= undet; run;
data undet2 (keep=snz_uid inj_undet); set undet; inj_undet=1; run;


*tbi;
proc freq data=injall2 (where=(isrsite3=1)) noprint;
table snz_uid / out= tbi; run;
data tbi2 (keep=snz_uid tbi); set tbi; tbi=1; run;


*other head, face & neck;
proc freq data=injall2 (where=(isrsite3=2)) noprint;
table snz_uid / out= othheadfaceneck; run;
data othheadfaceneck2 (keep=snz_uid othheadfaceneck); set othheadfaceneck; othheadfaceneck=1; run;


*spine & back;
proc freq data=injall2 (where=(isrsite3=3)) noprint;
table snz_uid / out= spineback; run;
data spineback2 (keep=snz_uid spineback); set spineback; spineback=1; run;


*torso;
proc freq data=injall2 (where=(isrsite3=4)) noprint;
table snz_uid / out= torso; run;
data torso2 (keep=snz_uid torso); set torso; torso=1; run;


*extremities;
proc freq data=injall2 (where=(isrsite3=5)) noprint;
table snz_uid / out= extremities; run;
data extremities2 (keep=snz_uid extremities); set extremities; extremities=1; run;


*unclassified;
proc freq data=injall2 (where=(isrsite3=6)) noprint;
table snz_uid / out= unclassified; run;
data unclassified2 (keep=snz_uid unclassified); set unclassified; unclassified=1; run;



data injall_wide;
merge unint2 sh2 assault2 other2 undet2 
tbi2 othheadfaceneck2 spineback2 torso2 extremities2 unclassified2;
by snz_uid;
post_inj=1;
if (inj_unint=1 or inj_assault=1 or inj_other=1 or inj_undet=1) then nsh_post_inj=1;
run;


proc freq data=injall_wide;
table inj_unint inj_assault inj_other inj_undet post_inj nsh_post_inj 
tbi othheadfaceneck spineback torso extremities unclassified;
run;



***COUNTING ALL INJURIES***;
proc freq data=injall2 noprint;
table snz_uid /out=temp11;
run;
data temp12 (drop=count percent);
set temp11;
n_post_inj = count;
run;
proc freq data=temp12; table n_post_inj; run;


***COUNTING ALL NON-SELF HARM INJURIES***;
proc freq data=injall2 (where=(inj_self=0)) noprint;
table snz_uid /out=temp13;
run;
data temp14 (drop=count percent);
set temp13;
nsh_n_post_inj = count;
run;
proc freq data=temp14; table nsh_n_post_inj; run;


******************************************;
***********MERGING ALL TOGETHER***********;
******************************************;

proc sort data=injall_wide; by snz_uid; run;
proc sort data=temp12; by snz_uid; run;
proc sort data=temp14; by snz_uid; run;

data injall_wide2;
merge injall_wide temp12 temp14;
by snz_uid; run;

*********************;
*********************;
*********************;


******************************************************************************;
****************************NEW CODE 10 MAR 2024******************************;
**************CAPTURING ALL INJURY TYPES ACROSS FULL 30-YR WINDOW*************;
******************************************************************************;

proc format;
VALUE site6m
1='TBI'                 
2='OTH HEAD,FACE,NECK'              
3='SPINE&BACK'
4='TORSO'
5='EXTREMITIES' 
6='UNCLASSIFIABLE BY SITE';
run;

data inj_anytime (keep=snz_uid hosp_start start_date inj_order inj1-inj6 isrsite3
injtype_nbr inj_unint inj_self inj_assault inj_other inj_undet);
set file.injuries;
*includes inj_order = {1,2,3};

if isrsite2=1 then isrsite3=1;
if isrsite2=2 then isrsite3=2;
if isrsite2=3 then isrsite3=3;
if isrsite2=4 then isrsite3=3;
if isrsite2=5 then isrsite3=4;
if isrsite2=6 then isrsite3=5;
if isrsite2=7 then isrsite3=5;
if isrsite2=8 then isrsite3=6;
if isrsite2=9 then isrsite3=6;
if isrsite2=. then isrsite3=6;
format isrsite3 site6m.;

inj_unint=0;
inj_self=0;
inj_assault=0;
inj_other=0;
inj_undet=0;
if (inj1=1 | inj2=1 | inj3=1 | inj4=1 | inj5=1 | inj6=1) then inj_unint=1; 
if (inj1=2 | inj2=2 | inj3=2 | inj4=2 | inj5=2 | inj6=2) then inj_self=1; 
if (inj1=3 | inj2=3 | inj3=3 | inj4=3 | inj5=3 | inj6=3) then inj_assault=1; 
if (inj1=4 | inj2=4 | inj3=4 | inj4=4 | inj5=4 | inj6=4) then inj_other=1; 
if (inj1=5 | inj2=5 | inj3=5 | inj4=5 | inj5=5 | inj6=5) then inj_undet=1; 
injtype_nbr = inj_unint + inj_self + inj_assault + inj_other + inj_undet;
run;


proc freq data=inj_anytime;
table inj_unint inj_self inj_assault inj_other inj_undet injtype_nbr isrsite3;
run;


proc freq data=inj_anytime (where=(injtype_nbr>1));
table inj_unint inj_self inj_assault inj_other inj_undet ;
run;
*mostly unintentional with assault/self-harm;
*PRIORITISING: self, then assault, then unint, then other, 
remainder (including where not specified)=undetermined;

data inj_anytime2;
set inj_anytime;
if injtype_nbr=0 then inj_undet=1;
if inj_self= 1 then do;
inj_assault=0; inj_unint=0; inj_other=0; inj_undet=0;
end;
if inj_assault= 1 then do;
inj_unint=0; inj_other=0; inj_undet=0;
end;
if inj_unint= 1 then do;
inj_other=0; inj_undet=0;
end;
if inj_other=1 then inj_undet=0;
injtype_nbr_2 = inj_unint + inj_self + inj_assault + inj_other + inj_undet;
run;

proc freq data=inj_anytime2;
table inj_unint inj_self inj_assault inj_other inj_undet injtype_nbr injtype_nbr_2 isrsite3;
run;
****ALL INJURIES NOW HAVE ONE AND ONLY ONE TYPE****;

***CREATING A PERSON-LEVEL FILE WITH INDICATOR FOR EACH POST_INJ TYPE/SITE;

*unintentional;
proc freq data=inj_anytime2 (where=(inj_unint=1)) noprint;
table snz_uid / out= unint; run;
data unint_at (keep=snz_uid unint_at); set unint; unint_at=1; run;


*self harm;
proc freq data=inj_anytime2 (where=(inj_self=1)) noprint;
table snz_uid / out= sh; run;
data sh_at (keep=snz_uid self_at); set sh; self_at=1; run;


*assault;
proc freq data=inj_anytime2 (where=(inj_assault=1)) noprint;
table snz_uid / out= assault; run;
data assault_at (keep=snz_uid assault_at); set assault; assault_at=1; run;


*other;
proc freq data=inj_anytime2 (where=(inj_other=1)) noprint;
table snz_uid / out= other; run;
data other_at (keep=snz_uid other_at); set other; other_at=1; run;


*undetermined;
proc freq data=inj_anytime2 (where=(inj_undet=1)) noprint;
table snz_uid / out= undet; run;
data undet_at (keep=snz_uid undet_at); set undet; undet_at=1; run;


*tbi;
proc freq data=inj_anytime2 (where=(isrsite3=1)) noprint;
table snz_uid / out= tbi; run;
data tbi_at (keep=snz_uid tbi_at); set tbi; tbi_at=1; run;


*other head, face & neck;
proc freq data=inj_anytime2 (where=(isrsite3=2)) noprint;
table snz_uid / out= othheadfaceneck; run;
data othheadfaceneck_at (keep=snz_uid othheadfaceneck_at); set othheadfaceneck; othheadfaceneck_at=1; run;


*spine & back;
proc freq data=inj_anytime2 (where=(isrsite3=3)) noprint;
table snz_uid / out= spineback; run;
data spineback_at (keep=snz_uid spineback_at); set spineback; spineback_at=1; run;


*torso;
proc freq data=inj_anytime2 (where=(isrsite3=4)) noprint;
table snz_uid / out= torso; run;
data torso_at (keep=snz_uid torso_at); set torso; torso_at=1; run;


*extremities;
proc freq data=inj_anytime2 (where=(isrsite3=5)) noprint;
table snz_uid / out= extremities; run;
data extremities_at (keep=snz_uid extremities_at); set extremities; extremities_at=1; run;


*unclassified;
proc freq data=inj_anytime2 (where=(isrsite3=6)) noprint;
table snz_uid / out= unclassified; run;
data unclassified_at (keep=snz_uid unclassified_at); set unclassified; unclassified_at=1; run;



data inj_at_wide;
merge unint_at sh_at assault_at other_at undet_at 
tbi_at othheadfaceneck_at spineback_at torso_at extremities_at unclassified_at;
by snz_uid;
inj_at=1;
if (unint_at=1 or assault_at=1 or other_at=1 or undet_at=1) then nsh_inj_at=1;
run;


proc freq data=inj_at_wide;
table unint_at self_at assault_at other_at undet_at inj_at nsh_inj_at  
tbi_at othheadfaceneck_at spineback_at torso_at extremities_at unclassified_at;
run;
 


***COUNTING ALL INJURIES***;
proc freq data=inj_anytime2 noprint;
table snz_uid /out=at1;
run;
data at2 (drop=count percent);
set at1;
n_inj_at = count;
run;
proc freq data=at2; table n_inj_at; run;


***COUNTING ALL NON-SELF HARM INJURIES***;
proc freq data=inj_anytime2 (where=(inj_self=0)) noprint;
table snz_uid /out=at3;
run;
data at4 (drop=count percent);
set at3;
nsh_n_inj_at = count;
run;
proc freq data=at4; table nsh_n_inj_at; run;


******************************************;
***********MERGING ALL TOGETHER***********;
******************************************;

proc sort data=inj_at_wide; by snz_uid; run;
proc sort data=at2; by snz_uid; run;
proc sort data=at4; by snz_uid; run;

data inj_at_wide2;
merge inj_at_wide at2 at4;
by snz_uid; run;

*********************;
*********************;
*********************;



**********NEW*****************;
**********NEW*****************;
**********NEW*****************;


****Analysis file;
data cohort_4; set file.cohort_4; run;
proc sort data=cohort_4; by snz_uid; run;
proc sort data=prev_inj; by snz_uid; run;
proc sort data=injall_wide2; by snz_uid; run;
proc sort data=inj_at_wide2; by snz_uid; run;


data inj_analysis_17Feb2024;
merge cohort_4 prev_inj injall_wide2 inj_at_wide2;
by snz_uid; 

if prev_inj=. then prev_inj=0;
if n_prev_inj=. then n_prev_inj=0;
if post_inj=. then post_inj=0;
if n_post_inj=. then n_post_inj=0;

if nsh_post_inj=. then nsh_post_inj=0;
if nsh_n_post_inj=. then nsh_n_post_inj=0;

if inj_unint=0 then inj_unint=.;
if inj_self=0 then inj_self=.;
if inj_assault=0 then inj_assault=.;
if post_inj=0 then inj_unint=0;
if post_inj=0 then inj_self=0;
if post_inj=0 then inj_assault=0;

if post_inj=0 then tbi=0; 
if post_inj=0 then othheadfaceneck=0; 
if post_inj=0 then spineback=0; 
if post_inj=0 then torso=0; 
if post_inj=0 then extremities=0; 
if post_inj=0 then unclassified=0; 

nsh_tbi=tbi; if nsh_post_inj=0 then nsh_tbi=0;
nsh_othheadfaceneck=othheadfaceneck; if nsh_post_inj=0 then nsh_othheadfaceneck=0;
nsh_spineback=spineback; if nsh_post_inj=0 then nsh_spineback=0;
nsh_torso=torso; if nsh_post_inj=0 then nsh_torso=0;
nsh_extremities=extremities; if nsh_post_inj=0 then nsh_extremities=0;
nsh_unclassified=unclassified; if nsh_post_inj=0 then nsh_unclassified=0;
*********;

***injury any time (at) variables***;
if inj_at=. then inj_at=0;
if n_inj_at=. then n_inj_at=0;
if nsh_inj_at=. then nsh_inj_at=0;
if nsh_n_inj_at=. then nsh_n_inj_at=0;

if unint_at=0 then unint_at=.;
if self_at=0 then self_at=.;
if assault_at=0 then assault_at=.;

if inj_at=0 then unint_at=0;
if inj_at=0 then self_at=0;
if inj_at=0 then assault_at=0;
if inj_at=0 then tbi_at=0; 
if inj_at=0 then othheadfaceneck_at=0; 
if inj_at=0 then spineback_at=0; 
if inj_at=0 then torso_at=0; 
if inj_at=0 then extremities_at=0; 
if inj_at=0 then unclassified_at=0;

nsh_tbi_at=tbi_at; if nsh_inj_at=0 then nsh_tbi_at=0;
nsh_othheadfaceneck_at=othheadfaceneck_at; if nsh_inj_at=0 then nsh_othheadfaceneck_at=0;
nsh_spineback_at=spineback_at; if nsh_inj_at=0 then nsh_spineback_at=0;
nsh_torso_at=torso_at; if nsh_inj_at=0 then nsh_torso_at=0;
nsh_extremities_at=extremities_at; if nsh_inj_at=0 then nsh_extremities_at=0;
nsh_unclassified_at=unclassified_at; if nsh_inj_at=0 then nsh_unclassified_at=0;

*********;
if Anxiety=. then Anxiety=0;
if ChildOnset=. then ChildOnset=0;
if Developmental=. then Developmental=0;
if Mood=. then Mood=0;
if Personality=. then Personality=0;
if Psychosis=. then Psychosis=0;
if SUD=. then SUD=0;
if Unspecified=. then Unspecified=0;
run;

*********************;
proc freq data=inj_analysis_17Feb2024;
*table post_inj nsh_post_inj inj_unint inj_self inj_assault;
*table n_post_inj nsh_n_post_inj;
*table tbi othheadfaceneck spineback torso extremities unclassified; 
*table nsh_tbi nsh_othheadfaceneck nsh_spineback nsh_torso nsh_extremities nsh_unclassified; 
table inj_at n_inj_at nsh_inj_at nsh_n_inj_at unint_at self_at assault_at other_at undet_at;
table tbi_at othheadfaceneck_at spineback_at torso_at extremities_at unclassified_at;
table nsh_tbi_at nsh_othheadfaceneck_at nsh_spineback_at nsh_torso_at nsh_extremities_at nsh_unclassified_at;
run;

proc freq data=post_inj; table post_inj inj_unint inj_self inj_assault; run;
proc freq data=alt_post_inj; table alt_post_inj ainj_unint ainj_self ainj_assault; run;



proc freq data=inj_analysis_28Aug2022;
table inj;
table post_inj*inj nsh_post_inj*inj;
run;








************************************************************;
************************************************************;
************************************************************;
************************************************************;
************************************************************;
************************************************************;


*SAVING;

DATA FILE.COHORT;
SET COHORT;
RUN;

DATA FILE.MATRIX9E;
SET MATRIX9E;
RUN;

DATA FILE.MATRIX_WIDE;
SET MATRIX_WIDE;
RUN;

DATA FILE.MATRICES2;
SET MATRICES2;
RUN;

DATA FILE.INJURIES;
SET INJURIES;
RUN;

DATA FILE.PREV_INJ;
SET PREV_INJ;
RUN;

DATA FILE.INJALL_WIDE2;
SET INJALL_WIDE2;
RUN;

DATA FILE.INJ_AT_WIDE2;
SET INJ_AT_WIDE2;
RUN;

data file.inj_analysis_17Feb2024;
set inj_analysis_17Feb2024;
run;
