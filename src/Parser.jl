module Parser

include("Engine.jl")

struct Label
    lineNumber::Integer
    name::String
end

function extractLabels!(input::Vector{String})::Vector{Label}
    labels::Vector{Label} = []
    toRemove::Vector{Int} = []
    for i in 1:length(input)
        if occursin(r"^[a-zA-Z0-9_]+:$", input[i])
            push!(labels, Label(i, input[i][1:end-1]))
            push!(toRemove, i)
        end
    end
    for i in reverse(toRemove)
        deleteat!(input, i)
    end
    return labels
end

function parse(input::Vector{String})::Engine.Program
    program::Engine.Program = []
    labels = extractLabels!(input)
    lineNumber = 1
    # for line in input
    return program
end

end # module