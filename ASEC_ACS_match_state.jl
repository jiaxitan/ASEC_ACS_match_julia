
function ASEC_ACS_match_state!(df_ASEC, df_ACS, k)

    sort!(df_ASEC, :county); sort!(df_ACS, :county);
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ASEC_id => collect(1:size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_proptax_mean => -2 .* ones(size(df_ASEC,1))); insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_proptax_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_valueh_mean  => -2 .* ones(size(df_ASEC,1))); insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_valueh_median  => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_rentgrs_mean => -2 .* ones(size(df_ASEC,1))); insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_rentgrs_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_rent_mean => -2 .* ones(size(df_ASEC,1)));    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_rent_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_grossinc_mean => -2 .* ones(size(df_ASEC,1))); insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_grossinc_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_size_mean  => -2 .* ones(size(df_ASEC,1))); insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_size_median  => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_age_mean => -2 .* ones(size(df_ASEC,1))); insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_age_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_race_mean => -2 .* ones(size(df_ASEC,1)));    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_race_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_educ_mean => -2 .* ones(size(df_ASEC,1)));    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_educ_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_sex_mean => -2 .* ones(size(df_ASEC,1)));    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_sex_median => -2 .* ones(size(df_ASEC,1)));

    for (asec_state_idx, asec_state) in enumerate(unique(df_ASEC.statename))

        df_ASEC_tmp = filter(r -> (r[:statename] .== asec_state), df_ASEC)
        df_ACS_tmp  = filter(r -> (r[:statename] .== asec_state), df_ACS)

        #array_ASEC_tmp0 = convert.(Float64, Array(select(df_ASEC_tmp, [:ownershp, :grossinc, :grossinc_potential, :size, :age, :race_recode, :educ_recode, :sex, :ASEC_id])))
        #array_ACS_tmp0  = convert.(Float64, Array(select(df_ACS_tmp,  [:ownershp, :grossinc, :grossinc_potential, :size, :age, :race_recode, :educ_recode, :sex, :proptx99_recode, :valueh, :rentgrs, :rent])))

        array_ASEC_tmp0 = convert.(Float64, Array(select(df_ASEC_tmp, [:ownershp, :grossinc, :size, :age, :race_recode, :educ_recode, :sex, :ASEC_id])))
        array_ACS_tmp0  = convert.(Float64, Array(select(df_ACS_tmp,  [:ownershp, :grossinc, :size, :age, :race_recode, :educ_recode, :sex, :proptx99_recode, :valueh, :rentgrs, :rent])))

        for j = 1:2 # Owners and renters

            j == 1 ? array_ASEC_tmp = array_ASEC_tmp0[array_ASEC_tmp0[:,1] .== 10.0, 2:end] : array_ASEC_tmp = array_ASEC_tmp0[array_ASEC_tmp0[:,1] .!= 10.0, 2:end]
            j == 1 ? array_ACS_tmp = array_ACS_tmp0[array_ACS_tmp0[:,1] .== 1.0, 2:end] : array_ACS_tmp = array_ACS_tmp0[array_ACS_tmp0[:,1] .!= 1.0, 2:end]

            if j == 1 && size(array_ACS_tmp,1) < k
                printstyled(df_ASEC_tmp[1, :statename] * " has less than " * string(k) * " owners in ACS\n"; color = :red)
                continue
            end

            if j == 2 && size(array_ACS_tmp,1) < k
                printstyled(df_ASEC_tmp[1, :statename] * " has less than " * string(k) * " renters in ACS\n"; color = :red)
                continue
            end

            array_ACS_tmp_transpose = convert(Array, transpose(array_ACS_tmp[:, 1:6]))
            kdtree_county = KDTree(array_ACS_tmp_transpose)

            for i = 1:size(array_ASEC_tmp, 1)
                ASEC_obs = array_ASEC_tmp[i, 1:6]
                idxs, dists = knn(kdtree_county, ASEC_obs, k)
                    #println(df_ASEC_tmp[1, :county_name_state_county] * " " * string(j) * " " * string(i))
                ASEC_obs_id = convert(Int64, array_ASEC_tmp[i, 7])
                i_df_ASEC = findfirst(x -> (x == ASEC_obs_id), df_ASEC.ASEC_id)
                if j == 1
                    df_ASEC[i_df_ASEC, :ACS_proptax_mean] = mean(array_ACS_tmp[idxs, 7]); df_ASEC[i_df_ASEC, :ACS_proptax_median] = median(array_ACS_tmp[idxs, 7]);
                    df_ASEC[i_df_ASEC, :ACS_valueh_mean]  = mean(array_ACS_tmp[idxs, 8]); df_ASEC[i_df_ASEC, :ACS_valueh_median]  = median(array_ACS_tmp[idxs, 8]);
                else
                    df_ASEC[i_df_ASEC, :ACS_rentgrs_mean] = mean(array_ACS_tmp[idxs, 9]); df_ASEC[i_df_ASEC, :ACS_rentgrs_median] = median(array_ACS_tmp[idxs, 9]);
                    df_ASEC[i_df_ASEC, :ACS_rent_mean]    = mean(array_ACS_tmp[idxs, 10]); df_ASEC[i_df_ASEC, :ACS_rent_median]    = median(array_ACS_tmp[idxs, 10]);
                end
                df_ASEC[i_df_ASEC, :dif_grossinc_mean] = df_ASEC[i_df_ASEC, :grossinc] - mean(array_ACS_tmp[idxs, 2]); df_ASEC[i_df_ASEC, :dif_grossinc_median] = df_ASEC[i_df_ASEC, :grossinc] - median(array_ACS_tmp[idxs, 2]);
                df_ASEC[i_df_ASEC, :dif_size_mean] = df_ASEC[i_df_ASEC, :size] - mean(array_ACS_tmp[idxs, 3]); df_ASEC[i_df_ASEC, :dif_size_median] = df_ASEC[i_df_ASEC, :size] - median(array_ACS_tmp[idxs, 3]);
                df_ASEC[i_df_ASEC, :dif_age_mean] = df_ASEC[i_df_ASEC, :age] - mean(array_ACS_tmp[idxs, 4]); df_ASEC[i_df_ASEC, :dif_age_median] = df_ASEC[i_df_ASEC, :age] - median(array_ACS_tmp[idxs, 4]);
                df_ASEC[i_df_ASEC, :dif_race_mean] = df_ASEC[i_df_ASEC, :race_recode] - mean(array_ACS_tmp[idxs, 5]); df_ASEC[i_df_ASEC, :dif_race_median] = df_ASEC[i_df_ASEC, :race_recode] - median(array_ACS_tmp[idxs, 5]);
                df_ASEC[i_df_ASEC, :dif_educ_mean] = df_ASEC[i_df_ASEC, :educ_recode] - mean(array_ACS_tmp[idxs, 6]); df_ASEC[i_df_ASEC, :dif_educ_median] = df_ASEC[i_df_ASEC, :educ_recode] - median(array_ACS_tmp[idxs, 6]);
                df_ASEC[i_df_ASEC, :dif_sex_mean] = df_ASEC[i_df_ASEC, :sex] - mean(array_ACS_tmp[idxs, 7]); df_ASEC[i_df_ASEC, :dif_sex_median] = df_ASEC[i_df_ASEC, :sex] - median(array_ACS_tmp[idxs, 7]);
            end

        end

    end

end
