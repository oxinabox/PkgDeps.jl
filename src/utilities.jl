"""
Get the latest VersionNumber for base_path/Versions.toml
"""
function _get_latest_version(base_path::AbstractString)
    versions_file_path = joinpath(base_path, "Versions.toml")

    if isfile(versions_file_path)
        versions_content = parsefile(versions_file_path)
        versions = [VersionNumber(v) for v in collect(keys(versions_content))]

        return first(findmax(versions))
    end
end


"""
Use levenshtein distance to find packages closely named to pkg_to_compare

Rules:
- Ignore package name casings
- Only return matches that are between 1 and 2 distances
"""
function _find_alternative_packages(pkg_to_compare::String, packages::Array)
    MIN_LEVENSHTEIN = 1
    MAX_LEVENSHTEIN = 2

    pkg_to_compare = uppercase(pkg_to_compare)
    pkg_distances = [(REPL.levenshtein(uppercase(pkg), pkg_to_compare), pkg) for pkg in packages]

    return [x[2] for x in pkg_distances if MIN_LEVENSHTEIN <= x[1] <= MAX_LEVENSHTEIN]
end


"""
Get the package name from a UUID
"""

function _get_pkg_name(uuid::UUID, registries=RegistryInstance[])
    for rego in registries
        for (pkg_name, pkg_entry) in rego.pkgs
            if pkg_entry.uuid == uuid
                return pkg_name
            end
        end
    end

    throw(NoUUIDMatch("No package found with the UUID $uuid"))
end

function _get_pkg_name(uuid::UUID; kwargs...)
    registries = reachable_registries(; kwargs...)
    return _get_pkg_name(uuid, registries)
end


"""
Get the UUID from a package name and the registry it is in.
Specify a registry name as well to avoid ambiguity with same package names in multiple registries.
"""
function _get_pkg_uuid(
    pkg_name::String, registry_name::String;
    depots::Union{String, Vector{String}}=Base.DEPOT_PATH,
)
    registry = only(reachable_registries(registry_name; depots=depots))
    return _get_pkg_uuid(pkg_name, registry)
end

function _get_pkg_uuid(pkg_name::String, registry::RegistryInstance)
    if haskey(registry.pkgs, pkg_name)
        return registry.pkgs[pkg_name].uuid
    else
        alt_packages = _find_alternative_packages(pkg_name, collect(keys(registry.pkgs)))

        warning = "The package $(pkg_name) was not found in the $(registry.name) registry."

        if !isempty(alt_packages)
            warning *= "\nPerhaps you meant: $(string(alt_packages))"
        end

        warning *= "\nOr you can search in another registry using `users(\"$(pkg_name)\", \"OtherRegistry\")`"
        throw(PackageNotInRegistry(warning))
    end
end
