include("Engine.jl")

module Parser
using .Engine

commandMap = Dict(
    "in" => Engine.Inbox,
    "out" => Engine.Outbox,
    "copyfrom" => Engine.CopyFrom,
    "copyto" => Engine.CopyTo,
    "add" => Engine.Add,
    "sub" => Engine.Sub,
    "inc" => Engine.Increment,
    "dec" => Engine.Decrement,
    "jump" => Engine.Jump,
    "jumpz" => Engine.JumpZero,
    "jumpn" => Engine.JumpNegative
)

struct Label
    lineNumber::Integer
    name::String
end

function isLabel(input::String)::Bool
    return occursin(r"^[a-zA-Z0-9_]+:$", input)
end

function extractLabels!(input::Vector{String})::Dict{String, Integer}
    labels = Dict{String, Integer}()
    toRemove::Vector{Int} = []
    labelCount::Integer = 0
    for i in 1:length(input)
        if isLabel(input[i])
            labels[input[i][1:end-1]] = i - labelCount
            push!(toRemove, i)
            labelCount += 1
        end
    end
    for i in reverse(toRemove)
        deleteat!(input, i)
    end
    return labels
end

function error(line::String, text::String)
    throw(ErrorException(
        "ERROR: failed to parse '$line': " * text))
end

function parse(input::Vector{String})::Engine.Program
    program::Engine.Program = []
    labels = extractLabels!(input)
    for i in 1:length(input)
        params = split(input[i])
        
        if params[1] in ("in", "out")
            command = Engine.CommandSet(commandMap[params[1]], 0, false)
            push!(program, command)

        elseif params[1] in ("copyfrom", "copyto", "add", "sub", "inc", "dec")
            command = createAddressedCommand(params)
            push!(program, command)

        elseif params[1] in ("jump", "jumpz", "jumpn")
            command = createJumpCommand(params, labels)
            push!(program, command)
            
        else 
            error(line, "This is not a valid command.")
        end
    end

    return program
end

function getAddress(value::AbstractString)::Tuple{Bool, Integer}
    if '*' === value[1]
        return (true, Base.parse(Int64, value[2:end]))
    end

    return (false, Base.parse(Int64, value))
end

function createAddressedCommand(params::Vector{<:AbstractString})
    if length(params) != 2
        # error
    end

    command = commandMap[params[1]]
    (isPointer, address) = getAddress(params[2])
    return Engine.CommandSet(command, address, isPointer)
end

function createJumpCommand(
        params::Vector{<:AbstractString}, 
        labels::Dict{String, Integer}
)::Engine.CommandSet

    if length(params) != 2
        error(params..., "Length of command has to be 2, " *
                         "but is $(length(params)).")
    end

    if !haskey(labels, params[2])
        error(params..., "Label '$(params[2]) not in defined.")
    end

    return Engine.CommandSet(commandMap[params[1]], labels[params[2]], false)    
end

end # module

# program = Parser.parse([
#     "jump begin",
#     "output:",
#     "copyfrom 0",
#     "out",
#     "begin:",
#     "in",
#     "copyto 0",
#     "in",
#     "sub 0",
#     "jumpz output",
#     "jump begin"
# ])

# for command in program
#     println(command)
# end
