
### Property Taxes for renters (based on GLVs procedure)

## Note: df_main_hh is the sample selected from ASEC

# 0. Run the matching file (match_ASEC_ACS_0506_1011_1516.jl) in folder 'Home owners' first
include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Home owners/match_ASEC_ACS_0506_1011_1516.jl");

## I: set input data
file_rent_paid = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/State_Zri_AllHomesPlusMultifamily_IMPORT.csv"
file_home_value = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/State_Zhvi_AllHomes_IMPORT.csv"

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

df_owners_mean = engel_owners_data_state(df_ASEC_owners, 10);
df_renters_mean = engel_renters_data_state(df_ASEC_renters, 10);

include("/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/proptx_owners_renters.jl");

proptx_owners_renters_states!(df_owners_mean, df_renters_mean, "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/Property tax by state/")
