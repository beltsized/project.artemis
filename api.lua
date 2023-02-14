local api  = {}
local http = require('coro-http')
local json = require('json')

local format  = string.format
local request = http.request
local decode  = json.decode

local BASE_URL = '' -- no api for u silly!

function api:fetchminegrid(slots, gameid)
    local _, res = request('GET', format('', BASE_URL), {
        {'slots', slots}, {'game-id', gameid}
    })

    return decode(res).msg
end

function api:fetchcrashpoint()
    local _, res = request('GET', format('', BASE_URL))

    return decode(res).msg
end

function api:getcustomer(userid)
    local _, res = request('GET', format('', BASE_URL, userid))

    return decode(res).msg
end

function api:getallcustomers()
    local _, res = request('GET', format('', BASE_URL))

    return decode(res).msg
end

function api:addcustomer(userid, subtype, subduration)
    local _, res = request('POST', format('', BASE_URL, userid), {
        {'subscription-type', subtype}, {'subscription-end', subduration}
    })

    local data = decode(res)

    return data.msg, data.error
end

function api:deletecustomer(userid)
    local _, res = request('DELETE', format('', BASE_URL, userid))
    local data = decode(res)

    return data.msg, data.error
end

return api
