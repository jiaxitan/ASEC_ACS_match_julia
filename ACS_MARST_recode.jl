
function ACS_MARST_recode!(df)

    MARST_codes = collect(1:1:6);
    MARST_vals1 = repeat([1], 2);   # married
    MARST_vals2 = repeat([2], 6-2); # not married
    MARST_vals = [MARST_vals1; MARST_vals2];
    MARST_dic = Dict(MARST_codes .=> MARST_vals);

    df[:, :MARST_recode] = map(x -> MARST_dic[x], df[:, :MARST]);

    return df

end
