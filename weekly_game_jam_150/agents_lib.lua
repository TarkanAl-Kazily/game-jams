--
-- agents_lib.lua
--
-- Author: Tarkan Al-Kazily
--
-- This library contains code and tables used to prototype an agent system
-- for Pico-8 (https://www.lexaloffle.com/pico-8.php)
--
-- The goal of this system is to be extendable to a variety of games,
-- and to give insight into how I would design a general task-based program

-- ===========================================================
-- # Agents Overview
--
-- An agent is something with agency that needs to be updated over time.
-- In this way, we break down the functionality into small aspects,
-- simplifying complexity.
--
-- Each agent has an init, update, and draw function, although not all
-- have to do anything. The init and update functions must both return a table.
-- The update function table is merged with the current agent's table.
--
-- Each agent needs to have a priority to order update and draw functions.
-- Priority values range from 1 (minimum) to the maximum table size,
-- with lower priority happening first. Agents can share priority - this
-- has no defined relative order.
-- ===========================================================

--[[
-- Creates the main table to manage all agents, needed to use library.
--]]
function agents_lib_init()
    local ret = {}
    -- Data structure of handles -> agents
    ret.agents = {}
    -- List of priorities -> list of agents
    ret.update_q = {}
    -- List of priorities -> list of agents
    ret.draw_q = {}
    ret.max_priority = 1
    return ret
end

--[[
-- Runs the update step for all agents in table
--
-- Arguments:
--  table: Datastructure returned by agents_lib_init
--]]
function agents_lib_update(table)
    for i=1, table.max_priority do
        if table.update_q[i] != nil then
            for a in all(table.update_q[i]) do
                local new_a = a.update(a)
                for k, v in pairs(new_a) do
                    a[k] = v
                end
            end
        end
    end
end


--[[
-- Runs the draw step for all agents in table
--
-- Arguments:
--  table: Datastructure returned by agents_lib_init
--]]
function agents_lib_draw(table)
    for i=1, table.max_priority do
        if table.draw_q[i] != nil then
            for a in all(table.draw_q[i]) do
                a.draw(a)
            end
        end
    end
end

-- ===========================================================
-- Creating/Removing Agents
--
-- This library defines three methods for interacting with agents.
--
-- agents_lib_create: Used to create a new agent.
-- ===========================================================

--[[
-- Creates a new agent, added into the given table
--
-- Arguments:
--  table: Datastructure returned by agents_lib_init
--  name: String name of the agent, populates agent handle
--  functions: Table defining init, update, and draw functions, in order
--  args: table of arguments for init
--  priority: An int or table of two ints for update/draw priority
--
-- Returns:
--  handle: resulting key for table.agents to get the agent context
--]]
function agents_lib_create(table, name, functions, args, priority)
    -- check if name exists, if so add a number to end
    local handle = name
    local n = 0
    while (table.agents[handle] != nil) do
        n += 1
        handle = name..n
    end

    if (functions[1] == nil) functions[1] = _agents_lib_nop
    if (functions[2] == nil) functions[2] = _agents_lib_nop
    if (functions[3] == nil) functions[3] = _agents_lib_nop

    -- create agent
    local a = functions[1](args)
    a.name = handle
    a.update = functions[2]
    a.draw = functions[3]
    -- assign priority
    if (type(priority) == "number") then
        a.priority = {priority, priority}
    elseif (type(priority) == "table") then
        a.priority = {priority[1], priority[2]}
    else
        assert("priority must be a number or table")
    end

    -- add agent to table
    _agents_lib_table_add_agent(table, a)

    return handle
end

--[[
-- Removes an agent from the table.
--
-- Arguments:
--  table: Datastructure returned by agents_lib_init
--  handle: String handle of the agent
--]]
function agents_lib_remove(table, handle)
    -- Check agent exists
    if table.agents[handle] == nil then
        return
    end

    a = table.agents[handle]
    -- Remove from update queue
    del(table.update_q[a.priority[1]], a)
    -- Remove from draw queue
    del(table.draw_q[a.priority[2]], a)
    -- must not use del with table.agents, since not a sequence
    table.agents[handle] = nil
end

--[[
-- Changes an agent's priority
--
-- Arguments:
--  table: Datastructure returned by agents_lib_init
--  handle: String handle of the angent
--  priority: New priority of agents - 0 means agent does not run
--]]
function agents_lib_change_priority(table, handle, priority)
    -- Check agent exists
    if table.agents[handle] == nil then
        return
    end

    a = table.agents[handle]
    -- Remove from update queue
    del(table.update_q[a.priority[1]], a)
    -- Remove from draw queue
    del(table.draw_q[a.priority[2]], a)

    -- assign priority
    if (type(priority) == "number") then
        a.priority = {priority, priority}
    elseif (type(priority) == "table") then
        a.priority = {priority[1], priority[2]}
    else
        assert("priority must be a number or table")
    end

    -- add agent to table
    _agents_lib_table_add_agent(table, a)
end

-- ===========================================================
-- Private Functions
-- ===========================================================

--[[
-- Handles the adding an agent to the necessary tables
--
-- Arguments:
--  table: Datastructure returned by agents_lib_init
--  a: Created agent
--]]
function _agents_lib_table_add_agent(table, a)
    table.agents[a.name] = a

    if (table.update_q[a.priority[1]] == nil) then
        table.update_q[a.priority[1]] = {a}
    else
        add(table.update_q[a.priority[1]], a)
    end

    if (table.draw_q[a.priority[2]] == nil) then
        table.draw_q[a.priority[2]] = {a}
    else
        add(table.draw_q[a.priority[2]], a)
    end

    table.max_priority = max(table.max_priority, max(a.priority[1], a.priority[2]))
end

--[[
-- Does nothing, used for default action of init, update, draw.
--
-- Returns:
--  new_state: empty table, which initialized/changes nothing
--]]
function _agents_lib_nop(args)
    return args
end

