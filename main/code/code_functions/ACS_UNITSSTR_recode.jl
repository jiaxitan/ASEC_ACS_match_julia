
function ACS_UNITSSTR_recode!(df)

    UNITSSTR_codes = collect(0:1:10);
    UNITSSTR_vals1 = 0;     # N/A
    UNITSSTR_vals2 = 1;     # Mobile home or trailer
    UNITSSTR_vals3 = 99;    # Boat, tent, van, other
    UNITSSTR_vals4 = 5;     # 1-family house, detached
    UNITSSTR_vals5 = 5;     # 1-family house, attached
    UNITSSTR_vals6 = 2;     # 2-family building
    UNITSSTR_vals7 = 3;     # 3-4 family building
    UNITSSTR_vals8 = 4;     # 5-9 family building
    UNITSSTR_vals9 = 6;     # 10-19 family building
    UNITSSTR_vals10= 6;     # 20-49 family building
    UNITSSTR_vals11= 6;     # 50+ family building

    UNITSSTR_vals = [UNITSSTR_vals1; UNITSSTR_vals2; UNITSSTR_vals3; UNITSSTR_vals4; UNITSSTR_vals5; UNITSSTR_vals6; UNITSSTR_vals7; UNITSSTR_vals8; UNITSSTR_vals9; UNITSSTR_vals10; UNITSSTR_vals11];
    UNITSSTR_dic = Dict(UNITSSTR_codes .=> UNITSSTR_vals);

    df[:, :UNITSSTR_recode] = map(x -> UNITSSTR_dic[x], df[:, :UNITSSTR]);

    return df

end
