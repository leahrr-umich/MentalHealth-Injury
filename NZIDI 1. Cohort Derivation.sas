************************************************************
PROJECT: Mental Health and Injury
AUTHORS: S. D'Souza and B. Milne
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
keep their data safe.
Careful consideration has been given to the privacy, security, and 
confidentiality issues associated with using administrative and 
survey data in the IDI. Further detail can be found in the Privacy 
impact assessment for the Integrated Data Infrastructure available 
from www.stats.govt.nz.
*************************************************************;

libname data ODBC dsn=idi_clean_20211020_srvprd schema=data;
libname file "/nas/DataLab/MAA/MAA2019-35/Accidents/Data" ;

*********************************************************************;
***INPUT DATASETS**
dia_clean.births
dia_clean.deaths
data.personal_detail
data.snz_res_pop
;

***OUTPUT DATASETS***
file.coh7079h_22Aug22
file.coh6069h_22Aug22
file.coh5059h_22Aug22
file.coh4049h_22Aug22
file.coh2939h_22Aug22
file.coh7079a_22Aug22
file.coh6069a_22Aug22
file.coh5059a_22Aug22
file.coh4049a_22Aug22
file.coh2939a_22Aug22
;

*********************************************************************;

*get births;
proc sql;
connect to odbc(dsn=idi_clean_20211020_srvprd);
	create table births as 
	select * from connection to odbc
		(select distinct snz_uid, dia_bir_birth_year_nbr, dia_bir_birth_month_nbr 
			from dia_clean.births)
 ;
disconnect from odbc;
quit;

*get deaths;
proc sql;
connect to odbc(dsn=idi_clean_20211020_srvprd);
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

** Create indicator for dead vs. alive during exposure period  - CHECK WITH LEAH WHEN EXPOSURE PERIOD IS;
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


*checking death dates;
proc freq data=coh7079h_sex; table death_date died89; run;
proc freq data=coh6069h_sex; table death_date died89; run;
proc freq data=coh5059h_sex; table death_date died89; run;
proc freq data=coh4049h_sex; table death_date died89; run;
proc freq data=coh2939h_sex; table death_date died89; run;




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
data file.&cohort.h_22Aug22;
set &cohort.h_res;
keep snz_uid dia_bir_birth_month_nbr dia_bir_birth_year_nbr death_date snz_sex_gender_code res_pop_flag;  
run;

data file.&cohort.a_22Aug22;
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


*checking death dates;
proc freq data=file.coh7079h_22Aug22; table death_date; run;
proc freq data=file.coh6069h_22Aug22; table death_date; run;
proc freq data=file.coh5059h_22Aug22; table death_date; run;
proc freq data=file.coh4049h_22Aug22; table death_date; run;
proc freq data=file.coh2939h_22Aug22; table death_date; run;








