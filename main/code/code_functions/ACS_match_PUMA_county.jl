# NOTE: 
# Identify some unidentified county with code 0 in ACS using PUMA-county equivalency files
# 0: ACS PUMA includes more than one county
# 
# ACS 2005, 2006, 2010, 2011 use PUMA 2000. ACS 2015, 2016 use PUMA 2010.

function leftjoin_by_year(df, df_PUMA_county)
    if size(df)[1] != 0
        select!(df, Not(:COUNTYFIPS2));

        res = leftjoin(df, df_PUMA_county, on = [:STATEFIPS => :STATEFIPS, :PUMA => :PUMA]);
        sort!(res, [:YEAR, :STATEFIPS, :PUMA]);

        res[ismissing.(res.COUNTYFIPS2),:COUNTYFIPS2] .= 0;

        return res.COUNTYFIPS2
    end

    return df.COUNTYFIPS2

end

function ACS_match_PUMA_county!(df_ACS, df_state_info)
    
    df_PUMA_county00 = HTTP.get("https://usa.ipums.org/usa/volii/2000PUMAsASCII.txt");
    df_PUMA_county00 = CSV.read(df_PUMA_county00.body,delim = " ",header = false, DataFrame);
    select!(df_PUMA_county00,2:6);
    filter!(r -> (string(r[1]) == "781"), df_PUMA_county00);
    deleteat!(df_PUMA_county00,1);
    select!(df_PUMA_county00,2,4,5);
    rename!(df_PUMA_county00,[:STATEFIPS, :PUMA, :COUNTYFIPS2]);

    df_PUMA_county10 = DataFrame(STATEFIPS = Any[], PUMA = Any[], COUNTYFIPS2 = Any[]);
    
    for state in df_state_info.STATEFIPS
        state = lpad(string(state), 2, "0")
        df_state = HTTP.get(string("https://www2.census.gov/geo/docs/reference/puma/PUMSEQ10_", state, ".txt"));
        df_state = CSV.read(df_state.body,delim = "             ",header = false, DataFrame);
        select!(df_state, 1);
        filter!(r -> (SubString(r[1], 1, 3) == "796"), df_state);
        append!(df_PUMA_county10, DataFrame(STATEFIPS = SubString.(df_state[:, 1], 4, 5), PUMA = SubString.(df_state[:, 1], 14, 18), COUNTYFIPS2 = SubString.(df_state[:, 1], 19, 21)));
    end

    df_PUMA_county00 = parse.(Int64, df_PUMA_county00); df_PUMA_county10 = parse.(Int64, df_PUMA_county10);

    df_PUMA_county00 = filter(r -> r.nrow == 1, combine(groupby(df_PUMA_county00, [:STATEFIPS, :PUMA]), nrow, :COUNTYFIPS2));
    df_PUMA_county10 = filter(r -> r.nrow == 1, combine(groupby(df_PUMA_county10, [:STATEFIPS, :PUMA]), nrow, :COUNTYFIPS2));

    select!(df_PUMA_county00, Not(:nrow)); select!(df_PUMA_county10, Not(:nrow));

    insertcols!(df_ACS, size(df_ACS,2)+1, :COUNTYFIPS2 => df_ACS.COUNTYFIPS);
    
    df_ACS[(df_ACS.COUNTYFIPS2 .== 0) .& (df_ACS.YEAR_survey .< 2012), :COUNTYFIPS2] .=  leftjoin_by_year(df_ACS[(df_ACS.COUNTYFIPS2 .== 0) .& (df_ACS.YEAR_survey .< 2012), :], df_PUMA_county00);
    df_ACS[(df_ACS.COUNTYFIPS2 .== 0) .& (df_ACS.YEAR_survey .>= 2012), :COUNTYFIPS2] .=  leftjoin_by_year(df_ACS[(df_ACS.COUNTYFIPS2 .== 0) .& (df_ACS.YEAR_survey .>= 2012), :], df_PUMA_county10);

end

