using Pigeons
using StatsFuns 

struct SimpleMixture{T} 
    data::T
end 
Adapt.@adapt_structure SimpleMixture 
SimpleMixture(backend::Backend) = 
    SimpleMixture(copy_to_device(simple_mixture_data(Float32), backend)) 

function iid_sample!(rng, ::SimpleMixture, state::AbstractVector{E}) where {E}
    @assert length(state) == 5 
    state[1] = E(100) * randn(rng, E) + E(150)
    state[2] = E(100) * randn(rng, E) + E(150) 
    state[3] = E(100) * rand(rng, E) 
    state[4] = E(100) * rand(rng, E) 
    state[5] = rand(rng, E) 
    return nothing
end

function log_reference(mix::SimpleMixture{A}, state::AbstractVector{E}) where {E, A <: AbstractVector}
    mean1, mean2, sds1, sds2, proportion = state
    if sds1 < 0 || sds1 > 100 ||
        sds2 < 0 || sds2 > 100 || proportion < 0 || proportion > 1
         return -Pigeons.inf(E)
     end
    sum = zero(E) 
    sum += normlogpdf(E(150), E(100), mean1)
    sum += normlogpdf(E(150), E(100), mean2)
    sum += -2*log(E(100))
    return sum
end

function log_density_ratio(mix::SimpleMixture{A}, state::AbstractVector{E}) where {E, A <: AbstractVector}
    mean1, mean2, sds1, sds2, proportion = state
    if sds1 < 0 || sds1 > 100 ||
        sds2 < 0 || sds2 > 100 || proportion < 0 || proportion > 1
         return -Pigeons.inf(E)
     end
    sum = zero(E) 
    for datum in mix.data
        ll1 = log(proportion) + normlogpdf(mean1, sds1, datum)
        ll2 = log(1-proportion) + normlogpdf(mean2, sds2, datum)
        sum += logaddexp(ll1, ll2)
    end
    return sum
end

dimensionality(::SimpleMixture) = 5

simple_mixture_data(::Type{E}) where {E} = Array{E}([
    1.158567914166645352e+02
    1.522615371577288670e+02
    1.788744905891352914e+02
    1.629350081470792588e+02
    1.070282069704478687e+02
    1.051914114638578326e+02
    1.183828850125410668e+02
    1.253769803023669596e+02
    1.028805401104259118e+02
    2.067132613581522378e+02
    1.393689112736414870e+02
    1.554104808778958500e+02
    1.487593071755844676e+02
    8.375957653422238991e+01
    1.399077526119093307e+02
    1.206223893711136839e+02
    1.355653294182054935e+02
    1.048872555335645700e+02
    1.100078889548582310e+02
    1.188513733603652440e+02
    1.132073362373470928e+02
    1.014642371115838984e+02
    5.356401814042712317e+01
    8.343273493925009632e+01
    1.583050349068367382e+02
    1.064199800668446869e+02
    1.558244033676002402e+02
    1.131988392873396521e+02
    1.267707052969062715e+02
    1.373788302432297712e+02
    1.206953931925136061e+02
    1.115746362929019284e+02
    1.154467698745591520e+02
    9.923198975585711423e+01
    1.316472257470074680e+02
    9.996377019794388730e+01
    1.114213874064032979e+02
    1.246905912527673479e+02
    1.391450928299441898e+02
    1.361514286100230322e+02
    1.307114960428298787e+02
    8.081320412094767391e+01
    1.078213581175719611e+02
    1.262596451507411501e+02
    1.712742662463147383e+02
    1.570100443945581219e+02
    8.570544719055581595e+01
    1.135717929149446377e+02
    1.370765432994399475e+02
    7.990858139039664820e+01
    4.740688606684956596e+01
    6.701135245547557417e+01
    1.316212901516728664e+02
    1.327180223388547233e+02
    1.685093629801724546e+02
    1.337698992870340646e+02
    1.755485831680152558e+02
    1.655242363776454511e+02
    1.268471820873596698e+02
    1.676015711703536226e+02
    1.455898511751295246e+02
    1.956160184192707447e+02
    1.182224625628614518e+02
    8.925085983612626706e+01
    1.286269237190567196e+02
    9.946176931548411915e+01
    1.571061188364705856e+02
    1.002501134175815167e+02
    1.178736425808296389e+02
    9.422954036020570356e+01
    9.632336367696697721e+01
    1.309771108808969871e+02
    1.181391667258337890e+02
    8.718473890259349446e+01
    1.467363729533580283e+02
    1.257994960590099538e+02
    1.034723269322880412e+02
    1.117477319618722476e+02
    1.346570263925455890e+02
    1.104112268972690600e+02
    1.240279649415264771e+02
    9.058614097837573809e+01
    1.743529241470696718e+02
    1.454735444682585239e+02
    1.200774356852196547e+02
    7.684825811735771595e+01
    1.327615627530778681e+02
    9.236097068799219301e+01
    9.552784968289883238e+01
    1.332776882106832943e+02
    1.473534846560240510e+02
    1.020106291189790824e+02
    9.650714482034651098e+01
    7.139916441047688522e+01
    1.401992316904928657e+02
    9.516569029497389920e+01
    1.419834249663591095e+02
    1.066032295735071500e+02
    1.502077702798387122e+02
    1.708914207381996277e+02
    1.299656738905514715e+02
    1.135507706312860989e+02
    1.853554068292964416e+02
    9.021956920397798285e+01
    6.968136186221670414e+01
    9.037055157785742665e+01
    1.332929122157154040e+02
    1.438895971894569925e+02
    1.999686126528019372e+02
    7.347125660893672716e+01
    1.724387017675225593e+02
    1.739221981887874904e+02
    1.604682597323718483e+02
    5.568169798182179875e+01
    1.585200286677854251e+02
    1.040052091982859821e+02
    1.063286334389799492e+02
    1.626048095277152470e+02
    7.911796631966825544e+01
    1.307427048577662561e+02
    2.057499230950611206e+02
    1.968272359917557139e+02
    1.881442820837430077e+02
    2.099549294015370151e+02
    1.998661946532027969e+02
    2.118440756588201168e+02
    1.606377918214757301e+02
    2.345495227313272721e+02
    1.979870202889300117e+02
    1.767565653027037627e+02
    2.392032562427630751e+02
    2.203634866605279967e+02
    2.186204436985496784e+02
    1.958292604060661688e+02
    1.763536231210040341e+02
    1.720099990072054084e+02
    2.276111145823536503e+02
    2.031618190973077560e+02
    2.203394620375324564e+02
    1.748951748467622167e+02
    2.246467115445838658e+02
    2.063262381110193644e+02
    2.243575662535018296e+02
    1.784441729981658966e+02
    2.062286003797039768e+02
    1.775707944495688935e+02
    2.155143763250597715e+02
    1.773479541349278747e+02
    1.812393484934563048e+02
    2.016410664104029422e+02
])