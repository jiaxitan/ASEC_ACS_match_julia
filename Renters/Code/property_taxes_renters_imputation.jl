
### Property Taxes for renters (based on GLVs procedure)

## Note: df_main_hh is the sample selected from ASEC
include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Home owners/match_ASEC_ACS_0506_1011_1516.jl");
df_ASEC_owners = df_ASEC_hh_match_0506_final[df_ASEC_hh_match_0506_final.ownershp .== 10, :];
df_ASEC_renters = df_ASEC_hh_match_0506_final[df_ASEC_hh_match_0506_final.ownershp .!= 10, :];

select!(df_ASEC_owners, Not(:valueh))
select!(df_ASEC_owners, Not(:proptx99_recode))
insertcols!(df_ASEC_owners, :valueh => df_ASEC_owners.ACS_valueh_mean);
insertcols!(df_ASEC_owners, :proptx99_recode => df_ASEC_owners.ACS_proptax_mean);
insertcols!(df_ASEC_renters, :valueh => df_ASEC_renters.ACS_valueh_mean);
insertcols!(df_ASEC_renters, :rentgrs => df_ASEC_renters.ACS_rentgrs_mean);
insertcols!(df_ASEC_renters, :proptx99_recode => df_ASEC_renters.ACS_proptax_mean);
df_ASEC_owners.txrate = df_ASEC_owners.proptx99_recode ./ df_ASEC_owners.valueh;
df_ASEC_renters.txrate = df_ASEC_renters.proptx99_recode ./ df_ASEC_renters.valueh;


include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Home owners/inc_valueh_rentgrs_regressivity.jl");
## National plots - ASEC
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

## Plot by states - ASEC
df_owners_mean = engel_owners_data_state(df_ASEC_owners, 10);
df_renters_mean = engel_renters_data_state(df_ASEC_renters, 10);

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Code/proptx_owners_renters.jl");
proptx_owners_renters_states!(df_owners_mean, df_renters_mean, "ASEC Property Tax - ", "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Property tax by state/")
# proptx_owners_renters_states!(df_owners_mean, df_renters_mean, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Property tax by state_avg rent to price/")

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Code/txrate_owners_renters.jl");
txrate_owners_renters_states!(df_owners_mean, df_renters_mean, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/State-level fitting/")

# Compare home charateristics of owners and renters\
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

## Same exericise for ACS renters
df_ACS_owners = df_ACS_hh[(in([2005, 2006]).(df_ACS_hh.YEAR)) .&& (df_ACS_hh.ownershp .== 1), :];
insertcols!(df_ACS_owners, size(df_ACS_owners, 2)+1, :txrate => df_ACS_owners.proptx99_recode ./ df_ACS_owners.valueh);
df_ACS_owners[df_ACS_owners.valueh .== 0, :txrate] .= 0;

df_ACS_renters = df_ACS_hh[(in([2005, 2006]).(df_ACS_hh.YEAR)) .&& (df_ACS_hh.ownershp .!= 1), :];
df_ACS_renters = leftjoin(df_ACS_renters, df_annual_rentgrs_to_valueh, on = [:statename, :YEAR]);
insertcols!(df_ACS_renters, :valueh_renters_mean => 12 .* df_ACS_renters.rentgrs ./ df_ACS_renters.rentgrs_valueh_ratio);

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/fit_proptxrate_income.jl");
fit_proptxrate_income_ACS!();

df_ACS_renters.proptx99_recode = df_ACS_renters.txrate .* df_ACS_renters.valueh_renters_mean;

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Home owners/inc_valueh_rentgrs_regressivity.jl");
df_ACS_renters.valueh = 12 .* df_ACS_renters.rentgrs ./ df_ACS_renters.rentgrs_valueh_ratio;
df_owners_mean = engel_owners_data_state(df_ACS_owners, 1);
df_renters_mean = engel_renters_data_state(df_ACS_renters, 1);

scatter(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "New York"], df_owners_mean.log_valueh_mean[df_owners_mean.statename .== "New York"],
    label = "owners",
    markershape = :rect,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    yaxis = "Log home value",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (10.5,14.5),
    aspect_ratio=:equal)
scatter!(df_renters_mean.log_grossinc_mean[df_renters_mean.statename .== "New York"], df_renters_mean.log_valueh_mean[df_renters_mean.statename .== "New York"],
    label = "renters - imputed", markershape = :diamond, title = "Home value, New York")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "NY home value.pdf")

scatter(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "California"], df_owners_mean.txrate_mean[df_owners_mean.statename .== "California"] .* 100,
    label = "owners",
    markershape = :rect,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    yaxis = "Property tax rate (%)",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (0.5,2.5),
    aspect_ratio=2)
scatter!(df_renters_mean.log_grossinc_mean[df_renters_mean.statename .== "California"], df_renters_mean.txrate_mean[df_renters_mean.statename .== "California"] .* 100,
    label = "renters - imputed", markershape = :diamond, title = "Property tax rate, New York")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "NY property tax rate.pdf")

scatter(df_renters_mean.log_grossinc_mean[df_renters_mean.statename .== "California"], df_renters_mean.txrate_mean[df_renters_mean.statename .== "California"] .* 100,
    label = "CA",
    markershape = :rect,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    yaxis = "Property tax rate (%)",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (0.5,2.5),
    aspect_ratio=2)
scatter!(df_renters_mean.log_grossinc_mean[df_renters_mean.statename .== "Texas"], df_renters_mean.txrate_mean[df_renters_mean.statename .== "Texas"] .* 100,
    label = "TX", markershape = :diamond)
scatter!(df_renters_mean.log_grossinc_mean[df_renters_mean.statename .== "New York"], df_renters_mean.txrate_mean[df_renters_mean.statename .== "New York"] .* 100,
    label = "NY", markershape = :xcross)
scatter!(df_renters_mean.log_grossinc_mean[df_renters_mean.statename .== "Florida"], df_renters_mean.txrate_mean[df_renters_mean.statename .== "Florida"].* 100,
    label = "FL", markershape = :star5)
annotate!(title = "Renters' Proptery Tax Rate (ACS, 2005/06)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/" * "4 states imputed property tax rate_renters.pdf")


include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Code/proptx_owners_renters.jl");
proptx_owners_renters_states!(df_owners_mean, df_renters_mean, "ACS Property Tax - ", "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Property tax by state ACS/")
# proptx_owners_renters_states!(df_owners_mean, df_renters_mean, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Property tax by state_avg rent to price/")

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Code/txrate_owners_renters.jl");
txrate_owners_renters_states!(df_owners_mean, df_renters_mean, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Property tax rate fitting ACS/")

p1 = scatter(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "California"], df_owners_mean.log_proptx_mean[df_owners_mean.statename .== "California"],
    label = "CA",
    markershape = :rect,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    yaxis = "Log property tax",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (6,10),
    aspect_ratio=:equal)
scatter!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "Texas"], df_owners_mean.log_proptx_mean[df_owners_mean.statename .== "Texas"],
    label = "TX", markershape = :diamond)
scatter!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "New York"], df_owners_mean.log_proptx_mean[df_owners_mean.statename .== "New York"],
    label = "NY", markershape = :xcross)
scatter!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "Florida"], df_owners_mean.log_proptx_mean[df_owners_mean.statename .== "Florida"],
    label = "FL", markershape = :star5)
plot!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "California"], df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "California"] .- 3,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
annotate!(12.0,9.2, Plots.text("Homothetic", 10, :dark, rotation = 45 ), title = "Owners' Property Tax (ACS, 2005/06)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Engel_curves/" * "4 states property tax.pdf")


p2 = scatter(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "California"], df_owners_mean.log_valueh_mean[df_owners_mean.statename .== "California"],
    label = "CA",
    markershape = :rect,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    yaxis = "Log home value",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (10.5,14.5),
    aspect_ratio=:equal)
scatter!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "Texas"], df_owners_mean.log_valueh_mean[df_owners_mean.statename .== "Texas"],
    label = "TX", markershape = :diamond)
scatter!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "New York"], df_owners_mean.log_valueh_mean[df_owners_mean.statename .== "New York"],
    label = "NY", markershape = :xcross)
scatter!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "Florida"], df_owners_mean.log_valueh_mean[df_owners_mean.statename .== "Florida"],
    label = "FL", markershape = :star5)
plot!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "California"], df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "California"] .+ 1.5,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
annotate!(12.3,14.0, Plots.text("Homothetic", 10, :dark, rotation = 45 ), title = "Owners' Home Value (ACS, 2005/06)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Engel_curves/" * "4 states home value.pdf")

p3 = scatter(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "California"], df_owners_mean.txrate_mean[df_owners_mean.statename .== "California"] .* 100,
    label = "CA",
    markershape = :rect,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    yaxis = "Property tax rate (%)",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (0.5,2.5),
    aspect_ratio=2)
scatter!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "Texas"], df_owners_mean.txrate_mean[df_owners_mean.statename .== "Texas"] .* 100,
    label = "TX", markershape = :diamond)
scatter!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "New York"], df_owners_mean.txrate_mean[df_owners_mean.statename .== "New York"] .* 100,
    label = "NY", markershape = :xcross)
scatter!(df_owners_mean.log_grossinc_mean[df_owners_mean.statename .== "Florida"], df_owners_mean.txrate_mean[df_owners_mean.statename .== "Florida"].* 100,
    label = "FL", markershape = :star5)
annotate!(title = "Owners' Proptery Tax Rate (ACS, 2005/06)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Engel_curves/" * "4 states property tax rate.pdf")

## Combine owners and renters
df_mean = engel_data_state(vcat(df_ACS_owners[:, [:grossinc, :statename, :proptx99_recode, :txrate]], df_ACS_renters[:, [:grossinc, :statename, :proptx99_recode, :txrate]]));

scatter(df_mean.log_grossinc_mean[df_mean.statename .== "California"], df_mean.log_proptx_mean[df_mean.statename .== "California"],
    label = "CA",
    markershape = :rect,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    yaxis = "Log property tax",
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (6,10),
    aspect_ratio=:equal)
scatter!(df_mean.log_grossinc_mean[df_mean.statename .== "Texas"], df_mean.log_proptx_mean[df_mean.statename .== "Texas"],
    label = "TX", markershape = :diamond)
scatter!(df_mean.log_grossinc_mean[df_mean.statename .== "New York"], df_mean.log_proptx_mean[df_mean.statename .== "New York"],
    label = "NY", markershape = :xcross)
scatter!(df_mean.log_grossinc_mean[df_mean.statename .== "Florida"], df_mean.log_proptx_mean[df_mean.statename .== "Florida"],
    label = "FL", markershape = :star5)
plot!(df_mean.log_grossinc_mean[df_mean.statename .== "California"], df_mean.log_grossinc_mean[df_mean.statename .== "California"] .- 3,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
annotate!(12.0,9.2, Plots.text("Homothetic", 10, :dark, rotation = 45 ), title = "Property Tax, Both (ACS, 2005/06)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Owners and renters/" * "4 states property tax, owners and renters.pdf")


df_mean = engel_data(vcat(df_ACS_owners[:, [:grossinc, :statename, :proptx99_recode, :txrate]], df_ACS_renters[:, [:grossinc, :statename, :proptx99_recode, :txrate]]));
scatter(df_mean.log_grossinc_mean, df_mean.log_proptx_mean,
    legend = false,
    xaxis="Log pre-government income",
    yaxis = "Log property tax", 
    xformatter = xi -> string(floor(Int, exp(xi)/1000)) * "." * string(round(Int, (exp(xi) - floor(Int, exp(xi)/1000)*1000)/10)) * "K",
    yformatter = yi -> string(floor(Int, exp(yi)/1000)) * "." * string(round(Int, (exp(yi) - floor(Int, exp(yi)/1000)*1000)/10)) * "K",
    xlim = (9,13),
    ylim = (6,10),
    aspect_ratio=:equal)
plot!(df_mean.log_grossinc_mean, df_mean.log_grossinc_mean .- 3.3,
    line=:black,
    linestyle=:dash,
    label = "",
    aspect_ratio=:equal)
annotate!(12.0,9, Plots.text("Homothetic", 10, :dark, rotation = 45 ), title = "US Property Tax, Both (ACS, 2005/06)")
savefig("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Owners and renters/" * "National property tax, owners and renters.pdf")
