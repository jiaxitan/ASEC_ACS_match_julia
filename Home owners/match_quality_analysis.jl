### Compares 3 different matching sets, investigates match quality at national and state level with engel plots

# Include all functions needed for plotting engel curves. Set output directory.
include(dir_functions * "inc_valueh_rentgrs_regressivity.jl");
fig2_dir_out = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Engel_curves/";

## Plot with ACS data
insertcols!(df_ACS_hh, size(df_ACS_hh, 2)+1, :txrate => df_ACS_hh.proptx99_recode ./ df_ACS_hh.valueh);
df_ACS_hh[df_ACS_hh.valueh .== 0, :txrate] .= 0;

# Engel curves, percentiles, mean
df_owners_mean = engel_owners_data_percentiles(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);
df_renters_mean = engel_renters_data_percentiles(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);

p1_mean = engel_plot(df_owners_mean, df_renters_mean, "Housing Engel Curves (ACS, 2010/2011)")

# Engel curves, vingtiles, mean
df_owners_mean = engel_owners_data(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);
df_renters_mean = engel_renters_data(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);

p1_mean = engel_plot(df_owners_mean, df_renters_mean, "Housing Engel Curves (ACS, 2010/2011)")
savefig(fig2_dir_out * "levels home value ACS.pdf");

# Plot engel curves for property tax
p1_proptx_mean = proptx_plot(df_owners_mean, "Property Tax Engel Curves (ACS, 2010/2011)")
savefig(fig2_dir_out * "levels prop tax ACS.pdf");

# Plot engel curves for property tax rate
p1_txrate_mean = txrate_plot(df_owners_mean, "Property Tax Rate Engel Curves (ACS, 2010/2011)")


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

df_ASEC_hh_match_0506_final2 = ASEC_ACS_match([2010, 2011], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);

# Engel curves, percentiles, mean of nearest neighbors 
insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :valueh => df_ASEC_hh_match_0506_final2.ACS_valueh_mean);
insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :rentgrs => df_ASEC_hh_match_0506_final2.ACS_rentgrs_mean);
insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :proptx99_recode => df_ASEC_hh_match_0506_final2.ACS_proptax_mean);
df_owners_mean2 = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final2, 10);
df_renters_mean2 = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final2, 10);

p3_mean = engel_plot(df_owners_mean2, df_renters_mean2, "Housing Engel Curves (ASEC benchmark, 2010/2011)");

# Engel curves, percentiles, median of nearest neighbors
df_ASEC_hh_match_0506_final2.valueh = df_ASEC_hh_match_0506_final2.ACS_valueh_median;
df_ASEC_hh_match_0506_final2.rentgrs = df_ASEC_hh_match_0506_final2.ACS_rentgrs_median;
df_owners_median2 = engel_owners_data_percentiles_median(df_ASEC_hh_match_0506_final2, 10);
df_renters_median2 = engel_renters_data_percentiles_median(df_ASEC_hh_match_0506_final2, 10);

p3_median = engel_plot_median(df_owners_median2, df_renters_median2, "Housing Engel Curves (ASEC benchmark, 2010/2011)");

# Engel curves for property tax, mean of nearest neigbors
df_owners_mean_proptx2 = engel_proptax_data(df_ASEC_hh_match_0506_final2, 10);

# Plot ACS and ASEC property tax together
proptx_plot(df_owners_mean_proptx, df_owners_mean_proptx2, "Propty tax Engel, National")
savefig(fig2_dir_out * "Property_Tax_k9.pdf");

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
df_owners_mean_ACS = engel_owners_data_state(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);
df_owners_mean_ASEC = engel_owners_data_state(df_ASEC_hh_match_0506_final2, 10);

proptx_plot_compare!(df_owners_mean_ACS, df_owners_mean_ASEC, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/state engel k=9/");

## LA vs NJ, property tax Engel
s1 = "New Jersey"
s2 = "Louisiana"

p_ACS = scatter(df_owners_mean_ACS[df_owners_mean_ACS.statename .== s1, :log_grossinc_mean], df_owners_mean_ACS[df_owners_mean_ACS.statename .== s1, :log_proptx_mean] .* 100,
    label = s1,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xlim = (9,13),
    ylim = (0, 5))
scatter!(df_owners_mean_ACS[df_owners_mean_ACS.statename .== s2, :log_grossinc_mean], df_owners_mean_ACS[df_owners_mean_ACS.statename .== s2, :log_proptx_mean] .* 100,
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
    title = "NJ vs. LA ASEC")
plot!(df_owners_mean_ASEC.log_grossinc_mean, df_owners_mean_ASEC.log_grossinc_mean .- 3.0,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal,
    title = "NJ vs. LA ASEC")


plot(p_ACS, p_ASEC, layout = (1,2))
savefig(fig2_dir_out * "nj la.pdf");

## LA vs NJ, property tax rate

# Compute property tax rate for each household
insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :txrate =>  df_ASEC_hh_match_0506_final2.proptx99_recode ./ df_ASEC_hh_match_0506_final2.valueh);
df_ASEC_hh_match_0506_final2[df_ASEC_hh_match_0506_final2.valueh .== 0, :txrate] .= 0;

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