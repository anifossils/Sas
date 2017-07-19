
/*datasets*/
/*for 60 day replacement anal.diag_proc;*/
/*entire drug data*/
/*anal.mel_drug_proc_ndc;*/

/*import drug type - core/non-core*/

proc import 
datafile="E:\Projects\BMS\13948 - Melanoma\Database\RawData\DRUG_TYPE-2017-07-19.txt"
out=anal.drug_type_generic
dbms=tab REPLACE;
getnames=Yes;
datarow=2;
guessingrows=32767;
run;


data diag_proc1 (drop=type rename=date=svcdate);
set anal.diag_proc;
flag='NDRG';
label date=svcdate;
run;

/*to check that diag_proc data corrsponds to only analysis cohort on or after index date*/
proc sql;
create table diag_proc_chk as
select a.*, b.idxdt 
from diag_proc1 a
left join 
sasdata.analysis_cohort b
on a.enrolid=b.enrolid;
quit;

data x;
set diag_proc_chk;
where idxdt>svcdate;
run;
/************************************************/

data mel_drug_proc_ndc1;
set anal.mel_drug_proc_ndc;
flag='DRUG';
if generic='NON-PVC INTRAVENOUS ADMINIST'  then delete;
if propcase(generic)='Betaxolol Hydrochloride' then delete;
run;

data drug_all;
set mel_drug_proc_ndc1 diag_proc1;
enddate=svcdate+daysupp-1;
format enddate date9.;
run;

proc sort data=drug_all;
by enrolid svcdate flag;
run;

%let gap=60;
data drug_all2;
set drug_all;
by enrolid svcdate flag;
format drug_prior2 $100.;
retain drug_prior2;
drug_prior=lag(generic);
end_prior=lag(enddate);
if first.enrolid then do;
drug_prior='';
drug_prior2='';
end;
else if drug_prior ne '' then drug_prior2=drug_prior;
format end_prior date9.;
gap1=svcdate-end_prior;
if not first.enrolid and flag='NDRG' then do;
	if svcdate-end_prior<=&gap. then generic=drug_prior2;
end;
run;

data drug_all3;
set drug_all2;
where generic ne '';
keep enrolid svcdate generic daysupp flag;
run;

proc sort data=drug_all3;
by enrolid generic svcdate descending daysupp flag;
run;

data drug_all4;
set drug_all3;
by enrolid generic svcdate descending daysupp flag;
if first.svcdate;
generic=propcase(generic);
run;


proc sort data=drug_all4 out=drug_all5;
by enrolid svcdate generic ;
run;



proc sql;
create table anal.drug_data_final as
select a.*, b.type
from drug_all5 a
left join
anal.drug_type_generic b
on lowcase(a.generic)=lowcase(b.generic)
order by enrolid, svcdate, generic, type;
quit;


