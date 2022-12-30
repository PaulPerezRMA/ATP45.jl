abstract type AbstractCategory end

"""
    AbstractWeapon <: AbstractCategory
Discriminate between the type of weapon (Chemical, Biological, Radiological, Nuclear)
"""
abstract type AbstractWeapon <: AbstractCategory end

struct ChemicalWeapon <: AbstractWeapon end
id(::Type{ChemicalWeapon}) = "chem"
longname(::Type{ChemicalWeapon}) = "Chemical"

struct BiologicalWeapon <: AbstractWeapon end
id(::Type{BiologicalWeapon}) = "bio"
longname(::Type{BiologicalWeapon}) = "Biological"

struct RadiologicalWeapon <: AbstractWeapon end
id(::Type{RadiologicalWeapon}) = "radio"
longname(::Type{RadiologicalWeapon}) = "Radiological"

struct NuclearWeapon <: AbstractWeapon end
id(::Type{NuclearWeapon}) = "nuclear"
longname(::Type{NuclearWeapon}) = "Nuclear"

"""
    AbstractReleaseType <: AbstractCategory
Discriminate between the release type (ex: Air Contaminating Attack, Ground Contaminating Attacks)
"""
abstract type AbstractReleaseType <: AbstractCategory end
description(::Type{<:AbstractReleaseType}) = "No description"
longname(::Type{<:AbstractReleaseType}) = "Unknown release type"
id(::Type{<:AbstractReleaseType}) = ""
note(::Type{<:AbstractReleaseType}) = ""

struct ReleaseTypeA <: AbstractReleaseType end
description(::Type{ReleaseTypeA}) = "Release following an attack with an air contaminating (non-persistent) chemical agent."
longname(::Type{ReleaseTypeA}) = "Air Contaminating Attack."
id(::Type{ReleaseTypeA}) = "typeA"
note(::Type{ReleaseTypeA}) = """
Type A attack is considered the immediate, short period worst-case attack scenario because it is an immediate hazard. Assume a Type A attack if:
- Liquid agent cannot be observed or;
- No passive methods or indicators confirm the hazard to be a persistent agent.
"""

struct ReleaseTypeB <: AbstractReleaseType end
description(::Type{ReleaseTypeB}) = "Release following an attack with a ground contaminating (persistent) chemical agent."
longname(::Type{ReleaseTypeB}) = "Ground Contaminating Attacks."
id(::Type{ReleaseTypeB}) = "typeB"

struct ReleaseTypeC <: AbstractReleaseType end
description(::Type{ReleaseTypeC}) = "Detection of a chemical agent following an unobserved release."
longname(::Type{ReleaseTypeC}) = "Chemical Agent Release of Unknown Origin."
id(::Type{ReleaseTypeC}) = "typeC"


abstract type AbstractWindCategory <: AbstractCategory end

struct LowerThan10 <: AbstractWindCategory end
description(::Type{LowerThan10}) = "The wind is <= 10km/h."

struct HigherThan10 <: AbstractWindCategory end
description(::Type{HigherThan10}) = "The wind is > 10km/h."

abstract type AbstractContainerType <: AbstractCategory end

# struct Bomblet <: AbstractContainerType end
# id(::Type{Bomblet}) = "BML"
# description(::Type{Bomblet}) = "Bomblet"

# struct Bomb <: AbstractContainerType end
# id(::Type{Bomb}) = "BOM"
# description(::Type{Bomb}) = "Bomb"

# struct Shell <: AbstractContainerType end
# id(::Type{Shell}) = "SHL"
# description(::Type{Shell}) = "Shell"

# struct Spray <: AbstractContainerType end
# id(::Type{Spray}) = "SPR"
# description(::Type{Spray}) = "Spray (tank)"

# struct Generator <: AbstractContainerType end
# id(::Type{Generator}) = "GEN"
# description(::Type{Generator}) = "Generator (Aerosol)"

# macro container(typ::String, id::String, descr::String)
macro container(typ, id, descr)
    containermacro(typ, id, descr)
end

# function containermacro(typ, id, descr)
#     quote
#         Base.@__doc__ struct $(eval(typ)) <: AbstractContainerType end
#         id(::Type{$(eval(typ))}) = $id
#         description(::Type{$(eval(typ))}) = $descr
#     end |> esc
# end
function containermacro(typ, id, descr)
    quote
        struct $typ <: AbstractContainerType end
        id(::Type{$typ}) = $id
        longname(::Type{$typ}) = $descr
    end
end

const container_types = (
    (:Bomblet, "BML", "Bomblet"),
    (:Bomb, "BOM", "Bomb"),
    (:Shell, "SHL", "Shell"),
    (:Spray, "SPR", "Spray (tank)"),
    (:Generator, "GEN", "Generator (Aerosol)"),
    (:Mine, "MNE", "Mine"),
    (:Missile, "MSL", "Missile"),
    (:AirRocket, "ARKT", "Air burst rocket"),
    (:SurfaceRocket, "SRKT", "Surface burst rocket"),
    (:MissilesPayload, "MPL", "Surface burst missiles payload"),
    (:NotKnown, "NKN", "Unknown munitions"),
)

for ct in container_types
    eval(containermacro(ct...))
end

const container_groups = (
    ContainerGroupA = [Bomblet, Bomb, SurfaceRocket, AirRocket, Shell, Mine, NotKnown, Missile],
    ContainerGroupB = [Bomblet, Shell, Mine, SurfaceRocket, Missile],
    ContainerGroupC = [Bomb, NotKnown, AirRocket, Missile],
    ContainerGroupD = [Spray, Generator],
    ContainerGroupE = [Shell, Bomblet, Mine],
    ContainerGroupF = [MissilesPayload, Bomb, SurfaceRocket, AirRocket, NotKnown],
)

abstract type AbstractContainerGroup <: AbstractCategory end
struct ContainerGroup <: AbstractContainerGroup
    content::Vector{<:AbstractContainerType}
end
Base.in(item::AbstractContainerType, collection::AbstractContainerGroup) = item in collection.content

function containergroupmacro(name, group)
    quote
        const $name = Union{$(group...)}
        $name() = ContainerGroup([ct() for ct in $group])
    end
end

for (k, v) in pairs(container_groups)
    eval(containergroupmacro(k, v))
end


# function(::Type{Union{<:T}})() where {T <: Tuple{<:AbstractContainerType, Vararg{<:AbstractContainerType}}}
#     conttypes = [ct() for ct in T]
#     ContainerGroup(conttypes)
# end

nextchoice(args::Vararg{<:AbstractCategory}) = nextchoice(typeof.(args)...)

nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeA}) = [LowerThan10(), HigherThan10()]
nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeA}, ::Type{LowerThan10}) = nothing
nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeA}, ::Type{HigherThan10}) = [container_groups.ContainerGroupE, container_groups.ContainerGroupF]
nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeA}, ::Type{HigherThan10}, ::Type{<:ContainerGroupE}) = nothing
nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeA}, ::Type{HigherThan10}, ::Type{<:ContainerGroupF}) = nothing

nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeB}) = [container_groups.ContainerGroupB, container_groups.ContainerGroupC, container_groups.ContainerGroupD]
nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeB}, ::Type{<:ContainerGroupB}) = [LowerThan10(), HigherThan10()]
nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeB}, ::Type{<:ContainerGroupC}) = [LowerThan10(), HigherThan10()]
nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeB}, ::Type{<:ContainerGroupD}) = [LowerThan10(), HigherThan10()]

nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeB}, ::Type{<:ContainerGroupB}, ::Type{LowerThan10}) = nothing

nextchoice(::Type{ChemicalWeapon}, ::Type{ReleaseTypeC}) = nothing

categories_order() = [AbstractWeapon, AbstractReleaseType, AbstractContainerType]

function sort_categories(categories)
    order = categories_order()
    ordered = AbstractCategory[]
    for ocat in order
        icategory = findfirst(isa.(categories, Ref(ocat)))
        !isnothing(icategory) && push!(ordered, categories[icategory])
    end
    Tuple(ordered)
end
# nextchoice(::Type{ReleaseTypeB}, ::Type{HigherThan10}) = "circle"