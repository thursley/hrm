using Test

include("../machine.jl")

ram = Array{MemoryItem}(undef, 16)
inbox = Array{Union{Char, Integer}}(undef, 0)
outbox = Array{Union{Char, Integer}}(undef, 0)

machine = Machine(ram, MemoryItem(' '), inbox, outbox, 0)

@testset "test_error" begin
    command = CommandSet(CopyFrom, 0, true)
    testMessage = "this is a test message"
    message = ""
    try
        error(command, testMessage)
    catch exception
        message = exception.msg
    end
    @test "($programCounter) $(command.command) failed. " * testMessage == message
end

@testset "test_isAddress" begin
    @test false === isAddress(0, machine.ram)
    @test false === isAddress(length(machine.ram) + 1, machine.ram)
    for i in 1:length(machine.ram)
        @test true === isAddress(i, machine.ram)
    end
end

@testset "test_isValue" begin
     @test false === isValue(' ')
     @test true === isValue('a')
     @test true === isValue(1)
end

@testset "test_getAddress_success" begin
    index = 1::Int64
    pointer = 2::Int64
    machine.ram[index] = MemoryItem(pointer)
    machine.ram[pointer] = MemoryItem(3)

    directCommand = CommandSet(CopyFrom, index, false)
    pointedCommand = CommandSet(CopyFrom, index, true)

    @test 1 === getAddress(directCommand, machine.ram)
    @test 2 === getAddress(pointedCommand, machine.ram)
end

@testset "test_getNewProgramCounter" begin
    for i in 1:length(program)
        command = CommandSet(Jump, i, false)
        @test i === getNewProgramCounter(command)
    end 
    for j in (0, length(program) + 1)
        thrown = false
        try
            getNewProgramCounter(CommandSet(Jump, j, false))
        catch
            thrown = true
        end
        @test thrown
    end
end

@testset "test_execute_outbox" begin
    command = CommandSet(Outbox, 0, false)
    machine.register = MemoryItem(' ')
    thrown = false
    try
        execute!(command, machine)
    catch
       thrown = true
    end

    @test thrown

    value = 'a'
    machine.register = MemoryItem(value)
    execute!(command, machine)

    @test last(machine.outbox) == value
    @test ' ' == machine.register
end

@testset "test_execute_inbox" begin
    command = CommandSet(Inbox, 0, false)
    push!(machine.inbox, 'a')
    push!(machine.inbox, 'b')
    machine.register = MemoryItem(' ')
    execute!(command, machine)
    
    @test machine.register == 'b'
    @test last(machine.inbox) == 'a'
end

@testset "test_execute_copyfrom" begin
    index = 5
    pointer = 3
    secret = 47
    direct = CommandSet(CopyFrom, index, false)
    pointed = CommandSet(CopyFrom, index, true)
    machine.ram[index] = MemoryItem(pointer)
    machine.ram[pointer] = MemoryItem(secret)

    execute!(direct, machine)
    @test machine.register == pointer

    execute!(pointed, machine)
    @test machine.register == secret
end

@testset "test_execute_copyto" begin
    index = 5
    pointer = 3
    point = 7

    machine.ram[index] = MemoryItem(0)
    machine.ram[pointer] = MemoryItem(point)
    machine.ram[point] = MemoryItem(0)

    machine.register = MemoryItem('a')

    direct = CommandSet(CopyTo, index, false)
    pointed = CommandSet(CopyTo, pointer, true)

    execute!(direct, machine)
    @test 'a' == machine.register
    @test 'a' == machine.ram[index]

    machine.register = MemoryItem(47)
    execute!(pointed, machine)
    @test 47 == machine.register
    @test 47 == ram[point]

end

programMaxOfTwo = ([
    CommandSet(Inbox, 0, false)
    CommandSet(CopyTo, 1, false)
    CommandSet(Inbox, 0, false)
    CommandSet(Sub, 1, false)
    CommandSet(JumpNegative, 9, false)
    CommandSet(Add, 1, false)
    CommandSet(Outbox, 0, false)
    CommandSet(Jump, 1, false)
    CommandSet(CopyFrom, 1, false)
    CommandSet(Jump, 7, false)
],
[1,2,4,3,100,150,999,0],
[2, 4, 150, 999]
)

@testset "test_runProgram" begin
    init(machine)
    machine.inbox = Array{Union{Char, Integer}}(undef, 0)

    push!(machine.inbox, 'c')
    push!(machine.inbox, 'b')
    push!(machine.inbox, 'a')

    program = [
        CommandSet(Inbox, 0, false)
        CommandSet(Outbox, 0, false)
        CommandSet(Jump, 1, false)
    ]

    runProgram(machine, program)

    @test machine.outbox == ['a', 'b', 'c']
    init(machine)
    machine.inbox = reverse(programMaxOfTwo[2])
    runProgram(machine, programMaxOfTwo[1])
    @test machine.outbox == programMaxOfTwo[3]
end


