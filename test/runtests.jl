using Appl
using Base.Test

dist = @appl enum() do
    local a = flip(0.5),
          b = flip(0.5),
          c = flip(0.5)
    a + b + c
end

println(dist)
@test dist.hist == {0=>0.125,1=>0.375,2=>0.375,3=>0.125}

# Ensure the context is restored when an exception occurs during
# enumeration.
try @appl enum(()->foo())
catch e
    if isa(e, UndefVarError)
        @test Appl.ctx == Appl.Prior()
    else
        rethrow(e)
    end
end

hist = [0=>0.2, 1=>0.3, 2=>0.5]
erp = Appl.Discrete(hist)
@test all([x in Appl.support(erp) for x in 0:2])
@test all([Appl.score(erp, x) == log(hist[x]) for x in 0:2])

# Hellinger distance.
@test hellingerdistance(Bernoulli(0.5), Bernoulli(0.5)) == 0
@test hellingerdistance(Bernoulli(1.0), Bernoulli(0.0)) == 1
# Test the case where some values in the support of the exact
# distribution have not been sampled.
p = Appl.Discrete([0=>0.25,1=>0.25,2=>0.5])
q = Appl.Discrete([0=>0.4,2=>0.6], true)
@test hellingerdistance(p,p) == 0
@test 0 < hellingerdistance(p,q) < 1

println("Passed!")
