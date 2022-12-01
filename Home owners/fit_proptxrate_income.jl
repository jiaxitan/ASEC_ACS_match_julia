### Write the function that fits property tax rate to income at county (wherever possible) and state level, and impute property tax
using FixedEffectModels
using RDatasets, DataFrames

function fit_proptxrate_income!()
    years = [[2005,2006], [2010,2011], [2015,2016]]
    insertcols!(df_ACS_hh, :txrate => -1.0);
    df_ACS_hh[df_ACS_hh.ownershp .== 1.0, :txrate] .= df_ACS_hh[df_ACS_hh.ownershp .== 1.0, :proptx99_recode] ./ df_ACS_hh[df_ACS_hh.ownershp .== 1.0, :valueh]

    for year in years
        fm = @formula(txrate ~ grossinc_log + grossinc_log^2);
        #df_state = DataFrame(state = String[], rent_to_own = Float64[], n_owner = Int[], pvalue = Float64[])

        df_ACS_renters = df_ACS_hh[(in(year).(df_ACS_hh.YEAR)) .& (df_ACS_hh.ownershp .!= 1.0), :]
        df_ACS_owners = df_ACS_hh[(in(year).(df_ACS_hh.YEAR)) .& (df_ACS_hh.ownershp .== 1.0), :]

        for state in unique(df_ACS_renters.statename)
            df_renters_tmp_state = df_ACS_renters[df_ACS_renters.statename .== state, :]
            df_owners_tmp_state = df_ACS_owners[df_ACS_owners.statename .== state, :]

            deleteat!(df_ACS_hh, (in(year).(df_ACS_hh.YEAR)) .& (df_ACS_hh.ownershp .!= 1.0) .& (df_ACS_hh.county .== 0) .& (df_ACS_hh.statename .== state));
            deleteat!(df_ACS_renters, (df_ACS_renters.county .== 0) .&& (df_ACS_renters.statename .== state));

            for county in unique(df_renters_tmp_state.county[df_renters_tmp_state.county .!= 0])

                df_renters_tmp = df_renters_tmp_state[df_renters_tmp_state.county .== county, :];
                df_owners_tmp = df_owners_tmp_state[df_owners_tmp_state.county .== county, :];
                #rent_own_ratio = nrow(df_renters_tmp)/nrow(df_owners_tmp)

                if nrow(df_owners_tmp) < 30
                    printstyled(df_renters_tmp[1, :county_name_state_county] * "does not exsit among owners\n"; color = :red)
                    deleteat!(df_ACS_renters, df_ACS_renters.county .== county);
                    deleteat!(df_ACS_hh, (in(year).(df_ACS_hh.YEAR)) .& (df_ACS_hh.ownershp .!= 1.0) .& (df_ACS_hh.county .== county));
                    continue
                end

                regression = lm(fm, df_owners_tmp)
                #push!(df_state, [state, rent_own_ratio, nrow(df_owners_tmp), coeftable(regression).cols[4][1]])
                df_ACS_hh[(in(year).(df_ACS_hh.YEAR)) .& (df_ACS_hh.ownershp .!= 1.0) .& (df_ACS_hh.county .== county), :txrate] .= predict(regression, df_renters_tmp);

                deleteat!(df_owners_tmp_state, df_owners_tmp_state.county .== county);
                deleteat!(df_renters_tmp_state, df_renters_tmp_state.county .== county);
            end

            if nrow(df_renters_tmp_state) == 0
                continue
            end

            regression = lm(fm, df_owners_tmp_state);
            #push!(df_state, [state, nrow(df_renters_tmp_state)/nrow(df_owners_tmp_state), nrow(df_owners_tmp_state), coeftable(regression).cols[4][1]])
            #df_ACS_hh[(df_ACS_hh.ownershp .!= 1.0) .& (df_ACS_hh.statename .== state), :txrate] .= predict(regression, df_renters_tmp_state);
            df_renters_tmp_state.txrate .= predict(regression, df_renters_tmp_state);

            append!(df_ACS_hh, df_renters_tmp_state);

        end
    end
end

function fit_proptxrate_income_ACS!()
    fm = @formula(txrate ~ grossinc_log + grossinc_log^2);
    insertcols!(df_ACS_renters, :txrate => -1.0);

    for state in unique(df_ACS_renters.statename)
        df_renters_tmp_state = df_ACS_renters[df_ACS_renters.statename .== state, :];
        df_owners_tmp_state = df_ACS_owners[df_ACS_owners.statename .== state, :];

        deleteat!(df_ACS_renters, (df_ACS_renters.county .== 0) .&& (df_ACS_renters.statename .== state));

        for county in unique(df_renters_tmp_state.county[df_renters_tmp_state.county .!= 0])
            county = unique(df_renters_tmp_state.county[df_renters_tmp_state.county .!= 0])[1]

            df_renters_tmp = df_renters_tmp_state[df_renters_tmp_state.county .== county, :];
            df_owners_tmp = df_owners_tmp_state[df_owners_tmp_state.county .== county, :];

            if nrow(df_owners_tmp) < 30
                printstyled(df_renters_tmp[1, :county_name_state_county] * "does not exsit among owners\n"; color = :red)
                deleteat!(df_ACS_renters, df_ACS_renters.county .== county);
                continue
            end

            regression = lm(fm, df_owners_tmp[df_owners_tmp.txrate .!=0,:])
            df_ACS_renters[df_ACS_renters.county .== county, :txrate] .= predict(regression, df_renters_tmp);

            deleteat!(df_owners_tmp_state, df_owners_tmp_state.county .== county);
            deleteat!(df_renters_tmp_state, df_renters_tmp_state.county .== county);
        end

        if nrow(df_renters_tmp_state) == 0
            continue
        end

        regression = lm(fm, df_owners_tmp_state[df_owners_tmp_state.txrate .!=0,:]);
        df_renters_tmp_state.txrate .= predict(regression, df_renters_tmp_state);

        append!(df_ACS_renters, df_renters_tmp_state);

    end
end
