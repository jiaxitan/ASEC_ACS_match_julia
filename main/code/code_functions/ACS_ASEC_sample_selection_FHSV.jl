### Selects different samples from ASEC and ACS

# baseline: similar sample B of HPV 2010 = HSV 2017 QJE (age requirement on household head, income requirement on head + spouse earned income)
# full: all hhs with head age 25 <= i <= 60 (baseline without earnings requirement)

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

function ACS_ASEC_sample_selection_FHSV(df, sample::String)

    ACS_INCBUS00 = sum(occursin.(r"INCBUS00", names(df)))

    df_result = copy(df[1:2,:]; copycols=true);
    for group in groupby(df, [:SERIAL, :YEAR_reference])
        age_test = count(i->(25+1 <= i <= 60+1), group.AGE)                             # Skip record if no member is between 25 and 60
        RELATE_test = count(i->(i==1 || i==2 || i==101 || i==201), group.RELATE)        # Skip record if not at least one head
        if age_test > 0 && RELATE_test > 0
            minwage = lookup_minwage(group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :YEAR_reference])
            head_age = group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :AGE]
            if ACS_INCBUS00 == 1
                head_inc   = group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :INCWAGE] .+ group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :INCBUS00]
                if ((2 in group.RELATE) || (201 in group.RELATE))
                    spouse_inc = group[findfirst(x -> (x == 2 || x == 201), group.RELATE), :INCWAGE] .+ group[findfirst(x -> (x == 2 || x == 201), group.RELATE), :INCBUS00]
                end
            else
                head_inc   = group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :INCWAGE] .+ group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :INCBUS] .+ group[findfirst(x -> (x == 1 || x == 101), group.RELATE), :INCFARM]
                if ((2 in group.RELATE) || (201 in group.RELATE))
                    spouse_inc = group[findfirst(x -> (x == 2 || x == 201), group.RELATE), :INCWAGE] .+ group[findfirst(x -> (x == 2 || x == 201), group.RELATE), :INCBUS] .+ group[findfirst(x -> (x == 2 || x == 201), group.RELATE), :INCFARM]
                end
            end

            ((2 in group.RELATE) || (201 in group.RELATE)) ? hh_inc = head_inc + spouse_inc : hh_inc = head_inc 

            if sample == "baseline"
                cond = ((25+1 <= head_age <= 60+1) && (hh_inc > minwage))
            elseif sample == "full"
                cond =  (25+1 <= head_age <= 60+1)
            else
                error("Undefined sample selection choice")
            end
            if cond > 0 append!(df_result, group) end
        else
            continue
        end
    end
    delete!(df_result, 1:2)
    return df_result
end
