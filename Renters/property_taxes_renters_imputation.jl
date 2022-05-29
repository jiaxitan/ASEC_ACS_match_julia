
### Property Taxes for renters (based on GLVs procedure)

## Note: df_main_hh is the sample selected from ASEC

using CSV
using DataFrames

## 0. Define CE income groups
const inc_cutoffs = 1000*[5, 10, 15, 20, 30, 40, 50, 70, 80, 100, 120, 150];
function inc_group(y::Int64)::Int64
    if (y >= 0) && (y < inc_cutoffs[1])
        return 1
    elseif (y >= inc_cutoffs[1]) && (y < inc_cutoffs[2])
        return 2
    elseif (y >= inc_cutoffs[2]) && (y < inc_cutoffs[3])
        return 3
    elseif (y >= inc_cutoffs[3]) && (y < inc_cutoffs[4])
        return 4
    elseif (y >= inc_cutoffs[4]) && (y < inc_cutoffs[5])
        return 5
    elseif (y >= inc_cutoffs[5]) && (y < inc_cutoffs[6])
        return 6
    elseif (y >= inc_cutoffs[6]) && (y < inc_cutoffs[7])
        return 7
    elseif (y >= inc_cutoffs[7]) && (y < inc_cutoffs[8])
        return 8
    elseif (y >= inc_cutoffs[8]) && (y < inc_cutoffs[9])
        return 9
    elseif (y >= inc_cutoffs[9]) && (y < inc_cutoffs[10])
        return 10
    elseif (y >= inc_cutoffs[10]) && (y < inc_cutoffs[11])
        return 11
    elseif (y >= inc_cutoffs[11]) && (y < inc_cutoffs[12])
        return 12
    else
        return 13
    end
end


## I: set input data

file_property_taxes_renters_2005 = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/imputed_prop_tax_renters_2005.csv";
file_property_taxes_renters_2006 = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/imputed_prop_tax_renters_2006.csv";


## II: Import and prepare property taxes for renters

df_property_taxes_renters_2005 = CSV.read(file_property_taxes_renters_2005, DataFrame; types=[String, Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64]);
df_property_taxes_renters_2006 = CSV.read(file_property_taxes_renters_2006, DataFrame; types=[String, Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64,Float64]);

N_states = 51;

df_renters_proptaxes_2005 = stack(df_property_taxes_renters_2005, Not(:Column1), :Column1);
dropmissing!(df_renters_proptaxes_2005, :Column1);
insertcols!(df_renters_proptaxes_2005, 3, :CE_inc_group => repeat(1:13,inner=N_states,outer=1));
select!(df_renters_proptaxes_2005, Not(:variable));
rename!(df_renters_proptaxes_2005, ["statename", "CE_inc_group", "proptax_renter_imputed"]);
insertcols!(df_renters_proptaxes_2005, 4, :YEAR => repeat([2005], N_states*13));

df_renters_proptaxes_2005_2006 = stack(df_property_taxes_renters_2006, Not(:Column1), :Column1);
dropmissing!(df_renters_proptaxes_2005_2006, :Column1);
insertcols!(df_renters_proptaxes_2005_2006, 3, :CE_inc_group => repeat(1:13,inner=N_states,outer=1));
select!(df_renters_proptaxes_2005_2006, Not(:variable));
rename!(df_renters_proptaxes_2005_2006, ["statename", "CE_inc_group", "proptax_renter_imputed"]);
insertcols!(df_renters_proptaxes_2005_2006, 4, :YEAR => repeat([2006], N_states*13));

append!(df_renters_proptaxes_2005_2006, df_renters_proptaxes_2005);


## III Impute property taxes for renters (ownershp 1: owner; 2:renter)

# Set function and output directory + ASEC, ACS, state info files
dir_functions   = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Home owners/";
file_ASEC       = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/cps_00002.csv";
file_ACS        = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/usa_00010.csv";
file_state_info = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/states_fips_names.csv";
dir_out         = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/";
fig_dir_out     = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Match Quality/";
    
# Prepare ACS and ASEC data
# Potential income regressions are muted for speed, since we are not using potential income for now
include(dir_functions * "ACS_ASEC_data_preparation.jl");
include(dir_functions * "ACS_ASEC_selection_sampleB.jl");
include(dir_functions * "ACS_ASEC_inc_earned_person.jl");

include(dir_functions * "ASEC_UNITSSTR_recode.jl");
include(dir_functions * "ASEC_EDUC_recode.jl");
include(dir_functions * "ASEC_RACE_recode.jl");
include(dir_functions * "ASEC_MARST_recode.jl");
include(dir_functions * "ASEC_COUNTY_recode.jl");
include(dir_functions * "ASEC_METRO_recode.jl");

include(dir_functions * "ACS_UNITSSTR_recode.jl");
include(dir_functions * "ACS_METRO_recode.jl");
include(dir_functions * "ACS_RACE_recode.jl");
include(dir_functions * "ACS_EDUC_recode.jl");
include(dir_functions * "ACS_MARST_recode.jl");
include(dir_functions * "ACS_PROPTX99_recode.jl");
include(dir_functions * "ACS_COUNTY_2005_onwards_recode.jl");
include(dir_functions * "ACS_match_PUMA_county.jl");
    #include("/Users/main/Documents/GitHubRepos/julia_utils/ACS_COUNTY_2005_2006_recode.jl")

df_ACS_hh, df_ASEC_hh = prepare_data();

# Merge imputed property taxes for renters
df_main_hh = df_ACS_hh[in([2005, 2006]).(df_ACS_hh.YEAR), :];
insertcols!(df_main_hh, :CE_inc_group => inc_group.(df_main_hh.grossinc));

df_main_hh_prop_taxes_renters_tmp = filter(row -> (row[:ownershp] == 2), df_main_hh);
df_main_hh_prop_taxes_renters = innerjoin(df_renters_proptaxes_2005_2006, df_main_hh_prop_taxes_renters_tmp, on = [:YEAR, :statename, :CE_inc_group]);

#select!(df_main_hh_prop_taxes_renters, Not(:proptax)); # drop owner property tax variable
rename!(df_main_hh_prop_taxes_renters, :proptax_renter_imputed => :proptax); # rename imputed renter property tax variable

# Merge back with owners
df_main_hh_imputed_renter_property_taxes = filter(row -> (row[:ownershp] == 1), df_main_hh);
append!(df_main_hh_imputed_renter_property_taxes, df_main_hh_prop_taxes_renters);
rename!(df_main_hh_imputed_renter_property_taxes, :proptax => :proptax_baseline);
