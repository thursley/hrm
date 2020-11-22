board = Array{Char, 2}(undef, 30, 81)
for i in 1:length(board)
    board[i] = ' ' 
end

for row in eachrow(board)
    row[end] = '\n'
end

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
    board[point.y, point.x + width] = '\u2510'
    board[point.y + height, point.x] = '\u2514'
    board[point.y + height, point.x + width] = '\u2518'
    for x in point.x + 1:point.x + width - 1
        board[point.y, x] = '\u2500'
        board[point.y+height, x] = '\u2500'
    end
    for y in point.y + 1:point.y + height - 1
        board[y, point.x] = '\u2502'
        board[y, point.x + width] = '\u2502'
    end
end

function boxedNumber(point::Point, number::Integer)
    str = string(number)
    rectangle(point, 8, 2)
    for i in length(str):-1:1
        board[point.y + 1, point.x + 6 - length(str) + i] = str[i]
    end
end

# rectangle(Point(5, 5), 5, 5)
boxedNumber(Point(10, 10), 1024)
boxedNumber(Point(10, 12), 24)
update()

# for row in eachrow(board)
#     map(x -> print(string(x)), row)
#     print("\n")
# end

function printField(offset::Integer, field::AbstractMatrix{Char})
    printWithOffset(string::String) = begin
        print(repeat(" ", offset), string)
    end

    printHorizental() = begin
        printWithOffset(repeat("+---", width) * "+\n")
    end

    printValues(row::AbstractArray) = begin
        printWithOffset("")
        for value in row
            print("| $value ")
        end
        print("|\n")
    end

    height, width = size(field)

    for row in eachrow(field)
        printHorizental()
        printValues(row)
    end
    printHorizental()
end

# field = Array{Char, 2}(undef, 9, 9)
# printField(10, field)

