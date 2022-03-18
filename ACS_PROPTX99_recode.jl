
function ACS_PROPTX99_recode!(df, code_missing = 0)

    PROPTX99_codes = [0; collect(1:56); collect(58:1:69)]; # 57 only in 1990 assigned

    code_missing == 0 ? PROPTX99_vals1 = [0; 0; collect(25:50:975)] : PROPTX99_vals1 = [missing; 0; collect(25:50:975)]
    PROPTX99_vals2 = collect(1050:100:4950); PROPTX99_vals3 = collect(5250:500:5750); PROPTX99_vals4 = collect(6500:1000:9500); PROPTX99_vals5 = 10000;
    PROPTX99_vals = [PROPTX99_vals1; PROPTX99_vals2; PROPTX99_vals3; PROPTX99_vals4; PROPTX99_vals5];
    PROPTX99_dic = Dict(PROPTX99_codes .=> PROPTX99_vals);

    df[:, :PROPTX99_recode] = map(x -> PROPTX99_dic[x], df[:, :PROPTX99]);

    return df

end
