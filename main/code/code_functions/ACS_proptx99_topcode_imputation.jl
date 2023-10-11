
function ACS_PROPTX99_topcode_imputation!(df)
    df_sample = df[(df.proptx99 .== 67) .| (df.proptx99 .== 68), [:valueh, :YEAR, :proptx99, :proptx99_recode, :statefips]]
    df_sample.txrate = df_sample.proptx99_recode ./ df_sample.valueh

    df_sample.year_group .= 1
    df_sample[in([2010,2011]).(df_sample.YEAR), :year_group] .= 2
    df_sample[in([2015,2016]).(df_sample.YEAR), :year_group] .= 3

    df_sample = combine(groupby(df_sample, [:year_group, :statefips]), :txrate => (x -> mean(x[(x .< 1) .& (.!ismissing.(x))])) => :txrate_topavg)

    df.year_group .= 1
    df[in([2010,2011]).(df.YEAR), :year_group] .= 2
    df[in([2015,2016]).(df.YEAR), :year_group] .= 3

    df = leftjoin(df,df_sample[:, [:year_group, :statefips, :txrate_topavg]], on = [:year_group, :statefips])
    select!(df, Not(:year_group))
    df.proptx99_imputed = copy(df.proptx99_recode)
    df.proptx99_imputed = convert(Array{Float64}, df.proptx99_imputed)
    df[df.proptx99 .== 69, :proptx99_imputed] .= df[df.proptx99 .== 69, :valueh] .* df[df.proptx99 .== 69, :txrate_topavg]

    return df
end