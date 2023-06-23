
function ASEC_METRO_recode!(df)

    METRO_dic = Dict(
    0 => "Metropolitan Area not identified",
    1 => "Not in Metropolitan Area",
    2 => "In Metropolitan Area: Central City",
    3 => "In Metropolitan Area: Outside Central City",
    4 => "In Metropolitan Area: Central City Status Unknown",
    9 => "Metropolitan Area Missing/Unknown")

    df[:, :METRO_name] = map(x -> METRO_dic[x], df[:, :METRO]);

    return df

end
