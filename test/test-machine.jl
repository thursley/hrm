using Test

include("../machine.jl")

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
    @test false === isAddress("")
    @test false === isAddress('a')
    @test false === isAddress(1.0)
    @test false === isAddress(0)
    @test false === isAddress(length(memory) + 1)
    for i in 1:length(memory)
        @test true === isAddress(i)
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
    memory[index] = pointer
    memory[pointer] = 3

    directCommand = CommandSet(CopyFrom, index, false)
    pointedCommand = CommandSet(CopyFrom, index, true)

    @test 1 === getAddress(directCommand)
    @test 2 === getAddress(pointedCommand)
end