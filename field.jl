function printField(field::AbstractMatrix{Char})
    height, width = size(field)
    for h in 1:height
        for j in 1:width
            print("+---")
        end
        print("+\n")
        for j in 1:width
            print("| $(field[h, j]) ")
        end
        print("|\n")
    end
    for j in 1:width
        print("+---")
    end
    print("+\n")
end

field = ['1' '2'; '3' '4'; '5' '6' ]
printField(field)