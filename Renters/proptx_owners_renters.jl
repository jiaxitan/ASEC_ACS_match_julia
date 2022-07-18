### This file plots imputed property taxes for owners and renters by each state

function proptx_owners_renters!(df_owners_mean, df_renters_mean, state, title, outfile)
    scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.log_proptx_mean,
        label = "owners",
        legend = :topleft,
        foreground_color_legend = nothing,
        xaxis="Log pre-government income",
        xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
        xlim = (9,13))
    scatter!(df_renters_mean.log_grossinc_mean, df_renters_mean.log_proptx_mean,
        label = "renters",
        yaxis="Log property tax",
        yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
        ylim = (6,10),
        title = title * state * " 2005/06")
    plot!(df_owners_mean.log_grossinc_mean, df_owners_mean.log_grossinc_mean .- 3,
        line=:black,
        linestyle=:dash,
        label = "",
        aspect_ratio=:equal)
    annotate!(12.0,9.2, Plots.text("Homothetic", 10, :dark, rotation = 45 ))

    savefig(outfile * state);
end

function proptx_owners_renters_states!(df_owners_mean, df_renters_mean, title, outfile)
    state = unique(df_owners_mean.statename);
    for s in state
        proptx_owners_renters!(df_owners_mean[df_owners_mean.statename .== s, :], df_renters_mean[df_renters_mean.statename .== s, :], s, title, outfile);
    end
end