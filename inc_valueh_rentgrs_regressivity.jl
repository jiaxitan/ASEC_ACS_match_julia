
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

function engel_owners_data(df, code)

    df_owners = filter(r -> (r[:ownershp] .== code), df);
    inc_vingtiles!(df_owners);
    gdf_owners = groupby(df_owners, [:grossinc_vingtile]);
    df_owners_mean = combine(gdf_owners, :grossinc => mean, :valueh => mean, nrow);
    sort!(df_owners_mean, :grossinc_vingtile);
    df_owners_mean[:, :log_grossinc_mean] = log.(df_owners_mean[:, :grossinc_mean]);
    df_owners_mean[:, :log_valueh_mean]  = log.(df_owners_mean[:, :valueh_mean]);
    # ols_owners = lm(@formula(log_valueh_mean ~ log_grossinc_mean), df_owners_mean)

    df_owners_mean[:, :log_valueh_mean_predict_beta1] = 1.5 .+ df_owners_mean[:, :log_grossinc_mean];
    
    return df_owners_mean
end

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

function engel_plot(df_owners_mean, df_renters_mean, title)

    scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.log_valueh_mean,
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
    
    scatter(df_renters_mean.log_grossinc_mean, df_renters_mean.log_rentgrs_mean,
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
    
    l = @layout [a{0.01h}; grid(1,2)]
    p = fill(plot(),3,1)
    p[1] = plot(title=title, framestyle=nothing, showaxis=false, xticks=false, yticks=false, margin=0mm, bottom_margin = -20mm)
    p[2] = p11
    p[3] = p22
    p1 = plot(p..., layout=l)
    #savefig( "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Engel_curves/" * filename)
    

    return p1
end