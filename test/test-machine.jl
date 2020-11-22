using Test
using Hrm.Engine: programCounter, Machine, MemoryItem, runProgram!, execute!, 
    singleStep!, init!, CommandSet, Inbox, Outbox, CopyFrom, CopyTo, Add, Sub, 
    Increment, Decrement, Jump, JumpNegative, JumpZero, error, isAddress, 
    getAddress, isValue, Program, getNewProgramCounter, Command

import Base.copy

Base.:(==)(x::MemoryItem, y::MemoryItem) = begin
    return y.isCharacter == x.isCharacter && y.value == x.value
end

function Base.:(==)(m1::Machine, m2::Machine)
    return m1.ram == m2.ram &&
           m1.register == m2.register &&
           m1.inbox == m2.inbox &&
           m1.outbox == m2.outbox &&
           m1.programCounter == m2.programCounter
end

function copy(machine::Machine)::Machine 
    return Machine(
        copy(machine.ram),
        machine.register,
        copy(machine.inbox),
        copy(machine.outbox),
        machine.programCounter)
end

struct TestCase
    machine::Machine
    command::CommandSet
    expectedOutcome::Machine
end

function testCommand(testCase::TestCase)::Bool
    execute!(testCase.command, testCase.machine)
    return testCase.expectedOutcome == testCase.machine
end


ram = Vector{MemoryItem}(undef, 16)
inbox = Vector{Union{Char, Integer}}(undef, 0)
outbox = Vector{Union{Char, Integer}}(undef, 0)

machine = Machine(ram, MemoryItem(' '), inbox, outbox, 0)
init!(machine)

@testset "test_equality" begin
    machine2 = copy(machine)
    @test machine2 == machine
    @test machine2 !== machine
end

@testset "test_error" begin
    cmd = CommandSet(CopyFrom, 0, true)
    testMessage = "this is a test message"
    message = ""
    try
        error(cmd, testMessage)
    catch exception
        message = exception.msg
    end
    @test ("ERROR: ($programCounter) $(cmd.command) failed. " * testMessage 
            == message)
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
    for i in 1:100
        command = CommandSet(Jump, i, false)
        @test i === getNewProgramCounter(command)
    end 
    thrown = false
    try
        getNewProgramCounter(CommandSet(Jump, 0, false))
    catch
        thrown = true
    end
    @test thrown
    
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
    expected = copy(machine)
    push!(machine.inbox, 'b')
    machine.register = MemoryItem(' ')
    expected.register = MemoryItem('b')

    @test testCommand(TestCase(machine, command, expected)) 
end

@testset "test_execute_copyfrom" begin
    index = 5
    pointer = 3
    secret = 47
    direct = CommandSet(CopyFrom, index, false)
    pointed = CommandSet(CopyFrom, index, true)
    machine.ram[index] = MemoryItem(pointer)
    machine.ram[pointer] = MemoryItem(secret)

    expected = copy(machine)
    expected.register = MemoryItem(pointer)
    @test testCommand(TestCase(machine, direct, expected))
    
    expected.register = MemoryItem(secret)
    @test testCommand(TestCase(machine, pointed, expected))
end

@testset "test_execute_copyto" begin
    index = 5
    pointer = 3
    point = 7

    machine.ram[index] = MemoryItem(0)
    machine.ram[pointer] = MemoryItem(point)
    machine.ram[point] = MemoryItem(0)

    direct = CommandSet(CopyTo, index, false)
    pointed = CommandSet(CopyTo, pointer, true)
    
    machine.register = MemoryItem('a')
    expected = copy(machine)
    expected.ram[index] = expected.register
    @test testCommand(TestCase(machine, direct, expected))
    
    machine.register = MemoryItem(47)
    expected = copy(machine)
    expected.ram[point] = expected.register
    @test testCommand(TestCase(machine, pointed, expected))
end

@testset "test_execute_add" begin
    value = 7
    offset = 1009
    index = 1
    machine.ram[index] = MemoryItem(value)
    machine.register = MemoryItem(offset)

    command = CommandSet(Add, index, false)
    execute!(command, machine)
    @test value + offset == machine.register
    @test value == machine.ram[index]
end

@testset "test_execute_sub" begin
    value = 7
    offset = 1009
    index = 1
    machine.ram[index] = MemoryItem(value)
    machine.register = MemoryItem(offset)

    command = CommandSet(Sub, index, false)
    execute!(command, machine)
    @test offset - value == machine.register
    @test value == machine.ram[index]
end

@testset "test_execute_increment" begin
    value = 16
    index = 12
    machine.ram[index] = MemoryItem(value)
    machine.register = MemoryItem('x')
    command = CommandSet(Increment, index, false)
    execute!(command, machine)
    @test value + 1 == machine.ram[index]
    @test value + 1 == machine.register
end

@testset "test_execute_decrement" begin
    value = 16
    index = 12
    machine.ram[index] = MemoryItem(value)
    machine.register = MemoryItem('x')
    command = CommandSet(Decrement, index, false)
    execute!(command, machine)
    @test value - 1 == machine.ram[index]
    @test value - 1 == machine.register
end

@testset "test_execute_jump" begin
    oldPc = 7
    newPc = 18
    machine.programCounter = 7
    command = CommandSet(Jump, newPc, false)
    execute!(command, machine)
    @test newPc - 1 == machine.programCounter
end

@testset "test_execute_jumpZero" begin
    oldPc = 7
    newPc = 18
    machine.programCounter = 7
    command = CommandSet(JumpZero, newPc, false)
    machine.register = MemoryItem(0)
    execute!(command, machine)
    @test newPc - 1 == machine.programCounter

    machine.programCounter = oldPc
    machine.register = MemoryItem(-2)
    execute!(command, machine)
    @test oldPc == machine.programCounter

    machine.programCounter = oldPc
    machine.register = MemoryItem(15)
    execute!(command, machine)
    @test oldPc == machine.programCounter
end

@testset "test_execute_jumpZero" begin
    oldPc = 7
    newPc = 18
    machine.programCounter = 7
    command = CommandSet(JumpNegative, newPc, false)
    machine.register = MemoryItem(-2)
    execute!(command, machine)
    @test newPc - 1 == machine.programCounter

    machine.programCounter = oldPc
    machine.register = MemoryItem(0)
    execute!(command, machine)
    @test oldPc == machine.programCounter

    machine.programCounter = oldPc
    machine.register = MemoryItem(15)
    execute!(command, machine)
    @test oldPc == machine.programCounter
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
[1, 2, 4, 3, 100, 150, 999, 0],
[2, 4, 150, 999]
)

@testset "test_runProgram" begin
    init!(machine)
    machine.inbox = Array{Union{Char, Integer}}(undef, 0)

    push!(machine.inbox, 'c')
    push!(machine.inbox, 'b')
    push!(machine.inbox, 'a')

    program = [
        CommandSet(Inbox, 0, false)
        CommandSet(Outbox, 0, false)
        CommandSet(Jump, 1, false)
    ]

    runProgram!(machine, program)

    @test machine.outbox == ['a', 'b', 'c']
    init!(machine)
    machine.inbox = reverse(programMaxOfTwo[2])
    runProgram!(machine, programMaxOfTwo[1])
    @test machine.outbox == programMaxOfTwo[3]
end


