### Write the function that fits property tax rate to income at county (wherever possible) and state level, and impute property tax


function fit_proptxrate_income!()
    fm = @formula(txrate ~ grossinc_log + grossinc_log^2);
    insertcols!(df_ASEC_renters, :txrate => -1.0);

    for state in unique(df_ASEC_renters.statename)
        df_renters_tmp_state = df_ASEC_renters[df_ASEC_renters.statename .== state, :];
        df_owners_tmp_state = df_ASEC_owners[df_ASEC_owners.statename .== state, :]

        deleteat!(df_ASEC_renters, (df_ASEC_renters.county .== 0) .&& (df_ASEC_renters.statename .== state));

        for county in unique(df_renters_tmp_state.county[df_renters_tmp_state.county .!= 0])
            df_renters_tmp = df_renters_tmp_state[df_renters_tmp_state.county .== county, :];
            df_owners_tmp = df_owners_tmp_state[df_owners_tmp_state.county .== county, :];

            if nrow(df_owners_tmp) < 30
                printstyled(df_renters_tmp[1, :county_name_state_county] * "does not exsit among owners\n"; color = :red)
                deleteat!(df_ASEC_renters, df_ASEC_renters.county .== county);
                continue
            end

            regression = lm(fm, df_owners_tmp);
            df_ASEC_renters[df_ASEC_renters.county .== county, :txrate] .= predict(regression, df_renters_tmp);

            deleteat!(df_owners_tmp_state, df_owners_tmp_state.county .== county);
            deleteat!(df_renters_tmp_state, df_renters_tmp_state.county .== county);
        end

        if nrow(df_renters_tmp_state) == 0
            continue
        end

        regression = lm(fm, df_owners_tmp_state);
        df_renters_tmp_state.txrate .= predict(regression, df_renters_tmp_state);

        append!(df_ASEC_renters, df_renters_tmp_state);

    end
end

function fit_proptxrate_income_ACS!()
    fm = @formula(txrate ~ grossinc_log + grossinc_log^2);
    insertcols!(df_ACS_renters, :txrate => -1.0);

    for state in unique(df_ACS_renters.statename)
        df_renters_tmp_state = df_ACS_renters[df_ACS_renters.statename .== state, :];
        df_owners_tmp_state = df_ACS_owners[df_ACS_owners.statename .== state, :]

        deleteat!(df_ACS_renters, (df_ACS_renters.county .== 0) .&& (df_ACS_renters.statename .== state));

        for county in unique(df_renters_tmp_state.county[df_renters_tmp_state.county .!= 0])
            df_renters_tmp = df_renters_tmp_state[df_renters_tmp_state.county .== county, :];
            df_owners_tmp = df_owners_tmp_state[df_owners_tmp_state.county .== county, :];

            if nrow(df_owners_tmp) < 30
                printstyled(df_renters_tmp[1, :county_name_state_county] * "does not exsit among owners\n"; color = :red)
                deleteat!(df_ACS_renters, df_ACS_renters.county .== county);
                continue
            end

            regression = lm(fm, df_owners_tmp);
            df_ACS_renters[df_ACS_renters.county .== county, :txrate] .= predict(regression, df_renters_tmp);

            deleteat!(df_owners_tmp_state, df_owners_tmp_state.county .== county);
            deleteat!(df_renters_tmp_state, df_renters_tmp_state.county .== county);
        end

        if nrow(df_renters_tmp_state) == 0
            continue
        end

        regression = lm(fm, df_owners_tmp_state);
        df_renters_tmp_state.txrate .= predict(regression, df_renters_tmp_state);

        append!(df_ACS_renters, df_renters_tmp_state);

    end
end
