
@enum Command begin
    Inbox
    Outbox
    CopyFrom
    CopyTo
    Add
    Sub
    Increment
    Decrement
    Jump
    JumpZero
    JumpNegative
end

struct CommandSet
    command::Command
    address::Integer
    isPointer::Bool
end

mutable struct Machine
    ram::Array{Union{Char, Integer}}
    register::Union{Char, Integer}
    inbox::Array{Union{Char, Integer}}
    outbox::Array{Union{Char, Integer}}
    programCounter::Integer
end

function error(command::CommandSet, message::String)
    throw(ErrorException(
        "($programCounter) $(command.command) failed. " * message))
end

function isAddress(value, memory::Array{Union{Char, Integer}})
    return (value isa Int64) && (0 < value <= length(memory))
end

function isValue(value)
    return ' ' !== value
end

function getAddress(command::CommandSet, memory::Array{Union{Char, Integer}})::Integer
    if !isAddress(command.address, memory)
        error(command, "$(command.address) is no address")
    end

    if command.isPointer
        # we have to convert here, or compile will think this is a Char
        address = convert(Int64, memory[command.address])
        if !isAddress(address, memory)
            error(command, "pointed value $address is no address.")
        end
    else
        address = command.address
    end

    return address
end

function getNewProgramCounter(command::CommandSet)::Integer
    value = command.address
    if !(value isa Integer) || value > length(program) || value < 1
        error(command, "$(command.address) is no program counter address")
    end
    
    return command.address
end

function getMemoryValue(address, memory::Array{Union{Char, Integer}})::Union{Nothing, Char}
    if ' ' === memory[address] 
        return nothing
    else
        return memory[address]
    end
end

function execute!(command::CommandSet, machine::Machine)
    if Inbox === command.command
        machine.register = pop!(machine.inbox)

    elseif Outbox === command.command
        if ' ' === machine.register
            error(command, "no value.")
        end
        push!(machine.outbox, machine.register)
        machine.register = ' '

    elseif CopyFrom === command.command
        address = getAddress(command, machine.ram)

        if ' ' === machine.ram[address]
            error(command, "no value at $(command.address).")
        end
        machine.register = machine.ram[address]

    elseif CopyTo == command.command
        if ' ' === machine.register
            error(command, "no value.")
        end

        address = getAddress(command, machine.ram)
        machine.ram[address] = machine.register

    elseif command.command in (Add, Sub)
        address = getAddress(command, machine.ram)
        value = getMemoryValue(address, machine.ram)
        if nothing === value
            error(command, "no value at $address")
        elseif ' ' === machine.register
            error(command, "no value")
        end

        machine.register += Add === command.command ? value : -value

    elseif command.command in (Increment, Decrement)
        address = getAddress(command, machine.ram)
        value = getMemoryValue(address, machine.ram)
        if nothing === value
            error(command, "no value at $address")
        end
        machine.ram[address] += Increment === command.command ? 1 : -1
        machine.register = machine.ram[address]

    elseif Jump === command.command
        address = getNewProgramCounter(command)
        programCounter = address - 1

    elseif JumpZero === command.command   
        address = getNewProgramCounter(command)
        if ' ' === machine.register
            error(command, "no value")
        elseif 0 === machine.register
            programCounter = address - 1
        end

    elseif JumpZero === command.command   
        address = getNewProgramCounter(command)
        if ' ' === machine.register
            error(command, "no value")
        elseif machine.register < 0
            programCounter = address - 1
        end 

    else
        error(command, "$(command.command) is not supported.")
    end
end
            
program = Array{CommandSet}(undef, 60)

function init(machine::Machine)
    machine.programCounter = 1
    for i in range 1:length(machine.ram)
        machine.ram[i] = ' '
    end
    machine.register = ' ' 
    machine.outbox = Array{Union{Char, Integer}}()
end
    

function runProgram(machine::Machine, program::Array{CommandSet})

    nextCommand = program[machine.programCounter]

    programFinished() = begin
        return machine.programCounter > length(program) ||
               (Inbox === nextCommand.command && 0 === length(machine.inbox))
    end

    while !programFinished()
        execute!(program[machine.programCounter], machine)
        machine.programCounter += 1
    end
end