*********************************************************************
PROJECT: Mental Health and Injury
AUTHOR: S. D'Souza & B. Milne (transferred from InjuryDx_13Apr22)
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

*load relevant data;
data inj_analysis_17Feb2024;
set file.inj_analysis_17Feb2024;
run;
proc contents data = inj_analysis_17Feb2024; run;

*NOTE ON CODING:
For Sex: 1 = Male, 2 = Female

For Cohort:
1 = 1929-39
2 = 1940-49
3 = 1950-59
4 = 1960-69
5 = 1970-79;

***********************************************************;
********************ANALYSIS 1 DESCRIPTIVES****************;
***********************************************************;
proc freq data=inj_analysis_17Feb2024;

*table MH sex coh prev_inj post_inj dia_bir_birth_year_nbr;
*table MH*post_inj coh*post_inj;
*table Anxiety ChildOnset Developmental Mood Personality Psychosis SUD Unspecified;
*table sex*(MH prev_inj post_inj dia_bir_birth_year_nbr);
*table sex*MH*(post_inj  inj_unint inj_self inj_assault);
*table sex*(Anxiety ChildOnset Developmental Mood Personality Psychosis SUD Unspecified);
*table coh*(Anxiety ChildOnset Developmental Mood Personality Psychosis SUD Unspecified);

**OVERALL;
table nsh_post_inj inj_unint inj_self inj_assault inj_other inj_undet;
table nsh_tbi nsh_othheadfaceneck nsh_spineback nsh_torso nsh_extremities nsh_unclassified;
table MH*(nsh_post_inj inj_unint inj_self inj_assault);
**BY COHORT;
table coh*(nsh_post_inj inj_unint inj_self inj_assault);
table coh*(nsh_tbi nsh_othheadfaceneck nsh_spineback nsh_torso nsh_extremities nsh_unclassified);
table coh*MH*(nsh_post_inj inj_unint inj_self inj_assault);
**BY SEX;
table sex*(nsh_post_inj inj_unint inj_self inj_assault);
table sex*(nsh_tbi nsh_othheadfaceneck nsh_spineback nsh_torso nsh_extremities nsh_unclassified);
table sex*MH*(nsh_post_inj inj_unint inj_self inj_assault);
**BY COHORT & SEX;
table coh*sex*(nsh_post_inj inj_unint inj_self inj_assault);
table coh*sex*MH*(nsh_post_inj inj_unint inj_self inj_assault);
run;


*****injuries across the full 30-year period;
proc freq data=inj_analysis_17Feb2024;
**OVERALL;
table inj_at nsh_inj_at unint_at self_at assault_at other_at undet_at;
table tbi_at othheadfaceneck_at spineback_at torso_at extremities_at unclassified_at;
table nsh_tbi_at nsh_othheadfaceneck_at nsh_spineback_at nsh_torso_at nsh_extremities_at nsh_unclassified_at;
table MH*(inj_at nsh_inj_at unint_at self_at assault_at);
**BY COHORT;
table coh*(inj_at nsh_inj_at unint_at self_at assault_at);
table coh*(tbi_at othheadfaceneck_at spineback_at torso_at extremities_at unclassified_at);
table coh*(nsh_tbi_at nsh_othheadfaceneck_at nsh_spineback_at nsh_torso_at nsh_extremities_at nsh_unclassified_at);
table coh*MH*(inj_at nsh_inj_at unint_at self_at assault_at);
**BY SEX;
table sex*(inj_at nsh_inj_at unint_at self_at assault_at);
table sex*(tbi_at othheadfaceneck_at spineback_at torso_at extremities_at unclassified_at);
table sex*(nsh_tbi_at nsh_othheadfaceneck_at nsh_spineback_at nsh_torso_at nsh_extremities_at nsh_unclassified_at);
table sex*MH*(inj_at nsh_inj_at unint_at self_at assault_at);
**BY COHORT & SEX;
table coh*sex*(inj_at nsh_inj_at unint_at self_at assault_at);
table coh*sex*MH*(inj_at nsh_inj_at unint_at self_at assault_at);
run;




***********************************************************;
**************************ANALYSIS 2***********************;
***********************************************************;
**SAME MONTH INJURIES EXCLUDED;
**WEIGHTED;
*RRs: MH and 4 diff types;

**TOTAL POPULATION;
proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;


*by sex;
proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
where sex = 1;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
where sex = 2;
run;



*by cohort and sex; 
%macro analysis2(sex,cohort);
proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
where sex = &sex. and coh = &cohort.;
run;
%mend analysis2;

*males;
%analysis2(sex=1,cohort=1);
%analysis2(sex=1,cohort=2);
%analysis2(sex=1,cohort=3);
%analysis2(sex=1,cohort=4);
%analysis2(sex=1,cohort=5);

*females;
%analysis2(sex=2,cohort=1);
%analysis2(sex=2,cohort=2);
%analysis2(sex=2,cohort=3);
%analysis2(sex=2,cohort=4);
%analysis2(sex=2,cohort=5);


***********************************************************;
**************************ANALYSIS 3***********************;
***********************************************************;

******BY MENTAL DISORDER TYPE********;
******BY MENTAL DISORDER TYPE********;
******BY MENTAL DISORDER TYPE********;
******BY MENTAL DISORDER TYPE********;

*total population;
proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=Anxiety prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Anxiety beta' Anxiety 1 / exp;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=Mood prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mood' Mood 1 / exp;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=Psychosis prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
estimate 'Psychosis beta' Psychosis 1 / exp;
weight wgt;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=SUD prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
estimate 'SUD beta' SUD 1 / exp;
weight wgt;
run;


*By sex; 
%macro analysis3a(mhtype,sex);
proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=&mhtype. prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' &mhtype. 1 / exp;
where sex = &sex.;
run;
%mend analysis3a;

*males;
%analysis3a(mhtype = Anxiety, sex = 1);
%analysis3a(mhtype = Mood, sex = 1);
%analysis3a(mhtype = Psychosis, sex = 1);
%analysis3a(mhtype = SUD, sex = 1);

*females;
%analysis3a(mhtype = Anxiety, sex = 2);
%analysis3a(mhtype = Mood, sex = 2);
%analysis3a(mhtype = Psychosis, sex = 2);
%analysis3a(mhtype = SUD, sex = 2);


*By sex and cohort; 
%macro analysis3b(mhtype,sex,cohort);
proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=&mhtype. prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' &mhtype. 1 / exp;
where sex = &sex. and coh = &cohort.;
run;
%mend analysis3b;

*Anxiety 
*males;
%analysis3b(mhtype = Anxiety, sex=1,cohort=1);
%analysis3b(mhtype = Anxiety, sex=1,cohort=2);
%analysis3b(mhtype = Anxiety, sex=1,cohort=3);
%analysis3b(mhtype = Anxiety, sex=1,cohort=4);
%analysis3b(mhtype = Anxiety, sex=1,cohort=5);
*females;
%analysis3b(mhtype = Anxiety, sex=2,cohort=1);
%analysis3b(mhtype = Anxiety, sex=2,cohort=2);
%analysis3b(mhtype = Anxiety, sex=2,cohort=3);
%analysis3b(mhtype = Anxiety, sex=2,cohort=4);
%analysis3b(mhtype = Anxiety, sex=2,cohort=5);


*Mood 
*males;
%analysis3b(mhtype = Mood, sex=1,cohort=1);
%analysis3b(mhtype = Mood, sex=1,cohort=2);
%analysis3b(mhtype = Mood, sex=1,cohort=3);
%analysis3b(mhtype = Mood, sex=1,cohort=4);
%analysis3b(mhtype = Mood, sex=1,cohort=5);
*females;
%analysis3b(mhtype = Mood, sex=2,cohort=1);
%analysis3b(mhtype = Mood, sex=2,cohort=2);
%analysis3b(mhtype = Mood, sex=2,cohort=3);
%analysis3b(mhtype = Mood, sex=2,cohort=4);
%analysis3b(mhtype = Mood, sex=2,cohort=5);


*Psychosis 
*males;
%analysis3b(mhtype = Psychosis, sex=1,cohort=1);
%analysis3b(mhtype = Psychosis, sex=1,cohort=2);
%analysis3b(mhtype = Psychosis, sex=1,cohort=3);
%analysis3b(mhtype = Psychosis, sex=1,cohort=4);
%analysis3b(mhtype = Psychosis, sex=1,cohort=5);
*females;
%analysis3b(mhtype = Psychosis, sex=2,cohort=1);
%analysis3b(mhtype = Psychosis, sex=2,cohort=2);
%analysis3b(mhtype = Psychosis, sex=2,cohort=3);
%analysis3b(mhtype = Psychosis, sex=2,cohort=4);
%analysis3b(mhtype = Psychosis, sex=2,cohort=5);


*SUD 
*males;
%analysis3b(mhtype = SUD, sex=1,cohort=1);
%analysis3b(mhtype = SUD, sex=1,cohort=2);
%analysis3b(mhtype = SUD, sex=1,cohort=3);
%analysis3b(mhtype = SUD, sex=1,cohort=4);
%analysis3b(mhtype = SUD, sex=1,cohort=5);
*females;
%analysis3b(mhtype = SUD, sex=2,cohort=1);
%analysis3b(mhtype = SUD, sex=2,cohort=2);
%analysis3b(mhtype = SUD, sex=2,cohort=3);
%analysis3b(mhtype = SUD, sex=2,cohort=4);
%analysis3b(mhtype = SUD, sex=2,cohort=5);



******BY INJURY TYPE********;
******BY INJURY TYPE********;
******BY INJURY TYPE********;
******BY INJURY TYPE********;


*total population;
proc genmod data=inj_analysis_17Feb2024;
model inj_unint=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Unintentional beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_17Feb2024;
model inj_self=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Self harm beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_17Feb2024;
model inj_assault=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Assault beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_tbi=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'TBI beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_othheadfaceneck=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'OTHER HEAD FACE & NECK beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_spineback =MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'SPINE & BACK beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_torso =MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'TORSO beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_extremities =MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'EXTREMITIES beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_unclassified=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'UNCLASSIFIED beta' MH 1 / exp;
run;



*By sex; 
%macro analysis3c(inj,sex);
proc genmod data=inj_analysis_17Feb2024;
model &inj.=MH prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'MH' MH 1 / exp;
where sex = &sex.;
run;
%mend analysis3c;

*males;
%analysis3c(inj = inj_unint, sex = 1);
%analysis3c(inj = inj_self, sex = 1);
%analysis3c(inj = inj_assault, sex = 1);
%analysis3c(inj = nsh_tbi, sex = 1);
%analysis3c(inj = nsh_othheadfaceneck, sex = 1);
%analysis3c(inj = nsh_spineback, sex = 1);
%analysis3c(inj = nsh_torso, sex = 1);
%analysis3c(inj = nsh_extremities, sex = 1);
%analysis3c(inj = nsh_unclassified, sex = 1);

*females;
%analysis3c(inj = inj_unint, sex = 2);
%analysis3c(inj = inj_self, sex = 2);
%analysis3c(inj = inj_assault, sex = 2);
%analysis3c(inj = nsh_tbi, sex = 2);
%analysis3c(inj = nsh_othheadfaceneck, sex = 2);
%analysis3c(inj = nsh_spineback, sex = 2);
%analysis3c(inj = nsh_torso, sex = 2);
%analysis3c(inj = nsh_extremities, sex = 2);
%analysis3c(inj = nsh_unclassified, sex = 2);




*By sex and cohort; 
%macro analysis3d(inj,cohort,sex);
proc genmod data=inj_analysis_17Feb2024;
model &inj.=MH prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'MH' MH 1 / exp;
where sex = &sex. and coh = &cohort.;
run;
%mend analysis3d;


*Unintentional 
*males;
%analysis3d(inj = inj_unint, sex=1,cohort=1);
%analysis3d(inj = inj_unint, sex=1,cohort=2);
%analysis3d(inj = inj_unint, sex=1,cohort=3);
%analysis3d(inj = inj_unint, sex=1,cohort=4);
%analysis3d(inj = inj_unint, sex=1,cohort=5);
*females;
%analysis3d(inj = inj_unint, sex=2,cohort=1);
%analysis3d(inj = inj_unint, sex=2,cohort=2);
%analysis3d(inj = inj_unint, sex=2,cohort=3);
%analysis3d(inj = inj_unint, sex=2,cohort=4);
%analysis3d(inj = inj_unint, sex=2,cohort=5);

*Self harm 
*males;
%analysis3d(inj = inj_self, sex=1,cohort=1);
%analysis3d(inj = inj_self, sex=1,cohort=2);
%analysis3d(inj = inj_self, sex=1,cohort=3);
%analysis3d(inj = inj_self, sex=1,cohort=4);
%analysis3d(inj = inj_self, sex=1,cohort=5);
*females;
%analysis3d(inj = inj_self, sex=2,cohort=1);
%analysis3d(inj = inj_self, sex=2,cohort=2);
%analysis3d(inj = inj_self, sex=2,cohort=3);
%analysis3d(inj = inj_self, sex=2,cohort=4);
%analysis3d(inj = inj_self, sex=2,cohort=5);

*Assault 
*males;
%analysis3d(inj = inj_assault, sex=1,cohort=1);
%analysis3d(inj = inj_assault, sex=1,cohort=2);
%analysis3d(inj = inj_assault, sex=1,cohort=3);
%analysis3d(inj = inj_assault, sex=1,cohort=4);
%analysis3d(inj = inj_assault, sex=1,cohort=5);
*females;
%analysis3d(inj = inj_assault, sex=2,cohort=1);
%analysis3d(inj = inj_assault, sex=2,cohort=2);
%analysis3d(inj = inj_assault, sex=2,cohort=3);
%analysis3d(inj = inj_assault, sex=2,cohort=4);
%analysis3d(inj = inj_assault, sex=2,cohort=5);

*TBI 
*males;
%analysis3d(inj = nsh_tbi, sex=1,cohort=1);
%analysis3d(inj = nsh_tbi, sex=1,cohort=2);
%analysis3d(inj = nsh_tbi, sex=1,cohort=3);
%analysis3d(inj = nsh_tbi, sex=1,cohort=4);
%analysis3d(inj = nsh_tbi, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_tbi, sex=2,cohort=1);
%analysis3d(inj = nsh_tbi, sex=2,cohort=2);
%analysis3d(inj = nsh_tbi, sex=2,cohort=3);
%analysis3d(inj = nsh_tbi, sex=2,cohort=4);
%analysis3d(inj = nsh_tbi, sex=2,cohort=5);

*Other head, neck and face 
*males;
%analysis3d(inj = nsh_othheadfaceneck, sex=1,cohort=1);
%analysis3d(inj = nsh_othheadfaceneck, sex=1,cohort=2);
%analysis3d(inj = nsh_othheadfaceneck, sex=1,cohort=3);
%analysis3d(inj = nsh_othheadfaceneck, sex=1,cohort=4);
%analysis3d(inj = nsh_othheadfaceneck, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_othheadfaceneck, sex=2,cohort=1);
%analysis3d(inj = nsh_othheadfaceneck, sex=2,cohort=2);
%analysis3d(inj = nsh_othheadfaceneck, sex=2,cohort=3);
%analysis3d(inj = nsh_othheadfaceneck, sex=2,cohort=4);
%analysis3d(inj = nsh_othheadfaceneck, sex=2,cohort=5);

*Spine and back 
*males;
%analysis3d(inj = nsh_spineback, sex=1,cohort=1);
%analysis3d(inj = nsh_spineback, sex=1,cohort=2);
%analysis3d(inj = nsh_spineback, sex=1,cohort=3);
%analysis3d(inj = nsh_spineback, sex=1,cohort=4);
%analysis3d(inj = nsh_spineback, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_spineback, sex=2,cohort=1);
%analysis3d(inj = nsh_spineback, sex=2,cohort=2);
%analysis3d(inj = nsh_spineback, sex=2,cohort=3);
%analysis3d(inj = nsh_spineback, sex=2,cohort=4);
%analysis3d(inj = nsh_spineback, sex=2,cohort=5);

*Torso 
*males;
%analysis3d(inj = nsh_torso, sex=1,cohort=1);
%analysis3d(inj = nsh_torso, sex=1,cohort=2);
%analysis3d(inj = nsh_torso, sex=1,cohort=3);
%analysis3d(inj = nsh_torso, sex=1,cohort=4);
%analysis3d(inj = nsh_torso, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_torso, sex=2,cohort=1);
%analysis3d(inj = nsh_torso, sex=2,cohort=2);
%analysis3d(inj = nsh_torso, sex=2,cohort=3);
%analysis3d(inj = nsh_torso, sex=2,cohort=4);
%analysis3d(inj = nsh_torso, sex=2,cohort=5);

*Extremities 
*males;
%analysis3d(inj = nsh_extremities, sex=1,cohort=1);
%analysis3d(inj = nsh_extremities, sex=1,cohort=2);
%analysis3d(inj = nsh_extremities, sex=1,cohort=3);
%analysis3d(inj = nsh_extremities, sex=1,cohort=4);
%analysis3d(inj = nsh_extremities, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_extremities, sex=2,cohort=1);
%analysis3d(inj = nsh_extremities, sex=2,cohort=2);
%analysis3d(inj = nsh_extremities, sex=2,cohort=3);
%analysis3d(inj = nsh_extremities, sex=2,cohort=4);
%analysis3d(inj = nsh_extremities, sex=2,cohort=5);

*Unclassified 
*males;
%analysis3d(inj = nsh_unclassified, sex=1,cohort=1);
%analysis3d(inj = nsh_unclassified, sex=1,cohort=2);
%analysis3d(inj = nsh_unclassified, sex=1,cohort=3);
%analysis3d(inj = nsh_unclassified, sex=1,cohort=4);
%analysis3d(inj = nsh_unclassified, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_unclassified, sex=2,cohort=1);
%analysis3d(inj = nsh_unclassified, sex=2,cohort=2);
%analysis3d(inj = nsh_unclassified, sex=2,cohort=3);
%analysis3d(inj = nsh_unclassified, sex=2,cohort=4);
%analysis3d(inj = nsh_unclassified, sex=2,cohort=5);


********************10 MAR 2024********************;
*****CHECKING UNINTENTIONAL & ASSAULT COMBINED*****;
proc freq data=inj_analysis_17Feb2024;
table inj_unint inj_assault;
run;

data temp;
set inj_analysis_17Feb2024;
inj_unint_assault = inj_unint;
if inj_assault = 1 then inj_unint_assault = 1;
run;

proc freq data=temp;
table inj_unint inj_assault inj_unint*inj_assault inj_unint_assault;
run;

proc genmod data=temp;
model inj_unint_assault=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Assault beta' MH 1 / exp;
run;





****************************************************************;
**************************ANALYSIS 4****************************;
****************************************************************;

***Number of Injuries;
proc freq data=inj_analysis_17Feb2024;
table n_post_inj nsh_n_post_inj; 
run;

data burden;
set inj_analysis_17Feb2024;
n_post_inj_trunc = n_post_inj;
if n_post_inj>3 then n_post_inj_trunc = 3;
nsh_n_post_inj_trunc = nsh_n_post_inj;
if nsh_n_post_inj>3 then nsh_n_post_inj_trunc = 3;
run;

proc freq data=burden;
table n_post_inj_trunc nsh_n_post_inj_trunc;
run;

**NBREG analyses;
proc genmod data=burden; 
model nsh_n_post_inj_trunc = MH prev_inj dia_bir_birth_year_nbr sex/ 
dist=negbin; weight wgt; run; 

proc genmod data=burden; 
model nsh_n_post_inj = MH prev_inj dia_bir_birth_year_nbr sex/ 
dist=negbin; weight wgt; run; 

**by sex;
proc genmod data=burden; 
model nsh_n_post_inj_trunc = MH prev_inj dia_bir_birth_year_nbr/ 
dist=negbin; weight wgt; where sex = 1; run; 

proc genmod data=burden; 
model nsh_n_post_inj = MH prev_inj dia_bir_birth_year_nbr/ 
dist=negbin; weight wgt; where sex = 1; run; 

proc genmod data=burden; 
model nsh_n_post_inj_trunc = MH prev_inj dia_bir_birth_year_nbr/ 
dist=negbin; weight wgt; where sex = 2; run; 

proc genmod data=burden; 
model nsh_n_post_inj = MH prev_inj dia_bir_birth_year_nbr/ 
dist=negbin; weight wgt; where sex = 2; run; 


*by cohort and sex; 
%macro analysis4(sex,cohort);
proc genmod data=burden; 
model nsh_n_post_inj_trunc = MH prev_inj dia_bir_birth_year_nbr/ 
dist=negbin; weight wgt; 
where sex = &sex. and coh = &cohort.; run; 

proc genmod data=burden; 
model nsh_n_post_inj = MH prev_inj dia_bir_birth_year_nbr/ 
dist=negbin; weight wgt; 
where sex = &sex. and coh = &cohort.; run;
%mend analysis4;

*males;
%analysis4(sex=1,cohort=1);
%analysis4(sex=1,cohort=2);
%analysis4(sex=1,cohort=3);
%analysis4(sex=1,cohort=4);
%analysis4(sex=1,cohort=5);

*females;
%analysis4(sex=2,cohort=1);
%analysis4(sex=2,cohort=2);
%analysis4(sex=2,cohort=3);
%analysis4(sex=2,cohort=4);
%analysis4(sex=2,cohort=5);




****************************************************************;
*************************SENSITIVITY****************************;
****************************************************************;

***********************************************;
*undetermined and 'site unclassified' injuries*;
***********************************************;

*undetermined;
proc freq data=file.injuries (where=(inj1=5 | inj2=5 | inj3=5 | inj4=5 | inj5=5 | inj6=5));
table icd9code icd10code ecode9; run;
*'Injury undetermined whether accidentally or purposefully inflicted';

*unclassified site;
proc freq data=file.injuries (where=(isrsite2=8 or isrsite2=9 or isrsite2=.));
table icd9code icd10code ecode9; run;


****************************************************************;
*other, undetermined, and unintentional/assualt combined models*;
****************************************************************;
proc freq data=file.inj_analysis_17Feb2024;
table inj_unint inj_self inj_assault inj_other inj_undet;
run;


data temp;
set file.inj_analysis_17Feb2024;

if inj_unint=0 then inj_other=0;
if inj_unint=0 then inj_undet=0;

inj_unint_or_assault = inj_unint;
if inj_assault = 1 then inj_unint_or_assault = 1;
run;

proc freq data= temp;
table inj_unint inj_self inj_assault inj_other inj_undet inj_unint_or_assault;
run;

**models;
proc genmod data=temp;
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;


proc genmod data=temp;
model inj_unint=MH prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;


proc genmod data=temp;
model inj_assault=MH prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;


proc genmod data=temp;
model inj_unint_or_assault=MH prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;


proc genmod data=temp;
model inj_other=MH prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;


proc genmod data=temp;
model inj_undet=MH prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;



*******************;
*UNWEIGHTED MODELS*;
*******************;

**TOTAL POPULATION;
proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
estimate 'Mental health beta' MH 1 / exp;
run;


*by sex;
proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
estimate 'Mental health beta' MH 1 / exp;
where sex = 1;
run;


proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
estimate 'Mental health beta' MH 1 / exp;
where sex = 2;
run;



*by cohort and sex; 
%macro analysis2(sex,cohort);
proc genmod data=inj_analysis_17Feb2024;
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
estimate 'Mental health beta' MH 1 / exp;
where sex = &sex. and coh = &cohort.;
run;
%mend analysis2;

*males;
%analysis2(sex=1,cohort=1);
%analysis2(sex=1,cohort=2);
%analysis2(sex=1,cohort=3);
%analysis2(sex=1,cohort=4);
%analysis2(sex=1,cohort=5);

*females;
%analysis2(sex=2,cohort=1);
%analysis2(sex=2,cohort=2);
%analysis2(sex=2,cohort=3);
%analysis2(sex=2,cohort=4);
%analysis2(sex=2,cohort=5);





*************;
*DEPRIVATION*;
*************;


*****getting IDs*****;
data cohort; set file.inj_analysis_17Feb2024; 
keep snz_uid coh; run;
proc sort data=cohort; by snz_uid; run;


***getting addresses;
proc sql;
connect to odbc(dsn=IDI_Clean_20211020_srvprd);
create table address as
select * from connection to odbc
(select snz_uid,ant_notification_date,ant_replacement_date,ant_meshblock_code 
FROM IDI_Clean_20211020.data.address_notification);
disconnect from odbc;
quit;

data address2; set address; if ant_meshblock_code ~=""; run;

proc sort data=COHORT; by snz_uid; run;
proc sort data=address2; by snz_uid; run;

data cohort_address; merge cohort address2; by snz_uid; if coh ~=""; run;

data temp; set cohort_address; if ant_meshblock_code =""; run;
proc sort data=temp nodup; by snz_uid; run;


proc freq data=COHORT; table coh; run;
proc freq data=temp; table coh; run;



***getting nzdep;
proc sql;
connect to odbc(dsn=IDI_Metadata_srvprd);
create table nzdep as
select * from connection to odbc
(select MB_2013,NZDep2013 FROM IDI_Metadata_202303.data.Dep_Index13);
disconnect from odbc;
quit;
proc freq data=nzdep; table NZDep2013; run;



***getting Meshblock2013;
proc sql;
connect to odbc(dsn=IDI_Metadata_srvprd);
create table concordance as
select * from connection to odbc
(select meshblock_code,MB2020_code,MB2019_code,MB2018_code,MB2017_code,MB2016_code,MB2015_code,
MB2014_code,MB2013_code,census_meshblock_code 
FROM IDI_Metadata_202303.data.meshblock_concordance);
disconnect from odbc;
quit;

data cohort_address2; set cohort_address; meshblock_code=ant_meshblock_code; run;



***adding Meshblock2013 to cohort file;
proc sort data=concordance; by meshblock_code; run;
proc sort data=cohort_address2; by meshblock_code; run;
data cohort_address3; merge cohort_address2 concordance; by meshblock_code; if coh ~=""; run;

proc means data=cohort_address3 (where=(meshblock_code ~="")); var snz_uid; run;
proc means data=cohort_address3 (where=(MB2013_code ~="")); var snz_uid; run;
proc means data=cohort_address3 (where=(meshblock_code ~="" & MB2013_code="")); 
var snz_uid; run;

proc freq data=cohort_address3 (where=(meshblock_code ~="" & MB2013_code="")); 
table meshblock_code;
run;


data cohort_address4 
(drop= ant_meshblock_code MB2020_code MB2019_code MB2018_code MB2017_code MB2016_code 
MB2015_code MB2014_code MB2013_code census_meshblock_code); 
set cohort_address3; MB_2013 = MB2013_code;
run;
proc means data=cohort_address4 (where=(meshblock_code ~="")); var snz_uid; run;
proc means data=cohort_address4 (where=(MB_2013 ~="")); var snz_uid; run;


***adding in NZDep;
proc sort data=cohort_address4; by MB_2013; run;
proc sort data=nzdep; by MB_2013; run;
data cohort_address5; merge cohort_address4 nzdep; by MB_2013; if coh ~=""; run;

proc freq data=cohort_address5; table NZDep2013; run;


data temp; set cohort_address5; if NZDep2013 ~= .; run;
proc sort data=temp nodupkey; by snz_uid; run;
proc freq data=temp; table coh; run;
proc freq data=inj_analysis_17Feb2024; table coh; run;



***checking number of address changes, and keeping first address with NZDep;
data cohort_address6; set cohort_address5; if NZDep2013 ~= .; run;
proc freq data=cohort_address6 noprint; table snz_uid /out=temp2; run;
proc freq data=temp2; table count; run;

proc freq data=cohort_address6; table ant_notification_date; run;

proc sort data=cohort_address6; by snz_uid ant_notification_date; run;


data cohort_address7; set cohort_address6;
count + 1;
by snz_uid;
if first.snz_uid then count = 1;
run;

proc freq data=cohort_address7; table count; run;


data dep1 (keep=snz_uid dep1 ); set cohort_address7; if count=1 ; dep1  = NZDep2013*1; run;
data dep2 (keep=snz_uid dep2 ); set cohort_address7; if count=2 ; dep2  = NZDep2013*1; run;
data dep3 (keep=snz_uid dep3 ); set cohort_address7; if count=3 ; dep3  = NZDep2013*1; run;
data dep4 (keep=snz_uid dep4 ); set cohort_address7; if count=4 ; dep4  = NZDep2013*1; run;
data dep5 (keep=snz_uid dep5 ); set cohort_address7; if count=5 ; dep5  = NZDep2013*1; run;
data dep6 (keep=snz_uid dep6 ); set cohort_address7; if count=6 ; dep6  = NZDep2013*1; run;
data dep7 (keep=snz_uid dep7 ); set cohort_address7; if count=7 ; dep7  = NZDep2013*1; run;
data dep8 (keep=snz_uid dep8 ); set cohort_address7; if count=8 ; dep8  = NZDep2013*1; run;
data dep9 (keep=snz_uid dep9 ); set cohort_address7; if count=9 ; dep9  = NZDep2013*1; run;
data dep10 (keep=snz_uid dep10 ); set cohort_address7; if count=10 ; dep10  = NZDep2013*1; run;
data dep11 (keep=snz_uid dep11 ); set cohort_address7; if count=11 ; dep11  = NZDep2013*1; run;
data dep12 (keep=snz_uid dep12 ); set cohort_address7; if count=12 ; dep12  = NZDep2013*1; run;
data dep13 (keep=snz_uid dep13 ); set cohort_address7; if count=13 ; dep13  = NZDep2013*1; run;
data dep14 (keep=snz_uid dep14 ); set cohort_address7; if count=14 ; dep14  = NZDep2013*1; run;
data dep15 (keep=snz_uid dep15 ); set cohort_address7; if count=15 ; dep15  = NZDep2013*1; run;
data dep16 (keep=snz_uid dep16 ); set cohort_address7; if count=16 ; dep16  = NZDep2013*1; run;
data dep17 (keep=snz_uid dep17 ); set cohort_address7; if count=17 ; dep17  = NZDep2013*1; run;
data dep18 (keep=snz_uid dep18 ); set cohort_address7; if count=18 ; dep18  = NZDep2013*1; run;
data dep19 (keep=snz_uid dep19 ); set cohort_address7; if count=19 ; dep19  = NZDep2013*1; run;
data dep20 (keep=snz_uid dep20 ); set cohort_address7; if count=20 ; dep20  = NZDep2013*1; run;

data dep; merge dep1 dep2 dep3 dep4 dep5 dep6 dep7 dep8 dep9 dep10 dep11 dep12 dep13 dep14 dep15 dep16 dep17 dep18 dep19 dep20; by snz_uid; 
meandep = mean(dep1,dep2,dep3,dep4,dep5,dep6,dep7,dep8,dep9,dep10,dep11,dep12,dep13,dep14,dep15,dep16,dep17,dep18,dep19,dep20);
run;

proc means data=dep; var dep1 meandep; run;


*****adding dep1 and meandep into analysis file;
proc sort data=file.inj_analysis_17Feb2024; by snz_uid; run;
proc sort data=dep; by snz_uid; run;
data totpop_dep (drop=dep2 dep3 dep4 dep5 dep6 dep7 dep8 dep9 dep10 dep11 dep12 dep13 dep14 dep15 dep16 dep17 dep18 dep19 dep20); 
merge file.inj_analysis_17Feb2024 dep; by snz_uid; 
	if dep1=. then dep1cat='missing';
	else if dep1 le 2 then dep1cat='Q1';
	else if dep1 le 4 then dep1cat='Q2';
	else if dep1 le 6 then dep1cat='Q3';
	else if dep1 le 8 then dep1cat='Q4';
	else if dep1 ge 9 then dep1cat='Q5';
run;
proc means data=totpop_dep; var dep1 meandep; run;
proc freq data=totpop_dep; table dep1cat; run;



******;
data file.totpop_dep; 
set totpop_dep;
run;

data temp (keep=snz_uid anxiety_clean mood_clean psychosis_clean SUD_clean
inj_unint_dirty inj_self_dirty inj_assault_dirty nsh_tbi_dirty nsh_othheadfaceneck_dirty 
nsh_spineback_dirty nsh_torso_dirty nsh_extremities_dirty nsh_unclassified_dirty);
set file.inj_analysis_7Apr2024;
run;

proc sort data=file.totpop_dep; by snz_uid; run;
proc sort data=temp; by snz_uid; run;

data totpop_dep_7Apr2024;
merge file.totpop_dep temp;
by snz_uid; run;

data file.totpop_dep_7Apr2024; 
set totpop_dep_7Apr2024;
run;

*****;


***models***;

**TOTAL POPULATION;
proc genmod data=totpop_dep;
class dep1cat (ref='Q1');
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr sex dep1cat/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
run;


*by sex;
proc genmod data=totpop_dep;
class dep1cat (ref='Q1');
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr dep1cat/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
where sex = 1;
run;


proc genmod data=totpop_dep;
class dep1cat (ref='Q1');
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr dep1cat/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
where sex = 2;
run;



*by cohort and sex; 
%macro analysis2(sex,cohort);
proc genmod data=totpop_dep;
class dep1cat (ref='Q1');
model nsh_post_inj=MH prev_inj dia_bir_birth_year_nbr dep1cat/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
where sex = &sex. and coh = &cohort.;
run;
%mend analysis2;

*males;
%analysis2(sex=1,cohort=1);
%analysis2(sex=1,cohort=2);
%analysis2(sex=1,cohort=3);
%analysis2(sex=1,cohort=4);
%analysis2(sex=1,cohort=5);

*females;
%analysis2(sex=2,cohort=1);
%analysis2(sex=2,cohort=2);
%analysis2(sex=2,cohort=3);
%analysis2(sex=2,cohort=4);
%analysis2(sex=2,cohort=5);



***************************;
*MENTAL HEALTH TYPE COUNTS*;
***************************;

proc freq data=file.inj_analysis_17Feb2024;
table MH Anxiety ChildOnset Developmental Mood Personality 
Physiol_Disturb Psychosis SUD Unspecified;
run;






***********************************************************;
**************************ANALYSIS 3***********************;
***********************************************************;
**************************REDONE*WITH**********************;
***********************************************************;
************CLEAN MENTAL HEALTH TYPE PREDICTORS************;
***************DIRTY INJURY TYPE PREDICTORS****************;
***********************************************************;


proc freq data=file.inj_analysis_17Feb2024;
table MH Anxiety ChildOnset Developmental Mood Personality 
Physiol_Disturb Psychosis SUD Unspecified;
run;

proc freq data=file.inj_analysis_17Feb2024;
table nsh_post_inj inj_unint inj_self inj_assault;
table nsh_tbi nsh_othheadfaceneck nsh_spineback nsh_torso nsh_extremities nsh_unclassified;
run;


PROC PRINT DATA=file.inj_analysis_17Feb2024 (where=(MH=1 & snz_uid<1000000));
VAR MH_start anx_start child_start dev_start mood_start 
Pers_start Phys_start Psychosis_start SUD_start uns_start;
run;

data temp;
set file.inj_analysis_17Feb2024;
min_start=min(anx_start,child_start,dev_start,mood_start,
Pers_start,Phys_start,Psychosis_start,SUD_start,uns_start);
max_start=max(anx_start,child_start,dev_start,mood_start,
Pers_start,Phys_start,Psychosis_start,SUD_start,uns_start);
run;

proc means data=temp;
var mh_start min_start max_start;
run;

****The current MH type vars (a) do not use a clean comparison group, and 
(b) capture events at any time in the follow-up 
(needed for descriptives, but exposure matching assume the MH event was the first MH event;
****The current injury type vars use a clean comparison group;
****Creating MH type vars (Anxiety Mood Psychosis SUD) with clean comparison group, 
and capturing first MH event only;
****Creating injury type vars with dirty comparison group;

data file.inj_analysis_7Apr2024;
set inj_analysis_17Feb2024;
*Clean MH type vars;
anxiety_clean = Anxiety; 
if anx_start>MH_start then anxiety_clean=.;
if MH=1 & Anxiety=0 then anxiety_clean=.;
mood_clean = Mood; 
if mood_start>MH_start then mood_clean=.;
if MH=1 & Mood=0 then mood_clean=.;
psychosis_clean = Psychosis; 
if Psychosis_start>MH_start then psychosis_clean=.;
if MH=1 & Psychosis=0 then psychosis_clean=.;
SUD_clean = SUD; 
if SUD_start>MH_start then SUD_clean=.;
if MH=1 & SUD=0 then SUD_clean=.;
*Dirty injury type vars;
inj_unint_dirty = inj_unint; 
if inj_unint_dirty = . then inj_unint_dirty = 0;
inj_self_dirty = inj_self; 
if inj_self_dirty = . then inj_self_dirty = 0;
inj_assault_dirty = inj_assault; 
if inj_assault_dirty = . then inj_assault_dirty = 0;
inj_other_dirty = inj_other; 
if inj_other_dirty = . then inj_other_dirty = 0;
inj_undet_dirty = inj_undet; 
if inj_undet_dirty = . then inj_undet_dirty = 0;

nsh_tbi_dirty = nsh_tbi;  
if nsh_tbi_dirty = . then nsh_tbi_dirty = 0;
nsh_othheadfaceneck_dirty = nsh_othheadfaceneck;  
if nsh_othheadfaceneck_dirty = . then nsh_othheadfaceneck_dirty = 0;
nsh_spineback_dirty = nsh_spineback;  
if nsh_spineback_dirty = . then nsh_spineback_dirty = 0;
nsh_torso_dirty = nsh_torso;  
if nsh_torso_dirty = . then nsh_torso_dirty = 0;
nsh_extremities_dirty = nsh_extremities;  
if nsh_extremities_dirty = . then nsh_extremities_dirty = 0;
nsh_unclassified_dirty = nsh_unclassified; 
if nsh_unclassified_dirty = . then nsh_unclassified_dirty = 0;
run;


proc freq data=file.inj_analysis_7Apr2024;
*table MH Anxiety anxiety_clean Mood mood_clean Psychosis psychosis_clean SUD SUD_clean;
*table nsh_post_inj inj_unint inj_unint_dirty inj_self inj_self_dirty inj_assault inj_assault_dirty;
table inj_other inj_other_dirty inj_undet inj_undet_dirty;
*table nsh_tbi nsh_tbi_dirty nsh_othheadfaceneck nsh_othheadfaceneck_dirty nsh_spineback nsh_spineback_dirty 
nsh_torso nsh_torso_dirty nsh_extremities nsh_extremities_dirty nsh_unclassified nsh_unclassified_dirty;
run;


***********************************************************;
**************************ANALYSIS 3***********************;
****************************REDONE*************************;

data inj_analysis_7Apr2024;
set file.inj_analysis_7Apr2024;
run;

******BY MENTAL DISORDER TYPE********;
******BY MENTAL DISORDER TYPE********;
******BY MENTAL DISORDER TYPE********;
******BY MENTAL DISORDER TYPE********;

*total population;
proc genmod data=inj_analysis_7Apr2024;
model nsh_post_inj=Anxiety_clean prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Anxiety beta' Anxiety_clean 1 / exp;
run;


proc genmod data=inj_analysis_7Apr2024;
model nsh_post_inj=Mood_clean prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mood' Mood_clean 1 / exp;
run;


proc genmod data=inj_analysis_7Apr2024;
model nsh_post_inj=Psychosis_clean prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
estimate 'Psychosis beta' Psychosis_clean 1 / exp;
weight wgt;
run;


proc genmod data=inj_analysis_7Apr2024;
model nsh_post_inj=SUD_clean prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
estimate 'SUD beta' SUD_clean 1 / exp;
weight wgt;
run;


*By sex; 
%macro analysis3a(mhtype,sex);
proc genmod data=inj_analysis_7Apr2024;
model nsh_post_inj=&mhtype. prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' &mhtype. 1 / exp;
where sex = &sex.;
run;
%mend analysis3a;

*males;
%analysis3a(mhtype = Anxiety_clean, sex = 1);
%analysis3a(mhtype = Mood_clean, sex = 1);
%analysis3a(mhtype = Psychosis_clean, sex = 1);
%analysis3a(mhtype = SUD_clean, sex = 1);

*females;
%analysis3a(mhtype = Anxiety_clean, sex = 2);
%analysis3a(mhtype = Mood_clean, sex = 2);
%analysis3a(mhtype = Psychosis_clean, sex = 2);
%analysis3a(mhtype = SUD_clean, sex = 2);


*By sex and cohort; 
%macro analysis3b(mhtype,sex,cohort);
proc genmod data=inj_analysis_7Apr2024;
model nsh_post_inj=&mhtype. prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' &mhtype. 1 / exp;
where sex = &sex. and coh = &cohort.;
run;
%mend analysis3b;

*Anxiety 
*males;
%analysis3b(mhtype = Anxiety_clean, sex=1,cohort=1);
%analysis3b(mhtype = Anxiety_clean, sex=1,cohort=2);
%analysis3b(mhtype = Anxiety_clean, sex=1,cohort=3);
%analysis3b(mhtype = Anxiety_clean, sex=1,cohort=4);
%analysis3b(mhtype = Anxiety_clean, sex=1,cohort=5);
*females;
%analysis3b(mhtype = Anxiety_clean, sex=2,cohort=1);
%analysis3b(mhtype = Anxiety_clean, sex=2,cohort=2);
%analysis3b(mhtype = Anxiety_clean, sex=2,cohort=3);
%analysis3b(mhtype = Anxiety_clean, sex=2,cohort=4);
%analysis3b(mhtype = Anxiety_clean, sex=2,cohort=5);


*Mood 
*males;
%analysis3b(mhtype = Mood_clean, sex=1,cohort=1);
%analysis3b(mhtype = Mood_clean, sex=1,cohort=2);
%analysis3b(mhtype = Mood_clean, sex=1,cohort=3);
%analysis3b(mhtype = Mood_clean, sex=1,cohort=4);
%analysis3b(mhtype = Mood_clean, sex=1,cohort=5);
*females;
%analysis3b(mhtype = Mood_clean, sex=2,cohort=1);
%analysis3b(mhtype = Mood_clean, sex=2,cohort=2);
%analysis3b(mhtype = Mood_clean, sex=2,cohort=3);
%analysis3b(mhtype = Mood_clean, sex=2,cohort=4);
%analysis3b(mhtype = Mood_clean, sex=2,cohort=5);


*Psychosis 
*males;
%analysis3b(mhtype = Psychosis_clean, sex=1,cohort=1);
%analysis3b(mhtype = Psychosis_clean, sex=1,cohort=2);
%analysis3b(mhtype = Psychosis_clean, sex=1,cohort=3);
%analysis3b(mhtype = Psychosis_clean, sex=1,cohort=4);
%analysis3b(mhtype = Psychosis_clean, sex=1,cohort=5);
*females;
%analysis3b(mhtype = Psychosis_clean, sex=2,cohort=1);
%analysis3b(mhtype = Psychosis_clean, sex=2,cohort=2);
%analysis3b(mhtype = Psychosis_clean, sex=2,cohort=3);
%analysis3b(mhtype = Psychosis_clean, sex=2,cohort=4);
%analysis3b(mhtype = Psychosis_clean, sex=2,cohort=5);


*SUD 
*males;
%analysis3b(mhtype = SUD_clean, sex=1,cohort=1);
%analysis3b(mhtype = SUD_clean, sex=1,cohort=2);
%analysis3b(mhtype = SUD_clean, sex=1,cohort=3);
%analysis3b(mhtype = SUD_clean, sex=1,cohort=4);
%analysis3b(mhtype = SUD_clean, sex=1,cohort=5);
*females;
%analysis3b(mhtype = SUD_clean, sex=2,cohort=1);
%analysis3b(mhtype = SUD_clean, sex=2,cohort=2);
%analysis3b(mhtype = SUD_clean, sex=2,cohort=3);
%analysis3b(mhtype = SUD_clean, sex=2,cohort=4);
%analysis3b(mhtype = SUD_clean, sex=2,cohort=5);



******BY INJURY TYPE********;
******BY INJURY TYPE********;
******BY INJURY TYPE********;
******BY INJURY TYPE********;


*total population;
proc genmod data=inj_analysis_7Apr2024;
model inj_unint_dirty=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Unintentional beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_7Apr2024;
model inj_self_dirty=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Self harm beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_7Apr2024;
model inj_assault_dirty=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Assault beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_7Apr2024;
model nsh_tbi_dirty=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'TBI beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_7Apr2024;
model nsh_othheadfaceneck_dirty=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'OTHER HEAD FACE & NECK beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_7Apr2024;
model nsh_spineback_dirty =MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'SPINE & BACK beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_7Apr2024;
model nsh_torso_dirty =MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'TORSO beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_7Apr2024;
model nsh_extremities_dirty =MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'EXTREMITIES beta' MH 1 / exp;
run;


proc genmod data=inj_analysis_7Apr2024;
model nsh_unclassified_dirty=MH prev_inj prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'UNCLASSIFIED beta' MH 1 / exp;
run;



*By sex; 
%macro analysis3c(inj,sex);
proc genmod data=inj_analysis_7Apr2024;
model &inj.=MH prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'MH' MH 1 / exp;
where sex = &sex.;
run;
%mend analysis3c;

*males;
%analysis3c(inj = inj_unint_dirty, sex = 1);
%analysis3c(inj = inj_self_dirty, sex = 1);
%analysis3c(inj = inj_assault_dirty, sex = 1);
%analysis3c(inj = nsh_tbi_dirty, sex = 1);
%analysis3c(inj = nsh_othheadfaceneck_dirty, sex = 1);
%analysis3c(inj = nsh_spineback_dirty, sex = 1);
%analysis3c(inj = nsh_torso_dirty, sex = 1);
%analysis3c(inj = nsh_extremities_dirty, sex = 1);
%analysis3c(inj = nsh_unclassified_dirty, sex = 1);

*females;
%analysis3c(inj = inj_unint_dirty, sex = 2);
%analysis3c(inj = inj_self_dirty, sex = 2);
%analysis3c(inj = inj_assault_dirty, sex = 2);
%analysis3c(inj = nsh_tbi_dirty, sex = 2);
%analysis3c(inj = nsh_othheadfaceneck_dirty, sex = 2);
%analysis3c(inj = nsh_spineback_dirty, sex = 2);
%analysis3c(inj = nsh_torso_dirty, sex = 2);
%analysis3c(inj = nsh_extremities_dirty, sex = 2);
%analysis3c(inj = nsh_unclassified_dirty, sex = 2);




*By sex and cohort; 
%macro analysis3d(inj,cohort,sex);
proc genmod data=inj_analysis_7Apr2024;
model &inj.=MH prev_inj dia_bir_birth_year_nbr/ dist = poisson link = log;
weight wgt;
estimate 'MH' MH 1 / exp;
where sex = &sex. and coh = &cohort.;
run;
%mend analysis3d;


*Unintentional 
*males;
%analysis3d(inj = inj_unint_dirty, sex=1,cohort=1);
%analysis3d(inj = inj_unint_dirty, sex=1,cohort=2);
%analysis3d(inj = inj_unint_dirty, sex=1,cohort=3);
%analysis3d(inj = inj_unint_dirty, sex=1,cohort=4);
%analysis3d(inj = inj_unint_dirty, sex=1,cohort=5);
*females;
%analysis3d(inj = inj_unint_dirty, sex=2,cohort=1);
%analysis3d(inj = inj_unint_dirty, sex=2,cohort=2);
%analysis3d(inj = inj_unint_dirty, sex=2,cohort=3);
%analysis3d(inj = inj_unint_dirty, sex=2,cohort=4);
%analysis3d(inj = inj_unint_dirty, sex=2,cohort=5);

*Self harm 
*males;
%analysis3d(inj = inj_self_dirty, sex=1,cohort=1);
%analysis3d(inj = inj_self_dirty, sex=1,cohort=2);
%analysis3d(inj = inj_self_dirty, sex=1,cohort=3);
%analysis3d(inj = inj_self_dirty, sex=1,cohort=4);
%analysis3d(inj = inj_self_dirty, sex=1,cohort=5);
*females;
%analysis3d(inj = inj_self_dirty, sex=2,cohort=1);
%analysis3d(inj = inj_self_dirty, sex=2,cohort=2);
%analysis3d(inj = inj_self_dirty, sex=2,cohort=3);
%analysis3d(inj = inj_self_dirty, sex=2,cohort=4);
%analysis3d(inj = inj_self_dirty, sex=2,cohort=5);

*Assault 
*males;
%analysis3d(inj = inj_assault_dirty, sex=1,cohort=1);
%analysis3d(inj = inj_assault_dirty, sex=1,cohort=2);
%analysis3d(inj = inj_assault_dirty, sex=1,cohort=3);
%analysis3d(inj = inj_assault_dirty, sex=1,cohort=4);
%analysis3d(inj = inj_assault_dirty, sex=1,cohort=5);
*females;
%analysis3d(inj = inj_assault_dirty, sex=2,cohort=1);
%analysis3d(inj = inj_assault_dirty, sex=2,cohort=2);
%analysis3d(inj = inj_assault_dirty, sex=2,cohort=3);
%analysis3d(inj = inj_assault_dirty, sex=2,cohort=4);
%analysis3d(inj = inj_assault_dirty, sex=2,cohort=5);

*TBI 
*males;
%analysis3d(inj = nsh_tbi_dirty, sex=1,cohort=1);
%analysis3d(inj = nsh_tbi_dirty, sex=1,cohort=2);
%analysis3d(inj = nsh_tbi_dirty, sex=1,cohort=3);
%analysis3d(inj = nsh_tbi_dirty, sex=1,cohort=4);
%analysis3d(inj = nsh_tbi_dirty, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_tbi_dirty, sex=2,cohort=1);
%analysis3d(inj = nsh_tbi_dirty, sex=2,cohort=2);
%analysis3d(inj = nsh_tbi_dirty, sex=2,cohort=3);
%analysis3d(inj = nsh_tbi_dirty, sex=2,cohort=4);
%analysis3d(inj = nsh_tbi_dirty, sex=2,cohort=5);

*Other head, neck and face 
*males;
%analysis3d(inj = nsh_othheadfaceneck_dirty, sex=1,cohort=1);
%analysis3d(inj = nsh_othheadfaceneck_dirty, sex=1,cohort=2);
%analysis3d(inj = nsh_othheadfaceneck_dirty, sex=1,cohort=3);
%analysis3d(inj = nsh_othheadfaceneck_dirty, sex=1,cohort=4);
%analysis3d(inj = nsh_othheadfaceneck_dirty, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_othheadfaceneck_dirty, sex=2,cohort=1);
%analysis3d(inj = nsh_othheadfaceneck_dirty, sex=2,cohort=2);
%analysis3d(inj = nsh_othheadfaceneck_dirty, sex=2,cohort=3);
%analysis3d(inj = nsh_othheadfaceneck_dirty, sex=2,cohort=4);
%analysis3d(inj = nsh_othheadfaceneck_dirty, sex=2,cohort=5);

*Spine and back 
*males;
%analysis3d(inj = nsh_spineback_dirty, sex=1,cohort=1);
%analysis3d(inj = nsh_spineback_dirty, sex=1,cohort=2);
%analysis3d(inj = nsh_spineback_dirty, sex=1,cohort=3);
%analysis3d(inj = nsh_spineback_dirty, sex=1,cohort=4);
%analysis3d(inj = nsh_spineback_dirty, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_spineback_dirty, sex=2,cohort=1);
%analysis3d(inj = nsh_spineback_dirty, sex=2,cohort=2);
%analysis3d(inj = nsh_spineback_dirty, sex=2,cohort=3);
%analysis3d(inj = nsh_spineback_dirty, sex=2,cohort=4);
%analysis3d(inj = nsh_spineback_dirty, sex=2,cohort=5);

*Torso 
*males;
%analysis3d(inj = nsh_torso_dirty, sex=1,cohort=1);
%analysis3d(inj = nsh_torso_dirty, sex=1,cohort=2);
%analysis3d(inj = nsh_torso_dirty, sex=1,cohort=3);
%analysis3d(inj = nsh_torso_dirty, sex=1,cohort=4);
%analysis3d(inj = nsh_torso_dirty, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_torso_dirty, sex=2,cohort=1);
%analysis3d(inj = nsh_torso_dirty, sex=2,cohort=2);
%analysis3d(inj = nsh_torso_dirty, sex=2,cohort=3);
%analysis3d(inj = nsh_torso_dirty, sex=2,cohort=4);
%analysis3d(inj = nsh_torso_dirty, sex=2,cohort=5);

*Extremities 
*males;
%analysis3d(inj = nsh_extremities_dirty, sex=1,cohort=1);
%analysis3d(inj = nsh_extremities_dirty, sex=1,cohort=2);
%analysis3d(inj = nsh_extremities_dirty, sex=1,cohort=3);
%analysis3d(inj = nsh_extremities_dirty, sex=1,cohort=4);
%analysis3d(inj = nsh_extremities_dirty, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_extremities_dirty, sex=2,cohort=1);
%analysis3d(inj = nsh_extremities_dirty, sex=2,cohort=2);
%analysis3d(inj = nsh_extremities_dirty, sex=2,cohort=3);
%analysis3d(inj = nsh_extremities_dirty, sex=2,cohort=4);
%analysis3d(inj = nsh_extremities_dirty, sex=2,cohort=5);

*Unclassified 
*males;
%analysis3d(inj = nsh_unclassified_dirty, sex=1,cohort=1);
%analysis3d(inj = nsh_unclassified_dirty, sex=1,cohort=2);
%analysis3d(inj = nsh_unclassified_dirty, sex=1,cohort=3);
%analysis3d(inj = nsh_unclassified_dirty, sex=1,cohort=4);
%analysis3d(inj = nsh_unclassified_dirty, sex=1,cohort=5);
*females;
%analysis3d(inj = nsh_unclassified_dirty, sex=2,cohort=1);
%analysis3d(inj = nsh_unclassified_dirty, sex=2,cohort=2);
%analysis3d(inj = nsh_unclassified_dirty, sex=2,cohort=3);
%analysis3d(inj = nsh_unclassified_dirty, sex=2,cohort=4);
%analysis3d(inj = nsh_unclassified_dirty, sex=2,cohort=5);


**************************************************************************;
**************************************************************************;
**************************************************************************;
**************************************************************************;

***Mh * injury type crosstabs;
proc freq data=file.inj_analysis_7Apr2024; 
table MH*(nsh_post_inj inj_unint_dirty inj_self_dirty inj_assault_dirty inj_other_dirty inj_undet_dirty); 
weight wgt; run;



****ANALYSIS 5 - MH TYPE BY INJURY TYPE;

data inj_analysis_7Apr2024;
set file.inj_analysis_7Apr2024;
run;

data totpop_dep_7Apr2024; 
set file.totpop_dep_7Apr2024;
run;

*without dep;
%macro analysis5(inj,mhtype);
proc genmod data=inj_analysis_7Apr2024;
model &inj.=&mhtype. prev_inj dia_bir_birth_year_nbr sex/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' &mhtype. 1 / exp;
run;
%mend analysis5;


%analysis5(inj = inj_unint_dirty, mhtype = Anxiety_clean);
%analysis5(inj = inj_unint_dirty, mhtype = Mood_clean);
%analysis5(inj = inj_unint_dirty, mhtype = Psychosis_clean);
%analysis5(inj = inj_unint_dirty, mhtype = SUD_clean);

%analysis5(inj = inj_self_dirty, mhtype = Anxiety_clean);
%analysis5(inj = inj_self_dirty, mhtype = Mood_clean);
%analysis5(inj = inj_self_dirty, mhtype = Psychosis_clean);
%analysis5(inj = inj_self_dirty, mhtype = SUD_clean);

%analysis5(inj = inj_assault_dirty, mhtype = Anxiety_clean);
%analysis5(inj = inj_assault_dirty, mhtype = Mood_clean);
%analysis5(inj = inj_assault_dirty, mhtype = Psychosis_clean);
%analysis5(inj = inj_assault_dirty, mhtype = SUD_clean);

%analysis5(inj = nsh_tbi_dirty, mhtype = Anxiety_clean);
%analysis5(inj = nsh_tbi_dirty, mhtype = Mood_clean);
%analysis5(inj = nsh_tbi_dirty, mhtype = Psychosis_clean);
%analysis5(inj = nsh_tbi_dirty, mhtype = SUD_clean);

%analysis5(inj = nsh_othheadfaceneck_dirty, mhtype = Anxiety_clean);
%analysis5(inj = nsh_othheadfaceneck_dirty, mhtype = Mood_clean);
%analysis5(inj = nsh_othheadfaceneck_dirty, mhtype = Psychosis_clean);
%analysis5(inj = nsh_othheadfaceneck_dirty, mhtype = SUD_clean);

%analysis5(inj = nsh_spineback_dirty, mhtype = Anxiety_clean);
%analysis5(inj = nsh_spineback_dirty, mhtype = Mood_clean);
%analysis5(inj = nsh_spineback_dirty, mhtype = Psychosis_clean);
%analysis5(inj = nsh_spineback_dirty, mhtype = Anxiety_clean);

%analysis5(inj = nsh_torso_dirty, mhtype = Anxiety_clean);
%analysis5(inj = nsh_torso_dirty, mhtype = Mood_clean);
%analysis5(inj = nsh_torso_dirty, mhtype = Psychosis_clean);
%analysis5(inj = nsh_torso_dirty, mhtype = SUD_clean);

%analysis5(inj = nsh_extremities_dirty, mhtype = Anxiety_clean);
%analysis5(inj = nsh_extremities_dirty, mhtype = Mood_clean);
%analysis5(inj = nsh_extremities_dirty, mhtype = Psychosis_clean);
%analysis5(inj = nsh_extremities_dirty, mhtype = SUD_clean);

%analysis5(inj = nsh_unclassified_dirty, mhtype = Anxiety_clean);
%analysis5(inj = nsh_unclassified_dirty, mhtype = Mood_clean);
%analysis5(inj = nsh_unclassified_dirty, mhtype = Psychosis_clean);
%analysis5(inj = nsh_unclassified_dirty, mhtype = SUD_clean);




*withdep;
%macro analysis5dep(inj,mhtype);
proc genmod data=totpop_dep_7Apr2024;
class dep1cat (ref='Q1');
model &inj.=&mhtype. prev_inj dia_bir_birth_year_nbr sex dep1cat/ dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' &mhtype. 1 / exp;
run;
%mend analysis5dep;

%analysis5dep(inj = inj_unint_dirty, mhtype = Anxiety_clean);
%analysis5dep(inj = inj_unint_dirty, mhtype = Mood_clean);
%analysis5dep(inj = inj_unint_dirty, mhtype = Psychosis_clean);
%analysis5dep(inj = inj_unint_dirty, mhtype = SUD_clean);

%analysis5dep(inj = inj_self_dirty, mhtype = Anxiety_clean);
%analysis5dep(inj = inj_self_dirty, mhtype = Mood_clean);
%analysis5dep(inj = inj_self_dirty, mhtype = Psychosis_clean);
%analysis5dep(inj = inj_self_dirty, mhtype = SUD_clean);

%analysis5dep(inj = inj_assault_dirty, mhtype = Anxiety_clean);
%analysis5dep(inj = inj_assault_dirty, mhtype = Mood_clean);
%analysis5dep(inj = inj_assault_dirty, mhtype = Psychosis_clean);
%analysis5dep(inj = inj_assault_dirty, mhtype = SUD_clean);

%analysis5dep(inj = nsh_tbi_dirty, mhtype = Anxiety_clean);
%analysis5dep(inj = nsh_tbi_dirty, mhtype = Mood_clean);
%analysis5dep(inj = nsh_tbi_dirty, mhtype = Psychosis_clean);
%analysis5dep(inj = nsh_tbi_dirty, mhtype = SUD_clean);

%analysis5dep(inj = nsh_othheadfaceneck_dirty, mhtype = Anxiety_clean);
%analysis5dep(inj = nsh_othheadfaceneck_dirty, mhtype = Mood_clean);
%analysis5dep(inj = nsh_othheadfaceneck_dirty, mhtype = Psychosis_clean);
%analysis5dep(inj = nsh_othheadfaceneck_dirty, mhtype = SUD_clean);

%analysis5dep(inj = nsh_spineback_dirty, mhtype = Anxiety_clean);
%analysis5dep(inj = nsh_spineback_dirty, mhtype = Mood_clean);
%analysis5dep(inj = nsh_spineback_dirty, mhtype = Psychosis_clean);
%analysis5dep(inj = nsh_spineback_dirty, mhtype = Anxiety_clean);

%analysis5dep(inj = nsh_torso_dirty, mhtype = Anxiety_clean);
%analysis5dep(inj = nsh_torso_dirty, mhtype = Mood_clean);
%analysis5dep(inj = nsh_torso_dirty, mhtype = Psychosis_clean);
%analysis5dep(inj = nsh_torso_dirty, mhtype = SUD_clean);

%analysis5dep(inj = nsh_extremities_dirty, mhtype = Anxiety_clean);
%analysis5dep(inj = nsh_extremities_dirty, mhtype = Mood_clean);
%analysis5dep(inj = nsh_extremities_dirty, mhtype = Psychosis_clean);
%analysis5dep(inj = nsh_extremities_dirty, mhtype = SUD_clean);

%analysis5dep(inj = nsh_unclassified_dirty, mhtype = Anxiety_clean);
%analysis5dep(inj = nsh_unclassified_dirty, mhtype = Mood_clean);
%analysis5dep(inj = nsh_unclassified_dirty, mhtype = Psychosis_clean);
%analysis5dep(inj = nsh_unclassified_dirty, mhtype = SUD_clean);




**************************************************************************;
**************************************************************************;
**************************************************************************;
**************************************************************************;


***Number of Injuries;
proc freq data=inj_analysis_17Feb2024;
table (n_inj_at nsh_n_inj_at)*MH /norow nocol nocum nopercent; 
run;







**************************************************************************;
**************************************************************************;
**********************ADDITIONAL ANALYSES 26 FEB 2025*********************;
**************************************************************************;
**************************************************************************;

************************************1*************************************;
**********E-CODES FOR UNCLASSIFIED SITES, EXCL SELF-HARM EVENTS***********;
************************************1*************************************;

proc format;
VALUE site6m
1='TBI'                 
2='OTH HEAD,FACE,NECK'              
3='SPINE&BACK'
4='TORSO'
5='EXTREMITIES' 
6='UNCLASSIFIABLE BY SITE';
run;


data temp2 (keep=snz_uid hosp_start start_date inj_order inj1-inj6 isrsite3 icd9code icd10code ecode9);
set file.injuries;
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

proc freq data=temp3;
table inj_unint inj_self inj_assault inj_other inj_undet; 
table inj_self * (inj_unint inj_assault inj_other inj_undet);
run;

proc freq data=temp3 (where=(inj_self=0 & isrsite3=6));
table icd9code icd10code ecode9;
run;



************************************2*************************************;
****************COUNTS OF OTHER AND UNDETERMINED INJURIES*****************;
************************************2*************************************;

data inj_analysis_7Apr2024;
set file.inj_analysis_7Apr2024;
run;

proc freq data= inj_analysis_7Apr2024;
table inj_assault inj_at inj_other inj_self inj_undet inj_unint;
run;



************************************3*************************************;
***************ANALYSES BY INJURY TYPE CONTROLLING FOR DEP****************;
************************************3*************************************;
data totpop_dep_7Apr2024; 
set file.totpop_dep_7Apr2024;
run;

**OVERALL**;


proc genmod data=totpop_dep_7Apr2024;
class dep1cat (ref='Q1');
model inj_unint_dirty=MH prev_inj  dia_bir_birth_year_nbr sex dep1cat/ dist = poisson link = log;
weight wgt;
estimate 'Unintentional beta' MH 1 / exp;
run;


proc genmod data=totpop_dep_7Apr2024;
class dep1cat (ref='Q1');
model inj_self_dirty=MH prev_inj  dia_bir_birth_year_nbr sex dep1cat/ dist = poisson link = log;
weight wgt;
estimate 'Self harm beta' MH 1 / exp;
run;


proc genmod data=totpop_dep_7Apr2024;
class dep1cat (ref='Q1');
model inj_assault_dirty=MH prev_inj  dia_bir_birth_year_nbr sex dep1cat/ dist = poisson link = log;
weight wgt;
estimate 'Assault beta' MH 1 / exp;
run;



*By sex; 
%macro injtype_dep_sex(inj,sex);
proc genmod data=totpop_dep_7Apr2024;
class dep1cat (ref='Q1');
model &inj.=MH prev_inj dia_bir_birth_year_nbr dep1cat / dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
where sex = &sex.;
run;
%mend injtype_dep_sex;

*UNINTENTIONAL;
%injtype_dep_sex(inj = inj_unint_dirty, sex = 1);
%injtype_dep_sex(inj = inj_unint_dirty, sex = 2);

*SELF-HARM;
%injtype_dep_sex(inj = inj_self_dirty, sex = 1);
%injtype_dep_sex(inj = inj_self_dirty, sex = 2);

*ASSAULT;
%injtype_dep_sex(inj = inj_assault_dirty, sex = 1);
%injtype_dep_sex(inj = inj_assault_dirty, sex = 2);



*By sex and cohort; 
%macro injtype_dep_sex_coh(inj,sex,coh);
proc genmod data=totpop_dep_7Apr2024;
class dep1cat (ref='Q1');
model &inj.=MH prev_inj dia_bir_birth_year_nbr dep1cat / dist = poisson link = log;
weight wgt;
estimate 'Mental health beta' MH 1 / exp;
where sex = &sex. & coh = &coh.;
run;
%mend injtype_dep_sex_coh;

**UNINTENTIONAL;
*males;
%injtype_dep_sex_coh(inj = inj_unint_dirty, sex=1, coh=1);
%injtype_dep_sex_coh(inj = inj_unint_dirty, sex=1,coh=2);
%injtype_dep_sex_coh(inj = inj_unint_dirty, sex=1, coh=3);
%injtype_dep_sex_coh(inj = inj_unint_dirty, sex=1, coh=4);
%injtype_dep_sex_coh(inj = inj_unint_dirty, sex=1, coh=5);

*females;
%injtype_dep_sex_coh(inj = inj_unint_dirty, sex=2, coh=1);
%injtype_dep_sex_coh(inj = inj_unint_dirty, sex=2, coh=2);
%injtype_dep_sex_coh(inj = inj_unint_dirty, sex=2, coh=3);
%injtype_dep_sex_coh(inj = inj_unint_dirty, sex=2, coh=4);
%injtype_dep_sex_coh(inj = inj_unint_dirty, sex=2, coh=5);

**SELF-HARM;
*males;
%injtype_dep_sex_coh(inj = inj_self_dirty, sex=1, coh=1);
%injtype_dep_sex_coh(inj = inj_self_dirty, sex=1, coh=2);
%injtype_dep_sex_coh(inj = inj_self_dirty, sex=1, coh=3);
%injtype_dep_sex_coh(inj = inj_self_dirty, sex=1, coh=4);
%injtype_dep_sex_coh(inj = inj_self_dirty, sex=1, coh=5);

*females;
%injtype_dep_sex_coh(inj = inj_self_dirty, sex=2, coh=1);
%injtype_dep_sex_coh(inj = inj_self_dirty, sex=2, coh=2);
%injtype_dep_sex_coh(inj = inj_self_dirty, sex=2, coh=3);
%injtype_dep_sex_coh(inj = inj_self_dirty, sex=2, coh=4);
%injtype_dep_sex_coh(inj = inj_self_dirty, sex=2, coh=5);

**ASSAULT;
*males;
%injtype_dep_sex_coh(inj = inj_assault_dirty, sex=1, coh=1);
%injtype_dep_sex_coh(inj = inj_assault_dirty, sex=1, coh=2);
%injtype_dep_sex_coh(inj = inj_assault_dirty, sex=1, coh=3);
%injtype_dep_sex_coh(inj = inj_assault_dirty, sex=1, coh=4);
%injtype_dep_sex_coh(inj = inj_assault_dirty, sex=1, coh=5);

*females;
%injtype_dep_sex_coh(inj = inj_assault_dirty, sex=2, coh=1);
%injtype_dep_sex_coh(inj = inj_assault_dirty, sex=2, coh=2);
%injtype_dep_sex_coh(inj = inj_assault_dirty, sex=2, coh=3);
%injtype_dep_sex_coh(inj = inj_assault_dirty, sex=2, coh=4);
%injtype_dep_sex_coh(inj = inj_assault_dirty, sex=2, coh=5);




