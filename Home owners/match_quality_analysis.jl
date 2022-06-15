### Compares 3 different matching sets, investigates match quality at national and state level with engel plots

# Include all functions needed for plotting engel curves. Set output directory.
include(dir_functions * "inc_valueh_rentgrs_regressivity.jl");
fig2_dir_out = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Engel_curves/";

## Plot with ACS data
insertcols!(df_ACS_hh, size(df_ACS_hh, 2)+1, :txrate => df_ACS_hh.proptx99_recode ./ df_ACS_hh.valueh);
df_ACS_hh[df_ACS_hh.valueh .== 0, :txrate] .= 0;

# Engel curves, percentiles, mean
df_owners_mean = engel_owners_data_percentiles(df_ACS_hh[in([2005, 2006]).(df_ACS_hh.YEAR), :], 1);
df_renters_mean = engel_renters_data_percentiles(df_ACS_hh[in([2005, 2006]).(df_ACS_hh.YEAR), :], 1);

p1_mean = engel_plot(df_owners_mean, df_renters_mean, "Housing Engel Curves (ACS, 2010/2011)")

# Engel curves, vingtiles, mean
df_owners_mean = engel_owners_data(df_ACS_hh[in([2005, 2006]).(df_ACS_hh.YEAR), :], 1);
df_renters_mean = engel_renters_data(df_ACS_hh[in([2005, 2006]).(df_ACS_hh.YEAR), :], 1);

p1_mean = engel_plot(df_owners_mean, df_renters_mean, "Housing Engel Curves (ACS, 2005/2006)")
savefig(fig2_dir_out * "levels home value ACS.pdf");

# Plot engel curves for property tax
p1_proptx_mean = proptx_plot(df_owners_mean, "Property Tax (ACS, 2005/2006)");
savefig(fig2_dir_out * "levels prop tax ACS.pdf");

# Plot engel curves for property tax rate
p1_txrate_mean = txrate_plot(df_owners_mean, "Property Tax Rate Engel Curves (ACS, 2005/2006)");
savefig(fig2_dir_out * "levels tax rate vs income ACS.pdf");
txrate_valueh_plot(df_owners_mean, "Property Tax Rate vs Home Value (ACS, 2005/2006)");
savefig(fig2_dir_out * "levels tax rate vs home value ACS.pdf");

scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.log_valueh_mean,
    label = "Log home value",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    seriescolor = :blue,
    xlim = (9,13),
    xformatter = xi -> string(round(Int, exp(xi)/1000)) * "K",
    yformatter = yi -> string(round(Int, exp(yi)/1000)) * "K",
    ylim = (10.5,14.5), aspect_ratio = :equal)
plot!(df_owners_mean.log_grossinc_mean, df_owners_mean.log_valueh_mean_predict_beta1,
    line=:black,
    linestyle=:dash,
    label = "")
annotate!(12.0,13.7, Plots.text("Homothetic", 10, :dark, rotation = 45 ), title = "Property Tax and Tax Rate Engels (ACS, 2005/2006)")
scatter(twinx(), df_owners_mean.log_grossinc_mean, df_owners_mean.txrate_mean.*100,
    label = "Property tax rate (%)",
    legend = (0.2,0.85),
    seriescolor = :red,
    foreground_color_legend = nothing,
    xticks = :none,
    ylim = (0.5,1.5),
    xlim = (9,13), 
    #left_margin = -2Plots.mm,
    aspect_ratio = 4)
savefig(fig2_dir_out * "tax rate and home value Engel ACS.pdf");

df_owners_mean_proptx = engel_proptax_data(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);
p1_proptx_mean = proptx_plot_median(df_owners_median_proptx, "Property Tax Engel Curves (ACS, 2010/2011)")

# Compare mean and median approach with ACS data
#=
scatter(df_owners_median.log_grossinc_median, df_owners_median.log_valueh_median,
    label = "home value median",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (10.5,14.5),
    aspect_ratio=:equal)
scatter!(df_owners_mean.log_grossinc_mean, df_owners_mean.log_valueh_mean,
    label = "home value mean (& matched mean)",
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
#title!("ASEC new benchmark 2010/2011 owners")
p1 = annotate!(12.0,13.7, Plots.text("Homothetic", 10, :dark, rotation = 45 ))

scatter(df_renters_median.log_grossinc_median, df_renters_median.log_rentgrs_median,
    label = "gross rent median",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (5,9),
    aspect_ratio=:equal)
scatter!(df_renters_mean.log_grossinc_mean, df_renters_mean.log_rentgrs_mean,
    label = "gross rent mean (& matched mean)",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (5,9),
    aspect_ratio=:equal)
plot!(df_renters_mean.log_grossinc_mean, df_renters_mean.log_rentgrs_mean_predict_beta1,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
#title!("ASEC new benchmark 2010/2011 renters")
p12 = annotate!(12.0, 8.2, Plots.text("Homothetic", 10, :dark, rotation = 45 ))
    
plot(p1, p12, layout = (1,2), size = (800,500))
title!("ASEC benchmark 10/11")
savefig(fig2_dir_out * "ASEC new benchmark 2010_11 mean_median comparison_matched mean.pdf");
=#


## 1st matching set
matching_set = [:grossinc, :size, :age, :unitsstr_recode, :race_recode, :educ_recode, :sex];

df_ASEC_hh_match_0506_final1 = ASEC_ACS_match([2010, 2011], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);

# Engel curves, percentiles, mean of nearest neighbors
insertcols!(df_ASEC_hh_match_0506_final1, size(df_ASEC_hh_match_0506_final1, 2)+1, :valueh => df_ASEC_hh_match_0506_final.ACS_valueh_mean);
insertcols!(df_ASEC_hh_match_0506_final1, size(df_ASEC_hh_match_0506_final1, 2)+1, :rentgrs => df_ASEC_hh_match_0506_final.ACS_rentgrs_mean);
insertcols!(df_ASEC_hh_match_0506_final1, size(df_ASEC_hh_match_0506_final1, 2)+1, :proptx99_recode => df_ASEC_hh_match_0506_final.ACS_proptax_mean);
df_owners_mean1 = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final1, 10);
df_renters_mean1 = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final1, 10);

p2_mean = engel_plot_median(df_owners_mean1, df_renters_mean1, "Housing Engel Curves (ASEC ALL, 2010/2011)");

# Engel curves, percentiles, median of nearest neighbors
df_ASEC_hh_match_0506_final1.valueh = df_ASEC_hh_match_0506_final1.ACS_valueh_median;
df_ASEC_hh_match_0506_final1.rentgrs = df_ASEC_hh_match_0506_final1.ACS_rentgrs_median;
df_owners_median1 = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final1, 10);
df_renters_median1 = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final1, 10);

p2_median = engel_plot_median(df_owners_median1, df_renters_median1, "Housing Engel Curves (ASEC ALL, 2010/2011)");

# Engel curves for property tax, median of nearest neigbors
# Note: whenever the engel data preparation function has _median, it's using the median of each income bin
df_owners_median_proptx1 = engel_proptax_data_median(df_ASEC_hh_match_0506_final1, 10);

p2_proptx = proptx_plot(df_owners_median_proptx1, "Property Tax Engel Curves (ASEC ALL, 2010/2011)")


## 2nd matching - no recodes
matching_set = [:grossinc, :educ_recode, :unitsstr_recode];

k_NN = 9;
df_ASEC_hh_match_0506_final2 = ASEC_ACS_match([2005, 2006], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);


# Engel curves, percentiles, mean of nearest neighbors 
insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :valueh => df_ASEC_hh_match_0506_final2.ACS_valueh_mean);
insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :rentgrs => df_ASEC_hh_match_0506_final2.ACS_rentgrs_mean);
insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :proptx99_recode => df_ASEC_hh_match_0506_final2.ACS_proptax_mean);
insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :txrate =>  df_ASEC_hh_match_0506_final2.proptx99_recode ./ df_ASEC_hh_match_0506_final2.valueh);
df_ASEC_hh_match_0506_final2[df_ASEC_hh_match_0506_final2.valueh .== 0, :txrate] .= 0;

df_owners_mean2 = engel_owners_data(df_ASEC_hh_match_0506_final2, 10);
df_renters_mean2 = engel_renters_data(df_ASEC_hh_match_0506_final2, 10);

p3_mean = engel_plot(df_owners_mean2, df_renters_mean2, "Housing Engel Curves (ASEC benchmark, 2010/2011)");

# Engel curves, percentiles, median of nearest neighbors
df_ASEC_hh_match_0506_final2.valueh = df_ASEC_hh_match_0506_final2.ACS_valueh_median;
df_ASEC_hh_match_0506_final2.rentgrs = df_ASEC_hh_match_0506_final2.ACS_rentgrs_median;
df_ASEC_hh_match_0506_final2.proptx99_recode = df_ASEC_hh_match_0506_final2.ACS_proptax_median;
df_ASEC_hh_match_0506_final2.txrate = df_ASEC_hh_match_0506_final2.proptx99_recode ./ df_ASEC_hh_match_0506_final2.valueh;
df_ASEC_hh_match_0506_final2[df_ASEC_hh_match_0506_final2.valueh .== 0, :txrate] .= 0;

df_owners_median2 = engel_owners_data_median(df_ASEC_hh_match_0506_final2, 10);
#df_renters_median2 = engel_renters_data_median(df_ASEC_hh_match_0506_final2, 10);

#df_owners_median2_k1 = engel_owners_data_median(df_ASEC_hh_match_0506_final2, 10);
df_renters_median2_k1 = engel_renters_data_median(df_ASEC_hh_match_0506_final2, 10);

p3_median = engel_plot(df_owners_median2, df_renters_median2, "Housing Engel Curves (ASEC benchmark, 2005/2006)");
savefig(fig2_dir_out * "levels home value ASEC k=9 median.pdf");

# Engel curves for property tax, median of nearest neigbors
proptx_plot(df_owners_median2, "Property Tax Engel Curves (ASEC, 2005/2006)")
savefig(fig2_dir_out * "levels prop tax ASEC k=9 median.pdf");

scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.log_proptx_mean,
    label = "ACS")
scatter!(df_owners_mean2.log_grossinc_mean, df_owners_mean2.log_proptx_mean,
    label = "k=9 mean",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (6,10),
    aspect_ratio=:equal)
scatter!(df_owners_median2_k1.log_grossinc_mean, df_owners_median2_k1.log_proptx_mean,
    label = "k=1")
plot!(df_owners_median2.log_grossinc_mean, df_owners_median2.log_proptx_mean_predict_beta1,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
annotate!(12.0,9, Plots.text("Homothetic", 10, :dark, rotation = 45 ), title = "Property Tax Engel Curves")
savefig(fig2_dir_out * "levels prop tax mean.pdf");

p1_txrate_mean = txrate_plot(df_owners_median2, "Property Tax Rate Engel Curves (ASEC, 2005/2006)")
savefig(fig2_dir_out * "levels tax rate vs income ASEC k=9 median.pdf");
txrate_valueh_plot(df_owners_median2, "Property Tax Rate vs Home Value(ASEC, 2005/2006)")
savefig(fig2_dir_out * "levels tax rate vs home value ASEC k=9 median.pdf");

# Compare mean and median approach on plotting using matched ASEC home value
#=
df_owners_median = engel_grossinc_data_median(df_ASEC_hh_match_0506_final2, 10);
df_owners_mean = engel_grossinc_data_mean(df_ASEC_hh_match_0506_final2, 10);


scatter(df_owners_median.log_x_valueh_median, df_owners_median.log_grossinc_median,
    label = "median",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log home value",
    ylim = (9,13),
    xlim = (10.5,14.5),
    aspect_ratio=:equal)
scatter!(df_owners_mean.log_x_valueh_mean, df_owners_mean.log_grossinc_mean,
    label = "mean",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log home value",
    ylim = (9,13),
    xlim = (10.5,14.5),
    aspect_ratio=:equal)

=#

## 3rd matching - permanent income
matching_set = [:grossinc_potential];

df_ASEC_hh_match_0506_final3 = ASEC_ACS_match([2010, 2011], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);

# Engel curves, percentiles, mean of nearest neighbors
insertcols!(df_ASEC_hh_match_0506_final3, size(df_ASEC_hh_match_0506_final3, 2)+1, :valueh => df_ASEC_hh_match_0506_final3.ACS_valueh_mean);
insertcols!(df_ASEC_hh_match_0506_final3, size(df_ASEC_hh_match_0506_final3, 2)+1, :rentgrs => df_ASEC_hh_match_0506_final3.ACS_rentgrs_mean);
insertcols!(df_ASEC_hh_match_0506_final3, size(df_ASEC_hh_match_0506_final3, 2)+1, :proptx99_recode => df_ASEC_hh_match_0506_final3.ACS_proptax_median);

df_owners_mean3 = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final3, 10);
df_renters_mean3 = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final3, 10);

p4_mean = engel_plot_median(df_owners_mean3, df_renters_mean3, "Housing Engel Curves (ASEC perm. INC, 2010/2011)");

# Engel curves, percentiles, median of nearest neighbors
df_ASEC_hh_match_0506_final3.valueh = df_ASEC_hh_match_0506_final3.ACS_valueh_median;
df_ASEC_hh_match_0506_final3.rentgrs = df_ASEC_hh_match_0506_final3.ACS_rentgrs_median;
df_owners_median3 = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final3, 10);
df_renters_median3 = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final3, 10);

p4_median = engel_plot_median(df_owners_median3, df_renters_median3, "Housing Engel Curves (ASEC perm. INC, 2010/2011)");

# Engel curves for property tax, median of nearest neigbors
df_owners_median_proptx3 = engel_proptax_data_median(df_ASEC_hh_match_0506_final3, 10);

p4_proptx = proptx_plot(df_owners_median_proptx3, "Property Tax Engel Curves (ASEC only INC, 2010/2011)")

## Combine plots
plot(p1_mean, p2_mean, p3_mean, p4_mean, layout = (2,2), size = (1200,800))
savefig(fig2_dir_out * "Weighted_Mean_Engel_curve_ACS_new_benchmark_median_1011.pdf");

## Compare property tax of ACS and ASEC by state
df_owners_mean_ACS = engel_owners_data_state(df_ACS_hh[in([2005, 2006]).(df_ACS_hh.YEAR), :], 1);
df_owners_mean_ASEC = engel_owners_data_state(df_ASEC_hh_match_0506_final2, 10);

proptx_plot_compare!(df_owners_mean_ACS, df_owners_mean_ASEC, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/state engel k=9/");

## LA vs NJ, property tax Engel
s1 = "California"
s2 = "Texas"

proptx_plot_state(df_owners_mean_ACS, s1, s2, "CA vs. TX (ACS, 2005/2006)")
savefig(fig2_dir_out * "ca vs tx ACS.pdf");

s1 = "New York"
s2 = "Florida"
proptx_plot_state(df_owners_mean_ACS, s1, s2, "NY vs. FL (ACS, 2005/2006)")
savefig(fig2_dir_out * "ny vs fl ACS.pdf");


p_ACS = scatter(df_owners_mean_ACS[df_owners_mean_ACS.statename .== s1, :log_grossinc_mean], df_owners_mean_ACS[df_owners_mean_ACS.statename .== s1, :log_proptx_mean],
    label = s1,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(round(Int, exp(xi)/1000)) * "K",
    yformatter = yi -> string(round(Int, exp(yi)/1000)) * "K",
    xlim = (9,13))
scatter!(df_owners_mean_ACS[df_owners_mean_ACS.statename .== s2, :log_grossinc_mean], df_owners_mean_ACS[df_owners_mean_ACS.statename .== s2, :log_proptx_mean],
    label = s2,
    legend = :topleft,
    foreground_color_legend = nothing,
    yaxis="Property tax rate (%)",
    xlim = (9,13),
    #ylim = (0, 5),
    title = "CA vs. TX ACS")
plot!(df_owners_mean_ACS.log_grossinc_mean, df_owners_mean_ACS.log_grossinc_mean .- 3.0,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal,
    title = "CA vs. TX ACS")
annotate!(12.0,9.5, Plots.text("Homothetic", 10, :dark, rotation = 45))


p_ASEC = scatter(df_owners_mean_ASEC[df_owners_mean_ASEC.statename .== s1, :log_grossinc_mean], df_owners_mean_ASEC[df_owners_mean_ASEC.statename .== s1, :log_proptx_mean] .* 100,
    label = s1,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (0, 5))
scatter!(df_owners_mean_ASEC[df_owners_mean_ASEC.statename .== s2, :log_grossinc_mean], df_owners_mean_ASEC[df_owners_mean_ASEC.statename .== s2, :log_proptx_mean] .* 100,
    label = s2,
    legend = :topleft,
    foreground_color_legend = nothing,
    yaxis="Property tax rate (%)",
    xlim = (9,13),
    ylim = (0, 5),
    title = "CA vs. TX ASEC")
plot!(df_owners_mean_ASEC.log_grossinc_mean, df_owners_mean_ASEC.log_grossinc_mean .- 3.0,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal,
    title = "CA vs. TX ASEC")


plot(p_ACS, p_ASEC, layout = (1,2))
savefig(fig2_dir_out * "nj la.pdf");

## LA vs NJ, property tax rate

# Compute property tax rate for each household
df_owners_mean_ACS = engel_owners_data_state(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);
df_owners_mean_ASEC = engel_owners_data_state(df_ASEC_hh_match_0506_final2, 10);

scatter(df_owners_mean_ACS[:, :log_grossinc_mean], df_owners_mean_ACS[df_owners_mean_ACS.statename .== s1, :txrate_mean] .* 100,
    label = s1,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (0, 5))
scatter!(df_owners_mean_ACS[df_owners_mean_ACS.statename .== s2, :log_grossinc_mean], df_owners_mean_ACS[df_owners_mean_ACS.statename .== s2, :txrate_mean] .* 100,
    label = s2,
    legend = :topleft,
    foreground_color_legend = nothing,
    yaxis="Property tax rate (%)",
    xlim = (9,13),
    ylim = (0, 5),
    title = "NJ vs. LA ACS")
plot!(df_owners_mean_ACS.log_grossinc_mean, df_owners_mean_ACS.log_grossinc_mean .- 3.0,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal,
    title = "NJ vs. LA ACS") 


p_ACS = scatter(df_owners_mean_ACS[df_owners_mean_ACS.statename .== s1, :log_grossinc_mean], df_owners_mean_ACS[df_owners_mean_ACS.statename .== s1, :txrate_mean] .* 100,
    label = s1,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (0, 5))
scatter!(df_owners_mean_ACS[df_owners_mean_ACS.statename .== s2, :log_grossinc_mean], df_owners_mean_ACS[df_owners_mean_ACS.statename .== s2, :txrate_mean] .* 100,
    label = s2,
    legend = :topleft,
    foreground_color_legend = nothing,
    yaxis="Property tax rate (%)",
    xlim = (9,13),
    ylim = (0, 5),
    title = "NJ vs. LA ACS")
plot!(df_owners_mean_ACS.log_grossinc_mean, df_owners_mean_ACS.log_grossinc_mean .- 3.0,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal,
    title = "NJ vs. LA ACS") 

p_ASEC = scatter(df_owners_mean_ASEC[df_owners_mean_ASEC.statename .== s1, :log_grossinc_mean], df_owners_mean_ASEC[df_owners_mean_ASEC.statename .== s1, :txrate_mean] .* 100,
    label = s1,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (0, 5))
scatter!(df_owners_mean_ASEC[df_owners_mean_ASEC.statename .== s2, :log_grossinc_mean], df_owners_mean_ASEC[df_owners_mean_ASEC.statename .== s2, :txrate_mean] .* 100,
    label = s2,
    legend = :topleft,
    foreground_color_legend = nothing,
    yaxis="Property tax rate (%)",
    xlim = (9,13),
    ylim = (0, 5),
    title = "NJ vs. LA ASEC")
plot!(df_owners_mean_ASEC.log_grossinc_mean, df_owners_mean_ASEC.log_grossinc_mean .- 3.0,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal,
    title = "NJ vs. LA ASEC")


plot(p_ACS, p_ASEC, layout = (1,2))
savefig(fig2_dir_out * "nj la tax rate.pdf");