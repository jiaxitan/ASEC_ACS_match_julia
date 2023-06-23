
# Computes personal earned income in the ASEC and ACS datasets

function ACS_ASEC_inc_earned_person!(df)

    insertcols!(df, size(df,2)+1, :inc_earned_person => vec(zeros(Int64, size(df,1),1)))

    ACS_INCBUS00 = sum(occursin.(r"INCBUS00", names(df)))

    if ACS_INCBUS00 == 1
        for i = 1:size(df,1)
            df[i, :inc_earned_person] = df[i, :INCWAGE] + df[i, :INCBUS00]
        end
    else
        for i = 1:size(df,1)
            df[i, :inc_earned_person] = df[i, :INCWAGE] + df[i, :INCBUS] + df[i, :INCFARM]
        end
    end

end
