
### Experiment with NearestNeighbors.jl package


## Housekeeping

using StatsBase, Statistics, Distributions, Random
using Plots, Plots.PlotMeasures, StatsPlots; gr()
using NearestNeighbors

dir_out = "/Users/main/Downloads/";

## Generate 100 observations with three features: income, age, gender

Random.seed!(123)
N = 500;

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

k = 10;
obs1 = [75_000.0; 55.0; 1.0];


## 1. UNTRANSFORMED VARIABLES

kdtree = KDTree(obs)
idxs, dists = knn(kdtree, obs1, k);

# Compare mean features of matched observations
obs_matched = obs[:, idxs];

# Income
p1 = density(obs[1,:]/1000, label = "All obs: " * string(N), title = "Income (in 1,000 USD)")
vline!([obs1[1]]/1000; label = "Given obs: 1", legend = :topright, linestyle = :dash)
density!(obs_matched[1,:]/1000, label = "Matched obs: " * string(k), legendfontsize = 6, titlefontsize = 7, xtickfontsize = 7)

# Age
p2 = density(obs[2,:], label = "All observations: " * string(N), title = "Age")
vline!([obs1[2]]; label = "Given observation: 1", legend = :topright, linestyle = :dash)
density!(obs_matched[2,:], label = "Matched observations: " * string(k), legend = false, titlefontsize = 7, xtickfontsize = 7)

# Gender
x = ["All obs", "Given obs", "Matched obs"]
y = 100 .* [mean(obs[3,:]), obs1[3], mean(obs_matched[3,:])]
p3 = bar(x, y, title = "Gender: share male (%)", legend = false, color = [:blue, :red, :green], titlefontsize = 7, xtickfontsize = 7)

# Combine plots
l = @layout [a; b; c]
plot(p1, p2, p3, layout = l)
savefig(dir_out * "NN_match_summary.pdf")


## 2. NORMALIZED VARIABLES

# Normalize features of observations by dividing with std
obs_norm  = [ transpose(obs[1,:] ./ std(obs[1,:])); transpose(obs[2,:] ./ std(obs[2,:])); transpose(obs[3,:] ./ std(obs[3,:])) ]
obs1_norm = [ obs1[1] ./ std(obs[1,:]); obs1[2] ./ std(obs[2,:]); obs1[3] ./ std(obs[3,:]) ];

kdtree_norm = KDTree(obs_norm);
idxs_norm, dists_norm = knn(kdtree_norm, obs1_norm, k);

# Compare mean features of matched observations
obs_matched_norm = obs[:, idxs_norm];

# Income
p1_norm = density(obs[1,:]/1000, label = "All observations: " * string(N), title = "Income (in 1,000 USD)")
vline!([obs1[1]]/1000; label = "Given observation: 1", legend = false, linestyle = :dash)
density!(obs_matched_norm[1,:]/1000, label = "Matched observations: " * string(k), titlefontsize = 7, xtickfontsize = 7)

# Age
p2_norm = density(obs[2,:], label = "All observations: " * string(N), title = "Age")
vline!([obs1[2]]; label = "Given observation: 1", legend = false, linestyle = :dash)
density!(obs_matched_norm[2,:], label = "Matched observations: " * string(k), legend = false, titlefontsize = 7, xtickfontsize = 7)

# Gender
x_norm = ["All obs", "Given obs", "Matched obs"]
y_norm = 100 .* [mean(obs[3,:]), obs1[3], mean(obs_matched_norm[3,:])]
p3_norm = bar(x_norm, y_norm, title = "Gender: share male (%)", legend = false, color = [:blue, :red, :green], titlefontsize = 7, xtickfontsize = 7)

# Combine plots
l = @layout [a; b; c]
plot(p1_norm, p2_norm, p3_norm, layout = l)
savefig(dir_out * "NN_match_summary_normalized.pdf")

# Combine all plots
p_title = plot(title = "Non-normalized (lhs) vs normalized (rhs) matching", grid = false, showaxis = false, ticks=nothing, border=nothing)
plot(p_title, p1, p1_norm, p2, p2_norm, p3, p3_norm, layout = @layout([A{0.01h}; [B C; D E; F G]]))
savefig(dir_out * "NN_match_summary_comparison.pdf")
