using Test

include("../src/Parser.jl")

@testset "test_parse" begin
    testCases = [
        ("abc", false),
        ("   label:", false),
        (":", false),
        ("::", false),
        (",", false),
        ("^label:\$", false),
        ("", false),
        ("spacedLabel :", false),
        ("untrimmedLabel: ", false),
        ("realLabel:", true),
        ("9sdf:", true),
        ("1:", true),
        ("a:", true)
    ]
    
    labels = Parser.extractLabels!([x[1] for x in testCases])
    for testCase in testCases
        @test testCase[2] == haskey(labels, testCase[1][1:end-1])
    end
end