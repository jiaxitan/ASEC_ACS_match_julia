### Prepare ACS and ASEC data for matching

# If ASEC county known      -> use same county (if in ACS, otherwise treat as ASEC county not known)
# If ASEC county not known  -> match to all ACS obs in the same ASEC state

# For ASEC owners: get home value and property taxes
# For ASEC renters: get rent and gross rent paid
# NOTE: for ACS, split potential earnings regression by years to speed up/avoid crashes

function prepare_data(sample::String)

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

    # Distinguish reference years and survey years
    # So :YEAR is reference year, and :YEAR_survey is the corresponding survey year
    insertcols!(df_ASEC, :YEAR_survey => df_ASEC.YEAR)
    df_ASEC.YEAR = df_ASEC.YEAR .- 1

    # Apply FHSV sample selection
    insertcols!(df_ASEC, :YEAR_reference => df_ASEC.YEAR)
    df_ASEC_sample = ACS_ASEC_sample_selection_FHSV(df_ASEC, sample);


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
    df_ASEC_hh.YEAR_survey = df_ASEC_hh.YEAR .+ 1

    #= 
    # Potential Earnings Regression using FE package -> fast
    ols_potential_earnings_ASEC_fe = reg(df_ASEC_hh, @formula(grossinc_log ~ YEAR + earners + age + age^2 + sex + marst_recode + race_recode + educ_recode + ind + occ + age&educ_recode + age&occ));
    println("ASEC: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ASEC_fe),digits=2) ))
    df_ASEC_hh[:, :grossinc_log_potential] = predict(ols_potential_earnings_ASEC_fe, df_ASEC_hh);
    df_ASEC_hh[:, :grossinc_potential] = exp.(df_ASEC_hh[:, :grossinc_log_potential]);
    =#

    # # Potential Earnings Regression using GLM package -> slow
    # transform!(df_ASEC_hh, [:YEAR, :sex, :race_recode, :educ_recode, :marst_recode, :ind, :occ] .=> categorical, renamecols = false);
    # ols_potential_earnings_ASEC = lm(@formula(grossinc_log ~ YEAR + earners + age + age^2 + sex + marst_recode + race_recode + educ_recode + ind + occ + age&educ_recode + age&occ), df_ASEC_hh);
    # println("ASEC: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ASEC),digits=2) ))
    # df_ASEC_hh[:, :grossinc_log_potential] = predict(ols_potential_earnings_ASEC);
    # df_ASEC_hh[:, :grossinc_potential] = exp.(predict(ols_potential_earnings_ASEC));

    #replace!(x -> x < 0 ? 1 : x, df_ASEC_hh.grossinc_potential);

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
    
    df_ACS = CSV.read(file_ACS, DataFrame);

    select!(df_ACS, Not([:SAMPLE, :CBSERIAL, :HHWT, :CLUSTER, :STRATA, :GQ, :PERWT, :OWNERSHPD, :RACED, :EDUCD, :WKSWORK1]));

    rename!(df_ACS, :STATEFIP => :STATEFIPS);
    rename!(df_ACS, :COUNTYFIP => :COUNTYFIPS);

    replace!(df_ACS.INCWAGE,  999999=>0);
    replace!(df_ACS.INCBUS00, 999999=>0); # Business and farm income; has negative values -> bottom coded at -9999
    replace!(df_ACS.INCINVST, 999999=>0); # Interest, dividend, and rental income; has negative values -> bottom coded at -9999
    replace!(df_ACS.VALUEH,   9999999=>0); # Value of housing units in contemporary dollars; Missing == 9999999

    # Distinguish reference years and survey years
    # So :YEAR is reference year, and :YEAR_survey is the corresponding survey year
    insertcols!(df_ACS, :YEAR_survey => df_ACS.YEAR)
    df_ACS.YEAR = df_ACS.YEAR .- 1

    # Apply FHSV sample selection
    insertcols!(df_ACS, :YEAR_reference => df_ACS.YEAR)
    df_ACS_sample0 = ACS_ASEC_sample_selection_FHSV(df_ACS, sample);

    # Add state info
    df_ACS_sample = innerjoin(df_ACS_sample0, df_state_info, on = :STATEFIPS);

    # Construct county from PUMA
    sort!(df_ACS_sample, [:YEAR, :STATEFIPS, :PUMA]);
    ACS_match_PUMA_county!(df_ACS_sample, df_state_info);

    #=
    # Compare the share of missing counties after PUMA-county matching
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
    :QVALUEH=>first=>:qvalueh, :STATEFIPS=>first=>:statefips,:COUNTY2_name_state_county=>first=>:county_name_state_county, :COUNTYFIPS2_recode=>first=>:county, :CITY=>first=>:city, :PUMA=>first=>:puma, :OWNERSHP=>first=>:ownershp, :HHINCOME=>first=>:hhincome, :INCWAGE=>sum=>:incwage, :INCBUS00=>sum=>:incbus00, :INCINVST=>sum=>:incinvst, :PROPTX99_recode=>first=>:proptx99_recode, :RENTGRS=>first=>:rentgrs, :RENT=>first=>:rent, :VALUEH=>first=>:valueh,
    :ROOMS=>first=>:rooms, :MOVEDIN=>first=>:movedin);
    insertcols!(df_ACS_hh, 3, :grossinc => df_ACS_hh.incwage + df_ACS_hh.incbus00 + df_ACS_hh.incinvst);
    filter!(r -> (r[:grossinc] .> 0), df_ACS_hh); # Innocent
    df_ACS_hh[:, :grossinc_log] = log.(df_ACS_hh[:, :grossinc]);
    df_ACS_hh[:, :proptx_log] = log.(df_ACS_hh[:, :proptx99_recode]);
    df_ACS_hh.YEAR_survey = df_ACS_hh.YEAR .+ 1

    #Impute home value for renters from Zillow data
    file_rent_paid = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/State_Zri_AllHomesPlusMultifamily_IMPORT.csv";
    file_home_value = "/Users/jiaxitan/UMN/Fed RA/Heathcote/Property Tax Est/Property-Tax-Imputing/Renters/State_Zhvi_AllHomes_IMPORT.csv";
    
    df_rentgrs = CSV.read(file_rent_paid, DataFrame);
    df_valueh = CSV.read(file_home_value, DataFrame);
    df_annual_rentgrs_to_valueh = 12 .* df_rentgrs[:,2:end] ./ df_valueh[:,2:end];
    insertcols!(df_annual_rentgrs_to_valueh, 1, :statename => df_rentgrs.Column1);
    df_annual_rentgrs_to_valueh = DataFrames.stack(df_annual_rentgrs_to_valueh, Not(:statename));
    rename!(df_annual_rentgrs_to_valueh, :variable => :YEAR, :value => :rentgrs_valueh_ratio);
    df_annual_rentgrs_to_valueh.YEAR = convert.(Int64, parse.(Int64, df_annual_rentgrs_to_valueh.YEAR));

    df_ACS_hh = leftjoin(df_ACS_hh, df_annual_rentgrs_to_valueh, on = [:statename, :YEAR_survey => :YEAR]);
    df_ACS_hh.valueh = convert.(Float64, df_ACS_hh.valueh)
    df_ACS_hh[df_ACS_hh.ownershp .!= 1.0, :valueh] .= 12 .* df_ACS_hh[df_ACS_hh.ownershp .!= 1.0, :rentgrs] ./ df_ACS_hh[df_ACS_hh.ownershp .!= 1.0, :rentgrs_valueh_ratio]
    
    #=
    # Potential Earnings Regression using FE package -> fast
    ols_potential_earnings_ACS_fe = reg(df_ACS_hh, @formula(grossinc_log ~ YEAR + earners + age + age^2 + sex + marst_recode + race_recode + educ_recode + ind + occ + age&educ_recode + age&occ));
    println("ACS: R2 of potential earnings regression: " * string( round(adjr2(ols_potential_earnings_ACS_fe),digits=2) ));
    df_ACS_hh[:, :grossinc_log_potential] = predict(ols_potential_earnings_ACS_fe, df_ACS_hh);
    df_ACS_hh[:, :grossinc_potential] = exp.(df_ACS_hh[:, :grossinc_log_potential]);
    =#

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

    #replace!(x -> x < 0 ? 1 : x, df_ACS_hh.grossinc_potential);

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

    # Fix for race code
    df_ASEC_hh.race_recode[df_ASEC_hh.race_recode .!= 1] .= 2;
    df_ACS_hh.race_recode[df_ACS_hh.race_recode .!= 1] .= 2;
    
    return df_ACS_hh, df_ASEC_hh
end