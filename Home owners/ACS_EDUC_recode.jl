
function ACS_EDUC_recode!(df)

    EDUC_codes = collect(0:1:11);
    EDUC_vals1 = repeat([1], 6);      # less than high school
    EDUC_vals2 = repeat([2], 9-5);    # high school and some college
    EDUC_vals3 = repeat([3], 11-9);   # at least undergrad degree
    EDUC_vals = [EDUC_vals1; EDUC_vals2; EDUC_vals3];
    EDUC_dic = Dict(EDUC_codes .=> EDUC_vals);

    df[:, :EDUC_recode] = map(x -> EDUC_dic[x], df[:, :EDUC]);

    return df

end
