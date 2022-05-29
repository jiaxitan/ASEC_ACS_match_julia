### Prepares for and plots engel curves

function inc_vingtiles!(df)

    insertcols!(df, 3, :grossinc_vingtile => zeros(Int64, size(df,1)));

    inc_cutoffs = Vector{Float64}(undef, 19);
    for (i_idx, i) in enumerate(collect(5:5:95))
        inc_cutoffs[i_idx] = percentile(df.grossinc, i)
    end

    for i = 1:size(df,1)
        y = df[i, :grossinc]

        if (y >= 0) && (y < inc_cutoffs[1])
            df[i, :grossinc_vingtile] = 1
        elseif (y >= inc_cutoffs[1]) && (y < inc_cutoffs[2])
            df[i, :grossinc_vingtile] = 2
        elseif (y >= inc_cutoffs[2]) && (y < inc_cutoffs[3])
            df[i, :grossinc_vingtile] = 3
        elseif (y >= inc_cutoffs[3]) && (y < inc_cutoffs[4])
            df[i, :grossinc_vingtile] = 4
        elseif (y >= inc_cutoffs[4]) && (y < inc_cutoffs[5])
            df[i, :grossinc_vingtile] = 5
        elseif (y >= inc_cutoffs[5]) && (y < inc_cutoffs[6])
            df[i, :grossinc_vingtile] = 6
        elseif (y >= inc_cutoffs[6]) && (y < inc_cutoffs[7])
            df[i, :grossinc_vingtile] = 7
        elseif (y >= inc_cutoffs[7]) && (y < inc_cutoffs[8])
            df[i, :grossinc_vingtile] = 8
        elseif (y >= inc_cutoffs[8]) && (y < inc_cutoffs[9])
            df[i, :grossinc_vingtile] = 9
        elseif (y >= inc_cutoffs[9]) && (y < inc_cutoffs[10])
            df[i, :grossinc_vingtile] = 10
        elseif (y >= inc_cutoffs[10]) && (y < inc_cutoffs[11])
            df[i, :grossinc_vingtile] = 11
        elseif (y >= inc_cutoffs[11]) && (y < inc_cutoffs[12])
            df[i, :grossinc_vingtile] = 12
        elseif (y >= inc_cutoffs[12]) && (y < inc_cutoffs[13])
            df[i, :grossinc_vingtile] = 13
        elseif (y >= inc_cutoffs[13]) && (y < inc_cutoffs[14])
            df[i, :grossinc_vingtile] = 14
        elseif (y >= inc_cutoffs[14]) && (y < inc_cutoffs[15])
            df[i, :grossinc_vingtile] = 15
        elseif (y >= inc_cutoffs[15]) && (y < inc_cutoffs[16])
            df[i, :grossinc_vingtile] = 16
        elseif (y >= inc_cutoffs[16]) && (y < inc_cutoffs[17])
            df[i, :grossinc_vingtile] = 17
        elseif (y >= inc_cutoffs[17]) && (y < inc_cutoffs[18])
            df[i, :grossinc_vingtile] = 18
        elseif (y >= inc_cutoffs[18]) && (y < inc_cutoffs[19])
            df[i, :grossinc_vingtile] = 19
        else
            df[i, :grossinc_vingtile] = 20
        end
    end
end

function inc_percentiles!(df)
    sort!(df, :grossinc);
    cutoff = (1:99) .* 0.01;
    p = quantile(df.grossinc, cutoff; sorted = true);
    insertcols!(df, ncol(df) + 1, :grossinc_percentile => searchsortedfirst.(Ref(p), df.grossinc));

end

# Median property tax of each income bin, percentiles
function engel_proptax_data_median(df, code)

    df_owners = filter(r -> (r[:ownershp] .== code), df);
    inc_percentiles!(df_owners);
    gdf_owners = groupby(df_owners, [:grossinc_percentile]);
    df_owners_median = combine(gdf_owners, :grossinc => median, :proptx99_recode => median => :proptx_median, nrow);
    # sort!(df_owners_median, :grossinc_percentile);
    df_owners_median[:, :log_grossinc_median] = log.(df_owners_median[:, :grossinc_median]);
    df_owners_median[:, :log_proptx_median]  = log.(df_owners_median[:, :proptx_median]);
    # ols_owners = lm(@formula(log_valueh_median ~ log_grossinc_median), df_owners_median)

    df_owners_median[:, :log_proptx_median_predict_beta1] = -3.3 .+ df_owners_median[:, :log_grossinc_median];
    
    return df_owners_median
end

# Mean property tax of each income bin, percentiles
function engel_proptax_data(df, code)

    df_owners = filter(r -> (r[:ownershp] .== code), df);
    inc_vingtiles!(df_owners);
    gdf_owners = groupby(df_owners, [:grossinc_vingtile]);
    df_owners_mean = combine(gdf_owners, :grossinc => mean, :proptx99_recode => mean => :proptx_mean, nrow);
    sort!(df_owners_mean, :grossinc_vingtile);
    df_owners_mean[:, :log_grossinc_mean] = log.(df_owners_mean[:, :grossinc_mean]);
    df_owners_mean[:, :log_proptx_mean]  = log.(df_owners_mean[:, :proptx_mean]);
    # ols_owners = lm(@formula(log_valueh_median ~ log_grossinc_median), df_owners_median)

    df_owners_mean[:, :log_proptx_mean_predict_beta1] = -3.3 .+ df_owners_mean[:, :log_grossinc_mean];
    
    return df_owners_mean
end

# Median home value of each income bin, vingtiles
function engel_owners_data_median(df, code)

    df_owners = filter(r -> (r[:ownershp] .== code), df);
    inc_vingtiles!(df_owners);
    gdf_owners = groupby(df_owners, [:grossinc_vingtile]);
    df_owners_median = combine(gdf_owners, :grossinc => median, :valueh => median, nrow);
    sort!(df_owners_median, :grossinc_vingtile);
    df_owners_median[:, :log_grossinc_median] = log.(df_owners_median[:, :grossinc_median]);
    df_owners_median[:, :log_valueh_median]  = log.(df_owners_median[:, :valueh_median]);
    # ols_owners = lm(@formula(log_valueh_median ~ log_grossinc_median), df_owners_median)

    df_owners_median[:, :log_valueh_median_predict_beta1] = 1.5 .+ df_owners_median[:, :log_grossinc_median];
    
    return df_owners_median
end

# Meah home value of each income bin, vingtiles
function engel_owners_data(df, code)

    df_owners = filter(r -> (r[:ownershp] .== code), df);
    inc_vingtiles!(df_owners);
    gdf_owners = groupby(df_owners, [:grossinc_vingtile]);
    df_owners_mean = combine(gdf_owners, :grossinc => mean, :valueh => mean, :proptx99_recode => mean => :proptx_mean, :txrate => mean, nrow);
    sort!(df_owners_mean, :grossinc_vingtile);
    df_owners_mean[:, :log_grossinc_mean] = log.(df_owners_mean[:, :grossinc_mean]);
    df_owners_mean[:, :log_proptx_mean]  = log.(df_owners_mean[:, :proptx_mean]);
    df_owners_mean[:, :log_valueh_mean]  = log.(df_owners_mean[:, :valueh_mean]);
    # ols_owners = lm(@formula(log_valueh_mean ~ log_grossinc_mean), df_owners_mean)

    df_owners_mean[:, :log_valueh_mean_predict_beta1] = 1.5 .+ df_owners_mean[:, :log_grossinc_mean];
    df_owners_mean[:, :log_proptx_mean_predict_beta1] = -3.3 .+ df_owners_mean[:, :log_grossinc_mean];

    return df_owners_mean
end

# Median home value of each income bin, percentiles
function engel_owners_data_percentiles_median(df, code)

    df_owners = filter(r -> (r[:ownershp] .== code), df);
    inc_percentiles!(df_owners);
    gdf_owners = groupby(df_owners, [:grossinc_percentile]);
    df_owners_median = combine(gdf_owners, :grossinc => median, :valueh => median, nrow);
    # sort!(df_owners_median, :grossinc_percentile);
    df_owners_median[:, :log_grossinc_median] = log.(df_owners_median[:, :grossinc_median]);
    df_owners_median[:, :log_valueh_median]  = log.(df_owners_median[:, :valueh_median]);
    # ols_owners = lm(@formula(log_valueh_median ~ log_grossinc_median), df_owners_median)

    df_owners_median[:, :log_valueh_median_predict_beta1] = 1.5 .+ df_owners_median[:, :log_grossinc_median];
    
    return df_owners_median
end

# Mean home value of each income bin, percentiles
function engel_owners_data_percentiles(df, code)

    df_owners = filter(r -> (r[:ownershp] .== code), df);
    inc_percentiles!(df_owners);
    gdf_owners = groupby(df_owners, [:grossinc_percentile]);
    df_owners_mean = combine(gdf_owners, :grossinc => mean, :valueh => mean, nrow);
    # sort!(df_owners_mean, :grossinc_percentile);
    df_owners_mean[:, :log_grossinc_mean] = log.(df_owners_mean[:, :grossinc_mean]);
    df_owners_mean[:, :log_valueh_mean]  = log.(df_owners_mean[:, :valueh_mean]);
    # ols_owners = lm(@formula(log_valueh_median ~ log_grossinc_median), df_owners_median)

    df_owners_mean[:, :log_valueh_mean_predict_beta1] = 1.5 .+ df_owners_mean[:, :log_grossinc_mean];
    
    return df_owners_mean
end

# Median gross rent of each income bin, vintiles
function engel_renters_data_median(df, code)

    df_renters = filter(r -> (r[:ownershp] .!= code), df);
    inc_vingtiles!(df_renters);
    gdf_renters = groupby(df_renters, [:grossinc_vingtile]);
    df_renters_median = combine(gdf_renters, :grossinc => median, :rentgrs => median, nrow);
    sort!(df_renters_median, :grossinc_vingtile);
    df_renters_median[:, :log_grossinc_median] = log.(df_renters_median[:, :grossinc_median]);
    df_renters_median[:, :log_rentgrs_median] = log.(df_renters_median[:, :rentgrs_median]);
    # ols_renters = lm(@formula(log_rentgrs_median ~ log_grossinc_median), df_renters_median)

    df_renters_median[:, :log_rentgrs_median_predict_beta1] =  -4 .+ df_renters_median[:, :log_grossinc_median];

    return df_renters_median
end

# Mean gross rent of each income bin, vintiles
function engel_renters_data(df, code)

    df_renters = filter(r -> (r[:ownershp] .!= code), df);
    inc_vingtiles!(df_renters);
    gdf_renters = groupby(df_renters, [:grossinc_vingtile]);
    df_renters_mean = combine(gdf_renters, :grossinc => mean, :rentgrs => mean, nrow);
    sort!(df_renters_mean, :grossinc_vingtile);
    df_renters_mean[:, :log_grossinc_mean] = log.(df_renters_mean[:, :grossinc_mean]);
    df_renters_mean[:, :log_rentgrs_mean] = log.(df_renters_mean[:, :rentgrs_mean]);
    # ols_renters = lm(@formula(log_rentgrs_mean ~ log_grossinc_mean), df_renters_mean)

    df_renters_mean[:, :log_rentgrs_mean_predict_beta1] =  -4 .+ df_renters_mean[:, :log_grossinc_mean];

    return df_renters_mean
end

# Median gross rent of each income bin, percentiles
function engel_renters_data_percentiles_median(df, code)

    df_renters = filter(r -> (r[:ownershp] .!= code), df);
    inc_percentiles!(df_renters);
    gdf_renters = groupby(df_renters, [:grossinc_percentile]);
    df_renters_median = combine(gdf_renters, :grossinc => median, :rentgrs => median, nrow);
    # sort!(df_renters_median, :grossinc_percentile);
    df_renters_median[:, :log_grossinc_median] = log.(df_renters_median[:, :grossinc_median]);
    df_renters_median[:, :log_rentgrs_median] = log.(df_renters_median[:, :rentgrs_median]);
    # ols_renters = lm(@formula(log_rentgrs_median ~ log_grossinc_median), df_renters_median)

    df_renters_median[:, :log_rentgrs_median_predict_beta1] =  -4 .+ df_renters_median[:, :log_grossinc_median];

    return df_renters_median
end

# Mean gross rent of each income bin, percentiles
function engel_renters_data_percentiles(df, code)

    df_renters = filter(r -> (r[:ownershp] .!= code), df);
    inc_percentiles!(df_renters);
    gdf_renters = groupby(df_renters, [:grossinc_percentile]);
    df_renters_mean = combine(gdf_renters, :grossinc => mean, :rentgrs => mean, nrow);
    # sort!(df_renters_median, :grossinc_percentile);
    df_renters_mean[:, :log_grossinc_mean] = log.(df_renters_mean[:, :grossinc_mean]);
    df_renters_mean[:, :log_rentgrs_mean] = log.(df_renters_mean[:, :rentgrs_mean]);
    # ols_renters = lm(@formula(log_rentgrs_median ~ log_grossinc_median), df_renters_median)

    df_renters_mean[:, :log_rentgrs_mean_predict_beta1] =  -4 .+ df_renters_mean[:, :log_grossinc_mean];

    return df_renters_mean
end

# Mean home value and property tax by state, vingtiles
function engel_owners_data_state(df, code)
    df_owners = filter(r -> (r[:ownershp] .== code), df);
    inc_vingtiles!(df_owners);
    gdf_owners = groupby(df_owners, [:statename, :grossinc_vingtile]);
    df_owners_mean = combine(gdf_owners, :grossinc => mean, :valueh => mean, :proptx99_recode => mean, :txrate => mean, nrow);
    sort!(df_owners_mean, [:statename, :grossinc_vingtile]);

    df_owners_mean[:, :log_grossinc_mean] = log.(df_owners_mean[:, :grossinc_mean]);
    df_owners_mean[:, :log_valueh_mean]  = log.(df_owners_mean[:, :valueh_mean]);
    df_owners_mean[:, :log_proptx_mean]  = log.(df_owners_mean[:, :proptx99_recode_mean]);

    return df_owners_mean
end

# Plot mean property tax of each income bin 
function proptx_plot(df_owners_mean, title)

    p11 = scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.log_proptx_mean,
    label = "Log Property Tax",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (6,10),
    aspect_ratio=:equal)
    plot!(df_owners_mean.log_grossinc_mean, df_owners_mean.log_proptx_mean_predict_beta1,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
    p11 = annotate!(12.0,9, Plots.text("Homothetic", 10, :dark, rotation = 45 ), title = title)
    
    return p11
end

# Plot mean property tax rate of each income bin
function txrate_plot(df_owners_mean, title)

    p11 = scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.txrate_mean.*100,
    label = "Property tax rate (%)",
    legend = :topright,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(round(Int, exp(xi)/1000)) * "K",
    xlim = (9,13),
    ylim = (0.5,1.5),
    title = title,
    aspect_ratio= 4)

    return p11
end

# Plot mean property tax with ACS and ASEC data 
function proptx_plot(df_owners_mean_ACS, df_owners_mean_ASEC, title)

    p11 = scatter(df_owners_mean_ACS.log_grossinc_mean, df_owners_mean_ACS.log_proptx_mean,
    label = "ACS",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    #ylim = (6,10),
    aspect_ratio=:equal)
    scatter!(df_owners_mean_ASEC.log_grossinc_mean, df_owners_mean_ASEC.log_proptx_mean,
    label = "ASEC",
    legend = :topleft,
    foreground_color_legend = nothing,
    yaxis="Log property tax",
    xlim = (9,13),
    #ylim = (6,10),
    aspect_ratio=:equal)
    plot!(df_owners_mean_ACS.log_grossinc_mean, df_owners_mean_ACS.log_grossinc_mean .- (df_owners_mean_ACS.log_grossinc_mean[10] - df_owners_mean_ACS.log_proptx_mean[10]),
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal,
    title = title)
    
    return p11
end

# Plot mean property tax with ACS and ASEC data for each state. Save plots in outfile.
function proptx_plot_compare!(df_owners_mean_ACS, df_owners_mean_ASEC, outfile)
    state = unique(df_owners_mean_ACS.statename);
    for s in state
        proptx_plot(df_owners_mean_ACS[df_owners_mean_ACS.statename .== s, :], df_owners_mean_ASEC[df_owners_mean_ASEC.statename .== s, :], "Property tax Engel, " * s);
        savefig(outfile * s);
    end
end

# Plot median property tax for each income bin
function proptx_plot_median(df_owners_median, title)

    scatter(df_owners_median.log_grossinc_median, df_owners_median.log_proptx_median,
    label = "Log Property Tax",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (6,10),
    aspect_ratio=:equal)
    plot!(df_owners_median.log_grossinc_median, df_owners_median.log_proptx_median_predict_beta1,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
    p11 = annotate!(12.0,9, Plots.text("Homothetic", 10, :dark, rotation = 45 ), title = title)
    
    return p11
end

# Plot mean home value and gross rent
function engel_plot(df_owners_mean, df_renters_mean, title)

    p11 = scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.log_valueh_mean,
    label = "Log Home Value",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (10.5,14.5),
    aspect_ratio=:equal)
    plot!(df_owners_mean.log_grossinc_mean, df_owners_mean.log_valueh_mean_predict_beta1,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
    p11 = annotate!(12.0,13.7, Plots.text("Homothetic", 10, :dark, rotation = 45 ))
    
    
    p22 = scatter(df_renters_mean.log_grossinc_mean, df_renters_mean.log_rentgrs_mean,
    label = "Log Rent",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (5,9),
    seriescolor = :orange,
    aspect_ratio=:equal)
    # plot!([9.3,12.1], [5.3,8.1], line=:black, linestyle=:dash, label = "", aspect_ratio=:equal)
    plot!(df_renters_mean.log_grossinc_mean, df_renters_mean.log_rentgrs_mean_predict_beta1,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
    p22 = annotate!(12.0, 8.2, Plots.text("Homothetic", 10, :dark, rotation = 45 ))
    
    # Comment areas saved for when we want one axis lable for both graphs
    # l = @layout [a{0.01h}; grid(1,2); a{0.01h}]
    # p = fill(plot(),4,1)
    l = @layout [a{0.01h}; grid(1,2)]
    p = fill(plot(),3,1)
    p[1] = plot(title=title, framestyle=nothing, showaxis=false, xticks=false, yticks=false, margin=0mm, bottom_margin = -20mm)
    p[2] = p11
    p[3] = p22
    # p[4] = plot(framestyle=nothing, showaxis=false, xticks=false, yticks=false, margin=0mm, top_margin = -25mm, xlabel = "Pre-governemnt income (thousands)", bottom_margin = 10mm)

    p1 = plot(p..., layout=l)

    return p1
end

# Plot median home value and property tax for each income bin
function engel_plot_median(df_owners_median, df_renters_median, title)

    scatter(df_owners_median.log_grossinc_median, df_owners_median.log_valueh_median,
    label = "Log Home Value",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (10.5,14.5),
    aspect_ratio=:equal)
    plot!(df_owners_median.log_grossinc_median, df_owners_median.log_valueh_median_predict_beta1,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
    p11 = annotate!(12.0,13.7, Plots.text("Homothetic", 10, :dark, rotation = 45 ))
    
    scatter(df_renters_median.log_grossinc_median, df_renters_median.log_rentgrs_median,
    label = "Log Rent",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (5,9),
    seriescolor = :orange,
    aspect_ratio=:equal)
    # plot!([9.3,12.1], [5.3,8.1], line=:black, linestyle=:dash, label = "", aspect_ratio=:equal)
    plot!(df_renters_median.log_grossinc_median, df_renters_median.log_rentgrs_median_predict_beta1,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
    p22 = annotate!(12.0, 8.2, Plots.text("Homothetic", 10, :dark, rotation = 45 ))
    
    l = @layout [a{0.01h}; grid(1,2)]
    p = fill(plot(),3,1)
    p[1] = plot(title=title, framestyle=nothing, showaxis=false, xticks=false, yticks=false, margin=0mm, bottom_margin = -20mm)
    p[2] = p11
    p[3] = p22
    p1 = plot(p..., layout=l)
    
    return p1
end

    