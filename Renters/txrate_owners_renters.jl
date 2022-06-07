function txrate_owners_renters(df_owners_mean, df_renters_mean, state)
    p1 = scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.txrate_mean.*100,
    label = "owners",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(round(Int, exp(xi)/1000)) * "K",
    xlim = (9,13))
    # ylim = (6,10)
    scatter!(df_renters_mean.log_grossinc_mean, df_renters_mean.txrate_mean.*100,
    label = "renters - fitted",
    legend = :topleft,
    foreground_color_legend = nothing,
    yaxis="Property tax rate",
    xlim = (9,13),
    #ylim = (0.5,1.5),
    title = "Property tax rate - " * state)

    return p1
end

function txrate_owners_renters_states!(df_owners_mean, df_renters_mean, outfile)
    state = unique(df_owners_mean.statename);
    for s in state
        txrate_owners_renters(df_owners_mean[df_owners_mean.statename .== s, :], df_renters_mean[df_renters_mean.statename .== s, :], s);
        savefig(outfile * s);
    end
end