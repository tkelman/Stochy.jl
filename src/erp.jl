import Base.show
import Base.Random.rand
export Bernoulli, Categorical, flip, randominteger, hellingerdistance

function rand(ps::Vector{Float64})
    @assert isdistribution(ps)
    acc = 0.
    r = rand()
    for (i,p) in enumerate(ps)
        acc += p
        if r < acc
            return i
        end
    end
    error("unreachable")
end

isprob(x::Float64) = 0 <= x <= 1
# TODO: Perhaps the epsilon should be based on length(xs)?
isdistribution(xs::Vector{Float64}) = all(isprob, xs) && abs(sum(xs)-1) < 1e-10

abstract ERP

immutable Bernoulli <: ERP
    p::Float64
    function Bernoulli(p::Float64)
        @assert isprob(p)
        new(p)
    end
end

# @appl
Bernoulli(p::Float64, k::Function) = k(Bernoulli(p))

sample(erp::Bernoulli) = rand() < erp.p
support(::Bernoulli) = (true,false)
score(erp::Bernoulli, x::Bool) = x ? log(erp.p) : log(1-erp.p)

@appl function flip(p)
    sample(Bernoulli(p))
end

@appl function flip()
    flip(0.5)
end


# Consider having a separate type for approximate distributions made
# from samples (empirical distribution?) rather than the "isapprox"
# flag and accompanying conditionals. This is perhaps best tackled
# after adding some more ERP so that I can better understand what the
# type hierarchy for discrete/continuous ERP needs to look like.

immutable Discrete <: ERP
    hist::Dict{Any,Float64}
    xs::Array
    ps::Array{Float64}
    isapprox::Bool
    function Discrete(hist, isapprox)
        # TODO: I'm assuming that keys/values iterate over the dict in
        # the same order. Check that they do otherwise values will
        # have their probabilities mixed up.
        xs = collect(keys(hist))
        ps = collect(values(hist))
        @assert isdistribution(ps)
        new(hist, xs, ps, isapprox)
    end
end

Discrete(hist) = Discrete(hist, false)

# @appl
Discrete(hist, k::Function) = k(Discrete(hist))

sample(erp::Discrete) = erp.xs[rand(erp.ps)]
# This is potentially misleading for approximating distributions as we
# don't really know the support. i.e. We can't (currently, at least)
# distinguish between an x which is not in the support and one which
# has zero probability.
support(erp::Discrete) = erp.xs
function score(erp::Discrete, x)
    prob = erp.isapprox ? get(erp.hist, x, 0.) : erp.hist[x]
    log(prob)
end

function show(io::IO, erp::Discrete)
    println(io, "Discrete(")
    for (x,p) in filter((x,p)->p>0,erp.hist)
        show(io, x)
        print(io, " => ")
        show(io, p)
        println()
    end
    print(io, ")")
end

# TODO: Using the generic Discrete ERP here seems pretty inefficient
# as there's no need to expand the parameter n into a Dict.
# TODO: Can this be written as @appl.
# TODO: Think about naming. Should "uniform" be mentioned here?

# @appl
function randominteger(n, k::Function)
    sample(Discrete(Dict([(x,1/n) for x in 1:n])), k)
end

# What would happen if this was passed two approximating
# distributions? Currently it would work because support is defined,
# but I'm not sure it does the right thing as I think all values in
# p.xs union q.xs would need to be considered. Perhaps this supports
# the idea of having a specific type for approximating distributions.
function hellingerdistance(p::ERP, q::ERP)
    acc = 0.0
    for x in support(p)
        px = exp(score(p,x))
        qx = exp(score(q,x))
        acc += (sqrt(px)-sqrt(qx))^2
    end
    sqrt(acc/2.0)
end
