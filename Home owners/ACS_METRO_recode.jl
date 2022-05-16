
function ACS_METRO_recode!(df)

    METRO_dic = Dict(
    0 => "Metropolitan status indeterminable (mixed)",
    1 => "Not in Metropolitan Area",
    2 => "In Metropolitan Area: Central/Principal City",
    3 => "In Metropolitan Area: Not in Central/Principal City",
    4 => "In Metropolitan Area: Central/Principal City status indeterminable (mixed)")

    df[:, :METRO_name] = map(x -> METRO_dic[x], df[:, :METRO]);

    return df

end
