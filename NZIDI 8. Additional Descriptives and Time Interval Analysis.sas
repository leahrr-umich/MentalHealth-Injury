
*********************************************************************
PROJECT: Mental Health and Injury
AUTHOR: S. D'Souza and B. Milne 
IDI Refresh: IDI_Clean_20211020
***
UPDATE TO IDI Refresh: IDI_Clean_202410

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
keep their data safe.
Careful consideration has been given to the privacy, security, and 
confidentiality issues associated with using administrative and 
survey data in the IDI. Further detail can be found in the Privacy 
impact assessment for the Integrated Data Infrastructure available 
from www.stats.govt.nz.
*********************************************************************;

libname sec ODBC dsn=IDI_Clean_202410_srvprd schema=security;
libname data ODBC dsn=IDI_Clean_202410_srvprd schema=data;
libname file "/nas/DataLab/MAA/MAA2019-35/Accidents/Data" ;



**************************************************
****************1 count of dep1cat****************
**************************************************;

proc freq data=file.totpop_dep;
table dep1cat;
run;

proc freq data=file.totpop_dep (where=(wgt>0));
table dep1cat;
run;




**************************************************
*******************Suppl Fig 1********************
**************************************************;

libname data ODBC dsn=idi_clean_202410_srvprd schema=data;
libname file "/nas/DataLab/MAA/MAA2019-35/Accidents/Data" ;
libname sec ODBC dsn=IDI_Clean_202410_srvprd schema=security;


**Checking numbers with original refresh;

proc means data=file.coh7079h_22Aug22; var snz_uid; run;
proc means data=file.coh6069h_22Aug22; var snz_uid; run;
proc means data=file.coh5059h_22Aug22; var snz_uid; run;
proc means data=file.coh4049h_22Aug22; var snz_uid; run;
proc means data=file.coh2939h_22Aug22; var snz_uid; run;

*************************************************************;


*get births;
proc sql;
connect to odbc(dsn=idi_clean_202410_srvprd);
	create table births as 
	select * from connection to odbc
		(select distinct snz_uid, dia_bir_birth_year_nbr, dia_bir_birth_month_nbr 
			from dia_clean.births) 
 ;
disconnect from odbc;
quit;

proc means data=births; var dia_bir_birth_year_nbr; run;

**********************************************
**CHECKING HOW MANY ARE IN ORIGINAL REFRESH***
**********************************************

*original refresh (link_set_key=41);
proc sql; 
create table ref20211020 as 
select link_set_key, snz_uid, snz_spine_uid
from  sec.concordance_historic
where link_set_key = 41; 
quit;

proc sql; 
create table spine_id as 
select snz_uid, snz_spine_uid
from  sec.concordance; 
quit;


proc sort data=births; by snz_uid; run;
proc sort data=spine_id; by snz_uid; run;

data births_2;
merge births spine_id; 
by snz_uid; if dia_bir_birth_year_nbr~=.;
run;

proc means data=births_2; run;

data births_3 (drop=snz_uid); set births_2; run;

proc sort data=births_3; by snz_spine_uid; run;
proc sort data=ref20211020; by snz_spine_uid; run;

data births_4;
merge births_3 ref20211020;
by snz_spine_uid; if dia_bir_birth_year_nbr~=.; if snz_spine_uid ~=.;
run; 


proc means data=births_4; run;

proc freq data=births_4 (where=(snz_uid~=.));
table dia_bir_birth_year_nbr;
run;



proc freq data=births (where=(snz_uid~=.));
table dia_bir_birth_year_nbr;
run;

**using born 1840 to 2020 from 202410 refresh;


*get deaths;
proc sql;
connect to odbc(dsn=idi_clean_202410_srvprd);
	create table deaths as 
	select * from connection to odbc
		(select distinct snz_uid, dia_dth_death_month_nbr, dia_dth_death_year_nbr 
			from dia_clean.deaths)
 ;
disconnect from odbc;
quit;

*checking death year;
proc freq data=deaths;
table dia_dth_death_year_nbr;
run;



%macro sample(
  cohort,
  start_yr /* first year of birth cohort */, 
  end_yr /* final year of birth cohort */);

data &cohort.;
set births;
if &start_yr. <= dia_bir_birth_year_nbr <= &end_yr.;
run;

* remove duplicates;
proc sort data=&cohort. nodupkey;
by snz_uid dia_bir_birth_month_nbr dia_bir_birth_year_nbr;
run;

* CHECK AND MAKE NOTE OF INITIAL COUNTS;
proc means data=&cohort.; var snz_uid; run;

* exclude those not in spine (data.personal_detail is spine table);
proc sql;
	create table &cohort._1 as
	select a.*, b.snz_spine_ind from &cohort. a
	left join data.personal_detail b 
		on a.snz_uid = b.snz_uid
		where b.snz_spine_ind = 1;
quit;

* CHECK AND MAKE NOTE OF COUNT OF THOSE ONLY IN SPINE;
proc means data= &cohort._1; var snz_uid; run;

* merge cohorts with deaths;
proc sql; 
	create table &cohort._2 as
		select * from &cohort._1 a
		left join deaths b
			on a.snz_uid = b.snz_uid;
quit;

*remove duplicates;
proc sort data=&cohort._2 nodupkey;
by snz_uid;
run;

* creat dod; 
data &cohort._alive; set &cohort._2;
format death_date date10.;
death_date = mdy(dia_dth_death_month_nbr, 1, dia_dth_death_year_nbr);
label death_date = 'date of death';
run;

** Create indicator for dead vs. alive during exposure period;
** BM: Creating two death flags: <jul 1989 for hospitalizations and < jul 2000 for acc ;
data &cohort._death; set &cohort._alive;
if (death_date ne .) and (death_date < '01JUL1989'd) then died89 = 1;
else died89 = 0;
if (death_date ne .) and (death_date < '01JUL2000'd) then died00 = 1;
else died00 = 0;

*MAKE NOTE OF THOSE WHERE DIED = 0, AS THIS WILL BE COHORT NUMBER EXCLUDING ALL THOSE WHO DIED PRIOR TO EXPOSURE PERIOD;
proc freq data=&cohort._death;
table died89 died00;
run;

** DROP individuals who died prior to observation periods;
data &cohort._3; set &cohort._death;
if (death_date ne .) and (death_date < '01JUL1989'd) then delete;
run;

data &cohort._4; set &cohort._death;
if (death_date ne .) and (death_date < '01JUL2000'd) then delete;
run;

*** Bring in sex from personal details table;
*  1 = male, 2 = female;
proc sql;
	create table &cohort.h_sex as 
	select a.*, b.snz_sex_gender_code from  &cohort._3 a
	left join data.personal_detail b
		on a.snz_uid = b.snz_uid;
quit;

proc sql;
	create table &cohort.a_sex as 
	select a.*, b.snz_sex_gender_code from  &cohort._4 a
	left join data.personal_detail b
		on a.snz_uid = b.snz_uid;
quit;

* Note: check if sex is missing for some individuals;
proc freq data=&cohort.h_sex;
table snz_sex_gender_code;
run;

proc freq data=&cohort.a_sex;
table snz_sex_gender_code;
run;
%mend sample;

%sample(coh8089, 1980, 1989);
%sample(coh7079, 1970, 1979);
%sample(coh6069, 1960, 1969);
%sample(coh5059, 1950, 1959);
%sample(coh4049, 1940, 1949);
%sample(coh3039, 1930, 1939);
%sample(coh2939, 1929, 1939);

proc means data=coh8089h_sex; var snz_uid; run;
proc means data=coh7079h_sex; var snz_uid; run;
proc means data=coh6069h_sex; var snz_uid; run;
proc means data=coh5059h_sex; var snz_uid; run;
proc means data=coh4049h_sex; var snz_uid; run;
proc means data=coh2939h_sex; var snz_uid; run;



* create overseas flag and resident population flag;
* resident population - remove duplicate snz_uids;
proc freq data=data.snz_res_pop noprint;
table snz_uid /out=res_pop_ids;
run;

data res_pop_ids2; set res_pop_ids; 
res_pop_flag = 1; 
drop count percent; 
run;

%macro final(cohort);
* merge with res pop ids;
proc sql;
	create table &cohort.h_res as
	select distinct a.*, b.res_pop_flag from &cohort.h_sex a
	left join res_pop_ids2 b
		on a.snz_uid = b.snz_uid;
quit;

proc sql;
	create table &cohort.a_res as
	select distinct a.*, b.res_pop_flag from &cohort.a_sex a
	left join res_pop_ids2 b
		on a.snz_uid = b.snz_uid;
quit;

* res count without os restriction;
proc freq data=&cohort.h_res;
table res_pop_flag;
run; 

proc freq data=&cohort.a_res;
table res_pop_flag;
run;

proc sort data = &cohort.h_res; by dia_bir_birth_year_nbr; run;
proc sort data = &cohort.a_res; by dia_bir_birth_year_nbr; run;

*save;
data &cohort.h_2410refresh;
set &cohort.h_res;
keep snz_uid dia_bir_birth_month_nbr dia_bir_birth_year_nbr death_date snz_sex_gender_code res_pop_flag;  
run;

data &cohort.a_2410refresh;
set &cohort.a_res;
keep snz_uid dia_bir_birth_month_nbr dia_bir_birth_year_nbr death_date snz_sex_gender_code res_pop_flag;  
run;

%mend final;

%final(coh8089);
%final(coh7079);
%final(coh6069);
%final(coh5059);
%final(coh4049);
%final(coh3039);
%final(coh2939);


proc means data=coh7079h_2410refresh; var snz_uid; run;
proc means data=coh6069h_2410refresh; var snz_uid; run;
proc means data=coh5059h_2410refresh; var snz_uid; run;
proc means data=coh4049h_2410refresh; var snz_uid; run;
proc means data=coh2939h_2410refresh; var snz_uid; run;

proc means data=coh7079a_2410refresh; var snz_uid; run;
proc means data=coh6069a_2410refresh; var snz_uid; run;
proc means data=coh5059a_2410refresh; var snz_uid; run;
proc means data=coh4049a_2410refresh; var snz_uid; run;
proc means data=coh2939a_2410refresh; var snz_uid; run;



*born 1929-1979;
proc sql; 
create table born2979 as 
select snz_uid, snz_birth_year_nbr, snz_spine_ind
from  data.personal_detail
		where snz_spine_ind = 1 & 1979>=snz_birth_year_nbr>=1929; 
quit;

proc freq data=born2979;
table snz_birth_year_nbr;
run;

proc sql; 
create table spine_id as 
select snz_uid, snz_spine_uid
from  sec.concordance; 
quit;

proc sort data=born2979; by snz_uid; run;
proc sort data=spine_id; by snz_uid; run;

data born2979_2;
merge born2979 spine_id; 
by snz_uid; if snz_birth_year_nbr~=.;
run;

proc means data=born2979_2; run;

data born2979_3 (drop=snz_uid); set born2979_2; run;

*original refresh (link_set_key=41);
proc sql; 
create table ref20211020 as 
select link_set_key, snz_uid, snz_spine_uid
from  sec.concordance_historic
where link_set_key = 41; 
quit;



**BIRTHS;
proc sql;
connect to odbc(dsn=idi_clean_202410_srvprd);
	create table births2979 as 
	select * from connection to odbc
		(select distinct snz_uid, dia_bir_birth_year_nbr, dia_bir_birth_month_nbr 
			from dia_clean.births) where 1929<=dia_bir_birth_year_nbr<=1979
 ;
disconnect from odbc;
quit;


proc sort data=births2979; by snz_uid; run;
proc sort data=spine_id; by snz_uid; run;

data births2979_2;
merge births2979 spine_id; 
by snz_uid; if dia_bir_birth_year_nbr~=.;
run;

data births2979_3 (drop=snz_uid); set births2979_2; run;

proc sort data=births2979_3; by snz_spine_uid; run;
proc sort data=ref20211020; by snz_spine_uid; run;

data births2979_4;
merge births2979_3 ref20211020;
by snz_spine_uid; if dia_bir_birth_year_nbr~=.; if snz_spine_uid ~=.;
run; 


proc means data=births2979_4; run;

proc freq data=births2979_4 (where=(snz_uid~=.));
table dia_bir_birth_year_nbr;
run;

proc means data=file.inj_analysis_17Feb2024 (where=(wgt>0));
var wgt; run;


proc means data=file.ACCMH_Analyses_19May2024 (where=(wgt>0));
var wgt; run;





**************************************************
*******3 ethnicity *******
**************************************************;

proc contents data=file.inj_analysis_17Feb2024; run;
*update to refresh - use IDI_Clean_202410;

*for IDI_Clean_20211020 (original refresh), link set key = 41;

*getting IDs;
data temp (keep=snz_uid xxx wgt); 
set file.totpop_dep; xxx=1; run;

proc sql; 
create table ref20211020 as 
select link_set_key, snz_uid, snz_spine_uid
from  sec.concordance_historic
where link_set_key = 41; 
quit;

proc sort data=ref20211020; by snz_uid; run;
proc sort data=temp; by snz_uid; run;

data check;
merge ref20211020 temp;
by snz_uid; run;

proc freq data=check; table xxx; run;
proc freq data=check (where=(snz_spine_uid~=.)); table xxx; run;
**All IDs appear to be in the spine;

data MHINJid (keep=snz_uid_old xxx snz_spine_uid wgt);
set check;
if xxx=1;
rename snz_uid=snz_uid_old;
run;


*************GETTING 202410 SNZ_UID***************;

proc sql; 
create table ref202410 as 
select snz_uid, snz_spine_uid
from  sec.concordance
where snz_spine_uid ~= .; 
quit;


**MERGING USING SNZ_SPINE_UID;
proc sort data=MHINJid; by snz_spine_uid; run;
proc sort data=ref202410; by snz_spine_uid; run;

data MHINJid_ref202410;
merge MHINJid ref202410;
by snz_spine_uid; if xxx=1; run;

proc means data=MHINJid_ref202410; run;

***Every case with an original snz_uid has a 202410 snz_uid ***

**********************SAVING**********************;
data file.MHINJid_ref202410;
set MHINJid_ref202410;
run;

data MHINJid_ref202410;
set file.MHINJid_ref202410;
run;


*************GETTING ETHNICITY DATA***************;
data ethdata;
set data.personal_detail (keep=snz_uid snz_ethnicity_grp1_nbr
snz_ethnicity_grp2_nbr snz_ethnicity_grp3_nbr snz_ethnicity_grp4_nbr
snz_ethnicity_grp5_nbr snz_ethnicity_grp6_nbr snz_spine_ind 
snz_ethnicity_source_code);
if snz_spine_ind=1;
run;

************MERGING WITH ID FILE*****************;
proc sort data=MHINJid_ref202410; by snz_uid; run;
proc sort data=ethdata; by snz_uid; run;

data MHINJ_eth;
merge MHINJid_ref202410 ethdata;
by snz_uid; if xxx=1;
neth = snz_ethnicity_grp1_nbr + snz_ethnicity_grp2_nbr + snz_ethnicity_grp3_nbr +
snz_ethnicity_grp4_nbr + snz_ethnicity_grp5_nbr + snz_ethnicity_grp6_nbr;
run;

proc freq data=MHINJ_eth;
table snz_ethnicity_grp1_nbr snz_ethnicity_grp2_nbr snz_ethnicity_grp3_nbr 
snz_ethnicity_grp4_nbr snz_ethnicity_grp5_nbr snz_ethnicity_grp6_nbr
neth snz_ethnicity_source_code;
run;

proc freq data=MHINJ_eth (where=(wgt>0));
table snz_ethnicity_grp1_nbr snz_ethnicity_grp2_nbr snz_ethnicity_grp3_nbr 
snz_ethnicity_grp4_nbr snz_ethnicity_grp5_nbr snz_ethnicity_grp6_nbr
neth snz_ethnicity_source_code;
run;




**************************************************
************Injury risk across time intervals*************
**************************************************;

**capturing non self harm injuries in different follow-up periods;
data nonsh_fo (keep=snz_uid hosp_start start_date time_to_inj 
inj1y inj1_5y inj5_10y inj10_15y inj15_20y inj20_25y inj25_30y);
set file.injuries;
if inj_order=3;
if (inj1~=2 & inj2~=2 & inj3~=2 & inj4~=2 & inj5~=2 & inj6~=2);
time_to_inj = hosp_start - start_date;
if time_to_inj<366 then inj1y=1;
if 366<=time_to_inj<1826 then inj1_5y=1;
if 1826<=time_to_inj<3652 then inj5_10y=1;
if 3652<=time_to_inj<5479 then inj10_15y=1;
if 5479<=time_to_inj<7305 then inj15_20y=1;
if 7305<=time_to_inj<9131 then inj20_25y=1;
if 9131<=time_to_inj then inj25_30y=1;
run;

proc means data=nonsh_fo; 
var time_to_inj;
run;

proc freq data=nonsh_fo;
table inj1y inj1_5y inj5_10y inj10_15y inj15_20y inj20_25y inj25_30y;
run;

proc freq data=nonsh_fo (where=(inj1y=1)) noprint; table snz_uid /out=inj1y; run;
proc freq data=nonsh_fo (where=(inj1_5y=1)) noprint; table snz_uid /out=inj1_5y; run;
proc freq data=nonsh_fo (where=(inj5_10y=1)) noprint; table snz_uid /out=inj5_10y; run;
proc freq data=nonsh_fo (where=(inj10_15y=1)) noprint; table snz_uid /out=inj10_15y; run;
proc freq data=nonsh_fo (where=(inj15_20y=1)) noprint; table snz_uid /out=inj15_20y; run;
proc freq data=nonsh_fo (where=(inj20_25y=1)) noprint; table snz_uid /out=inj20_25y; run;
proc freq data=nonsh_fo (where=(inj25_30y=1)) noprint; table snz_uid /out=inj25_30y; run;


proc freq data = file.inj_analysis_7Apr2024;
table nsh_post_inj;
run;


data nsh1y (keep=snz_uid nsh1y); set inj1y; nsh1y = 1; run;
data nsh1_5y (keep=snz_uid nsh1_5y); set inj1_5y; nsh1_5y = 1; run;
data nsh5_10y (keep=snz_uid nsh5_10y); set inj5_10y; nsh5_10y = 1; run;
data nsh10_15y (keep=snz_uid nsh10_15y); set inj10_15y; nsh10_15y = 1; run;
data nsh15_20y (keep=snz_uid nsh15_20y); set inj15_20y; nsh15_20y = 1; run;
data nsh20_25y (keep=snz_uid nsh20_25y); set inj20_25y; nsh20_25y = 1; run;
data nsh25_30y (keep=snz_uid nsh25_30y); set inj25_30y; nsh25_30y = 1; run;

proc sort data=nsh1y; by snz_uid; run;
proc sort data=nsh1_5y; by snz_uid; run;
proc sort data=nsh5_10y; by snz_uid; run;
proc sort data=nsh10_15y; by snz_uid; run;
proc sort data=nsh15_20y; by snz_uid; run;
proc sort data=nsh20_25y; by snz_uid; run;
proc sort data=nsh25_30y; by snz_uid; run;

data nsh_fo;
merge nsh1y nsh1_5y nsh5_10y nsh10_15y nsh15_20y nsh20_25y nsh25_30y;
by snz_uid;
run;

proc sort data=file.inj_analysis_7Apr2024; by snz_uid; run;

data varyingtime;
merge file.inj_analysis_7Apr2024 nsh_fo;
by snz_uid;
if nsh1y = . then nsh1y = 0;
if nsh1_5y = . then nsh1_5y = 0;
if nsh5_10y = . then nsh5_10y = 0;
if nsh10_15y = . then nsh10_15y = 0;
if nsh15_20y = . then nsh15_20y = 0;
if nsh20_25y = . then nsh20_25y = 0;
if nsh25_30y = . then nsh25_30y = 0;
run;

proc freq data = varyingtime;
table nsh_post_inj nsh1y nsh1_5y nsh5_10y nsh10_15y nsh15_20y nsh20_25y nsh25_30y;
run;

proc freq data = varyingtime (where=(wgt>0));
table nsh_post_inj nsh1y nsh1_5y nsh5_10y nsh10_15y nsh15_20y nsh20_25y nsh25_30y;
run;



**************************ANALYSIS 2***********************;

*total population;
%macro analysis5(inj);
proc genmod data=varyingtime;
model &inj.=MH prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'MH' MH 1 / exp;
run;
%mend analysis5;

%analysis5(inj = nsh1y);
%analysis5(inj = nsh1_5y);
%analysis5(inj = nsh5_10y);
%analysis5(inj = nsh10_15y);
%analysis5(inj = nsh15_20y);
%analysis5(inj = nsh20_25y);
%analysis5(inj = nsh25_30y);

