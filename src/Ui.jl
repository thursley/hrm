
struct Point
    x::Integer
    y::Integer
end

function update()
    # TODO clear screen
    for row in eachrow(board)
        print(row...)
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


programWidth = maximum(map(line -> length(line), program))
programHeight = length(program)

rectangle(Point(4,4), programWidth + 2, programHeight + 2)
for i in 1:length(program)
    for j in 1:length(program[i])
        board[i+4, j+4] = program[i][j]
    end
end
update()



