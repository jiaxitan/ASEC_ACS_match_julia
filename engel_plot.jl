
### Generate Engel curves of home values and rents using ACS data


## Housekeeping

using CSV, DataFrames, StatsBase, Statistics
using Plots, Plots.PlotMeasures, StatsPlots; gr()
using GLM, PrettyTables, FixedEffectModels, RegressionTables
using TableView

dir_out = "/Users/main/Documents/Dropbox/Research/Tax_prog_fed_state_local/property_tax_regressivity_ACS/";

# Import state info
file_state_info = "/Users/main/OneDrive - Istituto Universitario Europeo/data/US_state_info/states_fips_names.csv";
df_state_info = CSV.read(file_state_info, DataFrame; types=[Int64, Int64, String, String, String, Int64, Int64]);

include("/Users/main/Documents/GitHubRepos/julia_utils/inc_vingtile.jl")


## Import and clean ACS data

file_ACS = "/Users/main/OneDrive - Istituto Universitario Europeo/data/ACS_property_taxes/usa_00042.csv"; # 2005 + 2006
df_ACS_in = CSV.read(file_ACS, DataFrame);
#select!(df_ACS, Not([:CBSERIAL, :CLUSTER, :STRATA, :PERWT, :SAMPLE, :RELATED]));

# Select the FHSV sample
include("/Users/main/Documents/GitHubRepos/julia_utils/ACS_ASEC_selection_sampleB.jl")
df_ACS_sample = ACS_ASEC_selection_sampleB(df_ACS_in);

rename!(df_ACS_sample, :STATEFIP => :STATEFIPS);
df_ACS = innerjoin(df_ACS_sample, df_state_info, on = :STATEFIPS);

include("/Users/main/Documents/GitHubRepos/julia_utils/ACS_PROPTX99_recode.jl")
ACS_PROPTX99_recode!(df_ACS);

gdf_ACS = groupby(df_ACS, [:SERIAL, :YEAR]);
df_ACS_hh = combine(gdf_ACS, :VALUEH => unique => :valueh, :RENT => unique => :rent, :RENTGRS => unique => :rentgrs, :STATENAME => unique => :statename, :OWNERSHP => unique => :ownershp, :COUNTYFIP => unique => :countyfip, :HHINCOME => unique => :hhincome, :INCEARN => sum => :incearn, :PROPTX99_recode => unique => :prop_tax);

# keep only households with positive earned income
filter!(r -> (r[:incearn] .> 0), df_ACS_hh);

# # keep only households who are either owners or renters (ownership is NOT N/A) - TAKEN CARE OF BY FHSV SELECTION
# filter!(r -> (r[:ownershp] .> 0), df_ACS_hh);


## Prepare data

# Homeowners
df_owners = filter(r -> (r[:ownershp] .== 1), df_ACS_hh);
inc_vingtiles!(df_owners);
gdf_owners = groupby(df_owners, [:incearn_vingtile]);
df_owners_mean = combine(gdf_owners, :incearn => mean, :valueh => mean, nrow);
sort!(df_owners_mean, :incearn_vingtile);
df_owners_mean[:, :log_incearn_mean] = log.(df_owners_mean[:, :incearn_mean]);
df_owners_mean[:, :log_valueh_mean]  = log.(df_owners_mean[:, :valueh_mean]);
ols_owners = lm(@formula(log_valueh_mean ~ log_incearn_mean), df_owners_mean)

df_owners_mean[:, :log_valueh_mean_predict_beta1] = 1.5 .+ df_owners_mean[:, :log_incearn_mean];
#df_owners_mean[:, :log_valueh_mean_predict_beta1] = coef(ols_owners)[1] .+ df_owners_mean[:, :log_incearn_mean];

# Renters
df_renters = filter(r -> (r[:ownershp] .== 2), df_ACS_hh);
inc_vingtiles!(df_renters);
gdf_renters = groupby(df_renters, [:incearn_vingtile]);
df_renters_mean = combine(gdf_renters, :incearn => mean, :rentgrs => mean, nrow);
sort!(df_renters_mean, :incearn_vingtile);
df_renters_mean[:, :log_incearn_mean] = log.(df_renters_mean[:, :incearn_mean]);
df_renters_mean[:, :log_rentgrs_mean] = log.(df_renters_mean[:, :rentgrs_mean]);
ols_renters = lm(@formula(log_rentgrs_mean ~ log_incearn_mean), df_renters_mean)

df_renters_mean[:, :log_rentgrs_mean_predict_beta1] =  -4 .+ df_renters_mean[:, :log_incearn_mean];
#df_renters_mean[:, :log_rentgrs_mean_predict_beta1] =  coef(ols_renters)[1] .+ df_renters_mean[:, :log_incearn_mean];


## Combined figure with predicted values

scatter(df_owners_mean.log_incearn_mean, df_owners_mean.log_valueh_mean,
label = "Log Home Value",
legend = :topleft,
foreground_color_legend = nothing,
xaxis="Log pre-government income",
xlim = (9,13),
ylim = (10.5,14.5),
aspect_ratio=:equal)
plot!(df_owners_mean.log_incearn_mean, df_owners_mean.log_valueh_mean_predict_beta1,
line=:black,
linestyle=:dash,
label = "",
aspect_ratio=:equal)
p11 = annotate!(12.0,13.7, Plots.text("Homothetic", 10, :dark, rotation = 45 ))

scatter(df_renters_mean.log_incearn_mean, df_renters_mean.log_rentgrs_mean,
label = "Log Rent",
legend = :topleft,
foreground_color_legend = nothing,
xaxis="Log pre-government income",
xlim = (9,13),
ylim = (5,9),
seriescolor = :orange,
aspect_ratio=:equal)
plot!([9.3,12.1], [5.3,8.1], line=:black, linestyle=:dash, label = "", aspect_ratio=:equal)
# plot!(df_renters_mean.log_incearn_mean, df_renters_mean.log_rentgrs_mean_predict_beta1,
# line=:black,
# linestyle=:dash,
# label = "",
# aspect_ratio=:equal)
p22 = annotate!(12.0,8.2, Plots.text("Homothetic", 10, :dark, rotation = 45 ))

l = @layout [a{0.01h}; grid(1,2)]
p = fill(plot(),3,1)
p[1] = plot(title="Housing Engel Curves (ACS, 2005/2006)",framestyle=nothing,showaxis=false,xticks=false,yticks=false,margin=0mm, bottom_margin = -20mm)
p[2] = p11
p[3] = p22
plot(p..., layout=l)
savefig( dir_out * "Engel_curve_ACS_homevalues_rents_ols.pdf" )
