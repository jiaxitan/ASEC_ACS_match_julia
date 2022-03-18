
function ASEC_EDUC_recode!(df)

    EDUC_codes = collect(1:1:125);
    EDUC_vals1 = repeat([1], 60);       # less than high school
    EDUC_vals2 = repeat([2], 92-60);    # high school and some college
    EDUC_vals3 = repeat([3], 125-92);   # at least undergrad degree
    EDUC_vals = [EDUC_vals1; EDUC_vals2; EDUC_vals3];
    EDUC_dic = Dict(EDUC_codes .=> EDUC_vals);

    df[:, :EDUC_recode] = map(x -> EDUC_dic[x], df[:, :EDUC]);

    return df

end
