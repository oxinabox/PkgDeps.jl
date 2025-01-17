using PkgDeps
using Test
using UUIDs

const DEPOT = joinpath(@__DIR__, "resources")
const GENERAL_REGISTRY = only(reachable_registries("General"; depots=DEPOT))
const FOOBAR_REGISTRY = only(reachable_registries("Foobar"; depots=DEPOT))


@testset "internal functions" begin
    @testset "_get_pkg_name" begin
        @testset "uuid to name" begin
            expected = "Case1"
            pkg_name = PkgDeps._get_pkg_name(UUID("00000000-1111-2222-3333-444444444444"); depots=DEPOT)

            @test expected == pkg_name
        end

        @testset "exception" begin
            @test_throws NoUUIDMatch PkgDeps._get_pkg_name(UUID("00000000-0000-0000-0000-000000000000"); registries=FOOBAR_REGISTRY)
        end
    end

    @testset "_get_pkg_uuid" begin
        @testset "name to uuid" begin
            expected = UUID("00000000-1111-2222-3333-444444444444")

            pkg_uuid = PkgDeps._get_pkg_uuid("Case1", "Foobar"; depots=DEPOT)
            @test expected == pkg_uuid

            pkg_uuid = PkgDeps._get_pkg_uuid("Case1", FOOBAR_REGISTRY)
            @test expected == pkg_uuid
        end

        @testset "exception" begin
            @test_throws PackageNotInRegistry PkgDeps._get_pkg_uuid("PkgDepsFakePackage", "General")
            @test_throws PackageNotInRegistry PkgDeps._get_pkg_uuid("FakePackage", FOOBAR_REGISTRY)
        end
    end

    @testset "_get_latest_version" begin
        expected = v"0.2.0"
        path = joinpath("resources", "registries", "General", "Case4")
        result = PkgDeps._get_latest_version(path)

        @test expected == result
    end

    @testset "_find_alternative_packages" begin
        MAX = 9
        pkg_to_compare = "package_name"
        packages = ["$(pkg_to_compare)_$(i)" for i in 1:MAX]

        result = PkgDeps._find_alternative_packages(pkg_to_compare, packages)
        @test length(result) == MAX
    end
end

@testset "reachable_registries" begin
    @testset "specfic registry -- $(typeof(v))" for v in ("Foobar", ["Foobar"])
        registry = only(reachable_registries("Foobar"; depots=DEPOT))

        @test registry.name == "Foobar"
    end

    @testset "all registries" begin
        registries = reachable_registries(; depots=DEPOT)

        @test length(registries) == 2
    end
end

@testset "users" begin
    all_registries = reachable_registries(; depots=DEPOT)

    @testset "specific registry - registered in another registry" begin
        dependents = users("DownDep", FOOBAR_REGISTRY; registries=[GENERAL_REGISTRY], depots=DEPOT)

        @test length(dependents) == 1
        [@test case in dependents for case in ["Case3"]]
    end

    @testset "all registries" begin
        dependents = users("DownDep", FOOBAR_REGISTRY; registries=all_registries, depots=DEPOT)

        @test length(dependents) == 3
        @test !("Case4" in dependents)
        [@test case in dependents for case in ["Case1", "Case2", "Case3"]]
    end
end
