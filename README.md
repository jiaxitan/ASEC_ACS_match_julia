# Property-Tax-Imputing

<details><summary>Summary of Approaches</summary>
<p>
Data: ACS and ASEC data
Time: 2005/2006, 2010/2011, 2015/2016

Home Owners:
1. Prepare ACS and ASEC data by recoding demographic variables. In particular, we use PUMA to imput county information for ACS.
2. For households that is available for county-level matching, we find the 9 nearest neighbors at the same county based on household gross income, education level, and # of housing units in the structure. 
3. For households that is not availanle for county-level matching, we match at state level, after excluding all the counties that are eligible for county-matching. 
4. Given the 9 nearest neighbors, we compute the mean property tax and mean property value. Assign these values to the ASEC household.
5. We compare the regressivity of propterty tax in ACS and in imputed ASEC data. The conclusion is that we should plot the mean of income and property tax in each income group. (Refer to an email on June 12, 2022)

Renters:
1. 1, 2 and 3 are the same as that in home owners'.
4. Given the 9 nearest neighbors, we computed the mean gross rent and mean rent. Assign these values to the ASEC household.
5. Use the Zillow price-rent ratios by state to estimate home values for each ASEC renter given the imputed rent paid (gross rent). 
6. For each ASEC home owner, compute the property tax rate as the ratio of property tax paid over home value.
7. At the state and county level (where possible) estimate the property tax rate paid given the ASEC household income level by fitting the function:
![equation](https://latex.codecogs.com/svg.image?\tau_i(y)&space;=&space;\alpha_{0,i}&space;&plus;&space;\alpha_{1,i}\log(y)&space;&plus;&space;\alpha_{2,i}\log(y)^2&space;)
where i denotes state and country. We run this regression at individual household level.
8. The we use the estimated coefficients and imputed home value for renters to imput property taxes for renters.

</p>
</details>
