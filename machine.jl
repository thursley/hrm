struct MemoryItem
    value::Integer
    isCharacter::Bool
end

MemoryItem(value::Integer) = MemoryItem(value, false)
MemoryItem(value::Char) = MemoryItem(convert(Int64, value), true)

function unwrap(item::MemoryItem)
    if item.isCharacter
        return convert(Char, item.value)
    else
        return item.value
    end
end

Base.:(==)(x::Char, y::MemoryItem) = begin
    return y.isCharacter && convert(Char, y.value) === x
end

Base.:(==)(y::MemoryItem, x::Char) = begin
    return x == y
end

Base.:(==)(x::Integer, y::MemoryItem) = begin
    return !y.isCharacter && y.value == x
end

Base.:(==)(y::MemoryItem, x::Integer) = begin
    return x == y
end

Base.:(+)(x::MemoryItem, y::MemoryItem) = begin
    if x.isCharacter || y.isCharacter
        throw(ErrorException("you can't add characters."))
    end
    return MemoryItem(x.value + y.value, false)
end

Base.:(-)(x::MemoryItem, y::MemoryItem) = begin
    if x.isCharacter != y.isCharacter
        throw(ErrorException("items have to be of same type when subtracting"))
    end
    return MemoryItem(x.value - y.value, false)
end

Base.:(-)(x::MemoryItem) = begin
    if x.isCharacter
        throw(ErrorException("can't get negative character."))
    end
    return MemoryItem(-x.value, x.isCharacter)
end

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

Program = Array{CommandSet}

mutable struct Machine
    ram::Array{MemoryItem}
    register::MemoryItem
    inbox::Array{Union{Char, Integer}}
    outbox::Array{Union{Char, Integer}}
    programCounter::Integer
end

function error(command::CommandSet, message::String)
    throw(ErrorException(
        "($programCounter) $(command.command) failed. " * message))
end

function isAddress(value::Integer, memory::Array{MemoryItem})
    return 0 < value <= length(memory)
end

function isAddress(value::MemoryItem, memory::Array{MemoryItem})
    return !value.isCharacter && (0 < value.value <= length(memory))
end

function isValue(value)
    return ' ' !== value
end

function getAddress(command::CommandSet, memory::Array{MemoryItem})::Integer
    if !isAddress(command.address, memory)
        error(command, "$(command.address) is no address")
    end

    if command.isPointer
        # we have to convert here, or compile will think this is a Char
        if !isAddress(memory[command.address], memory)
            error(command, "pointed value $address is no address.")
        end
        address = memory[command.address].value
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

function getMemoryValue(address, memory::Array{MemoryItem})::MemoryItem
    if ' ' == memory[address] 
        return nothing
    else
        return memory[address]
    end
end

function execute!(command::CommandSet, machine::Machine)
    if Inbox === command.command
        machine.register = MemoryItem(pop!(machine.inbox))

    elseif Outbox === command.command
        if ' ' == machine.register
            error(command, "no value.")
        end
        push!(machine.outbox, unwrap(machine.register))
        machine.register = MemoryItem(' ')

    elseif CopyFrom === command.command
        address = getAddress(command, machine.ram)

        if ' ' == machine.ram[address]
            error(command, "no value at $(command.address).")
        end
        machine.register = machine.ram[address]

    elseif CopyTo == command.command
        if ' ' == machine.register
            error(command, "no value.")
        end

        address = getAddress(command, machine.ram)
        machine.ram[address] = machine.register

    elseif command.command in (Add, Sub)
        address = getAddress(command, machine.ram)
        value = getMemoryValue(address, machine.ram)
        if nothing === value
            error(command, "no value at $address")
        elseif ' ' == machine.register
            error(command, "no value")
        end

        machine.register = Add === command.command ? 
            machine.register + value : machine.register - value

    elseif command.command in (Increment, Decrement)
        address = getAddress(command, machine.ram)
        value = getMemoryValue(address, machine.ram)
        if nothing === value
            error(command, "no value at $address")
        end
        machine.ram[address].value += Increment === command.command ? 1 : -1
        machine.register = machine.ram[address]

    elseif Jump === command.command
        address = getNewProgramCounter(command)
        # address will be incremented later.
        machine.programCounter = address - 1
        
    elseif JumpZero === command.command   
        address = getNewProgramCounter(command)
        if ' ' == machine.register
            error(command, "no value")
        elseif 0 == machine.register
            # address will be incremented later.
            machine.programCounter = address - 1
        end
        
    elseif JumpNegative === command.command   
        address = getNewProgramCounter(command)
        if ' ' == machine.register
            error(command, "no value")
        elseif machine.register.value < 0
            # address will be incremented later.
            machine.programCounter = address - 1
        end 

    else
        error(command, "$(command.command) is not supported.")
    end
end
            
program = Program(undef, 60)
programCounter = 0

function init!(machine::Machine)
    machine.programCounter = 1
    for i in 1:length(machine.ram)
        machine.ram[i] = MemoryItem(' ')
    end
    machine.register = MemoryItem(' ') 
    machine.outbox = Array{Union{Char, Integer}}(undef, 0)
end

function singleStep!(machine::Machine, program::Program)
    execute!(program[machine.programCounter], machine)
    machine.programCounter += 1
end

function isFinished(machine::Machine, program::Program)
    return machine.programCounter > length(program) ||
        (Inbox === program[machine.programCounter].command &&
             0 === length(machine.inbox))
end

function runProgram!(machine::Machine, program::Program)
    while !isFinished(machine, program)
        programCounter = machine.programCounter
        singleStep!(machine, program)
    end
end