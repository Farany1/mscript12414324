---@diagnostic disable: undefined-global, lowercase-global

require 'lib.moonloader'

do -- begin hueta
    require("Direct3D9HookDll")
    local origAddEventHandler = addEventHandler
    local presentQueue = {}
    local lostQueue = {}
    local resetQueue = {}
    function addEventHandler(name, callback)
        if name == "onD3DPresent" then
            table.insert(presentQueue, callback)
        elseif name == "onD3DDeviceLost" then
            table.insert(lostQueue, callback)
        elseif name == "onD3DDeviceReset" then
            table.insert(resetQueue, callback)
        else
            origAddEventHandler(name, callback)
        end
    end
    function OnPresent()
        for i, callback in ipairs(presentQueue) do
            callback()
        end
    end
    function OnLost()
        for i, callback in ipairs(lostQueue) do
            callback()
        end
    end
    function OnReset()
        for i, callback in ipairs(resetQueue) do
            callback()
        end
    end

    origAddEventHandler("onScriptTerminate", function(scr)
        if scr == script.this then
            require("Direct3D9HookDll").Uninitialize()
        end
    end)
end -- end hueta

gmtoggled = false

local imgui = require 'mimgui'
local ffi = require 'ffi'
local hotkey = require('mimhotkey')
local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
local encoding = require 'encoding'
local sampev = require 'lib.samp.events'
local mem = require "memory"
local inicfg = require 'inicfg'
local ws, hs = getScreenResolution()
local cx = representIntAsFloat(readMemory(0xB6EC10, 4, false))
local cy = representIntAsFloat(readMemory(0xB6EC14, 4, false))
local xc, yc = ws * cy, hs * cx
amplification = {
-- weapon   speed multiplier (greater value = faster)
	-- [23]   =   4,    -- silenced pistol
	[24]   =   2.5,  -- desert eagle
}

local policemodels = {285, 280, 281, 282, 284, 300, 301, 302, 310, 311, 306, 307, 265, 266, 267, 286, 163, 164, 165}
local militarymodels = {253, 191, 179, 61, 255, 287}
local medmodels = {70, 71, 274, 275, 276, 308}

blockedModels={[509]=true,[481]=true,[510]=true,[448]=true,[531]=true,[532]=true,[572]=true,[441]=true,[464]=true,[465]=true,[501]=true,[564]=true}

local codeToKey = {
    [112] = "F1",
    [113] = "F2",
    [114] = "F3",
    [115] = "F4",
    [116] = "F5",
    [117] = "F6",
    [118] = "F7",
    [119] = "F8",
    [120] = "F9",
    [121] = "F10",
    [122] = "F11",
    [123] = "F12",
    [32] = "SPACE",
    [8] = "BACK",
    [9] = "TAB",
    [13] = "RETURN",
    [16] = "SHIFT",
    [17] = "CONTROL",
    [18] = "MENU",
    [20] = "CAPITAL",
    [27] = "ESCAPE",
    [45] = "INSERT",
    [33] = "PRIOR",
    [34] = "NEXT",
    [35] = "END",
    [36] = "HOME",
    [37] = "LEFT",
    [38] = "UP",
    [39] = "RIGHT",
    [40] = "DOWN",
    [46] = "DELETE",
    [44] = "SNAPSHOT",
    [145] = "SCROLL",
    [48] = "0",
    [49] = "1",
    [50] = "2",
    [51] = "3",
    [52] = "4",
    [53] = "5",
    [54] = "6",
    [55] = "7",
    [56] = "8",
    [57] = "9",
    [192] = "`",
    [189] = "-",
    [187] = "=",
    [219] = "[",
    [221] = "]",
    [186] = ";",
    [222] = "'",
    [220] = "\\",
    [188] = ",",
    [190] = ".",
    [191] = "/",
    [65] = "A",
    [66] = "B",
    [67] = "C",
    [68] = "D",
    [69] = "E",
    [70] = "F",
    [71] = "G",
    [72] = "H",
    [73] = "I",
    [74] = "J",
    [75] = "K",
    [76] = "L",
    [77] = "M",
    [78] = "N",
    [79] = "O",
    [80] = "P",
    [81] = "Q",
    [82] = "R",
    [83] = "S",
    [84] = "T",
    [85] = "U",
    [86] = "V",
    [87] = "W",
    [88] = "X",
    [89] = "Y",
    [90] = "Z",
    [91] = "LWIN",
    [92] = "RWIN"
}

rapidon = false

encoding.default = 'CP1251'
begcj = false
local u8 = encoding.UTF8
fisheyeislocked = false
fisheyeisenabled = false
local tab = 1

bike = {[481] = true, [509] = true, [510] = true}
moto = {[448] = true, [461] = true, [462] = true, [463] = true, [468] = true, [471] = true, [521] = true, [522] = true, [523] = true, [581] = true, [586] = true}

whbyp, whbypnicks = false, false
acsrem = false
activewh = false

local wm = require 'windows.message'
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof

if not doesFileExist("moonloader/config/bomjterminator.ini") then
    local mainIni = inicfg.load({
        settings =
        {
            cj = false,
            wh = false,
            skillgun = false,
            autobike = false,
            antibh = false,
            sbiv = false,
            rapid = false,
            fisheye = false,
            optimizationacs = false,
            rapidspeed = 1,
            antilomka = false,
            gmcar = false,
            c = false,
            ckey = 90,
            whnobypskeletal = false,
            antishlagbaum = false,
            gm = false,
            gmkey = 83,
            rapidkey = '[78]',
            menukey = '[45]',
            flipcar = false,
            flipkey = '[46]',
            skipzz = false,
            skiprep = false,
            nobike = false,
            nobikewater = false,
            noreload = false,
            aimmaxdist = 1,
            aimfov = 1,
            aimthroughtwall = false,
            aimon = false,
            drawcircle = false,
            zakladwh = false,
            nocamrestore = false
        }
    })
    inicfg.save(mainIni, "bomjterminator")
end
local flipcarCallBack = function()
    local mainIni = inicfg.load({}, 'bomjterminator')
    if mainIni.settings.flipcar then
        if isCharInAnyCar(PLAYER_PED) then
            local v = storeCarCharIsInNoSave(PLAYER_PED)
            setCarCoordinates(v, getCarCoordinates(v))
        end
    end
end
local mainIni = inicfg.load({}, "bomjterminator")
hotkey.no_flood = false
local renderWindow, checkboxcj, fpsupbomj, checkboxwh, skillgun, chbxautobike, chbxantibh, chbxsbiv, chbxrapid, Sliderrapid, chbxfisheye, fisheye1, fisheye2, whbyp, chbxantilomka, whbypnicks, gmcar, chbxc, chbxwhnobypskeletal, chbxantishlagbaum, cbxgm, chbxflipcar = new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.float(), new.bool(), new.int(100), new.int(70), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool()
local inputField = new.char[256]()
local sizeX, sizeY = getScreenResolution()
local otchetuncuff, otchetdubinka, otchetdeath, otchetmask, otchetgospolicewh, otchetgosmilitarywh, otchetgosmedwh, chbxskiprep, chbxskipzz, chbxnobikewater, chbxnobike, chbxnoreload, chbxzakladwh, nocamrestore = new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool(), new.bool() , new.bool()
local aimmaxdist, aimfov, aimthroughtwall, aimon, drawcircle = new.int(), new.int(), new.bool(), new.bool(), new.bool()
function loadcfg()
    checkboxcj[0] = mainIni.settings.cj
    checkboxwh[0] = mainIni.settings.wh
    skillgun[0] = mainIni.settings.skillgun
    chbxantibh[0] = mainIni.settings.antibh
    chbxautobike[0] = mainIni.settings.autobike
    chbxsbiv[0] = mainIni.settings.sbiv
    chbxrapid[0] = mainIni.settings.rapid
    chbxfisheye[0] = mainIni.settings.fisheye
    chbxantilomka[0] = mainIni.settings.antilomka
    gmcar[0] = mainIni.settings.gmcar
    chbxc[0] = mainIni.settings.c
    ckey = mainIni.settings.ckey
    chbxwhnobypskeletal[0] = mainIni.settings.whnobypskeletal
    chbxantishlagbaum[0] = mainIni.settings.antishlagbaum
    cbxgm[0] = mainIni.settings.gm
    gmkey = mainIni.settings.gmkey
    rapidkey = decodeJson(mainIni.settings.rapidkey)
    menukey = decodeJson(mainIni.settings.menukey)
    chbxflipcar[0] = mainIni.settings.flipcar
    flipkey = decodeJson(mainIni.settings.flipkey)
    chbxskipzz[0] = mainIni.settings.skipzz
    chbxskiprep[0] = mainIni.settings.skiprep
    chbxnobikewater[0] = mainIni.settings.nobikewater
    chbxnobike[0] = mainIni.settings.nobike
    chbxnoreload[0] = mainIni.settings.noreload
    Sliderrapid[0] = mainIni.settings.rapidspeed
    aimmaxdist[0] = mainIni.settings.aimmaxdist
    aimfov[0] = mainIni.settings.aimfov
    aimthroughtwall[0] = mainIni.settings.aimthroughtwall
    aimon[0] = mainIni.settings.aimon
    drawcircle[0] = mainIni.settings.drawcircle
    chbxzakladwh[0] = mainIni.settings.zakladwh
    nocamrestore[0] = mainIni.settings.nocamrestore
end

if not doesFileExist("moonloader/resource/bomj.png") then
    local dlstatus = require('moonloader').download_status
    downloadUrlToFile('https://raw.githubusercontent.com/Farany1/mscript12414324/refs/heads/main/bomj.png', 'moonloader/resource/bomj.png', function (id, status, p1, p2)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            sampAddChatMessage('файл загружен', -1)
        end
    end)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    theme()
    img = imgui.CreateTextureFromFile(getWorkingDirectory()..'/resource/bomj.png')
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    imFont = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14)..'\\trebucbd.ttf', 18, _, glyph_ranges)
end)

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(335, 800), imgui.Cond.FirstUseEver)
        imgui.Begin("BomjTerminator", renderWindow)
        if imgui.BeginTabBar('Tabs') then
            if imgui.BeginTabItem(u8'Основная вкладка') then
                imgui.Image(img, imgui.ImVec2(300, 270))
                if imgui.Button(u8'Первая страница') then tab = 1 end
                imgui.SameLine()
                if imgui.Button(u8'Вторая страница') then tab = 2 end
                if tab == 1 then
                    if imgui.Checkbox(u8'Фармильский бег', checkboxcj) then
                        mainIni.settings.cj = checkboxcj[0]
                        inicfg.save(mainIni, "bomjterminator")
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Ускоряет вашего персонажа')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8'Скилы оружия', skillgun) then
                        mainIni.settings.skillgun = skillgun[0]
                        inicfg.save(mainIni, "bomjterminator")
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Мощные скиллы оружия')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8'Автострелка', chbxautobike) then
                        mainIni.settings.autobike = chbxautobike[0]
                        inicfg.save(mainIni, "bomjterminator")
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Ускоряет езду на мотоцикле/велике (удерживайте LSHIFT)')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8'Anti-bunnyhop', chbxantibh) then
                        mainIni.settings.antibh = chbxantibh[0]
                        inicfg.save(mainIni, "bomjterminator")
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Вы сможете бегать и прыгать')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8'Сбив на X', chbxsbiv) then
                        mainIni.settings.sbiv = chbxsbiv[0]
                        inicfg.save(mainIni, "bomjterminator") 
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Сбивает анимацию')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8'Noreload', chbxnoreload) then
                        mainIni.settings.noreload = chbxnoreload[0]
                        inicfg.save(mainIni, "bomjterminator") 
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Автоматически перезаряжает оружие')
                        imgui.EndTooltip()
                    end
                    if imgui.Checkbox(u8'Fisheye', chbxfisheye) then
                        mainIni.settings.fisheye = chbxfisheye[0]
                        inicfg.save(mainIni, "bomjterminator")
                    end
                    if imgui.IsItemHovered() then
                        imgui.BeginTooltip()
                        imgui.Text(u8'Изменяет FOV, по умолчанию 100 и 70 для снайперки')
                        imgui.EndTooltip()
                    end
                    if imgui.SliderInt(u8'FOV', fisheye1, 40, 120) then
                        changefov = true
                        changefov = false
                    end
                    imgui.SliderInt(u8'FOV снайперки', fisheye2, 40, 120)
                    if imgui.CollapsingHeader(u8'Rapidfire') then
                        if imgui.Checkbox(u8'Rapid deagle', chbxrapid) then
                            mainIni.settings.rapid = chbxrapid[0]
                            inicfg.save(mainIni, "bomjterminator")
                        end
                        if imgui.IsItemHovered() then
                            imgui.BeginTooltip()
                            imgui.Text(u8'Ускоряет стрельбу с дигла')
                            imgui.EndTooltip()
                        end
                        if imgui.SliderFloat(u8'Скорость', Sliderrapid, 1, 6) then
                            mainIni.settings.rapidspeed = Sliderrapid[0]
                            inicfg.save(mainIni, "bomjterminator")
                        end
                        if imgui.IsItemHovered() then
                            imgui.BeginTooltip()
                            imgui.Text(u8'Изменяет скорость стрельбы с дигла (для изменения скорости нужно выключить и включить RapidFire)')
                            imgui.EndTooltip()
                        end
                        bndr = hotkey.KeyEditor('rapid', u8'Клавиша RapidFire')
                        if bndr then
                            mainIni.settings.rapidkey = encodeJson(bndr)
                            inicfg.save(mainIni, "bomjterminator")
                        end
                    end
                    if imgui.CollapsingHeader(u8'Aim') then
                        if imgui.Checkbox(u8'Silent Aim', aimon) then
                            mainIni.settings.aimon = aimon[0]
                            inicfg.save(mainIni, 'bomjterminator')
                        end
                        if imgui.Checkbox(u8'Сквозь стены', aimthroughtwall) then
                            mainIni.settings.aimthroughtwall = aimthroughtwall[0]
                            inicfg.save(mainIni, 'bomjterminator')
                        end
                        if imgui.SliderInt(u8'Fov', aimfov, 1, 90) then
                            mainIni.settings.aimfov = aimfov[0]
                            inicfg.save(mainIni, "bomjterminator")
                        end
                        if imgui.SliderInt(u8'Дистанция', aimmaxdist, 1, 200) then
                            mainIni.settings.aimmaxdist = aimmaxdist[0]
                            inicfg.save(mainIni, "bomjterminator")
                        end
                        if imgui.Checkbox(u8'Рисовать круг', drawcircle) then
                            mainIni.settings.drawcircle = drawcircle[0]
                            inicfg.save(mainIni, 'bomjterminator')
                        end
                    end
                elseif tab == 2 then
                    local mainIni = inicfg.load({}, "bomjterminator")
                    if imgui.Checkbox(u8'Антишлагбаум', chbxantishlagbaum) then
                        mainIni.settings.antishlagbaum = chbxantishlagbaum[0]
                        inicfg.save(mainIni, "bomjterminator")
                    end
                    if imgui.Checkbox(u8'Антиломка', chbxantilomka) then
                        mainIni.settings.antilomka = chbxantilomka[0]
                        inicfg.save(mainIni, "bomjterminator")
                    end
                    if imgui.Checkbox(u8'Гм авто', gmcar) then
                        mainIni.settings.gmcar = gmcar[0]
                        inicfg.save(mainIni, "bomjterminator")
                    end
                    if imgui.CollapsingHeader(u8'Вх') then
                        if imgui.CollapsingHeader(u8'Вх без обхода обс') then
                            if imgui.Checkbox(u8'Вх скелетоны', chbxwhnobypskeletal) then
                                mainIni.settings.whnobypskeletal = chbxwhnobypskeletal[0]
                                inicfg.save(mainIni, "bomjterminator")
                            end
                            if imgui.Checkbox(u8'Всевидящее око', checkboxwh) then
                                if checkboxwh[0] == true then
                                    nameTagOn()
                                else
                                    nameTagOff()
                                end
                            end
                        end
                        if imgui.CollapsingHeader(u8'Вх с обходом обс') then
                            imgui.Checkbox(u8'Вх (Обход обс)',whbyp)
                            if imgui.IsItemHovered() then
                                imgui.BeginTooltip()
                                imgui.Text(u8'Показывает персонажей через стены')
                                imgui.EndTooltip()
                            end
                            imgui.Checkbox(u8'Вх ники (Обход обс)',whbypnicks)
                        end
                        if imgui.CollapsingHeader(u8'Вх на гос') then
                            imgui.Checkbox(u8("ВХ на отчётиков"), otchetgospolicewh)
                            imgui.Checkbox(u8("ВХ на вояк"), otchetgosmilitarywh)
                            imgui.Checkbox(u8("ВХ на медиков"), otchetgosmedwh)
                        end
                        if imgui.Checkbox(u8'вх на закладки', chbxzakladwh) then
                            mainIni.settings.zakladwh = chbxzakladwh[0]
                            inicfg.save(mainIni, "bomjterminator")
                        end
                    end
                    if imgui.CollapsingHeader(u8'Настройки +C') then
                        if imgui.Checkbox(u8'+С', chbxc) then
                            mainIni.settings.c = chbxc[0]
                            inicfg.save(mainIni, "bomjterminator")
                        end
                        if imgui.Button(u8'Забиндить клавишу +C') then
                            bindc = true
                        end
                        imgui.Text(u8'Клавиша +C: '..kc)
                    end
                    if imgui.CollapsingHeader(u8'Настройки GM') then
                        if imgui.Checkbox(u8'Зажимной Гм', cbxgm) then
                            mainIni.settings.gm = cbxgm[0]
                            inicfg.save(mainIni, "bomjterminator")
                        end
                        if imgui.Button(u8'Забиндить клавишу GM') then
                            bindgm = true
                        end
                        imgui.Text(u8'Клавиша GM: '..kgm)
                    end
                    if imgui.CollapsingHeader(u8'Настройки flipcar') then
                        if imgui.Checkbox(u8'Флип кар', chbxflipcar) then
                            mainIni.settings.flipcar = chbxflipcar[0]
                            inicfg.save(mainIni, "bomjterminator")
                        end
                        if imgui.IsItemHovered() then
                            imgui.BeginTooltip()
                            imgui.Text(u8'Переворачивает ваше авто')
                            imgui.EndTooltip()
                        end
                        bndflipcar = hotkey.KeyEditor('flipcar', u8'Клавиша flipcar')
                        if bndflipcar then
                            mainIni.settings.flipkey = encodeJson(bndflipcar)
                            inicfg.save(mainIni, "bomjterminator")
                        end
                    end
                    if imgui.CollapsingHeader(u8'Настройки Nobike') then
                        if imgui.Checkbox(u8'Nobike', chbxnobike) then
                            mainIni.settings.nobike = chbxnobike[0]
                            inicfg.save(mainIni, "bomjterminator")
                        end
                        if imgui.Checkbox(u8'Падать в воде', chbxnobikewater) then
                            mainIni.settings.nobikewater = chbxnobikewater[0]
                            inicfg.save(mainIni, "bomjterminator")
                        end
                    end
                end
                imgui.EndTabItem()
            end
            if imgui.BeginTabItem(u8'Разное') then
                bndmenu = hotkey.KeyEditor('menu', u8'Клавиша открытия меню')
                if bndmenu then
                    mainIni.settings.menukey = encodeJson(bndmenu)
                    inicfg.save(mainIni, "bomjterminator")
                end
                if imgui.Checkbox(u8'Бомж оптимизация(+1 fps)', fpsupbomj) then
                    if fpsupbomj[0] == true then
                        fpsup = true
                        acsrem = not acsrem
                    else
                        fpsup = false
                        acsrem = false
                    end
                    if acsrem and fpsup then
                        for k, v in ipairs(getAllChars()) do
                            local res, id = sampGetPlayerIdByCharHandle(v)
                            if v ~= 1 and res and not sampIsPlayerNpc(id) then
                                deleteAllAcs(id)
                            end
                        end
                    elseif not fpsup then
                        sampAddChatMessage('Чтобы появились аксессуары, требуется перезагрузка зоны стрима (войдите в интерьер и выйдите)', -1)
                    end
                end
                if imgui.Checkbox(u8'Скип диалога ЗЗ', chbxskipzz) then
                    mainIni.settings.skipzz = chbxskipzz[0]
                    inicfg.save(mainIni, "bomjterminator")
                end
                if imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                    imgui.Text(u8'Закрывает диалог ЗЗ')
                    imgui.EndTooltip()
                end
                if imgui.Checkbox(u8'Скип диалога репорт', chbxskiprep) then
                    mainIni.settings.skiprep = chbxskiprep[0]
                    inicfg.save(mainIni, "bomjterminator")
                end
                if imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                    imgui.Text(u8'Закрывает диалог ответа на репорт')
                    imgui.EndTooltip()
                end
                if imgui.Checkbox(u8'NoCamRestore (extraWS)', nocamrestore) then
                    mainIni.settings.nocamrestore = nocamrestore[0]
                    inicfg.save(mainIni, "bomjterminator")
                else
                    mainIni.settings.nocamrestore = nocamrestore[0]
                    inicfg.save(mainIni, "bomjterminator")
                end
                if imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                    imgui.Text(u8'Убирает перевод камеры при +С')
                    imgui.EndTooltip()
                end
                imgui.EndTabItem()
            end
            if imgui.BeginTabItem(u8'Защитник') then
                imgui.Checkbox(u8("Снять наручники"), otchetuncuff)
		        imgui.Checkbox(u8("Анти Дубинка-Тайзер"), otchetdubinka)
                if imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                    imgui.Text(u8'Включать до удара отчётика')
                    imgui.EndTooltip()
                end
		        imgui.Checkbox(u8("Смерть"), otchetdeath)
		        imgui.Checkbox(u8("Авто использование маски"), otchetmask)
            end
            imgui.EndTabItem()
            imgui.EndTabBar()
        end
        imgui.End()
    end
)

function isKeyCheckAvailable()
	if not isSampLoaded() then
		return true
	end
	if not isSampfuncsLoaded() then
		return not sampIsChatInputActive() and not sampIsDialogActive()
	end
	return not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive()
end

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(0)
    end
    local bindrapidfireCallBack = function()
        chbxrapid[0] = not chbxrapid[0]
        printStringNow('Rapid: '..(chbxrapid[0] and 'ON' or 'OFF'), 1000)
    end
    loadcfg()
    local font = renderCreateFont("Courier New", 9, 7)
    hotkey.RegisterCallback('flipcar', flipkey, flipcarCallBack)
    hotkey.RegisterCallback('rapid', rapidkey, bindrapidfireCallBack)
    hotkey.RegisterCallback('menu', menukey, function() renderWindow[0] = not renderWindow[0] end)
    gameGetWeaponInfo = ffi.cast('struct CWeaponInfo* (__cdecl*)(int, int)', 0x743C60)
    local m_bLookingAtPlayer = ffi.cast("uint8_t*", 0xB6F028 + 0x2B)
	local m_pPlayerPed = ffi.cast("uintptr_t*", 0xB6F5F0)
    mem.setint8(0xB7CEE4, 1)
    sampAddChatMessage("{D2691E}[{DAA520}BomjTerminator{D2691E}] {FFFFFF}Успешно загружен! Открыть меню: {FF0000}/btt {FFFFFF}Авторы: {89CFF0}velmest, farany, kron", -1)
    sampRegisterChatCommand('btt', menu)
    while not isPlayerPlaying(playerped) do
        wait(1000)
    end
    while true do
        local mainIni = inicfg.load({}, "bomjterminator")
        kc = codeToKey[mainIni.settings.ckey]
        kgm = codeToKey[mainIni.settings.gmkey]
        if chbxc[0] then
            if isKeyDown(2) and isKeyJustPressed(mainIni.settings.ckey) then
                sendKey(4)
			    setGameKeyState(17, 255)
			    wait(55)
			    setGameKeyState(6, 0)
			    sendKey(2)
			    setGameKeyState(18, 255)
            end
        end
        if nocamrestore[0] then
            writeMemory(0x5231A6, 1, 0x90)
        else
            writeMemory(0x5231A6, 1, 0x75)
        end
        if chbxzakladwh[0] then
			for a = 1, 2048 do
				if sampIs3dTextDefined(a) then
					local string, color, vposX, vposY, vposZ, distance, ignoreWalls, playerId, vehicleId = sampGet3dTextInfoById(a)
					local X, Y, Z = getCharCoordinates(PLAYER_PED)
					local distances = getDistanceBetweenCoords2d(vposX, vposY, X, Y)
					if isPointOnScreen(vposX, vposY, vposZ, 0.0) and string.find(string, "Закладка") and distances > 4.0 then
						local wposX, wposY = convert3DCoordsToScreen(vposX, vposY, vposZ)
						renderFontDrawText(font, string, wposX, wposY, color)
					end
				end
			end
		end
        if isCharOnAnyBike(PLAYER_PED) and chbxnobike[0] then
            if chbxnobikewater[0] and isCarInWater(storeCarCharIsInNoSave(PLAYER_PED)) then
                local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                setCharCoordinates(PLAYER_PED, posX, posY, posZ - 3)
                wait(3000)
            elseif not isCarInWater(storeCarCharIsInNoSave(PLAYER_PED)) then
                setCharCanBeKnockedOffBike(PLAYER_PED, true)
            end
        else
            setCharCanBeKnockedOffBike(PLAYER_PED, false)
        end
        if chbxnoreload[0] then
            local bs = raknetNewBitStream()

			raknetBitStreamWriteInt32(bs, getCurrentCharWeapon(PLAYER_PED))
			raknetBitStreamWriteInt32(bs, 0)
			raknetEmulRpcReceiveBitStream(22, bs)
			raknetDeleteBitStream(bs)
        end
        if cbxgm[0] then
            if isKeyDown(mainIni.settings.gmkey) then
                setCharProofs(playerPed, true, true, true, true, true)
	            setCharOnlyDamagedByPlayer(playerPed, true)
	            writeMemory(9867629, 1, 1, true)
	            writeMemory(12046054, 1, 1, true)
	            makePlayerFireProof(PLAYER_HANDLE, true)
                printStringNow('GM: ON', 1500)
            else
                setCharProofs(playerPed, false, false, false, false, false)
                setCharOnlyDamagedByPlayer(playerPed, false)
                writeMemory(9867629, 1, 0, true)
                writeMemory(12046054, 1, 0, true)
                makePlayerFireProof(PLAYER_HANDLE, false)
            end
        else
            setCharProofs(playerPed, false, false, false, false, false)
            setCharOnlyDamagedByPlayer(playerPed, false)
            writeMemory(9867629, 1, 0, true)
            writeMemory(12046054, 1, 0, true)
            makePlayerFireProof(PLAYER_HANDLE, false)
        end
        if bindc then
            for i = 1, 255 do
                if isKeyDown(i) then
                    bindc = false
                    mainIni.settings.ckey = i
                    local mainIni = inicfg.save(mainIni, "bomjterminator")
                    break
                end
            end
        end
        if bindgm then
            for i = 1, 255 do
                if isKeyDown(i) then
                    bindgm = false
                    mainIni.settings.gmkey = i
                    local mainIni = inicfg.save(mainIni, "bomjterminator")
                    break
                end
            end
        end
        if otchetgospolicewh[0] then
            for v, k in pairs(getAllChars()) do
                local a = nil
                local result, id = sampGetPlayerIdByCharHandle(k)

                if isCharOnScreen(k) and id ~= -1 then
                    local x, y, z = getCharCoordinates(k)
                    local result, id = sampGetPlayerIdByCharHandle(k)
                    local xs1, ys1 = convert3DCoordsToScreen(x, y, z)
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    local xs2, ys2 = convert3DCoordsToScreen(px, py, pz)
                    local model = getCharModel(k)
                    local color = sampGetPlayerColor(id)
					local aa, rr, gg, bb = explode_argb(color)
					local color = join_argb(255, rr, gg, bb)
                    for i, v in pairs(policemodels) do
                        if model == v then
                            renderDrawLine(xs2, ys2, xs1, ys1, 2, color)
                        end
                    end
                end
            end
        end
        if otchetgosmilitarywh[0] then
            for v, k in pairs(getAllChars()) do
                local a = nil
                local result, id = sampGetPlayerIdByCharHandle(k)

                if isCharOnScreen(k) and id ~= -1 then
                    local x, y, z = getCharCoordinates(k)
                    local result, id = sampGetPlayerIdByCharHandle(k)
                    local xs1, ys1 = convert3DCoordsToScreen(x, y, z)
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    local xs2, ys2 = convert3DCoordsToScreen(px, py, pz)
                    local model = getCharModel(k)
                    local color = sampGetPlayerColor(id)
					local aa, rr, gg, bb = explode_argb(color)
					local color = join_argb(255, rr, gg, bb)
                    for i, v in pairs(militarymodels) do
                        if model == v then
                            renderDrawLine(xs2, ys2, xs1, ys1, 2, color)
                        end
                    end
                end
            end
        end
        if otchetgosmedwh[0] then
            for v, k in pairs(getAllChars()) do
                local a = nil
                local result, id = sampGetPlayerIdByCharHandle(k)

                if isCharOnScreen(k) and id ~= -1 then
                    local x, y, z = getCharCoordinates(k)
                    local result, id = sampGetPlayerIdByCharHandle(k)
                    local xs1, ys1 = convert3DCoordsToScreen(x, y, z)
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    local xs2, ys2 = convert3DCoordsToScreen(px, py, pz)
                    local model = getCharModel(k)
                    local color = sampGetPlayerColor(id)
					local aa, rr, gg, bb = explode_argb(color)
					local color = join_argb(255, rr, gg, bb)
                    for i, v in pairs(medmodels) do
                        if model == v then
                            renderDrawLine(xs2, ys2, xs1, ys1, 2, color)
                        end
                    end
                end
            end
        end
        if cbxgm[0] then
            if isKeyDown(gmkey) then
                setCharProofs(playerPed, true, true, true, true, true)
	            setCharOnlyDamagedByPlayer(playerPed, true)
	            writeMemory(9867629, 1, 1, true)
	            writeMemory(12046054, 1, 1, true)
	            makePlayerFireProof(PLAYER_HANDLE, true)
                printStringNow('GM: ON', 1500)
            end
        else
            setCharProofs(playerPed, false, false, false, false, false)
            setCharOnlyDamagedByPlayer(playerPed, false)
            writeMemory(9867629, 1, 0, true)
            writeMemory(12046054, 1, 0, true)
            makePlayerFireProof(PLAYER_HANDLE, false)
        end
        if checkboxcj[0] then
            setAnimGroupForChar(PLAYER_PED, "PLAYER")
        else
            setAnimGroupForChar(PLAYER_PED, (usePlayerAnimGroup and "PLAYER" or (isCharMale(PLAYER_PED) and "MAN" or "WOMAN")))
        end
        if otchetmask[0] then
			function sampev.onServerMessage(arg0, arg1)
				if arg1:find("Время действия маски истекло, вам пришлось ее выбросить.") then
					sampSendChat("/mask")
					sampAddChatMessage("У вас истекло время действие маски,но я прописал команду за вас!", 56576)

                    otchetmask[0] = false
					otchetmask[0] = true
				end
			end
		end
        if otchetdeath[0] then
			setCharHealth(PLAYER_PED, 0)
			addOneOffSound(0, 0, 0, 1058)

			otchetdeath[0] = false
		end
        if gmcar[0] then
            if isCharInAnyCar(PLAYER_PED) then
                local Handle = storeCarCharIsInNoSave(PLAYER_PED)
                mem.setint8(getCarPointer(Handle) + 0x40 + 0x0, isKeyDown(1) and 7 or 2, true)
                setCarProofs(Handle, true, true, true, true, true)
            end
        end
        if otchetuncuff[0] then
			sampSetSpecialAction(0)
			printStringNow("~g~~h~ UNCUFF!", 1000)
			addOneOffSound(0, 0, 0, 1139)

			otchetuncuff[0] = false
		end
        if otchetdubinka[0] then
			function sampev.onApplyPlayerAnimation()
				if otchetdubinka[0] then
					return false
				end
			end
		end
        if skillgun[0] then
            registerIntStat(70, 1000.0)
            registerIntStat(71, 1000.0)
            registerIntStat(72, 1000.0)
            registerIntStat(76, 1000.0)
            registerIntStat(77, 1000.0)
            registerIntStat(78, 1000.0)
            registerIntStat(79, 1000.0)
        end
        if chbxwhnobypskeletal[0] then
			if not isPauseMenuActive() and not isKeyDown(VK_F8) then
				for i = 0, sampGetMaxPlayerId() do
				if sampIsPlayerConnected(i) then
					local result, cped = sampGetCharHandleBySampPlayerId(i)
					local color = sampGetPlayerColor(i)
					local aa, rr, gg, bb = explode_argb(color)
					local color = join_argb(255, rr, gg, bb)
					if result then
						if doesCharExist(cped) and isCharOnScreen(cped) then
							local t = {3, 4, 5, 51, 52, 41, 42, 31, 32, 33, 21, 22, 23, 2}
							for v = 1, #t do
								pos1X, pos1Y, pos1Z = getBodyPartCoordinates(t[v], cped)
								pos2X, pos2Y, pos2Z = getBodyPartCoordinates(t[v] + 1, cped)
								pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
								pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
								renderDrawLine(pos1, pos2, pos3, pos4, 1, color)
							end
							for v = 4, 5 do
								pos2X, pos2Y, pos2Z = getBodyPartCoordinates(v * 10 + 1, cped)
								pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
								renderDrawLine(pos1, pos2, pos3, pos4, 1, color)
							end
							local t = {53, 43, 24, 34, 6}
							for v = 1, #t do
								posX, posY, posZ = getBodyPartCoordinates(t[v], cped)
								pos1, pos2 = convert3DCoordsToScreen(posX, posY, posZ)
							end
						end
					end
				end
			end
			else
				nameTagOff()
				while isPauseMenuActive() or isKeyDown(VK_F8) do wait(0) end
				nameTagOn()
			end
        end
        if chbxautobike[0] then
            if isCharOnAnyBike(playerPed) and isKeyCheckAvailable() and isKeyDown(0xA0) then	-- onBike&onMoto SpeedUP [[LSHIFT]] --
			    if bike[getCarModel(storeCarCharIsInNoSave(playerPed))] then
				    setGameKeyState(16, 255)
				    wait(10)
				    setGameKeyState(16, 0)
			    elseif moto[getCarModel(storeCarCharIsInNoSave(playerPed))] then
				    setGameKeyState(1, -128)
				    wait(10)
				    setGameKeyState(1, 0)
			    end
            end
        end
        if m_bLookingAtPlayer[0] == 1 then
			if not isCharSittingInAnyCar(PLAYER_PED) and isButtonPressed(PLAYER_HANDLE, 16) then
				local m_pPlayerData = ffi.cast("uintptr_t*", m_pPlayerPed[0] + 0x480)
				local m_fSprintEnergy = ffi.cast("float*", m_pPlayerData[0] + 0x1C)
				if m_fSprintEnergy[0] < 1 then
					m_fSprintEnergy[0] = 1
				end
			end
		end
        if chbxsbiv[0] then
            if isKeyJustPressed(88) and not sampIsCursorActive() then
                if not isCharInAnyCar(PLAYER_PED) then clearCharTasksImmediately(PLAYER_PED) setPlayerControl(playerHandle, 1) freezeCharPosition(PLAYER_PED, false) restoreCameraJumpcut() end
            end
        end
        if chbxfisheye[0] then
			if isCurrentCharWeapon(PLAYER_PED, 34) and isKeyDown(2) then
				if not fisheyeislocked then 
					cameraSetLerpFov(fisheye2[0], fisheye2[0], 999988888, true)
					fisheyeislocked = true
				end
			elseif not changefov then
				cameraSetLerpFov(fisheye1[0], fisheye1[0], 999988888, true)
				fisheyeislocked = false
			end
		else
            cameraSetLerpFov(70, 70, 999988888, true)
        end
        if chbxrapid[0] then
			pGunsAnimations = {
				"PYTHON_CROUCHFIRE",
				"PYTHON_FIRE",
				"PYTHON_FIRE_POOR",
				"PYTHON_CROCUCHRELOAD",
				"RIFLE_CROUCHFIRE",
				"RIFLE_CROUCHLOAD",
				"RIFLE_FIRE",
				"RIFLE_FIRE_POOR",
				"RIFLE_LOAD",
				"SHOTGUN_CROUCHFIRE",
				"SHOTGUN_FIRE",
				"SHOTGUN_FIRE_POOR",
				"SILENCED_CROUCH_RELOAD",
				"SILENCED_CROUCH_FIRE",
				"SILENCED_FIRE",
				"SILENCED_RELOAD",
				"TEC_crouchfire",
				"TEC_crouchreload",
				"TEC_fire",
				"TEC_reload",
				"UZI_crouchfire",
				"UZI_crouchreload",
				"UZI_fire",
				"UZI_fire_poor",
				"UZI_reload",
				"idle_rocket",
				"Rocket_Fire",
				"run_rocket",
				"walk_rocket",
				"WALK_start_rocket",
				"WEAPON_sniper"
			}

			for int, anim in pairs(pGunsAnimations) do
				setCharAnimSpeed(PLAYER_PED, anim, Sliderrapid[0])
			end
		end
        if aimon[0] and drawcircle[0] and mem.getint8(getCharPointer(PLAYER_PED) + 0x528, false) == 19 then
            renderFigure2D(xc, yc, 30, getpx(), 0xFFFFFFFF)
        end
        wait(0)
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if chbxskipzz[0] then
        if text:find("драться/стрелять") then
            return false
        end
    end
    if chbxskiprep[0] then
        if text:find('Вам ответил администратор') then
            sampSendDialogResponse(id, 0, 0, "")
            return false
        end
        if text:find('Хороший ответ') then
            sampSendDialogResponse(id, 0, 0, "")
            return false
        end
    end
end

function sendKey(key)
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local data = allocateMemory(68)
    sampStorePlayerOnfootData(myId, data)
    setStructElement(data, 4, 2, key, false)
    sampSendOnfootData(data)
    freeMemory(data)
end

local whvisible = imgui.OnFrame(function () return whbyp[0] end,
    function(wh)
    wh.HideCursor = true
        local dl = imgui.GetBackgroundDrawList()
        if not isPauseMenuActive() and not isKeyDown(VK_F8) then
			for i = 0, sampGetMaxPlayerId() do
			if sampIsPlayerConnected(i) then
				local result, cped = sampGetCharHandleBySampPlayerId(i)
				local color = 0xFFFFFFff
				local nick = sampGetPlayerNickname(i)
				if result then
					if doesCharExist(cped) and isCharOnScreen(cped) then
						local t = {3, 4, 5, 51, 52, 41, 42, 31, 32, 33, 21, 22, 23, 2}
						for v = 1, #t do
							pos1X, pos1Y, pos1Z = getBodyPartCoordinates(t[v], cped)
							pos2X, pos2Y, pos2Z = getBodyPartCoordinates(t[v] + 1, cped)
							pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
							pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            if whbypnicks[0] then
        					    local x, y, z = getCharCoordinates(cped) -- Записываем координаты персонажа в переменные x, y, z
							    local wX, wY = convert3DCoordsToScreen(x, y, z)
							    local wY = wY - 100
							    dl:AddTextFontPtr(imFont, 18, imgui.ImVec2(wX,wY), color, nick)
                            end
							dl:AddLine(imgui.ImVec2(pos1,pos2),imgui.ImVec2(pos3,pos4),color,2)
						end
						for v = 4, 5 do
							pos2X, pos2Y, pos2Z = getBodyPartCoordinates(v * 10 + 1, cped)
							pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
							dl:AddLine(imgui.ImVec2(pos1,pos2),imgui.ImVec2(pos3,pos4),color,2)
						end
						local t = {53, 43, 24, 34, 6}
						for v = 1, #t do
							posX, posY, posZ = getBodyPartCoordinates(t[v], cped)
							pos1, pos2 = convert3DCoordsToScreen(posX, posY, posZ)
						end
					end
				end
			end
		end
	end
end)

function getBodyPartCoordinates(id, handle)
  local pedptr = getCharPointer(handle)
  local vec = ffi.new("float[3]")
  getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
  return vec[0], vec[1], vec[2]
end

function join_argb(a, r, g, b)
  local argb = b  -- b
  argb = bit.bor(argb, bit.lshift(g, 8))  -- g
  argb = bit.bor(argb, bit.lshift(r, 16)) -- r
  argb = bit.bor(argb, bit.lshift(a, 24)) -- a
  return argb
end

function explode_argb(argb)
  local a = bit.band(bit.rshift(argb, 24), 0xFF)
  local r = bit.band(bit.rshift(argb, 16), 0xFF)
  local g = bit.band(bit.rshift(argb, 8), 0xFF)
  local b = bit.band(argb, 0xFF)
  return a, r, g, b
end

function menu()
    renderWindow[0] = not renderWindow[0]
end

function sampev.onSendPlayerSync(data)
    if chbxantibh[0] then
	    if bit.band(data.keysData, 0x28) == 0x28 then
		    data.keysData = bit.bxor(data.keysData, 0x20)
        else
            return true
        end
    end
end

function onSendRpc(id, bs)
    if id == 106 then
        return false
    end
end

function onReceiveRpc(id, bs)
    if id == 91 then
        local turn = raknetBitStreamReadBool(bs)
        local x = raknetBitStreamReadFloat(bs)
        local y = raknetBitStreamReadFloat(bs)
        local z = raknetBitStreamReadFloat(bs)
        return false 
    end
end

function onReceivePacket(id, bs)
    if id == 32 then
    end
    if id == 220 then
        raknetBitStreamIgnoreBits(bs, 8)
        local type = raknetBitStreamReadInt8(bs)
        if type == 155 then
            local playerId = raknetBitStreamReadInt16(bs)
            local index = raknetBitStreamReadInt32(bs)
            local create = raknetBitStreamReadBool(bs)
            local myId = select(2, sampGetPlayerIdByCharHandle(1))
            if ((playerId == myId and acsremme) or (playerId ~= myId and acsrem)) and create then
                return false
            end
        end
    end
end

function sampev.onSetPlayerAttachedObject(id, index, create, object)
    local myId = select(2, sampGetPlayerIdByCharHandle(1))
    if ((id == myId and acsrem) or (id ~= myId and acsrem)) and create then
        return false
    end
end

function sampev.onSetPlayerDrunk(drunkLevel)
    if chbxantilomka[0] then
        return {1}
    end
end

function sampev.onServerMessage(color, text)
    if chbxantilomka[0] then
	    if text:find('У вас началась сильная ломка') or text:find('Вашему персонажу нужно принять') then return false end
    end
end

function sampev.onCreateObject(id, data)
    if chbxantishlagbaum[0] then
	    if data.modelId == 968 or data.modelId == 966 then
		    return false
	    end
    end
end

function deleteAllAcs(id)
    local bs = raknetNewBitStream()
    for i = 0, 7 do
        raknetBitStreamWriteInt16(bs, id)
        raknetBitStreamWriteInt32(bs, i)
        raknetBitStreamWriteBool(bs, false)
        raknetEmulRpcReceiveBitStream(113, bs)
        raknetResetBitStream(bs)

        raknetBitStreamWriteInt8(bs, 155)
        raknetBitStreamWriteInt16(bs, id)
        raknetBitStreamWriteInt32(bs, i)
        raknetBitStreamWriteBool(bs, false)
        raknetEmulPacketReceiveBitStream(220, bs)
        raknetResetBitStream(bs)
    end
    raknetDeleteBitStream(bs)
end

function nameTagOn()
	local pStSet = sampGetServerSettingsPtr();
	NTdist = mem.getfloat(pStSet + 39)
	NTwalls = mem.getint8(pStSet + 47)
	NTshow = mem.getint8(pStSet + 56)
	mem.setfloat(pStSet + 39, 1488.0)
	mem.setint8(pStSet + 47, 0)
	mem.setint8(pStSet + 56, 1)
	nameTag = true
end

function nameTagOff()
	local pStSet = sampGetServerSettingsPtr();
	mem.setfloat(pStSet + 39, NTdist)
	mem.setint8(pStSet + 47, NTwalls)
	mem.setint8(pStSet + 56, NTshow)
	nameTag = false
end

function theme()
    imgui.SwitchContext()
    imgui.GetStyle().WindowPadding = imgui.ImVec2(15, 15)
    imgui.GetStyle().WindowRounding = 5.0
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FrameRounding = 4.0
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(12, 8)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(8, 6)
    imgui.GetStyle().IndentSpacing = 25.0
    imgui.GetStyle().ScrollbarSize = 15.0
    imgui.GetStyle().ScrollbarRounding = 9.0
    imgui.GetStyle().GrabMinSize = 5.0
    imgui.GetStyle().GrabRounding = 3.0

    imgui.GetStyle().Colors[imgui.Col.Text] = imgui.ImVec4(0.80, 0.80, 0.83, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.24, 0.23, 0.29, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg] = imgui.ImVec4(0.06, 0.05, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg] = imgui.ImVec4(0.07, 0.07, 0.09, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg] = imgui.ImVec4(0.07, 0.07, 0.09, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Border] = imgui.ImVec4(0.80, 0.80, 0.83, 0.88)
    imgui.GetStyle().Colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.92, 0.91, 0.88, 0.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg] = imgui.ImVec4(0.10, 0.09, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.24, 0.23, 0.29, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.56, 0.56, 0.58, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg] = imgui.ImVec4(0.10, 0.09, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(1.00, 0.98, 0.95, 0.75)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.07, 0.07, 0.09, 1.00)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.10, 0.09, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.10, 0.09, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.80, 0.80, 0.83, 0.31)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.56, 0.56, 0.58, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.06, 0.05, 0.07, 1.00)
    --//imgui.GetStyle().Colors[imgui.Col.ComboBg] = imgui.ImVec4(0.19, 0.18, 0.21, 1.00)
    imgui.GetStyle().Colors[imgui.Col.CheckMark] = imgui.ImVec4(0.80, 0.80, 0.83, 0.31)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.80, 0.80, 0.83, 0.31)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.06, 0.05, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(0.10, 0.09, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.24, 0.23, 0.29, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.56, 0.56, 0.58, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Header] = imgui.ImVec4(0.10, 0.09, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.56, 0.56, 0.58, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.06, 0.05, 0.07, 1.00)
    --//imgui.GetStyle().Colors[imgui.Col.CloseButton] = imgui.ImVec4(0.40, 0.39, 0.38, 0.16)
    --//imgui.GetStyle().Colors[imgui.Col.CloseButtonHovered] = imgui.ImVec4(0.40, 0.39, 0.38, 0.39)
    --//imgui.GetStyle().Colors[imgui.Col.CloseButtonActive] = imgui.ImVec4(0.40, 0.39, 0.38, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLines] = imgui.ImVec4(0.40, 0.39, 0.38, 0.63)
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(0.25, 1.00, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.40, 0.39, 0.38, 0.63)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(0.25, 1.00, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.25, 1.00, 0.00, 0.43)
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.10, 0.09, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0, 0, 0, 0.51)
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = imgui.ImVec4(0, 0, 0, 0.51)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.10, 0.09, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0, 0, 0, 0.51)
end


function onExitScript()
	restoreOriginalWeaponData()
end


--- Возвращает нормальную скорость стрельбы
function restoreOriginalWeaponData()
	if weaponOrigData ~= nil then
		for skill, weaponsOrig in pairs(weaponOrigData) do
			for id, orig in pairs(weaponsOrig) do
				local weap = gameGetWeaponInfo(id, skill - 1)
				weap.m_fAccuracy 			 = orig.accuracy
				weap.m_fAnimLoopStart  = orig.animLoopStart
				weap.m_fAnimLoopFire   = orig.animLoopFire
				weap.m_fAnimLoopEnd    = orig.animLoopEnd
				weap.m_fAnimLoop2Start = orig.animLoopStart2
				weap.m_fAnimLoop2Fire  = orig.animLoopFire2
				weap.m_fAnimLoop2End   = orig.animLoopEnd2
			end
		end
	end
end


--- FFI
ffi.cdef([[
struct CVector { float x, y, z; };
// from plugin-sdk: https://github.com/DK22Pac/plugin-sdk/blob/master/plugin_sa/game_sa/CWeaponInfo.h
struct CWeaponInfo
{
	int m_iWeaponFire; // 0
	float m_fTargetRange; // 4
	float m_fWeaponRange; // 8
	__int32 m_dwModelId1; // 12
	__int32 m_dwModelId2; // 16
	unsigned __int32 m_dwSlot; // 20
	union {
		int m_iWeaponFlags; // 24
		struct {
			unsigned __int32 m_bCanAim : 1;
			unsigned __int32 m_bAimWithArm : 1;
			unsigned __int32 m_b1stPerson : 1;
			unsigned __int32 m_bOnlyFreeAim : 1;
			unsigned __int32 m_bMoveAim : 1;
			unsigned __int32 m_bMoveFire : 1;
			unsigned __int32 _weaponFlag6 : 1;
			unsigned __int32 _weaponFlag7 : 1;
			unsigned __int32 m_bThrow : 1;
			unsigned __int32 m_bHeavy : 1;
			unsigned __int32 m_bContinuosFire : 1;
			unsigned __int32 m_bTwinPistol : 1;
			unsigned __int32 m_bReload : 1;
			unsigned __int32 m_bCrouchFire : 1;
			unsigned __int32 m_bReload2Start : 1;
			unsigned __int32 m_bLongReload : 1;
			unsigned __int32 m_bSlowdown : 1;
			unsigned __int32 m_bRandSpeed : 1;
			unsigned __int32 m_bExpands : 1;
		};
	};
	unsigned __int32 m_dwAnimGroup; // 28
	unsigned __int16 m_wAmmoClip; // 32
	unsigned __int16 m_wDamage; // 34
	struct CVector m_vFireOffset; // 36
	unsigned __int32 m_dwSkillLevel; // 48
	unsigned __int32 m_dwReqStatLevel; // 52
	float m_fAccuracy; // 56
	float m_fMoveSpeed;
	float m_fAnimLoopStart;
	float m_fAnimLoopEnd;
	float m_fAnimLoopFire;
	float m_fAnimLoop2Start;
	float m_fAnimLoop2End;
	float m_fAnimLoop2Fire;
	float m_fBreakoutTime;
	float m_fSpeed;
	float m_fRadius;
	float m_fLifespan;
	float m_fSpread;
	unsigned __int16 m_wAimOffsetIndex;
	unsigned __int8 m_nBaseCombo;
	unsigned __int8 m_nNumCombos;
} __attribute__ ((aligned (4)));
]])

function sampev.onSendVehicleSync(sync)
	if a then
		data=samp_create_sync_data("passenger")
		data.vehicleId=sync.vehicleId
		data.seatId=1
		data.position=sync.position
		data.send()
		return false
	end
end

function samp_create_sync_data(sync_type, copy_from_player)
	local ffi = require "ffi"
	local sampfuncs = require "sampfuncs"
	local raknet = require "samp.raknet"
	copy_from_player = copy_from_player or true
	local sync_traits = {passenger = {"PassengerSyncData", raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData}}
	local sync_info = sync_traits[sync_type]
	local data_type = "struct " .. sync_info[1]
	local data = ffi.new(data_type, {})
	local raw_data_ptr = tonumber(ffi.cast("uintptr_t", ffi.new(data_type .. "*", data)))
	if copy_from_player then
		local copy_func = sync_info[3]
		if copy_func then
			local _, player_id
			if copy_from_player == true then
				_, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
			else
				player_id = tonumber(copy_from_player)
			end
			copy_func(player_id, raw_data_ptr)
		end
	end
	local func_send = function()
		local bs = raknetNewBitStream()
		raknetBitStreamWriteInt8(bs, sync_info[2])
		raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
		raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
		raknetDeleteBitStream(bs)
	end
	local mt = {
		__index = function(t, index)
			return data[index]
		end,
		__newindex = function(t, index, value)
			data[index] = value
		end
	}
	return setmetatable({send = func_send}, mt)
end

function sampev.onSendBulletSync(data)
    math.randomseed(os.clock())
    if not aimon[0] then return end
    local weap = getCurrentCharWeapon(PLAYER_PED)
    if not getDamage(weap) then return end
    local id, ped = getClosestPlayerFromCrosshair()
    if id == -1 then return end
    if not getcond(ped) then return end
    data.targetType = 1
    local px, py, pz = getCharCoordinates(ped)
    data.targetId = id

    data.target = { x = px + rand(), y = py + rand(), z = pz + rand() }
    data.center = { x = rand(), y = rand(), z = rand() }

    lua_thread.create(function()
         wait(1)
        sampSendGiveDamage(id, getDamage(weap), weap, 3)
    end)
end

function getDamage(weap)
	local damage = {
		[22] = 8.25,
		[23] = 13.2,
		[24] = 46.200000762939,
		[25] = 30,
		[26] = 30,
		[27] = 30,
		[28] = 6.6,
		[29] = 8.25,
		[30] = 9.9,
		[31] = 9.9000005722046,
		[32] = 6.6,
		[33] = 25,
		[38] = 46.2
	}
	return (damage[weap] or 0) + math.random(1e9)/1e15
end

function getcond(ped)
	if aimthroughtwall[0] then return true
	else return canPedBeShot(ped) end
end

function rand() return math.random(-50, 50) / 100 end

function getpx()
	return ((ws / 2) / getCameraFov()) * aimfov[0]
end

function getClosestPlayerFromCrosshair()
	local R1, target = getCharPlayerIsTargeting(0)
	local R2, player = sampGetPlayerIdByCharHandle(target)
	if R2 then return player, target end
	local minDist = getpx()
	local closestId, closestPed = -1, -1
	for i = 0, 999 do
		local res, ped = sampGetCharHandleBySampPlayerId(i)
		if res then
			if getDistanceFromPed(ped) < aimmaxdist[0] then
                local xi, yi = convert3DCoordsToScreen(getCharCoordinates(ped))
                local dist = math.sqrt( (xi - xc) ^ 2 + (yi - yc) ^ 2 )
                if dist < minDist then
                    minDist = dist
                    closestId, closestPed = i, ped
                end
			end
		end
	end
	return closestId, closestPed
end

function canPedBeShot(ped)
	local ax, ay, az = convertScreenCoordsToWorld3D(xc, yc, 0)
	local bx, by, bz = getCharCoordinates(ped)
	return not select(1, processLineOfSight(ax, ay, az, bx, by, bz + 0.7, true, false, false, true, false, true, false, false))
end

function getDistanceFromPed(ped)
	local ax, ay, az = getCharCoordinates(1)
	local bx, by, bz = getCharCoordinates(ped)
	return math.sqrt( (ax - bx) ^ 2 + (ay - by) ^ 2 + (az - bz) ^ 2 )
end

function renderFigure2D(x, y, points, radius, color)
    local step = math.pi * 2 / points
    local render_start, render_end = {}, {}
    for i = 0, math.pi * 2, step do
        render_start[1] = radius * math.cos(i) + x
        render_start[2] = radius * math.sin(i) + y
        render_end[1] = radius * math.cos(i + step) + x
        render_end[2] = radius * math.sin(i + step) + y
        renderDrawLine(render_start[1], render_start[2], render_end[1], render_end[2], 1, color)
    end
end
