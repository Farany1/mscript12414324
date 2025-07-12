require "lib.moonloader"
local inicfg = require 'inicfg'
local bit = require("bit")
local socket = require("socket")
local io = require("io")
local http = require("socket.http")
local sampev = require 'lib.samp.events'
local vector = require("vector3d")
local ffi = require 'ffi'
ffi.cdef("bool SetCursorPos(int X, int Y);")
local encoding = require('encoding')
local u8 = encoding.UTF8
encoding.default = 'CP1251'
local effil = require('effil')
currentline = 0
seconds = 0
minutes = 0
port = 7777
players_col_act = true
car_col_act = false
obj_col_act = false
state = false
chekhealth = false
zaxod = true
file = io.open(getGameDirectory().."//moonloader//nicks.txt", "r")
ips = io.open(getGameDirectory().."//moonloader//serverips.txt", "r")

function autoupdate(json_url, prefix, url)
  local dlstatus = require('moonloader').download_status
  local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
  if doesFileExist(json) then os.remove(json) end
  downloadUrlToFile(json_url, json,
    function(id, status, p1, p2)
      if status == dlstatus.STATUSEX_ENDDOWNLOAD then
        if doesFileExist(json) then
          local f = io.open(json, 'r')
          if f then
            local info = decodeJson(f:read('*a'))
            updatelink = info.updateurl
            updateversion = info.latest
            f:close()
            os.remove(json)
            if updateversion ~= thisScript().version then
              lua_thread.create(function(prefix)
                local dlstatus = require('moonloader').download_status
                local color = -1
                sampAddChatMessage((prefix..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion), color)
                wait(250)
                downloadUrlToFile(updatelink, thisScript().path,
                  function(id3, status1, p13, p23)
                    if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                      print(string.format('Загружено %d из %d.', p13, p23))
                    elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                      print('Загрузка обновления завершена.')
                      sampAddChatMessage((prefix..'Обновление завершено!'), color)
                      goupdatestatus = true
                      lua_thread.create(function() wait(500) thisScript():reload() end)
                    end
                    if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                      if goupdatestatus == nil then
                        sampAddChatMessage((prefix..'Обновление прошло неудачно. Запускаю устаревшую версию..'), color)
                        update = false
                      end
                    end
                  end
                )
                end, prefix
              )
            else
              update = false
              print('v'..thisScript().version..': Обновление не требуется.')
            end
          end
        else
          print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..url)
          update = false
        end
      end
    end
  )
  while update ~= false do wait(100) end
end

local step = {500, 1000}

function QueryServerInfo(ip, port, timeout)
    local ret, response_data, isThread
    local s = socket.udp()
    s:setpeername(ip, port)
    s:settimeout(0)

    local request_data = ffi.new("char[11]", "\x53\x41\x4D\x50\x00\x00\x00\x00\x00\x00\x69")
    local wPort = ffi.new("uint16_t", port)
    local byteIp = {ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")}

    for i = 1, 4 do request_data[3+i] = tonumber(byteIp[i]) or 0 end
    request_data[8] = tonumber(wPort)
    request_data[9] = bit.rshift(tonumber(wPort), 8)
 
    s:send(ffi.string(request_data, 11))

    timeout = os.clock() + (((timeout ~= nil) and timeout or 3000) / 1000)
    isThread = pcall(wait, 0)
    while response_data == nil and os.clock() < timeout do
        if isThread then wait(0) end
        response_data = s:receive()
    end

    if response_data and response_data:len() > 11 and response_data:sub(1, 4) == "\x53\x41\x4D\x50" then
        local szData = ffi.new("char[?]", 1024, response_data)
        for i = response_data:len(), 1023 do szData[i] = 0 end

        local parse_data = function(offs, size)
            if size <= 0 then return ffi.new("char[1]", 0) end -- new
         
            local ret = ffi.new("char[?]", size, 0)
            for i = 0, tonumber(size) - 1 do
                ret[i] = szData[i + offs]
            end
            return ret
        end

        local bytePassword = ffi.new("uint8_t", szData[11])
        local wOnlinePlayers = ffi.cast("uint16_t*", parse_data(12, 2))[0]
        local wMaxPlayers = ffi.cast("uint16_t*", parse_data(14, 2))[0]
        local iHostNameLen = ffi.cast("uint32_t*", parse_data(16, 4))[0]
        local szHostName = parse_data(20, iHostNameLen)
        local iGameModeLen = ffi.cast("uint32_t*", parse_data(iHostNameLen + 20, 4))[0]
        local szGameMode = parse_data(iHostNameLen + 24, iGameModeLen)
        local iLanguageLen = ffi.cast("uint32_t*", parse_data(iHostNameLen + iGameModeLen + 24, 4))[0]
        local szLanguage = parse_data(iHostNameLen + iGameModeLen + 28, iLanguageLen)

        ret = {
            password = (bytePassword ~= 0),
            players = {
                online = tonumber(wOnlinePlayers),
                max = tonumber(wMaxPlayers)
            },
            hostname = ffi.string(szHostName, iHostNameLen),
            gamemode = ffi.string(szGameMode, iGameModeLen),
            language = ffi.string(szLanguage, iLanguageLen)
        }
    end

    s:close()
    return ret
end

function sendCustomPacket(text)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #text)
    raknetBitStreamWriteString(bs, text)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

function onReceivePacket(id, bs) 
    if id == 220 then
        raknetBitStreamIgnoreBits(bs, 8)
        if raknetBitStreamReadInt8(bs) == 17 then
            raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
            if str:find([[window%.executeEvent%('event%.setActiveView', `%["Blueprint"%]`%);]]) then
                lua_thread.create(function ()
                    math.randomseed(os.clock())
                    wait(math.random(step[1], step[2]))
                    sendCustomPacket('blueprint.complete')
                end)
                return false
            end
        end
    elseif id == 32 and rabota == 1 and state then
        chekhealth = false
        kachaccstop()
        lua_thread.create(function()
            wait(1000)
            if currentip == 1 then
                serverip = "185.169.134.43"
            elseif currentip == 2 then
                serverip = "185.169.134.44"
            elseif currentip == 3 then
                serverip = "185.169.134.45"
            elseif currentip == 4 then
                serverip = "185.169.134.5"
            elseif currentip == 5 then
                serverip = "185.169.134.59"
            elseif currentip == 6 then
                serverip = "185.169.134.61"
            elseif currentip == 7 then
                serverip = "185.169.134.107"
            elseif currentip == 8 then
                serverip = "185.169.134.109"
            elseif currentip == 9 then
                serverip = "185.169.134.166"
            elseif currentip == 10 then
                serverip = "185.169.134.171"
            elseif currentip == 11 then
                serverip = "185.169.134.172"
            elseif currentip == 12 then
                serverip = "185.169.134.173"
            elseif currentip == 13 then
                serverip = "185.169.134.174"
            elseif currentip == 14 then
                serverip = "80.66.82.191"
            elseif currentip == 15 then
                serverip = "80.66.82.190"
            elseif currentip == 16 then
                serverip = "80.66.82.188"
            elseif currentip == 17 then
                serverip = "80.66.82.168"
            elseif currentip == 18 then
                serverip = "80.66.82.159"
            elseif currentip == 19 then
                serverip = "80.66.82.200"
            elseif currentip == 20 then
                serverip = "80.66.82.144"
            elseif currentip == 21 then
                serverip = "80.66.82.132"
            elseif currentip == 22 then
                serverip = "80.66.82.128"
            elseif currentip == 23 then
                serverip = "80.66.82.113"
            elseif currentip == 24 then
                serverip = "80.66.82.82"
            elseif currentip == 25 then
                serverip = "80.66.82.87"
            elseif currentip == 26 then
                serverip = "80.66.82.54"
            elseif currentip == 27 then
                serverip = "80.66.82.39"
            elseif currentip == 28 then
                serverip = "80.66.82.33"
            end
            wait(1000)
            sampSendChat('/recon'.." "..serverip..":"..port)
            wait(20000)
            sampSendChat('/recon 15')
            wait(40000)
            local mainIni = inicfg.load({
                settings =
                {
                    iniexsist = true,
                    reloaded = true,
                    pass = pass,
                    user = user
                }
            })
            inicfg.save(mainIni, "bomjbots")
            wait(5000)
            thisScript():reload()
        end)
    end
end

local array = {}

function GetNearest3DText(search)
    for i = 0, 2049 do
        if sampIs3dTextDefined(i) then
            local text, color, x, y, z, distance, ignoreWalls, playerId, vehicleId = sampGet3dTextInfoById(i)
            local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
            local distance = getDistanceBetweenCoords3d(myX, myY, myZ, x, y, z)

            if text:find(search) then
                table.insert(array, {['text'] = text, ['position'] = {x, y, z}, ['distance'] = distance})
            end
        end
    end

    if #array >= 1 then
        table.sort( array, function(a, b) return (a.distance < b.distance) end)
        return true, array[1].text, array[1].position, array[1].distance
    end
    return false
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if id == 1 then
        regi = 1
    elseif id == 2 then
        regi = 2
    elseif id == 19999 then
        kick = true
    elseif id == 9208 then
        simka = true
    end
end

function SendWebhook(URL, DATA, callback_ok, callback_error)
    local function asyncHttpRequest(method, url, args, resolve, reject)
        local request_thread = effil.thread(function (method, url, args)
           local requests = require 'requests'
           local result, response = pcall(requests.request, method, url, args)
           if result then
              response.json, response.xml = nil, nil
              return true, response
           else
              return false, response
           end
        end)(method, url, args)
        if not resolve then resolve = function() end end
        if not reject then reject = function() end end
        lua_thread.create(function()
            local runner = request_thread
            while true do
                local status, err = runner:status()
                if not err then
                    if status == 'completed' then
                        local result, response = runner:get()
                        if result then
                           resolve(response)
                        else
                           reject(response)
                        end
                        return
                    elseif status == 'canceled' then
                        return reject(status)
                    end
                else
                    return reject(err)
                end
                wait(0)
            end
        end)
    end
    asyncHttpRequest('POST', URL, {headers = {['content-type'] = 'application/json'}, data = u8(DATA)}, callback_ok, callback_error)
end

function chekcol()
    if car_col_act then
        myPosX, myPosY, myPosZ = getCharCoordinates(PLAYER_PED)
        result, vehHandle = findAllRandomVehiclesInSphere(myPosX, myPosY, myPosZ, 25, true, true)
        if result then
            setCarCollision(vehHandle, false)
        end
    else
        myPosX, myPosY, myPosZ = getCharCoordinates(PLAYER_PED)
        result, vehHandle = findAllRandomVehiclesInSphere(myPosX, myPosY, myPosZ, 25, true, true)
        if result then
            if vehHandle then
                setCarCollision(vehHandle, true)
            end
        end
    end
end

function kachacc()
    thread1 = lua_thread.create_suspended(kachaccc)
    thread1:run()
end

function kachaccstop()
    thread1:terminate()
    thread3:terminate()
end

function test()
    local thread2 = lua_thread.create(testr)
    thread2:run()
end

function testr()
end

function discordsend()
    local current_attempt = 1

    ::label_try::
    local result = QueryServerInfo(ip, port, 1000)
    if result then
        print("Info about " .. ip .. ":")
        print("Password: " .. (result.password and "true" or "false"))
        print("Players: " .. result.players.online .. '/' .. result.players.max)
        print("Hostname: " .. result.hostname)
        print("Mode: " .. result.gamemode)
        print("Language: " .. result.language)
    else
        if current_attempt <= 5 then
            current_attempt = current_attempt + 1
            goto label_try
        end

        print("Error: cannot get info about " .. ip)
    end

    print()
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(myid)
    print(nick)
    ip = ip
    port = port
    name = result.hostname
    mainIni = inicfg.load({}, "bomjbots.ini")
    pass = mainIni.settings.pass
    user = mainIni.settings.user
    senddatatouser()
end

function password(pas)
    local pass = pas
    local mainIni = inicfg.load({}, "bomjbots.ini")
    mainIni.settings.pass = pass
    inicfg.save(mainIni, "bomjbots")
end

function setuser(uss)
    user = uss
    print(user)
    local mainIni = inicfg.load({}, "bomjbots.ini")
    mainIni.settings.user = user
    inicfg.save(mainIni, "bomjbots")
end

function timescript()
    while true do
        seconds = seconds + 1
        if seconds == 60 then
            seconds = 0
            minutes = minutes + 1
        end
        printStringNow(minutes..":"..seconds, 1000)
        wait(1000)
    end
end

function kachaccc()
    mainIni = inicfg.load({}, "bomjbots.ini")
    pass = mainIni.settings.pass
    user = mainIni.settings.user
    sampAddChatMessage(pass, -1)
    sampAddChatMessage(user, -1)
    thread3 = lua_thread.create_suspended(timescript)
    thread3:run()
    wait(3000)
    while true do
        if zaxod then
            if regi == 1 then
                wait(5000)
                sampSendDialogResponse(1, 1, 0, pass)
                wait(1000)
                sampSendDialogResponse(1, 1, 0)
                wait(1000)
                sampSendDialogResponse(1, 1, 0)
                wait(1000)
                sampSendDialogResponse(1, 1, 0)
                wait(5000)
                if kick == true then
                    sampSendChat('/recon 15')
                    wait(30000)
                    sampSendDialogResponse(2, 1, 0, pass)
                    sendkey(13)
                    wait(5000)
                    sampSendClickTextdraw(286)
                    wait(5000)
                    sampSendClickTextdraw(286)
                    wait(10000)
                    sendkey(13)
                    wait(2000)
                    sendkey(13)
                    wait(2000)
                    sendkey(13)
                    wait(2000)
                    sendkey(13)
                    wait(4000)
                    sendkey(13)
                    wait(4000)
                end
                sendkey(13)
                wait(5000)
                sampSendClickTextdraw(286)
                wait(5000)
                sampSendClickTextdraw(286)
                wait(5000)
                sendkey(13)
                wait(2000)
                sendkey(13)
                wait(2000)
                sendkey(13)
                wait(2000)
                sendkey(13)
                wait(7000)
                sendkey(13)
                wait(4000)
            elseif regi == 2 then
                wait(5000)
                sampSendDialogResponse(2, 1, 0, pass)
                wait(1000)
                sendkey(13)
                wait(5000)
                sampSendClickTextdraw(286)
                wait(5000)
                sampSendClickTextdraw(286)
                wait(5000)
                sendkey(13)
                wait(5000)
                sendkey(13)
                wait(1000)
                sendkey(13)
                wait(1000)
                sendkey(13)
                wait(500)
                runToPointbeg(1779.7640, -1894.4297)
                runToPointbeg(1773.2271, -1921.2283)
                sendkey(18)
                wait(1000)
                sendkey(13)
                wait(1000)
                if isCharInAnyCar(1) then
                    sampAddChatMessage('GO', -1)
                elseif isCharOnFoot(1) then
                    sendkey(18)
                    wait(1000)
                    sendkey(13)
                    wait(1000)
                end
            end
        end
        rabota = 1
        regi = 0
        state = true
        chekhealth = true
        wait(1000)
        if isCharInAnyCar(1) then
            sampAddChatMessage('GO', -1)
        elseif isCharOnFoot(1) then
            sendkey(13)
            wait(1000)
            sampAddChatMessage('GO', -1)
        end
        wait(1000)
        coordMaster(1503.2697,-1235.9581,14.4566)
        wait(1000)
        sendkey(13)
        wait(2000)
        if isCharInAnyCar(1) then
            sendkey(70)
        end
        wait(1000)
        obj_col_act = true
        chekcol()
        wait(3000)
        runToPointbeg(1522.3766, -1237.0568)
        runToPointbeg(1523.9780, -1249.7235)
        wait(4000)
        sendkey(13)
        wait(2000)
        runToPointbeg(1523.6302, -1264.3035)
        runToPointbeg(1513.4043, -1283.6663)
        runToPointbeg(1512.1971, -1287.7810)
        runToPointbeg(1498.8059, -1284.5940)
        runToPointbeg(1495.3263, -1280.1298)
        obj_col_act = false
        wait(3000)
        sendkey(13)
        wait(2000)
        runToPointbeg(1509.4061, 1345.8151)
        runToPointbeg(1510.8701, 1360.7457)
        wait(2000)
        sendkey(18)
        wait(2000)
        sendkey(13)
        wait(2000)
        sendkey(18)
        wait(2000)
        sendkey(13)
        wait(2000)
        sendkey(18)
        wait(2000)
        sendkey(13)
        wait(2000)
        sendkey(13)
        wait(2000)
        sendkey(13)
        wait(2000)
        runToPointbeg(1509.4061, 1345.8151)
        runToPointbeg(1496.4340,1338.2133)
        wait(15000)
        obj_col_act = true
        sendkey(13)
        wait(2000)
        sendkey(13)
        wait(2000)
        sendkey(13)
        wait(2000)
        sendkey(13)
        wait(2000)
        sendkey(13)
        wait(4000)
        runToPoint(1504.9763,-1288.0743)
        wait(1000)
        runToPoint(1506.7135, -1282.8953)
        car_col_act = false
        chekcol()
        wait(4000)
        sendkey(18)
        wait(1000)
        sendkey(13)
        wait(1000)
        sendkey(13)
        wait(2000)
        if isCharInAnyCar(1) then
            sampAddChatMessage('GO', -1)
        elseif isCharOnFoot(1) then
            sendkey(18)
            wait(1000)
            sendkey(70)
            wait(1000)
        end
        wait(4000)
        coordMaster(-77.6476,-308.2517,1.4297)
        wait(5000)
        sendkey(13)
        wait(2000)
        if isCharInAnyCar(1) then
            sendkey(70)
        end
        wait(2000)
        coordMaster(-86.3166,-299.4308,2.7646)
        wait(2000)
        sendkey(13)
        wait(2000)
        runToPoint(1951.6395, 1333.5083)
        wait(2000)
        click(916, 468)
        wait(2000)
        sendkey(13)
        wait(2000)
        sendkey(13)
        wait(2000)
        runToPointbeg(1951.5289, 1339.9854)
        runToPointbeg(1957.3792, 1340.1188)
        runToPointbeg(1957.6836, 1353.9434)
        runToPointbeg(1971.0997, 1356.7495)
        wait(2000)
        sendkey(13)
        wait(2000)
        sendkey(13)
        wait(2000)
        oryzia = 14
        while oryzia ~= 0 do
            if oryzia == 0 then
                break
            elseif oryzia ~= 0 then
                oryzia = oryzia - 1
                wait(1000)
                runToPoint(1972.8569, 1352.7001)
                wait(10000)
                runToPointbeg(1975.6506, 1353.6497)
                runToPointbeg(1984.3573, 1354.3240)
                runToPointbeg(1981.5759,1353.8472)
                runToPointbeg(1975.6506, 1353.6497)
                runToPointbeg(1971.0997, 1356.7495)
                wait(500)
                end
            end
        wait(1000)
        runToPoint(1972.8569, 1352.7001)
        wait(10000)
        runToPointbeg(1975.6506, 1353.6497)
        runToPoint(1982.9954, 1354.1296)
        wait(7000)
        sendkey(13)
        wait(2000)
        chekhealth = false
        state = false
        sendkey(13)
        wait(1000)
        sampSendChat('/recon 3')
        wait(12000)
        if regi == 1 then
            sampSendChat('/q')   
        elseif regi == 2 then
            state = true
            sampSendDialogResponse(2, 1, 0, pass)
            wait(4000)
            sendkey(13)
            wait(4000)
            sendkey(13)
            wait(10000)
            sendkey(13)
            wait(5000)
            sendkey(13)
            wait(1000)
            sendkey(13)
            wait(1000)
            sendkey(13)
            wait(1000)
            sendkey(13)
            wait(1000)
            sendkey(13)
            wait(1000)
            sendkey(13)
            wait(1000)
            sendkey(13)
            wait(1000)
            sendkey(13)
            wait(1000)
            sendkey(13)
            wait(1000)
            state = false
            sendkey(13)
            wait(1000)
            sampSendChat('/recon 3')
        end
        wait(12000)
        sampSendDialogResponse(2, 1, 0, pass)
        wait(10000)
        chekhealth = true
        state = true
        sendkey(13)
        wait(10000)
        sendkey(13)
        wait(3000)
        sendkey(13)
        wait(3000)
        --car_col_act = true
        --chekcol()
        runToPointbeg(1777.5171, -1895.2437)
        runToPointbeg(1809.1324, -1886.2566)
        runToPointbeg(1829.4222,-1861.5909)
        runToPointbeg(1842.5614,-1862.7593)
        runToPoint(1847.2635,-1866.8649)
        wait(3000)
        runToPoint(1847.5441, -1871.6066)
        wait(3000)
        sendkey(18)
        wait(3000)
        sendkey(13)
        wait(7000)
        local result, text, position, distance = GetNearest3DText('Магазин')
        if result then
            kassax, kassay, kassaz = position[1], position[2], position[3]
        end
        wait(1000)
        coordMaster(kassax, kassay, kassaz)
        wait(10000)
        sendkey(18)
        wait(2000)
        click(1340, 650)
        wait(2000)
        sendkey(13)
        wait(2000)
        sendkey(13)
        sendkey(13)
        sendkey(13)
        wait(2000)
        sendkey(89)
        wait(2000)
        click(1520, 415)
        wait(2000)
        click(1520, 430)
        wait(500)
        sampSendDialogResponse(9208, 1, 0)
        wait(2000)
        sendkey(13)
        wait(5000)
        sendkey(13)
        state = false
        if simka then
            discordsend()
        end
        chekhealth = false
        for line in file:lines() do
            if currentline == line then
                break
            end
            regi = 0
            nick = line
            currentline = currentline + 1
            print(nick)
            wait(1000)
            sampSendChat('/recon'.." "..nick)
            wait(5000)
            sampSendChat('/recon 15')
            wait(20000)
            break
        end
        simka = false
        car_col_act = false
        chekcol()
    end
end

function senddatatouser()
    if user == "farany" or "petuh" or "eblan1337" or "opezdal" or "dobriy" or "xack" or "oldi" then
        if user == "farany" then
            webhukurl = "https://discord.com/api/webhooks/1392131878210768926/4Cdun5vmwBPS8DOCa_qdCT7oofiZ-fx_urmpoVaW_E_dS_gFGuS4VHHZYd1r86pEXKYL"
        elseif user == "petuh" then
            webhukurl = "https://discord.com/api/webhooks/1392131961216176129/cbaAym2CXayWDfRUjw9E8IKz_nl3I4iGh2Da0caIXnKa52TUxoO2zWNoHMSPwCk1pjaJ"
        elseif user == "eblan1337" then
            webhukurl = "https://discord.com/api/webhooks/1392132025166594058/i4q11h4zWidRrpiKFvFLUE8nV_RFwtNUV7ndMZ0J0FV_9F5ZC2QSHh0BporSlyglU_xL"
        elseif user == "opezdal" then
            webhukurl = "https://discord.com/api/webhooks/1392134205625995464/v85J1SJcbCZHL2-WWX61fOaI_gGPla0upF86uqdr0VXPRXJ7SUVkp2iCG1pyZw_5Ndhy"
        elseif user == "dobriy" then
            webhukurl = "https://discord.com/api/webhooks/1392134170540769351/eujvIMXHCyKIXPPSKm4M7BeJOveG4n7hHLpDYFrvTXDuZOttTTh59y7kriMAJFcpa6G6"
        elseif user == "xack" then
            webhukurl = "https://discord.com/api/webhooks/1392218554530795600/uelYNmMtngL_ebg5yDBDLTh1DlY6wpPcNjDhdBvtE2488KDmiRGnNs-JCib38DazeV1a"
        elseif user == "oldi" then
            webhukurl = "https://discord.com/api/webhooks/1392429226258333716/mNpkNothqPVNmw3jWXWOY2S-s64FtcDjOgSfeUWCcOUPxMnj09e0ITAN99_GpNbDKYzH"
        else
            sampAddChatMessage('пошёл нахуй', -1)
        end
        SendWebhook(webhukurl, ([[{
            "content": null,
            "embeds": [
                {
                "description": "**Ник:**  `%s`\n**Пароль:** `%s`\n**Сервер:** `%s`",
                "color": 16711757
                }
            ],
            "attachments": []
            }]]):format(nick, pass, name))
        sampAddChatMessage('Успешно отправленно', -1)
    else
        sampAddChatMessage('пошёл нахуй', -1)
    end
end

function runToPoint(tox, toy)
    local x, y, z = getCharCoordinates(PLAYER_PED)
    local angle = getHeadingFromVector2d(tox - x, toy - y)
    local xAngle = math.random(-50, 50)/100
    setCameraPositionUnfixed(xAngle, math.rad(angle - 90))
    stopRun = false
    while getDistanceBetweenCoords2d(x, y, tox, toy) > 0.8 do
        setGameKeyState(1, -255)
        --setGameKeyState(16, 1)
        wait(1)
        x, y, z = getCharCoordinates(PLAYER_PED)
        angle = getHeadingFromVector2d(tox - x, toy - y)
        setCameraPositionUnfixed(xAngle, math.rad(angle - 90))
        if stopRun then
            stopRun = false
            break
        end
    end
end

function runToPointbeg(tox, toy)
    local x, y, z = getCharCoordinates(PLAYER_PED)
    local angle = getHeadingFromVector2d(tox - x, toy - y)
    local xAngle = math.random(-50, 50)/100
    setCameraPositionUnfixed(xAngle, math.rad(angle - 90))
    stopRun = false
    while getDistanceBetweenCoords2d(x, y, tox, toy) > 0.8 do
        setGameKeyState(1, -255)
        setGameKeyState(16, 1)
        wait(1)
        x, y, z = getCharCoordinates(PLAYER_PED)
        angle = getHeadingFromVector2d(tox - x, toy - y)
        setCameraPositionUnfixed(xAngle, math.rad(angle - 90))
        if stopRun then
            stopRun = false
            break
        end
    end
end

function sendkey(id)
    setVirtualKeyDown(id, true)
    wait(1000)    
    setVirtualKeyDown(id, false)
end

function click(x, y)
    ffi.C.SetCursorPos(x, y)
    setVirtualKeyDown(1, true)
    wait(100)
    setVirtualKeyDown(1, false)
end

function onSendPacket(id)
    if syncblock and (id == 200 or id == 207) then
        return false
    end
end
speed = 0

function coordMaster(x,y,z)
    local pos = {x,y,z}
    local char = {getCharCoordinates(PLAYER_PED)}
    local vecDist = getDistanceBetweenCoords3d(char[1], char[2], char[3], pos[1], pos[2], pos[3])
    local v = isCharInAnyCar(1) and storeCarCharIsInNoSave(1) or -1
    local coef = 4
    local start = os.time()
    local w = 50
    local step = 0
    local stepLimit = 20
    syncblock = true
    while getDistanceBetweenCoords3d(char[1], char[2], char[3], pos[1], pos[2], pos[3]) >= coef and syncblock do
        printStringNow(math.floor(100 - (getDistanceBetweenCoords3d(char[1], char[2], char[3], pos[1], pos[2], pos[3]) / vecDist) * 100).."% = "..speed.."ms - coef -  "..coef, 1555)
        local vector = vector(pos[1] - char[1], pos[2] - char[2], pos[3] - char[3])
        vector:normalize()
        char[1] = char[1] + vector.x * coef
        char[2] = char[2] + vector.y * coef
        char[3] = char[3] + vector.z * coef 
        if isCharInAnyCar(1) then
            coef = speed == 1.5 and 7 or 8
            SendVehicleSync(char[1], char[2], char[3])
            w = 50
            stepLimit = -1
        elseif isCharOnFoot(1) then
            coef = 4
            sendPlayerSync(char[1], char[2], char[3],0)
            w = 60
            stepLimit = -1
        end
        speed = speed < (isCharInAnyCar(1) and 1.5 or 1.0) and speed + 0.05 or speed 
        wait(w)
        
        step = step + 1
        if step == stepLimit then
            step = 0
            wait(300) 
        end
        if getDistanceBetweenCoords3d(char[1], char[2], char[3], pos[1], pos[2], pos[3]) <= coef then
            speed = 0
            syncblock = false
            setCharCoordinates(1,x,y,z)
        end
    end
end

function SendVehicleSync(x,y,z)
    local data = samp_create_sync_data("vehicle")
    data.vehicleId = select(2,sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(1)))
    data.position = {x,y,z}
    data.moveSpeed = {speed,speed,0.1}
    data.vehicleHealth = getCarHealth(storeCarCharIsInNoSave(1))
    data.send()
end

function sendPlayerSync(x, y, z)
	local data = samp_create_sync_data("player")
    data.position = {x,y,z}
    data.moveSpeed = {speed,0.1,0.1}
    data.send()
end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require 'ffi'
    local sampfuncs = require 'sampfuncs'
    local raknet = require 'samp.raknet'
    require 'samp.synchronization'

    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData}
    }
    local data = ffi.new('struct ' .. sync_traits[sync_type][1], {})
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_traits[sync_type][2])
        raknetBitStreamWriteBuffer(bs, tonumber(ffi.cast('uintptr_t', ffi.new('struct ' .. sync_traits[sync_type][1] .. '*', data))), ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    return setmetatable({send = func_send}, {__index = function(t, index) return data[index] end, __newindex = function(t, index, value) data[index] = value end})
end

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(0)
    end

    autoupdate("https://github.com/Farany1/mscript12414324/blob/main/update.json", '['..string.upper(thisScript().name)..']: ', "http://vk.com/qrlk.mods")

    math.randomseed(os.time())
    currentip = math.random(28)
    ip, port = sampGetCurrentServerAddress()
    sampRegisterChatCommand("kac", kachacc)
    sampRegisterChatCommand("kacstop", kachaccstop)
    sampRegisterChatCommand("user", setuser)
    sampRegisterChatCommand('test', test)
    sampRegisterChatCommand('pass', password)
    local mainIni = inicfg.load({}, "bomjbots.ini")
    if mainIni.settings.iniexsist == false then
        local mainIni = inicfg.load({
            settings =
            {
                iniexsist = true,
                reloaded = false
            }
        })
    end
    inicfg.save(mainIni, "bomjbots")
    local mainIni = inicfg.load({}, "bomjbots.ini")
    if mainIni.settings.reloaded == true then
        local mainIni = inicfg.load({}, "bomjbots.ini")
        mainIni.settings.reloaded = false
        inicfg.save(mainIni, "bomjbots")
        wait(1000)
        regi = 1
        wait(3000)
        kachacc()
    end

    while true do
        wait(0)
        
        if players_col_act then
            find_ped_x, find_ped_y, find_ped_z = getCharCoordinates(PLAYER_PED)
            result, pedHandle = findAllRandomCharsInSphere(find_ped_x, find_ped_y, find_ped_z, 25, true, false)
            if result then
                setCharCollision(pedHandle, false)
            end
        else
            find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(PLAYER_PED)
            result, pedHandle = findAllRandomCharsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true, false)
            if result then
                setCharCollision(pedHandle, true)
            end
        end

        if obj_col_act then
            find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(PLAYER_PED)
            result, objectHandle = findAllRandomObjectsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true)
            if result then
                setObjectCollision(objectHandle, false)
            end
        else
            find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(PLAYER_PED)
            result, objectHandle = findAllRandomObjectsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true)
            if result then
                setObjectCollision(objectHandle, true)
            end
        end
        if getCharHealth(PLAYER_PED) < 24 and chekhealth then
            chekhealth = false
            kachaccstop()
            wait(10000)
            lua_thread.create(function()
                wait(1000)
                if currentip == 1 then
                    serverip = "185.169.134.43"
                elseif currentip == 2 then
                    serverip = "185.169.134.44"
                elseif currentip == 3 then
                    serverip = "185.169.134.45"
                elseif currentip == 4 then
                    serverip = "185.169.134.5"
                elseif currentip == 5 then
                    serverip = "185.169.134.59"
                elseif currentip == 6 then
                    serverip = "185.169.134.61"
                elseif currentip == 7 then
                    serverip = "185.169.134.107"
                elseif currentip == 8 then
                    serverip = "185.169.134.109"
                elseif currentip == 9 then
                    serverip = "185.169.134.166"
                elseif currentip == 10 then
                    serverip = "185.169.134.171"
                elseif currentip == 11 then
                    serverip = "185.169.134.172"
                elseif currentip == 12 then
                    serverip = "185.169.134.173"
                elseif currentip == 13 then
                    serverip = "185.169.134.174"
                elseif currentip == 14 then
                    serverip = "80.66.82.191"
                elseif currentip == 15 then
                    serverip = "80.66.82.190"
                elseif currentip == 16 then
                    serverip = "80.66.82.188"
                elseif currentip == 17 then
                    serverip = "80.66.82.168"
                elseif currentip == 18 then
                    serverip = "80.66.82.159"
                elseif currentip == 19 then
                    serverip = "80.66.82.200"
                elseif currentip == 20 then
                    serverip = "80.66.82.144"
                elseif currentip == 21 then
                    serverip = "80.66.82.132"
                elseif currentip == 22 then
                    serverip = "80.66.82.128"
                elseif currentip == 23 then
                    serverip = "80.66.82.113"
                elseif currentip == 24 then
                    serverip = "80.66.82.82"
                elseif currentip == 25 then
                    serverip = "80.66.82.87"
                elseif currentip == 26 then
                    serverip = "80.66.82.54"
                elseif currentip == 27 then
                    serverip = "80.66.82.39"
                elseif currentip == 28 then
                    serverip = "80.66.82.33"
                end
                wait(1000)
                sampSendChat('/recon'.." "..serverip..":"..port)
                wait(20000)
                sampSendChat('/recon 15')
                wait(40000)
                local mainIni = inicfg.load({
                    settings =
                    {
                        iniexsist = true,
                        reloaded = true,
                        pass = pass,
                        user = user
                    }
                })
                inicfg.save(mainIni, "bomjbots")
                wait(5000)
                thisScript():reload()
            end) 
        end
    end
end