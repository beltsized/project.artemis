local info      = require('./info')
local discordia = require('discordia')
local api       = require('./api')
local cmds      = require('./cmds')

local PREFIX   = info.prefix
local TOKEN    = info.token
local SETTINGS = info.settings
local OWNERS   = info.owners

discordia.extensions()

local remove, search  = table.remove, table.search
local format          = string.format

local client = discordia.Client(SETTINGS)

client:once('ready', function()
    print('project artemis ready')
end)

client:on('messageCreate', function(msg)
    if not msg.guild or msg.author.bot then
        return
    end

    local args = msg.content:split(' ')
    local cname = args[1]:sub(#PREFIX + 1)
    local cmd = cmds[cname]

    if not cmd then
        return
    end

    local author = msg.author.id
    local isowner = search(OWNERS, author)

    if cmd.owneronly and not isowner then
        return
    elseif cmd.buyeronly then
        local rmsg = api:getcustomer(author)
        
        if rmsg == 'non-customer' then
            return
        end
    end

    remove(args, 1)

    local success, err = pcall(cmd.respond, client, msg, args)

    if not success then
        return msg:reply(format('```%s```', err))
    end
end)

client:run(TOKEN)