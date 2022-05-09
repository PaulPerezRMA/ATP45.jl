module ATP45

using GeoInterface
using Proj4

const EARTH_RADIUS = 6371.0e3
const DEFAULT_PROJ = Ref{Any}(C_NULL)

function __init__()
    DEFAULT_PROJ[] = Projection("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
end

include("shapes.jl")
include("coordinates.jl")
include("helpers.jl")


end
