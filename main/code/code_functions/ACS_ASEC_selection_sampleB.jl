### Selects sample B of HPV 2010 from ASEC and ACS

# NOTE: identifying households uniquely
# ASEC: "A combination of YEAR, MONTH, and SERIAL provides a within-sample unique identifier for every household in IPUMS-CPS"
# -> ASEC has only MARCH observations. So for the ASEC month does not need to be included
# ACS/CENSUS: "A combination of SAMPLE and SERIAL provides a unique identifier for every household in the IPUMS"
# -> SAMPLE is related to YEAR: YYYY01. i.e. can use YEAR for unique identification


function lookup_minwage(y)
    ifelse(y == 1960, 1000, ifelse(y == 1970, 1300, ifelse(y == 1980, 3100,
    ifelse(y == 1990, 3350, ifelse(y == 1991, 3800, ifelse(y == 1992, 4250, ifelse(y == 1993, 4250, ifelse(y == 1994, 4250, ifelse(y == 1995, 4250,
    ifelse(y == 1996, 4250, ifelse(y == 1997, 4750, ifelse(y == 1998, 5150, ifelse(y == 1999, 5150,
    ifelse(y == 2000, 5150, ifelse(y == 2001, 5150, ifelse(y == 2002, 5150, ifelse(y == 2003, 5150, ifelse(y == 2004, 5150, ifelse(y == 2005, 5150,
    ifelse(y == 2006, 5150, ifelse(y == 2007, 5850, ifelse(y == 2008, 6550, ifelse(y == 2009, 7250,
    ifelse(y == 2010, 7250, ifelse(y == 2011, 7250, ifelse(y == 2012, 7250, ifelse(y == 2013, 7250, ifelse(y == 2014, 7250, ifelse(y == 2015, 7250,
    ifelse(y == 2016, 7250, ifelse(y == 2017, 7250, ifelse(y == 2019, 7250,
    100_000))))))))))))))))))))))))))))))))
end

function ACS_ASEC_selection_sampleB(df)

    ACS_INCBUS00 = sum(occursin.(r"INCBUS00", names(df)))

    df_result = copy(df[1:2,:]; copycols=true);
    for group in groupby(df, [:SERIAL, :YEAR])
        age_test = count(i->(25 <= i <= 60), group.AGE)                          # Skip record if no member is between 25 and 60
        RELATE_test = count(i->(i==1 || i==2 || i==101 || i==201), group.RELATE)    # Skip record if not at least one head
        if age_test > 0 && RELATE_test > 0
            minwage = lookup_minwage(group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :YEAR])
            # Need to -1 to get reference year age
            head_age  = group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :AGE] .- 1
            head_work = group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :WKSWORK2]
            if ACS_INCBUS00 == 1
                head_inc = group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :INCWAGE] .+ group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :INCBUS00]
            else
                head_inc = group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :INCWAGE] .+ group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :INCBUS] .+ group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :INCFARM]
            end
            cond1 = ((25 <= head_age <= 60) && (head_inc > minwage) && (head_work > 0))
                if ((2 in group.RELATE) || (201 in group.RELATE))
                    spouse_age  = group[findfirst(x -> (x == 201 || x == 2), group.RELATE), :AGE]
                    spouse_work = group[findfirst(x -> (x == 201 || x == 2), group.RELATE), :WKSWORK2]
                    if ACS_INCBUS00 == 1
                        spouse_inc  = group[findfirst(x -> (x == 201 || x == 2), group.RELATE), :INCWAGE] .+ group[findfirst(x -> (x == 201 || x == 2), group.RELATE), :INCBUS00]
                    else
                        spouse_inc  = group[findfirst(x -> (x == 201 || x == 2), group.RELATE), :INCWAGE] .+ group[findfirst(x -> (x == 201 || x == 2), group.RELATE), :INCBUS] .+ group[findfirst(x -> (x == 201 || x == 2), group.RELATE), :INCFARM]
                    end
                    cond2 = ((25 <= spouse_age <= 60) && (spouse_inc > minwage) && (spouse_work > 0))
                else
                    cond2 = false
                end
            if cond1 + cond2 > 0 append!(df_result, group) end
        end
    end
    delete!(df_result, 1:2)
    return df_result
end
