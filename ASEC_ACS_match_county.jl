
# NOTE: output codes
# -1: ASEC county not identified in ACS
# -2: ACS has less than k owners (or renters) in ASEC county

function ASEC_ACS_match_county!(df_ASEC, df_ACS, k, matching_elements)

    sort!(df_ASEC, :county); sort!(df_ACS, :county);
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ASEC_id => collect(1:size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_proptax_mean => -2 .* ones(size(df_ASEC,1)));  insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_proptax_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_valueh_mean  => -2 .* ones(size(df_ASEC,1)));  insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_valueh_median  => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_rentgrs_mean => -2 .* ones(size(df_ASEC,1)));  insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_rentgrs_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_rent_mean => -2 .* ones(size(df_ASEC,1)));     insertcols!(df_ASEC, size(df_ASEC,2)+1, :ACS_rent_median => -2 .* ones(size(df_ASEC,1)));
    #=
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_grossinc_mean => -2 .* ones(size(df_ASEC,1))); insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_grossinc_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_size_mean  => -2 .* ones(size(df_ASEC,1)));    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_size_median  => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_age_mean => -2 .* ones(size(df_ASEC,1)));      insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_age_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_unitsstr_mean => -2 .* ones(size(df_ASEC,1))); insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_unitsstr_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_race_mean => -2 .* ones(size(df_ASEC,1)));     insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_race_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_educ_mean => -2 .* ones(size(df_ASEC,1)));     insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_educ_median => -2 .* ones(size(df_ASEC,1)));
    insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_sex_mean => -2 .* ones(size(df_ASEC,1)));      insertcols!(df_ASEC, size(df_ASEC,2)+1, :dif_sex_median => -2 .* ones(size(df_ASEC,1)));
    =#
    
    ASEC_mean = mean.(eachcol(df_ASEC[:, matching_elements]));
    ASEC_std = std.(eachcol(df_ASEC[:, matching_elements]))
    ASEC_std[ASEC_std .== 0] .= 1;
    ACS_mean = mean.(eachcol(df_ACS[:, matching_elements]));
    ACS_std = std.(eachcol(df_ACS[:, matching_elements]));
    ACS_std[ACS_std .== 0] .= 1;
    
   for (asec_county_idx, asec_county) in enumerate(unique(df_ASEC.county))
        df_ASEC_tmp = filter(r -> (r[:county] .== asec_county), df_ASEC)
        df_ACS_tmp  = filter(r -> (r[:county] .== asec_county), df_ACS)
        if isempty(df_ACS_tmp)
            printstyled(df_ASEC_tmp[1, :county_name_state_county] * " : not identified in ACS\n"; color = :red)
                for i = 1:size(df_ASEC_tmp,1)
                    ASEC_obs_id = convert(Int64, df_ASEC_tmp[i, :ASEC_id])
                    i_df_ASEC = findfirst(x -> (x == ASEC_obs_id), df_ASEC.ASEC_id)
                    df_ASEC[i_df_ASEC, :ACS_proptax_mean] = -1; df_ASEC[i_df_ASEC, :ACS_proptax_median] = -1;
                    df_ASEC[i_df_ASEC, :ACS_valueh_mean]  = -1; df_ASEC[i_df_ASEC, :ACS_valueh_median]  = -1;
                    df_ASEC[i_df_ASEC, :ACS_rentgrs_mean] = -1; df_ASEC[i_df_ASEC, :ACS_rentgrs_median] = -1;
                    df_ASEC[i_df_ASEC, :ACS_rent_mean]    = -1; df_ASEC[i_df_ASEC, :ACS_rent_median]    = -1;
                end
            continue
        end

        #array_ASEC_tmp0 = convert.(Float64, Array(select(df_ASEC_tmp, [:ownershp, :grossinc, :grossinc_potential, :size, :age, :race_recode, :educ_recode, :sex, :ASEC_id])))
        #array_ACS_tmp0  = convert.(Float64, Array(select(df_ACS_tmp,  [:ownershp, :grossinc, :grossinc_potential, :size, :age, :race_recode, :educ_recode, :sex, :proptx99_recode, :valueh, :rentgrs, :rent])))
        
        array_ASEC_tmp0 = convert.(Float64, Array(select(df_ASEC_tmp, vcat([:ownershp, :ASEC_id], matching_elements))))
        array_ACS_tmp0  = convert.(Float64, Array(select(df_ACS_tmp,  vcat([:ownershp, :proptx99_recode, :valueh, :rentgrs, :rent], matching_elements))))

        for j = 1:2 # Owners and renters
            j == 1 ? array_ASEC_tmp = array_ASEC_tmp0[array_ASEC_tmp0[:,1] .== 10.0, 2:end] : array_ASEC_tmp = array_ASEC_tmp0[array_ASEC_tmp0[:,1] .!= 10.0, 2:end]
            j == 1 ? array_ACS_tmp = array_ACS_tmp0[array_ACS_tmp0[:,1] .== 1.0, 2:end] : array_ACS_tmp = array_ACS_tmp0[array_ACS_tmp0[:,1] .!= 1.0, 2:end]

            if j == 1 && size(array_ACS_tmp,1) < k
                printstyled(df_ASEC_tmp[1, :county_name_state_county] * " has less than " * string(k) * " owners in ACS\n"; color = :red)
                continue
            end

            if j == 2 && size(array_ACS_tmp,1) < k
                printstyled(df_ASEC_tmp[1, :county_name_state_county] * " has less than " * string(k) * " renters in ACS\n"; color = :red)
                continue
            end

            array_ASEC_tmp[:, 2:end] = array_ASEC_tmp[:, 2:end] ./transpose(ASEC_std);
            array_ACS_tmp[:, 5:end] = array_ACS_tmp[:, 5:end] ./transpose(ACS_std);

            array_ACS_tmp_transpose = convert(Array, transpose(array_ACS_tmp[:, 5:end]))
            kdtree_county = KDTree(array_ACS_tmp_transpose)

            for i = 1:size(array_ASEC_tmp, 1)
                ASEC_obs = array_ASEC_tmp[i, 2:end]
                idxs, dists = knn(kdtree_county, ASEC_obs, k)
                    #println(df_ASEC_tmp[1, :county_name_state_county] * " " * string(j) * " " * string(i))
                ASEC_obs_id = convert(Int64, array_ASEC_tmp[i, 1])
                i_df_ASEC = findfirst(x -> (x == ASEC_obs_id), df_ASEC.ASEC_id)
                if j == 1
                    df_ASEC[i_df_ASEC, :ACS_proptax_mean] = mean(array_ACS_tmp[idxs, 1]); df_ASEC[i_df_ASEC, :ACS_proptax_median] = median(array_ACS_tmp[idxs, 1]);
                    df_ASEC[i_df_ASEC, :ACS_valueh_mean]  = mean(array_ACS_tmp[idxs, 2]); df_ASEC[i_df_ASEC, :ACS_valueh_median]  = median(array_ACS_tmp[idxs, 2]);
                else
                    df_ASEC[i_df_ASEC, :ACS_rentgrs_mean] = mean(array_ACS_tmp[idxs, 3]); df_ASEC[i_df_ASEC, :ACS_rentgrs_median] = median(array_ACS_tmp[idxs, 3]);
                    df_ASEC[i_df_ASEC, :ACS_rent_mean]    = mean(array_ACS_tmp[idxs, 4]); df_ASEC[i_df_ASEC, :ACS_rent_median]    = median(array_ACS_tmp[idxs, 4]);
                end
                #=
                df_ASEC[i_df_ASEC, :dif_grossinc_mean] = mean(array_ACS_tmp[idxs, 1]) - df_ASEC[i_df_ASEC, :grossinc];          df_ASEC[i_df_ASEC, :dif_grossinc_median] = median(array_ACS_tmp[idxs, 1]) - df_ASEC[i_df_ASEC, :grossinc];
                df_ASEC[i_df_ASEC, :dif_size_mean] = mean(array_ACS_tmp[idxs, 2]) - df_ASEC[i_df_ASEC, :size];                  df_ASEC[i_df_ASEC, :dif_size_median] = median(array_ACS_tmp[idxs, 2]) - df_ASEC[i_df_ASEC, :size];
                df_ASEC[i_df_ASEC, :dif_age_mean] = mean(array_ACS_tmp[idxs, 3]) - df_ASEC[i_df_ASEC, :age];                    df_ASEC[i_df_ASEC, :dif_age_median] = median(array_ACS_tmp[idxs, 3]) - df_ASEC[i_df_ASEC, :age];
                df_ASEC[i_df_ASEC, :dif_unitsstr_mean] = mean(array_ACS_tmp[idxs, 4]) - df_ASEC[i_df_ASEC, :unitsstr_recode];   df_ASEC[i_df_ASEC, :dif_unitsstr_median] = median(array_ACS_tmp[idxs, 4]) - df_ASEC[i_df_ASEC, :unitsstr_recode];
                df_ASEC[i_df_ASEC, :dif_race_mean] = mean(array_ACS_tmp[idxs, 5]) - df_ASEC[i_df_ASEC, :race_recode];           df_ASEC[i_df_ASEC, :dif_race_median] = median(array_ACS_tmp[idxs, 5]) - df_ASEC[i_df_ASEC, :race_recode];
                df_ASEC[i_df_ASEC, :dif_educ_mean] = mean(array_ACS_tmp[idxs, 6]) - df_ASEC[i_df_ASEC, :educ_recode];           df_ASEC[i_df_ASEC, :dif_educ_median] = median(array_ACS_tmp[idxs, 6]) - df_ASEC[i_df_ASEC, :educ_recode];
                df_ASEC[i_df_ASEC, :dif_sex_mean] = mean(array_ACS_tmp[idxs, 7]) - df_ASEC[i_df_ASEC, :sex];                    df_ASEC[i_df_ASEC, :dif_sex_median] = median(array_ACS_tmp[idxs, 7]) - df_ASEC[i_df_ASEC, :sex];
                =#
            end
        end

    end

end
