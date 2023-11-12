### Write the function that fits property tax rate to income at county (wherever possible) and state level, and impute property tax
using FixedEffectModels
using RDatasets, DataFrames

# This is the function we use in current version
function fit_proptxrate_income!()
    years = [[2005,2006], [2010,2011], [2015,2016]]
    insertcols!(df_ACS_hh, :txrate => -1.0);
    df_ACS_hh[df_ACS_hh.ownershp .== 1.0, :txrate] .= df_ACS_hh[df_ACS_hh.ownershp .== 1.0, :proptx99_recode] ./ df_ACS_hh[df_ACS_hh.ownershp .== 1.0, :valueh]
    #df_ACS_hh[isnan.(df_ACS_hh.txrate), :txrate] .= missing
    df_ACS_hh[df_ACS_hh.txrate .== Inf, :txrate] .= NaN
    df_ACS_hh[df_ACS_hh.txrate .== -Inf, :txrate] .= NaN

    for year in years
        println(year)
        fm = @formula(txrate ~ grossinc_log + grossinc_log^2 + fe(county));
        #df_state = DataFrame(state = String[], county = Int[],n_rent = Float64[], n_owner = Int[], txrate = Float64[])

        for state in unique(df_ACS_hh.statename)
            #println(state)
            df_renters_tmp_state = df_ACS_hh[(in(year).(df_ACS_hh.YEAR)) .& (df_ACS_hh.ownershp .!= 1.0) .& (df_ACS_hh.statename .== state), :]
            df_owners_tmp_state = df_ACS_hh[(in(year).(df_ACS_hh.YEAR)) .& (df_ACS_hh.ownershp .== 1.0) .& (df_ACS_hh.statename .== state), :]

            #nyc_counties = [36081, 36005, 36061, 36047, 36085]
            #deleteat!(df_renters_tmp_state, in(nyc_counties).(df_renters_tmp_state.county))
            #deleteat!(df_owners_tmp_state, in(nyc_counties).(df_owners_tmp_state.county))
            regression = FixedEffectModels.reg(df_owners_tmp_state[(.!isnan.(df_owners_tmp_state.txrate)) .& (df_owners_tmp_state.txrate .< 1), :], fm, save = :fe)
            df_renters_tmp_state = leftjoin(df_renters_tmp_state, unique(regression.fe), on = :county)
            df_renters_tmp_state.txrate .= df_renters_tmp_state.fe_county .+ df_renters_tmp_state.grossinc_log .* regression.coef[1] .+ ((df_renters_tmp_state.grossinc_log).^2) .* regression.coef[2]
            select!(df_renters_tmp_state, Not(:fe_county))
            
            deleteat!(df_ACS_hh, (in(year).(df_ACS_hh.YEAR)) .& (df_ACS_hh.ownershp .!= 1.0) .& (df_ACS_hh.statename .== state))
            append!(df_ACS_hh, df_renters_tmp_state)
            #=
            for c in unique(df_owners_tmp_state.county)
                push!(df_state, [state, c, sum(df_renters_tmp_state.county .== c), sum(df_owners_tmp_state.county .== c), mean(df_owners_tmp_state[(.!isnan.(df_owners_tmp_state.txrate)) .& (df_owners_tmp_state.county .== c), :txrate])])
            end
            =#
        end
    end
end

# Below are archived versions

function fit_proptxrate_income_ASEC!()
    years = [[2005,2006], [2010,2011], [2015,2016]]
    insertcols!(df_ASEC_hh, :txrate => -1.0);
    df_ASEC_hh[df_ASEC_hh.ownershp .== 10.0, :txrate] .= df_ASEC_hh[df_ASEC_hh.ownershp .== 10.0, :proptx99_recode] ./ df_ASEC_hh[df_ASEC_hh.ownershp .== 10.0, :valueh]
    #df_ACS_hh[isnan.(df_ACS_hh.txrate), :txrate] .= missing
    df_ASEC_hh[df_ASEC_hh.txrate .== Inf, :txrate] .= NaN
    df_ASEC_hh[df_ASEC_hh.txrate .== -Inf, :txrate] .= NaN

    for year in years
        println(year)
        fm = @formula(txrate ~ grossinc_log + grossinc_log^2 + fe(county));
        #df_state = DataFrame(state = String[], county = Int[],n_rent = Float64[], n_owner = Int[], txrate = Float64[])

        for state in unique(df_ASEC_hh.statename)
            println(state)
            df_renters_tmp_state = df_ASEC_hh[(in(year).(df_ASEC_hh.YEAR)) .& (df_ASEC_hh.ownershp .!= 10.0) .& (df_ASEC_hh.statename .== state), :]
            df_owners_tmp_state = df_ASEC_hh[(in(year).(df_ASEC_hh.YEAR)) .& (df_ASEC_hh.ownershp .== 10.0) .& (df_ASEC_hh.statename .== state), :]

            #nyc_counties = [36081, 36005, 36061, 36047, 36085]
            #deleteat!(df_renters_tmp_state, in(nyc_counties).(df_renters_tmp_state.county))
            #deleteat!(df_owners_tmp_state, in(nyc_counties).(df_owners_tmp_state.county))
            regression = FixedEffectModels.reg(df_owners_tmp_state[(.!isnan.(df_owners_tmp_state.txrate)), :], fm, save = :fe)
            df_renters_tmp_state = leftjoin(df_renters_tmp_state, unique(regression.fe), on = :county)
            df_renters_tmp_state.txrate .= df_renters_tmp_state.fe_county .+ df_renters_tmp_state.grossinc_log .* regression.coef[1] .+ ((df_renters_tmp_state.grossinc_log).^2) .* regression.coef[2]
            select!(df_renters_tmp_state, Not(:fe_county))
            
            deleteat!(df_ASEC_hh, (in(year).(df_ASEC_hh.YEAR)) .& (df_ASEC_hh.ownershp .!= 10.0) .& (df_ASEC_hh.statename .== state))
            append!(df_ASEC_hh, df_renters_tmp_state)
            #=
            for c in unique(df_owners_tmp_state.county)
                push!(df_state, [state, c, sum(df_renters_tmp_state.county .== c), sum(df_owners_tmp_state.county .== c), mean(df_owners_tmp_state[(.!isnan.(df_owners_tmp_state.txrate)) .& (df_owners_tmp_state.county .== c), :txrate])])
            end
            =#
        end
    end
end

function fit_proptxrate_income_ASEC_old!()
    years = [[2005,2006], [2010,2011], [2015,2016]]
    insertcols!(df_ASEC_hh, :txrate => -1.0);
    df_ASEC_hh[df_ASEC_hh.ownershp .== 10.0, :txrate] .= df_ASEC_hh[df_ASEC_hh.ownershp .== 10.0, :proptx99_recode] ./ df_ASEC_hh[df_ASEC_hh.ownershp .== 10.0, :valueh]
    #df_ACS_hh[isnan.(df_ACS_hh.txrate), :txrate] .= missing
    df_ASEC_hh[df_ASEC_hh.txrate .== Inf, :txrate] .= NaN
    df_ASEC_hh[df_ASEC_hh.txrate .== -Inf, :txrate] .= NaN

    for year in years

        println(year)
        fm = @formula(txrate ~ grossinc_log + grossinc_log^2);

        for state in unique(df_ASEC_hh.statename)

            df_renters_tmp_state = df_ASEC_hh[(in(year).(df_ASEC_hh.YEAR)) .& (df_ASEC_hh.ownershp .!= 10.0) .& (df_ASEC_hh.statename .== state), :]
            df_owners_tmp_state = df_ASEC_hh[(in(year).(df_ASEC_hh.YEAR)) .& (df_ASEC_hh.ownershp .== 10.0) .& (df_ASEC_hh.statename .== state), :]

            deleteat!(df_ASEC_hh, (in(year).(df_ASEC_hh.YEAR)) .& (df_ASEC_hh.ownershp .!= 10.0) .& (df_ASEC_hh.county .== 0) .& (df_ASEC_hh.statename .== state));

            for county in unique(df_renters_tmp_state.county[df_renters_tmp_state.county .!= 0])

                df_renters_tmp = df_renters_tmp_state[df_renters_tmp_state.county .== county, :];
                df_owners_tmp = df_owners_tmp_state[df_owners_tmp_state.county .== county, :];

                if nrow(df_owners_tmp) < 30
                    printstyled(df_renters_tmp[1, :county_name_state_county] * "does not exsit among owners\n"; color = :red)
                    deleteat!(df_ASEC_hh, (in(year).(df_ASEC_hh.YEAR)) .& (df_ASEC_hh.ownershp .!= 10.0) .& (df_ASEC_hh.county .== county));
                    continue
                end

                regression = lm(fm, df_owners_tmp[.!isnan.(df_owners_tmp.txrate),:])
                df_ASEC_hh[(in(year).(df_ASEC_hh.YEAR)) .& (df_ASEC_hh.ownershp .!= 10.0) .& (df_ASEC_hh.county .== county), :txrate] .= predict(regression, df_renters_tmp);

                deleteat!(df_owners_tmp_state, df_owners_tmp_state.county .== county);
                deleteat!(df_renters_tmp_state, df_renters_tmp_state.county .== county);
            end

            if nrow(df_renters_tmp_state) == 0
                continue
            end

            regression = lm(fm, df_owners_tmp_state[.!isnan.(df_owners_tmp_state.txrate),:]);
            df_renters_tmp_state.txrate .= predict(regression, df_renters_tmp_state);

            append!(df_ASEC_hh, df_renters_tmp_state);

        end
    end
end
