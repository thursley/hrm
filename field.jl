board = Array{Char, 2}(undef, 15, 80)
for i in 1:length(board)
    board[i] = 'x' 
end

for row in eachrow(board)
    map(x->print(string(x)), row)
    print("\n")
end

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

field = Array{Char, 2}(undef, 9, 9)
printField(10, field)