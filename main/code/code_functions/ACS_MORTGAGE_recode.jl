function ACS_MORTGAGE_recode!(df)
    MORTGAGE_codes = [0,1,3,4];
    
    MORTGAGE_vals1 = -1;   # NA
    MORTGAGE_vals2 = 0;   # No Mortgage
    MORTGAGE_vals3 = repeat([1], 4-2); # Has Mortgage
    MORTGAGE_vals = [MORTGAGE_vals1; MORTGAGE_vals2; MORTGAGE_vals3];
    
    MORTGAGE_dic = Dict(MORTGAGE_codes .=> MORTGAGE_vals);
    
    df[:, :MORTGAGE_recode] = map(x -> MORTGAGE_dic[x], df[:, :MORTGAGE]);
    
    return df
end

function ACS_MORTGAG2_recode!(df)
    MORTGAG2_codes = [0,1,3,4,5];
    
    MORTGAG2_vals1 = -1;   # NA
    MORTGAG2_vals2 = 0;   # No 2nd Mortgage
    MORTGAG2_vals3 = repeat([1], 5-2); # Has 2nd Mortgage
    MORTGAG2_vals = [MORTGAG2_vals1; MORTGAG2_vals2; MORTGAG2_vals3];
    
    MORTGAG2_dic = Dict(MORTGAG2_codes .=> MORTGAG2_vals);
    
    df[:, :MORTGAG2_recode] = map(x -> MORTGAG2_dic[x], df[:, :MORTGAG2]);
    
    return df
end

