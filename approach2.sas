data have;
  input (patient_id drug_name drug_type) ($) (start end) (: date11.);
  format start end  date9.;
  cards;
A11                        N1               Non_core   23-Apr-14   21-May-14
A11                        C1                 Core         27-Apr-14   25-May-14
A11                        C1                 Core         3-May-14   31-May-14
A11                        N1               Non_core   10-May-14   7-Jun-14
A11                        C2                  Core        11-May-14    8-Jun-14
A11                        N2               Non_core   12-May-14    9-Jun-14
A11                        C1                 Core         10-Jul-14      7-Aug-14
A11                        C1                 Core         15-Jul-14    12-Aug-14
A11                        C3                 Core         29-Jul-14     26-Aug-14
A11                        N4              Non_core     8-Sep-14       6-Oct-14
A11                        N2              Non_core     9-Sep-14      7-Oct-14
A11                        C1                Core           12-Sep-14    10-Oct-14
A11                        C1                Core           15-Sep-14    13-Oct-14
A11                        C1                Core           27-Sep-14     25-Oct-14
A11                        C3                Core            1-Jan-15        29-Jan-15
A11                        C1                 Core           3-Jan-15       31-Jan-15
A11                        C1                 Core            5-Jan-15       2-Feb-15
A11                        C1                 Core           10-Jan-15      7-Feb-15
A11                        N1              Non_core       15-Jan-15    12-Feb-15
A11                        N2              Non_core       18-Jan-15     15-Feb-15
;

data want (keep=patient_id drug start_date end_date lot);
  set have;
  by patient_id;
  retain start_date end_date drug end60;
  format start_date end_date date9.;
  set have ( firstobs = 2 keep = start drug_type drug_name 
              rename = (start = next_start drug_type=next_type drug_name=next_drug) )
      have (      obs = 1 drop = _all_ );
  next_start = ifn(last.patient_id, (.), next_start );
  if first.patient_id or counter eq 0 then do;
    start_date=start;
    end_date=end;
    if drug_type eq 'Core' then do;
      counter=1;
      drug=drug_name;
      end60=end+60;
    end;
    else do;
      drug='';
      counter=0;
    end;
  end;
  else if start le Start_Date+21 then do;
    if counter=0 then do;
      if drug_type eq 'Core' then do;
        drug=drug_name;
        counter=1;
        end60=end;
      end;
    end;
    else do;
      if not findw(drug,drug_name) then drug=catx('+',drug,drug_name);
      if drug_type eq 'Core' then do;
        counter+1;
        end_date=end;
      end;
    end;
  end;
  else if Start_Date le end60 and findw(drug,drug_name) and drug_type eq 'Core' then do;
    end60=end+60;
  end;
  if counter gt 0 and
     (next_start gt End60 or
     (counter gt 0 and
      not findw(drug,next_drug) and
      next_type eq 'Core' and
      next_start gt start_date+21)) or
      last.patient_id then do;
    end_date=start-1;
    lot+1;
    output;
    drug='';
    core='';
    counter=0;
  end;
run;


data want ;
  set have;
  by patient_id;
set have ( firstobs = 2 keep = start drug_type drug_name 
              rename = (start = next_start drug_type=next_type drug_name=next_drug) )
      have (      obs = 1 drop = _all_ );
	  next_start = ifn(last.patient_id, (.), next_start );
	  run;

