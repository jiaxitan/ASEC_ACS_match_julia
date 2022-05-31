### This file plots imputed property taxes for owners and renters by each state

function proptx_owners_renters(df_owners_mean, df_renters_mean, state)
    p1 = scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.log_proptx_mean,
    label = "owners",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(round(Int, exp(xi)/1000)) * "K",
    xlim = (9,13))
    #ylim = (6,10)
    scatter!(df_renters_mean.log_grossinc_mean, df_renters_mean.log_proptx_mean,
    label = "renters",
    legend = :topleft,
    foreground_color_legend = nothing,
    yaxis="Log property tax",
    yformatter = yi -> string(round(Int, exp(yi)/1000)) * "K",
    xlim = (9,13),
    #ylim = (6,10),
    title = "Imputed ASEC property tax - " * state)

    return p1
end

function proptx_owners_renters_states!(df_owners_mean, df_renters_mean, outfile)
    state = unique(df_owners_mean.statename);
    for s in state
        proptx_owners_renters(df_owners_mean[df_owners_mean.statename .== s, :], df_renters_mean[df_renters_mean.statename .== s, :], s);
        savefig(outfile * s);
    end
end