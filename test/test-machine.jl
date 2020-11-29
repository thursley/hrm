using Test
using Hrm.Engine: programCounter, Machine, MemoryItem, runProgram!, execute!, 
    singleStep!, init!, Command, Inbox, Outbox, CopyFrom, CopyTo, Add, Sub, 
    Increment, Decrement, Jump, JumpNegative, JumpZero, error, isAddress, 
    getAddress, isValue, Program, getNewProgramCounter, Operation

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
    command::Command
    expectedOutcome::Machine
end

function testCommand(testCase::TestCase)::Bool
    execute!(testCase.command, testCase.machine)
    return testCase.expectedOutcome == testCase.machine
end

function testCommand(testee::Machine, command::Command, expected::Machine)
    return testCommand(TestCase(testee, command, expected))
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
    cmd = Command(CopyFrom, 0, true)
    testMessage = "this is a test message"
    message = ""
    try
        error(cmd, testMessage)
    catch exception
        message = exception.msg
    end
    @test ("ERROR: ($programCounter) $(cmd.operation) failed. " * testMessage 
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

    directCommand = Command(CopyFrom, index, false)
    pointedCommand = Command(CopyFrom, index, true)

    @test 1 === getAddress(directCommand, machine.ram)
    @test 2 === getAddress(pointedCommand, machine.ram)
end

@testset "test_getNewProgramCounter" begin
    for i in 1:100
        command = Command(Jump, i, false)
        @test i === getNewProgramCounter(command)
    end 
    thrown = false
    try
        getNewProgramCounter(Command(Jump, 0, false))
    catch
        thrown = true
    end
    @test thrown
    
end

@testset "test_execute_outbox" begin
    command = Command(Outbox, 0, false)
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
    command = Command(Inbox, 0, false)
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
    direct = Command(CopyFrom, index, false)
    pointed = Command(CopyFrom, index, true)
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

    direct = Command(CopyTo, index, false)
    pointed = Command(CopyTo, pointer, true)
    
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

    command = Command(Add, index, false)
    expected = copy(machine)
    expected.register = MemoryItem(offset + value)
    @test testCommand(machine, command, expected)
end

@testset "test_execute_sub" begin
    value = 7
    offset = 1009
    index = 1
    machine.ram[index] = MemoryItem(value)
    machine.register = MemoryItem(offset)

    command = Command(Sub, index, false)
    expected = copy(machine)
    expected.register = MemoryItem(offset - value)
    @test testCommand(machine, command, expected)
end

@testset "test_execute_increment" begin
    value = 16
    index = 12
    machine.ram[index] = MemoryItem(value)
    machine.register = MemoryItem('x')
    command = Command(Increment, index, false)
    expected = copy(machine)
    expected.register = MemoryItem(value + 1)
    expected.ram[index] = expected.register
    @test testCommand(machine, command, expected)
end

@testset "test_execute_decrement" begin
    value = 16
    index = 12
    machine.ram[index] = MemoryItem(value)
    machine.register = MemoryItem('x')
    command = Command(Decrement, index, false)
    expected = copy(machine)
    expected.register = MemoryItem(value - 1)
    expected.ram[index] = expected.register
    @test testCommand(machine, command, expected)
end

function testJump(oldPc, command, jumpExpected)::Bool
    machine.programCounter = oldPc
    expected = copy(machine)
    if jumpExpected
        expected.programCounter = command.address - 1
    end
    return testCommand(machine, command, expected)
end

@testset "test_execute_jump" begin
    command = Command(Jump, 18, false)
    @test testJump(7, command, true)
end

@testset "test_execute_jumpZero" begin
    command = Command(JumpZero, 58, false)

    machine.register = MemoryItem(0)
    @test testJump(5, command, true)
   
    machine.register = MemoryItem(-2)
    @test testJump(5, command, false)
   
    machine.register = MemoryItem(15)
    @test testJump(5, command, false)
end

@testset "test_execute_jumpNegative" begin
     command = Command(JumpNegative, 58, false)
    
    machine.register = MemoryItem(0)
    @test testJump(5, command, false)
   
    machine.register = MemoryItem(-2)
    @test testJump(5, command, true)
   
    machine.register = MemoryItem(15)
    @test testJump(5, command, false)
end

programMaxOfTwo = ([
    Command(Inbox, 0, false)
    Command(CopyTo, 1, false)
    Command(Inbox, 0, false)
    Command(Sub, 1, false)
    Command(JumpNegative, 9, false)
    Command(Add, 1, false)
    Command(Outbox, 0, false)
    Command(Jump, 1, false)
    Command(CopyFrom, 1, false)
    Command(Jump, 7, false)
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
        Command(Inbox, 0, false)
        Command(Outbox, 0, false)
        Command(Jump, 1, false)
    ]

    runProgram!(machine, program)

    @test machine.outbox == ['a', 'b', 'c']
    init!(machine)
    machine.inbox = reverse(programMaxOfTwo[2])
    runProgram!(machine, programMaxOfTwo[1])
    @test machine.outbox == programMaxOfTwo[3]
end


