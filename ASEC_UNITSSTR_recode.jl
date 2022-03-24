
function ASEC_UNITSSTR_recode!(df)

    UNITSSTR_codes = [0,1,5,6,7,11,12];
    UNITSSTR_vals1 = 0;     # not coded
    UNITSSTR_vals2 = 1;     # Mobile home or trailer
    UNITSSTR_vals3 = 2;     # 2 family building
    UNITSSTR_vals4 = 3;     # 3-4 family building
    UNITSSTR_vals5 = 4;     # 5-9 family building
    UNITSSTR_vals6 = 5;     # One unit, unspecified type (CPS)
    UNITSSTR_vals7 = 6;     # 10+ units in structure (CPS)
    UNITSSTR_vals = [UNITSSTR_vals1; UNITSSTR_vals2; UNITSSTR_vals3; UNITSSTR_vals4; UNITSSTR_vals5; UNITSSTR_vals6; UNITSSTR_vals7];
    UNITSSTR_dic = Dict(UNITSSTR_codes .=> UNITSSTR_vals);

    df[:, :UNITSSTR_recode] = map(x -> UNITSSTR_dic[x], df[:, :UNITSSTR]);

    return df

end
