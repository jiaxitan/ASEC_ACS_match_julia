
### Match ASEC 2005/2006, 2010/2011 and 2015/16 to ACS

# If ASEC county known      -> use same county (if in ACS, otherwise treat as ASEC county not known)
# If ASEC county not known  -> match to all ACS obs in the same ASEC state

# For ASEC owners: get home value and property taxes
# For ASEC renters: get rent and gross rent paid
# NOTE: for ACS, split potential earnings regression by years to speed up/avoid crashes


## Housekeeping

using CSV, DataFrames, StatsBase, Statistics
using Plots, Plots.PlotMeasures, StatsPlots; gr()
using GLM, PrettyTables, FixedEffectModels, RegressionTables, CategoricalArrays
using TableView
using NearestNeighbors
using HTTP
using Distributions

# Set function and output directory + ASEC, ACS, state info files
dir_functions   = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/ASEC_ACS_match_julia/";
dir_out         = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/";
fig_dir_out     = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Match Quality/";
file_ASEC       = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/cps_00002.csv";
file_ACS        = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/usa_00010.csv";
file_state_info = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/states_fips_names.csv";

include(dir_functions * "ACS_ASEC_selection_sampleB.jl")
include(dir_functions * "ACS_ASEC_inc_earned_person.jl")

include(dir_functions * "ASEC_UNITSSTR_recode.jl")
include(dir_functions * "ASEC_EDUC_recode.jl")
include(dir_functions * "ASEC_RACE_recode.jl")
include(dir_functions * "ASEC_MARST_recode.jl")
include(dir_functions * "ASEC_COUNTY_recode.jl")
include(dir_functions * "ASEC_METRO_recode.jl")

# Import state info
df_state_info = CSV.read(file_state_info, DataFrame; types=[Int64, Int64, String, String, String, Int64, Int64]);


## Import and prepare ASEC file
df_ASEC_0 = CSV.read(file_ASEC, DataFrame);

select!(df_ASEC_0, Not([:MONTH, :CPSID, :ASECFLAG, :ASECWTH, :CPSIDP, :ASECWT, :CBSASZ]));
rename!(df_ASEC_0, :STATEFIP => :STATEFIPS);

# Add state info
df_ASEC = innerjoin(df_ASEC_0, df_state_info, on = :STATEFIPS);

replace!(df_ASEC.INCWAGE,  99999999=>0);
replace!(df_ASEC.INCBUS,   99999999=>0); # has negative values -> bottom coded at -19998
replace!(df_ASEC.INCFARM,  99999999=>0); # has negative values -> bottom coded at -19998
replace!(df_ASEC.INCINT,   9999999=>0);
replace!(df_ASEC.INCDIVID, 9999999=>0); df_ASEC[!, :INCDIVID] = collect(skipmissing(df_ASEC.INCDIVID));
replace!(df_ASEC.INCRENT,  9999999=>0); df_ASEC[!, :INCRENT]  = collect(skipmissing(df_ASEC.INCRENT));   # has negative values
replace!(df_ASEC.INCASIST, 9999999=>0); df_ASEC[!, :INCASIST] = collect(skipmissing(df_ASEC.INCASIST));
replace!(df_ASEC.PROPTAX,  99997=>0);   df_ASEC[!, :PROPTAX] = collect(skipmissing(df_ASEC.PROPTAX));   # 99997 = Missing

# Apply FHSV sample selection
df_ASEC_sample = ACS_ASEC_selection_sampleB(df_ASEC);


# Recode UNITSSTR, EDUC, RACE, MARST, COUNTY Names
ASEC_UNITSSTR_recode!(df_ASEC_sample);
ASEC_EDUC_recode!(df_ASEC_sample);
ASEC_RACE_recode!(df_ASEC_sample);
ASEC_MARST_recode!(df_ASEC_sample);
ASEC_COUNTY_recode!(df_ASEC_sample);
ASEC_METRO_recode!(df_ASEC_sample);

# Generate personal earned income (to compute number of earners in each household)
ACS_ASEC_inc_earned_person!(df_ASEC_sample)
# Collapse at household level
ASEC_gdf_hh = groupby(df_ASEC_sample, [:YEAR, :SERIAL]);
df_ASEC_hh = combine(ASEC_gdf_hh, nrow=>:size, :inc_earned_person => ( x -> (count(!=(0), x)) ) => :earners, :AGE=>first=>:age, :SEX=>first=>:sex, :IND=>first=>:ind, :UNITSSTR_recode=>first=>:unitsstr_recode, :RACE_recode=>first=>:race_recode, :MARST_recode=>first=>:marst_recode, :OCC=>first=>:occ, :EDUC_recode=>first=>:educ_recode, :STATENAME=>first=>:statename, :METRO=>first=>:metro, :METRO_name=>first=>:metro_name, :METAREA=>first=>:metarea, :COUNTY=>first=>:county, :COUNTY_name_state_county=>first=>:county_name_state_county, :METFIPS=>first=>:metfips, :INDIVIDCC=>first=>:individcc, :OWNERSHP=>first=>:ownershp, :HHINCOME=>first=>:hhincome, :PROPTAX=>first=>:proptax, :INCWAGE=>sum=>:incwage, :INCBUS=>sum=>:incbus, :INCFARM=>sum=>:incfarm, :INCINT=>sum=>:incint, :INCDIVID=>sum=>:incdivid, :INCRENT=>sum=>:incrent, :INCASIST=>sum=>:incasist);
insertcols!(df_ASEC_hh, 3, :grossinc => df_ASEC_hh.incwage + df_ASEC_hh.incbus + df_ASEC_hh.incfarm + df_ASEC_hh.incint + df_ASEC_hh.incdivid + df_ASEC_hh.incrent + df_ASEC_hh.incasist);
filter!(r -> (r[:grossinc] .> 0), df_ASEC_hh); # Innocent
df_ASEC_hh[:, :grossinc_log] = log.(df_ASEC_hh[:, :grossinc]);
sort!(df_ASEC_hh, :grossinc)

# Potential Earnings Regression using FE package -> fast
ols_potential_earnings_ASEC_fe = reg(df_ASEC_hh, @formula(grossinc_log ~ YEAR + earners + age + age^2 + sex + marst_recode + race_recode + educ_recode + ind + occ + age&educ_recode + age&occ));
println("ASEC: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ASEC_fe),digits=2) ))
df_ASEC_hh[:, :grossinc_log_potential] = predict(ols_potential_earnings_ASEC_fe, df_ASEC_hh);
df_ASEC_hh[:, :grossinc_potential] = exp.(df_ASEC_hh[:, :grossinc_log_potential]);

# # Potential Earnings Regression using GLM package -> slow
# transform!(df_ASEC_hh, [:YEAR, :sex, :race_recode, :educ_recode, :marst_recode, :ind, :occ] .=> categorical, renamecols = false);
# ols_potential_earnings_ASEC = lm(@formula(grossinc_log ~ YEAR + earners + age + age^2 + sex + marst_recode + race_recode + educ_recode + ind + occ + age&educ_recode + age&occ), df_ASEC_hh);
# println("ASEC: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ASEC),digits=2) ))
# df_ASEC_hh[:, :grossinc_log_potential] = predict(ols_potential_earnings_ASEC);
# df_ASEC_hh[:, :grossinc_potential] = exp.(predict(ols_potential_earnings_ASEC));

replace!(x -> x < 0 ? 1 : x, df_ASEC_hh.grossinc_potential);

# ### OLD VERSION - too slow! see below
# # Compute potential earnings
# df_ASEC_sample[:, :GROSSINC] = df_ASEC_sample[:, :INCWAGE] + df_ASEC_sample[:, :INCBUS] + df_ASEC_sample[:, :INCFARM] + df_ASEC_sample[:, :INCINT] + df_ASEC_sample[:, :INCDIVID] + df_ASEC_sample[:, :INCRENT] + df_ASEC_sample[:, :INCASIST];
# df_ASEC_sample_earnings_reg = filter(r -> (r[:GROSSINC] .> 0), df_ASEC_sample);
# transform!(df_ASEC_sample_earnings_reg, [:YEAR, :SEX, :RACE_recodes, :EDUC_recodes, :MARST_recodes, :IND, :OCC] .=> categorical, renamecols = false);
# ols_potential_earnings_ASEC = lm(@formula(GROSSINC ~ YEAR + AGE + AGE^2 + SEX + MARST_recodes + RACE_recodes + EDUC_recodes + IND + OCC + WKSWORK1), df_ASEC_sample_earnings_reg);
# println(" ")
# println("ASEC: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ASEC),digits=2) ))
# println(" ")
# df_ASEC_sample_earnings_reg[:, :GROSSINC_potential] = predict(ols_potential_earnings_ASEC);
# replace!(x -> x < 0 ? 1 : x, df_ASEC_sample_earnings_reg.GROSSINC_potential);
#
# # #### THIS IS TOO SLOW... that's why I am doing this at this household level now. Potential fix: loop over years?
# # df_tmp = leftjoin(df_ASEC_sample, df_ASEC_sample_earnings_reg, on = [:YEAR, :SERIAL, :PERNUM], makeunique=true);
# # replace!(x -> ismissing(x) ? 0 : x, df_tmp.GROSSINC_potential);
# # duplicates = names(df_tmp)[occursin.(r"_1", names(df_tmp))];
# # select!(df_tmp, Not(duplicates));
#
# # # Add state info
# # df_ASEC_sample_final = innerjoin(df_tmp, df_state_info, on = :STATEFIPS);
#
# # # Collapse at household level
# # ASEC_gdf_hh = groupby(df_ASEC_sample_final, [:YEAR, :SERIAL]);
# # df_ASEC_hh = combine(ASEC_gdf_hh, nrow=>:size, :AGE=>first=>:age, :SEX=>first=>:sex, :RACE_recodes=>first=>:race_recodes, :EDUC_recodes=>first=>:educ_recodes, :STATENAME=>first=>:statename, :METRO=>first=>:metro, :METRO_name=>first=>:metro_name, :METAREA=>first=>:metarea, :COUNTY=>first=>:county, :COUNTY_name_state_county=>first=>:county_name_state_county, :METFIPS=>first=>:metfips, :INDIVIDCC=>first=>:individcc, :OWNERSHP=>first=>:ownershp, :HHINCOME=>first=>:hhincome, :PROPTAX=>first=>:proptax, :INCWAGE=>sum=>:incwage, :INCBUS=>sum=>:incbus, :INCFARM=>sum=>:incfarm, :INCINT=>sum=>:incint, :INCDIVID=>sum=>:incdivid, :INCRENT=>sum=>:incrent, :INCASIST=>sum=>:incasist, :GROSSINC_potential=>sum=>:grossinc_potential);
# # insertcols!(df_ASEC_hh, 3, :grossinc => df_ASEC_hh.incwage + df_ASEC_hh.incbus + df_ASEC_hh.incfarm + df_ASEC_hh.incint + df_ASEC_hh.incdivid + df_ASEC_hh.incrent + df_ASEC_hh.incasist);

ASEC_missing_COUNTY_share  = count(i -> (i .== 0), df_ASEC_hh.county)/size(df_ASEC_hh,1)*100         # Compute share of observations with missing COUNTY
ASEC_missing_METRO_share   = count(i -> (i .== 0 || i .== 4 || i .== 9 ), df_ASEC_hh.metro)/size(df_ASEC_hh,1)*100   # Compute share of observations with missing METFIPS
ASEC_missing_METAREA_share = count(i -> (i .>= 9997), df_ASEC_hh.metarea)/size(df_ASEC_hh,1)*100    # Compute share of observations with missing METAREA
ASEC_missing_METFIPS_share = count(i -> (i .>= 99998), df_ASEC_hh.metfips)/size(df_ASEC_hh,1)*100   # Compute share of observations with missing METFIPS
ASEC_missing_INDIVIDCC_share = count(i -> (i .== 0), df_ASEC_hh.individcc)/size(df_ASEC_hh,1)*100   # Compute share of observations with missing INDIVIDCC


## Import and prepare ACS file

include(dir_functions * "ACS_UNITSSTR_recode.jl")
include(dir_functions * "ACS_METRO_recode.jl")
include(dir_functions * "ACS_RACE_recode.jl")
include(dir_functions * "ACS_EDUC_recode.jl")
include(dir_functions * "ACS_MARST_recode.jl")
include(dir_functions * "ACS_PROPTX99_recode.jl")
include(dir_functions * "ACS_COUNTY_2005_onwards_recode.jl")
include(dir_functions * "ACS_match_PUMA_county.jl")
    #include("/Users/main/Documents/GitHubRepos/julia_utils/ACS_COUNTY_2005_2006_recode.jl")

df_ACS = CSV.read(file_ACS, DataFrame);

select!(df_ACS, Not([:SAMPLE, :CBSERIAL, :HHWT, :CLUSTER, :STRATA, :GQ, :PERWT, :OWNERSHPD, :RACED, :EDUCD, :WKSWORK1]));

rename!(df_ACS, :STATEFIP => :STATEFIPS);
rename!(df_ACS, :COUNTYFIP => :COUNTYFIPS);

replace!(df_ACS.INCWAGE,  999999=>0);
replace!(df_ACS.INCBUS00, 999999=>0); # Business and farm income; has negative values -> bottom coded at -9999
replace!(df_ACS.INCINVST, 999999=>0); # Interest, dividend, and rental income; has negative values -> bottom coded at -9999
replace!(df_ACS.VALUEH,   9999999=>0); # Value of housing units in contemporary dollars; Missing == 9999999

# Apply FHSV sample selection
df_ACS_sample0 = ACS_ASEC_selection_sampleB(df_ACS);

# Add state info
df_ACS_sample = innerjoin(df_ACS_sample0, df_state_info, on = :STATEFIPS);

# Construct county from PUMA
sort!(df_ACS_sample, [:YEAR, :STATEFIPS, :PUMA]);
ACS_match_PUMA_county!(df_ACS_sample);

#=
compare_county = combine(groupby(df_ACS_sample, :STATEFIPS), :COUNTYFIPS => (c -> (sum(c .== 0)/length(c))), :COUNTYFIPS2 => (c -> (sum(c .== 0)/length(c))));
rename!(compare_county, :COUNTYFIPS_function => :Original, :COUNTYFIPS2_function => :After_matching);
insertcols!(compare_county, size(compare_county,2)+1, :STATENAME => df_state_info.STATENAME);
CSV.write(dir_out * "compare_county_matching.csv", compare_county);
=#
# Recode UNITSSTR, EDUC, RACE, MARST, COUNTY Names
ACS_UNITSSTR_recode!(df_ACS_sample);
ACS_EDUC_recode!(df_ACS_sample);
ACS_RACE_recode!(df_ACS_sample);
ACS_MARST_recode!(df_ACS_sample);
ACS_COUNTY_2005_onwards_recode!(df_ACS_sample);
ACS_METRO_recode!(df_ACS_sample);
ACS_PROPTX99_recode!(df_ACS_sample);

# Drop observations with UNITSSTR_recode == 99 (Boat, tent, van, other -> does not exist in ASEC)
filter!(r -> (r[:UNITSSTR_recode] .< 99), df_ACS_sample);

# Generate personal earned income (to compute number of earners in each household)
ACS_ASEC_inc_earned_person!(df_ACS_sample);

# Collapse at household level
ACS_gdf_hh = groupby(df_ACS_sample, [:YEAR, :SERIAL]);
df_ACS_hh = combine(ACS_gdf_hh, nrow=>:size, :inc_earned_person => ( x -> (count(!=(0), x)) ) => :earners, :AGE=>first=>:age, :SEX=>first=>:sex, :UNITSSTR_recode=>first=>:unitsstr_recode, :RACE_recode=>first=>:race_recode, :EDUC_recode=>first=>:educ_recode, :MARST_recode=>first=>:marst_recode, :IND=>first=>:ind, :OCC=>first=>:occ, :STATENAME=>first=>:statename, :METRO=>first=>:metro, :METRO_name=>first=>:metro_name, :METAREA=>first=>:metarea, 
:QVALUEH=>first=>:qvalueh, :STATEFIPS=>first=>:statefips,:COUNTY2_name_state_county=>first=>:county_name_state_county, :COUNTYFIPS2_recode=>first=>:county, :CITY=>first=>:city, :PUMA=>first=>:puma, :OWNERSHP=>first=>:ownershp, :HHINCOME=>first=>:hhincome, :INCWAGE=>sum=>:incwage, :INCBUS00=>sum=>:incbus00, :INCINVST=>sum=>:incinvst, :PROPTX99_recode=>first=>:proptx99_recode, :RENTGRS=>first=>:rentgrs, :RENT=>first=>:rent, :VALUEH=>first=>:valueh);
insertcols!(df_ACS_hh, 3, :grossinc => df_ACS_hh.incwage + df_ACS_hh.incbus00 + df_ACS_hh.incinvst);
filter!(r -> (r[:grossinc] .> 0), df_ACS_hh); # Innocent
df_ACS_hh[:, :grossinc_log] = log.(df_ACS_hh[:, :grossinc]);
df_ACS_hh[:, :proptx_log] = log.(df_ACS_hh[:, :proptx99_recode]);


# Potential Earnings Regression using FE package -> fast
ols_potential_earnings_ACS_fe = reg(df_ACS_hh, @formula(grossinc_log ~ YEAR + earners + age + age^2 + sex + marst_recode + race_recode + educ_recode + ind + occ + age&educ_recode + age&occ));
println("ACS: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ACS_fe),digits=2) ));
df_ACS_hh[:, :grossinc_log_potential] = predict(ols_potential_earnings_ACS_fe, df_ACS_hh);
df_ACS_hh[:, :grossinc_potential] = exp.(df_ACS_hh[:, :grossinc_log_potential]);


# # Potential Earnings Regression using GLM package -> slow
# transform!(df_ACS_hh, [:YEAR, :sex, :race_recode, :educ_recode, :marst_recode, :ind, :occ] .=> categorical, renamecols = false);
# df_ACS_hh_ols_05_06 = filter(r -> (r[:YEAR] .== 2005 || r[:YEAR] .== 2006), df_ACS_hh);
# df_ACS_hh_ols_10_11 = filter(r -> (r[:YEAR] .== 2010 || r[:YEAR] .== 2011), df_ACS_hh);
# df_ACS_hh_ols_15_16 = filter(r -> (r[:YEAR] .== 2015 || r[:YEAR] .== 2016), df_ACS_hh);
# ols_potential_earnings_ACS_05_06 = lm(@formula(grossinc_log ~ YEAR + earners + age + age^2 + sex + marst_recode + race_recode + educ_recode + ind + occ + age&educ_recode + age&occ), df_ACS_hh_ols_05_06);
# ols_potential_earnings_ACS_10_11 = lm(@formula(grossinc_log ~ YEAR + earners + age + age^2 + sex + marst_recode + race_recode + educ_recode + ind + occ + age&educ_recode + age&occ), df_ACS_hh_ols_10_11);
# ols_potential_earnings_ACS_15_16 = lm(@formula(grossinc_log ~ YEAR + earners + age + age^2 + sex + marst_recode + race_recode + educ_recode + ind + occ + age&educ_recode + age&occ), df_ACS_hh_ols_15_16);
# println(" ")
# println("ACS 05/06: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ACS_05_06),digits=2) ) )
# println("ACS 10/11: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ACS_10_11),digits=2) ) )
# println("ACS 15/16: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ACS_15_16),digits=2) ) )
# println(" ")
# df_ACS_hh[:, :grossinc_log_potential] = [predict(ols_potential_earnings_ACS_05_06); predict(ols_potential_earnings_ACS_10_11); predict(ols_potential_earnings_ACS_15_16)];
# df_ACS_hh[:, :grossinc_potential] = [exp.(predict(ols_potential_earnings_ACS_05_06)); exp.(predict(ols_potential_earnings_ACS_10_11)); exp.(predict(ols_potential_earnings_ACS_15_16))];

replace!(x -> x < 0 ? 1 : x, df_ACS_hh.grossinc_potential);

# ### OLD VERSION - too slow and crashes Julia! see below
# # Compute potential earnings
# df_ACS_sample[:, :GROSSINC] = df_ACS_sample[:, :INCWAGE] + df_ACS_sample[:, :INCBUS00] + df_ACS_sample[:, :INCINVST];
# df_ACS_sample_earnings_reg = filter(r -> (r[:GROSSINC] .> 0), df_ACS_sample);
# transform!(df_ACS_sample_earnings_reg, [:YEAR, :SEX, :RACE_recodes, :EDUC_recodes, :MARST_recodes, :IND, :OCC] .=> categorical, renamecols = false);
# ols_potential_earnings_ACS = lm(@formula(GROSSINC ~ YEAR + AGE + AGE^2 + SEX + MARST_recodes + RACE_recodes + EDUC_recodes + IND + OCC), df_ACS_sample_earnings_reg);
#     #ols_potential_earnings_ACS_new = reg(df_ACS_sample_earnings_reg, @formula(GROSSINC ~ YEAR + AGE + AGE^2 + SEX + MARST_recodes + RACE_recodes + EDUC_recodes + IND + OCC + WKSWORK1));
# println(" ")
# println("ACS: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ACS),digits=2) ) )
# println(" ")
# df_ACS_sample_earnings_reg[:, :GROSSINC_potential] = predict(ols_potential_earnings_ACS);
# replace!(x -> x < 0 ? 1 : x, df_ACS_sample_earnings_reg.GROSSINC_potential);
# df_tmp_ACS = leftjoin(df_ACS_sample, df_ACS_sample_earnings_reg, on = [:YEAR, :SERIAL, :PERNUM], makeunique=true);
# replace!(x -> ismissing(x) ? 0 : x, df_tmp_ACS.GROSSINC_potential);
# duplicates_ACS = names(df_tmp_ACS)[occursin.(r"_1", names(df_tmp_ACS))];
# select!(df_tmp_ACS, Not(duplicates_ACS));
#
# # Add state info
# df_ACS_sample_final = innerjoin(df_tmp_ACS, df_state_info, on = :STATEFIPS);

# # Collapse at household level
# ACS_gdf_hh = groupby(df_ACS_sample_final, [:YEAR, :SERIAL]);
# df_ACS_hh = combine(ACS_gdf_hh, nrow=>:size, :AGE=>first=>:age, :SEX=>first=>:sex, :RACE_recodes=>first=>:race_recodes, :EDUC_recodes=>first=>:educ_recodes, :STATENAME=>first=>:statename, :METRO=>first=>:metro, :METRO_name=>first=>:metro_name, :METAREA=>first=>:metarea, :COUNTY_name_state_county=>first=>:county_name_state_county, :COUNTYFIPS_recode=>first=>:county, :CITY=>first=>:city, :PUMA=>first=>:puma, :OWNERSHP=>first=>:ownershp, :HHINCOME=>first=>:hhincome, :INCWAGE=>sum=>:incwage, :INCBUS00=>sum=>:incbus00, :INCINVST=>sum=>:incinvst, :GROSSINC_potential=>sum=>:grossinc_potential, :PROPTX99_recode=>first=>:proptx99_recode, :RENTGRS=>first=>:rentgrs, :VALUEH=>first=>:valueh);
# insertcols!(df_ACS_hh, 3, :grossinc => df_ACS_hh.incwage + df_ACS_hh.incbus00 + df_ACS_hh.incinvst);

 #=
CSV.write(dir_out * "ASEC_sample.csv", df_ASEC_hh);
CSV.write(dir_out * "ACS_sample.csv", df_ACS_hh);

df_ASEC_hh = CSV.read(dir_out * "ASEC_sample.csv", DataFrame);
df_ACS_hh = CSV.read(dir_out * "ACS_sample.csv", DataFrame);
=#

valueh_topcode = DataFrame(year = [2005, 2010, 2015], 
Altered_cases = [sum(df_ACS_hh[in([2005, 2006]).(df_ACS_hh.YEAR), :qvalueh] .== 4)/nrow(df_ACS_hh[in([2005, 2006]).(df_ACS_hh.YEAR), :]), sum(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :qvalueh] .== 4)/nrow(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :]), sum(df_ACS_hh[in([2015, 2016]).(df_ACS_hh.YEAR), :qvalueh] .== 4)/ nrow(df_ACS_hh[in([2015, 2016]).(df_ACS_hh.YEAR), :])])

using XLSX
topcodes10 = DataFrame(XLSX.readtable("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/topcodes/2010acs_topcodes.xlsx", "Sheet1")...);
topcodes11 = DataFrame(XLSX.readtable("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/topcodes/2011acs_topcodes.xlsx", "Sheet1")...);
topcodes15 = DataFrame(XLSX.readtable("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/topcodes/2015acs_topcodes.xlsx", "Sheet1")...);
topcodes16 = DataFrame(XLSX.readtable("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/topcodes/2016acs_topcodes.xlsx", "Sheet1")...);


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

#=
topcode_test = combine(groupby(df_ACS_hh, :YEAR), :proptx99_recode => (s -> (topcode = sum(s .== 10000))) => :topcode, nrow);
insertcols!(topcode_test, ncol(topcode_test)+1, :topcode_share => topcode_test.topcode./topcode_test.nrow);
topcode_test

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

insertcols!(df_ACS_hh, ncol(df_ACS_hh)+1, :valueh_log => log.(df_ACS_hh.valueh));

include(dir_functions * "R2_comparison.jl");
R2_comparison = r2_compare();

f = FDist(1,8)
quantile(f, 1 - 0.05)
CSV.write(dir_out * "valueh_regression.csv", R2_comparison);

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
matching_set = [:grossinc, :size, :age, :unitsstr_recode, :race_recode, :educ_recode, :sex];
const k_NN = 9;

# Prepare ASEC and ACS data

df_ASEC_hh_match = deepcopy(df_ASEC_hh);
df_ASEC_hh_match_county = filter(r -> (r[:county] .!= 0), df_ASEC_hh_match); # Select obs with county for county matching
df_ASEC_hh_match_state = filter(r -> (r[:county] .== 0), df_ASEC_hh_match);  # Select obs with missing county for state matching

df_ACS_hh_match = deepcopy(df_ACS_hh);
df_ACS_hh_match_county = filter(r -> (r[:county] .!= 0), df_ACS_hh_match); # Select obs with county for county matching
df_ACS_hh_match_state = filter(r -> (r[:county] .== 0), df_ACS_hh_match);  # Select obs with missing county for state matching

## 2005 and 2006
df_ASEC_hh_match_0506_final = ASEC_ACS_match([2005, 2006], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);

## 2010 and 2011
df_ASEC_hh_match_1011_final = ASEC_ACS_match([2010, 2011], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);

## 2015 and 2016
df_ASEC_hh_match_1516_final = ASEC_ACS_match([2015, 2016], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);

## Save results

df_ASEC_hh_match_0506_save = select(df_ASEC_hh_match_0506_final, [:YEAR, :SERIAL, :statename, :ACS_proptax_mean, :ACS_proptax_median, :ACS_valueh_mean, :ACS_valueh_median, :ACS_rentgrs_mean, :ACS_rentgrs_median, :ACS_rent_mean, :ACS_rent_median]);
df_ASEC_hh_match_1011_save = select(df_ASEC_hh_match_1011_final, [:YEAR, :SERIAL, :statename, :ACS_proptax_mean, :ACS_proptax_median, :ACS_valueh_mean, :ACS_valueh_median, :ACS_rentgrs_mean, :ACS_rentgrs_median, :ACS_rent_mean, :ACS_rent_median]);
df_ASEC_hh_match_1516_save = select(df_ASEC_hh_match_1516_final, [:YEAR, :SERIAL, :statename, :ACS_proptax_mean, :ACS_proptax_median, :ACS_valueh_mean, :ACS_valueh_median, :ACS_rentgrs_mean, :ACS_rentgrs_median, :ACS_rent_mean, :ACS_rent_median]);

sort!(df_ASEC_hh_match_0506_save, [:YEAR, :SERIAL]);
sort!(df_ASEC_hh_match_1011_save, [:YEAR, :SERIAL]);
sort!(df_ASEC_hh_match_1516_save, [:YEAR, :SERIAL]);

CSV.write(dir_out * "ASEC_ACS_hh_match_0506.csv", df_ASEC_hh_match_0506_save);
CSV.write(dir_out * "ASEC_ACS_hh_match_1011.csv", df_ASEC_hh_match_1011_save);
CSV.write(dir_out * "ASEC_ACS_hh_match_1516.csv", df_ASEC_hh_match_1516_save);

#=
df_ASEC_hh_match_0506_save = select(df_ASEC_hh_match_0506_final, [:YEAR, :SERIAL, :statename, :dif_grossinc_mean, :dif_grossinc_median, :dif_size_mean, :dif_size_median, :dif_age_mean, :dif_age_median, :dif_unitsstr_mean, :dif_unitsstr_median, :dif_race_mean, :dif_race_median, :dif_educ_mean, :dif_educ_median, :dif_sex_mean, :dif_sex_median]);
df_ASEC_hh_match_1011_save = select(df_ASEC_hh_match_1011_final, [:YEAR, :SERIAL, :statename, :dif_grossinc_mean, :dif_grossinc_median, :dif_size_mean, :dif_size_median, :dif_age_mean, :dif_age_median, :dif_unitsstr_mean, :dif_unitsstr_median, :dif_race_mean, :dif_race_median, :dif_educ_mean, :dif_educ_median, :dif_sex_mean, :dif_sex_median]);
df_ASEC_hh_match_1516_save = select(df_ASEC_hh_match_1516_final, [:YEAR, :SERIAL, :statename, :dif_grossinc_mean, :dif_grossinc_median, :dif_size_mean, :dif_size_median, :dif_age_mean, :dif_age_median, :dif_unitsstr_mean, :dif_unitsstr_median, :dif_race_mean, :dif_race_median, :dif_educ_mean, :dif_educ_median, :dif_sex_mean, :dif_sex_median]);

sort!(df_ASEC_hh_match_0506_save, [:YEAR, :SERIAL]);
sort!(df_ASEC_hh_match_1011_save, [:YEAR, :SERIAL]);
sort!(df_ASEC_hh_match_1516_save, [:YEAR, :SERIAL]);

CSV.write(dir_out * "ASEC_ACS_hh_match_quality_0506.csv", df_ASEC_hh_match_0506_save);
CSV.write(dir_out * "ASEC_ACS_hh_match_quality_1011.csv", df_ASEC_hh_match_1011_save);
CSV.write(dir_out * "ASEC_ACS_hh_match_quality_1516.csv", df_ASEC_hh_match_1516_save);
=#

#=
## Plot for match quality

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

## Home Value - Income Plot ACS 2005/06

include(dir_functions * "inc_valueh_rentgrs_regressivity.jl");
fig2_dir_out = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Engel_curves/";

# A. ACS data
df_owners_mean = engel_owners_data_percentiles(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);
df_renters_mean = engel_renters_data_percentiles(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);

p1_mean = engel_plot(df_owners_mean, df_renters_mean, "Housing Engel Curves (ACS, 2010/2011)")

df_owners_median = engel_owners_data_percentiles_median(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);
df_renters_median = engel_renters_data_percentiles_median(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);

p1_median = engel_plot_median(df_owners_median, df_renters_median, "Housing Engel Curves (ACS, 2010/2011)")

df_owners = filter(r -> (r[:ownershp] .== 1), df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :]);
inc_vingtiles!(df_owners);
gdf_owners = groupby(df_owners, [:statename, :grossinc_vingtile]);
df_owners_mean = combine(gdf_owners, :grossinc => mean, :valueh => mean, :proptx99_recode => mean, nrow);
sort!(df_owners_mean, [:statename, :grossinc_vingtile]);

df_owners_mean[:, :log_grossinc_mean] = log.(df_owners_mean[:, :grossinc_mean]);
df_owners_mean[:, :log_valueh_mean]  = log.(df_owners_mean[:, :valueh_mean]);
df_owners_mean[:, :log_proptx_mean]  = log.(df_owners_mean[:, :proptx99_recode_mean]);

s1 = "New Jersey"
s2 = "Louisiana"

df_valueh_state, df_proptx_state = engel_owners_data_state(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1)

CSV.write(dir_out * "ACS_logvalueh_loginc.csv", df_valueh_state);
CSV.write(dir_out * "ACS_logproptx_loginc.csv", df_proptx_state);


vscodedisplay(df_proptx_state)
vscodedisplay(mean.(eachrow(df_proptx_state[:,2:4])) .- mean.(eachrow(df_proptx_state[:,(end-2):end])))

scatter(df_owners_mean[df_owners_mean.statename .== s1, :log_grossinc_mean], df_owners_mean[df_owners_mean.statename .== s1, :log_proptx_mean],
    label = s1,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    #xlim = (9,13),
    #ylim = (6,10),
    aspect_ratio=:equal)
scatter!(df_owners_mean[df_owners_mean.statename .== s2, :log_grossinc_mean], df_owners_mean[df_owners_mean.statename .== s2, :log_proptx_mean],
    label = s2,
    legend = :topleft,
    foreground_color_legend = nothing,
    xaxis="Log pre-government income",
    #xlim = (9,13),
    #ylim = (6,10),
    aspect_ratio=:equal)

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
df_owners_mean = engel_proptax_data(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);
p1_proptx = proptx_plot(df_owners_mean, "Property Tax Engel Curves (ACS, 2010/2011)")

df_owners_median = engel_proptax_data_median(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);
p1_proptx_median = proptx_plot_median(df_owners_median, "Property Tax Engel Curves (ACS, 2010/2011)")


# B. 1st matching
matching_set = [:grossinc, :size, :age, :unitsstr_recode, :race_recode, :educ_recode, :sex];
df_ASEC_hh_match_county.race_recode[df_ASEC_hh_match_county.race_recode .!= 1] .= 2;
df_ACS_hh_match_county.race_recode[df_ACS_hh_match_county.race_recode .!= 1] .= 2;
df_ASEC_hh_match_state.race_recode[df_ASEC_hh_match_state.race_recode .!= 1] .= 2;
df_ACS_hh_match_state.race_recode[df_ACS_hh_match_state.race_recode .!= 1] .= 2;

df_ASEC_hh_match_0506_final = ASEC_ACS_match([2010, 2011], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);

insertcols!(df_ASEC_hh_match_0506_final, size(df_ASEC_hh_match_0506_final, 2)+1, :valueh => df_ASEC_hh_match_0506_final.ACS_valueh_mean);
insertcols!(df_ASEC_hh_match_0506_final, size(df_ASEC_hh_match_0506_final, 2)+1, :rentgrs => df_ASEC_hh_match_0506_final.ACS_rentgrs_mean);
df_ASEC_hh_match_0506_final.valueh = df_ASEC_hh_match_0506_final.ACS_valueh_mean;
df_ASEC_hh_match_0506_final.rentgrs = df_ASEC_hh_match_0506_final.ACS_rentgrs_mean;
df_owners_mean = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final, 10);
df_renters_mean = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final, 10);

p2_mean = engel_plot_median(df_owners_mean, df_renters_mean, "Housing Engel Curves (ASEC ALL, 2010/2011)");

df_ASEC_hh_match_0506_final.valueh = df_ASEC_hh_match_0506_final.ACS_valueh_median;
df_ASEC_hh_match_0506_final.rentgrs = df_ASEC_hh_match_0506_final.ACS_rentgrs_median;
df_owners_median = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final, 10);
df_renters_median = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final, 10);

p2_median = engel_plot_median(df_owners_median, df_renters_median, "Housing Engel Curves (ASEC ALL, 2010/2011)");

insertcols!(df_ASEC_hh_match_0506_final, size(df_ASEC_hh_match_0506_final, 2)+1, :proptx99_recode => df_ASEC_hh_match_0506_final.ACS_proptax_median);
df_owners_median = engel_proptax_data_median(df_ASEC_hh_match_0506_final, 10);

p2_proptx = proptx_plot(df_owners_median, "Property Tax Engel Curves (ASEC ALL, 2010/2011)")


# C. 2nd matching - no recodes
matching_set = [:grossinc, :educ_recode, :unitsstr_recode];

df_ASEC_hh_match_0506_final2 = ASEC_ACS_match([2010, 2011], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);

insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :valueh => df_ASEC_hh_match_0506_final2.ACS_valueh_mean);
insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :rentgrs => df_ASEC_hh_match_0506_final2.ACS_rentgrs_mean);
insertcols!(df_ASEC_hh_match_0506_final2, size(df_ASEC_hh_match_0506_final2, 2)+1, :proptx99_recode => df_ASEC_hh_match_0506_final2.ACS_proptax_mean);

df_ASEC_hh_match_0506_final2.valueh = df_ASEC_hh_match_0506_final2.ACS_valueh_mean;
df_ASEC_hh_match_0506_final2.rentgrs = df_ASEC_hh_match_0506_final2.ACS_rentgrs_mean;
df_owners_mean = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final2, 10);
df_renters_mean = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final2, 10);
df_valueh_state_ASEC, df_proptx_state_ASEC = engel_owners_data_state(df_ASEC_hh_match_0506_final2, 10)

dif_valueh_state = df_valueh_state_ASEC[:, 2:end] .- df_valueh_state[:, 2:end]
insertcols!(dif_valueh_state, 1, :statename => df_valueh_state.statename);
dif_proptx_state = df_proptx_state_ASEC[:, 2:end] .- df_proptx_state[:, 2:end]
insertcols!(dif_proptx_state, 1, :statename => df_proptx_state.statename);

CSV.write(dir_out * "diff_ACS_ASEC_logvalueh_loginc k=9.csv", dif_valueh_state);
CSV.write(dir_out * "diff_ACS_ASEC_logproptx_loginc k=9.csv", dif_proptx_state);


p3_mean = engel_plot(df_owners_mean, df_renters_mean, "Housing Engel Curves (ASEC benchmark, 2010/2011)");

df_ASEC_hh_match_0506_final2.valueh = df_ASEC_hh_match_0506_final2.ACS_valueh_median;
df_ASEC_hh_match_0506_final2.rentgrs = df_ASEC_hh_match_0506_final2.ACS_rentgrs_median;
# df_owners_mean = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final2, 10);
# df_renters_mean = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final2, 10);
df_owners_median = engel_owners_data_percentiles_median(df_ASEC_hh_match_0506_final2, 10);
df_renters_median = engel_renters_data_percentiles_median(df_ASEC_hh_match_0506_final2, 10);

df_k1 = CSV.read("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/diff_ACS_ASEC_logproptx_loginc k=1.csv", DataFrame);
df_k9 = CSV.read("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/diff_ACS_ASEC_logproptx_loginc k=9.csv", DataFrame);

vscodedisplay(df_k1[:,2:end] .!= df_k9[:,2:end])

p3_median = engel_plot_median(df_owners_median, df_renters_median, "Housing Engel Curves (ASEC benchmark, 2010/2011)");

df_owners_mean = engel_proptax_data(df_ASEC_hh_match_0506_final2, 10);

proptx_plot(df_owners_mean, "Property Tax Engel Curves (ASEC benchmark, 2010/2011)")
p3_proptx = proptx_plot(df_owners_mean, "Property Tax Engel Curves (ASEC benchmark, 2010/2011)")

df_ASEC_hh_match_0506_final2.proptx99_recode = df_ASEC_hh_match_0506_final2.ACS_proptax_median;
df_owners_median = engel_proptax_data_median(df_ASEC_hh_match_0506_final2, 10);

proptx_plot_median(df_owners_median, "Property Tax Engel Curves (ASEC benchmark, 2010/2011)")
p3_proptx = proptx_plot_median(df_owners_median, "Property Tax Engel Curves (ASEC benchmark, 2010/2011)")

# D. 3rd matching - permanent income
matching_set = [:grossinc_potential];

df_ASEC_hh_match_0506_final3 = ASEC_ACS_match([2010, 2011], df_ASEC_hh_match_county, df_ACS_hh_match_county, df_ASEC_hh_match_state, df_ACS_hh_match_state, matching_set);

insertcols!(df_ASEC_hh_match_0506_final3, size(df_ASEC_hh_match_0506_final3, 2)+1, :valueh => df_ASEC_hh_match_0506_final3.ACS_valueh_mean);
insertcols!(df_ASEC_hh_match_0506_final3, size(df_ASEC_hh_match_0506_final3, 2)+1, :rentgrs => df_ASEC_hh_match_0506_final3.ACS_rentgrs_mean);
df_ASEC_hh_match_0506_final3.valueh = df_ASEC_hh_match_0506_final3.ACS_valueh_mean;
df_ASEC_hh_match_0506_final3.rentgrs = df_ASEC_hh_match_0506_final3.ACS_rentgrs_mean;
df_owners_mean = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final3, 10);
df_renters_mean = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final3, 10);

p4_mean = engel_plot_median(df_owners_mean, df_renters_mean, "Housing Engel Curves (ASEC perm. INC, 2010/2011)");

df_ASEC_hh_match_0506_final3.valueh = df_ASEC_hh_match_0506_final3.ACS_valueh_median;
df_ASEC_hh_match_0506_final3.rentgrs = df_ASEC_hh_match_0506_final3.ACS_rentgrs_median;
df_owners_median = engel_owners_data_percentiles(df_ASEC_hh_match_0506_final3, 10);
df_renters_median = engel_renters_data_percentiles(df_ASEC_hh_match_0506_final3, 10);

p4_median = engel_plot_median(df_owners_median, df_renters_median, "Housing Engel Curves (ASEC perm. INC, 2010/2011)");

insertcols!(df_ASEC_hh_match_0506_final3, size(df_ASEC_hh_match_0506_final3, 2)+1, :proptx99_recode => df_ASEC_hh_match_0506_final3.ACS_proptax_median);
df_owners_median = engel_proptax_data_median(df_ASEC_hh_match_0506_final3, 10);

p4_proptx = proptx_plot(df_owners_median, "Property Tax Engel Curves (ASEC only INC, 2010/2011)")


# Combine plots
plot(p1_mean, p2_mean, p3_mean, p4_mean, layout = (2,2), size = (1200,800))
savefig(fig2_dir_out * "Weighted_Mean_Engel_curve_ACS_new_benchmark_median_1011.pdf");

plot(p1_mean, p3_mean, layout = (2,1), size = (600,800))
savefig(fig2_dir_out * "Property_Tax_NEWcounty.pdf");


plot(p1_median, p2_median, p3_median, p4_median, layout = (2,2), size = (1200,800))
savefig(fig2_dir_out * "Demeaned_Weighted_Median_Engel_curve_ACS_new_benchmark_percentilesMedian_1011.pdf");

plot(p1_median, p3_median, layout = (2,1), size = (600,800))
savefig(fig2_dir_out * "k=1 median.pdf");

plot(p1_proptx_median, p3_proptx, layout = (2,1), size = (600,800))
savefig(fig2_dir_out * "Median_Property_tax_NEWcounty.pdf");


df_valueh_state_ACS, df_proptx_state_ACS = engel_owners_data_state(df_ACS_hh[in([2010, 2011]).(df_ACS_hh.YEAR), :], 1);
df_valueh_state_ASEC, df_proptx_state_ASEC = engel_owners_data_state(df_ASEC_hh_match_0506_final2, 10);

proptx_plot_compare!(df_proptx_state_ACS, df_proptx_state_ASEC, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/state engel k=9/")