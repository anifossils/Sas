libname anal "C:\Users\Ani\Downloads";


Proc sort data=anal.Mel_drug_data_p out=Mel_drug_data_p ;
by ENROLID;
run;


Data regimen_2(keep= ENROLID SVCDATE cut_date DAYSUPP Generic route drug_type  end_dt flag_21);
set Mel_drug_data_p;
format cut_date end_dt date9.;
retain cut_date;
by ENROLID;
if first.ENROLID then do;
cut_date=SVCDATE+21-1;
end;
end_dt=SVCDATE+DAYSUPP-1;
if SVCDATE <= cut_date then flag_21="Y";
else flag_21 ="N";
run;


proc sort data=regimen_2 out=regimen_3 nodupkey;
by enrolid SVCDATE Generic;
run;



Data flag_21_y falg_21_n;
set regimen_3;
if flag_21 = "Y" then output flag_21_y;
else output falg_21_n;
run;

Proc sql;
create table tagging as select
ENROLID,count(distinct drug_type)as cnt
from flag_21_y
where drug_type ne "UNK"
group by ENROLID;
quit;

Proc sql;
create table regimen_1_1 as select a.*,
b.cnt
from flag_21_y as a
left join
tagging as b
on a.ENROLID=b.ENROLID;
quit;


Data regimen_1;
set regimen_1_1;
format reg_type $5.;
if  cnt =1 and drug_type ="C" then reg_type= "CO";
else if  cnt =1 and drug_type ="NC" then reg_type="NCO";
else reg_type="C+NC";
where drug_type ne "UNK";
run;

/*data regimen_4;*/
/*set regimen_1;*/
/*format new_end date9.;*/
/*by enrolid;*/
/*if reg_type = "C"  then do ;*/
/*if last.enrolid then new_end = end_dt;*/
/*end;*/
/*else if reg_type = "NC"  then do ;*/
/*if last.enrolid then new_end = end_dt;*/
/*end;*/
/*else if reg_type = "C+NC" then do ;*/
/*if last.enrolid and drug_type ="C" then new_end = end_dt;*/
/*/*else if last.enrolid and drug_type ="NC" then new_end = end_dt;*/*/
/*end;*/
/*/*drug1=compress(lowcase(Generic));*/*/
/*run;*/;

Proc sort data=regimen_1;
by enrolid end_dt ;
run;

data regimen_4;
set regimen_1;
format new_end date9.;
by enrolid  ;
if first.enrolid and last .enrolid then do;
if reg_type = "CO" then new_end = end_dt;
else if reg_type = "NCO" then new_end = end_dt;
end;
else if reg_type = "CO"  then do;
if last.enrolid then new_end = end_dt ;
end;
else if  reg_type = "NCO"  then do;
if last.enrolid then new_end = end_dt;
end;
if reg_type = "C+NC" and drug_type ="C"   then do ;
if  not last.enrolid  then new_end = end_dt;
else if  last.enrolid then do;
new_end = end_dt;
end;
end;
run;

data xx;
set regimen_4;
where  reg_type = "C+NC";
run;

data regimen_5(keep=enrolid drug);
length drug $500.;
   do until (last.enrolid);
      set regimen_4;
        by enrolid notsorted;
      drug=catx(',',drug,generic);
   end;
run;

/*data regimen_6;*/
/*   set regimen_5;*/
/*   array name[35] $32 _temporary_;*/
/*   call missing(of name[*]);*/
/*   do i = 1 to dim(name) until(p eq 0);*/
/*      call scan(drug,i,p,l);*/
/*      name[i] = substrn(drug,p,l);*/
/*      end;*/
/*   call sortc(of name[*]);*/
/*   length drug_new $200;*/
/*   drug_new = catx(',',of name[*]);*/
/*   drop i p l;*/
/*   run;*/
/**/
/**/
/*data regimen_6;*/
/* set regimen_5;*/
/*    length word $100;*/
/*    i = 2;*/
/*    do while(scan(drug, i, ',') ^= '');*/
/*        word = scan(drug, i, ',');*/
/*        do j = 1 to i - 1;*/
/*            if word = scan(drug, j, ',') then do;*/
/*                start = findw(drug, word, ',', findw(drug, word, ',', 't') + 1, 't');*/
/*                drug = cats(substr(drug, 1, start - 2), substr(drug, start + length(word)));*/
/*                leave;*/
/*            end;*/
/*        end;*/
/*        i = i + 1;*/
/*    end;*/
/*keep enrolid drug;*/
/*run;*/


/*Proc sql;*/
/*create table tagging_1 as select*/
/*ENROLID,count(distinct drug_type)as cnt_1*/
/*from regimen_4*/
/*group by ENROLID;*/
/*quit;*/
/**/
/**/
/*Proc sql;*/
/*create table tagging_2 as select a.*,*/
/*b.cnt_1,*/
/*case when cnt_1 =1 and drug_type ="C" then "C"*/
/*     when cnt_1 =1 and drug_type ="NC" then "NC"*/
/*	 else "C+NC"*/
/*end as reg_type*/
/*from flag_21_y as a*/
/*left join*/
/*tagging_1 as b*/
/*on a.ENROLID=b.ENROLID*/
/*where drug_type  ne "UNK";*/
/*quit;*/

Proc sql;
create table tagging_3 as select distinct ENROLID,reg_type
from regimen_1;
quit;


Proc sql;
create table regimen_6 as select
ENROLID,min(svcdate) as start_dt  format= date9.
from regimen_4
group by
ENROLID;
quit;


Data regimen_7(keep= ENROLID new_end);
set regimen_4;
where new_end ne . ;
by ENROLID;
if last.ENROLID;
run;

Data regimen_8;
merge regimen_5 regimen_6 regimen_7 ;
by ENROLID;
run;

Data regimen_9;
set falg_21_n;
format drug $500.;
rename svcdate=start_dt end_dt=new_end generic=drug ;
run;

Data regimen_10;
set regimen_8 regimen_9(keep=ENROLID start_dt new_end drug drug_type);
retain reg_type;
by ENROLID;
run;

Proc transpose data=regimen_10 out=regimen_11(drop=_name_ _label_) prefix=reg;
by ENROLID;
var drug;
run;

Proc transpose data=regimen_10 out=regimen_12(drop=_name_ _label_) prefix=strt;
by ENROLID;
var start_dt;
run;

Proc transpose data=regimen_10 out=regimen_13(drop=_name_ _label_) prefix=ends;
by ENROLID;
var new_end;
run;

Proc transpose data=regimen_10 out=regimen_14(drop=_name_ _label_) prefix=type;
by ENROLID;
var drug_type;
run;


Data regimen_15;
merge regimen_11 regimen_12 regimen_13 regimen_14 tagging_3;
by ENROLID;
run;

Data regimen_16;
set regimen_15;
where reg_type="C+NC";
run;

data regimen_17  ;
	set regimen_16 ;
	format new_start new_end date9.; 
	array strt(36) strt1-strt36;
	array ends(36) ends1-ends36;
	array reg(36) $ reg1-reg36;
	array type(36) $ type1-type36;
    z= N(of strt:);
do i =1 to z;
if reg(i) ne " " and reg(i+1) eq " " then do;
new_reg= reg(i);
new_start=strt(i);
new_end = ends(i);
output;
end;
else  do;
if reg(i) ~= " " and reg(i+1) ~= " " then do;
if index(reg(i),"reg(i+1)") > 0 and ends(i)+60 >= strt(i+1) and type(i+1)="C" then do;
new_reg= reg(i);
new_start=strt(i);
new_end = ends(i+1);
output;
end;
else if index(reg(i),"reg(i+1)") = 0 and ends(i)+60 >= strt(i+1) and type(i+1)="C" then do;
new_reg= reg(i);
new_start=strt(i);
new_end = strt(i+1)-1;
output;
end;
end;
end;
end;
run;
