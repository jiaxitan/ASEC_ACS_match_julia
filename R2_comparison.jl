
function r2_compare()
    R2_comparison = DataFrame(regressors = Any[], sample = Int64[], levels = Float64[], logs = Float64[]);
    regressors_logs = ["grossinc_log", "age", "size", "unitsstr_recode", "educ_recode", "race_recode", "sex"];
    regressors_levels = ["grossinc", "age", "size", "unitsstr_recode", "educ_recode", "race_recode", "sex"];


    for x in 1:(size(regressors_logs)[1]+1)
        for y in [2005, 2010, 2015]
            df_regression = df_ACS_hh[(in([y, y+1]).(df_ACS_hh.YEAR)) .& (df_ACS_hh.valueh .!= 0), :];
            if x > 1
                regression_logs = reg(df_regression, term("valueh_log") ~ sum(term.(regressors_logs[Not(x-1)])));
                regression_levels = reg(df_regression, term("valueh") ~ sum(term.(regressors_levels[Not(x-1)])));

                push!(R2_comparison, [regressors_levels[x-1] y r2(regression_levels) r2(regression_logs)]);
            else
                regression_logs = reg(df_regression, term("valueh_log") ~ sum(term.(regressors_logs)));
                regression_levels = reg(df_regression, term("valueh") ~ sum(term.(regressors_levels)));
                
                push!(R2_comparison, ["All" y r2(regression_levels) r2(regression_logs)])
            end
        end

    end

    return R2_comparison
end




