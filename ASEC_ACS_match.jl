
function ASEC_ACS_match(year, df_ASEC_county, df_ACS_county, df_ASEC_state, df_ACS_state, matching_set)

    df_ASEC_hh_county = df_ASEC_county[in(year).(df_ASEC_county.YEAR), :];
    df_ASEC_hh_state = df_ASEC_state[in(year).(df_ASEC_state.YEAR), :];

    df_ACS_hh_county = df_ACS_county[in(year).(df_ACS_county.YEAR), :];
    df_ACS_hh_state = df_ACS_state[in(year).(df_ACS_state.YEAR), :];

    # 1. ASEC observations with identified county -> match to ACS obs in same county
    ASEC_ACS_match_county!(df_ASEC_hh_county, df_ACS_hh_county, k_NN, matching_set)

    # 2. Merge unmatched county observations with state level matching
    df_ASEC_hh_county_unmatched = filter(r -> (r[:ACS_proptax_mean] .== -1), df_ASEC_hh_county);
    filter!(r -> (r[:ACS_proptax_mean] .!= -1), df_ASEC_hh_county);
    df_ASEC_hh_county_matched_counties = unique(df_ASEC_hh_county.county);
    select!(df_ASEC_hh_county_unmatched, Not([:ASEC_id, :ACS_proptax_mean, :ACS_proptax_median, :ACS_valueh_mean, :ACS_valueh_median, :ACS_rentgrs_mean, :ACS_rentgrs_median, :ACS_rent_mean, :ACS_rent_median]));
    #select!(df_ASEC_hh_county_unmatched, Not([:dif_grossinc_mean, :dif_grossinc_median, :dif_size_mean, :dif_size_median, :dif_age_mean, :dif_age_median, :dif_unitsstr_mean, :dif_unitsstr_median, :dif_race_mean, :dif_race_median, :dif_educ_mean, :dif_educ_median, :dif_sex_mean, :dif_sex_median]));
    append!(df_ASEC_hh_state, df_ASEC_hh_county_unmatched);
    append!(df_ACS_hh_state, df_ACS_hh_county[.!in(df_ASEC_hh_county_matched_counties).(df_ACS_hh_county.county),:]);
    ASEC_ACS_match_state!(df_ASEC_hh_state, df_ACS_hh_state, k_NN, matching_set)

    df_ASEC_hh_match_final = vcat(df_ASEC_hh_county, df_ASEC_hh_state); 

    return df_ASEC_hh_match_final
end