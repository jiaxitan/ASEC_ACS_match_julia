
### Match ASEC 2005/2006, 2010/2011 and 2015/16 to ACS


using CSV, DataFrames, StatsBase, Statistics
using Plots, Plots.PlotMeasures, StatsPlots; gr()
using GLM, PrettyTables, FixedEffectModels, RegressionTables, CategoricalArrays
using TableView
using NearestNeighbors
using HTTP
using Distributions

## Housekeeping

# Set function and output directory + ASEC, ACS, state info files
dir_functions   = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Home owners/";
file_ASEC       = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/cps_reference_year.csv";
file_ACS        = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/usa_reference_year.csv";
file_state_info = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/states_fips_names.csv";
dir_out         = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/";
fig_dir_out     = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Match Quality/";
sample = "baseline";
    
# Prepare ACS and ASEC data
# Potential income regressions are muted for speed, since we are not using potential income for now
include(dir_functions * "ACS_ASEC_data_preparation.jl");
include(dir_functions * "ACS_ASEC_selection_sampleB.jl")
include(dir_functions * "ACS_ASEC_sample_selection_FHSV.jl")
include(dir_functions * "ACS_ASEC_inc_earned_person.jl")

include(dir_functions * "ASEC_UNITSSTR_recode.jl")
include(dir_functions * "ASEC_EDUC_recode.jl")
include(dir_functions * "ASEC_RACE_recode.jl")
include(dir_functions * "ASEC_MARST_recode.jl")
include(dir_functions * "ASEC_COUNTY_recode.jl")
include(dir_functions * "ASEC_METRO_recode.jl")

include(dir_functions * "ACS_UNITSSTR_recode.jl")
include(dir_functions * "ACS_METRO_recode.jl")
include(dir_functions * "ACS_RACE_recode.jl")
include(dir_functions * "ACS_EDUC_recode.jl")
include(dir_functions * "ACS_MARST_recode.jl")
include(dir_functions * "ACS_PROPTX99_recode.jl")
include(dir_functions * "ACS_COUNTY_2005_onwards_recode.jl")
include(dir_functions * "ACS_match_PUMA_county.jl")
    #include("/Users/main/Documents/GitHubRepos/julia_utils/ACS_COUNTY_2005_2006_recode.jl")

    df_ACS_hh, df_ASEC_hh = prepare_data(sample);

## Evaluate share of topcoded home value
#=
# The share of allocated (altered) values indicated by the flag variable QVALUEH in each two-year sample
valueh_topcode = DataFrame(year = [2005, 2010, 2015], Altered_cases = [sum(df_ACS_hh[in([2005, 2006]).(df_ACS_hh.YEAR), :qvalueh] .== 4)/nrow(df_ACS_hh[in([2005, 2006]).(df_ACS_hh.YEAR), :]), sum(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :qvalueh] .== 4)/nrow(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :]), sum(df_ACS_hh[in([2015, 2016]).(df_ACS_hh.YEAR), :qvalueh] .== 4)/ nrow(df_ACS_hh[in([2015, 2016]).(df_ACS_hh.YEAR), :])])

# Read the topcodes by state for each two-year sample. Note: 05/06 home value in bins
using XLSX
topcodes10 = DataFrame(XLSX.readtable("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/topcodes/2010acs_topcodes.xlsx", "Sheet1")...);
topcodes11 = DataFrame(XLSX.readtable("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/topcodes/2011acs_topcodes.xlsx", "Sheet1")...);
topcodes15 = DataFrame(XLSX.readtable("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/topcodes/2015acs_topcodes.xlsx", "Sheet1")...);
topcodes16 = DataFrame(XLSX.readtable("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/topcodes/2016acs_topcodes.xlsx", "Sheet1")...);

# Compute the share of topcoded home value for each state, for each two-year sample
state_topcodes1011 = unique(df_ACS_hh[:, [:statefips, :statename]])
state_topcodes1516 = unique(df_ACS_hh[:, [:statefips, :statename]])
insertcols!(state_topcodes1011, ncol(state_topcodes1011) + 1, :valueh_topcode_share => -1.0)
insertcols!(state_topcodes1516, ncol(state_topcodes1516) + 1, :valueh_topcode_share => -1.0)
df_10 = df_ACS_hh[df_ACS_hh.YEAR .== 2010, :];
df_11 = df_ACS_hh[df_ACS_hh.YEAR .== 2011, :];
df_15 = df_ACS_hh[df_ACS_hh.YEAR .== 2015, :];
df_16 = df_ACS_hh[df_ACS_hh.YEAR .== 2016, :];

for i in 1:nrow(state_topcodes1011)
    state = state_topcodes1011.statefips[i];
    state_topcodes1011[i, :valueh_topcode_share] = (sum(df_10[df_10.statefips .== state, :valueh] .== topcodes10[topcodes10.statefip .== state, :valueh]) + sum(df_11[df_11.statefips .== state, :valueh] .== topcodes11[topcodes11.statefip .== state, :valueh]))/(nrow(df_10[df_10.statefips .== state,:]) + nrow(df_11[df_11.statefips .== state,:]));
end
for i in 1:nrow(state_topcodes1516)
    state = state_topcodes1516.statefips[i];
    state_topcodes1516[i, :valueh_topcode_share] = (sum(df_15[df_15.statefips .== state, :valueh] .== topcodes15[topcodes15.statefip .== state, :valueh]) + sum(df_16[df_16.statefips .== state, :valueh] .== topcodes16[topcodes16.statefip .== state, :valueh]))/(nrow(df_15[df_15.statefips .== state,:]) + nrow(df_16[df_16.statefips .== state,:]));
end


CSV.write(dir_out * "valueh_topcodes1011.csv", state_topcodes1011);
CSV.write(dir_out * "valueh_topcodes1516.csv", state_topcodes1516);
=#

## Evaluate share of topcoded property tax

# topcode_proptx = combine(groupby(df_ACS_hh, :YEAR), :proptx99_recode => (s -> (topcode = sum(s .== 10000))) => :topcode, nrow);
# insertcols!(topcode_proptx, ncol(topcode_proptx)+1, :topcode_share => topcode_test.topcode./topcode_test.nrow);

## Dot plots of home value: home value of 2005 and 2006 are bined
#= 
sort!(df_ACS_hh, [:YEAR, :valueh, :rentgrs]);
scatter(df_ACS_hh.valueh[(df_ACS_hh.YEAR .== 2005) .& (df_ACS_hh.ownershp .== 1)], 
xlabel = "No. of the sample obs",
ylabel = "House value",
title = "Scatter plot of sorted house value 2005",
legend=false)
savefig(dir_out * "Sorted house value 2005.pdf");

scatter(df_ACS_hh.valueh[(df_ACS_hh.YEAR .== 2010) .& (df_ACS_hh.ownershp .== 1)], 
xlabel = "No. of the sample obs",
ylabel = "House value",
title = "Scatter plot of sorted house value 2010",
legend=false)
savefig(dir_out * "Sorted house value 2010.pdf");
=#

## Regression analysis on matching variables
#=
insertcols!(df_ACS_hh, ncol(df_ACS_hh)+1, :valueh_log => log.(df_ACS_hh.valueh));
include(dir_functions * "R2_comparison.jl");
R2_comparison = r2_compare();
CSV.write(dir_out * "valueh_regression.csv", R2_comparison);

# Compute F-value of the significance test. 
# Kjetil pointed out that this F-test is not meaningful due to the larger sample size
insertcols!(R2_comparison, :F_levels => ((R2_comparison.RSS_levels .- repeat(R2_comparison.RSS_levels[1:3], 9)) .* (R2_comparison.n .- 8)) ./ (repeat(R2_comparison.RSS_levels[1:3], 9) .* 1))
insertcols!(R2_comparison, :F_logs => ((R2_comparison.RSS_logs .- repeat(R2_comparison.RSS_logs[1:3], 9)) .* (R2_comparison.n .- 8)) ./ (repeat(R2_comparison.RSS_logs[1:3],9) .* 1))
insertcols!(R2_comparison, :F_critical => quantile.(FDist.(1, R2_comparison.n .- 8), 1-0.05))
R2_comparison[R2_comparison.regressors .== "None", :F_levels] .= ((R2_comparison.RSS_levels[R2_comparison.regressors .== "None",:] .- R2_comparison.RSS_levels[1:3]) .* (R2_comparison.n[R2_comparison.regressors .== "None", :] .- 8)) ./ (R2_comparison.RSS_levels[1:3] .* 6)
R2_comparison[R2_comparison.regressors .== "None", :F_logs] .= ((R2_comparison.RSS_logs[R2_comparison.regressors .== "None",:] .- R2_comparison.RSS_logs[1:3]) .* (R2_comparison.n[R2_comparison.regressors .== "None", :] .- 8)) ./ (R2_comparison.RSS_logs[1:3] .* 6)
R2_comparison[R2_comparison.regressors .== "None", :F_critical] .= quantile.(FDist.(6, R2_comparison.n[R2_comparison.regressors .== "None", :] .- 8), 1-0.05)
sort!(R2_comparison, :sample);
CSV.write(dir_out * "valueh_regression.csv", R2_comparison);

=#

## Match ASEC to ACS observations

include(dir_functions * "ASEC_ACS_match_county.jl")
include(dir_functions * "ASEC_ACS_match_state.jl")
include(dir_functions * "ASEC_ACS_match.jl")
matching_set = [:grossinc, :educ_recode, :unitsstr_recode];
k_NN = 9;

# Prepare ASEC and ACS data

df_ASEC_hh_match = deepcopy(df_ASEC_hh);
df_ASEC_hh_match_county = filter(r -> (r[:county] .!= 0), df_ASEC_hh_match); # Select obs with county for county matching
df_ASEC_hh_match_state = filter(r -> (r[:county] .== 0), df_ASEC_hh_match);  # Select obs with missing county for state matching

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Home Owners/fit_proptxrate_income.jl");
#select!(df_ACS_hh, Not(:txrate))
fit_proptxrate_income!()
df_ACS_hh.proptx99_recode = convert.(Float64, df_ACS_hh.proptx99_recode)
df_ACS_hh[df_ACS_hh.ownershp .!= 1.0, :proptx99_recode] .= df_ACS_hh[df_ACS_hh.ownershp .!= 1.0, :valueh] .* df_ACS_hh[df_ACS_hh.ownershp .!= 1.0, :txrate]

df_ACS_hh_match = deepcopy(df_ACS_hh);
df_ACS_hh_match_county = filter(r -> (r[:county] .!= 0), df_ACS_hh_match); # Select obs with county for county matching
df_ACS_hh_match_state = filter(r -> (r[:county] .== 0), df_ACS_hh_match);  # Select obs with missing county for state matching

## 2005 and 2006
df_ASEC_hh_match_0506_final = ASEC_ACS_match([2005, 2006], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);
insertcols!(df_ASEC_hh_match_0506_final, :YEAR_reference => df_ASEC_hh_match_0506_final.YEAR)

## 2010 and 2011
df_ASEC_hh_match_1011_final = ASEC_ACS_match([2010, 2011], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);
insertcols!(df_ASEC_hh_match_1011_final, :YEAR_reference => df_ASEC_hh_match_1011_final.YEAR)

## 2015 and 2016
df_ASEC_hh_match_1516_final = ASEC_ACS_match([2015, 2016], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);
insertcols!(df_ASEC_hh_match_1516_final, :YEAR_reference => df_ASEC_hh_match_1516_final.YEAR)

## Save results

df_ASEC_hh_match_0506_save = select(df_ASEC_hh_match_0506_final, [:YEAR_reference, :YEAR_survey, :SERIAL, :statename, :ACS_proptax_mean, :ACS_proptax_median, :ACS_valueh_mean, :ACS_valueh_median, :ACS_rentgrs_mean, :ACS_rentgrs_median, :ACS_rent_mean, :ACS_rent_median]);
df_ASEC_hh_match_1011_save = select(df_ASEC_hh_match_1011_final, [:YEAR_reference, :YEAR_survey, :SERIAL, :statename, :ACS_proptax_mean, :ACS_proptax_median, :ACS_valueh_mean, :ACS_valueh_median, :ACS_rentgrs_mean, :ACS_rentgrs_median, :ACS_rent_mean, :ACS_rent_median]);
df_ASEC_hh_match_1516_save = select(df_ASEC_hh_match_1516_final, [:YEAR_reference, :YEAR_survey, :SERIAL, :statename, :ACS_proptax_mean, :ACS_proptax_median, :ACS_valueh_mean, :ACS_valueh_median, :ACS_rentgrs_mean, :ACS_rentgrs_median, :ACS_rent_mean, :ACS_rent_median]);

sort!(df_ASEC_hh_match_0506_save, [:YEAR_reference, :SERIAL]);
sort!(df_ASEC_hh_match_1011_save, [:YEAR_reference, :SERIAL]);
sort!(df_ASEC_hh_match_1516_save, [:YEAR_reference, :SERIAL]);

if sample == "baseline"
    CSV.write(dir_out * "baseline_ASEC_ACS_hh_match_0506.csv", df_ASEC_hh_match_0506_save);
    CSV.write(dir_out * "baseline_ASEC_ACS_hh_match_1011.csv", df_ASEC_hh_match_1011_save);
    CSV.write(dir_out * "baseline_ASEC_ACS_hh_match_1516.csv", df_ASEC_hh_match_1516_save);
elseif sample == "full"
    CSV.write(dir_out * "full_ASEC_ACS_hh_match_0506.csv", df_ASEC_hh_match_0506_save);
    CSV.write(dir_out * "full_ASEC_ACS_hh_match_1011.csv", df_ASEC_hh_match_1011_save);
    CSV.write(dir_out * "full_ASEC_ACS_hh_match_1516.csv", df_ASEC_hh_match_1516_save);
end
#=
## Density plot for match quality on each matching variable, for the original matching set with 7 variables

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_grossinc_mean[(:dif_grossinc_mean .> quantile!(:dif_grossinc_mean, 0.05, sorted = false)) .& (:dif_grossinc_mean .< quantile!(:dif_grossinc_mean, 0.95, sorted = false))])
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_grossinc_mean[(:dif_grossinc_mean .> quantile!(:dif_grossinc_mean, 0.05, sorted = false)) .& (:dif_grossinc_mean .< quantile!(:dif_grossinc_mean, 0.95, sorted = false))])
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_grossinc_mean[(:dif_grossinc_mean .> quantile!(:dif_grossinc_mean, 0.05, sorted = false)) .& (:dif_grossinc_mean .< quantile!(:dif_grossinc_mean, 0.95, sorted = false))])
xlabel!("Differences to ASEC HHs - Gross Income Mean")
savefig(fig_dir_out * "Grossinc_mean.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_grossinc_median[(:dif_grossinc_median .> quantile!(:dif_grossinc_median, 0.05, sorted = false)) .& (:dif_grossinc_median .< quantile!(:dif_grossinc_median, 0.95, sorted = false))])
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_grossinc_median[(:dif_grossinc_median .> quantile!(:dif_grossinc_median, 0.05, sorted = false)) .& (:dif_grossinc_median .< quantile!(:dif_grossinc_median, 0.95, sorted = false))])
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_grossinc_median[(:dif_grossinc_median .> quantile!(:dif_grossinc_median, 0.05, sorted = false)) .& (:dif_grossinc_median .< quantile!(:dif_grossinc_median, 0.95, sorted = false))])
xlabel!("Differences to ASEC HHs - Gross Income Median")
savefig(fig_dir_out * "Grossinc_median.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_size_mean)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_size_mean)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_size_mean)
xlabel!("Differences to ASEC HHs - Size Mean")
savefig(fig_dir_out * "Size_mean.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_size_median)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_size_median)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_size_median)
xlabel!("Differences to ASEC HHs - Size Median")
savefig(fig_dir_out * "Size_median.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_age_mean)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_age_mean)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_age_mean)
xlabel!("Differences to ASEC HHs - Age Mean")
savefig(fig_dir_out * "Age_mean.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_age_median)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_age_median)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_age_median)
xlabel!("Differences to ASEC HHs - Age Median")
savefig(fig_dir_out * "Age_median.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_unitsstr_mean)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_unitsstr_mean)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_unitsstr_mean)
xlabel!("Differences to ASEC HHs - Unit Structure Mean")
savefig(fig_dir_out * "UnitsStr_mean.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_unitsstr_median)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_unitsstr_median)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_unitsstr_median)
xlabel!("Differences to ASEC HHs - Unit Structure Median")
savefig(fig_dir_out * "UnitsStr_median.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_race_mean)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_race_mean)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_race_mean)
xlabel!("Differences to ASEC HHs - Race Mean")
savefig(fig_dir_out * "Race_mean.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_race_median)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_race_median)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_race_median)
xlabel!("Differences to ASEC HHs - Race Median")
savefig(fig_dir_out * "Race_median.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_educ_mean)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_educ_mean)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_educ_mean)
xlabel!("Differences to ASEC HHs - Educ Mean")
savefig(fig_dir_out * "Educ_mean.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_educ_median)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_educ_median)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_educ_median)
xlabel!("Differences to ASEC HHs - Educ Median")
savefig(fig_dir_out * "Educ_median.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_sex_mean)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_sex_mean)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_sex_mean)
xlabel!("Differences to ASEC HHs - Sex Mean")
savefig(fig_dir_out * "Sex_mean.pdf")

@df df_ASEC_hh_match_0506_final density(label = "2005/06", :dif_sex_median)
@df df_ASEC_hh_match_1011_final density!(label = "2010/11", :dif_sex_median)
@df df_ASEC_hh_match_1516_final density!(label = "2015/16", :dif_sex_median)
xlabel!("Differences to ASEC HHs - Sex Median")
savefig(fig_dir_out * "Sex_median.pdf")
=#



