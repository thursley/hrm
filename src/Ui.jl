import Base.show

include("Engine.jl")
include("Parser.jl")
# using .Engine
# using .Parser

function isAddressedCommand(command::Engine.Command)::Bool
    return command in (
        Engine.Add, Engine.Sub, 
        Engine.Increment, Engine.Decrement,
        Engine.CopyFrom, Engine.CopyTo)
end

function isJumpCommand(command::Engine.Command)::Bool
    return command in (Engine.Jump, Engine.JumpNegative, Engine.JumpZero)
end

function show(io::IO, command::Engine.CommandSet)
    name = findfirst(isequal(command.command), Parser.commandMap)
    print(io, "$(name)")
    if isAddressedCommand(command.command)
        if command.isPointer
            print(io, " [$(command.address)]")
        else 
            print(io, " $(command.address)")
        end
    elseif isJumpCommand(command.command)
        # TODO can we get label name here?
        print(io, " $(command.address)")
    end
end

function show(io::IO, program::Engine.Program)
    for line in program
        println(io, line)
    end
end

function show(io::IO, machine::Engine.Machine)
end
    

	

struct Point
    x::Integer
    y::Integer
end

function Base.:(+)(x::Point, y::Point)::Point
    return Point(x.x + y.x, x.y + y.y)
end

function update()
    # TODO clear screen
    for row in eachrow(board)
        print(row...)
    end
end

function rectangle!(field::Matrix{Char}, position::Point, 
                    width::Integer, height::Integer)
    
    field[point.y, point.x] = '\u250c'
    field[point.y, point.x + width - 1] = '\u2510'
    field[point.y + height - 1, point.x] = '\u2514'
    field[point.y + height - 1, point.x + width - 1] = '\u2518'
    for x in point.x + 1:point.x + width - 2
        field[point.y, x] = '\u2500'
        field[point.y + height - 1, x] = '\u2500'
    end
    for y in point.y + 1:point.y + height - 2
        field[y, point.x] = '\u2502'
        field[y, point.x + width - 1] = '\u2502'
    end
end

function rectangle(point::Point, width::Integer, height::Integer)
    board[point.y, point.x] = '\u250c'
    board[point.y, point.x + width - 1] = '\u2510'
    board[point.y + height - 1, point.x] = '\u2514'
    board[point.y + height - 1, point.x + width - 1] = '\u2518'
    for x in point.x + 1:point.x + width - 2
        board[point.y, x] = '\u2500'
        board[point.y + height - 1, x] = '\u2500'
    end
    for y in point.y + 1:point.y + height - 2
        board[y, point.x] = '\u2502'
        board[y, point.x + width - 1] = '\u2502'
    end
end

function boxedNumber(point::Point, number::Integer)
    str = string(number)
    rectangle(point, 8, 2)
    for i in length(str):-1:1
        board[point.y + 1, point.x + 6 - length(str) + i] = str[i]
    end
end

boardWidth = 81
boardHeight = 30

board = Matrix{Char}(undef, boardHeight, boardWidth)
for i in 1:boardHeight
    for j in 1:boardWidth
        if (j % boardWidth) == 0
            board[i, j] = '\n'
        else
            board[i, j] = ' '
        end
    end
end

rectangle(Point(1,1), boardWidth - 1, boardHeight)

program = (
    "jump begin",
    "output:",
    "copyfrom 0",
    "out",
    "begin:",
    "in",
    "copyto 0",
    "in",
    "sub 0",
    "jumpz output",
    "jump begin"
)

struct StrippedProgram
    program::Vector{String}
    labels::Dict{Integer, String}
end

function strip(program::Vector{String})::StrippedProgram
    count = 1
    labels::Dict{Integer, String} = Dict()
    stripped::Vector{String} = []
    for line in program
        if Parser.isLabel(line)
            labels[count] = line
        else
            count += 1
            push!(stripped, line)
        end
    end

    return StrippedProgram(program, labels)
end

function draw(position::Point, field::Matrix{Char})
    height, width = size(field)
    for i in 1:height
        for j in 1:width
            board[i + position.y, j + position.x] = field[i,j]
        end
    end
end 

function draw(position::Point, program::StrippedProgram)
    labelWidth = maximum(map(l -> length(l)), keys(program.labels))
    programWidth = maximum(map(line -> length(line), program))
    programHeight = length(program)

    rectangle!(point + Point(labelWidth, 0), programWidth + 2, programHeight + 2)
    for i in 1:length(program)
        for j in 1:length(program[i])
            board[i+4, j+4] = program[i][j]
        end
    end
end



    # rectangle(Point(4,4), programWidth + 2, programHeight + 2)
    # update()



