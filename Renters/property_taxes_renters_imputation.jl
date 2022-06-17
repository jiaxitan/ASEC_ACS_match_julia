
### Property Taxes for renters (based on GLVs procedure)

## Note: df_main_hh is the sample selected from ASEC

# 0. Run the matching file (match_ASEC_ACS_0506_1011_1516.jl) in folder 'Home owners' first
include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Home owners/match_ASEC_ACS_0506_1011_1516.jl");

## I: set input data
file_rent_paid = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/State_Zri_AllHomesPlusMultifamily_IMPORT.csv";
file_home_value = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/State_Zhvi_AllHomes_IMPORT.csv";

## II: Import and prepare property taxes for renters
df_rentgrs = CSV.read(file_rent_paid, DataFrame);
df_valueh = CSV.read(file_home_value, DataFrame);
df_annual_rentgrs_to_valueh = 12 .* df_rentgrs[:,2:end] ./ df_valueh[:,2:end];
insertcols!(df_annual_rentgrs_to_valueh, 1, :statename => df_rentgrs.Column1);
df_annual_rentgrs_to_valueh = DataFrames.stack(df_annual_rentgrs_to_valueh, Not(:statename));
rename!(df_annual_rentgrs_to_valueh, :variable => :YEAR, :value => :rentgrs_valueh_ratio);
df_annual_rentgrs_to_valueh.YEAR = convert.(Int64, parse.(Int64, df_annual_rentgrs_to_valueh.YEAR));

df_ASEC_owners = df_ASEC_hh_match_0506_final[df_ASEC_hh_match_0506_final.ownershp .== 10, :];
insertcols!(df_ASEC_owners, size(df_ASEC_owners, 2)+1, :txrate =>  df_ASEC_owners.ACS_proptax_mean ./ df_ASEC_owners.ACS_valueh_mean);
df_ASEC_owners[df_ASEC_owners.ACS_valueh_mean .== 0, :txrate] .= 0;

df_ASEC_renters = df_ASEC_hh_match_0506_final[df_ASEC_hh_match_0506_final.ownershp .!= 10, :];
df_ASEC_renters = leftjoin(df_ASEC_renters, df_annual_rentgrs_to_valueh, on = [:statename, :YEAR]);
insertcols!(df_ASEC_renters, :valueh_renters_mean => 12 .* df_ASEC_renters.ACS_rentgrs_mean ./ df_ASEC_renters.:rentgrs_valueh_ratio);

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/fit_proptxrate_income.jl");
fit_proptxrate_income!();

insertcols!(df_ASEC_renters, :proptx => df_ASEC_renters.txrate .* df_ASEC_renters.valueh_renters_mean);

insertcols!(df_ASEC_owners, :valueh => df_ASEC_owners.ACS_valueh_mean);
insertcols!(df_ASEC_owners, :proptx99_recode => df_ASEC_owners.ACS_proptax_mean);

insertcols!(df_ASEC_renters, :rentgrs => df_ASEC_renters.ACS_rentgrs_mean);
insertcols!(df_ASEC_renters, :proptx99_recode => df_ASEC_renters.proptx);

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Home owners/inc_valueh_rentgrs_regressivity.jl");

df_owners_mean = engel_owners_data(df_ASEC_owners, 10);
df_renters_mean = engel_renters_data(df_ASEC_renters, 10);

scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.log_proptx_mean,
    label = "Owners")
scatter!(df_renters_mean.log_grossinc_mean, df_renters_mean.log_proptx_mean,
    label = "Renters",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (6,10),
    aspect_ratio=:equal)
plot!(df_owners_mean.log_grossinc_mean, df_owners_mean.log_proptx_mean_predict_beta1,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
annotate!(12.0,9, Plots.text("Homothetic", 10, :dark, rotation = 45 ), title = "US Property Tax Engel Curves (ASEC, 2005/2006)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "National renters vs owners.pdf")


df_owners_mean = engel_owners_data_state(df_ASEC_owners, 10);
df_renters_mean = engel_renters_data_state(df_ASEC_renters, 10);

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/proptx_owners_renters.jl");
proptx_owners_renters_states!(df_owners_mean, df_renters_mean, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Property tax by state/")
# proptx_owners_renters_states!(df_owners_mean, df_renters_mean, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Property tax by state_avg rent to price/")

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/txrate_owners_renters.jl");
txrate_owners_renters_states!(df_owners_mean, df_renters_mean, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Property tax rate fitting/")

# Compare home charateristics of owners and renters
df_ACS_owners = df_ACS_hh[(in([2005,2006]).(df_ACS_hh.YEAR)) .&& (df_ACS_hh.ownershp .== 1), :];
df_ACS_renters = df_ACS_hh[(in([2005,2006]).(df_ACS_hh.YEAR)) .&& (df_ACS_hh.ownershp .!= 1), :];

df_owners_mean = engel_owners_homeCha(df_ACS_owners, 1);
df_renters_mean = engel_renters_homeCha(df_ACS_renters, 1);

df_owners_mean_state = engel_owners_homeCha_state(df_ACS_owners,1);
df_renters_mean_state = engel_renters_homeCha_state(df_ACS_renters,1);

scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.rooms_mean,
    label = "Owners")
scatter!(df_renters_mean.log_grossinc_mean, df_renters_mean.rooms_mean,
    label = "Renters",
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    #yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (3.5,8),
    aspect_ratio= 0.89,
    title = "Number of rooms by income (ACS, 2005/2006)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "Number of rooms.pdf")

scatter(df_owners_mean_state[df_owners_mean_state.statename .== "California", :].log_grossinc_mean, df_owners_mean_state[df_owners_mean_state.statename .== "California", :].rooms_mean,
    label = "Owners", color = "blue")
scatter!(df_renters_mean_state[df_renters_mean_state.statename .== "California", :].log_grossinc_mean, df_renters_mean_state[df_renters_mean_state.statename .== "California", :].rooms_mean,
    label = "Renters",
    legend = :topleft,
    color = :red,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    #yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (3.5,8),
    aspect_ratio= 0.89,
    title = "Number of rooms by income, CA (ACS, 2005/2006)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "Number of rooms CA.pdf")


scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.age_mean,
    label = "Owners")
scatter!(df_renters_mean.log_grossinc_mean, df_renters_mean.age_mean,
    label = "Renters",
    legend = :left,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    #yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (35,50),
    aspect_ratio=0.27,
    title = "Age of hh head by income (ACS, 2005/2006)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "Age of household head.pdf")

scatter(df_owners_mean_state[df_owners_mean_state.statename .== "California", :].log_grossinc_mean, df_owners_mean_state[df_owners_mean_state.statename .== "California", :].age_mean,
    label = "Owners", color = "blue")
scatter!(df_renters_mean_state[df_renters_mean_state.statename .== "California", :].log_grossinc_mean, df_renters_mean_state[df_renters_mean_state.statename .== "California", :].age_mean,
    label = "Renters",
    legend = :left,
    foreground_color_legend = nothing,
    color = "red",
    xaxis="Log pre-government income",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    #yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (35,50),
    aspect_ratio=0.27,
    title = "Age of hh head by income, CA (ACS, 2005/2006)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "Age of household head CA.pdf")


scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.movedin_mean,
    label = "Owners")
scatter!(df_renters_mean.log_grossinc_mean, df_renters_mean.movedin_mean,
    label = "Renters",
    legend = :left,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    #yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (2.5,4.5),
    aspect_ratio=2,
    title = "Years since moved in by income (ACS, 2005/2006)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "Years since moved in.pdf")

scatter(df_owners_mean_state[df_owners_mean_state.statename .== "California", :].log_grossinc_mean, df_owners_mean_state[df_owners_mean_state.statename .== "California", :].movedin_mean,
    label = "Owners", color = "blue")
scatter!(df_renters_mean_state[df_renters_mean_state.statename .== "California", :].log_grossinc_mean, df_renters_mean_state[df_renters_mean_state.statename .== "California", :].movedin_mean,
    label = "Renters",
    legend = :topleft,
    foreground_color_legend = nothing,
    color = "red",
    xaxis="Log pre-government income",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    #yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (2.5,4.5),
    aspect_ratio=2,
    title = "Years since moved in by income, CA (ACS, 2005/2006)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "Years since moved in CA.pdf")


scatter(df_owners_mean.log_grossinc_mean, df_owners_mean.single_fam./df_owners_mean.nrow *100,
    label = "Owners")
scatter!(df_renters_mean.log_grossinc_mean, df_renters_mean.single_fam./df_renters_mean.nrow *100,
    label = "Renters",
    legend = :left,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    #yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (30,100),
    aspect_ratio=0.06,
    title = "% of Single-family homes by income (ACS, 2005/2006)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "Share of single-family homes.pdf")

scatter(df_owners_mean_state[df_owners_mean_state.statename .== "California", :].log_grossinc_mean, df_owners_mean_state[df_owners_mean_state.statename .== "California", :].single_fam./df_owners_mean_state[df_owners_mean_state.statename .== "California", :].nrow *100,
    label = "Owners", color = :blue)
scatter!(df_renters_mean_state[df_renters_mean_state.statename .== "California", :].log_grossinc_mean, df_renters_mean_state[df_renters_mean_state.statename .== "California", :].single_fam./df_renters_mean_state[df_renters_mean_state.statename .== "California", :].nrow *100,
    label = "Renters",
    legend = :left,
    foreground_color_legend = nothing,
    color = :red,
    xaxis="Log pre-government income",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    #yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (30,100),
    aspect_ratio=0.06,
    title = "% of Single-family homes by income, CA (ACS, 2005/2006)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "Share of single-family homes CA.pdf")


scatter(df_ACS_owners.grossinc_log, df_ACS_owners.rooms, label="owners")
scatter!(df_ACS_renters.grossinc_log, df_ACS_renters.rooms, label="renters")
