local cmds = {}
local api  = require('./api')
local json = require('json')
local http = require('coro-http')

local decode               = json.decode
local format               = string.format
local insert               = table.insert
local date, difftime, time = os.date, os.difftime, os.time

local S_EMOJI = '<:success:1074911057488904263>'
local F_EMOJI = '<:failure:1074911017089384508>'

local SUBTYPE_ENUMS = {
    ['lifetime'] = (3.1536E+12),
    ['monthly']  = (2592000000)
}

local FAIL_ENUMS    = {
    ['slots']        = 'Slots value is greater than 25 or less than 1.',
    ['seed']         = 'Client-seed value is improperly formatted.',
    ['non-customer'] = 'That user is not a customer.',
    ['failure']      = 'The `Artemis API` failed to process the request, please retry.'
}

function failureformat(str, ...)
    return format('%s %s', F_EMOJI, format(str, ...))
end

function successformat(str, ...)
    return format('%s %s', S_EMOJI, format(str, ...))
end

for i, v in pairs(FAIL_ENUMS) do
    FAIL_ENUMS[i] = failureformat(v)
end

cmds['ping'] = {
    buyeronly = false,
    owneronly = true,
    info = 'Pong.',
    respond = function(client, msg)
        return msg:reply('Nope.')
    end
}

cmds['mines'] = {
    buyeronly = false,
    owneronly = true,
    info = 'Predicts a mines game.',
    respond = function(client, msg, args)
        local slots = tonumber(args[1])
        local gameid = args[2]

        if not slots then
            return msg:reply(successformat('Parameter `slots` must be a number.'))
        end

        local notif = msg:reply(successformat('Requesting mine prediction from the `Artemis API`...'))
        local rmsg = api:fetchminegrid(slots, gameid)
        local failmsg = FAIL_ENUMS[rmsg]

        return notif:setContent(failmsg or rmsg)
    end
}

cmds['addcustomer'] = {
    buyeronly = false,
    owneronly = true,
    info = 'Adds a new customer to the database.',
    respond = function(client, msg, args)
        local user = msg.mentionedUsers.first

        if not user then
            return msg:reply('Provide a user first.')
        end

        local subtype = args[1]
        local subduration = SUBTYPE_ENUMS[subtype]

        if not subduration then
            return msg:reply(failureformat('Invalid susbcription type, must be one of: `lifetime`, `monthly`'))
        end

        local userid = user.id
        local notif = msg:reply(successformat('Adding customer using the `Artemis API`...'))
        local rmsg = api:addcustomer(userid, subtype, subduration)
        local failmsg = FAIL_ENUMS[rmsg]

        return notif:setContent(failmsg or successformat('<@!%s> is now a registered customer.', userid))
    end
}

cmds['deletecustomer'] = {
    buyeronly = false,
    owneronly = true,
    info = 'Deletes a customer from the database.',
    respond = function(client, msg, args)
        local user = msg.mentionedUsers.first

        if not user then
            return msg:reply('Provide a user first.')
        end

        local userid = user.id
        local notif = msg:reply(successformat('Deleting customer using the `Artemis API`...'))
        local rmsg = api:deletecustomer(userid)
        local failmsg = FAIL_ENUMS[rmsg]

        return notif:setContent(failmsg or successformat('<@!%s> is no longer a registered customer.', userid))
    end
}

cmds['customerinfo'] = {
    buyeronly = false,
    owneronly = true,
    info = 'Gets a customer\'s info from the database.',
    respond = function(client, msg, args)
        local user = msg.mentionedUsers.first

        if not user then
            return msg:reply('Provide a user first.')
        end

        local userid = user.id
        local notif = msg:reply(successformat('Requesting customer info from the `Artemis API`...'))
        local rmsg = api:getcustomer(userid)
        local failmsg = FAIL_ENUMS[rmsg]
        local istable = type(rmsg) == 'table'
        local subsince = istable and rmsg['subscribedSince'] or nil
        local subduration = istable and rmsg['subscriptionEnd'] or nil
        local subseconds = subsince / 1000
        local durseconds = subduration / 1000
        local subdate = subsince and date('%x', subseconds) or nil
        local timeleft = istable and (durseconds - (time() - subseconds)) or nil
        local days = timeleft / 86400

        return notif:setContent(failmsg or successformat('<@!%s> has been a customer since %s, giving them %d days left.', userid, subdate, days))
    end
}

cmds['crash'] = {
    buyeronly = false,
    owneronly = true,
    info = 'Predicts a crash game.',
    respond = function(client, msg, args)
        local notif = msg:reply(successformat('Requesting crash prediction from the `Artemis API`...'))
        local rmsg = api:fetchcrashpoint()
        local failmsg = FAIL_ENUMS[rmsg]

        return notif:setContent(failmsg or successformat('Crash point expected to be less than or greater to `%dx`.', rmsg))
    end
}

return cmds