memory = Array{Char}(undef, 16)
inbox = Array{Char}()
programCounter = 1
program = Array{CommandSet}()
outbox = Array{Char}()

register = ' '

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
    value::Union{Char, Integer}
    isPointer::Bool
end

function error(command::CommandSet, message::String)
    throw(ErrorException(
        "($programCounter) $(command.command) failed. " * message))
end

function isAddress(value)
    return value isa Integer && value[1] <= length(memory)
end

function isValue(value)
    return value isa Char && ' ' !== value
end

function getAddress(command::CommandSet)::Integer
    if !isAddress(command.value)
        error(command, "$(command.value) is no address")
    end

    if command.isPointer
        address = tryparse(Int, command.value)
        if nothing === address || address > length(memory)
            error(command, "pointed value $(command.value) is no address.")
        end
    else
        address = command.value
    end

    return address
end

function getNewProgramCounter(command::CommandSet)::Integer
    if !(command.value isa Integer) || command.value > length(program)
        error(command, "$(command.value) is no program counter address")
    end
    
    return command.value
end

function getMemoryValue(address)::Union{Nothing, Char}
    if ' ' === memory[address] 
        return nothing
    else
        return memory[address]
    end
end

function execute(command::CommandSet)
    if Inbox == command.command
        register = pop!(Inbox)

    elseif Outbox == command.command
        if ' ' === register
            error(command, "no value.")
        end
        push!(outbox, register)
        register = ' '

    elseif CopyFrom === command.command
        address = getAddress(command)

        if ' ' === memory[address]
            error(command, "no value at $(command.value).")
        end
        register = memory[command.value]

    elseif CopyTo == command.command
        if ' ' === register
            error(command, "no value.")
        end

        address = getAddress(command)
        memory[address] = register

    elseif command.command in (Add, Sub)
        address = getAddress(command)
        value = getMemoryValue(address)
        if nothing === value
            error(command, "no value at $address")
        elseif ' ' === register
            error(command, "no value")
        end

        register += Add === command.command ? value : -value

    elseif command.command in (Increment, Decrement)
        address = getAddress(command)
        value = getMemoryValue(address)
        if nothing === value
            error(command, "no value at $address")
        end
        memory[address] += Increment === command.command ? 1 : -1
        register = memory[address]

    elseif Jump === command.command
        address = getNewProgramCounter(command)
        programCounter = address - 1

    elseif JumpZero === command.command   
        address = getNewProgramCounter(command)
        if ' ' === register
            error(command, "no value")
        elseif 0 === register
            programCounter = address - 1
        end

    elseif JumpZero === command.command   
        address = getNewProgramCounter(command)
        if ' ' === register
            error(command, "no value")
        elseif register < 0
            programCounter = address - 1
        end 

    else
        error(command, "$(command.command) is not supported.")
    end
end

            
            
