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
    lines = map(testCases) do x
        x[1]
    end
    matches = map(testCases) do x
        x[2]
    end
    
    labels = Parser.extractLabels!(lines)
    labelNames = map(x -> x.name * ":", labels)
    for testCase in testCases
        @test testCase[2] == (testCase[1] in labelNames)
    end
end