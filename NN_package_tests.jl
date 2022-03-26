
### Experiment with NearestNeighbors package


## Housekeeping

using StatsBase, Statistics, Distributions, Random
using Plots, Plots.PlotMeasures, StatsPlots; gr()
using NearestNeighbors


## Generate 100 observations with three features: income, age, gender

Random.seed!(123)
N = 1000;

# Income 
inc_mu = 70_000;
inc_sigma = 20_000;
d_inc = truncated(Normal(inc_mu, inc_sigma), 0, Inf)
vec_inc = rand(d_inc, N)

# Age
age_mu = 45;
age_sigma = 15;
d_age = truncated(Normal(age_mu, age_sigma), 0, Inf)
vec_age = rand(d_age, N)

# Gender
d_gender = Binomial(1)
vec_gender = rand(d_gender,N);

# Collect into matrix as input for NN package
obs = convert.(Float64,round.([vec_inc'; vec_age'; vec_gender'],digits=0));


## Find best k matches for given observation

# Define given observation to match
obs1 = [80_000.0; 55.0; 1.0];

k = 10;
kdtree = KDTree(obs);
idxs, dists = knn(kdtree, obs1, k);

# Compute mean features of matched observations
obs_matched = obs[:, idxs];
obs_matched_inc_mean = mean(obs_matched[1,:]);
obs_matched_age_mean = mean(obs_matched[2,:]);
obs_matched_gender_mean = mean(obs_matched[3,:]);


## Compare mean features

# Income
density(obs[1,:], label = "All observations: " * string(N), title = "Income")
vline!([obs1[1]]; label = "Given observation: 1", legend = :topleft, linestyle = :dash)
density!(obs_matched[1,:], label = "Matched observations: " * string(k))

# Age
density(obs[2,:], label = "All observations: " * string(N), title = "Age")
vline!([obs1[2]]; label = "Given observation: 1", legend = :topleft, linestyle = :dash)
density!(obs_matched[2,:], label = "Matched observations: " * string(k))

# Gender
x = ["All observations: " * string(N), "Given observation: 1", "Matched observations: " * string(k)]
y = 100 .* [mean(obs[3,:]), obs1[3], mean(obs_matched[3,:])]
bar(x, y, title = "Gender: share male (%)", legend = false)

