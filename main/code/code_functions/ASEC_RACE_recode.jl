
function ASEC_RACE_recode!(df)

    RACE_codes = [100; 200; collect(300:1:830)];

    RACE_vals1 = repeat([1], 1);       # white
    RACE_vals2 = repeat([2], 1);       # black
    RACE_vals3 = repeat([3], 830-299); # other
    RACE_vals = [RACE_vals1; RACE_vals2; RACE_vals3];

    RACE_dic = Dict(RACE_codes .=> RACE_vals);

    df[:, :RACE_recode] = map(x -> RACE_dic[x], df[:, :RACE]);

    return df

end
