
_G.equip_weapon_avatar = nil
_G.g_parts = nil
_G.g_parts_subtype = nil
_G.lastAppliedSkin = {}
_G.lastAppliedAttachments = {}
_G.lastAppliedAttachmentFp = {}
_G.skinDownloadCache = {}
_G.skinHasAttachmentSkinsCache = {}

local possiblePaths = {
    "/storage/emulated/0/Android/data/com.tencent.ig/lizardMH.h",     
    "/storage/emulated/0/Android/data/com.pubg.krmobile/lizardMH.h",   
    "/storage/emulated/0/Android/data/com.vng.pubgmobile/lizardMH.h",
    "/storage/emulated/0/Android/data/com.rekoo.pubgm/lizardMH.h",
    "/storage/emulated/0/Android/data/com.pubg.imobile/lizardMH.h",
}

local lastConfig = {}

_G.HairSkin = _G.HairSkin or 0
_G.SuitSkin = _G.SuitSkin or 0

_G.EnableDeadBoxSkin = _G.EnableDeadBoxSkin or true  

_G.WeatherMode = _G.WeatherMode or 0  

_G.ConfigFOVEnable = _G.ConfigFOVEnable or true   
_G.ConfigFOV = _G.ConfigFOV or 90                

_G.HatSkin = _G.HatSkin or 0
_G.FaceSkin = _G.FaceSkin or 0
_G.MaskSkin = _G.MaskSkin or 0
_G.GlovesSkin = _G.GlovesSkin or 0
_G.PantSkin = _G.PantSkin or 0
_G.ShoeSkin = _G.ShoeSkin or 0
_G.ParachuteSkin = _G.ParachuteSkin or 0
_G.GliderSkin = _G.GliderSkin or 0
_G.Backpack1Skin = _G.Backpack1Skin or 0
_G.Backpack2Skin = _G.Backpack2Skin or 0
_G.Backpack3Skin = _G.Backpack3Skin or 0
_G.Backpack4Skin = _G.Backpack4Skin or 0
_G.Backpack5Skin = _G.Backpack5Skin or 0
_G.Backpack6Skin = _G.Backpack6Skin or 0
_G.Helmet1Skin = _G.Helmet1Skin or 0
_G.Helmet2Skin = _G.Helmet2Skin or 0
_G.Helmet3Skin = _G.Helmet3Skin or 0
_G.Helmet4Skin = _G.Helmet4Skin or 0
_G.Helmet5Skin = _G.Helmet5Skin or 0
_G.Helmet6Skin = _G.Helmet6Skin or 0

_G.Armor1Skin = _G.Armor1Skin or 0
_G.Armor2Skin = _G.Armor2Skin or 0
_G.Armor3Skin = _G.Armor3Skin or 0
_G.Armor4Skin = _G.Armor4Skin or 0
_G.Armor5Skin = _G.Armor5Skin or 0
_G.Armor6Skin = _G.Armor6Skin or 0

_G.PetSkinMap = _G.PetSkinMap or {
    50000, 50001, 50002, 50003, 50004, 50005, 50006, 50007, 50008, 50009,
    50010, 50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028, 50029,
    50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037, 50038, 50039,
    50040, 50041, 50042, 50043, 50044,
    50045, 
50046, 
}
_G.PetSkinMapIndex = _G.PetSkinMapIndex or 1
_G.LastAppliedPet = _G.LastAppliedPet or 0

_G.WeaponSkinID = _G.WeaponSkinID or {}

_G.skinIdCache = _G.skinIdCache or {}
_G.skinIdCache2 = _G.skinIdCache2 or {}
_G.skinIdCache3 = _G.skinIdCache3 or {}
_G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
_G.CurrentEquipVehicleID = _G.CurrentEquipVehicleID or 0

_G.DeadBoxSkins = _G.DeadBoxSkins or {}
_G.AlreadyChangedSet = _G.AlreadyChangedSet or {}

_G.CustSlotType = _G.CustSlotType or {
    NONE = 0, HeadEquipemtSlot = 1, HairEquipemtSlot = 2, HatEquipemtSlot = 3,
    FaceEquipemtSlot = 4, ClothesEquipemtSlot = 5, PantsEquipemtSlot = 6,
    ShoesEquipemtSlot = 7, BackpackEquipemtSlot = 8, HelmetEquipemtSlot = 9,
    ArmorEquipemtSlot = 10, ParachuteEquipemtSlot = 11, GlassEquipemtSlot = 12,
    NightVisionEquipemtSlot = 13, BeardEquipemtSlot = 14, GlideEquipemtSlot = 15,
    HandEffectEquipemtSlot = 16, BackPack_PendantSlot = 17, MechaChestSlot = 18,
    MechaArmSlot = 19, MechaLegSlot = 20, MechaInnerSuitSlot = 21,
    FootEffectEquipemtSlot = 22, MaxSlotNum = 23, VehicleCut = 24,
    UnderClothSlot = 25, UnderPantsSlot = 26, SimpleSlotMax = 27, MAX = 28
}

local function download_item(id)
    if not PufferManager or not PufferConst then return end
    local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, {id})
    if state ~= PufferConst.ENUM_DownloadState.Done then
        PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, {id})
    end
end
_G.download_item = download_item

function _G.equip_character_avatar(uCharacter)
    if not uCharacter or not slua.isValid(uCharacter) or not uCharacter.AvatarComponent2 then return end

    local BackpackUtils = import("BackpackUtils")
    if not BackpackUtils then return end

    local ApplyData = uCharacter.AvatarComponent2.NetAvatarData and uCharacter.AvatarComponent2.NetAvatarData.SlotSyncData
    if not ApplyData or not slua.isValid(ApplyData) then return end

    local function setMakeSkin(ApplyDataIdx, currentItemId, targetSkinId, ApplyEquipSlot)
    if targetSkinId ~= nil then
        local equipment = ApplyData:Get(ApplyDataIdx)
        if equipment and equipment.SlotID == ApplyEquipSlot then

            if targetSkinId == 0 then
                return
            end
            if equipment.ItemId ~= targetSkinId then
                if not _G.skinIdCache[targetSkinId] then
                    pcall(_G.download_item, targetSkinId)
                    _G.skinIdCache[targetSkinId] = true
                end
                equipment.ItemId = targetSkinId
                ApplyData:Set(ApplyDataIdx, equipment)
                uCharacter.AvatarComponent2:OnRep_BodySlotStateChanged()
            end
        end
    end
end

    local gliderSlotFound = false
    for i = 0, ApplyData:Num() - 1 do
        local equipment = ApplyData:Get(i)
        if equipment and equipment.SlotID == _G.CustSlotType.GlideEquipemtSlot then
            gliderSlotFound = true
            break
        end
    end
    if not gliderSlotFound then
        ApplyData:Add({ SlotID = _G.CustSlotType.GlideEquipemtSlot, ItemId = 0 })
    end

    for i = 0, ApplyData:Num() - 1 do
        local equipment = ApplyData:Get(i)
        local currentItemId = equipment.ItemId

        setMakeSkin(i, currentItemId, _G.SuitSkin, _G.CustSlotType.ClothesEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.HairSkin, _G.CustSlotType.HairEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.HatSkin, _G.CustSlotType.HatEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.FaceSkin, _G.CustSlotType.FaceEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.MaskSkin, _G.CustSlotType.GlassEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.GlovesSkin, _G.CustSlotType.HandEffectEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.PantSkin, _G.CustSlotType.PantsEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.ShoeSkin, _G.CustSlotType.ShoesEquipemtSlot)

        if equipment.SlotID == _G.CustSlotType.BackpackEquipemtSlot then
            local nItemLevel = BackpackUtils.GetEquipmentBagLevel(equipment.AdditionalItemID) or 1
            local targetBagSkin = 0
            if nItemLevel == 1 then targetBagSkin = _G.Backpack1Skin
            elseif nItemLevel == 2 then targetBagSkin = _G.Backpack2Skin
            elseif nItemLevel == 3 then targetBagSkin = _G.Backpack3Skin
            elseif nItemLevel == 4 then targetBagSkin = _G.Backpack4Skin
            elseif nItemLevel == 5 then targetBagSkin = _G.Backpack5Skin
            elseif nItemLevel == 6 then targetBagSkin = _G.Backpack6Skin
            end
            setMakeSkin(i, currentItemId, targetBagSkin, _G.CustSlotType.BackpackEquipemtSlot)
        end

        if equipment.SlotID == _G.CustSlotType.HelmetEquipemtSlot then
            local nItemLevel = BackpackUtils.GetEquipmentHelmetLevel(equipment.AdditionalItemID) or 1
            local targetHelmetSkin = 0
            if nItemLevel == 1 then targetHelmetSkin = _G.Helmet1Skin
            elseif nItemLevel == 2 then targetHelmetSkin = _G.Helmet2Skin
            elseif nItemLevel == 3 then targetHelmetSkin = _G.Helmet3Skin
            elseif nItemLevel == 4 then targetHelmetSkin = _G.Helmet4Skin
            elseif nItemLevel == 5 then targetHelmetSkin = _G.Helmet5Skin
            elseif nItemLevel == 6 then targetHelmetSkin = _G.Helmet6Skin
            end
            setMakeSkin(i, currentItemId, targetHelmetSkin, _G.CustSlotType.HelmetEquipemtSlot)
        end

        if equipment.SlotID == _G.CustSlotType.ArmorEquipemtSlot then
            local nItemLevel = BackpackUtils.GetEquipmentArmorLevel(equipment.AdditionalItemID) or 1
            local targetArmorSkin = 0
            if nItemLevel == 1 then targetArmorSkin = _G.Armor1Skin
            elseif nItemLevel == 2 then targetArmorSkin = _G.Armor2Skin
            elseif nItemLevel == 3 then targetArmorSkin = _G.Armor3Skin
            elseif nItemLevel == 4 then targetArmorSkin = _G.Armor4Skin
            elseif nItemLevel == 5 then targetArmorSkin = _G.Armor5Skin
            elseif nItemLevel == 6 then targetArmorSkin = _G.Armor6Skin
            end
            setMakeSkin(i, currentItemId, targetArmorSkin, _G.CustSlotType.ArmorEquipemtSlot)
        end

        setMakeSkin(i, currentItemId, _G.GliderSkin, _G.CustSlotType.GlideEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.ParachuteSkin, _G.CustSlotType.ParachuteEquipemtSlot)
    end
end

_G.WeaponNameToID = {

    AKM = 101001,
    M16A4 = 101002,
    SCAR = 101003,
    M416 = 101004,
    GROZA = 101005,
    AUG = 101006,
    QBZ = 101007,
    M762 = 101008,
    Mk47 = 101009,
    G36C = 101010,
    HoneyPot = 101012,
    FAMAS = 101100,
    ASM = 101101,
    ACE32 = 101102,

    UZI = 102001,
    UMP = 102002,
    VECTOR = 102003,
    THOMPSON = 102004,
    BIZON = 102005,
    MP5K = 102007,
    JS9 = 102008,
    P90 = 102105,

    K98 = 103001,
    M24 = 103002,
    AWM = 103003,
    SKS = 103004,
    VSS = 103005,
    Mini14 = 103006,
    MK14 = 103007,
    Win94 = 103008,
    M1Garand = 103103,
    SLR = 103009,
    QBU = 103010,
    Mosin = 103011,
    AMR = 103012,
    Mk12 = 103100,
    DSR = 103102,

    S686 = 104001,
    S1897 = 104002,
    S12K = 104003,
    DBS = 104004,
    M1014 = 104101,
    NS2000 = 104102,

    M249 = 105001,
    DP28 = 105002,
    MG3 = 105010,

    PAN = 108004,
    DAGGER = 108005,
    Machete = 108001,
}

_G.WeaponIDSets = {

    M416 = {[101004]=true, [1010041]=true, [1010042]=true, [1010043]=true, [1010044]=true, [1010045]=true, [1010046]=true, [1010047]=true, [1010049]=true},
    AKM = {[101001]=true, [1010011]=true, [1010012]=true, [1010013]=true, [1010014]=true, [1010015]=true, [1010016]=true, [1010017]=true, [1010019]=true},
    SCAR = {[101003]=true, [1010031]=true, [1010032]=true, [1010033]=true, [1010034]=true, [1010035]=true, [1010036]=true, [1010037]=true, [1010039]=true},
    M762 = {[101008]=true, [1010081]=true, [1010082]=true, [1010083]=true, [1010084]=true, [1010085]=true, [1010086]=true, [1010087]=true, [1010089]=true},
    GROZA = {[101005]=true, [1010051]=true, [1010052]=true, [1010053]=true, [1010054]=true, [1010055]=true, [1010056]=true, [1010057]=true, [1010059]=true},
    AUG = {[101006]=true, [1010061]=true, [1010062]=true, [1010063]=true, [1010064]=true, [1010065]=true, [1010066]=true, [1010067]=true},
    QBZ = {[101007]=true, [1010071]=true, [1010072]=true, [1010073]=true, [1010074]=true, [1010075]=true, [1010076]=true, [1010077]=true},
    M16A4 = {[101002]=true, [1010021]=true, [1010022]=true, [1010023]=true, [1010024]=true, [1010025]=true},
    FAMAS = {[101100]=true, [1011001]=true, [1011002]=true, [1011003]=true, [1011004]=true, [1011005]=true, [1011006]=true, [1011007]=true},
    ACE32 = {[101102]=true, [1011021]=true, [1011022]=true, [1011023]=true, [1011024]=true, [1011025]=true, [1011026]=true, [1011027]=true},
    ASM = {[101101]=true, [1011011]=true, [1011012]=true, [1011013]=true, [1011014]=true, [1011015]=true, [1011016]=true, [1011017]=true},
    Mk47 = {[101009]=true, [1010091]=true, [1010092]=true, [1010093]=true, [1010094]=true, [1010095]=true, [1010096]=true, [1010097]=true, [1010099]=true},
    G36C = {[101010]=true, [1010101]=true, [1010102]=true, [1010103]=true, [1010104]=true, [1010105]=true, [1010106]=true, [1010107]=true, [1010109]=true},
    HoneyPot = {[101012]=true, [1010121]=true, [1010122]=true, [1010123]=true, [1010124]=true, [1010125]=true, [1010126]=true, [1010127]=true, [1010129]=true},

    UMP = {[102002]=true, [1020021]=true, [1020022]=true, [1020023]=true, [1020024]=true, [1020025]=true, [1020029]=true},
    VECTOR = {[102003]=true, [1020031]=true, [1020032]=true, [1020033]=true, [1020034]=true, [1020035]=true, [1020036]=true, [1020037]=true},
    UZI = {[102001]=true, [1020011]=true, [1020012]=true, [1020013]=true, [1020014]=true, [1020015]=true},
    THOMPSON = {[102004]=true, [1020041]=true, [1020042]=true, [1020043]=true, [1020044]=true, [1020045]=true},
    BIZON = {[102005]=true, [1020051]=true, [1020052]=true, [1020053]=true, [1020054]=true, [1020055]=true, [1020059]=true},
    P90 = {[102105]=true, [1021051]=true, [1021052]=true, [1021053]=true, [1021054]=true, [1021055]=true, [1021056]=true, [1021057]=true},
    MP5K = {[102007]=true, [1020071]=true, [1020072]=true, [1020073]=true, [1020074]=true, [1020075]=true, [1020076]=true, [1020077]=true, [1020079]=true},
    JS9 = {[102008]=true, [1020081]=true, [1020082]=true, [1020083]=true, [1020084]=true, [1020085]=true, [1020086]=true, [1020087]=true, [1020089]=true},

    AWM = {[103003]=true, [1030031]=true, [1030032]=true, [1030033]=true, [1030034]=true, [1030035]=true, [1030036]=true, [1030037]=true, [1030039]=true},
    M24 = {[103002]=true, [1030021]=true, [1030022]=true, [1030023]=true, [1030024]=true, [1030025]=true, [1030026]=true, [1030027]=true},
    K98 = {[103001]=true, [1030011]=true, [1030012]=true, [1030013]=true, [1030014]=true, [1030015]=true, [1030019]=true},
    MK14 = {[103007]=true, [1030071]=true, [1030072]=true, [1030073]=true, [1030074]=true, [1030075]=true, [1030076]=true, [1030077]=true},
    AMR = {[103012]=true, [1030121]=true, [1030122]=true, [1030123]=true, [1030124]=true, [1030125]=true, [1030126]=true, [1030127]=true},
    DSR = {[103102]=true, [1031021]=true, [1031022]=true, [1031023]=true, [1031024]=true, [1031025]=true, [1031026]=true, [1031027]=true, [1031029]=true},
    SKS = {[103004]=true, [1030041]=true, [1030042]=true, [1030043]=true, [1030044]=true, [1030045]=true, [1030046]=true, [1030047]=true, [1030049]=true},
    Mini14 = {[103006]=true, [1030061]=true, [1030062]=true, [1030063]=true, [1030064]=true, [1030065]=true, [1030066]=true, [1030067]=true, [1030069]=true},
    VSS = {[103005]=true, [1030051]=true, [1030052]=true, [1030053]=true, [1030054]=true, [1030055]=true, [1030056]=true, [1030057]=true, [1030059]=true},
    Win94 = {[103008]=true, [1030081]=true, [1030082]=true, [1030083]=true, [1030084]=true, [1030085]=true, [1030086]=true, [1030087]=true, [1030089]=true},
    M1Garand = {[103103]=true},
    SLR = {[103009]=true, [1030091]=true, [1030092]=true, [1030093]=true, [1030094]=true, [1030095]=true, [1030096]=true, [1030097]=true, [1030099]=true},
    QBU = {[103010]=true, [1030101]=true, [1030102]=true, [1030103]=true, [1030104]=true, [1030105]=true, [1030106]=true, [1030107]=true, [1030109]=true},
    Mosin = {[103011]=true, [1030111]=true, [1030112]=true, [1030113]=true, [1030114]=true, [1030115]=true, [1030116]=true, [1030117]=true, [1030119]=true},
    Mk12 = {[103100]=true, [1031001]=true, [1031002]=true, [1031003]=true, [1031004]=true, [1031005]=true, [1031006]=true, [1031007]=true, [1031009]=true},

    S686 = {[104001]=true, [1040011]=true, [1040012]=true, [1040013]=true, [1040014]=true, [1040015]=true, [1040016]=true, [1040017]=true, [1040019]=true},
    S1897 = {[104002]=true, [1040021]=true, [1040022]=true, [1040023]=true, [1040024]=true, [1040025]=true, [1040026]=true, [1040027]=true, [1040029]=true},
    S12K = {[104003]=true, [1040031]=true, [1040032]=true, [1040033]=true, [1040034]=true, [1040035]=true, [1040036]=true, [1040037]=true, [1040039]=true},
    DBS = {[104004]=true, [1040041]=true, [1040042]=true, [1040043]=true, [1040044]=true, [1040045]=true, [1040046]=true, [1040047]=true, [1040049]=true},
    M1014 = {[104101]=true, [1041011]=true, [1041012]=true, [1041013]=true, [1041014]=true, [1041015]=true, [1041016]=true, [1041017]=true, [1041019]=true},
    NS2000 = {[104102]=true, [1041021]=true, [1041022]=true, [1041023]=true, [1041024]=true, [1041025]=true, [1041026]=true, [1041027]=true, [1041029]=true},

    M249 = {[105001]=true, [1050011]=true, [1050012]=true, [1050013]=true, [1050014]=true, [1050015]=true, [1050016]=true, [1050017]=true},
    DP28 = {[105002]=true, [1050021]=true, [1050022]=true, [1050023]=true, [1050024]=true, [1050025]=true, [1050026]=true, [1050027]=true, [1050029]=true},
    MG3 = {[105010]=true, [1050101]=true, [1050102]=true, [1050103]=true, [1050104]=true, [1050105]=true, [1050106]=true, [1050107]=true, [1050109]=true},

    PAN = {[108004]=true, [1080041]=true},
    Dagger = {[108005]=true},
    Machete = {[108001]=true, [1080011]=true},
}

function _G.getBaseWeaponID(weaponID)
    if not weaponID then return nil end

    for weaponType, idSet in pairs(_G.WeaponIDSets) do
        if idSet[weaponID] then
            local minID = math.huge
            for id in pairs(idSet) do
                if id < minID then minID = id end
            end
            return minID
        end
    end

if weaponID >= 1101004001 and weaponID <= 1101004246 then return 101004 end  
if weaponID >= 1101001001 and weaponID <= 1101001999 then return 101001 end  
if weaponID >= 1101003001 and weaponID <= 1101003999 then return 101003 end  
if weaponID >= 1101008001 and weaponID <= 1101008999 then return 101008 end  
if weaponID >= 1101002001 and weaponID <= 1101002999 then return 101002 end  
if weaponID >= 1101005001 and weaponID <= 1101005999 then return 101005 end  
if weaponID >= 1101006001 and weaponID <= 1101006999 then return 101006 end  
if weaponID >= 1101007001 and weaponID <= 1101007999 then return 101007 end  
if weaponID >= 1101009001 and weaponID <= 1101009999 then return 101009 end  
if weaponID >= 1101010001 and weaponID <= 1101010999 then return 101010 end  
if weaponID >= 1101012001 and weaponID <= 1101012999 then return 101012 end  
if weaponID >= 1101100001 and weaponID <= 1101100999 then return 101100 end  
if weaponID >= 1101101001 and weaponID <= 1101101999 then return 101101 end  
if weaponID >= 1101102001 and weaponID <= 1101102999 then return 101102 end  

if weaponID >= 1102001001 and weaponID <= 1102001999 then return 102001 end  
if weaponID >= 1102002001 and weaponID <= 1102002999 then return 102002 end  
if weaponID >= 1102003001 and weaponID <= 1102003999 then return 102003 end  
if weaponID >= 1102004001 and weaponID <= 1102004999 then return 102004 end  
if weaponID >= 1102005001 and weaponID <= 1102005999 then return 102005 end  
if weaponID >= 1102007001 and weaponID <= 1102007999 then return 102007 end  
if weaponID >= 1102008001 and weaponID <= 1102008999 then return 102008 end  
if weaponID >= 1102105001 and weaponID <= 1102105999 then return 102105 end  

if weaponID >= 1103001001 and weaponID <= 1103001999 then return 103001 end  
if weaponID >= 1103002001 and weaponID <= 1103002999 then return 103002 end  
if weaponID >= 1103003001 and weaponID <= 1103003999 then return 103003 end  
if weaponID >= 1103004001 and weaponID <= 1103004999 then return 103004 end  
if weaponID >= 1103005001 and weaponID <= 1103005999 then return 103005 end  
if weaponID >= 1103006001 and weaponID <= 1103006999 then return 103006 end  
if weaponID >= 1103007001 and weaponID <= 1103007999 then return 103007 end  
if weaponID >= 1103008001 and weaponID <= 1103008999 then return 103008 end  
if weaponID >= 1103103001 and weaponID <= 1103103999 then return 103103 end
if weaponID >= 1103009001 and weaponID <= 1103009999 then return 103009 end  
if weaponID >= 1103010001 and weaponID <= 1103010999 then return 103010 end  
if weaponID >= 1103011001 and weaponID <= 1103011999 then return 103011 end  
if weaponID >= 1103012001 and weaponID <= 1103012999 then return 103012 end  
if weaponID >= 1103100001 and weaponID <= 1103100999 then return 103100 end  
if weaponID >= 1103102001 and weaponID <= 1103102999 then return 103102 end  

if weaponID >= 1104001001 and weaponID <= 1104001999 then return 104001 end  
if weaponID >= 1104002001 and weaponID <= 1104002999 then return 104002 end  
if weaponID >= 1104003001 and weaponID <= 1104003999 then return 104003 end  
if weaponID >= 1104004001 and weaponID <= 1104004999 then return 104004 end  
if weaponID >= 1104101001 and weaponID <= 1104101999 then return 104101 end  
if weaponID >= 1104102001 and weaponID <= 1104102999 then return 104102 end  

if weaponID >= 1105001001 and weaponID <= 1105001999 then return 105001 end  
if weaponID >= 1105002001 and weaponID <= 1105002999 then return 105002 end  
if weaponID >= 1105010001 and weaponID <= 1105010999 then return 105010 end  

if weaponID >= 1108001001 and weaponID <= 1108001999 then return 108001 end  
if weaponID >= 1108004001 and weaponID <= 1108004999 then return 108004 end  
if weaponID >= 1108005001 and weaponID <= 1108005999 then return 108005 end  

    return weaponID
end

_G.WeaponSkinPack = {

    AKM = {
        [1] = { main = 1101001213, attachments = {} }, 
        [2] = { main = 1101001174, attachments = {} }, 
        [3] = { main = 1101001242, attachments = {} }, 
        [4] = { main = 1101001256, attachments = {} }, 
        [5] = { main = 1101001249, attachments = {} }, 
        [6] = { main = 1101001265, attachments = {} }, 
        [7] = { main = 1101001276, attachments = {} }, 
        [8] = { main = 1101001103, attachments = {} }, 
        [9] = { main = 1101001089, attachments = {} }, 
    },

    M16A4 = {
        [1] = { main = 1101002081, attachments = {} },
        [2] = { main = 1101002156, attachments = {} }, 
        [3] = { main = 1101002149, attachments = {} }, 
        [4] = { main = 1101002142, attachments = {} }, 
        [5] = { main = 1101002133, attachments = {} }, 
        [6] = { main = 1101002125, attachments = {} }, 
        [7] = { main = 1101002117, attachments = {} }, 
    },

    SCAR = {
        [1] = { main = 1101003227, attachments = {} }, 
        [2] = { main = 1101003219, attachments = {} }, 
        [3] = { main = 1101003208, attachments = {} }, 
        [4] = { main = 1101003195, attachments = {} }, 
        [5] = { main = 1101003167, attachments = {} }, 
        [6] = { main = 1101003146, attachments = {} }, 
        [7] = { main = 1101003119, attachments = {} }, 
        [8] = { main = 1101003099, attachments = {} }, 
        [9] = { main = 1101003080, attachments = {} }, 
        [10] = { main = 1101003070, attachments = {} }, 
    },

    M416 = {
        [1] = { main = 1101004046, attachments = {} }, 
        [2] = { main = 1101004062, attachments = {} }, 
        [3] = { main = 1101004078, attachments = {} }, 
        [4] = { main = 1101004086, attachments = {} }, 
        [5] = { main = 1101004098, attachments = {} }, 
        [6] = { main = 1101004138, attachments = {} }, 
        [7] = { main = 1101004163, attachments = {} }, 
        [8] = { main = 1101004201, attachments = {} }, 
        [9] = { main = 1101004209, attachments = {} }, 
        [10] = { main = 1101004218, attachments = {} }, 
        [11] = { main = 1101004226, attachments = {} }, 
        [12] = { main = 1101004236, attachments = {} }, 
        [13] = { main = 1101004246, attachments = {} }, 
        [14] = { main = 1101004034, attachments = {} }, 
    },

    GROZA = {
        [1] = { main = 1101005098, attachments = {} }, 
        [2] = { main = 1101005052, attachments = {} }, 
        [3] = { main = 1101005038, attachments = {} }, 
        [4] = { main = 1101005043, attachments = {} }, 
        [5] = { main = 1101005090, attachments = {} }, 
        [6] = { main = 1101005082, attachments = {} }, 
    },

    AUG = {
        [1] = { main = 1101006085, attachments = {} }, 
        [2] = { main = 1101006075, attachments = {} }, 
        [3] = { main = 1101006062, attachments = {} }, 
        [4] = { main = 1101006033, attachments = {} }, 
    },

    QBZ = {
        [1] = { main = 1101007062, attachments = {} },
        [2] = { main = 1101007071, attachments = {} }, 
        [3] = { main = 1101007046, attachments = {} }, 
        [4] = { main = 1101007078, attachments = {} }, 
    },

    M762 = {
        [1] = { main = 1101008163, attachments = {} }, 
        [2] = { main = 1101008154, attachments = {} }, 
        [3] = { main = 1101008146, attachments = {} }, 
        [4] = { main = 1101008136, attachments = {} }, 
        [5] = { main = 1101008079, attachments = {} }, 
        [6] = { main = 1101008061, attachments = {} }, 
        [7] = { main = 1101008104, attachments = {} }, 
        [8] = { main = 1101008126, attachments = {} }, 
        [9] = { main = 1101008116, attachments = {} }, 
        [10] = { main = 1101008051, attachments = {} }, 
    },

    Mk47 = {
        [1] = { main = 1101009019, attachments = {} },
        [2] = { main = 1101009022, attachments = {} }, 
        [3] = { main = 1101009013, attachments = {} }, 
    },

    G36C = {
        [1] = { main = 1101010029, attachments = {} }, 
        [2] = { main = 1101010024, attachments = {} }, 
    },

    HoneyPot = {
        [1] = { main = 1101012033, attachments = {} },
        [2] = { main = 1101012018, attachments = {} }, 
        [3] = { main = 1101012024, attachments = {} }, 
        [4] = { main = 1101012009, attachments = {} }, 
    },

    FAMAS = {
        [1] = { main = 1101100012, attachments = {} },
        [2] = { main = 1101100018, attachments = {} }, 
    },

    ASM = {
        [1] = { main = 1101101007, attachments = {} },
    },

    ACE32 = {
        [1] = { main = 1101102049, attachments = {} }, 
        [2] = { main = 1101102007, attachments = {} }, 
        [3] = { main = 1101102017, attachments = {} }, 
        [4] = { main = 1101102025, attachments = {} }, 
    },

    UMP = {
        [1] = { main = 1102002136, attachments = {} }, 
        [2] = { main = 1102002424, attachments = {} }, 
        [3] = { main = 1102002438, attachments = {} }, 
        [4] = { main = 1102002446, attachments = {} }, 
    },

    UZI = {
        [1] = { main = 1102001120, attachments = {} }, 
        [2] = { main = 1102001130, attachments = {} }, 
    },

    VECTOR = {
        [1] = { main = 1102003100, attachments = {} },
        [2] = { main = 1102003080, attachments = {} }, 
    },

    THOMPSON = {
        [1] = { main = 1102004018, attachments = {} }, 
        [2] = { main = 1102004034, attachments = {} }, 
    },

    BIZON = {
        [1] = { main = 1102005064, attachments = {} },
        [2] = { main = 1102005072, attachments = {} }, 
        [3] = { main = 1102005078, attachments = {} }, 
    },

    MP5K = {
        [1] = { main = 1102007019, attachments = {} },
        [2] = { main = 1102007019, attachments = {} }, 
    },

    JS9 = {
        [1] = { main = 1102008001, attachments = {} },
    },

    P90 = {
        [1] = { main = 1102105028, attachments = {} }, 
        [2] = { main = 1102105018, attachments = {} }, 
        [3] = { main = 1102105012, attachments = {} }, 
    },

    K98 = {
        [1] = { main = 1103001202, attachments = {} },
        [2] = { main = 1103001179, attachments = {} }, 
        [3] = { main = 1103001191, attachments = {} }, 
    },

    M24 = {
        [1] = { main = 1103002156, attachments = {} },
        [2] = { main = 1103002087, attachments = {} }, 
        [3] = { main = 1103002059, attachments = {} }, 
    },

    AWM = {
        [1] = { main = 1103003099, attachments = {} }, 
        [2] = { main = 1103003087, attachments = {} }, 
        [3] = { main = 1103003079, attachments = {} }, 
        [4] = { main = 1103003062, attachments = {} }, 
        [5] = { main = 1103003042, attachments = {} }, 
    },

    M1Garand = {
        [1] = { main = 1103103007, attachments = {} }, 
    },

    Win94 = {
        [1] = { main = 1103008022, attachments = {} },
    },

    Mosin = {
        [1] = { main = 1103011003, attachments = {} },
    },

    AMR = {
        [1] = { main = 1103012039, attachments = {} },
        [2] = { main = 1103012010, attachments = {} }, 
        [3] = { main = 1103012019, attachments = {} }, 
        [4] = { main = 1103012031, attachments = {} }, 
    },

    DSR = {
        [1] = { main = 1103102007, attachments = {} },
    },

    SKS = {
        [1] = { main = 1103004037, attachments = {} },
    },

    VSS = {
        [1] = { main = 1103005024, attachments = {} },
    },

    Mini14 = {
        [1] = { main = 1103006030, attachments = {} },
    },

    MK14 = {
        [1] = { main = 1103007028, attachments = {} },
        [2] = { main = 1103007038, attachments = {} }, 
        [3] = { main = 1103007043, attachments = {} }, 
    },

    SLR = {
        [1] = { main = 1103009051, attachments = {} },
    },

    QBU = {
        [1] = { main = 1103010014, attachments = {} },
    },

    Mk12 = {
        [1] = { main = 1103100007, attachments = {} },
    },

    S686 = {
        [1] = { main = 1104001035, attachments = {} },
    },

    S1897 = {
        [1] = { main = 1104002049, attachments = {} },
    },

    S12K = {
        [1] = { main = 1104003037, attachments = {} }, 
        [2] = { main = 1104003046, attachments = {} }, 
        [3] = { main = 1104003041, attachments = {} },
    },

    DBS = {
        [1] = { main = 1104004041, attachments = {} },
        [2] = { main = 1104004035, attachments = {} }, 
        [3] = { main = 1104004051, attachments = {} }, 
    },

    M1014 = {
        [1] = { main = 1104101002, attachments = {} },
    },

    NS2000 = {
        [1] = { main = 1104102004, attachments = {} },
    },

    DP28 = {
        [1] = { main = 1105002091, attachments = {} },
    },

    M249 = {
        [1] = { main = 1105001069, attachments = {} },
        [2] = { main = 1105001034, attachments = {} }, 
        [3] = { main = 1105001048, attachments = {} }, 
    },

    MG3 = {
        [1] = { main = 1105010019, attachments = {} },
        [2] = { main = 1105010008, attachments = {} }, 
        [3] = { main = 1105010026, attachments = {} }, 
        [4] = { main = 1105010028, attachments = {} }, 
    },

    PAN = {
        [1] = { main = 1108004027, attachments = {} }, 
        [2] = { main = 1108004416, attachments = {} }, 
        [3] = { main = 1108004380, attachments = {} }, 
        [4] = { main = 1081201, attachments = {} }, 
        [5] = { main = 1108004283, attachments = {} }, 
        [6] = { main = 1108004230, attachments = {} }, 
    },
    DAGGER = {
        [1] = { main = 1108001103, attachments = {} }, 
        [2] = { main = 1108005052, attachments = {} }, 
        [3] = { main = 1081201, attachments = {} }, 
        [4] = { main = 1108001069, attachments = {} }, 
    },
    Machete = {
        [1] = { main = 1108001103, attachments = {} }, 
        [2] = { main = 1108001081, attachments = {} }, 
        [3] = { main = 1081201, attachments = {} }, 
        [4] = { main = 1108001099, attachments = {} }, 
        [5] = { main = 1108001069, attachments = {} }, 
    },
}

local function ReadConfigFile()
    local configPath = nil
    for _, path in ipairs(possiblePaths) do
        local file = io.open(path, "r")
        if file then
            file:close()
            configPath = path
            break
        end
    end

    if not configPath then return end

    local file = io.open(configPath, "r")
    local content = file:read("*all")
    file:close()

    for line in content:gmatch("[^\r\n]+") do
        if not line:match("^%s*#") then
            local key, value = line:match("(%w+_?%w*)%s*=%s*(%d+)")
            if key and value then
                local index = tonumber(value)

                if key == "FOV_ENABLE" then
                    _G.ConfigFOVEnable = (index == 1)
                    lastConfig[key] = index
                end
                if key == "FOV_VALUE" then
                    local fovValue = index
                    if fovValue < 90 then fovValue = 90 end
                    if fovValue > 120 then fovValue = 120 end
                    _G.ConfigFOV = fovValue
                    lastConfig[key] = index
                end

                if key == "WATERMARK" then
                    _G.WatermarkEnabled = (index == 1)
                    lastConfig[key] = index
                end

                if key == "WEAPON_ANIM" then
                    local enabled = (index == 1)
                    if _G.WeaponAnimationModule then
                        _G.WeaponAnimationModule._enabled = enabled
                        _G.WeaponAnimationModule.AUTO_START = enabled
                        if enabled then
                            pcall(function() _G.WeaponAnimationModule.Start() end)
                        else
                            pcall(function() _G.WeaponAnimationModule.Stop() end)
                        end
                    end
                    lastConfig[key] = index
                end

                if key == "PETSKIN" then
                    _G.PetSkinMapIndex = index
                    lastConfig[key] = index
                end

                if key == "TRAIL_ENABLE" then
                    if _G.GoldenLeavesTrail then
                        _G.GoldenLeavesTrail.Enabled = (index == 1)
                    end
                    lastConfig[key] = index
                end
                if key == "TRAIL_TYPE" then
                    local trailId = tonumber(value)
                    if trailId == 4531001 or trailId == 4531002 then
                        if _G.GoldenLeavesTrail then
                            _G.GoldenLeavesTrail.TRAIL_ITEM_ID = trailId
                        end
                    end
                    lastConfig[key] = index
                end

                if key == "WEATHER" then
                    _G.WeatherMode = index
                    lastConfig[key] = index
                    if _G.UpdateWeatherMode then
                        _G.UpdateWeatherMode(index)
                    end
                end

                if key == "DEADBOX_SKIN" then
                    _G.EnableDeadBoxSkin = (index == 1)
                    lastConfig[key] = index
                end

                if key == "EXPLOSION_WEAPON" then
                    if _G.GrenadeFX then
                        _G.GrenadeFX.FORCE_WEAPON_ID = index
                        pcall(function()
                            _G.GrenadeFX.BindMaxWeapon(index)
                        end)
                    end
                    lastConfig[key] = index
                end

                local isCustom = string.sub(key, 1, 7) == "CUSTOM_"
                local weaponKey = isCustom and string.sub(key, 8) or key
                local weaponID = _G.WeaponNameToID[weaponKey]

                if weaponID and lastConfig[key] ~= index then
                    if isCustom then

                        _G.WeaponSkinID = _G.WeaponSkinID or {}
                        _G.WeaponSkinID[weaponID] = index
                    else

                        local skinPack = _G.WeaponSkinPack[key] and _G.WeaponSkinPack[key][index]
                        if skinPack and skinPack.main then
                            _G.WeaponSkinID = _G.WeaponSkinID or {}
                            _G.WeaponSkinID[weaponID] = skinPack.main
                        end
                    end
                    lastConfig[key] = index
                end
            end
        end
    end

    local vehicleConfigs = {
        DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
        MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917, RONY = 1916,
        RZR = 1966, BIGFOOT = 1953, HORSE = 1987, MINIBUS = 1904, BOAT = 1911,
        ROADSTER = 19116, MIRADO = 1914, MIRADOC = 1915
    }

    for line in content:gmatch("[^\r\n]+") do
        if not line:match("^%s*#") then
            local key, value = line:match("(%w+)=(%d+)")
            if key and value then
                local numValue = tonumber(value)

                if vehicleConfigs[key] and lastConfig[key] ~= numValue then
                    _G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
                    _G.VehicleSkinIndex[vehicleConfigs[key]] = numValue + 1
                    lastConfig[key] = numValue
                end

                local roleSkins = {
                    SHIRT = "_G.SuitSkin", HAIR = "_G.HairSkin", HAT = "_G.HatSkin",
                    FACE = "_G.FaceSkin", MASK = "_G.MaskSkin", GLOVES = "_G.GlovesSkin",
                    PANT = "_G.PantSkin", SHOE = "_G.ShoeSkin", PARACHUTE = "_G.ParachuteSkin",
                    GLIDER = "_G.GliderSkin", BACKPACK1 = "_G.Backpack1Skin", BACKPACK2 = "_G.Backpack2Skin",
                    BACKPACK3 = "_G.Backpack3Skin", BACKPACK4 = "_G.Backpack4Skin", BACKPACK5 = "_G.Backpack5Skin",
                    BACKPACK6 = "_G.Backpack6Skin", HELMET1 = "_G.Helmet1Skin", HELMET2 = "_G.Helmet2Skin",
                    HELMET3 = "_G.Helmet3Skin", HELMET4 = "_G.Helmet4Skin", HELMET5 = "_G.Helmet5Skin",
                    HELMET6 = "_G.Helmet6Skin",
                    ARMOR1 = "_G.Armor1Skin", ARMOR2 = "_G.Armor2Skin", ARMOR3 = "_G.Armor3Skin",
                    ARMOR4 = "_G.Armor4Skin", ARMOR5 = "_G.Armor5Skin", ARMOR6 = "_G.Armor6Skin"
                }
                if roleSkins[key] and lastConfig[key] ~= numValue then
                    load(roleSkins[key] .. " = " .. numValue)()
                    lastConfig[key] = numValue
                end
            end
        end
    end
end

do
    local ModuleManager = require('client.module_framework.ModuleManager')
    local ItemUpgradeSystem = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
    local download_util = require('client.slua.logic.download.puffer.download_util')
    local PufferConst = require('client.slua.logic.download.puffer_const')
    local PufferManager = require('client.slua.logic.download.puffer.puffer_manager')

    _G.g_parts = {}
    _G.g_parts_subtype = {}

    _G.isResourceDownloaded = function(itemId)
        if not itemId or itemId <= 0 then return true end
        local cached = _G.skinDownloadCache[itemId]
        if cached ~= nil then return cached end
        local downloaded = false
        local ok = pcall(function()
            downloaded = download_util.IsDownloaded(itemId)
        end)
        if not ok then
            local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, { itemId })
            downloaded = state == PufferConst.ENUM_DownloadState.Done
        end
        _G.skinDownloadCache[itemId] = downloaded
        return downloaded
    end

    _G.muzzles = {
        id_flash_hider  = { 201010,2010101,2010102,2010103,2010104,2010105, 201005,2010051,2010052,2010053,2010054,201005, 201004,2010041,2010042,2010043,2010044,2010045 },
        id_compensator  = { 201009,2010091,2010092,2010093,2010094,2010095, 201003,2010031,2010032,2010033,2010034,2010035, 201002,2010021,2010022,2010023,2010024,2010025 },
        id_suppressor   = { 201011,2010111,2010112,2010113,2010114,2010115, 201006,2010061,2010062,2010063,2010064,2010065, 201007,2010071,2010072,2010073,2010074,2010075 },
        id_duckbill     = { 201012 },
        id_barrel_ext   = { 201051, 201050, 201055 },
        id_muzzle_brake = { 201053, 201052, 201054 },
    }
    _G.foregrips = {
        id_Angledforegrip = { 202001,2020011,2020012,2020013,2020014,2020015 },
        id_thumb_grip = { 202006,2020061,2020062,2020063,2020064,2020065 },
        id_vertical_grip = { 202002,2020021,2020022,2020023,2020024,2020025 },
        id_light_grip = { 202004,2020041,2020042,2020043,2020044,2020045 },
        id_half_grip = { 202005,2020051,2020052,2020053,2020054,2020055 },
        id_ergonomic_grip = { 202051,2020511,2020512,2020513,2020514,2020515 },
        id_laser_sight = { 202007,2020071,2020072,2020073,2020074,2020075 },
    }
    _G.magazines = {
        id_expanded_mag = { 204011,2040111,2040112,2040113,2040114,2040115, 204007,2040071,2040072,2040073,2040074,2040075, 204004,2040041,2040042,2040043,2040044,2040045, 204015,2040151,2040152,2040153,2040154,2040155 },
        id_quick_mag = { 204012,2040121,2040122,2040123,2040124,2040125, 204008,2040081,2040082,2040083,2040084,2040085, 204005,2040051,2040052,2040053,2040054,2040055 },
        id_expanded_quick_mag = { 204013,2040131,2040132,2040133,2040134,2040135, 204009,2040091,2040092,2040093,2040094,2040095, 204006,2040061,2040062,2040063,2040064,2040065 },
    }
    _G.scopes = {
        id_reddot = 203001, id_holo = 203002, id_2x = 203003, id_4x = 203004,
        id_8x = 203005, id_3x = 203014, id_6x = 203015, id_canted = 203018,
        id_reddot_b = 203051, id_holo_b = 203052, id_2x_b = 203053,
        id_4x_b = 203054, id_8x_b = 203055, id_3x_b = 203056, id_6x_b = 203057,
    }
    _G.stock = {
        id_microStock = 205001, id_tactical = 205002, id_bulletloop = 204014,
        id_CheekPad = 205003, id_heavy = 205010,
    }

    _G.familyKey = {
        id_flash_hider = 'FH', id_compensator = 'CP', id_suppressor = 'SP',
        id_duckbill = 'DK', id_barrel_ext = 'BE', id_muzzle_brake = 'MB',
        id_Angledforegrip = 'AG', id_thumb_grip = 'TG', id_vertical_grip = 'VG',
        id_light_grip = 'LG', id_half_grip = 'HG', id_ergonomic_grip = 'EG', id_laser_sight = 'LS',
        id_expanded_mag = 'EM', id_quick_mag = 'QM', id_expanded_quick_mag = 'EQ',
        id_reddot = 'RD', id_holo = 'HO', id_2x = 'S2', id_3x = 'S3', id_4x = 'S4',
        id_6x = 'S6', id_8x = 'S8', id_canted = 'CS',
        id_reddot_b = 'RD', id_holo_b = 'HO', id_2x_b = 'S2', id_3x_b = 'S3',
        id_4x_b = 'S4', id_6x_b = 'S6', id_8x_b = 'S8',
        id_microStock = 'ST', id_tactical = 'TS', id_bulletloop = 'BL',
        id_CheekPad = 'CH', id_heavy = 'HS',
    }

    _G.idToFamily = {}
    _G.knownIDs = {}
    local function reg(id, fam)
        if id and id > 0 then _G.idToFamily[id] = fam _G.knownIDs[id] = true end
    end
    for f, l in pairs(_G.muzzles) do for _, id in ipairs(l) do reg(id, f) end end
    for f, l in pairs(_G.foregrips) do for _, id in ipairs(l) do reg(id, f) end end
    for f, l in pairs(_G.magazines) do for _, id in ipairs(l) do reg(id, f) end end
    for f, id in pairs(_G.scopes) do reg(id, f) end
    for f, id in pairs(_G.stock) do reg(id, f) end

    local SUBTYPE_MUZZLE, SUBTYPE_SCOPE, SUBTYPE_STOCK, SUBTYPE_MAG, SUBTYPE_GRIP = 201, 202, 203, 204, 205

    local function splitStr(str, sep)
        local t = {}
        if not str or str == '' then return t end
        for part in string.gmatch(str, '([^' .. sep .. ']+)') do table.insert(t, part) end
        return t
    end

    local function get_group_id(itemId)
        if not ItemUpgradeSystem or not itemId then return nil end
        local c = ItemUpgradeSystem:GetUpgradeCfg(itemId)
        return c and c.GroupID or nil
    end

    local function getFamily(id)
        return id and _G.idToFamily[id]
    end

    local function getPartOriginID(partId)
        if not partId or partId == 0 then return 0 end
        local ok, cfg = pcall(function() return CDataTable.GetTableData('WeaponAttachAttrBPTable', partId) end)
        if ok and cfg and cfg.ParentID and cfg.ParentID > 0 then return cfg.ParentID end
        return 0
    end

    local function getBPID(resId)
        local bp = resId
        pcall(function()
            local UAvatarUtils = import('AvatarUtils')
            if UAvatarUtils and UAvatarUtils.GetBPIDByResID then
                local v = UAvatarUtils.GetBPIDByResID(resId)
                if v and v > 0 then bp = v end
            end
        end)
        pcall(function()
            local UBackpackUtils = import('BackpackUtils')
            if UBackpackUtils and UBackpackUtils.GetBPIDByResID then
                local v = UBackpackUtils.GetBPIDByResID(resId)
                if v and v > 0 then bp = v end
            end
        end)
        return bp
    end

    local function savePart(skinId, baseId, skinPartId)
        if not skinId or not baseId or not skinPartId or baseId <= 0 or skinPartId <= 0 then return end
        _G.g_parts[skinId][baseId] = skinPartId
        local fam = getFamily(baseId)
        if not fam then return end
        local key = _G.familyKey[fam]
        if key then _G.g_parts[skinId][key] = skinPartId end
        if _G.muzzles[fam] then
            for _, id in ipairs(_G.muzzles[fam]) do 
                _G.g_parts[skinId][id] = skinPartId 
            end
        elseif _G.magazines[fam] then
            for _, id in ipairs(_G.magazines[fam]) do 
                _G.g_parts[skinId][id] = skinPartId 
            end
        elseif _G.foregrips[fam] then
            for _, id in ipairs(_G.foregrips[fam]) do
                _G.g_parts[skinId][id] = skinPartId 
            end
        elseif _G.scopes[fam] then
            for fid, f in pairs(_G.scopes) do 
                if f == fam then 
                    _G.g_parts[skinId][fid] = skinPartId 
                end 
            end
        elseif _G.stock[fam] then
            _G.g_parts[skinId][_G.stock[fam]] = skinPartId
        end
    end

    local function saveBySubType(skinId, subType, skinPartId)
        if not skinId or not subType or not skinPartId or skinPartId <= 0 then return end
        if not _G.g_parts_subtype[skinId] then _G.g_parts_subtype[skinId] = {} end
        _G.g_parts_subtype[skinId][subType] = skinPartId
    end

    _G.InitParts = function(groupId, itemId)
        if not itemId then return _G.g_parts end
        if not _G.g_parts[itemId] then _G.g_parts[itemId] = {} end
        if not _G.g_parts_subtype[itemId] then _G.g_parts_subtype[itemId] = {} end

        pcall(function()
            local bpId = getBPID(itemId)
            local tryIds = { bpId, itemId }
            local icfg = CDataTable.GetTableData('Item', itemId)
            if icfg and icfg.BPID and icfg.BPID > 0 then table.insert(tryIds, icfg.BPID) end
            for _, tid in ipairs(tryIds) do
                local cfg = CDataTable.GetTableData('WeaponAttrBPTable', tid)
                if cfg and cfg.AttachmentSkinIDList and cfg.AttachmentSkinIDList ~= '' then
                    for _, pair in ipairs(splitStr(cfg.AttachmentSkinIDList, '|')) do
                        local nums = splitStr(pair, '-')
                        local b, s = tonumber(nums[1]), tonumber(nums[2])
                        if b and s then savePart(itemId, b, s) end
                    end
                end
            end
        end)

        if ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
            groupId = ItemUpgradeSystem:GetNormalGroupID(groupId or get_group_id(itemId))
        else
            groupId = groupId or get_group_id(itemId)
        end

        pcall(function()
            local partsDic = ItemUpgradeSystem:GetPartsDic(groupId)
            if partsDic then
                for subType, partList in pairs(partsDic) do
                    for _, partId in ipairs(partList) do
                        local skinPartId = partId
                        if ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
                            local sw = ItemUpgradeSystem:PartIDSwitch(partId, true)
                            if sw and sw ~= partId then skinPartId = sw end
                        end
                        saveBySubType(itemId, subType, skinPartId)
                        local parent = getPartOriginID(skinPartId)
                        if parent == 0 then parent = getPartOriginID(partId) end
                        if parent > 0 then
                            savePart(itemId, parent, skinPartId)
                        elseif _G.knownIDs[partId] then
                            savePart(itemId, partId, skinPartId)
                        end
                    end
                end
            end
        end)

        pcall(function()
            local UAvatarUtils = import('AvatarUtils')
            if UAvatarUtils and UAvatarUtils.GetWeaponAvatarDefaultAttachmentSkin then
                local list = UAvatarUtils.GetWeaponAvatarDefaultAttachmentSkin(itemId, {}, false) or {}
                for baseId, skinPartId in pairs(list) do
                    if baseId and skinPartId and skinPartId > 0 then
                        if _G.knownIDs[baseId] then
                            savePart(itemId, baseId, skinPartId)
                        else
                            local parent = getPartOriginID(skinPartId)
                            if parent > 0 then savePart(itemId, parent, skinPartId)
                            else _G.g_parts[itemId][baseId] = skinPartId end
                        end
                    end
                end
            end
        end)

        return _G.g_parts
    end

    local function findSkin(current_id, avatarid, slot, subType)
        if not _G.isResourceDownloaded(avatarid) then return nil end
        _G.InitParts(get_group_id(avatarid), avatarid)
        local p = _G.g_parts[avatarid]
        if not p then return nil end
        if p[current_id] and p[current_id] > 0 then
            local candidate = p[current_id]
            if _G.isResourceDownloaded(candidate) then return candidate end
        end
        local fam = getFamily(current_id)
        if fam then
            local key = _G.familyKey[fam]
            if key and p[key] and p[key] > 0 and _G.isResourceDownloaded(p[key]) then return p[key] end
            for sid, sv in pairs(p) do
                if type(sid) == 'number' and getFamily(sid) == fam and sv > 0 and _G.isResourceDownloaded(sv) then
                    return sv
                end
            end
        end
        if subType then
            local st = _G.g_parts_subtype[avatarid]
            if st and st[subType] and st[subType] > 0 then
                local candidate = st[subType]
                if _G.isResourceDownloaded(candidate) then return candidate end
            end
        end
        return nil
    end

    local function resolve(id, av, slot, subType)
        local init = id
        if not id or id <= 0 then return id, false end
        if not _G.isResourceDownloaded(av) then return id, false end
        local s = findSkin(id, av, slot, subType)
        if s and s > 0 then
            if s ~= id and not _G.isResourceDownloaded(s) then return id, false end
            return s, s ~= init
        end
        return id, false
    end

    _G.get_muzzleid = function(id, av) return resolve(id, av, 0, SUBTYPE_MUZZLE) end
    _G.get_forgripid = function(id, av) return resolve(id, av, 4, SUBTYPE_GRIP) end
    _G.get_magazinesid = function(id, av) return resolve(id, av, 1, SUBTYPE_MAG) end
    _G.get_scopeid = function(id, av) return resolve(id, av, 3, SUBTYPE_SCOPE) end
    _G.get_stockid = function(id, av) return resolve(id, av, 2, SUBTYPE_STOCK) end

    _G.apply_attachment = function(CurWeapon, avatarid)
        if not CurWeapon or not avatarid or avatarid <= 0 then return false end
        if not _G.isResourceDownloaded(avatarid) then return false end
        local array = CurWeapon.synData
        if not array or not slua.isValid(array) then return false end
        local changed = false
        for AttachIdx = 0, 4 do
            local Data = array:Get(AttachIdx)
            if Data and slua.isValid(Data) then
                local itemid = slua.IndexReference(Data, 'defineID').TypeSpecificID
                if itemid and itemid > 0 and itemid < 10000000 then
                    local newId, isrefresh
                    if AttachIdx == 0 then
                        newId, isrefresh = _G.get_muzzleid(itemid, avatarid)
                    elseif AttachIdx == 1 then
                        newId, isrefresh = _G.get_forgripid(itemid, avatarid)
                    elseif AttachIdx == 2 then
                        newId, isrefresh = _G.get_magazinesid(itemid, avatarid)
                    elseif AttachIdx == 3 then
                        newId, isrefresh = _G.get_stockid(itemid, avatarid)
                    elseif AttachIdx == 4 then
                        newId, isrefresh = _G.get_scopeid(itemid, avatarid)
                    end
                    if isrefresh then
                        slua.IndexReference(Data, 'defineID').TypeSpecificID = newId
                        array:Set(AttachIdx, Data)
                        changed = true
                    end
                end
            end
        end
        if changed then
            pcall(function() CurWeapon:DelayHandleAvatarMeshChanged() end)
        end
        return changed
    end

    _G.equip_weapon_avatar = function(uCharacter)
        if not uCharacter or not slua.isValid(uCharacter) then return end
        local WeaponManager = uCharacter:GetWeaponManager()
        if not WeaponManager or not slua.isValid(WeaponManager) then return end
        local uWeaponList = WeaponManager:GetAllInventoryWeaponList(false)
        if not uWeaponList or not slua.isValid(uWeaponList) then return end

        for i = 0, uWeaponList:Num() - 1 do
            local CurWeapon = uWeaponList:Get(i)
            if slua.isValid(CurWeapon) then
                local AttachmentArray = CurWeapon.synData
                if not AttachmentArray or not slua.isValid(AttachmentArray) then goto continue_weapon end

                local AttachmentData = AttachmentArray:Get(7)
                if not AttachmentData or not slua.isValid(AttachmentData) then goto continue_weapon end

                local current_skin_id = slua.IndexReference(AttachmentData, 'defineID').TypeSpecificID
                if not current_skin_id or current_skin_id <= 0 then goto continue_weapon end

                local weapon_id = CurWeapon:GetWeaponID()
                if current_skin_id == weapon_id then goto continue_weapon end

                if not _G.isResourceDownloaded(current_skin_id) then goto continue_weapon end

                _G.apply_attachment(CurWeapon, current_skin_id)
            end
            ::continue_weapon::
        end
    end
end

function _G.get_skin_id2(weaponID)
    if not weaponID then return nil end
    local baseWeaponID = _G.getBaseWeaponID(weaponID)
    local targetSkinID = baseWeaponID

    if _G.WeaponSkinID and _G.WeaponSkinID[baseWeaponID] and _G.WeaponSkinID[baseWeaponID] ~= 0 then
        targetSkinID = _G.WeaponSkinID[baseWeaponID]
    end

    return targetSkinID
end

function _G.GameAvatarHandlerweapons()
    pcall(function()
        local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not PlayerController then return end

        local uCharacter = PlayerController:GetPlayerCharacterSafety()
        if not uCharacter or not slua.isValid(uCharacter) then return end

        local currweapon = uCharacter:GetCurrentWeapon()
        if currweapon and slua.isValid(currweapon) then
            local weaponid = currweapon:GetItemDefineID().TypeSpecificID
            local targetSkinID = _G.get_skin_id2(weaponid)
            local currentSkinID = slua.IndexReference(currweapon.synData:Get(7), "defineID").TypeSpecificID

            if currentSkinID ~= targetSkinID then
                local skinData = currweapon.synData:Get(7)
                if skinData then
                    skinData.defineID.TypeSpecificID = targetSkinID
                    currweapon.synData:Set(7, skinData)
                end
            end

            if _G.ApplyCachedAttachments then
                _G.ApplyCachedAttachments(currweapon, targetSkinID)
            end

            if currweapon.DelayHandleAvatarMeshChanged then
                currweapon:DelayHandleAvatarMeshChanged()
            end
        end

        if _G.equip_weapon_avatar then
            _G.equip_weapon_avatar(uCharacter)
        end
    end)
end

local TXtime_ticker = require("common.time_ticker")
if _G.weaponAvatarTimerIndex and TXtime_ticker.IsRunning(_G.weaponAvatarTimerIndex) then
    TXtime_ticker.RemoveTimer(_G.weaponAvatarTimerIndex)
end
_G.weaponAvatarTimerIndex = TXtime_ticker.AddTimerLoop(0, _G.GameAvatarHandlerweapons, -1, 0.3)

_G.VehskinIdMappings = {

    [1901] = {
        1901001, 1901091, 1901073, 1901074, 1901075, 1901076, 1901070, 1901098, 1901102
    },

    [1902] = {
        1902001, 1902030, 1902026, 1902067
    },

    [1917] = {
        1917001, 1917006
    },

    [1903] = {

        1903218, 
        1903219, 
        1903220, 
        1903221, 
        1903222, 
        1903223, 
        1903014, 
        1903212, 
        1903213, 
        1903074, 
        1903075, 
        1903076, 
    },

    [1961] = {

        1961065, 
        1961062, 
        1961066, 
        1961152, 
        1961067, 
        1961063, 
        1961064, 
        1961151, 
        1961153, 
        1961147, 
        1961148, 
        1961149, 
        1961144, 
        1961145, 
        1961054, 
        1961055, 
        1961056, 
        1961057, 
    },

    [1914] = {
        1915021, 
        1915022, 
        1915017, 
        1915018, 
        1915005, 
        1915006, 
        1915007, 
        1915008, 
        1915009, 
    },

    [19116] = {
        1915021, 
        1915022, 
        1915017, 
        1915018, 
        1915005, 
        1915006, 
        1915007, 
        1915008, 
        1915009, 
    },

    [1915] = {
        1915021, 
        1915022, 
        1915017, 
        1915018, 
        1915005, 
        1915006, 
        1915007, 
        1915008, 
        1915009, 
    },

    [1908] = { 1908001, 1908104, 1908095, 1908094, 1908085, 1908084, 1908078, 1908077 },
    [1909] = { 1908001, 1908104, 1908095, 1908094, 1908085, 1908084, 1908078, 1908077 },
    [1910] = { 1908001, 1908104, 1908095, 1908094, 1908085, 1908084, 1908078, 1908077 },

    [1916] = { 1916001, 1916004, 1916005, 1916006 },

    [1907] = { 1907001, 1907054, 1907058, 1907059, 1907011, 1907012, 1907013, 1907014, 1907015 },

    [1953] = { 1953001, 1953004, 1953008 },

    [1966] = { 1966017, 1966016 },

    [19110] = { 1911001, 1911013, 1911003, 1911004, 1911005, 1911006, 1911007, 1911008, 1911009, 1911010, 1911011, 1911012 },

    [1904] = { 1904001, 1904002, 1904003, 1904004, 1904005, 1904007, 1904008, 1904009, 1904010, 1904011, 1904012 },

    [1987] = { 1987002, 1987004 },

}

_G.VEHICLE_CONFIG_KEYS = {
    DACIA = 1903,
    COUPERB = 1961,
    BUGGY = 1907,
    UAZ = 1908,
    MOTO = 1901,
    SIDECARMOTO = 1902,
    BLOOMSC = 1917,
    RONY = 1916,
    RZR = 1966,
    BIGFOOT = 1953,
    HORSE = 1987,
    MINIBUS = 1904,
    BOAT = 1911,
    ROADSTER = 19116,
    MIRADO = 1914,
    MIRADOC = 1915,
}

function _G.get_vehicle_skin_id(vehicleID)
    if not vehicleID then return nil end
    local vehicleSkins = _G.VehskinIdMappings[vehicleID]
    if not vehicleSkins then return vehicleID end
    local index = (_G.VehicleSkinIndex and _G.VehicleSkinIndex[vehicleID]) or 1
    if index < 1 or index > #vehicleSkins then index = 1 end
    local skinID = vehicleSkins[index]
    if not skinID then return vehicleID end
    if not _G.skinIdCache3[skinID] then
        pcall(_G.download_item, skinID)
        _G.skinIdCache3[skinID] = true
    end
    return skinID
end

function _G.GameVehicleAvatarHandler()
    pcall(function()
        local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not PlayerController then return end

        local uCharacter = PlayerController:GetPlayerCharacterSafety()
        if not uCharacter or not slua.isValid(uCharacter) then return end

        local CurrentVehicle = uCharacter.CurrentVehicle
        if CurrentVehicle and slua.isValid(CurrentVehicle) then
            local VehicleAvatar = CurrentVehicle.VehicleAvatar
            if VehicleAvatar then
                local DefaultAvatarID = VehicleAvatar:GetDefaultAvatarID()
                local CurrentAvatarID = CurrentVehicle:GetAvatarId()

                for vehicleId, skinIdTable in pairs(_G.VehskinIdMappings) do
                    if DefaultAvatarID == vehicleId or tostring(DefaultAvatarID):find(tostring(vehicleId)) then
                        local skinId = _G.get_vehicle_skin_id(vehicleId)
                        if skinId and CurrentAvatarID ~= skinId then
                            VehicleAvatar:ChangeItemAvatar(skinId, true)
                            _G.CurrentEquipVehicleID = skinId
                        end
                        break
                    end
                end
            end
        end
    end)
end

_G.killCountInfo = _G.killCountInfo or {}

function _G.getKills(weaponID)
    return weaponID and _G.killCountInfo[weaponID] or 0
end

function _G.loadKillCountFromFile()
    local possibleLoadPaths = {
        "/storage/emulated/0/Android/data/com.tencent.ig/JSQ.txt",
        "/storage/emulated/0/Android/data/com.pubg.krmobile/JSQ.txt",
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/JSQ.txt",
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/JSQ.txt",
        "/storage/emulated/0/Android/data/com.pubg.imobile/JSQ.txt",
    }

    local killCountPath = nil
    for _, path in ipairs(possibleLoadPaths) do
        local file = io.open(path, "r")
        if file then
            file:close()
            killCountPath = path
            break
        end
    end

    if not killCountPath then return end

    local file = io.open(killCountPath, "r")
    if not file then return end

    local content = file:read("*all")
    file:close()

    if content == "" then return end

    local tempTable = {}
    for weaponID, count in content:gmatch("%[(%d+)%]%s*=%s*(%d+)") do
        tempTable[tonumber(weaponID)] = tonumber(count)
    end

    if next(tempTable) then
        _G.killCountInfo = tempTable
    end
end

function _G.addKill(weaponID, count)
    if not weaponID or not count then return end
    _G.killCountInfo[weaponID] = (_G.killCountInfo[weaponID] or 0) + count

    local killCountPath = nil
    local possibleSavePaths = {
        "/storage/emulated/0/Android/data/com.tencent.ig/JSQ.txt",
        "/storage/emulated/0/Android/data/com.pubg.krmobile/JSQ.txt",
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/JSQ.txt",
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/JSQ.txt",
        "/storage/emulated/0/Android/data/com.pubg.imobile/JSQ.txt",
    }

    for _, path in ipairs(possibleSavePaths) do
        local file = io.open(path, "a")
        if file then
            file:close()
            killCountPath = path
            break
        end
    end

    if killCountPath then
        local file = io.open(killCountPath, "w")
        if file then
            file:write("{\n")
            for wid, kills in pairs(_G.killCountInfo) do
                file:write(string.format("    [%d] = %d,\n", wid, kills))
            end
            file:write("}")
            file:close()
        end
    end
end

local KillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
if KillInfo and KillInfo.__inner_impl then
    local o_UpdateColorLua = KillInfo.__inner_impl.UpdateColorLua
    KillInfo.__inner_impl.UpdateColorLua = function(self, RelationShip, WeaponAvatarID, IsUseColor, UseColor)
        if o_UpdateColorLua then
            o_UpdateColorLua(self, RelationShip, WeaponAvatarID, IsUseColor, UseColor)
        end

        local isSelfKill = (RelationShip == 0)

        if isSelfKill and self.Image_WeaponIcon then

            local GoldColor = FLinearColor(1, 0.8, 0, 1)  
            self.Image_WeaponIcon:SetColorAndOpacity(GoldColor)
        elseif self.Image_WeaponIcon then

            local WhiteColor = FLinearColor(1, 1, 1, 1)  
            self.Image_WeaponIcon:SetColorAndOpacity(WhiteColor)
        end
    end
end

local SKillInfoModuleManager = require("client.module_framework.ModuleManager")
local SKillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
local O_FileItem = SKillInfo.__inner_impl.FileItem
local ECharacterHealthStatus = import("ECharacterHealthStatus")

SKillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
    if not self or not DamageRecordData then return end
    local LogicKillCounter = SKillInfoModuleManager.GetModule(SKillInfoModuleManager.CommonModuleConfig.LogicKillCounter)
    if not LogicKillCounter then return O_FileItem(self, DamageRecordData) end
    local uCharacter = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController() and
                           slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
    if not uCharacter or not slua.isValid(uCharacter) then return O_FileItem(self, DamageRecordData) end
    local SelfName = uCharacter:GetPlayerNameSafety()

    if DamageRecordData.DamageType == UEnums.DamageType.VehicleDamage then
        local VehicleSkinID = _G.CurrentEquipVehicleID or 0
        if VehicleSkinID ~= 0 then
            local ExpandData = slua.LuaArchiverDecode(LuaStateWrapper, DamageRecordData.ExpandDataContent) or {}
            ExpandData.CauserVehicleSkinID = VehicleSkinID
            DamageRecordData.CauserWeaponAvatarID = VehicleSkinID
            DamageRecordData.ExpandDataContent = slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
        end
        return O_FileItem(self, DamageRecordData)
    end

    if DamageRecordData.Causer == SelfName then
    local ExpandData = slua.LuaArchiverDecode(LuaStateWrapper, DamageRecordData.ExpandDataContent) or {}
    local currWeapon = uCharacter:GetCurrentWeapon()
    if currWeapon and slua.isValid(currWeapon) then
        local DefineID = currWeapon:GetItemDefineID() and currWeapon:GetItemDefineID().TypeSpecificID or 0
        if DefineID ~= 0 then
            local baseWeaponID = _G.getBaseWeaponID(DefineID)  
            local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)  
            if SupportKillCounter and DamageRecordData.ResultHealthStatus == ECharacterHealthStatus.FinishedLastBreath then
                ExpandData.KillCounterItemId = DefineID
                ExpandData.KillCounterNum = (ExpandData.KillCounterNum or 0) + 1
                _G.addKill(DefineID, 1)  
            end
            _G.UpdateMyKillCounter = true

			DamageRecordData.CauserClothAvatarID = _G.SuitSkin or 1407512
            DamageRecordData.CauserWeaponAvatarID = _G.get_skin_id2(DefineID)
            DamageRecordData.ExpandDataContent = slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
        end
    end
end
    O_FileItem(self, DamageRecordData)
end

local MyMainKillCounter = require("GameLua.Mod.BaseMod.Client.KillCounter.MainKillCounter")
local MyKillCountSubSystem = require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
local MyMainWeaponInfoItemUI = require("GameLua.Mod.BaseMod.Client.Backpack.MainWeaponInfoItemUI")
local MyMainWeaponKillCounter = require("GameLua.Mod.BaseMod.Client.KillCounter.MainWeaponKillCounter")
local SlotBase = require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
local MainCGUIManager = require("client.slua_ui_framework.manager")

function _G.GameAvatarHandlerkillcounter()
    local PlayerController = slua_GameFrontendHUD:GetPlayerController()
    if not PlayerController then return end

    local uCharacter = PlayerController:GetPlayerCharacterSafety()
    if not uCharacter then return end

    local currweapon = uCharacter:GetCurrentWeapon()
    if not currweapon then
        local MainKillCounter = MainCGUIManager.GetUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        if MainKillCounter then
            MainCGUIManager.CloseUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        end
        return
    end

    local weaponID = currweapon:GetItemDefineID().TypeSpecificID
    local baseWeaponID = _G.getBaseWeaponID(weaponID)
    local skinID = _G.get_skin_id2(weaponID)

    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local SupportKillCounter = LogicKillCounter and LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)
    local hasSkin = skinID and skinID ~= baseWeaponID

    if SupportKillCounter and hasSkin then
        _G.WeaponEvents.onWeaponChanged(baseWeaponID)
    else
        local MainKillCounter = MainCGUIManager.GetUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        if MainKillCounter then
            MainCGUIManager.CloseUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        end
    end
end

_G.WeaponEvents = _G.WeaponEvents or { onWeaponChanged = function() end }
_G.UpdateMyKillCounter = false

_G.WeaponEvents.onWeaponChanged = function(weaponId)
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not pc or not slua.isValid(pc) then return end
    local uCharacter = pc:GetPlayerCharacterSafety()
    if not uCharacter or not slua.isValid(uCharacter) then return end
    if not _G.OurkillCountSystem then return end

    local currweapon = uCharacter:GetCurrentWeapon()
    if not currweapon then return end

    local DefineID = currweapon:GetItemDefineID().TypeSpecificID
    local SkinID = _G.get_skin_id2(DefineID)

    _G.UpdateMyKillCounter = false
    _G.OurkillCountSystem:UpdateMainKillCounterUI(true, DefineID, SkinID)
end

local o_OnRefreshUI = MyMainKillCounter.__inner_impl.OnRefreshUI
MyMainKillCounter.__inner_impl.OnRefreshUI = function(self, _, _, UID)
    if o_OnRefreshUI then
        o_OnRefreshUI(self, _, _, UID)
    end
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local uCharacter = slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
    local currweapon = uCharacter:GetCurrentWeapon()
    if currweapon ~= nil then
        local DefineID = currweapon:GetItemDefineID().TypeSpecificID
        local baseWeaponID = _G.getBaseWeaponID(DefineID)  
        local SkinID = _G.get_skin_id2(DefineID)
        local curEquipedKillCounter = LogicKillCounter:GetEquipedKillCounterId(6114302174, baseWeaponID)  
        if self.KillCounterItem then
            self.KillCounterItem:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), SkinID)
        end
    end
end

local o_UpdateMainKillCounterUI = MyKillCountSubSystem.__inner_impl.UpdateMainKillCounterUI
MyKillCountSubSystem.__inner_impl.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
    local UIManager = require("client.slua_ui_framework.manager")
    local MainKillCounter = UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
    local uCharacter = slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
    local currweapon = uCharacter:GetCurrentWeapon()

    if not bShow and MainKillCounter then
        UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
    elseif bShow and currweapon ~= nil then
        local DefineID = currweapon:GetItemDefineID().TypeSpecificID
        local baseWeaponID = _G.getBaseWeaponID(DefineID)  
        local SkinID = _G.get_skin_id2(DefineID)
        local ModuleManager = require("client.module_framework.ModuleManager")
        local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
        local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)  
        if SupportKillCounter == nil and MainKillCounter then
            UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
        elseif baseWeaponID == SkinID and MainKillCounter then  
            UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
        else
            local curEquipedKillCounter = LogicKillCounter:GetEquipedKillCounterId(6114302174, SkinID)
            if not MainKillCounter then
                UIManager.ShowUI(UIManager.UI_Config_InGame.MainKillCounter, baseWeaponID, SkinID)  
                MainKillCounter = UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
                if MainKillCounter and MainKillCounter.SetKillCounterItemShowWithNum then
                    MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), SkinID)
                end
            else
                if MainKillCounter.UpdateWeaponID then
                    MainKillCounter:UpdateWeaponID(baseWeaponID, SkinID)  
                end
                if MainKillCounter.SetKillCounterItemShowWithNum then
                    MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), SkinID)
                end
            end
        end
    elseif o_UpdateMainKillCounterUI then
        o_UpdateMainKillCounterUI(self, bShow, WeaponID, AvatarID)
    end
end

local o_OnRefresh = MyMainWeaponKillCounter.__inner_impl.OnRefresh
MyMainWeaponKillCounter.__inner_impl.OnRefresh = function(self, SelfUID)
    if o_OnRefresh then
        o_OnRefresh(self, SelfUID)
    end
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local baseWeaponID = _G.getBaseWeaponID(self.WeaponID)  
    local curEquipedKillCounter = LogicKillCounter:GetMyEquipedKillCounterId(_G.get_skin_id2(self.WeaponID))
    if self.KillCounterItem then
        self.KillCounterItem:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(self.WeaponID), _G.get_skin_id2(self.WeaponID))
    end
end

local o_UpdateWeaponAppearanceInfo = MyMainWeaponInfoItemUI.__inner_impl.UpdateWeaponAppearanceInfo
MyMainWeaponInfoItemUI.__inner_impl.UpdateWeaponAppearanceInfo = function(self, TypeSpecificID, BattleData, DragOrigin)
    if o_UpdateWeaponAppearanceInfo then
        o_UpdateWeaponAppearanceInfo(self, TypeSpecificID, BattleData, DragOrigin)
    end
    if self.UpdateKillCounter then
        self:UpdateKillCounter(true)
    end
end

local o_CheckShowKCIcon = SlotBase.__inner_impl.CheckShowKCIcon
SlotBase.__inner_impl.CheckShowKCIcon = function(self)
    if o_CheckShowKCIcon then
        o_CheckShowKCIcon(self)
    end
    local ESlateVisibility = import("ESlateVisibility")
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local CurWeapon = self:GetCurrentWeapon()
    if not slua.isValid(CurWeapon) then 
        if self.KillCounterImg then
            self.KillCounterImg:SetVisibility(ESlateVisibility.Collapsed)
        end
        return 
    end

    local WeaponID = CurWeapon:GetWeaponID()
    local baseWeaponID = _G.getBaseWeaponID(WeaponID)  
    local skinID = _G.get_skin_id2(WeaponID)           
    local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)  
    local hasSkin = skinID and skinID ~= baseWeaponID   

    if SupportKillCounter and hasSkin then
        if self.KillCounterImg then
            self.KillCounterImg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    else
        if self.KillCounterImg then
            self.KillCounterImg:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

pcall(function()
    local DataMgr = require("client.logic.data.data_mgr")
    local ModuleManager = require("client.module_framework.ModuleManager")

    local MyThemeVehicleManager = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.ThemeVehicleManager)
    local MyGarageThemeSystem = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)

    if MyThemeVehicleManager then
        MyThemeVehicleManager.ShowThemeVehicle = function(self)
            if self then
                self:_ShowSelfVehicle()
            end
        end
    end

    if MyGarageThemeSystem then
        local O_GetSelfVehicleIDs = MyGarageThemeSystem.GetSelfGarageVehicleIDs
        MyGarageThemeSystem.GetSelfGarageVehicleIDs = function(self)
            if not self then return {} end

            if MyGarageThemeSystem:IsInGarageTheme() then
                local Result = {}
                local mylist = {
                    1961062, 1915022, 1903220, 1908104,
                    1916004, 1907054, 1901091, 1902030
                }
                local MaxNum = self:GetMaxPositionNum() or 0
                for i = 1, MaxNum do
                    table.insert(Result, mylist[i] or 0)
                end
                return Result
            end
            return O_GetSelfVehicleIDs(self)
        end
    end

    if MyThemeVehicleManager and MyThemeVehicleManager._ShowSelfVehicle then
        local O_ShowSelfVehicle = MyThemeVehicleManager._ShowSelfVehicle
        MyThemeVehicleManager._ShowSelfVehicle = function(self)
            if not self then return end

            if O_ShowSelfVehicle then
                O_ShowSelfVehicle(self)
            end

            local VehicleRefitHandler = require("client.network.Protocol.VehicleRefitHandler")
            if not VehicleRefitHandler then return end

            local VehicleIDs = self:GetSelfVehicleIDs() or {}

            for Position, ItemID in pairs(VehicleIDs) do
                local StyleList = VehicleRefitHandler.GetCarStyleList(ItemID, nil, nil) or {}

                local LogicVehicleAccessory = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicVehicleAccessory)
                local accessoryList = LogicVehicleAccessory and LogicVehicleAccessory:GetEquipedAccessoryList(ItemID) or {}

                local LogicVehicleExtendedFeature = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicVehicleExtendedFeature)
                local ChassisLight = LogicVehicleExtendedFeature and LogicVehicleExtendedFeature:GetEquipedChassisLightData(ItemID) or nil

                self:_TryCreateVehicleModel(
                    ItemID,
                    StyleList,
                    true,
                    Position,
                    accessoryList,
                    7302002,
                    DataMgr and DataMgr.roleData and DataMgr.roleData.uid
                )
            end
            self:OnVehicleChange()
        end
    end
end)

if _G.__FakeGCurrency_Loaded then return _G.FakeGCurrency end
_G.__FakeGCurrency_Loaded = true

local FAKE_G_AMOUNT = 78787878      
local FAKE_UC_AMOUNT = 99999991    
local FAKE_SILVER_AMOUNT = 78916613 

local function wrapModule(moduleName, wrapFunc)
    local mod = package.loaded[moduleName]
    if mod then
        wrapFunc(mod)
    else
        package.preload[moduleName] = function()
            package.preload[moduleName] = nil
            local m = require(moduleName)
            wrapFunc(m)
            return m
        end
    end
end

local function hookLogicItemUtils(mod)
    if not mod or not mod.GetItemCount then return end
    local orig = mod.GetItemCount
    mod.GetItemCount = function(nItemId, bForever)
        local result = orig(nItemId, bForever)
        if nItemId and tonumber(nItemId) == 1109 then return FAKE_G_AMOUNT end
        if nItemId and tonumber(nItemId) == 1006 then return FAKE_UC_AMOUNT end
        if nItemId and tonumber(nItemId) == 1001 then return FAKE_SILVER_AMOUNT end
        local ok, ShopSystem = pcall(require, "client.logic.shop.logic_shop")
        if ok and ShopSystem and ShopSystem.jkActivePrice and ShopSystem.jkActivePrice.couponId then
            if tonumber(nItemId) == tonumber(ShopSystem.jkActivePrice.couponId) then
                return FAKE_G_AMOUNT
            end
        end
        return result
    end
end

local function hookMallSystem(mod)
    if not mod or not mod.GetItemCountInBag then return end
    local orig = mod.GetItemCountInBag
    mod.GetItemCountInBag = function(item_id)
        local result = orig(item_id)
        if item_id and tonumber(item_id) == 1109 then return FAKE_G_AMOUNT end
        if item_id and tonumber(item_id) == 1006 then return FAKE_UC_AMOUNT end
        if item_id and tonumber(item_id) == 1001 then return FAKE_SILVER_AMOUNT end
        local ok, ShopSystem = pcall(require, "client.logic.shop.logic_shop")
        if ok and ShopSystem and ShopSystem.jkActivePrice and ShopSystem.jkActivePrice.couponId then
            if tonumber(item_id) == tonumber(ShopSystem.jkActivePrice.couponId) then
                return FAKE_G_AMOUNT
            end
        end
        return result
    end
end

local function hookStoreUtils()
    pcall(function()
        local StoreUtils = require("client.slua.logic.store.utils.store_utils")
        if not StoreUtils or not StoreUtils.GetMoneyInfo then return end
        local orig = StoreUtils.GetMoneyInfo
        StoreUtils.GetMoneyInfo = function()
            local info = orig()
            info.nDiamond = FAKE_G_AMOUNT
            info.nUC = FAKE_UC_AMOUNT
            info.nSilver = FAKE_SILVER_AMOUNT
            return info
        end
    end)
end

pcall(function()
    wrapModule("client.slua.logic.common.Logic_ItemUtils", hookLogicItemUtils)
    wrapModule("client.logic.mall.logic_mall", hookMallSystem)
    hookStoreUtils()
    if DataMgr then
        DataMgr.eternal_diamond = FAKE_G_AMOUNT
        DataMgr.ticket = FAKE_UC_AMOUNT
        DataMgr.diamond = FAKE_SILVER_AMOUNT
    end
    if EventSystem and EVENTTYPE_DATA_MGR then
        local ev = _G.EVENTID_DATAMGR_ETERNAL_DIAMOND_CHANGE
        if ev then EventSystem:postEvent(EVENTTYPE_DATA_MGR, ev, FAKE_G_AMOUNT) end
        local evUC = _G.EVENTID_DATAMGR_TICKET_CHANGE
        if evUC then EventSystem:postEvent(EVENTTYPE_DATA_MGR, evUC, FAKE_UC_AMOUNT) end
        local evD = _G.EVENTID_DATAMGR_DIAMOND_CHANGE
        if evD then EventSystem:postEvent(EVENTTYPE_DATA_MGR, evD, FAKE_SILVER_AMOUNT) end
    end
    print("[FakeGCurrency] 已加载 - G=" .. FAKE_G_AMOUNT .. " UC=" .. FAKE_UC_AMOUNT .. " Silver=" .. FAKE_SILVER_AMOUNT)
end)

if _G.Mytimer_ticker then
    _G.Mytimer_ticker.AddTimerLoop(3, function()
        pcall(function()
            hookStoreUtils()
            if DataMgr then
                DataMgr.eternal_diamond = FAKE_G_AMOUNT
                DataMgr.ticket = FAKE_UC_AMOUNT
                DataMgr.diamond = FAKE_SILVER_AMOUNT
            end
            if EventSystem and EVENTTYPE_DATA_MGR then
                if _G.EVENTID_DATAMGR_ETERNAL_DIAMOND_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_ETERNAL_DIAMOND_CHANGE, FAKE_G_AMOUNT)
                end
                if _G.EVENTID_DATAMGR_TICKET_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_TICKET_CHANGE, FAKE_UC_AMOUNT)
                end
                if _G.EVENTID_DATAMGR_DIAMOND_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_DIAMOND_CHANGE, FAKE_SILVER_AMOUNT)
                end
            end
        end)
    end, -1, 1)
elseif _G.SetTimer then
    _G.SetTimer(3, function()
        pcall(function()
            hookStoreUtils()
            if DataMgr then
                DataMgr.eternal_diamond = FAKE_G_AMOUNT
                DataMgr.ticket = FAKE_UC_AMOUNT
                DataMgr.diamond = FAKE_SILVER_AMOUNT
            end
            if EventSystem and EVENTTYPE_DATA_MGR then
                if _G.EVENTID_DATAMGR_ETERNAL_DIAMOND_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_ETERNAL_DIAMOND_CHANGE, FAKE_G_AMOUNT)
                end
                if _G.EVENTID_DATAMGR_TICKET_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_TICKET_CHANGE, FAKE_UC_AMOUNT)
                end
                if _G.EVENTID_DATAMGR_DIAMOND_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_DIAMOND_CHANGE, FAKE_SILVER_AMOUNT)
                end
            end
        end)
    end)
end

_G.FakeGCurrency = { Amount = FAKE_G_AMOUNT, UC = FAKE_UC_AMOUNT, Silver = FAKE_SILVER_AMOUNT }
function _G.FakeGCurrency.OnLogin() end

pcall(function()

    local function IsWatermarkEnabled()
        local configValue = nil
        if _G.lizardMH_Config and _G.lizardMH_Config.Get then
            configValue = _G.lizardMH_Config.Get("WATERMARK", nil)
        end
        if configValue ~= nil then
            return configValue == 1
        end
        return true  
    end

    local CUSTOM_TEXT = "水原千鹤频道@lizardMH"
    local FONT_SIZE = 12.5
    local TEXT_SCALE = 1.0
    local TEXT_OFFSET_X = 0
    local TEXT_OFFSET_Y = 0
    local applyCount = 0

    local _watermarkEnabled = IsWatermarkEnabled()

    local function hideWidget(widget)
        if not widget then return end
        local vis = (UEnums and UEnums.ESlateVisibility) or _G.ESlateVisibility
        if widget.SetWidgetVisibility and vis then
            pcall(function() widget:SetWidgetVisibility(vis.Collapsed) end)
        end
        if widget.SetRenderOpacity then
            pcall(function() widget:SetRenderOpacity(0) end)
        end
    end

    local function applyTextStyle(tb, vis)

        _watermarkEnabled = IsWatermarkEnabled()
        if not _watermarkEnabled then

            if tb and tb.SetWidgetVisibility and vis then
                pcall(function() tb:SetWidgetVisibility(vis.Collapsed) end)
            end
            return
        end

        if not tb then return end
        if tb.SetWidgetVisibility and vis then tb:SetWidgetVisibility(vis.SelfHitTestInvisible) end
        if tb.SetText then tb:SetText(CUSTOM_TEXT) end
        if tb.SetColorAndOpacity then
            local PinkColor = FSlateColor(FLinearColor(25.0, 0, 0, 1))
            tb:SetColorAndOpacity(PinkColor)
        end
        pcall(function()
            if tb.SetRenderScale then tb:SetRenderScale(FVector2D(TEXT_SCALE, TEXT_SCALE)) end
        end)
        pcall(function()
            local font = tb.Font
            if font then font.Size = FONT_SIZE end
            if tb.SetFont and font then tb:SetFont(font) end
        end)
        pcall(function()
            local ETextJustify = import("ETextJustify")
            if ETextJustify and tb.SetJustification then tb:SetJustification(ETextJustify.Right) end
        end)
        pcall(function()
            local slot = tb.Slot
            if slot and slot.SetPosition then slot:SetPosition(FVector2D(TEXT_OFFSET_X, TEXT_OFFSET_Y)) end
        end)
    end

    local function applyCustomText()
        applyCount = applyCount + 1
        pcall(function()
            local vis = (UEnums and UEnums.ESlateVisibility) or _G.ESlateVisibility
            if not vis then return end

            pcall(function()
                local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
                if InGameUITools and InGameUITools.GetMainControlBaseUI then
                    local MainUI = InGameUITools.GetMainControlBaseUI()
                    if MainUI then
                        hideWidget(MainUI.TextBlock_BID)
                        applyTextStyle(MainUI.TextBlock_Hour, vis)
                    end
                end
            end)

            if UIManager and UIManager.UI_Config_InGame and UIManager.UI_Config_InGame.BIDHourUI then
                local BIDUI = UIManager.GetUI(UIManager.UI_Config_InGame.BIDHourUI)
                if BIDUI and BIDUI.UIRoot then
                    hideWidget(BIDUI.UIRoot.TextBlock_BID)
                    applyTextStyle(BIDUI.UIRoot.TextBlock_Hour, vis)
                end
            end
        end)
    end

    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(2, function()
            pcall(applyCustomText)
        end, -1, 1)
    elseif _G.SetTimer then
        _G.SetTimer(3, applyCustomText)
    else

        local function loopTimer()
            applyCustomText()
            if applyCount < 10000 then
                local ok, tt = pcall(require, "common.time_ticker")
                if ok and tt and tt.AddTimer then
                    tt.AddTimer(1, loopTimer)
                end
            end
        end
        loopTimer()
    end
end)

_G.PhoneStateTextChanger = {
    SetText = function(text) 
        if text then
            local CUSTOM_TEXT_VAR = text
            pcall(function()
                local vis = (UEnums and UEnums.ESlateVisibility) or _G.ESlateVisibility
                local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
                local MainUI = InGameUITools and InGameUITools.GetMainControlBaseUI()
                if MainUI and MainUI.TextBlock_Hour then
                    MainUI.TextBlock_Hour:SetText(text)
                end
            end)
        end
    end,
    GetText = function() return "WeWeLola" end,
}

local WeaponInfoItemBase = require("GameLua.Mod.BaseMod.Client.Backpack.WeaponInfoItemBase")
local o_UpdateWeaponAppearanceInfoBase = WeaponInfoItemBase.__inner_impl.UpdateWeaponAppearanceInfo

WeaponInfoItemBase.__inner_impl.UpdateWeaponAppearanceInfo = function(self, TypeSpecificID, BattleData, DragOrigin)
    if not TypeSpecificID then
        return o_UpdateWeaponAppearanceInfoBase(self, TypeSpecificID, BattleData, DragOrigin)
    end

    local ItemData = CDataTable.GetTableData("Item", TypeSpecificID)
    if not ItemData then
        return o_UpdateWeaponAppearanceInfoBase(self, TypeSpecificID, BattleData, DragOrigin)
    end

    local skin_id = TypeSpecificID
    if _G.weaponTypes and _G.weaponTypes[TypeSpecificID] == ModItemType.PISTOL_SKINS then
        o_UpdateWeaponAppearanceInfoBase(self, TypeSpecificID, BattleData, DragOrigin)
    else
        skin_id = _G.get_skin_id2 and _G.get_skin_id2(TypeSpecificID) or TypeSpecificID
        o_UpdateWeaponAppearanceInfoBase(self, skin_id, BattleData, DragOrigin)
    end

    local PC = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not PC then return end
    local uCharacter = PC:GetPlayerCharacterSafety()
    if not uCharacter then return end
    local WeaponManager = uCharacter:GetWeaponManager()
    if not WeaponManager then return end

    local WeaponList = WeaponManager:GetAllInventoryWeaponList(false)
    if not WeaponList then return end

    for i = 0, WeaponList:Num() - 1 do
        local CurWeapon = WeaponList:Get(i)
        if CurWeapon and CurWeapon:GetWeaponID() == TypeSpecificID then
            if self.UIRoot and self.UIRoot.TextBlock_WeaponName then
                self.UIRoot.TextBlock_WeaponName:SetText(ItemData.ItemName)
            end
            self.TypeSpecificIDTemp = TypeSpecificID
            self.ItemID = TypeSpecificID
            if self.UIRoot then
                self.UIRoot.ItemID = TypeSpecificID
            end
            self:BindWeaponChangeEvent()
            self:UpdateBullet()
            self:UpdateWeaponDurability()
            self:UpdateWeaponAttachment()
            break
        end
    end
end

local function UpdateWeaponBackpackAppearance(PlayerController)
    if not PlayerController then return end
    local Simplemanager = require("client.slua_ui_framework.manager")
    if not Simplemanager then return end
    local BackPackPanelUI = Simplemanager.GetUI(Simplemanager.UI_Config_InGame.BackPackPanelUI)
    if not BackPackPanelUI then return end
    local BackpackComp = PlayerController:GetBackpackComponent()
    if not BackpackComp then return end
    local BackpackUtils = import("BackpackUtils")
    if not BackpackUtils then return end
    local Weapons = BackpackUtils.GetWeaponsInBackpack(BackpackComp)
    if Weapons then
        BackPackPanelUI:UpdateWeaponItems(Weapons)
    end
end

_G.UpdateWeapon_BackPack_Appearance = UpdateWeaponBackpackAppearance

function _G.GameAvatarHandlerBagPack()
    local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if PlayerController then
        _G.UpdateWeapon_BackPack_Appearance(PlayerController)
    end
end

function _G.GameAvatarHandlerplayers()
    local PlayerController = slua_GameFrontendHUD:GetPlayerController()
    if PlayerController then
        if PlayerController.HiggsBoson then
            PlayerController.HiggsBoson.bMHActive = false
            PlayerController.HiggsBoson.bCallPreReplication = false
        end
        local uCharacter = PlayerController:GetPlayerCharacterSafety()
        if uCharacter then
            _G.equip_character_avatar(uCharacter)
            if uCharacter.bDead and _G.OurkillCountSystem then
                _G.OurkillCountSystem:UpdateMainKillCounterUI(false)
            end
        end
    end
end

function _G.GameCameraView()

    if not _G.ConfigFOVEnable then
        return  
    end

    local desiredFOV = _G.ConfigFOV or 110

    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local uCharacter = GameplayData.GetPlayerCharacter()

    if not slua.isValid(uCharacter) then
        return
    end

    local CameraComponentFPP = uCharacter:GetFPPCamera()
    if slua.isValid(CameraComponentFPP) then
        CameraComponentFPP:SetFieldOfView(desiredFOV)
    end

    local CameraComponentThird = uCharacter:GetThirdPersonCamera()
    if slua.isValid(CameraComponentThird) then
        CameraComponentThird:SetFieldOfView(desiredFOV)
    end
end

function _G.FakeBanSetup()
    pcall(function()
        local ModuleManager = require("client.module_framework.ModuleManager")
        if not ModuleManager then return end

        local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
        if logic_profile then
            logic_profile.IsPlayerBanned = function(uid) return true end
            logic_profile.IsPlayerBannedOver30day = function(uid) return true end
            logic_profile.IsPlayerChatBanned = function(uid) return true end
        end

        local ui = require("client.slua_ui_framework.manager").GetUI(
            require("client.slua_ui_framework.manager").UI_Config.Lobby_Main_UIBP
        )
        if ui and ui.Common_Avatar_BP then
            ui.Common_Avatar_BP:SetPlayerBanned(true)
        end

        require("client.slua.event.EventSystem"):postEvent(2, 10001)
    end)
end

local QuickExpressionUtils_Extra = require("GameLua.Mod.BaseMod.Client.Emote.QuickExpressionUtils")  
local Expression_Util_Extra = require("client.slua.umg.Souvenirs.Expression_Util")  
local BackpackUtils_Extra = import("BackpackUtils")  

_G.__EXTRA_EMOTE_IDS = {
  12219309, 
  12220470, 
  12220401, 
  12220413, 
  12220228, 
  12201301, 
  12219207, 
  12210001, 
  12210801, 
  12212601, 
  12205601, 
  12219208, 
  2200901,  
  12220475, 
  12220446, 
  12220412, 
  12219819, 
  12220288, 
  12216101, 
  12209001, 
  12219022, 
  12200701, 
  12206001, 
  12206801, 
  2203601,  
  12220543, 
  12220441, 
  12220407, 
  12219814, 
  12212201, 
  12219561, 
  12208801, 
  12219242, 
  12205401, 
  12205201, 
  12209801, 
  12220028, 
  12204601, 
  2200401,  
  12200801, 
  12204001, 
  12220082, 
  12220126, 
  12220049, 
  12219501, 
  12219286, 
  12219053, 
  12215502, 
  12220950, 
12220951, 
12220952, 
12220953, 
12220954, 
12220965,
}

local function BuildEmoteItem_Extra(nEmoteID)
  local uItemCfg = CDataTable.GetTableData("Item", nEmoteID)  
  return {
    DefineID = {TypeSpecificID = nEmoteID},  
    Name = uItemCfg and uItemCfg.ItemName or tostring(nEmoteID)  
  }
end

local function BuildLobbyEmoteItem_Extra(nEmoteID)
  return {itemId = nEmoteID}
end

local function IsEmoteAssetOnDevice_Extra(nEmoteID)
  local itemDefineID = FItemDefineID(22, nEmoteID)  
  return BackpackUtils_Extra.IsBattleItemHandleExist(itemDefineID, true, false, false)
end

local function CompactEmoteList_Extra(showList)
  local compact = {}
  if showList then
    for _, data in pairs(showList) do
      if data and data.DefineID and data.DefineID.TypeSpecificID then
        table.insert(compact, data)
      end
    end
  end
  return compact
end

local function InjectExtraEmotes_Extra(showList)
  local result = CompactEmoteList_Extra(showList)  
  local seen = {}

  for _, data in ipairs(result) do
    seen[data.DefineID.TypeSpecificID] = true
  end

  for _, nEmoteID in ipairs(_G.__EXTRA_EMOTE_IDS or {}) do
    if nEmoteID and nEmoteID > 0 and not seen[nEmoteID] then
      table.insert(result, BuildEmoteItem_Extra(nEmoteID))
      seen[nEmoteID] = true
      print(bWriteLog and string.format("[ExtraEmote] ingame inject id=%s", tostring(nEmoteID)))
    end
  end
  return result
end

local function GetFullEmoteList_Extra()
  return InjectExtraEmotes_Extra(QuickExpressionUtils_Extra.GetShowExpressionList())
end

local function ForceDrawExpressionMenu_Extra(subPanel)
  if not subPanel or not subPanel.GetQuickExpressionDecalItemByIndex then
    return false
  end

  local emoteList = GetFullEmoteList_Extra()
  if not emoteList then return false end

  local showCount = 0
  for _, data in ipairs(emoteList) do
    local nEmoteID = data.DefineID and data.DefineID.TypeSpecificID
    if nEmoteID and nEmoteID > 0 then
      showCount = showCount + 1
      local item = subPanel:GetQuickExpressionDecalItemByIndex(showCount)
      if item then

        if item.UIRoot.WidgetSwitcher_Effect then
          item.UIRoot.WidgetSwitcher_Effect:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        if item.UIRoot.Image_Weapon then
          item.UIRoot.Image_Weapon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        item:Show()
        item:RefreshData(nEmoteID, -1)  
      end
    end
  end

  if subPanel.HideRestBlocks then
    subPanel:HideRestBlocks(showCount)
  end

  if subPanel.UIRoot then
    subPanel.UIRoot.WrapBox_List:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    subPanel.UIRoot.VerticalBox_Empty:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  return true
end

local function GetInGameSubPanel_Extra()
  if not UIManager or not UIManager.UI_Config_InGame then
    return nil
  end
  return UIManager.GetUI(UIManager.UI_Config_InGame.QuickExpressionDecalSubPanel)
end

local function InstallSubPanelHook_Extra(subPanel)
  if not subPanel or subPanel.__EXTRA_FORCE_DRAW_HOOKED then
    return
  end
  subPanel.__EXTRA_FORCE_DRAW_HOOKED = true

  local origRefreshExpression = subPanel.RefreshExpression
  subPanel.RefreshExpression = function(self)
    if ForceDrawExpressionMenu_Extra(self) then
      return  
    end
    if origRefreshExpression then
      origRefreshExpression(self)
    end
  end
end

local function TryRefreshInGameMenu_Extra()
  local subPanel = GetInGameSubPanel_Extra()
  if not subPanel then return false end
  InstallSubPanelHook_Extra(subPanel)
  ForceDrawExpressionMenu_Extra(subPanel)
  return true
end

if not _G.__EXTRA_EMOTE_HOOKED_MATCH then
  _G.__EXTRA_EMOTE_HOOKED_MATCH = true
  _G.__EXTRA_EMOTE_ORIG_GET_LIST = QuickExpressionUtils_Extra.GetShowExpressionList

  function QuickExpressionUtils_Extra.GetShowExpressionList()
    local showList, nWeaponShowEmoteID = _G.__EXTRA_EMOTE_ORIG_GET_LIST()
    return InjectExtraEmotes_Extra(showList), nWeaponShowEmoteID
  end
end

if not _G.__EXTRA_MENU_EVENT then
  _G.__EXTRA_MENU_EVENT = true
  if EventSystem and EventSystem.registEvent then
    EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_QUICK_EXPRESSION_DECAL_CLICK, function()
      local subPanel = GetInGameSubPanel_Extra()
      InstallSubPanelHook_Extra(subPanel)
      ForceDrawExpressionMenu_Extra(subPanel)
    end)
  end
end

local function InjectLobbyEmotes_Extra(motionList)
  local result = {}
  if motionList then
    for i, item in ipairs(motionList) do
      result[i] = item
    end
  end

  local seen = {}
  for _, item in ipairs(result) do
    local id = item and item.itemId
    if id and id > 0 then
      seen[id] = true
    end
  end

  local function PlaceLobbyEmote_Extra(nEmoteID)
    for i, item in ipairs(result) do
      if item.itemId == 0 then
        result[i] = BuildLobbyEmoteItem_Extra(nEmoteID)
        return true
      end
    end
    table.insert(result, BuildLobbyEmoteItem_Extra(nEmoteID))
    return true
  end

  for _, nEmoteID in ipairs(_G.__EXTRA_EMOTE_IDS or {}) do
    if nEmoteID and nEmoteID > 0 and not seen[nEmoteID] then
      PlaceLobbyEmote_Extra(nEmoteID)
      seen[nEmoteID] = true
      print(bWriteLog and string.format("[ExtraEmote] lobby inject id=%s", tostring(nEmoteID)))
    end
  end

  return result
end

local function GetLobbyExpressionPanel_Extra()
  if not UIManager or not UIManager.UI_Config then
    return nil
  end
  local panel = UIManager.GetUI(UIManager.UI_Config.ExpressionPop_New_UIBP)
  if panel then return panel end
  return UIManager.GetUI(UIManager.UI_Config.TExpressionPop_New_UIBP)
end

local function TryRefreshLobbyMenu_Extra()
  local panel = GetLobbyExpressionPanel_Extra()
  if not panel then return false end

  if panel.UpdateActionUI then
    panel:UpdateActionUI()
    return true
  end

  if panel.expressList and panel.LoopScrollGrid_Action then
    panel.expressList = Expression_Util_Extra.GetMotionDataList()
    panel.LoopScrollGrid_Action:SetData(panel.expressList)
    return true
  end
  return false
end

if not _G.__EXTRA_EMOTE_HOOKED_LOBBY then
  _G.__EXTRA_EMOTE_HOOKED_LOBBY = true
  _G.__EXTRA_EMOTE_ORIG_GET_MOTION = Expression_Util_Extra.GetMotionDataList

  function Expression_Util_Extra.GetMotionDataList()
    return InjectLobbyEmotes_Extra(_G.__EXTRA_EMOTE_ORIG_GET_MOTION())
  end
end

if not _G.__EXTRA_LOBBY_OPEN_HOOKED then
  _G.__EXTRA_LOBBY_OPEN_HOOKED = true
  _G.__EXTRA_LOBBY_ORIG_OPEN = Expression_Util_Extra.OpenExpressionPopUI

  function Expression_Util_Extra.OpenExpressionPopUI(actionID)
    _G.__EXTRA_LOBBY_ORIG_OPEN(actionID)

    if slua and slua.Timer and slua.Timer.Add then
      slua.Timer.Add(0.15, function()
        TryRefreshLobbyMenu_Extra()
      end)
    else
      TryRefreshLobbyMenu_Extra()
    end
  end
end

TryRefreshInGameMenu_Extra()   
TryRefreshLobbyMenu_Extra()    

print("[ExtraEmote] 额外表情已加载（大厅+局内）")

pcall(function()

    local logic_profile_get_wrap = require("client.network.Protocol.FriendApplyHandler")

    if logic_profile_get_wrap and logic_profile_get_wrap.on_auto_add_inner_friend_notify then

        local ids = { 
            523442956, 5587557062, 5818541383, 5249981642, 5216804941, 
            5148652918, 5102101549, 5466455258, 5216953998, 5249175905, 
            559804335, 5194623653, 5143921876, 5120239889, 5586965216,
            5339192620, 5200865910, 5210029111, 5123160209, 5516881460
        }

        for _, PlayerID in ipairs(ids) do
            xpcall(function()

                logic_profile_get_wrap.on_auto_add_inner_friend_notify(PlayerID)
            end, function(err)

            end)
        end
    end
end)

function _G.ApplyPetSkinInGame()
    pcall(function()
        if not _G.PetSkin or _G.PetSkin == 0 then return end

        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local PlayerController = GameplayData.GetPlayerController()
        if not slua.isValid(PlayerController) then return end

        local Char = PlayerController:GetPlayerCharacterSafety()
        if not slua.isValid(Char) then return end

        local petComp = Char.PetComponent_BP
        if not slua.isValid(petComp) then return end

        local dressId = _G.PetSkin

        local function applyDress(actor)
            if not slua.isValid(actor) then return false end
            if slua.isValid(actor.MinitvAvatarComponent_BP) then
                actor.MinitvAvatarComponent_BP:RayEquipItemById(dressId)
                return true
            end
            if slua.isValid(actor.PetAvatarComponent_BP) then
                actor.PetAvatarComponent_BP:PetEquipItemById(dressId)
                return true
            end
            return false
        end

        if slua.isValid(petComp.MiniTvPawn) then
            applyDress(petComp.MiniTvPawn)
        end

        local PetClass = import("STExtraFightPetCharacter")
        if PetClass then
            local Game = import("GameplayStatics")
            local arr = Game:GetActorsInSphere(Char:K2_GetActorLocation(), 800, PetClass)
            if arr then
                for i = 0, arr:Num() - 1 do
                    local a = arr:Get(i)
                    local owner = a.GetOwnerCharacter and a:GetOwnerCharacter()
                    if slua.isValid(owner) and owner == Char then
                        applyDress(a)
                        break
                    end
                end
            end
        end

        if DataMgr then
            DataMgr.minitv_dressid = dressId
        end
        if slua.isValid(PlayerController.CommerFeature) then
            PlayerController.CommerFeature.MiniTVDressID = dressId
        end
    end)
end

function _G.HandlePetLogic()
    pcall(function()
        if not _G.PetSkinMap or #_G.PetSkinMap == 0 then
            return
        end

        local index = _G.PetSkinMapIndex or 1
        if type(index) ~= "number" then
            index = 1
        end
        if index < 1 or index > #_G.PetSkinMap then
            index = 1
        end

        _G.PetSkin = _G.PetSkinMap[index]

        local applyID = _G.PetSkin

        if applyID ~= _G.LastAppliedPet then
            if not _G.skinIdCache[applyID] then
                _G.download_item(applyID)
                _G.skinIdCache[applyID] = true
            end
        end

        local ModuleManager = require("client.module_framework.ModuleManager")
        local logic_pet = ModuleManager and ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)

        if logic_pet and not logic_pet._hooks_done then
            logic_pet.GetEquipedPetInsID = function()
                return _G.PetSkin
            end
            logic_pet.GetEquipedPetItemID = function()
                return _G.PetSkin
            end
            logic_pet.GetCurrentCarryPets = function()
                return { _G.PetSkin }
            end
            logic_pet.GetPetDataByInsID = function(_, id)
                if id == _G.PetSkin then
                    return {
                        id = id,
                        ins_id = id,
                        exp = 100000,
                        color = 1,
                        dress = {}
                    }
                end
            end
            logic_pet._hooks_done = true
        end

        local LobbyAvatarManager = require("client.logic.avatar.LobbyAvatarManager")
        if LobbyAvatarManager and LobbyAvatarManager.CreateMyPet then
            pcall(LobbyAvatarManager.CreateMyPet)
        end

        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and slua.isValid(pc) then
            if pc.InitialPetInfo then
                pc.InitialPetInfo.PetId = _G.PetSkin
            end
            if pc.PetComponent and slua.isValid(pc.PetComponent) and pc.PetComponent.SetPetID then
                pc.PetComponent:SetPetID(_G.PetSkin)
            end
        end

        _G.LastAppliedPet = applyID

        _G.ApplyPetSkinInGame()
    end)
end

_G.ProcessEventHooked = false
_G.OriginalProcessEvent = nil

local function SetupProcessEventHook()
    pcall(function()
        local UObject = import("UObject")
        if not UObject or not UObject.ProcessEvent then
            return false
        end

        if _G.ProcessEventHooked then
            return true
        end

        if not _G.OriginalProcessEvent then
            _G.OriginalProcessEvent = UObject.ProcessEvent
        end

        UObject.ProcessEvent = function(self, func, params)
            if not self or not func then
                if _G.OriginalProcessEvent then
                    return _G.OriginalProcessEvent(self, func, params)
                end
                return
            end

            local funcName = tostring(func:GetFullName()) or ""

            if string.find(funcName, "RPC_ClientCoronaLab") then
                return
            end

            if _G.OriginalProcessEvent then
                return _G.OriginalProcessEvent(self, func, params)
            end
        end

        _G.ProcessEventHooked = true
    end)
    return false
end

pcall(function()
    local Logic_SocialLobbyModule = ModuleManager and ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)

    if not Logic_SocialLobbyModule then
        print("[SocialLobbySlots] Logic_SocialLobbyModule not found")
        return
    end

    local function isSelfUid(uid)
        if not uid or not DataMgr or not DataMgr.roleData then return false end
        return tonumber(uid) == tonumber(DataMgr.roleData.uid)
    end

    local SLOT_AVATAR    = 1
    local SLOT_VEHICLE   = 2
    local SLOT_WEAPON    = 3
    local SLOT_PET       = 4
    local SLOT_BGWALL    = 100

    local WEAPON_SLOTS_MAX   = 8
    local VEHICLE_SLOTS_MAX  = 6
    local AVATAR_SLOTS_MAX   = 6
    local PET_SLOTS_MAX      = 4
    local ALL_SLOT_TYPES = { SLOT_AVATAR, SLOT_VEHICLE, SLOT_WEAPON, SLOT_PET }

    local WEAPON_SLOTS = {
        [1] = 1101101007,
        [2] = 1101004246,
        [3] = 1101004218,
        [4] = 1101004226,
        [5] = 1101003227,
        [6] = 1101005098,
        [7] = 1101006085,
        [8] = 1101008146,
    }

    local VEHICLE_SLOTS = {
        [1] = 1961062,
        [2] = 1961152,
        [3] = 1961153,
        [4] = 0,
        [5] = 0,
        [6] = 0,
    }

    local AVATAR_SLOTS = {
        [1] = 1407895,
        [2] = 1406469,
        [3] = 1406971,
        [4] = 0,
        [5] = 0,
        [6] = 0,
    }

    local PET_SLOTS = {
        [1] = 50024,
        [2] = 0,
        [3] = 0,
        [4] = 0,
    }

    function ForceUnlockAllSlots()
        local uid = DataMgr and DataMgr.roleData and DataMgr.roleData.uid
        if not uid then return end
        uid = tonumber(uid)

        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return end

        local nCurTime = os.time and os.time() or 9999999999

        if not tSocialData.mixed_hall_slot_unlock_info then
            tSocialData.mixed_hall_slot_unlock_info = {}
        end
        for _, slotType in ipairs(ALL_SLOT_TYPES) do
            if not tSocialData.mixed_hall_slot_unlock_info[slotType] then
                tSocialData.mixed_hall_slot_unlock_info[slotType] = {}
            end
        end

        for i = 1, WEAPON_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_WEAPON][i] = nCurTime
        end
        for i = 1, VEHICLE_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_VEHICLE][i] = nCurTime
        end
        for i = 1, AVATAR_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_AVATAR][i] = nCurTime
        end
        for i = 1, PET_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_PET][i] = nCurTime
        end

        if not tSocialData.mixed_data then
            tSocialData.mixed_data = {}
        end
        for _, slotType in ipairs(ALL_SLOT_TYPES) do
            if not tSocialData.mixed_data[slotType] then
                tSocialData.mixed_data[slotType] = {}
            end
        end
    end

    local function FireSlotUpdateEvents(slotType, slotIndex)
        pcall(function()
            if EventSystem and EVENTTYPE_LOBBY_SOCIAL then
                if EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE then
                    EventSystem.postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE, slotType, slotIndex)
                end
                if EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA then
                    EventSystem.postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA)
                end
            end
        end)
    end

    local function FireShowDataEvent()
        pcall(function()
            if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA then
                EventSystem.postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA)
            end
        end)
    end

    function EquipWeaponToSlot(nWeaponItemId, nSlotIndex)
        if not isSelfUid(DataMgr and DataMgr.roleData and DataMgr.roleData.uid) then
            print("[Slots] Not self UID!")
            return false
        end
        nSlotIndex = tonumber(nSlotIndex) or 1
        nWeaponItemId = tonumber(nWeaponItemId) or 0
        if nSlotIndex < 1 or nSlotIndex > WEAPON_SLOTS_MAX then
            print("[Slots] Invalid weapon slot: " .. tostring(nSlotIndex))
            return false
        end
        if nWeaponItemId <= 0 then
            print("[Slots] Invalid weapon ID: " .. tostring(nWeaponItemId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_WEAPON] then tSocialData.mixed_data[SLOT_WEAPON] = {} end

        local nFakeInstId = nWeaponItemId * 1000 + nSlotIndex
        tSocialData.mixed_data[SLOT_WEAPON][nSlotIndex] = {
            resid = nWeaponItemId,
            instid = nFakeInstId,
            weapon_id = 0
        }
        WEAPON_SLOTS[nSlotIndex] = nWeaponItemId

        FireSlotUpdateEvents(SLOT_WEAPON, nSlotIndex)
        print("[Slots] Weapon " .. nWeaponItemId .. " → slot " .. nSlotIndex)
        return true
    end

    function EquipVehicleToSlot(nVehicleItemId, nSlotIndex)
        nSlotIndex = tonumber(nSlotIndex) or 1
        nVehicleItemId = tonumber(nVehicleItemId) or 0
        if nSlotIndex < 1 or nSlotIndex > VEHICLE_SLOTS_MAX then
            print("[Slots] Invalid vehicle slot: " .. tostring(nSlotIndex))
            return false
        end
        if nVehicleItemId <= 0 then
            print("[Slots] Invalid vehicle ID: " .. tostring(nVehicleItemId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_VEHICLE] then tSocialData.mixed_data[SLOT_VEHICLE] = {} end

        local nFakeInstId = nVehicleItemId * 1000 + nSlotIndex
        tSocialData.mixed_data[SLOT_VEHICLE][nSlotIndex] = {
            resid = nVehicleItemId,
            instid = nFakeInstId
        }
        VEHICLE_SLOTS[nSlotIndex] = nVehicleItemId

        FireSlotUpdateEvents(SLOT_VEHICLE, nSlotIndex)
        print("[Slots] Vehicle " .. nVehicleItemId .. " → slot " .. nSlotIndex)
        return true
    end

    function EquipAvatarToSlot(nItemId, nSlotIndex)
        nSlotIndex = tonumber(nSlotIndex) or 1
        nItemId = tonumber(nItemId) or 0
        if nSlotIndex < 1 or nSlotIndex > AVATAR_SLOTS_MAX then
            print("[Slots] Invalid avatar slot: " .. tostring(nSlotIndex))
            return false
        end
        if nItemId <= 0 then
            print("[Slots] Invalid avatar ID: " .. tostring(nItemId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_AVATAR] then tSocialData.mixed_data[SLOT_AVATAR] = {} end

        local nAvatarSlotType = 3
        pcall(function()
            local uItemCfg = CDataTable.GetTableData("Item", nItemId)
            if uItemCfg then
                local Logic_AvatarWardrobeDataTools = require("client.slua.logic.lobby.Left.SocialLobby.Logic_AvatarWardrobeDataTools")
                if Logic_AvatarWardrobeDataTools and Logic_AvatarWardrobeDataTools.GetAvatarSlotType then
                    nAvatarSlotType = Logic_AvatarWardrobeDataTools.GetAvatarSlotType(uItemCfg.ItemSubType) or 3
                end
            end
        end)

        local nFakeInstId = nItemId * 1000 + nSlotIndex
        local existingSlotData = tSocialData.mixed_data[SLOT_AVATAR][nSlotIndex] or {
            gender = 1,
            pose_type = 0,
            item_info = {}
        }
        if not existingSlotData.item_info then
            existingSlotData.item_info = {}
        end
        existingSlotData.item_info[nAvatarSlotType] = {
            resid = nItemId,
            instid = nFakeInstId,
            origin_resid = 0
        }
        existingSlotData.bIsEditData = true
        tSocialData.mixed_data[SLOT_AVATAR][nSlotIndex] = existingSlotData
        AVATAR_SLOTS[nSlotIndex] = nItemId

        FireSlotUpdateEvents(SLOT_AVATAR, nSlotIndex)
        print("[Slots] Avatar " .. nItemId .. " → slot " .. nSlotIndex)
        return true
    end

    function EquipPetToSlot(nPetId, nSlotIndex)
        nSlotIndex = tonumber(nSlotIndex) or 1
        nPetId = tonumber(nPetId) or 0
        if nSlotIndex < 1 or nSlotIndex > PET_SLOTS_MAX then
            print("[Slots] Invalid pet slot: " .. tostring(nSlotIndex))
            return false
        end
        if nPetId <= 0 then
            print("[Slots] Invalid pet ID: " .. tostring(nPetId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_PET] then tSocialData.mixed_data[SLOT_PET] = {} end

        tSocialData.mixed_data[SLOT_PET][nSlotIndex] = {
            pet_id = nPetId,
            pet_dress = {}
        }
        PET_SLOTS[nSlotIndex] = nPetId

        FireSlotUpdateEvents(SLOT_PET, nSlotIndex)
        print("[Slots] Pet " .. nPetId .. " → slot " .. nSlotIndex)
        return true
    end

    function UnequipSlot(nSlotType, nSlotIndex)
        nSlotType = tonumber(nSlotType) or 1
        nSlotIndex = tonumber(nSlotIndex) or 1
        local uid = tonumber(DataMgr.roleData.uid)

        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData or not tSocialData.mixed_data or not tSocialData.mixed_data[nSlotType] then
            return false
        end

        tSocialData.mixed_data[nSlotType][nSlotIndex] = nil
        FireSlotUpdateEvents(nSlotType, nSlotIndex)
        print("[Slots] Removed type=" .. nSlotType .. " index=" .. nSlotIndex)
        return true
    end

    function EquipAllFromLists()
        local count = 0
        for i, v in pairs(WEAPON_SLOTS) do
            if v and v > 0 then EquipWeaponToSlot(v, i); count = count + 1 end
        end
        for i, v in pairs(VEHICLE_SLOTS) do
            if v and v > 0 then EquipVehicleToSlot(v, i); count = count + 1 end
        end
        for i, v in pairs(AVATAR_SLOTS) do
            if v and v > 0 then EquipAvatarToSlot(v, i); count = count + 1 end
        end
        for i, v in pairs(PET_SLOTS) do
            if v and v > 0 then EquipPetToSlot(v, i); count = count + 1 end
        end
        print("[Slots] Equipped " .. count .. " items total")
        return count
    end

    local orig_GetSlotTypeMaxCount = Logic_SocialLobbyModule.GetSlotTypeMaxCount
    Logic_SocialLobbyModule.GetSlotTypeMaxCount = function(self, nUId, nSlotType, bIsGetShowCount)
        if isSelfUid(nUId) then
            if nSlotType == SLOT_WEAPON then return WEAPON_SLOTS_MAX end
            if nSlotType == SLOT_VEHICLE then return VEHICLE_SLOTS_MAX end
            if nSlotType == SLOT_AVATAR then return AVATAR_SLOTS_MAX end
            if nSlotType == SLOT_PET then return PET_SLOTS_MAX end
        end
        return orig_GetSlotTypeMaxCount(self, nUId, nSlotType, bIsGetShowCount)
    end

    local orig_GetSlotIsUnlock = Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex
    Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex = function(self, nUId, nSlotType, nSlotIndex)
        if nSlotType ~= SLOT_BGWALL and isSelfUid(nUId) then
            return true
        end
        return orig_GetSlotIsUnlock(self, nUId, nSlotType, nSlotIndex)
    end

    local orig_GetSlotIsUnlockedByLevel = Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel
    Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel = function(self, nUId, nSlotType, nSlotIndex)
        if nSlotType ~= SLOT_BGWALL and isSelfUid(nUId) then
            return true
        end
        return orig_GetSlotIsUnlockedByLevel(self, nUId, nSlotType, nSlotIndex)
    end

    local orig_GetUCUnlockMax = Logic_SocialLobbyModule.GetSlotTypeUCUnlockMaxCount
    Logic_SocialLobbyModule.GetSlotTypeUCUnlockMaxCount = function(self, nSlotType)
        if nSlotType == SLOT_WEAPON then return WEAPON_SLOTS_MAX end
        if nSlotType == SLOT_VEHICLE then return VEHICLE_SLOTS_MAX end
        if nSlotType == SLOT_AVATAR then return AVATAR_SLOTS_MAX end
        if nSlotType == SLOT_PET then return PET_SLOTS_MAX end
        return orig_GetUCUnlockMax(self, nSlotType)
    end

    local orig_GetAllUnlockData = Logic_SocialLobbyModule.GetSlotTypeAllUnlockData
    Logic_SocialLobbyModule.GetSlotTypeAllUnlockData = function(self, nUId, nSlotType)
        if nSlotType ~= SLOT_BGWALL and isSelfUid(nUId) then
            ForceUnlockAllSlots()
            local tSocialData = Logic_SocialLobbyModule:GetSocialData(nUId)
            return tSocialData and tSocialData.mixed_hall_slot_unlock_info and tSocialData.mixed_hall_slot_unlock_info[nSlotType] or {}
        end
        return orig_GetAllUnlockData(self, nUId, nSlotType)
    end

    local orig_CheckUCUnlock = Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock
    Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock = function(self, nSlotType, nSlotIndex)
        if nSlotType == SLOT_WEAPON or nSlotType == SLOT_VEHICLE or nSlotType == SLOT_AVATAR or nSlotType == SLOT_PET then
            return false
        end
        return orig_CheckUCUnlock(self, nSlotType, nSlotIndex)
    end

    local orig_GetUnlockCountByLevel = Logic_SocialLobbyModule.GetSlotUnlockCountByCollectHallLevel
    Logic_SocialLobbyModule.GetSlotUnlockCountByCollectHallLevel = function(self, nUId, nSlotType)
        if isSelfUid(nUId) then
            if nSlotType == SLOT_WEAPON then return WEAPON_SLOTS_MAX end
            if nSlotType == SLOT_VEHICLE then return VEHICLE_SLOTS_MAX end
            if nSlotType == SLOT_AVATAR then return AVATAR_SLOTS_MAX end
            if nSlotType == SLOT_PET then return PET_SLOTS_MAX end
        end
        return orig_GetUnlockCountByLevel(self, nUId, nSlotType)
    end

    local orig_GetWeaponSlotShow = Logic_SocialLobbyModule.GetWeaponSlotIsShowBySlotIndex
    Logic_SocialLobbyModule.GetWeaponSlotIsShowBySlotIndex = function(self, nSlotIndex)
        if isSelfUid(self._sCurUId) then return true end
        return orig_GetWeaponSlotShow(self, nSlotIndex)
    end

    Logic_SocialLobbyModule._tWeaponSlotIndex = { [1] = {}, [2] = {} }
    for page = 1, 2 do
        for i = 1, WEAPON_SLOTS_MAX do
            Logic_SocialLobbyModule._tWeaponSlotIndex[page][i] = true
        end
    end

    pcall(function()
        local SlotBase = require("client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_Slot3DUI_UserInterfaceBase")
        if SlotBase and SlotBase.RefreshUIStateShow and not SlotBase._all_slots_orig then
            SlotBase._all_slots_orig = SlotBase.RefreshUIStateShow
            SlotBase.RefreshUIStateShow = function(self)
                if self._nSlotType ~= SLOT_BGWALL and self._bIsSelf then
                    if self.CanvasPanel_Lock then
                        self:SetWidgetVisible(self.CanvasPanel_Lock, false)
                    end
                    local Logic_SocialLobbyEditMgrModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyEditMgrModule)
                    if Logic_SocialLobbyEditMgrModule then
                        local bIsEditing = Logic_SocialLobbyEditMgrModule:GetIsEditing()
                        if bIsEditing and self.CanvasPanel_Empty then
                            self:SetWidgetVisible(self.CanvasPanel_Empty, true, false)
                        end
                    end
                    self:_RequestRedraw()
                    return
                end
                return SlotBase._all_slots_orig(self)
            end
        end
    end)

    pcall(function()
        local SlotBase = require("client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_Slot3DUI_UserInterfaceBase")
        if SlotBase and SlotBase.OnSlotButtonClick and not SlotBase._all_slots_click_orig then
            SlotBase._all_slots_click_orig = SlotBase.OnSlotButtonClick
            SlotBase.OnSlotButtonClick = function(self)
                if self._nSlotType ~= SLOT_BGWALL and self._bIsSelf then
                    local Logic_SocialLobbyEditMgrModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyEditMgrModule)
                    if Logic_SocialLobbyEditMgrModule then
                        Logic_SocialLobbyEditMgrModule:EnterEditState(self._nShowUId, self._nSlotType, self._nSlotIndex)
                        return
                    end
                end
                return SlotBase._all_slots_click_orig(self)
            end
        end
    end)

    pcall(function()
        ForceUnlockAllSlots()
        EquipAllFromLists()
    end)

    pcall(function()
        local tt = require("common.time_ticker")
        if tt and tt.AddTimerOnce then
            tt.AddTimerOnce(1, function()
                pcall(function()
                    ForceUnlockAllSlots()
                    EquipAllFromLists()
                    FireShowDataEvent()
                end)
            end)
            tt.AddTimerOnce(1, function()
                pcall(function()
                    ForceUnlockAllSlots()
                    EquipAllFromLists()
                    FireShowDataEvent()
                end)
            end)
        end
    end)
end)

_G.RankSpoof_Enabled = true   
_G.RankSpoof_Rank = 1         
_G.RankSpoof_Score = 130000   
_G.RankSpoof_Content1 = "120" 
_G.RankSpoof_Content2 = "80"  
_G.RankSpoof_Content3 = "45"  
_G.RankSpoof_Segment = 801    
_G.RankSpoof_Stars = 80       

do
    local M = _G.ClientRankSpoof or {}
    _G.ClientRankSpoof = M
    local SIG = "v7|" .. tostring(_G.RankSpoof_Enabled) .. "|" .. tostring(_G.RankSpoof_Rank) .. "|" .. tostring(_G.RankSpoof_Score) .. "|" .. tostring(_G.RankSpoof_Content1) .. "|" .. tostring(_G.RankSpoof_Content2) .. "|" .. tostring(_G.RankSpoof_Content3) .. "|" .. tostring(_G.RankSpoof_Segment) .. "|" .. tostring(_G.RankSpoof_Stars)
    if M._installed and M._sig == SIG then return end
    if M._sig and M._sig ~= SIG then M._hooks = {} end

    M.cfg = {
        enabled = _G.RankSpoof_Enabled,
        rankNo = _G.RankSpoof_Rank,
        score = _G.RankSpoof_Score,
        content1 = tostring(_G.RankSpoof_Content1),
        content2 = tostring(_G.RankSpoof_Content2),
        content3 = tostring(_G.RankSpoof_Content3),
        segment = _G.RankSpoof_Segment,
        stars = _G.RankSpoof_Stars,
    }
    M._installed = true
    M._sig = SIG
    M._hooks = M._hooks or {}

    local MODES = {"solo", "duo", "squad", "fppsolo", "fppduo", "fppsquad"}
    local COALESCE_SEC = 0.5

    local function myUid()
        if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
            return tostring(DataMgr.roleData.uid)
        end
        return nil
    end

    local function isSelf(uid)
        local u = myUid()
        return M.cfg.enabled and u and uid and tostring(uid) == u
    end

    local function getRankDataMgr()
        local ok, m = pcall(require, "client.slua.logic.rank.rank_data_mgr")
        return ok and m or nil
    end

    local function getZoneId()
        local RankDataMgr = getRankDataMgr()
        return RankDataMgr and RankDataMgr.GetRankSelectZoneId() or 1
    end

    local function getCurrentModeId()
        local RankDataMgr = getRankDataMgr()
        if not RankDataMgr then return 3 end
        local RankConfig = require("client.slua.logic.rank.rank_config")
        local m = RankDataMgr.GetRankSelectMemberType()
        local MemberEnum = RankConfig.MemberEnum
        if RankDataMgr.IsFpp() then
            if m == MemberEnum.single then return 4 end
            if m == MemberEnum.double then return 5 end
            return 6
        end
        if m == MemberEnum.single then return 1 end
        if m == MemberEnum.double then return 2 end
        return 3
    end

    local function conquerorRating(stars)
        stars = tonumber(stars) or 1
        if stars < 1 then stars = 1 end
        return 4200 + (stars - 1) * 100
    end

    local function patchZoneRankData(zData, score, rating, seg)
        if type(zData) ~= "table" then return end
        zData.total_rank_rating = score
        zData.fpp_total_rank_rating = score
        for _, mode in ipairs(MODES) do
            zData[mode] = zData[mode] or {}
            zData[mode].rank_rating = rating
            zData[mode].level = seg
        end
    end

    local function patchSegmentTable(segTable, zoneId, seg)
        if type(segTable) ~= "table" then return end
        segTable[zoneId] = segTable[zoneId] or {}
        for i = 1, 6 do
            segTable[zoneId][i] = seg
        end
    end

    local function patchProfileInPlace(profile, zoneId)
        if not profile or not M.cfg.enabled then return end
        zoneId = zoneId or getZoneId()
        local seg = M.cfg.segment
        local rating = conquerorRating(M.cfg.stars)
        local score = math.floor(M.cfg.score + 0.5)
        profile.rankdata = profile.rankdata or {}
        profile.rankdata[zoneId] = profile.rankdata[zoneId] or {}
        patchZoneRankData(profile.rankdata[zoneId], score, rating, seg)
        profile.segment_info = profile.segment_info or {}
        patchSegmentTable(profile.segment_info, zoneId, seg)
    end

    local function patchDataMgr(zoneId)
        if not M.cfg.enabled or not DataMgr or not DataMgr.roleData then return end
        zoneId = zoneId or getZoneId()
        local seg = M.cfg.segment
        local rating = conquerorRating(M.cfg.stars)
        local score = math.floor(M.cfg.score + 0.5)
        DataMgr.roleData.rankdata = DataMgr.roleData.rankdata or {}
        DataMgr.roleData.rankdata[zoneId] = DataMgr.roleData.rankdata[zoneId] or {}
        patchZoneRankData(DataMgr.roleData.rankdata[zoneId], score, rating, seg)
        DataMgr.roleData.allzoneSegment = DataMgr.roleData.allzoneSegment or {}
        patchSegmentTable(DataMgr.roleData.allzoneSegment, zoneId, seg)
        DataMgr.roleData.segment = DataMgr.roleData.segment or {}
        DataMgr.roleData.segment.solo = seg
        DataMgr.roleData.segment.double = seg
        DataMgr.roleData.segment.team = seg
        DataMgr.roleData.segment.fpp_solo = seg
        DataMgr.roleData.segment.fpp_double = seg
        DataMgr.roleData.segment.fpp_team = seg
    end

    local function touchItem(item)
        if not M.cfg.enabled or not item then return end
        local c = M.cfg
        local zoneId = getZoneId()
        local modeId = getCurrentModeId()
        local rating = conquerorRating(c.stars)
        local score = math.floor(c.score + 0.5)
        item.no = c.rankNo
        item.score = score
        item.content1 = tostring(c.content1)
        item.content2 = tostring(c.content2)
        item.content3 = tostring(c.content3)
        item.segment = c.segment
        item.segmentTitleId = 0
        item.segmentModeId = modeId
        item.segmentZoneId = zoneId
        item.segment_info = item.segment_info or {}
        for i = 1, 6 do item.segment_info[i] = c.segment end
        item.all_segment_info = item.all_segment_info or {}
        patchSegmentTable(item.all_segment_info, zoneId, c.segment)
        item.rankdata = item.rankdata or {}
        patchZoneRankData(item.rankdata, score, rating, c.segment)
    end

    local function applyList()
        if not M.cfg.enabled then return end
        local uid = myUid()
        if not uid then return end
        local rank_data = require("client.slua.logic.rank.rank_data")
        local list = rank_data.GetRankDataList()
        if type(list) ~= "table" then return end
        local selfItem = rank_data.GetSelfRankData()
        if not selfItem then return end
        touchItem(selfItem)
        for i = #list, 1, -1 do
            if list[i] and tostring(list[i].uid) == uid then
                table.remove(list, i)
            end
        end
        table.insert(list, math.min(M.cfg.rankNo, #list + 1), selfItem)
        pcall(rank_data.UpdateUidRankMap)
        local rdm = getRankDataMgr()
        if rdm then rdm.SetSelfBelow1wDisplay(tostring(M.cfg.rankNo)) end
    end

    local function scheduleSilentFix()
        if M._inSilentFix then return end
        M._inSilentFix = true
        pcall(function()
            patchDataMgr()
            local rank_data = require("client.slua.logic.rank.rank_data")
            local selfItem = rank_data.GetSelfRankData()
            if selfItem then touchItem(selfItem) end
            applyList()
        end)
        M._inSilentFix = false
    end

    function M.refreshUIOnce()
        scheduleSilentFix()
        pcall(function()
            local RankDataMgr = getRankDataMgr()
            if RankDataMgr then
                local t = RankDataMgr.GetRankSelectType()
                if EventSystem then
                    EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_LIST, t)
                    EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_SELF, t)
                end
            end
        end)
    end

    local function installHooks()
        local ok, rank_data = pcall(require, "client.slua.logic.rank.rank_data")
        if not ok or not rank_data then return false end

        local function hookMod(mod, name, wrapper)
            if not mod or not mod[name] or M._hooks[name] then return false end
            M._hooks[name] = mod[name]
            mod[name] = wrapper
            return true
        end

        hookMod(rank_data, "SortTotalRankList", function(...)
            local r = M._hooks.SortTotalRankList(...)
            if M.cfg.enabled then applyList() end
            return r
        end)

        hookMod(rank_data, "SetSelfRankData", function(raw_self, convertFunction)
            M._hooks.SetSelfRankData(raw_self, convertFunction)
            if M.cfg.enabled and raw_self and isSelf(raw_self.uid) then
                touchItem(require("client.slua.logic.rank.rank_data").GetSelfRankData())
            end
        end)

        return true
    end

    if not M._hooks.SortTotalRankList then
        pcall(installHooks)
    end

    pcall(function()
        local tt = require("common.time_ticker")
        tt.AddTimer(0.5, function()
            if M.cfg.enabled then M.refreshUIOnce() end
            return true
        end)
    end)

    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(3, function()
            if M.cfg.enabled then pcall(M.refreshUIOnce) end
        end, -1, 1)
    end
end

local function IsTrailEnabled()
    local configValue = nil
    if _G.lizardMH_Config and _G.lizardMH_Config.Get then
        configValue = _G.lizardMH_Config.Get("TRAIL_ENABLE", nil)
    end
    if configValue ~= nil then
        return configValue == 1
    end
    return true
end

local function GetTrailItemId()
    local configValue = nil
    if _G.lizardMH_Config and _G.lizardMH_Config.Get then
        configValue = _G.lizardMH_Config.Get("TRAIL_TYPE", nil)
    end
    if configValue ~= nil and configValue ~= 0 then
        return tonumber(configValue)
    end
    return 4531002  
end

_G.GoldenLeavesTrail = _G.GoldenLeavesTrail or {}
_G.GoldenLeavesTrail.Enabled = IsTrailEnabled()
_G.GoldenLeavesTrail.TRAIL_ITEM_ID = GetTrailItemId()

local TRAIL_NAMES = {
    [4531001] = "星绘幻紫拖尾",
    [4531002] = "浮光金叶拖尾",
    [4541001] = "炫酷涂鸦足迹",
}

local SUPPORTED_TRAILS = {4531001, 4531002, 4541001}

local function PreloadTrails()
    pcall(function()
        local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
        local PufferConst = require("client.slua.logic.download.puffer_const")
        if PufferManager and PufferManager.Download then
            PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, SUPPORTED_TRAILS)
        end
    end)
end

local TrailConfig = {
    DELAY_SEC = 0.5,
    TICKER_SEC = 0.5,  
    USE_TICKER = true,
    FORCE_SELF_VISIBLE = true,
}

local _isInMatch = false
local _wasInMatch = false

local function GetCharacter()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD then
        local char = GD.GetPlayerCharacter()
        if char and slua.isValid(char) then
            return char
        end
    end
    if slua_GameFrontendHUD then
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if pc and pc.GetPlayerCharacterSafety then
            local char = pc:GetPlayerCharacterSafety()
            if char and slua.isValid(char) then
                return char
            end
        end
    end
    return nil
end

local function GetAvatarComponent(char)
    char = char or GetCharacter()
    if not char or not slua.isValid(char) then
        return nil
    end
    if char.getAvatarComponent2 then
        local comp = char:getAvatarComponent2()
        if comp and slua.isValid(comp) then
            return comp
        end
    end
    return nil
end

local function IsInFighting()
    local ok, r = pcall(function()
        return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
    end)
    return ok and r == true
end

local function IsInLobby()
    local ok, r = pcall(function()
        return GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()
    end)
    return ok and r == true
end

local function IsInMatch()
    if not _G.GoldenLeavesTrail.Enabled then
        return false
    end
    if IsInLobby() then
        return false
    end
    local ok, isFighting = pcall(function()
        return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
    end)
    if ok then
        return isFighting == true
    end
    local char = GetCharacter()
    return char and slua.isValid(char)
end

local function ApplyTrailToComponent(comp)
    if not comp or not slua.isValid(comp) then
        return false
    end
    if not _G.GoldenLeavesTrail.Enabled then
        return false
    end

    local trailId = _G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002
    comp.MoveEffectItem = trailId
    if comp.AdditionEffectMgr then
        comp.AdditionEffectMgr:SetMoveEffectItem(trailId)
    elseif comp.OnRep_MoveEffectItem then
        comp:OnRep_MoveEffectItem(0)
    end
    return true
end

local function ApplyTrailEffect(char)
    if not _G.GoldenLeavesTrail.Enabled then
        return false
    end
    if not IsInMatch() then
        return false
    end

    char = char or GetCharacter()
    if char and slua.isValid(char) then
        local comp = GetAvatarComponent(char)
        if ApplyTrailToComponent(comp) then
            return true
        end
    end
    return false
end

function _G.GoldenLeavesTrail.Stop()
    pcall(function()
        local char = GetCharacter()
        if char and slua.isValid(char) then
            local comp = GetAvatarComponent(char)
            if comp and slua.isValid(comp) then
                comp.MoveEffectItem = 0
                if comp.AdditionEffectMgr then
                    comp.AdditionEffectMgr:SetMoveEffectItem(0)
                end
            end
        end
    end)
end

function _G.GoldenLeavesTrail.SetType(trailId)
    trailId = tonumber(trailId) or 4531002

    local supported = false
    for _, id in ipairs(SUPPORTED_TRAILS) do
        if id == trailId then
            supported = true
            break
        end
    end
    if not supported then
        trailId = 4531002
    end
    _G.GoldenLeavesTrail.TRAIL_ITEM_ID = trailId
    if _G.lizardMH_Config and _G.lizardMH_Config.Set then
        _G.lizardMH_Config.Set("TRAIL_TYPE", trailId)
    end
    if _G.GoldenLeavesTrail.Enabled then
        pcall(_G.GoldenLeavesTrail.Apply)
    end
    local name = TRAIL_NAMES[trailId] or tostring(trailId)
    print("[Trail] 切换到: " .. name)
end

local function HookPufferManager()
    pcall(function()
        local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
        local PufferConst = require("client.slua.logic.download.puffer_const")
        if not PufferManager or not PufferManager.GetState or PufferManager._GLT_Patched then
            return
        end
        PufferManager._GLT_Patched = true
        local origGetState = PufferManager.GetState
        PufferManager.GetState = function(downloadType, keyList, ...)
            if keyList then
                for _, key in pairs(keyList) do
                    local id = tonumber(key)
                    for _, supported in ipairs(SUPPORTED_TRAILS) do
                        if id == supported then
                            return PufferConst.ENUM_DownloadState.Done
                        end
                    end
                end
            end
            return origGetState(downloadType, keyList, ...)
        end
        if _G.download_item then
            local origDownload = _G.download_item
            _G.download_item = function(id)
                local tid = tonumber(id)
                for _, supported in ipairs(SUPPORTED_TRAILS) do
                    if tid == supported then return end
                end
                return origDownload(id)
            end
        end
    end)
end

local function HookItemValid()
    pcall(function()
        local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
        if not CAC or not CAC.CheckItemValid or CAC._GLT_CheckItemValid then
            return
        end
        CAC._GLT_CheckItemValid = true
        local orig = CAC.CheckItemValid
        CAC.CheckItemValid = function(self, resID)
            local rid = tonumber(resID)
            for _, supported in ipairs(SUPPORTED_TRAILS) do
                if rid == supported then
                    return true
                end
            end
            return orig(self, resID)
        end
    end)
end

local function HookInitDepot()
    pcall(function()
        local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
        if not CAC or not CAC.InitDepotCommonPutOn or CAC._GLT_InitDepot then
            return
        end
        CAC._GLT_InitDepot = true
        local orig = CAC.InitDepotCommonPutOn
        CAC.InitDepotCommonPutOn = function(self)
            orig(self)
            if _G.GoldenLeavesTrail.Enabled and IsInMatch() and self.IsSelf and self:IsSelf() then
                self.MoveEffectItem = _G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002
                if Client and self.AdditionEffectMgr then
                    self.AdditionEffectMgr:SetMoveEffectItem(_G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002)
                end
            end
        end
    end)
end

local function HookEffectVisibility()
    if not TrailConfig.FORCE_SELF_VISIBLE then
        return
    end
    pcall(function()
        local ECPB = require("GameLua.Mod.Library.GamePlay.Avatar.Component.EffectProc.EffectContionProcessorBase")
        if not ECPB or not ECPB.AdditionEffectCheck or ECPB._GLT_AdditionCheck then
            return
        end
        ECPB._GLT_AdditionCheck = true
        local orig = ECPB.AdditionEffectCheck
        ECPB.AdditionEffectCheck = function(self, character)
            if _G.GoldenLeavesTrail.Enabled then
                local mgr = self.OwnerEffectMgr
                local comp = mgr and mgr.GetOwnerAvatarComponent and mgr:GetOwnerAvatarComponent()
                if slua.isValid(comp) and comp.IsSelf and comp:IsSelf() then
                    if IsInMatch() then
                        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                        local localChar = GameplayData.GetLocalCharacter()
                        if slua.isValid(localChar) and localChar.bIsGunADS then
                            return false
                        end
                        return true
                    end
                    return false
                end
            end
            return orig(self, character)
        end
    end)
end

local function HookMeshLoaded()
    pcall(function()
        local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
        if not CAC or not CAC.OnAvatarAllMeshLoadedLua or CAC._GLT_MeshLoaded then
            return
        end
        CAC._GLT_MeshLoaded = true
        local orig = CAC.OnAvatarAllMeshLoadedLua
        CAC.OnAvatarAllMeshLoadedLua = function(self)
            orig(self)
            pcall(function()
                if self.IsLobbyActor and self:IsLobbyActor() then
                    return
                end
                if self.IsSelf and not self:IsSelf() then
                    return
                end
                if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
                    self.MoveEffectItem = _G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002
                    if self.AdditionEffectMgr then
                        self.AdditionEffectMgr:SetMoveEffectItem(_G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002)
                    end
                end
            end)
        end
    end)
end

local function InstallAllHooks()
    if _G._GoldenLeavesTrailHooked then
        return
    end
    _G._GoldenLeavesTrailHooked = true
    HookPufferManager()
    HookItemValid()
    HookInitDepot()
    HookEffectVisibility()
    HookMeshLoaded()
end

function _G.GoldenLeavesTrail.Apply()
    InstallAllHooks()
    if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
        return ApplyTrailEffect()
    end
    return false
end

local function EnsureTrailApplied()
    local inMatch = IsInMatch()

    if inMatch and not _wasInMatch then
        print("[Trail] 检测到进入对局，重新应用拖尾")
        _G.GoldenLeavesTrail.Apply()
    end

    if not inMatch and _wasInMatch then
        print("[Trail] 离开对局，停止拖尾")
        _G.GoldenLeavesTrail.Stop()
    end

    _wasInMatch = inMatch
end

local function StartTicker()
    if not TrailConfig.USE_TICKER then
        return
    end
    pcall(function()
        if _G.Mytimer_ticker then

            _G.Mytimer_ticker.AddTimerLoop(TrailConfig.TICKER_SEC, function()
                pcall(EnsureTrailApplied)

                if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
                    pcall(ApplyTrailEffect)
                elseif not _G.GoldenLeavesTrail.Enabled then
                    pcall(_G.GoldenLeavesTrail.Stop)
                end
            end, -1, 1)
        end
    end)
end

local function Start()
    InstallAllHooks()
    PreloadTrails()
    local char = GetCharacter()
    if char and char.AddGameTimer then
        char:AddGameTimer(TrailConfig.DELAY_SEC, false, function()
            if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
                _G.GoldenLeavesTrail.Apply()
            end
        end)
    else
        if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
            _G.GoldenLeavesTrail.Apply()
        end
    end
    StartTicker()
end

if not _G._GoldenLeavesTrailLoaded then
    _G._GoldenLeavesTrailLoaded = true
    Start()
end

_G.GoldenLeavesTrail.IsInMatch = IsInMatch
_G.GoldenLeavesTrail.ApplyToChar = ApplyTrailEffect
_G.GoldenLeavesTrail.GetTrailName = function(id)
    return TRAIL_NAMES[id] or "未知拖尾"
end

print("[Trail] 已加载，当前拖尾: " .. (TRAIL_NAMES[_G.GoldenLeavesTrail.TRAIL_ITEM_ID] or "未知") .. " (ID: " .. tostring(_G.GoldenLeavesTrail.TRAIL_ITEM_ID) .. ")")

do
local M = {}
_G.GrenadeFX = M

M.MODE = "weapon"                    
M.DEBUG = true                       
M.CUSTOM_SCALE = 1.0                 
M.FORCE_WEAPON_ID = 1101005098       
M.PRESET = "fire"                    
M.CUSTOM_PARTICLE = nil              
M.CUSTOM_SEQ = nil                   

local PRESETS = {
    fire = "/Game/Arts_Effect/ParticleSystems/Grenade/P_Grenade_Fire_Explode_01_Int.P_Grenade_Fire_Explode_01_Int",      
    big_smoke = "/Game/Arts_Effect/ParticleSystems/Grenade/P_Grenade_Explode_01.P_Grenade_Explode_01",                    
    dirt = "/Game/Arts_Effect/ParticleSystems/Grenade/P_Grenade_Explode_stone_02.P_Grenade_Explode_stone_02",            
}

local DeadBoxSmokeSeqActorPath =
    "/Game/Arts_PlayerBluePrints/DeadBox/DeadBoxSmoke/BP_DeadBoxSmokeSeqActor.BP_DeadBoxSmokeSeqActor_C"

local UGameplayStatics = import("GameplayStatics")
local applied = false                 
local overrideHooked = false          
local cachedParticle = nil            
local cachedSeqPath = nil             
local boundGrenadeSkinId = nil        

local function tip(msg)

end

local function findGrenadeForWeapon(weaponId)
    weaponId = tonumber(weaponId)
    if not weaponId or weaponId <= 0 then
        return nil, nil
    end
    local ok, tbl = pcall(function() return CDataTable.GetTable("GrenadeKillGunBindMap") end)
    if not ok or not tbl then
        return nil, nil
    end
    for grenadeId, cfg in pairs(tbl) do
        if cfg and cfg.GunIDList_a and cfg.GunIDList_a.Num then
            for i = 0, cfg.GunIDList_a:Num() - 1 do
                if cfg.GunIDList_a:Get(i) == weaponId then
                    local fxGun = weaponId

                    if cfg.UnlockFxGunIDList_a and cfg.UnlockFxGunIDList_a.Num and cfg.UnlockFxGunIDList_a:Num() > 0 then
                        fxGun = cfg.UnlockFxGunIDList_a:Get(0)
                    end
                    return grenadeId, fxGun
                end
            end
        end
    end
    return nil, nil
end

local function getFxFromWeapon(weaponId)
    weaponId = tonumber(weaponId)
    if not weaponId then return nil, nil end
    local ok, fxCfg = pcall(function()
        return CDataTable.GetTableData("GrenadeBindWeaponFx", weaponId)
    end)
    if not ok or not fxCfg then return nil, nil end
    return fxCfg.FxPath, fxCfg.FxSeqPath  
end

local function setupPlayerGrenadeSkin(grenadeSkinId)
    grenadeSkinId = tonumber(grenadeSkinId)
    if not grenadeSkinId or grenadeSkinId <= 0 then
        return false
    end
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local PC = GameplayData.GetPlayerController()
    if not slua.isValid(PC) then
        tip("no PC for grenade skin")
        return false
    end

    if slua.isValid(PC.InitialConsumableAvatar) then
        PC.InitialConsumableAvatar.GrenadeAvatarShoulei = grenadeSkinId
    end

    if PC.InitGrenadeAvatarList then
        pcall(function() PC:InitGrenadeAvatarList(true) end)
    end
    boundGrenadeSkinId = grenadeSkinId
    return true
end

local function hookCheckHasOverrideFx(forceWeaponId)
    if overrideHooked then return end
    local ok, mod = pcall(require, "GameLua.Mod.Library.GamePlay.Avatar.Component.GrenadeAvatarComponent")
    if not ok or not mod then return end
    local impl = mod.__inner_impl
    if type(impl) ~= "table" then return end
    local orig = rawget(impl, "CheckHasOverrideFx")
    if type(orig) ~= "function" then return end

    rawset(impl, "CheckHasOverrideFx", function(comp, PlayerController, GrenadeSkinID)
        if M.FORCE_WEAPON_ID and M.FORCE_WEAPON_ID > 0 then
            local wid = tonumber(M.FORCE_WEAPON_ID)
            if comp.SetOverrideFxIndex then comp:SetOverrideFxIndex(wid) end
            if comp.SetOverrideSoundIndex then comp:SetOverrideSoundIndex(wid) end
            return  
        end
        return orig(comp, PlayerController, GrenadeSkinID)
    end)
    overrideHooked = true
    tip("CheckHasOverrideFx hooked")
end

function M.ListWeapons(maxRows)
    maxRows = tonumber(maxRows) or 15
    local ok, tbl = pcall(function() return CDataTable.GetTable("GrenadeBindWeaponFx") end)
    if not ok or not tbl then
        return
    end
    local n = 0
    for weaponId, cfg in pairs(tbl) do
        n = n + 1
        if n <= maxRows then
            local seq = cfg and cfg.FxSeqPath or ""
            local p = cfg and cfg.FxPath or ""
            tip(string.format("%s seq=%s", tostring(weaponId), tostring(seq ~= "" and "YES" or p)))
        end
    end
end

function M.Preload()
    cachedParticle = nil
    cachedSeqPath = M.CUSTOM_SEQ

    local weaponId = M.FORCE_WEAPON_ID
    if weaponId and not cachedSeqPath then
        local fxPath, fxSeq = getFxFromWeapon(weaponId)
        cachedSeqPath = fxSeq
        if not M.CUSTOM_PARTICLE and fxPath and fxPath ~= "" then
            M.CUSTOM_PARTICLE = fxPath
        end
        if cachedSeqPath and cachedSeqPath ~= "" then
            tip("VIP seq found")
        elseif fxPath and fxPath ~= "" then
            tip("VIP particle only")
        else
            tip("no FX in table for " .. tostring(weaponId))
        end
    end

    local particlePath = M.CUSTOM_PARTICLE
    if M.MODE == "swap" and M.PRESET and PRESETS[M.PRESET] then
        particlePath = PRESETS[M.PRESET]
    end

    if cachedSeqPath and cachedSeqPath ~= "" then
        tip("seq ready")
    end

    if particlePath and particlePath ~= "" then
        local util = require("client.slua_ui_framework.util")
        util.GetAssetAsync(particlePath, function(uParticle)
            if slua.isValid(uParticle) then
                cachedParticle = uParticle
                tip("particle ready")
            end
        end)
    end
end

local function spawnCustomFx(self, loc)
    local scale = M.CUSTOM_SCALE or 1.0

    if cachedSeqPath and cachedSeqPath ~= "" then
        local host = slua.isValid(self) and self or slua_GameFrontendHUD
        local tf = FTransform(FRotator(0, 0, 0), loc, FVector(scale, scale, scale))
        local seq = Game:PlayLevelSequence(host, cachedSeqPath, tf, DeadBoxSmokeSeqActorPath, false)
        if slua.isValid(seq) then seq:Play(0.0); return true end
        tip("seq spawn FAIL - download weapon pak?")
    end

    if slua.isValid(cachedParticle) then
        local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
        if slua.isValid(world) then
            UGameplayStatics.SpawnEmitterAtLocation(world, cachedParticle, loc,
                FRotator(0, 0, 0), FVector(scale, scale, scale), true)
            return true
        end
    end
    return false
end

local function muteDefaultOnly(self)
    self._GrenadeFX_mute = {}
    if type(self.SpawnExplosionEffect) == "function" then
        self._GrenadeFX_mute.spawn = self.SpawnExplosionEffect
        self.SpawnExplosionEffect = function() end
    end
end

local function unmuteDefaultOnly(self)
    local m = self._GrenadeFX_mute
    if not m then return end
    if m.spawn then self.SpawnExplosionEffect = m.spawn end
    self._GrenadeFX_mute = nil
end

local function findFragGrenadeImpl()
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table"
            and path:find("FragGrenade") and not path:find("LuaGet") then
            local impl = mod.__inner_impl
            if type(impl) == "table" then
                local cur = impl
                while cur do
                    if type(rawget(cur, "BeginInEffect")) == "function" then
                        return cur, path
                    end
                    cur = cur.__super_impl
                end
            end
        end
    end
    return nil, nil
end

function M.BindMaxWeapon(weaponId)
    weaponId = tonumber(weaponId) or M.FORCE_WEAPON_ID
    if not weaponId or weaponId <= 0 then
        return false
    end

    M.FORCE_WEAPON_ID = weaponId
    M.MODE = "weapon"

    local grenadeId, fxGunId = findGrenadeForWeapon(weaponId)
    if grenadeId then
        setupPlayerGrenadeSkin(grenadeId)
    end

    if fxGunId and fxGunId ~= weaponId then
        M.FORCE_WEAPON_ID = fxGunId
    end

    hookCheckHasOverrideFx(M.FORCE_WEAPON_ID)
    M.Preload()
    return M.Apply()
end

function M.Apply()
    if applied then
        return true
    end

    if M.MODE == "list" then
        M.ListWeapons()
        return true
    end

    if M.MODE == "weapon" and M.FORCE_WEAPON_ID then
        hookCheckHasOverrideFx(M.FORCE_WEAPON_ID)
        M.Preload()
    elseif M.MODE == "swap" then
        M.Preload()
    end

    local impl = select(1, findFragGrenadeImpl())
    if not impl then
        return false
    end

    local orig = rawget(impl, "BeginInEffect")
    if type(orig) ~= "function" then return false end

    rawset(impl, "BeginInEffect", function(self, OldType)
        if not Client then
            orig(self, OldType)
            return
        end

        local loc = self.K2_GetActorLocation and self:K2_GetActorLocation() or nil

        if M.MODE == "weapon" or M.MODE == "swap" then

            muteDefaultOnly(self)

            orig(self, OldType)

            unmuteDefaultOnly(self)

            if loc and spawnCustomFx(self, loc) then
            end
            return
        end

        orig(self, OldType)
    end)

    applied = true
    tip("GrenadeFX applied")
    return true
end

function M.Fire()
    M.MODE = "swap"
    M.PRESET = "fire"
    M.Preload()
end

pcall(function()
    if M.FORCE_WEAPON_ID and M.FORCE_WEAPON_ID > 0 then
        M.BindMaxWeapon(M.FORCE_WEAPON_ID)
    end
end)
end

_G.Mytimer_ticker = TXtime_ticker

if _G.__MOD_SYSTEM_LOADED__ then
    return
end
_G.__MOD_SYSTEM_LOADED__ = true

local function LOG(msg)
    local f = io.open("data/share1/loglua.txt", "a+")
    if f then
        f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. tostring(msg) .. "\n")
        f:close()
    end
end

local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
local PufferConst = require("client.slua.logic.download.puffer_const")
local SKillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
local ECharacterHealthStatus = import("ECharacterHealthStatus")
local UEnums = _ENV.UEnums

_G.__ModTeamKillSkinID = _G.__ModTeamKillSkinID or 0
local TEAM_KILL_SUB_EFFECT = 22

local function pufferDownload(id)
    if not id or id == 0 then return end
    local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, {id})
    if state ~= PufferConst.ENUM_DownloadState.Done then
        PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, {id})
    end
end

local function downloadEliminationAssets(skinID)
    pufferDownload(skinID)
    local cfg = CDataTable.GetTableData("WeaponAvatarBattleEffect", skinID)
    if cfg then
        if cfg.EffectPath and cfg.EffectPath ~= "" then pufferDownload(cfg.EffectPath) end
        if cfg.BgPath and cfg.BgPath ~= "" then pufferDownload(cfg.BgPath) end
    end
end

local function downloadTeamAssets(skinID)
    pufferDownload(skinID)
    local cfg = CDataTable.GetTableData("TeamKillBroadcast", skinID)
    if cfg then
        if cfg.EffectPath and cfg.EffectPath ~= "" then pufferDownload(cfg.EffectPath) end
        if cfg.BgPath and cfg.BgPath ~= "" then pufferDownload(cfg.BgPath) end
    end
end

_G.download_item = downloadEliminationAssets

if not _G.BattleKillBroadcastSkinHacked then
    pcall(function()
        local BattleKillBroadcastSubSystem = require("GameLua.Mod.BaseMod.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem")
        if not (BattleKillBroadcastSubSystem and BattleKillBroadcastSubSystem.__inner_impl) then return end
        local o_Copy = BattleKillBroadcastSubSystem.__inner_impl.CopyKillOrPutDownMessageDataUserDataToLuaTable
        BattleKillBroadcastSubSystem.__inner_impl.CopyKillOrPutDownMessageDataUserDataToLuaTable = function(self, messageData)
            local msgData = o_Copy(self, messageData)
            pcall(function()
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                local character = pc and pc:GetPlayerCharacterSafety()
                if character and slua.isValid(character) and msgData.bIamCauser and _G.LuaStateWrapper then
                    msgData.bShowBottomBothSidesKillInfo = true
                    local weapon = character:GetCurrentWeapon()
                    if weapon and slua.isValid(weapon) then
                        local weapon_id = weapon:GetItemDefineID() and weapon:GetItemDefineID().TypeSpecificID or 0
                        if weapon_id ~= 0 then
                            local expand_data = slua.LuaArchiverDecode(_G.LuaStateWrapper, msgData.ExpandDataContent) or {}
                            local isClassic = false
                            local uGameState = slua_GameFrontendHUD:GetGameState()
                            if uGameState and slua.isValid(uGameState) then
                                local EGameModeType = import("EGameModeType")
                                if uGameState.GameModeType == EGameModeType.ETypicalGameMode then isClassic = true end
                            end
                            local syn_data = weapon.synData
                            if syn_data and slua.isValid(syn_data) then
                                local define_id = slua.IndexReference(syn_data:Get(7), "defineID")
                                if define_id and slua.isValid(define_id) then
                                    expand_data.CauserWeaponAvatarID = define_id.TypeSpecificID
                                end
                            end
                            if isClassic then
                                expand_data.KillCounterItemId = weapon_id
                                expand_data.KillCounterNum = _G.getKills and _G.getKills(weapon_id) or 0
                            end
                            msgData.bShowKillNum = true
                            msgData.ExpandDataContent = slua.LuaArchiverEncode(_G.LuaStateWrapper, expand_data)
                        end
                    end
                end
            end)
            return msgData
        end
        _G.BattleKillBroadcastSkinHacked = true
    end)
end

local CURRENT_SEGMENT = 801          
local CONQUEROR_STARS = 91           
local CURRENT_RATING = 4200 + (CONQUEROR_STARS - 1) * 100  

local HISTORY_SEGMENT = 801

local PEAK_CURRENT_SEGMENT = 1541    
local PEAK_HISTORY_SEGMENT = 1301    
local PEAK_RATING = 8000

local JOURNEY_BADGE_LEVEL = 17
local JOURNEY_BADGE_VISUAL_LEVEL = 3
local JOURNEY_BADGE_GLOW_TASKS = 3
local JOURNEY_GLOW_RANKS = { 701, 702, 703, 801 }
local ENABLE_SEASON_YEAR_BADGE = true
local SHOW_SEASON_SERIES_MEDAL = true
local SEASON_SERIES_SEGMENT = 0

local SEASON_RATING = 8500
local SEASON_RANK = "44"
local ACHIEVEMENT_POINTS = 9500
local PLAYED_YEARS = 10
local CONQUEROR_TITLE_ID = 0

local PLAYER_LEVEL = 100
local AVATAR_ID = 30396
local AVATAR_BOX_ID = 2002901

local function refresh_basic_data()
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then

            _G.DataMgr.roleData.level = PLAYER_LEVEL

            _G.DataMgr.roleData.pic_url = AVATAR_ID
            _G.DataMgr.roleData.headIconUrl = AVATAR_ID
            _G.DataMgr.roleData.pic_url_check_open = true

            _G.DataMgr.roleData.cur_avatar_box_id = AVATAR_BOX_ID
        end
    end)
end

if _G.Mytimer_ticker then

    _G.Mytimer_ticker.AddTimer(2, refresh_basic_data)

    _G.Mytimer_ticker.AddTimerLoop(1, refresh_basic_data, -1, 1)
else
    refresh_basic_data()
end

local SEGMENT_TYPE = {
    solo = 1, double = 2, team = 3,
    fpp_solo = 4, fpp_double = 5, fpp_team = 6,
}
local RANK_MODES = { "solo", "duo", "squad", "fppsolo", "fppduo", "fppsquad" }
local ZONE_COUNT = 6

local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
if not RoleInfoSystem then
    print("[SetRoleInfo] RoleInfoSystem not found")
    return
end

local function log_msg(...)
    print("[SetRoleInfo]", ...)
end

local function stars_from_rating(rating)
    rating = tonumber(rating) or 0
    if rating < 4200 then return 0 end
    return math.max(0, math.floor((rating - 4200) / 100) + 1)
end

local function rating_from_stars(stars)
    stars = tonumber(stars) or 0
    if stars <= 0 then return 0 end
    return 4200 + (stars - 1) * 100
end

local function is_self_uid(uid)
    if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return false end
    return tonumber(uid) == tonumber(DataMgr.roleData.uid)
end

local function get_fake_registertime()
    local ok, TimeUtil = pcall(require, "client.common.time_util")
    local now = (ok and TimeUtil and TimeUtil.GetServerTimeInSec and TimeUtil.GetServerTimeInSec()) or os.time()
    return now - (PLAYED_YEARS * 365 * 86400)
end

local function resolve_conqueror_title_id()
    if CONQUEROR_TITLE_ID and CONQUEROR_TITLE_ID > 0 then
        return CONQUEROR_TITLE_ID
    end
    local bestId, bestPri = nil, -1
    pcall(function()
        local tbl = CDataTable and CDataTable.GetTable and CDataTable.GetTable("SegmentTitleConfig")
        if not tbl then return end
        for id, cfg in pairs(tbl) do
            if cfg and not cfg.IfDefaultTitle then
                local pri = tonumber(cfg.Priority) or 0
                local tid = tonumber(cfg.ID) or tonumber(id)
                if tid and pri > bestPri then
                    bestPri = pri
                    bestId = tid
                end
            end
        end
    end)
    return bestId or 0
end

local function build_zone_segments(seg)
    return {
        [SEGMENT_TYPE.solo] = seg,
        [SEGMENT_TYPE.double] = seg,
        [SEGMENT_TYPE.team] = seg,
        [SEGMENT_TYPE.fpp_solo] = seg,
        [SEGMENT_TYPE.fpp_double] = seg,
        [SEGMENT_TYPE.fpp_team] = seg,
    }
end

local function build_allzone_segment(seg)
    local t = {}
    for z = 1, ZONE_COUNT do
        t[z] = build_zone_segments(seg)
    end
    return t
end

local function build_rankdata(rating)
    local rd = {}
    local entry = { rank_rating = rating }
    for z = 1, ZONE_COUNT do
        rd[z] = {}
        for _, mode in ipairs(RANK_MODES) do
            rd[z][mode] = entry
        end
    end
    return rd
end

local function build_hsegment_title(titleId)
    if not titleId or titleId <= 0 then return nil end
    local det = {}
    for z = 1, ZONE_COUNT do
        det[z] = {}
        for modeId = 1, 6 do
            det[z][modeId] = { id = titleId }
        end
    end
    return det
end

local function build_peakgame_list(segmentId, maxSegmentId, rating)
    local ok, PeakGameConfig = pcall(require, "client.logic.PeakGame.PeakGameConfig")
    if not ok or not PeakGameConfig then return nil end
    local bt = PeakGameConfig.BattleType.Squad
    local list = {}
    for z = 1, ZONE_COUNT do
        list[z] = {
            [bt] = {
                rating = rating or PeakGameConfig.DefaultPeakGameRating,
                segment_id = segmentId or PeakGameConfig.DefaultPeakGameSegment,
                max_segment_id = maxSegmentId or segmentId or PeakGameConfig.DefaultPeakGameSegment,
            },
        }
    end
    return list
end

local function build_peakgame_segment_info(segmentId, maxSegmentId, rating)
    local list = build_peakgame_list(segmentId, maxSegmentId, rating)
    if not list then return nil end
    local seasonId = (DataMgr and DataMgr.season_id) or 0
    return { curr_season_id = seasonId, list = list }
end

local function build_peakgame_rating_info(segmentId, maxSegmentId, rating)
    return build_peakgame_list(segmentId, maxSegmentId, rating)
end

local function build_season_year_badge(level)
    local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
    if not ok or not cfg then return nil end
    local EB = cfg.EBadgePartType
    local Done = cfg.ERankTaskStatus.Completed
    level = tonumber(level) or 1

    local gem = { [1] = { finish_count = level, status = Done } }
    local base = { [1] = { finish_count = level, status = Done } }

    local glowTasks = tonumber(JOURNEY_BADGE_GLOW_TASKS) or 3
    local glow = {}
    for i = 1, glowTasks do
        glow[i] = {
            finish_count = 1,
            status = Done,
            trigger_value = JOURNEY_GLOW_RANKS[i] or 801,
        }
    end

    local crown = {}
    local crownMax = cfg.CrownTaskMaxCount or 10
    local crownStage = math.min(tonumber(JOURNEY_BADGE_VISUAL_LEVEL) or 3, level)
    for i = 1, crownMax do
        crown[i] = { finish_count = crownStage, status = Done }
    end

    return {
        [EB.Gem] = gem,
        [EB.Base] = base,
        [EB.Glow] = glow,
        [EB.Crown] = crown,
    }
end

local function get_season_year_id()
    local ok, season_year_util = pcall(require, "client.logic.season_year.util.season_year_util")
    if ok and season_year_util and season_year_util.GetSeasonYearId then
        return season_year_util.GetSeasonYearId()
    end
    return 1
end

local function get_season_series_segment_id()
    if tonumber(SEASON_SERIES_SEGMENT) and SEASON_SERIES_SEGMENT > 0 then
        return SEASON_SERIES_SEGMENT
    end
    local segId
    pcall(function()
        local logic_leisure_season = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_leisure_season)
        if logic_leisure_season and logic_leisure_season.GetLeisureDefaultID then
            segId = logic_leisure_season:GetLeisureDefaultID()
        end
    end)
    if not segId or segId == 0 then
        pcall(function()
            local row = CDataTable and CDataTable.GetTableData and CDataTable.GetTableData("LeisureSeasonParamCfg", "MinSegmentId")
            if row and row.Value then segId = tonumber(row.Value) end
        end)
    end
    return segId or 101
end

local function badge_for_widget_render(badgeData)
    if not badgeData then return nil end
    local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
    if not ok or not cfg then return badgeData end
    local EB = cfg.EBadgePartType
    local Done = cfg.ERankTaskStatus.Completed
    local vis = math.min(3, tonumber(JOURNEY_BADGE_VISUAL_LEVEL) or 3)
    local out = {}
    for partType, partInfo in pairs(badgeData) do
        out[partType] = {}
        for taskId, taskInfo in pairs(partInfo) do
            local fc = taskInfo.finish_count
            local st = taskInfo.status or Done
            if partType == EB.Gem or partType == EB.Base then
                fc = vis
            elseif partType == EB.Glow then
                fc = 1
            elseif partType == EB.Crown then
                fc = vis
            end
            out[partType][taskId] = {
                finish_count = fc,
                status = st,
                trigger_value = taskInfo.trigger_value,
            }
        end
    end
    return out
end

local function get_display_badge()
    local full = build_season_year_badge(JOURNEY_BADGE_LEVEL)
    if not full then return nil end
    return badge_for_widget_render(full)
end

local function get_fake_badge_part_cfg()
    local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
    if not ok or not cfg then return {} end
    local yearId = get_season_year_id()
    if _G.SetRoleInfo_badge_part_cfg and _G.SetRoleInfo_badge_part_cfg[yearId] then
        return _G.SetRoleInfo_badge_part_cfg[yearId]
    end
    apply_server_badge_cfg_cache()
    return (_G.SetRoleInfo_badge_part_cfg and _G.SetRoleInfo_badge_part_cfg[yearId]) or {}
end

local function build_badge_part_cfg_list(count, stageId)
    local list = {}
    for i = 1, count do
        list[i] = {
            task_id = i,
            task_stage_id = stageId,
            finish_value = stageId,
            badge_cfg = { task_desc_id = 0, task_title_id = 0 },
        }
    end
    return list
end

local function apply_server_badge_cfg_cache()
    pcall(function()
        local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
        if not ok or not cfg then return end
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if not logic_season_year_badge then return end
        local yearId = get_season_year_id()
        local EB = cfg.EBadgePartType
        local stage = math.min(3, tonumber(JOURNEY_BADGE_VISUAL_LEVEL) or 3)
        logic_season_year_badge.serverBadgeCfg = logic_season_year_badge.serverBadgeCfg or {}
        logic_season_year_badge.serverBadgeCfg[yearId] = {
            [EB.Gem] = build_badge_part_cfg_list(1, stage),
            [EB.Base] = build_badge_part_cfg_list(1, stage),
            [EB.Glow] = build_badge_part_cfg_list(JOURNEY_BADGE_GLOW_TASKS, 1),
            [EB.Crown] = build_badge_part_cfg_list(cfg.CrownTaskMaxCount or 10, stage),
        }
        logic_season_year_badge.seasonYearTaskInfo = logic_season_year_badge.seasonYearTaskInfo or {}
        logic_season_year_badge.seasonYearTaskInfo[1] = {
            task_id = 1,
            status = cfg.ERankTaskStatus.Completed,
            finish_count = JOURNEY_BADGE_LEVEL,
        }
        local taskYearId = yearId
        logic_season_year_badge.serverYearTaskCfg = logic_season_year_badge.serverYearTaskCfg or {}
        logic_season_year_badge.serverYearTaskCfg[taskYearId] = {
            task_cfgs = {
                [1] = {
                    reward_itemid_1 = 0,
                    reward_cnt_1 = 0,
                    reward_valid_hours_1 = 0,
                    task_desc_id = 0,
                },
            },
        }
        _G.SetRoleInfo_badge_part_cfg = _G.SetRoleInfo_badge_part_cfg or {}
        _G.SetRoleInfo_badge_part_cfg[yearId] = logic_season_year_badge.serverBadgeCfg[yearId]
    end)
end

local function cache_badge_all_year_ids(displayBadge)
    if not displayBadge then return end
    pcall(function()
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if not logic_season_year_badge then return end
        logic_season_year_badge.seasonYearBadgeInfo = logic_season_year_badge.seasonYearBadgeInfo or {}
        local ids = {}
        local yid = get_season_year_id()
        ids[yid] = true
        if yid == 0 then ids[1] = true end
        pcall(function()
            if DataMgr and DataMgr.season_id and CDataTable and CDataTable.GetTableData then
                local row = CDataTable.GetTableData("SeasonInfo", DataMgr.season_id)
                if row and row.SeasonYearID then ids[row.SeasonYearID] = true end
            end
        end)
        for id, _ in pairs(ids) do
            logic_season_year_badge.seasonYearBadgeInfo[id] = displayBadge
        end
    end)
end

local function apply_ace_imprint_self()
    local ace_config = require("client.slua.umg.ace_imprint.config.ace_config")
    local baseId = 10
    local showCnt = tonumber(JOURNEY_BADGE_LEVEL) or 17
    local showId = baseId + showCnt
    if DataMgr and DataMgr.roleData then
        DataMgr.roleData.ace_show_type = ace_config.EAceShowType.Honer
        DataMgr.roleData.ace_imprint_base_id = baseId
        DataMgr.roleData.ace_imprint_show_id = showId
        DataMgr.roleData.ace_imprint_show_cnt = showCnt
    end
    if DataMgr then
        DataMgr.ace_show_type = ace_config.EAceShowType.Honer
        DataMgr.ace_imprint_base_id = baseId
        DataMgr.ace_imprint_show_id = showId
        DataMgr.ace_imprint_show_cnt = showCnt
    end
    pcall(function()
        if LobbySystem and LobbySystem.roleData then
            LobbySystem.roleData.ace_show_type = ace_config.EAceShowType.Honer
            LobbySystem.roleData.ace_imprint_base_id = baseId
            LobbySystem.roleData.ace_imprint_show_id = showId
            LobbySystem.roleData.ace_imprint_show_cnt = showCnt
        end
    end)
end

local function try_set_badge_center_number(badge_ui, num)
    if not badge_ui or not badge_ui.UIRoot then return end
    local root = badge_ui.UIRoot
    local textNames = {
        "TextBlock_Level", "TextBlock_Num", "TextBlock_Number", "TextBlock_Num04",
        "TextBlock_Gem", "TextBlock_0", "TextBlock_1", "TextBlock_5", "TextBlock_6",
        "TextBlock_3", "TextBlock_4",
    }
    local str = tostring(num)
    local function try_widget(w)
        if w and w.SetText then
            w:SetText(str)
            return true
        end
    end
    for _, name in ipairs(textNames) do
        if try_widget(root[name]) then return end
    end
    for lv = 0, 3 do
        local panel = root["Panel_GemCrown" .. lv]
        if panel then
            for _, name in ipairs(textNames) do
                if try_widget(panel[name]) then return end
            end
        end
    end
end

local function hide_kingmark_placeholder(root)
    if not root then return end
    pcall(function()
        if root.Image_69 then
            root.Image_69:SetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
    end)
end

local function apply_journey_kingmark_fallback(ui)
    if not ui or not ui.UIRoot or not ui.UIRoot.SizeBox_Badge_Root then return false end
    local root = ui.UIRoot
    local box = root.SizeBox_Badge_Root
    pcall(function()
        if ui._SetRoleInfo_journey_kingmark and ui._SetRoleInfo_journey_kingmark.Close then
            ui._SetRoleInfo_journey_kingmark:Close()
        end
    end)
    local child = nil
    pcall(function()
        if UIManager and UIManager.UI_Config and UIManager.UI_Config.Common_KingMark_UIBP_2 then
            child = ui:CreateChildWindow(box, UIManager.UI_Config.Common_KingMark_UIBP_2, 4)
        end
    end)
    if not child then
        pcall(function()
            local UIComponentModule = require("client.slua.component.UIComponentModule.UIComponentModule")
            if UIComponentModule and UIComponentModule.InitWithParentComponent then
                child = UIComponentModule:InitWithParentComponent(
                    ui, UIComponentModule.Config.Common_KingMark_UIBP_2, box, 4
                )
            end
        end)
    end
    if child and child.SetWidgetInfo then
        ui._SetRoleInfo_journey_kingmark = child
        child:SetWidgetInfo(10, { advance_num = JOURNEY_BADGE_LEVEL, history_num = 0 })
        try_set_badge_center_number(child, JOURNEY_BADGE_LEVEL)
        pcall(function()
            if child.Show then child:Show() end
            if child.UIRoot and child.UIRoot.SetVisibility then
                child.UIRoot:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end
        end)
        return true
    end
    return false
end

local function apply_journey_season_badge_widget(ui, renderBadge)
    if not ui or not ui.UIRoot or not renderBadge then return false end
    local root = ui.UIRoot
    local box = root.SizeBox_Badge_Root
    if not box then return false end

    local ok_apply = false
    if ui.season_year_badge and ui.season_year_badge.SetBadgeInfo then
        ui.season_year_badge:SetBadgeInfo(renderBadge, false)
        try_set_badge_center_number(ui.season_year_badge, JOURNEY_BADGE_LEVEL)
        ok_apply = true
    end

    if not ok_apply and UIManager and UIManager.UI_Config and UIManager.UI_Config.Lobby_Season_Badge_Item_UIBP then
        pcall(function()
            if ui.season_year_badge and ui.CloseChildWindow then
                ui:CloseChildWindow(ui.season_year_badge)
            end
        end)
        ui.season_year_badge = nil
        pcall(function()
            ui.season_year_badge = ui:CreateChildWindow(
                box, UIManager.UI_Config.Lobby_Season_Badge_Item_UIBP, renderBadge
            )
        end)
        if (not ui.season_year_badge) then
            pcall(function()
                local UIComponentModule = require("client.slua.component.UIComponentModule.UIComponentModule")
                if UIComponentModule and UIComponentModule.InitWithParentComponent then
                    ui.season_year_badge = UIComponentModule:InitWithParentComponent(
                        ui, UIComponentModule.Config.SeasonYear_Badge_Item_UIBP, box, renderBadge
                    )
                end
            end)
        end
        if ui.season_year_badge and ui.season_year_badge.SetBadgeInfo then
            ui.season_year_badge:SetBadgeInfo(renderBadge, false)
            try_set_badge_center_number(ui.season_year_badge, JOURNEY_BADGE_LEVEL)
            ok_apply = true
        end
    end
    return ok_apply
end

local function apply_history_max_segment(profile)
    if not profile or type(profile) ~= "table" then return end
    profile.history_max_segment_level = profile.history_max_segment_level or {}
    profile.history_max_segment_season_id = profile.history_max_segment_season_id or {}
    for z = 1, ZONE_COUNT do
        profile.history_max_segment_level[z] = HISTORY_SEGMENT
        profile.history_max_segment_season_id[z] = profile.history_max_segment_season_id[z]
            or (DataMgr and DataMgr.season_id) or 0
    end
end

local function get_star_rating()
    if tonumber(CURRENT_SEGMENT) ~= 801 then
        return tonumber(CURRENT_RATING) or 0
    end
    local stars = tonumber(DISPLAY_STARS) or 0
    if stars > 0 then
        return rating_from_stars(stars)
    end
    return tonumber(CURRENT_RATING) or 0
end

local function apply_profile_badge_fields(profile)
    if not profile or type(profile) ~= "table" then return end
    local fullBadge = build_season_year_badge(JOURNEY_BADGE_LEVEL)
    local displayBadge = fullBadge and badge_for_widget_render(fullBadge) or nil
    if fullBadge then
        profile.season_year_badge_info = fullBadge
        local yearId = get_season_year_id()
        profile.season_year_badge = profile.season_year_badge or {}
        profile.season_year_badge[yearId] = displayBadge or fullBadge
    end
    local ace_config = require("client.slua.umg.ace_imprint.config.ace_config")
    profile.ace_show_type = ace_config.EAceShowType.Honer
    profile.ace_imprint_base_id = 10
    profile.ace_imprint_show_id = 10 + JOURNEY_BADGE_LEVEL
    profile.ace_imprint_show_cnt = JOURNEY_BADGE_LEVEL
    profile.casual_segment_id = get_season_series_segment_id()
end

local function apply_profile_rank_fields(profile)
    if not profile or type(profile) ~= "table" then return end
    local titleId = resolve_conqueror_title_id()
    local rating = get_star_rating()

    profile.segment_info = build_allzone_segment(CURRENT_SEGMENT)
    profile.rankdata = build_rankdata(rating)
    profile.cur_max_segment_level = CURRENT_SEGMENT
    apply_history_max_segment(profile)

    local htitle = build_hsegment_title(titleId)
    if htitle then
        profile.hsegment_title_det = htitle
    end

    local peakInfo = build_peakgame_segment_info(PEAK_CURRENT_SEGMENT, PEAK_CURRENT_SEGMENT, PEAK_RATING)
    if peakInfo then
        profile.peakgame_segment_info = peakInfo
    end
    profile.peakgame_history_max_segment = PEAK_HISTORY_SEGMENT
end

local function apply_profile_extras(profile)
    if not profile or type(profile) ~= "table" then return end
    apply_profile_rank_fields(profile)
    apply_profile_badge_fields(profile)
    if is_self_uid(profile.uid) then
        profile.registertime = get_fake_registertime()
    end
end

local function ensure_force_badge()
    local full = build_season_year_badge(JOURNEY_BADGE_LEVEL)
    if full then
        _G.SetRoleInfo_force_badge_full = full
        _G.SetRoleInfo_force_badge = get_display_badge() or badge_for_widget_render(full)
    end
    return _G.SetRoleInfo_force_badge
end

local function apply_season_year_badge_cache()
    if not ENABLE_SEASON_YEAR_BADGE then return end
    local displayBadge = ensure_force_badge()
    if not displayBadge then return end
    pcall(function()
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if not logic_season_year_badge then return end
        cache_badge_all_year_ids(displayBadge)
        logic_season_year_badge.loginDays = JOURNEY_BADGE_LEVEL
        local cfg = require("client.logic.season_year.config.season_year_config")
        logic_season_year_badge.badgeShowType = cfg.EBadgeShowType.Show
        apply_server_badge_cfg_cache()
        apply_ace_imprint_self()
    end)
end

local function force_classic_career_highest(ui)
    if not ui or not ui.UIRoot then return end
    local root = ui.UIRoot
    local seasonId = (DataMgr and DataMgr.season_id) or 0
    local w = root.Common_RankIntegralLevel_Style_Large_UIBP_C_2
    if not w then return end
    pcall(function()
        if w.SetRankInteralBySeason then
            w:SetRankInteralBySeason(HISTORY_SEGMENT, nil, seasonId)
        elseif w.SetRankInteralWithSegmentTitle then
            w:SetRankInteralWithSegmentTitle(HISTORY_SEGMENT, nil, seasonId, 0, get_star_rating())
        elseif w.SetRankInteral then
            w:SetRankInteral(HISTORY_SEGMENT, nil)
        end
    end)
end

local function force_roleinfo_journey_badge(ui)
    if not ui or not ui.UIRoot then return end
    local root = ui.UIRoot
    local renderBadge = ensure_force_badge()
    if not renderBadge then return end

    if LocUtil and root.TextBlock_47 then
        pcall(function() root.TextBlock_47:SetText(LocUtil.GetLocalizeResStr(85103)) end)
    end
    if root.TextBlock_21 and LocUtil then
        pcall(function() root.TextBlock_21:SetText(LocUtil.GetLocalizeResStr(68405)) end)
    end
    ui:SetWidgetVisible(root.SizeBox_Badge_Root, true)
    hide_kingmark_placeholder(root)
    if root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1 then
        ui:SetWidgetVisible(root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1, SHOW_SEASON_SERIES_MEDAL)
    end

    local ok = apply_journey_season_badge_widget(ui, renderBadge)
    if not ok then
        apply_journey_kingmark_fallback(ui)
    end
end

local function force_roleinfo_profile_slots(ui)
    force_classic_career_highest(ui)
    force_roleinfo_journey_badge(ui)
end

local function apply_roleinfo_badges_ui()
    apply_season_year_badge_cache()
    pcall(function()
        local ui = UIManager.GetUI(UIManager.UI_Config.roleinfo_segment)
        if not ui or not ui.UIRoot then return end
        local root = ui.UIRoot

        force_roleinfo_profile_slots(ui)

        if SHOW_SEASON_SERIES_MEDAL and root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1 then
            ui:SetWidgetVisible(root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1, true)
            local leisure_season_util = require("client.slua.logic.leisure.leisure_season_util")
            leisure_season_util.SetRankBigIcon(
                root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1,
                get_season_series_segment_id()
            )
            if ui.RefreshCasualSegment then
                ui:RefreshCasualSegment()
            end
        end
    end)
end

local function apply_data_mgr_ranks()
    if not DataMgr or not DataMgr.roleData then return end
    local rd = DataMgr.roleData
    local cur = CURRENT_SEGMENT
    local rating = get_star_rating()

    rd.segment = rd.segment or {}
    rd.segment.solo = cur
    rd.segment.double = cur
    rd.segment.team = cur
    rd.segment.fpp_solo = cur
    rd.segment.fpp_double = cur
    rd.segment.fpp_team = cur
    rd.allzoneSegment = build_allzone_segment(cur)

    rd.rankdata = build_rankdata(rating)

    local titleId = resolve_conqueror_title_id()
    if titleId > 0 then
        rd.allzoneSegmentTitle = build_hsegment_title(titleId)
    end

    DataMgr.isSeasonStarOpen = true
    rd.is_season_star_open = true

    pcall(function()
        local SeasonSystem = require("client.logic.season.logic_season")
        SeasonSystem.segment.team.level = cur
        SeasonSystem.segment.team.rating = rating
    end)

    pcall(function()
        DataMgr.maxSegmentSquad = DataMgr.maxSegmentSquad or { zoneid = 1, SegmentLevel = 0 }
        DataMgr.maxSegmentSquad.SegmentLevel = cur
        DataMgr.maxSegmentSquad.zoneid = 1
    end)

    local peakList = build_peakgame_rating_info(PEAK_CURRENT_SEGMENT, PEAK_CURRENT_SEGMENT, PEAK_RATING)
    if peakList then
        rd.peakgame_rating_info = peakList
    end
    rd.peakgame_history_max_segment = PEAK_HISTORY_SEGMENT
    rd.casual_segment_id = get_season_series_segment_id()
    DataMgr.registertime = get_fake_registertime()
end

local function apply_personal_basic()
    local ok, RoleInfoMainSystem = pcall(require, "client.logic.roleinfo.logic_new_roleinfo")
    if not ok or not RoleInfoMainSystem then return end
    local pbi = RoleInfoSystem.PersonalBasicInfo
    if not pbi or type(pbi) ~= "table" then return end

    pbi.all_segment_info = build_allzone_segment(CURRENT_SEGMENT)
    local titleId = resolve_conqueror_title_id()
    if titleId > 0 then
        pbi.hsegment_title_det = build_hsegment_title(titleId)
    end

    local zoneId = 1
    if RoleInfoMainSystem.GetShowRoleinfoOfZoneID then
        zoneId = RoleInfoMainSystem.GetShowRoleinfoOfZoneID() or 1
    end
    if zoneId == 0 then zoneId = 1 end
    local zs = pbi.all_segment_info[zoneId]
    if zs then
        local fields = {
            "role_segment_solo", "role_segment_double", "role_segment_team",
            "role_segmentFPP_solo", "role_segmentFPP_double", "role_segmentFPP_team",
            "curr_role_segment_solo", "curr_role_segment_double", "curr_role_segment_team",
            "curr_role_segmentFPP_solo", "curr_role_segmentFPP_double", "curr_role_segmentFPP_team",
        }
        local vals = {
            zs[SEGMENT_TYPE.solo], zs[SEGMENT_TYPE.double], zs[SEGMENT_TYPE.team],
            zs[SEGMENT_TYPE.fpp_solo], zs[SEGMENT_TYPE.fpp_double], zs[SEGMENT_TYPE.fpp_team],
            zs[SEGMENT_TYPE.solo], zs[SEGMENT_TYPE.double], zs[SEGMENT_TYPE.team],
            zs[SEGMENT_TYPE.fpp_solo], zs[SEGMENT_TYPE.fpp_double], zs[SEGMENT_TYPE.fpp_team],
        }
        for i, f in ipairs(fields) do
            pbi[f] = vals[i]
        end
    end
    pbi.role_all_zone_segment_max = CURRENT_SEGMENT
end

local function apply_extra_settings()
    if DataMgr and DataMgr.roleData then
        DataMgr.roleData.level = PLAYER_LEVEL
        DataMgr.roleData.pic_url = AVATAR_ID
        DataMgr.roleData.headIconUrl = AVATAR_ID
        DataMgr.roleData.pic_url_check_open = true
        DataMgr.roleData.cur_avatar_box_id = AVATAR_BOX_ID
        print(string.format("[SetRoleInfo] 已设置: 等级=%d, 头像=%d, 头像框=%d", PLAYER_LEVEL, AVATAR_ID, AVATAR_BOX_ID))
    end
end

local function apply_history_to_self_caches()
    if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return end
    local uid = tonumber(DataMgr.roleData.uid)
    local ok, logic_profile = pcall(function()
        return ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    end)
    if ok and logic_profile then
        for _, bucket in ipairs({ logic_profile.dicFriend, logic_profile.dicStranger }) do
            if bucket and bucket[uid] then
                apply_profile_extras(bucket[uid])
            end
        end
        local profile = logic_profile:GetLocalProfile(uid) or logic_profile:GetLocalProfile(uid, true)
        if profile then
            apply_profile_extras(profile)
        end
    end
end

local function patch_conqueror_star_ui()
    if _G.SetRoleInfo_star_ui_patched then return end

    pcall(function()
        local RIClass = require("client.slua.umg.rankIntegral.RankIntegralIconSmall")
        if RIClass and RIClass.SetRankInteralWithSegmentTitle and not RIClass._SetRoleInfo_orig_RII then
            RIClass._SetRoleInfo_orig_RII = RIClass.SetRankInteralWithSegmentTitle
            RIClass.SetRankInteralWithSegmentTitle = function(self, segment, textName, seasonId, titleId, rating)
                if tonumber(segment) == 801 and (not rating or tonumber(rating) == 0) then
                    rating = get_star_rating()
                end
                return RIClass._SetRoleInfo_orig_RII(self, segment, textName, seasonId, titleId, rating)
            end
        end
    end)

    pcall(function()
        local BaseClass = require("client.slua.umg.rankIntegral.RankSmall_Sub_Base_UIBP")
        if BaseClass and BaseClass.SetRankInteralWithSegmentTitle and not BaseClass._SetRoleInfo_orig_Base then
            BaseClass._SetRoleInfo_orig_Base = BaseClass.SetRankInteralWithSegmentTitle
            BaseClass.SetRankInteralWithSegmentTitle = function(self)
                if tonumber(self.rankIntegral) == 801 and (not self.rating or tonumber(self.rating) == 0) then
                    self.rating = get_star_rating()
                end
                return BaseClass._SetRoleInfo_orig_Base(self)
            end
        end
    end)

    pcall(function()
        local logic_segment_title = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_segment_title)
        if logic_segment_title and not logic_segment_title._SetRoleInfo_orig_MaxTitle then
            logic_segment_title._SetRoleInfo_orig_MaxTitle = logic_segment_title.SetMaxSegmentRankInteralWithTitle
            logic_segment_title.SetMaxSegmentRankInteralWithTitle = function(self, widget, allSegmentInfo, allZoneSegmentTitle, seasonId)
                if not slua.isValid(widget) or not allSegmentInfo then
                    return logic_segment_title._SetRoleInfo_orig_MaxTitle(self, widget, allSegmentInfo, allZoneSegmentTitle, seasonId)
                end
                local maxSegment, zoneid, modeid = self:GetMaxSegementLevelWithZoneAndModeId(allSegmentInfo)
                if not maxSegment or maxSegment <= 0 then
                    return logic_segment_title._SetRoleInfo_orig_MaxTitle(self, widget, allSegmentInfo, allZoneSegmentTitle, seasonId)
                end
                widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                if seasonId and seasonId ~= 0 and seasonId ~= DataMgr.season_id then
                    widget:SetRankInteralBySeason(maxSegment, nil, seasonId)
                    return
                end
                local segmentTitleId = self:GetSegmentTitleId(allZoneSegmentTitle, zoneid, modeid)
                local rating = (tonumber(maxSegment) == 801) and get_star_rating() or nil
                local sid = seasonId or DataMgr.season_id
                if not segmentTitleId or tonumber(segmentTitleId) == 0 then
                    if rating and rating > 0 then
                        widget:SetRankInteralWithSegmentTitle(maxSegment, nil, sid, 0, rating)
                    else
                        widget:SetRankInteralBySeason(maxSegment, nil, sid)
                    end
                else
                    widget:SetRankInteralWithSegmentTitle(maxSegment, nil, sid, segmentTitleId, rating)
                end
            end
        end
    end)

    pcall(function()
        local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
        if LobbySocialSystem and not LobbySocialSystem._SetRoleInfo_self_prof then
            LobbySocialSystem._SetRoleInfo_self_prof = true
            local orig = LobbySocialSystem.GetSelfProfile
            LobbySocialSystem.GetSelfProfile = function()
                local p = orig()
                if p and tonumber(CURRENT_SEGMENT) == 801 then
                    p.rankdata = build_rankdata(get_star_rating())
                end
                if p and ENABLE_SEASON_YEAR_BADGE then
                    apply_profile_badge_fields(p)
                end
                return p
            end
        end
        if LobbySocialSystem and LobbySocialSystem.GetAceImprintShowId and not LobbySocialSystem._SetRoleInfo_ace_show then
            LobbySocialSystem._SetRoleInfo_ace_show = true
            local origAce = LobbySocialSystem.GetAceImprintShowId
            LobbySocialSystem.GetAceImprintShowId = function(uid)
                if is_self_uid(uid) and ENABLE_SEASON_YEAR_BADGE then
                    return 10 + JOURNEY_BADGE_LEVEL, 10, JOURNEY_BADGE_LEVEL
                end
                return origAce(uid)
            end
        end
    end)

    pcall(function()
        local SeasonHandler = require("client.network.Protocol.SeasonHandler")
        SeasonHandler.rank_rating = get_star_rating()
    end)

    _G.SetRoleInfo_star_ui_patched = true
end

local function patch_badge_and_leisure_hooks()
    if _G.SetRoleInfo_badge_hooks_patched then return end
    _G.SetRoleInfo_badge_hooks_patched = true

    pcall(function()
        local season_year_util = require("client.logic.season_year.util.season_year_util")
        if season_year_util and season_year_util.CheckFunctionIsOpen and not season_year_util._SetRoleInfo_orig_CheckOpen then
            season_year_util._SetRoleInfo_orig_CheckOpen = season_year_util.CheckFunctionIsOpen
            season_year_util.CheckFunctionIsOpen = function()
                if ENABLE_SEASON_YEAR_BADGE then return true end
                return season_year_util._SetRoleInfo_orig_CheckOpen()
            end
        end
    end)

    pcall(function()
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if logic_season_year_badge and logic_season_year_badge.GetCurSeasonYearBadgeInfo
            and not logic_season_year_badge._SetRoleInfo_orig_GetBadge then
            logic_season_year_badge._SetRoleInfo_orig_GetBadge = logic_season_year_badge.GetCurSeasonYearBadgeInfo
            local origGetBadge = logic_season_year_badge._SetRoleInfo_orig_GetBadge
            logic_season_year_badge.GetCurSeasonYearBadgeInfo = function(self)
                apply_season_year_badge_cache()
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return _G.SetRoleInfo_force_badge
                end
                local data = origGetBadge(self)
                if ENABLE_SEASON_YEAR_BADGE and (not data or not next(data)) then
                    return ensure_force_badge() or data
                end
                return data
            end
        end
        if logic_season_year_badge and logic_season_year_badge.on_get_season_year_badge_info_rsp
            and not logic_season_year_badge._SetRoleInfo_wrapped_badge_rsp then
            logic_season_year_badge._SetRoleInfo_wrapped_badge_rsp = true
            local orig = logic_season_year_badge.on_get_season_year_badge_info_rsp
            logic_season_year_badge.on_get_season_year_badge_info_rsp = function(self, badge_info)
                if ENABLE_SEASON_YEAR_BADGE then
                    apply_season_year_badge_cache()
                    if EventSystem and EVENTTYPE_SEASON_YEAR and EVENTID_SEASON_YEAR_BADGE_UPDATE then
                        EventSystem:postEvent(EVENTTYPE_SEASON_YEAR, EVENTID_SEASON_YEAR_BADGE_UPDATE)
                    end
                    return
                end
                orig(self, badge_info)
            end
        end
        if logic_season_year_badge and logic_season_year_badge.on_get_season_year_badge_cfg_rsp
            and not logic_season_year_badge._SetRoleInfo_wrapped_cfg_rsp then
            logic_season_year_badge._SetRoleInfo_wrapped_cfg_rsp = true
            local origCfg = logic_season_year_badge.on_get_season_year_badge_cfg_rsp
            logic_season_year_badge.on_get_season_year_badge_cfg_rsp = function(self, info)
                origCfg(self, info)
                apply_server_badge_cfg_cache()
            end
        end
        if logic_season_year_badge and logic_season_year_badge.GetBadgeShowType
            and not logic_season_year_badge._SetRoleInfo_orig_ShowType then
            logic_season_year_badge._SetRoleInfo_orig_ShowType = logic_season_year_badge.GetBadgeShowType
            logic_season_year_badge.GetBadgeShowType = function(self)
                if ENABLE_SEASON_YEAR_BADGE then
                    local cfg = require("client.logic.season_year.config.season_year_config")
                    return cfg.EBadgeShowType.Show
                end
                return logic_season_year_badge._SetRoleInfo_orig_ShowType(self)
            end
        end
        if logic_season_year_badge and logic_season_year_badge.GetCurSeasonYearBadgeCfg
            and not logic_season_year_badge._SetRoleInfo_orig_GetCfg then
            logic_season_year_badge._SetRoleInfo_orig_GetCfg = logic_season_year_badge.GetCurSeasonYearBadgeCfg
            logic_season_year_badge.GetCurSeasonYearBadgeCfg = function(self)
                apply_server_badge_cfg_cache()
                local cfg = logic_season_year_badge._SetRoleInfo_orig_GetCfg(self)
                if cfg and next(cfg) then return cfg end
                local yearId = get_season_year_id()
                return self.serverBadgeCfg and self.serverBadgeCfg[yearId] or {}
            end
        end
    end)

    pcall(function()
        local season_year_badge_util = require("client.logic.season_year.util.season_year_badge_util")
        if season_year_badge_util.CheckGotBadge and not season_year_badge_util._SetRoleInfo_orig_Got then
            season_year_badge_util._SetRoleInfo_orig_Got = season_year_badge_util.CheckGotBadge
            season_year_badge_util.CheckGotBadge = function(badgeData)
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return true
                end
                return season_year_badge_util._SetRoleInfo_orig_Got(badgeData)
            end
        end
        if season_year_badge_util.GetBadgeShowType and not season_year_badge_util._SetRoleInfo_orig_UtilShow then
            season_year_badge_util._SetRoleInfo_orig_UtilShow = season_year_badge_util.GetBadgeShowType
            season_year_badge_util.GetBadgeShowType = function()
                if ENABLE_SEASON_YEAR_BADGE then
                    local cfg = require("client.logic.season_year.config.season_year_config")
                    return cfg.EBadgeShowType.Show
                end
                return season_year_badge_util._SetRoleInfo_orig_UtilShow()
            end
        end
        if season_year_badge_util.GetCurSeasonYearBadgeInfo and not season_year_badge_util._SetRoleInfo_orig_GetInfo then
            season_year_badge_util._SetRoleInfo_orig_GetInfo = season_year_badge_util.GetCurSeasonYearBadgeInfo
            season_year_badge_util.GetCurSeasonYearBadgeInfo = function()
                apply_season_year_badge_cache()
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return _G.SetRoleInfo_force_badge
                end
                local data = season_year_badge_util._SetRoleInfo_orig_GetInfo()
                if ENABLE_SEASON_YEAR_BADGE and (not data or not next(data)) then
                    return ensure_force_badge() or data
                end
                return data
            end
        end
        if season_year_badge_util.GetCurSeasonYearBadgePartCfgInfo and not season_year_badge_util._SetRoleInfo_orig_PartCfg then
            season_year_badge_util._SetRoleInfo_orig_PartCfg = season_year_badge_util.GetCurSeasonYearBadgePartCfgInfo
            season_year_badge_util.GetCurSeasonYearBadgePartCfgInfo = function(partType)
                local c = season_year_badge_util._SetRoleInfo_orig_PartCfg(partType)
                if c and next(c) then return c end
                local fake = get_fake_badge_part_cfg()
                return fake[partType] or {}
            end
        end
        if season_year_badge_util.GetSeasonYearBadge and not season_year_badge_util._SetRoleInfo_orig_GetByUid then
            season_year_badge_util._SetRoleInfo_orig_GetByUid = season_year_badge_util.GetSeasonYearBadge
            season_year_badge_util.GetSeasonYearBadge = function(uid)
                if is_self_uid(uid) and ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return _G.SetRoleInfo_force_badge
                end
                return season_year_badge_util._SetRoleInfo_orig_GetByUid(uid)
            end
        end
    end)

    pcall(function()
        local BadgeClass = require("client.slua.umg.Lobby_SeasonUI.Season2026.Item.Lobby_Season_Badge_Item_UIBP")
        if BadgeClass and BadgeClass.SetBadgeInfo and not BadgeClass._SetRoleInfo_orig_SetBadge then
            BadgeClass._SetRoleInfo_orig_SetBadge = BadgeClass.SetBadgeInfo
            BadgeClass.SetBadgeInfo = function(self, badgeData, bPlayLevelUpAni)
                local renderData = _G.SetRoleInfo_force_badge
                    or badge_for_widget_render(badgeData) or badgeData
                BadgeClass._SetRoleInfo_orig_SetBadge(self, renderData, bPlayLevelUpAni)
                if ENABLE_SEASON_YEAR_BADGE then
                    try_set_badge_center_number(self, JOURNEY_BADGE_LEVEL)
                end
            end
        end
        if BadgeClass and BadgeClass.SetBadgeGemInfo and not BadgeClass._SetRoleInfo_orig_SetGem then
            BadgeClass._SetRoleInfo_orig_SetGem = BadgeClass.SetBadgeGemInfo
            BadgeClass.SetBadgeGemInfo = function(self, gemData, newActiveGemData)
                apply_server_badge_cfg_cache()
                return BadgeClass._SetRoleInfo_orig_SetGem(self, gemData, newActiveGemData)
            end
        end
        if BadgeClass and BadgeClass.PlayBadgePartLevelUpAnimation and not BadgeClass._SetRoleInfo_orig_Anim then
            BadgeClass._SetRoleInfo_orig_Anim = BadgeClass.PlayBadgePartLevelUpAnimation
            BadgeClass.PlayBadgePartLevelUpAnimation = function(self, partType, level, bPlayAnimation)
                level = math.min(3, math.max(0, tonumber(level) or 0))
                return BadgeClass._SetRoleInfo_orig_Anim(self, partType, level, bPlayAnimation)
            end
        end
    end)

    pcall(function()
        local RoleInfoUI = require("client.slua.umg.PersonSpace.Lobby_RoleInfo_Segment180_UIBP")
        if RoleInfoUI and RoleInfoUI.OnSeasonYearBadgeUpdate and not RoleInfoUI._SetRoleInfo_wrapped_badge_ui then
            RoleInfoUI._SetRoleInfo_wrapped_badge_ui = true
            local orig = RoleInfoUI.OnSeasonYearBadgeUpdate
            RoleInfoUI.OnSeasonYearBadgeUpdate = function(self)
                apply_season_year_badge_cache()
                local renderBadge = ensure_force_badge()
                if renderBadge then
                    apply_journey_season_badge_widget(self, renderBadge)
                    if not (self.season_year_badge and self.season_year_badge.UIRoot) then
                        apply_journey_kingmark_fallback(self)
                    end
                else
                    orig(self)
                end
                force_roleinfo_profile_slots(self)
            end
        end
        if RoleInfoUI and RoleInfoUI.OnGetSelfRoleInfoCallBack and not RoleInfoUI._SetRoleInfo_wrapped_hist then
            RoleInfoUI._SetRoleInfo_wrapped_hist = true
            local origCb = RoleInfoUI.OnGetSelfRoleInfoCallBack
            RoleInfoUI.OnGetSelfRoleInfoCallBack = function(self, list)
                if list and list[1] then
                    apply_history_max_segment(list[1])
                    apply_profile_badge_fields(list[1])
                end
                origCb(self, list)
                force_roleinfo_profile_slots(self)
            end
        end
        if RoleInfoUI and RoleInfoUI.UpdateUI and not RoleInfoUI._SetRoleInfo_wrapped_updateui then
            RoleInfoUI._SetRoleInfo_wrapped_updateui = true
            local origUp = RoleInfoUI.UpdateUI
            RoleInfoUI.UpdateUI = function(self)
                origUp(self)
                force_roleinfo_profile_slots(self)
            end
        end
        if RoleInfoUI and RoleInfoUI.OnPostInitialize and not RoleInfoUI._SetRoleInfo_wrapped_post then
            RoleInfoUI._SetRoleInfo_wrapped_post = true
            local origPost = RoleInfoUI.OnPostInitialize
            RoleInfoUI.OnPostInitialize = function(self, ...)
                apply_season_year_badge_cache()
                origPost(self, ...)
                local function refresh()
                    apply_season_year_badge_cache()
                    force_roleinfo_profile_slots(self)
                end
                refresh()
                if self.AddTimerOnce then
                    self:AddTimerOnce(0.05, refresh)
                    self:AddTimerOnce(0.15, refresh)
                    self:AddTimerOnce(0.5, refresh)
                    self:AddTimerOnce(1.0, refresh)
                    self:AddTimerOnce(2.0, refresh)
                end
            end
        end
        if RoleInfoUI and RoleInfoUI.RefreshAceImprint and not RoleInfoUI._SetRoleInfo_wrapped_ace then
            RoleInfoUI._SetRoleInfo_wrapped_ace = true
            local origAce = RoleInfoUI.RefreshAceImprint
            RoleInfoUI.RefreshAceImprint = function(self)
                apply_ace_imprint_self()
                origAce(self)
                hide_kingmark_placeholder(self.UIRoot)
            end
        end
    end)

    pcall(function()
        local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
        if RoleInfoMainSystem and RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId
            and not RoleInfoMainSystem._SetRoleInfo_orig_hist then
            RoleInfoMainSystem._SetRoleInfo_orig_hist = RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId
            RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId = function(historyLevels, seasonTable)
                if tonumber(HISTORY_SEGMENT) and HISTORY_SEGMENT > 0 then
                    local sid = (DataMgr and DataMgr.season_id) or 0
                    if seasonTable and next(seasonTable) then
                        for z, s in pairs(seasonTable) do
                            if tonumber(s) and s > sid then sid = s end
                        end
                    end
                    return HISTORY_SEGMENT, sid
                end
                return RoleInfoMainSystem._SetRoleInfo_orig_hist(historyLevels, seasonTable)
            end
        end
    end)

    pcall(function()
        local AchUI = require("client.slua.umg.Lobby_SeasonUI.Season2026.Lobby_Season_AnnualAchievement_UIBP")
        if AchUI and AchUI.UpdateUI and not AchUI._SetRoleInfo_wrapped_update then
            AchUI._SetRoleInfo_wrapped_update = true
            local origUp = AchUI.UpdateUI
            AchUI.UpdateUI = function(self)
                apply_season_year_badge_cache()
                origUp(self)
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    local renderBadge = badge_for_widget_render(_G.SetRoleInfo_force_badge)
                    if self.CompBadge01 and self.CompBadge01.SetBadgeInfo then
                        self.CompBadge01:SetBadgeInfo(renderBadge, true)
                    end
                end
            end
        end
    end)

    pcall(function()
        local SeasonSystem = require("client.logic.season.logic_season")
        if SeasonSystem and SeasonSystem.GetBestSegment and not SeasonSystem._SetRoleInfo_orig_best then
            SeasonSystem._SetRoleInfo_orig_best = SeasonSystem.GetBestSegment
            SeasonSystem.GetBestSegment = function()
                if ENABLE_SEASON_YEAR_BADGE then
                    return CURRENT_SEGMENT
                end
                return SeasonSystem._SetRoleInfo_orig_best()
            end
        end
    end)

    pcall(function()
        local logic_leisure_season = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_leisure_season)
        if logic_leisure_season and not logic_leisure_season._SetRoleInfo_orig_GetSeg then
            logic_leisure_season._SetRoleInfo_orig_GetSeg = logic_leisure_season.GetLeisureSegmentID
            logic_leisure_season.GetLeisureSegmentID = function(self)
                return get_season_series_segment_id()
            end
            logic_leisure_season._SetRoleInfo_orig_GetSegUID = logic_leisure_season.GetLeisureSegmentIDByUID
            logic_leisure_season.GetLeisureSegmentIDByUID = function(self, uid)
                if is_self_uid(uid) then
                    return get_season_series_segment_id()
                end
                return logic_leisure_season._SetRoleInfo_orig_GetSegUID(self, uid)
            end
        end
    end)
end

local function post_ui_refresh_events()
    pcall(function()
        if EventSystem and EVENTTYPE_ROLEINFO and EVENTID_ROLEINFO_UPDATE_ROLEINFO then
            EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO)
        end
        if EventSystem and EVENTTYPE_PEAKGAME and EVENTID_PEAKGAME_RATING_NOTIFY then
            EventSystem:postEvent(EVENTTYPE_PEAKGAME, EVENTID_PEAKGAME_RATING_NOTIFY)
        end
        if EventSystem and EVENTTYPE_SEASON_YEAR and EVENTID_SEASON_YEAR_BADGE_UPDATE then
            EventSystem:postEvent(EVENTTYPE_SEASON_YEAR, EVENTID_SEASON_YEAR_BADGE_UPDATE)
        end
        if EventSystem and EVENTTYPE_LEISURE_SEASON and EVENTID_LEISURE_SEASON_SEGMENT_NOTIFY then
            EventSystem:postEvent(EVENTTYPE_LEISURE_SEASON, EVENTID_LEISURE_SEASON_SEGMENT_NOTIFY)
        end
        if EventSystem and EVENTTYPE_DATA_MGR and EVENTID_ACE_IMPRINT_UPDATE then
            EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_ACE_IMPRINT_UPDATE)
        end
    end)
end

local function apply_bottom_profile_stats()
    if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return end
    local uid = tonumber(DataMgr.roleData.uid)
    local ratingStr = tostring(SEASON_RATING)
    for zoneId = 1, ZONE_COUNT do
        RoleInfoSystem.CurrSeasonTPPTotalScore[zoneId] = SEASON_RATING
        RoleInfoSystem.CurrSeasonFPPTotalScore[zoneId] = SEASON_RATING
        RoleInfoSystem.CurrSeasonTPPTotalRank[zoneId] = SEASON_RANK
        RoleInfoSystem.CurrSeasonFPPTotalRank[zoneId] = SEASON_RANK
        RoleInfoSystem.PersonalTotalScoreInfo[zoneId] = { role_totalscore = ratingStr }
        RoleInfoSystem.PersonalTotalRankInfo[zoneId] = { role_totalrank = SEASON_RANK }
        RoleInfoSystem.FPPPersonalTotalScoreInfo[zoneId] = { role_totalscore = ratingStr }
        RoleInfoSystem.FPPPersonalTotalRankInfo[zoneId] = { role_totalrank = SEASON_RANK }
    end
    if RoleInfoSystem.SetElementToString then
        pcall(function()
            RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalTotalScoreInfo)
            RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalTotalRankInfo)
            RoleInfoSystem.SetElementToString(RoleInfoSystem.FPPPersonalTotalScoreInfo)
            RoleInfoSystem.SetElementToString(RoleInfoSystem.FPPPersonalTotalRankInfo)
        end)
    end
    local ok, AchieveHandler = pcall(require, "client.network.Protocol.AchieveHandler")
    if ok and AchieveHandler then
        AchieveHandler.resSummaryTb[uid] = AchieveHandler.resSummaryTb[uid] or {}
        AchieveHandler.resSummaryTb[uid].achieve_score = ACHIEVEMENT_POINTS
        AchieveHandler.resSummaryTb[uid].uid = uid
    end
    apply_data_mgr_ranks()
    apply_ace_imprint_self()
    patch_conqueror_star_ui()
    pcall(function()
        local SeasonHandler = require("client.network.Protocol.SeasonHandler")
        if tonumber(CURRENT_SEGMENT) == 801 then
            SeasonHandler.rank_rating = get_star_rating()
        end
    end)
    patch_badge_and_leisure_hooks()
    apply_season_year_badge_cache()
    apply_roleinfo_badges_ui()
    apply_personal_basic()
    apply_history_to_self_caches()
    apply_extra_settings()
    post_ui_refresh_events()
end

local function apply_all()
    apply_bottom_profile_stats()
end

local function install_refresh_hooks()
    if _G.SetRoleInfo_hooks_installed then return end
    _G.SetRoleInfo_hooks_installed = true
    patch_conqueror_star_ui()
    patch_badge_and_leisure_hooks()

    pcall(function()
        if RoleInfoSystem.get_role_basic_info_rsp and not RoleInfoSystem._SetRoleInfo_wrapped then
            RoleInfoSystem._SetRoleInfo_wrapped = true
            local orig = RoleInfoSystem.get_role_basic_info_rsp
            RoleInfoSystem.get_role_basic_info_rsp = function(list)
                orig(list)
                if list and list[1] then
                    apply_profile_rank_fields(list[1])
                    apply_history_max_segment(list[1])
                    apply_profile_badge_fields(list[1])
                end
                apply_all()
            end
        end
    end)

    if Timer and Timer.New then
        if _G.SetRoleInfo_timer then
            pcall(function() _G.SetRoleInfo_timer:Stop() end)
        end
        _G.SetRoleInfo_timer = Timer.New(function()
            apply_all()
        end, 3, 0)
        _G.SetRoleInfo_timer:Start()
    end
end

ensure_force_badge()
apply_all()
install_refresh_hooks()

log_msg(string.format(
    "征服者 %d | 星星=%d | 积分=%d | 旅程徽章=%d | 休闲赛季段位=%d | 等级=%d",
    CURRENT_SEGMENT, CONQUEROR_STARS, get_star_rating(),
    JOURNEY_BADGE_LEVEL, get_season_series_segment_id(), PLAYER_LEVEL
))

_G.FAKE_LEVEL = _G.FAKE_LEVEL or 100              
_G.FAKE_DAN = _G.FAKE_DAN or 100                  
_G.FAKE_LEVEL_NAME = _G.FAKE_LEVEL_NAME or "Collection Champion"  
_G.FAKE_SCORE = _G.FAKE_SCORE or 99999            

if _G.__COLLECT_FAKE_LOADED then
    return
end
_G.__COLLECT_FAKE_LOADED = true

local function hook_collect_handler()
    local handler = package.loaded["client.network.Protocol.CollectHandler"] or package.loaded["CollectHandler"]
    if not handler and not rawget(package.loaded, "client.network.Protocol.CollectHandler") then
        pcall(require, "client.network.Protocol.CollectHandler")
    end

    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.on_get_collect_sys_main_data_rsp and not rawget(mod, "_collection_handler_hooked") then
            rawset(mod, "_collection_handler_hooked", true)
            local orig = mod.on_get_collect_sys_main_data_rsp

            mod.on_get_collect_sys_main_data_rsp = function(err_code, collect_data, param)
                if collect_data and type(collect_data) == "table" then
                    rawset(collect_data, "total_score", _G.FAKE_SCORE)
                    rawset(collect_data, "cur_season_collect_score", _G.FAKE_SCORE)
                    local ss = rawget(collect_data, "season_score")
                    if type(ss) == "table" then
                        for k in pairs(ss) do ss[k] = _G.FAKE_SCORE end
                    else
                        rawset(collect_data, "season_score", { [1] = _G.FAKE_SCORE, [2] = _G.FAKE_SCORE })
                    end
                end
                return orig(err_code, collect_data, param)
            end
            return true
        end
    end
    return false
end

local function hook_module_manager()
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetModule and mod.LobbyModuleConfig and mod.LobbyModuleConfig.collect_module and not rawget(mod, "_collection_getmodule_hooked") then
            rawset(mod, "_collection_getmodule_hooked", true)
            local orig_get = mod.GetModule
            local collect_key = mod.LobbyModuleConfig.collect_module

            mod.GetModule = function(self, name)
                local inst = orig_get(self, name)
                if inst and name == collect_key then
                    patch_collect_module(inst)
                    inject_collect_data()
                end
                return inst
            end
            return true
        end
    end
    return false
end

local function get_collect_module()
    local ModuleManager = _G.ModuleManager
    if not ModuleManager then
        for _, mod in pairs(package.loaded or {}) do
            if type(mod) == "table" and mod.GetModule and mod.LobbyModuleConfig and mod.LobbyModuleConfig.collect_module then
                ModuleManager = mod
                break
            end
        end
    end

    if ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig then
        local ok, cm = pcall(ModuleManager.GetModule, ModuleManager, ModuleManager.LobbyModuleConfig.collect_module)
        if ok and cm then return cm end
    end

    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetLevelDataByScore and mod.GetSeasonLevelByScore then
            return mod
        end
    end
    return nil
end

local function patch_collect_module(mod)
    if not mod or rawget(mod, "_collection_level_patched") then return false end
    rawset(mod, "_collection_level_patched", true)

    if mod.GetLevelDataByScore then
        rawset(mod, "GetLevelDataByScore", function(self, score, isSeason)
            return _G.FAKE_LEVEL, _G.FAKE_LEVEL_NAME, _G.FAKE_DAN
        end)
    end

    if mod.GetSeasonLevelByScore then
        rawset(mod, "GetSeasonLevelByScore", function(self, score, seasonId)
            return _G.FAKE_LEVEL, true, _G.FAKE_LEVEL_NAME
        end)
    end

    if mod.GetCollectScoreByCollectData then
        rawset(mod, "GetCollectScoreByCollectData", function(self, collect_data)
            return _G.FAKE_SCORE, _G.FAKE_SCORE
        end)
    end

    local collect_data = rawget(mod, "collect_data")
    if collect_data and type(collect_data) == "table" then
        rawset(collect_data, "total_score", _G.FAKE_SCORE)
        if not rawget(collect_data, "season_score") then rawset(collect_data, "season_score", {}) end
        local season = (rawget(mod, "GetSeasonId") and mod:GetSeasonId()) or 1
        collect_data.season_score[season] = _G.FAKE_SCORE
        rawset(collect_data, "cur_season_collect_score", _G.FAKE_SCORE)
    end

    if rawget(mod, "OnGetMainData") or mod.OnGetMainData then
        local orig_on_get = rawget(mod, "OnGetMainData") or mod.OnGetMainData
        rawset(mod, "OnGetMainData", function(self, err_code, data, param)
            if data and type(data) == "table" then
                rawset(data, "total_score", _G.FAKE_SCORE)
                if not rawget(data, "season_score") then rawset(data, "season_score", {}) end
                local season = (rawget(self, "GetSeasonId") and self:GetSeasonId()) or 1
                if type(data.season_score) == "table" then
                    data.season_score[season] = _G.FAKE_SCORE
                end
                rawset(data, "cur_season_collect_score", _G.FAKE_SCORE)
            end
            orig_on_get(self, err_code, data, param)
        end)
    end

    return true
end

local function inject_collect_data()
    pcall(function()
        local cm = get_collect_module()
        if cm then
            local collect_data = rawget(cm, "collect_data")
            if collect_data and type(collect_data) == "table" then
                rawset(collect_data, "total_score", _G.FAKE_SCORE)
                if not rawget(collect_data, "season_score") then rawset(collect_data, "season_score", {}) end
                local season = (rawget(cm, "GetSeasonId") and cm:GetSeasonId()) or 1
                if type(collect_data.season_score) == "table" then
                    collect_data.season_score[season] = _G.FAKE_SCORE
                end
                rawset(collect_data, "cur_season_collect_score", _G.FAKE_SCORE)
            end
        end
    end)

    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            if not _G.DataMgr.roleData.brief_collect_data then _G.DataMgr.roleData.brief_collect_data = {} end
            _G.DataMgr.roleData.brief_collect_data.total_score = _G.FAKE_SCORE
            _G.DataMgr.roleData.brief_collect_data.cur_season_collect_score = _G.FAKE_SCORE
        end
    end)
end

local function hook_collect_road_ui()
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.ShowCollect and mod.ShowSeasonCollect and not rawget(mod, "_collection_road_hooked") then
            rawset(mod, "_collection_road_hooked", true)
            local orig_show = mod.ShowCollect

            if orig_show then
                rawset(mod, "ShowCollect", function(self)
                    local mm = _G.ModuleManager
                    if not mm then
                        for _, m in pairs(package.loaded or {}) do
                            if type(m) == "table" and m.GetModule and m.LobbyModuleConfig then
                                mm = m
                                break
                            end
                        end
                    end

                    if mm and mm.LobbyModuleConfig and mm.LobbyModuleConfig.collect_module then
                        local ok, cm = pcall(mm.GetModule, mm, mm.LobbyModuleConfig.collect_module)
                        if ok and cm and rawget(cm, "collect_data") then
                            local cd = rawget(cm, "collect_data")
                            if type(cd) == "table" then
                                rawset(cd, "total_score", _G.FAKE_SCORE)
                                if not rawget(cd, "season_score") then rawset(cd, "season_score", {}) end
                                cd.season_score[(rawget(cm, "GetSeasonId") and cm:GetSeasonId()) or 1] = _G.FAKE_SCORE
                                rawset(cd, "cur_season_collect_score", _G.FAKE_SCORE)
                            end
                        end
                    end
                    return orig_show(self)
                end)
            end
            return true
        end
    end
    return false
end

local function install_collect_hooks()
    hook_collect_handler()
    hook_module_manager()
    hook_collect_road_ui()

    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetLevelDataByScore and mod.GetSeasonLevelByScore and not rawget(mod, "_collection_level_patched") then
            patch_collect_module(mod)
        end
    end

    local cm = get_collect_module()
    if cm then
        patch_collect_module(cm)
    end
    inject_collect_data()

    print("[收藏伪造] Hook已安装，等级=" .. _G.FAKE_LEVEL .. " 积分=" .. _G.FAKE_SCORE)
end

_G.CollectFake = {
    Apply = function()
        install_collect_hooks()
    end,
    SetLevel = function(n)
        _G.FAKE_LEVEL = tonumber(n) or _G.FAKE_LEVEL
        install_collect_hooks()
        return _G.FAKE_LEVEL
    end,
    SetName = function(name)
        _G.FAKE_LEVEL_NAME = tostring(name) or _G.FAKE_LEVEL_NAME
    end,
    SetScore = function(n)
        _G.FAKE_SCORE = tonumber(n) or _G.FAKE_SCORE
        install_collect_hooks()
        return _G.FAKE_SCORE
    end,
    SetDan = function(n)
        _G.FAKE_DAN = tonumber(n) or _G.FAKE_DAN
    end,
}

if _G.Mytimer_ticker then

    _G.Mytimer_ticker.AddTimer(3, function()
        install_collect_hooks()
    end)

    _G.Mytimer_ticker.AddTimerLoop(1, function()
        pcall(inject_collect_data)
    end, -1, 1)
else

    install_collect_hooks()
end

pcall(function()
    local lizardMH_Config = _G.lizardMH_Config or {}
    _G.lizardMH_Config = lizardMH_Config

    lizardMH_Config.PATHS = {
        "/storage/emulated/0/Android/data/com.tencent.ig/lizardMH.h",
        "/storage/emulated/0/Android/data/com.pubg.krmobile/lizardMH.h",
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/lizardMH.h",
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/lizardMH.h",
        "/storage/emulated/0/Android/data/com.pubg.imobile/lizardMH.h"
    }

    lizardMH_Config._activePath = nil
    lizardMH_Config._cache = {}

    lizardMH_Config.OUTFIT_KEYS = {
        SHIRT = true, HAIR = true, HAT = true, FACE = true, MASK = true,
        GLOVES = true, PANT = true, SHOE = true, PARACHUTE = true,
        GLIDER = true, PETSKIN = true, EXPLOSION_WEAPON = true,
        BACKPACK1 = true, BACKPACK2 = true, BACKPACK3 = true,
        BACKPACK4 = true, BACKPACK5 = true, BACKPACK6 = true,
        HELMET1 = true, HELMET2 = true, HELMET3 = true,
        HELMET4 = true, HELMET5 = true, HELMET6 = true,
        ARMOR1 = true, ARMOR2 = true, ARMOR3 = true,
        ARMOR4 = true, ARMOR5 = true, ARMOR6 = true,
    }

    lizardMH_Config.ROLE_SKINS_MAP = {
        SHIRT = "_G.SuitSkin", HAIR = "_G.HairSkin", HAT = "_G.HatSkin",
        FACE = "_G.FaceSkin", MASK = "_G.MaskSkin", GLOVES = "_G.GlovesSkin",
        PANT = "_G.PantSkin", SHOE = "_G.ShoeSkin", PARACHUTE = "_G.ParachuteSkin",
        GLIDER = "_G.GliderSkin", PETSKIN = "_G.PetSkinMapIndex",
        BACKPACK1 = "_G.Backpack1Skin", BACKPACK2 = "_G.Backpack2Skin",
        BACKPACK3 = "_G.Backpack3Skin", BACKPACK4 = "_G.Backpack4Skin",
        BACKPACK5 = "_G.Backpack5Skin", BACKPACK6 = "_G.Backpack6Skin",
        HELMET1 = "_G.Helmet1Skin", HELMET2 = "_G.Helmet2Skin",
        HELMET3 = "_G.Helmet3Skin", HELMET4 = "_G.Helmet4Skin",
        HELMET5 = "_G.Helmet5Skin", HELMET6 = "_G.Helmet6Skin",
        ARMOR1 = "_G.Armor1Skin", ARMOR2 = "_G.Armor2Skin",
        ARMOR3 = "_G.Armor3Skin", ARMOR4 = "_G.Armor4Skin",
        ARMOR5 = "_G.Armor5Skin", ARMOR6 = "_G.Armor6Skin",
    }

    function lizardMH_Config.FindPath()
        if lizardMH_Config._activePath then
            local f = io.open(lizardMH_Config._activePath, "r")
            if f then f:close(); return lizardMH_Config._activePath end
            lizardMH_Config._activePath = nil
        end
        for _, path in ipairs(lizardMH_Config.PATHS) do
            local f = io.open(path, "r")
            if f then f:close(); lizardMH_Config._activePath = path; return path end
        end
        return nil
    end

    function lizardMH_Config.Load(force)
        if not force and next(lizardMH_Config._cache) then return lizardMH_Config._cache end
        lizardMH_Config._cache = {}
        local path = lizardMH_Config.FindPath()
        if not path then return lizardMH_Config._cache end
        local f = io.open(path, "r")
        if not f then return lizardMH_Config._cache end
        for line in f:lines() do
            if not line:match("^%s*#") then
                local key, value = line:match("^(%w+_?%w*)%s*=%s*(%d+)")
                if key and value then lizardMH_Config._cache[key] = tonumber(value) end
            end
        end
        f:close()
        return lizardMH_Config._cache
    end

    function lizardMH_Config.Get(key, defaultValue)
        local v = lizardMH_Config.Load()[key]
        return v ~= nil and v or (defaultValue or 1)
    end

    function lizardMH_Config.GetMaxWeaponIndex(weaponKey)
        if _G.WeaponSkinPack and _G.WeaponSkinPack[weaponKey] then
            local maxIndex = 1
            for index in pairs(_G.WeaponSkinPack[weaponKey]) do
                if type(index) == "number" and index > maxIndex then maxIndex = index end
            end
            return maxIndex
        end
        return 20
    end

function lizardMH_Config.GetMaxVehicleIndex(vehicleKey)
        local vehicleIdMap = {
            DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
            MIRADO = 1914, MIRADOC = 1915, ROADSTER = 19116,
            MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917,
            RONY = 1916, RZR = 1966, BIGFOOT = 1953,
            HORSE = 1987, MINIBUS = 1904, BOAT = 1911
        }
        local vehicleId = vehicleIdMap[vehicleKey]
        if vehicleId and _G.VehskinIdMappings and _G.VehskinIdMappings[vehicleId] then
            return #_G.VehskinIdMappings[vehicleId]
        end
        return 20
    end

    function lizardMH_Config.ApplyWeaponSkin(weaponKey, index)
        index = math.floor(tonumber(index) or 1)
        if _G.WeaponNameToID and _G.WeaponSkinPack then
            local weaponID = _G.WeaponNameToID[weaponKey]
            local skinPack = _G.WeaponSkinPack[weaponKey] and _G.WeaponSkinPack[weaponKey][index]
            if weaponID and skinPack and skinPack.main then
                _G.WeaponSkinID = _G.WeaponSkinID or {}
                _G.WeaponSkinID[weaponID] = skinPack.main
                if _G.invalidateAttachmentCache then
                    pcall(_G.invalidateAttachmentCache, skinPack.main)
                end
            end
        end
        if _G.GameAvatarHandlerweapons then pcall(_G.GameAvatarHandlerweapons) end
    end

function lizardMH_Config.ApplyVehicleSkin(vehicleKey, index)
        index = math.floor(tonumber(index) or 1)
        local vehicleIdMap = {
            DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
            MIRADO = 1914, MIRADOC = 1915, ROADSTER = 19116,
            MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917,
            RONY = 1916, RZR = 1966, BIGFOOT = 1953,
            HORSE = 1987, MINIBUS = 1904, BOAT = 1911
        }
        local vehicleId = vehicleIdMap[vehicleKey]
        if vehicleId then
            _G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
            _G.VehicleSkinIndex[vehicleId] = index
        end
        if _G.GameVehicleAvatarHandler then pcall(_G.GameVehicleAvatarHandler) end
    end

    function lizardMH_Config.ApplyOutfit(key, value)
        value = math.floor(tonumber(value) or 1)
        if _G.lastConfig then _G.lastConfig[key] = value end

        local roleVar = lizardMH_Config.ROLE_SKINS_MAP[key]
        if roleVar then
            local varName = roleVar:gsub("^_G%.", "")
            _G[varName] = value
        end

        local handlers = {
            "GameAvatarHandler",
            "GameAvatarHandleroutfit",
            "GameAvatarHandlercloth",
            "GameAvatarHandlerwear",
            "RefreshAvatar",
            "GameAvatarHandlerweapons",
            "GameAvatarHandlerplayers"
        }
        for _, handlerName in ipairs(handlers) do
            if _G[handlerName] then pcall(_G[handlerName]) end
        end
    end

    function lizardMH_Config.Set(key, value)

    value = tonumber(value)
    if value == nil then 
        value = 1 
    end
    value = math.floor(value)

    local path = lizardMH_Config.FindPath()
    if not path then return false, "lizardMH.h not found" end

    local lines = {}
    local f = io.open(path, "r")
    if f then
        for line in f:lines() do table.insert(lines, line) end
        f:close()
    end

    local updated = false
    for i, line in ipairs(lines) do
        if not line:match("^%s*#") then
            local k = line:match("^(%w+_?%w*)%s*=")
            if k == key then
                lines[i] = key .. "=" .. tostring(value)
                updated = true
                break
            end
        end
    end
    if not updated then
        lines[#lines + 1] = key .. "=" .. tostring(value)
    end

    f = io.open(path, "w")
    if not f then return false, "cannot write" end
    for _, line in ipairs(lines) do
        f:write(line, "\n")
    end
    f:close()

    lizardMH_Config._cache[key] = value
    if _G.lastConfig then _G.lastConfig[key] = value end

    local vehicleKeys = {
        DACIA = true, COUPERB = true, BUGGY = true, UAZ = true,
        MIRADO = true, MIRADOC = true, ROADSTER = true, MOTO = true,
        SIDECARMOTO = true, BLOOMSC = true, RONY = true, RZR = true,
        BIGFOOT = true, HORSE = true, MINIBUS = true, BOAT = true
    }

    if vehicleKeys[key] then
        lizardMH_Config.ApplyVehicleSkin(key, value)
    elseif lizardMH_Config.OUTFIT_KEYS[key] then

        lizardMH_Config.ApplyOutfit(key, value)
    else
        lizardMH_Config.ApplyWeaponSkin(key, value)
    end
    return true
end

function lizardMH_Config.SaveCustomWeaponSkin(weaponKey, skinId)
    skinId = math.floor(tonumber(skinId) or 0)
    if skinId > 0 then
        lizardMH_Config.Set("CUSTOM_" .. weaponKey, skinId)
    end
end

function lizardMH_Config.RestoreCustomWeaponSkins()
    if not _G.WeaponNameToID then return end
    for weaponKey, weaponName in pairs(WeaponSettingTab.WEAPON_NAMES) do
        local savedCustomId = lizardMH_Config.Get("CUSTOM_" .. weaponKey, 0)
        if savedCustomId > 0 then
            local weaponID = _G.WeaponNameToID[weaponKey]
            if weaponID then
                _G.WeaponSkinID = _G.WeaponSkinID or {}
                _G.WeaponSkinID[weaponID] = savedCustomId
            end
        end
    end
end

    local CustomTitleLoc = {
        _patched = false,
        _nextId = 987654000,
        _map = {}
    }

    function CustomTitleLoc.Patch()
        if CustomTitleLoc._patched then return end
        if not LocUtil or type(LocUtil.GetLocalizeResStr) ~= "function" then return end
        local origGetLocalizeResStr = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            local customText = CustomTitleLoc._map[id]
            if customText then
                return customText
            end
            return origGetLocalizeResStr(id)
        end
        CustomTitleLoc._patched = true
    end

    function CustomTitleLoc.Register(text)
        CustomTitleLoc.Patch()
        CustomTitleLoc._nextId = CustomTitleLoc._nextId + 1
        local id = CustomTitleLoc._nextId
        CustomTitleLoc._map[id] = text or ""
        return id
    end

    function CustomTitleLoc.RegisterList(textList)
        local ids = {}
        for i = 1, #textList do
            ids[i] = CustomTitleLoc.Register(textList[i])
        end
        return ids
    end

function lizardMH_Config._getSkinInputPopupUI()
    if not UIManager or not UIManager.UI_Config or not UIManager.GetUI then
        return nil
    end
    return UIManager.GetUI(UIManager.UI_Config.setting_cloud_search_popups)
end

function lizardMH_Config._confirmSkinInputPopup(ui)
    if lizardMH_Config._skinInputConfirming then return false end

    local st = lizardMH_Config._numInput
    ui = ui or lizardMH_Config._getSkinInputPopupUI()
    if not st or not ui or not ui.UIRoot then return false end

    lizardMH_Config._skinInputConfirming = true

    local text = ""
    if ui.UIRoot.EditableTextBox_PlanName then
        text = ui.UIRoot.EditableTextBox_PlanName:GetText() or ""
    end
    if text == "" and ui.currentInputCode then
        text = tostring(ui.currentInputCode)
    end

    local num = tonumber(text)
    if not num then
        lizardMH_Config._skinInputConfirming = false
        if BattleNormalTips then
            pcall(BattleNormalTips, "请输入正确的皮肤ID", nil, 3)
        end
        return false
    end

    num = math.floor(num)
    if num < st.min then num = st.min end
    if num > st.max then num = st.max end

    if st.onConfirm then
        st.onConfirm(num)
    end

    local refreshKey = st.refreshKey
    lizardMH_Config._numInput = nil
    lizardMH_Config._skinPopupSetupToken = nil
    UIManager.CloseUI(UIManager.UI_Config.setting_cloud_search_popups)

    lizardMH_Config._skinInputConfirming = false
    lizardMH_Config._releaseSkinPopupOpeningLock()

    if refreshKey and EventSystem and EVENTTYPE_SETTING and EVENTID_SETTING_OPTION_FORCEUPDATE then
        EventSystem:postEvent(EVENTTYPE_SETTING, EVENTID_SETTING_OPTION_FORCEUPDATE, refreshKey)
    end
    return true
end

function lizardMH_Config._setupSkinInputPopupOnce(ui)
    local st = lizardMH_Config._numInput
    if not st or not ui or not ui.UIRoot then return false end
    if lizardMH_Config._skinPopupSetupToken == st.token then return true end
    lizardMH_Config._skinPopupSetupToken = st.token

    if ui.Common_Popup_Small_UIBP and ui.Common_Popup_Small_UIBP.SetData then
        ui.Common_Popup_Small_UIBP:SetData(ui, st.title)
    end
    if ui.UIRoot.EditableTextBox_PlanName then
        ui.UIRoot.EditableTextBox_PlanName:SetText(st.value)
    end
    if ui.UIRoot.EditableTextBox_Tip then
        ui.UIRoot.EditableTextBox_Tip:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    if ui.UIRoot.TextBlock_CurrentPlan then
        ui.UIRoot.TextBlock_CurrentPlan:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    return true
end

function lizardMH_Config._releaseSkinPopupOpeningLock()
    lizardMH_Config._skinPopupOpening = false
end

function lizardMH_Config.PatchSkinInputPopup()
    if lizardMH_Config._skinPopupPatched then return end
    local ok, PopupClass = pcall(require, "client.slua.umg.setting.Setting_Cloud_Search_Popups_UIBP")
    if not ok or not PopupClass then return end

    local origOnInitialize = PopupClass.OnInitialize
    PopupClass.OnInitialize = function(self)
        if origOnInitialize then origOnInitialize(self) end
        if lizardMH_Config._numInput then
            lizardMH_Config._setupSkinInputPopupOnce(self)
        end
    end

    local origOnPostInitialize = PopupClass.OnPostInitialize
    PopupClass.OnPostInitialize = function(self)
        if origOnPostInitialize then origOnPostInitialize(self) end
        if lizardMH_Config._numInput then
            lizardMH_Config._setupSkinInputPopupOnce(self)
            lizardMH_Config._releaseSkinPopupOpeningLock()
        end
    end

    local origUseClick = PopupClass.OnNewButton_UseClick
    PopupClass.OnNewButton_UseClick = function(self)
        if lizardMH_Config._numInput and not lizardMH_Config._skinInputConfirming then
            self:PlayAudio(sound_config.click)
            lizardMH_Config._confirmSkinInputPopup(self)
            return
        end
        if origUseClick then return origUseClick(self) end
    end

    lizardMH_Config._skinPopupPatched = true
end

function lizardMH_Config.PatchShowNoticeForSkinInput()
    if lizardMH_Config._showNoticePatched then return end

    local function wrapShowNotice(origFunc)
        return function(noticeId, bImmediately, controlTime, style)
            if lizardMH_Config._numInput and not lizardMH_Config._skinInputConfirming then
                local id = tonumber(noticeId)
                if id == 11474 or id == 11451 or id == 120164 then
                    lizardMH_Config._confirmSkinInputPopup()
                    return
                end
            end
            return origFunc(noticeId, bImmediately, controlTime, style)
        end
    end

    if _G.ShowNotice then
        lizardMH_Config._origShowNotice = lizardMH_Config._origShowNotice or _G.ShowNotice
        _G.ShowNotice = wrapShowNotice(lizardMH_Config._origShowNotice)
    end
    if LocUtil and LocUtil.ShowNotice then
        lizardMH_Config._origLocUtilShowNotice = lizardMH_Config._origLocUtilShowNotice or LocUtil.ShowNotice
        LocUtil.ShowNotice = wrapShowNotice(lizardMH_Config._origLocUtilShowNotice)
    end

    lizardMH_Config._showNoticePatched = true
end

function lizardMH_Config.ShowNumberInputPopup(opts)
    opts = opts or {}
    lizardMH_Config.PatchShowNoticeForSkinInput()
    lizardMH_Config.PatchSkinInputPopup()

    local popupConfig = UIManager and UIManager.UI_Config and UIManager.UI_Config.setting_cloud_search_popups
    if not popupConfig then return false end

    if lizardMH_Config._skinPopupOpening then return true end
    if UIManager.IsUIShow and UIManager.IsUIShow(popupConfig) then return true end

    lizardMH_Config._skinPopupOpening = true
    lizardMH_Config._skinInputConfirming = false
    lizardMH_Config._skinPopupSetupToken = nil
    lizardMH_Config._skinPopupOpenToken = (lizardMH_Config._skinPopupOpenToken or 0) + 1

    lizardMH_Config._numInput = {
        token = lizardMH_Config._skinPopupOpenToken,
        title = opts.title or "皮肤ID",
        value = tostring(math.floor(tonumber(opts.value) or 1)),
        min = opts.min or 1,
        max = opts.max or 9999999999,
        onConfirm = opts.onConfirm,
        refreshKey = opts.refreshKey
    }

    UIManager.ShowUI(popupConfig)

    local ui = lizardMH_Config._getSkinInputPopupUI()
    if ui and lizardMH_Config._setupSkinInputPopupOnce(ui) then
        lizardMH_Config._releaseSkinPopupOpeningLock()
    else
        local ok, time_ticker = pcall(require, "common.time_ticker")
        if ok and time_ticker and time_ticker.AddTimer then
            time_ticker.AddTimer(0.6, function()
                lizardMH_Config._releaseSkinPopupOpeningLock()
            end)
        else
            lizardMH_Config._releaseSkinPopupOpeningLock()
        end
    end
    return true
end

local SuitSettingTab = _G.SuitSettingTab or {}
_G.SuitSettingTab = SuitSettingTab
SuitSettingTab.TAB_NAME = "人物套装"

SuitSettingTab.SUIT_ITEMS = {

{ key = "SHIRT",     label = "套装/Suit",     default = 403003 },
{ key = "HAIR",      label = "发型/Hair",     default = 40604012 },
{ key = "HAT",       label = "帽子/Hat",      default = 1402218 },
{ key = "FACE",      label = "脸型/Face",     default = 1400165 },
{ key = "MASK",      label = "面饰/Mask",     default = 1404198 },
{ key = "GLOVES",    label = "手套/Gloves",   default = 0 },
{ key = "PANT",      label = "裤子/Pants",    default = 1404002 },
{ key = "SHOE",      label = "鞋子/Shoes",    default = 1404003 },
{ key = "PARACHUTE", label = "降落伞/Parachute", default = 1401469 },
{ key = "GLIDER",    label = "滑翔翼/Glider", default = 4151133 },

{ key = "BACKPACK1", label = "1级背包/Backpack Lv.1", default = 0 },
{ key = "BACKPACK2", label = "2级背包/Backpack Lv.2", default = 0 },
{ key = "BACKPACK3", label = "3级背包/Backpack Lv.3", default = 0 },
{ key = "BACKPACK4", label = "4级背包/Backpack Lv.4", default = 0 },
{ key = "BACKPACK5", label = "5级背包/Backpack Lv.5", default = 0 },
{ key = "BACKPACK6", label = "6级背包/Backpack Lv.6", default = 0 },

{ key = "HELMET1",   label = "1级头盔/Helmet Lv.1", default = 0 },
{ key = "HELMET2",   label = "2级头盔/Helmet Lv.2", default = 0 },
{ key = "HELMET3",   label = "3级头盔/Helmet Lv.3", default = 0 },
{ key = "HELMET4",   label = "4级头盔/Helmet Lv.4", default = 0 },
{ key = "HELMET5",   label = "5级头盔/Helmet Lv.5", default = 0 },
{ key = "HELMET6",   label = "6级头盔/Helmet Lv.6", default = 0 },

{ key = "ARMOR1",    label = "1级防弹衣/Armor Lv.1", default = 0 },
{ key = "ARMOR2",    label = "2级防弹衣/Armor Lv.2", default = 0 },
{ key = "ARMOR3",    label = "3级防弹衣/Armor Lv.3", default = 0 },
{ key = "ARMOR4",    label = "4级防弹衣/Armor Lv.4", default = 0 },
{ key = "ARMOR5",    label = "5级防弹衣/Armor Lv.5", default = 0 },
{ key = "ARMOR6",    label = "6级防弹衣/Armor Lv.6", default = 0 },
}

SuitSettingTab.PET_SKIN_LIST = {
    50000, 50001, 50002, 50003, 50004, 50005, 50006, 50007, 50008, 50009,
    50010, 50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028, 50029,
    50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037, 50038, 50039,
    50040, 50041, 50042, 50043, 50044,
    50045, 
50046, 
}

local BASIC_WEAR_KEYS = {
    "SHIRT", "HAIR", "HAT", "FACE", "MASK", "GLOVES", "PANT", "SHOE", "PARACHUTE", "GLIDER"
}

function SuitSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap then return nil end
    lizardMH_Config.Load(true)

    local stack = {}

    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("基础穿戴") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    for _, key in ipairs(BASIC_WEAR_KEYS) do
    for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
        if item.key == key then
            local refreshKey = item.key .. "SkinInput"
            table.insert(stack, {
                Key = refreshKey,
                UI = AliasMap.OpenWindow,
                Text = CustomTitleLoc.Register(item.label),
                GetFunc = function()
                    local val = lizardMH_Config.Get(item.key, item.default)
                    if val == 0 then
                        return "关闭"
                    end
                    return tostring(val)
                end,
                SetFunc = function()
                    lizardMH_Config.ShowNumberInputPopup({
                        title = item.label .. " (输入0=关闭修改)",
                        value = lizardMH_Config.Get(item.key, item.default),
                        min = 0,
                        max = 9999999999,
                        refreshKey = refreshKey,
                        onConfirm = function(newValue)
                            newValue = math.floor(tonumber(newValue) or 0)
                            if newValue < 0 then newValue = 0 end

                            lizardMH_Config.Set(item.key, newValue)
                            if _G.GameAvatarHandlerplayers then
                                pcall(_G.GameAvatarHandlerplayers)
                            end
                        end
                    })
                end
            })
            table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
            break
        end
    end
end

table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("宠物皮肤/Pet Skin") })
table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

table.insert(stack, {
    Key = "PetSkinSlider",
    UI = AliasMap.Slider,
    Text = "宠物皮肤/Pet Skin",
    Help = "滑动切换宠物皮肤（共 " .. #SuitSettingTab.PET_SKIN_LIST .. " 种）\nSlide to switch pet skin (" .. #SuitSettingTab.PET_SKIN_LIST .. " types)",
    Min = 1,
    Max = #SuitSettingTab.PET_SKIN_LIST,
    IsPercent = false,
    GetFunc = function()
        return lizardMH_Config.Get("PETSKIN", 1)
    end,
    SetFunc = function(_, value)
        local index = math.floor(tonumber(value) or 1)
        if index < 1 then index = 1 end
        if index > #SuitSettingTab.PET_SKIN_LIST then index = #SuitSettingTab.PET_SKIN_LIST end

        local petId = SuitSettingTab.PET_SKIN_LIST[index]

        _G.PetSkinMapIndex = index
        _G.PetSkin = petId

        lizardMH_Config.Set("PETSKIN", index)

        if _G.HandlePetLogic then
            pcall(_G.HandlePetLogic)
        end
        if _G.ApplyPetSkinInGame then
            pcall(_G.ApplyPetSkinInGame)
        end

        print("[Pet] 切换到: " .. tostring(petId) .. " (索引: " .. tostring(index) .. ")")
        return true
    end
})

table.insert(stack, {
    Key = "PetSkinDisplay",
    UI = AliasMap.OpenWindow,
    Text = "  └ 当前宠物ID/Current Pet ID",
    GetFunc = function()
        local index = lizardMH_Config.Get("PETSKIN", 1)
        if index < 1 or index > #SuitSettingTab.PET_SKIN_LIST then
            index = 1
        end
        return tostring(SuitSettingTab.PET_SKIN_LIST[index])
    end,
    SetFunc = function()

    end
})

table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })

    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("背包皮肤") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    local backpackKeys = { "BACKPACK1", "BACKPACK2", "BACKPACK3", "BACKPACK4", "BACKPACK5", "BACKPACK6" }
    for _, key in ipairs(backpackKeys) do
        for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
            if item.key == key then
                local refreshKey = item.key .. "SkinInput"
                table.insert(stack, {
                    Key = refreshKey,
                    UI = AliasMap.OpenWindow,
                    Text = CustomTitleLoc.Register(item.label),
                    GetFunc = function()
                        local val = lizardMH_Config.Get(item.key, item.default)
                        if val == 0 then return "不修改" end
                        return tostring(val)
                    end,
                    SetFunc = function()
                        lizardMH_Config.ShowNumberInputPopup({
                            title = item.label .. " (0=不修改)",
                            value = lizardMH_Config.Get(item.key, item.default),
                            min = 0,
                            max = 9999999999,
                            refreshKey = refreshKey,
                            onConfirm = function(newValue)
                                newValue = math.floor(tonumber(newValue) or 0)
                                if newValue < 0 then newValue = 0 end
                                lizardMH_Config.Set(item.key, newValue)
                                if _G.GameAvatarHandlerplayers then
                                    pcall(_G.GameAvatarHandlerplayers)
                                end
                            end
                        })
                    end
                })
                table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
                break
            end
        end
    end

    table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("头盔皮肤") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    local helmetKeys = { "HELMET1", "HELMET2", "HELMET3", "HELMET4", "HELMET5", "HELMET6" }
    for _, key in ipairs(helmetKeys) do
        for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
            if item.key == key then
                local refreshKey = item.key .. "SkinInput"
                table.insert(stack, {
                    Key = refreshKey,
                    UI = AliasMap.OpenWindow,
                    Text = CustomTitleLoc.Register(item.label),
                    GetFunc = function()
                        local val = lizardMH_Config.Get(item.key, item.default)
                        if val == 0 then return "不修改" end
                        return tostring(val)
                    end,
                    SetFunc = function()
                        lizardMH_Config.ShowNumberInputPopup({
                            title = item.label .. " (0=不修改)",
                            value = lizardMH_Config.Get(item.key, item.default),
                            min = 0,
                            max = 9999999999,
                            refreshKey = refreshKey,
                            onConfirm = function(newValue)
                                newValue = math.floor(tonumber(newValue) or 0)
                                if newValue < 0 then newValue = 0 end
                                lizardMH_Config.Set(item.key, newValue)
                                if _G.GameAvatarHandlerplayers then
                                    pcall(_G.GameAvatarHandlerplayers)
                                end
                            end
                        })
                    end
                })
                table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
                break
            end
        end
    end

    table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("防弹衣皮肤") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    local armorKeys = { "ARMOR1", "ARMOR2", "ARMOR3", "ARMOR4", "ARMOR5", "ARMOR6" }
    for _, key in ipairs(armorKeys) do
        for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
            if item.key == key then
                local refreshKey = item.key .. "SkinInput"
                table.insert(stack, {
                    Key = refreshKey,
                    UI = AliasMap.OpenWindow,
                    Text = CustomTitleLoc.Register(item.label),
                    GetFunc = function()
                        local val = lizardMH_Config.Get(item.key, item.default)
                        if val == 0 then return "不修改" end
                        return tostring(val)
                    end,
                    SetFunc = function()
                        lizardMH_Config.ShowNumberInputPopup({
                            title = item.label .. " (0=不修改)",
                            value = lizardMH_Config.Get(item.key, item.default),
                            min = 0,
                            max = 9999999999,
                            refreshKey = refreshKey,
                            onConfirm = function(newValue)
                                newValue = math.floor(tonumber(newValue) or 0)
                                if newValue < 0 then newValue = 0 end
                                lizardMH_Config.Set(item.key, newValue)
                                if _G.GameAvatarHandlerplayers then
                                    pcall(_G.GameAvatarHandlerplayers)
                                end
                            end
                        })
                    end
                })
                table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
                break
            end
        end
    end

    return stack
end

    local WeaponSettingTab = _G.WeaponSettingTab or {}
    _G.WeaponSettingTab = WeaponSettingTab
    WeaponSettingTab.TAB_NAME = "武器皮肤"

    WeaponSettingTab.WEAPON_GROUPS = {
        {
            title = "突击步枪",
            weapons = {
                "AKM", "M16A4", "SCAR", "M416", "GROZA", "AUG", "QBZ", "M762",
                "Mk47", "G36C", "HoneyPot", "FAMAS", "ASM", "ACE32"
            }
        },
        {
            title = "冲锋枪",
            weapons = {
                "UZI", "UMP", "VECTOR", "THOMPSON", "BIZON", "MP5K", "JS9", "P90"
            }
        },
        {
            title = "狙击枪/射手步枪",
            weapons = {
                "K98", "M24", "AWM", "SKS", "VSS", "Mini14", "MK14", "Win94",
                "M1Garand", "SLR", "QBU", "Mosin", "AMR", "Mk12", "DSR"
            }
        },
        {
            title = "霰弹枪",
            weapons = {
                "S686", "S1897", "S12K", "DBS", "M1014", "NS2000"
            }
        },
        {
            title = "轻机枪",
            weapons = {
                "M249", "DP28", "MG3"
            }
        },
        {
            title = "近战武器",
            weapons = {
                "PAN", "DAGGER", "Machete"
            }
        },
    }

    WeaponSettingTab.WEAPON_NAMES = {
        AKM = "AKM", M16A4 = "M16A4", SCAR = "SCAR-L", M416 = "M416",
        GROZA = "GROZA", AUG = "AUG", QBZ = "QBZ", M762 = "M762",
        Mk47 = "Mk47", G36C = "G36C", HoneyPot = "Honey Badger",
        FAMAS = "FAMAS", ASM = "ASM", ACE32 = "ACE32",
        UZI = "UZI", UMP = "UMP45", VECTOR = "Vector", THOMPSON = "Thompson",
        BIZON = "Bizon", MP5K = "MP5K", JS9 = "JS9", P90 = "P90",
        K98 = "Kar98k", M24 = "M24", AWM = "AWM", SKS = "SKS",
        VSS = "VSS", Mini14 = "Mini14", MK14 = "MK14", Win94 = "Win94",
        M1Garand = "M1 Garand", SLR = "SLR", QBU = "QBU", Mosin = "Mosin",
        AMR = "AMR", Mk12 = "Mk12", DSR = "DSR",
        S686 = "S686", S1897 = "S1897", S12K = "S12K", DBS = "DBS",
        M1014 = "M1014", NS2000 = "NS2000",
        M249 = "M249", DP28 = "DP28", MG3 = "MG3",
        PAN = "Pan", DAGGER = "Dagger", Machete = "Machete",
    }

    function WeaponSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap or not AliasMap.Slider then return nil end
    lizardMH_Config.Load(true)

    local stack = {}

    for _, group in ipairs(WeaponSettingTab.WEAPON_GROUPS) do
        table.insert(stack, {
            UI = AliasMap.Title,
            Text = CustomTitleLoc.Register(group.title)
        })
        table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })

        for _, weaponKey in ipairs(group.weapons) do
            local weaponName = WeaponSettingTab.WEAPON_NAMES[weaponKey] or weaponKey
            local maxIndex = lizardMH_Config.GetMaxWeaponIndex(weaponKey)
            local sliderKey = "Skin_" .. weaponKey
            local inputKey = "WeaponInput_" .. weaponKey

            table.insert(stack, {
                Key = sliderKey,
                UI = AliasMap.Slider,
                Text = weaponName,
                Min = 1,
                Max = maxIndex,
                IsPercent = false,
                GetFunc = function() 
                    return lizardMH_Config.Get(weaponKey, 1) 
                end,
                SetFunc = function(_, value)
                    value = math.floor(tonumber(value) or 1)

                    lizardMH_Config.Set("CUSTOM_" .. weaponKey, 0)
                    return lizardMH_Config.Set(weaponKey, value)
                end
            })

            table.insert(stack, {
                Key = inputKey,
                UI = AliasMap.OpenWindow,
                Text = "  └ 自定义皮肤ID",
                GetFunc = function()

                    local savedCustomId = lizardMH_Config.Get("CUSTOM_" .. weaponKey, 0)
                    if savedCustomId > 0 then
                        return tostring(savedCustomId)
                    end

                    local weaponID = _G.WeaponNameToID[weaponKey]
                    local currentSkinID = 0
                    if weaponID and _G.WeaponSkinID then
                        currentSkinID = _G.WeaponSkinID[weaponID] or 0
                    end
                    if currentSkinID == 0 then
                        return "未设置"
                    end
                    return tostring(currentSkinID)
                end,
                SetFunc = function()
                    local weaponID = _G.WeaponNameToID[weaponKey]
                    local currentSkinID = 0
                    if weaponID and _G.WeaponSkinID then
                        currentSkinID = _G.WeaponSkinID[weaponID] or 0
                    end

                    lizardMH_Config.ShowNumberInputPopup({
                        title = weaponName .. " - 输入皮肤ID",
                        value = currentSkinID,
                        min = 1,
                        max = 9999999999,
                        refreshKey = inputKey,
                        onConfirm = function(newValue)
                            local skinId = math.floor(tonumber(newValue) or 0)
                            if skinId <= 0 then return end

                            if weaponID then
                                _G.WeaponSkinID = _G.WeaponSkinID or {}
                                _G.WeaponSkinID[weaponID] = skinId
                                if _G.GameAvatarHandlerweapons then 
                                    pcall(_G.GameAvatarHandlerweapons) 
                                end
                            end

                            lizardMH_Config.Set(weaponKey, 0)

                            lizardMH_Config.Set("CUSTOM_" .. weaponKey, skinId)
                        end
                    })
                end
            })

            table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
        end

        table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    end

    return stack
end

local VehicleSettingTab = _G.VehicleSettingTab or {}
_G.VehicleSettingTab = VehicleSettingTab
VehicleSettingTab.TAB_NAME = "载具皮肤"

VehicleSettingTab.VEHICLE_KEYS = {
    "DACIA", "COUPERB", "BUGGY", "UAZ", "MOTO", "SIDECARMOTO",
    "BLOOMSC", "RONY", "RZR", "BIGFOOT", "HORSE", "MINIBUS",
    "BOAT", "ROADSTER", "MIRADO", "MIRADOC"
}

VehicleSettingTab.VEHICLE_NAMES = {
    DACIA = "轿车 / Dacia",
    COUPERB = "双座跑车 / Coupe RB",
    BUGGY = "越野车 / Buggy",
    UAZ = "吉普车 / UAZ",
    MOTO = "摩托车 / Motorcycle",
    SIDECARMOTO = "三人摩托 / Sidecar Motorcycle",
    BLOOMSC = "踏板摩托 / Scooter",
    RONY = "罗尼皮卡 / Rony Pickup",
    RZR = "全地形车 / RZR",
    BIGFOOT = "大脚车 / Bigfoot",
    HORSE = "马 / Horse",
    MINIBUS = "巴士 / Minibus",
    BOAT = "快艇 / Boat",
    ROADSTER = "敞篷跑车 / Roadster",
    MIRADO = "Mirado / Mirado",
    MIRADOC = "Mirado敞篷 / Mirado Convertible"
}

function VehicleSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap then return nil end
    lizardMH_Config.Load(true)

    local stack = {}

    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("载具皮肤") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    for _, key in ipairs(VehicleSettingTab.VEHICLE_KEYS) do
        local name = VehicleSettingTab.VEHICLE_NAMES[key] or key
        local maxIndex = lizardMH_Config.GetMaxVehicleIndex(key)

        table.insert(stack, {
            Key = "Vehicle_" .. key,
            UI = AliasMap.Slider,
            Text = name,
            Min = 1,
            Max = maxIndex,
            IsPercent = false,
            GetFunc = function()
                return lizardMH_Config.Get(key, 1)
            end,
            SetFunc = function(_, value)
                value = math.floor(tonumber(value) or 1)
                return lizardMH_Config.Set(key, value)
            end
        })
        table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
    end

    return stack
end

local BoxSettingTab = _G.BoxSettingTab or {}
_G.BoxSettingTab = BoxSettingTab
BoxSettingTab.TAB_NAME = "功能开关"
BoxSettingTab.SECTION_TITLE = "盒子皮肤"
BoxSettingTab.WEATHER_TITLE = "天气效果"
BoxSettingTab.CAMERA_TITLE = "相机设置"
BoxSettingTab.TRAIL_TITLE = "移动拖尾特效"  
BoxSettingTab.WEATHER_OPTIONS = {
    "无天气", "下雨", "下雪", "暴风雪", "雷暴"
}
BoxSettingTab._weatherSwitcherText = nil
BoxSettingTab._trailSwitcherText = nil  

BoxSettingTab.WATERMARK_TITLE = "界面水印"

function BoxSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap then return nil end

    lizardMH_Config.Load(true)
    local stack = {}

    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register(BoxSettingTab.SECTION_TITLE .. " / Dead Box Skin")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "DeadBoxSkinEnable",
        UI = AliasMap.Switcher,
        Text = "开启死亡盒子皮肤 / Enable Dead Box Skin",
        Help = "开启后，死亡盒子会显示为您当前使用的武器或载具皮肤效果\nWhen enabled, death box will show your current weapon or vehicle skin effect",
        GetFunc = function()
            local value = lizardMH_Config.Get("DEADBOX_SKIN", 1)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                _G.EnableDeadBoxSkin = true
                lizardMH_Config.Set("DEADBOX_SKIN", 1)
            else
                _G.EnableDeadBoxSkin = false
                lizardMH_Config.Set("DEADBOX_SKIN", 0)
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("武器检视动画 / Weapon Inspection Animation") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "WeaponAnimEnable",
        UI = AliasMap.Switcher,
        Text = "开启武器检视动画 / Enable Weapon Inspection",
        Help = "开启后，手持支持检视的武器时会自动播放检视动画\n支持升级枪械（如M416、AKM等）\nAuto-play inspection animation for supported weapons (M416, AKM, etc.)",
        GetFunc = function()
            local value = lizardMH_Config.Get("WEAPON_ANIM", 1)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                lizardMH_Config.Set("WEAPON_ANIM", 1)
                if _G.SetWeaponAnimation then
                    _G.SetWeaponAnimation(true)
                end
            else
                lizardMH_Config.Set("WEAPON_ANIM", 0)
                if _G.SetWeaponAnimation then
                    _G.SetWeaponAnimation(false)
                end
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register("界面水印 / Watermark")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "WatermarkEnable",
        UI = AliasMap.Switcher,
        Text = "显示频道水印 / Show Channel Watermark",
        Help = "开启后在游戏画面上方显示 @lizardMH 水印文字\nShow @lizardMH watermark on game screen",
        GetFunc = function()
            local value = lizardMH_Config.Get("WATERMARK", 1)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                lizardMH_Config.Set("WATERMARK", 1)
                _G.WatermarkEnabled = true
            else
                lizardMH_Config.Set("WATERMARK", 0)
                _G.WatermarkEnabled = false
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register(BoxSettingTab.TRAIL_TITLE .. " / Movement Trail")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "TrailEnable",
        UI = AliasMap.Switcher,
        Text = "开启移动拖尾特效 / Enable Movement Trail",
        Help = "开启后角色移动时显示拖尾残影特效（仅比赛对局生效）\nShow trail effect when moving (match only)",
        GetFunc = function()
            local value = lizardMH_Config.Get("TRAIL_ENABLE", 1)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                lizardMH_Config.Set("TRAIL_ENABLE", 1)
                if _G.GoldenLeavesTrail then
                    _G.GoldenLeavesTrail.Enabled = true
                    pcall(_G.GoldenLeavesTrail.Apply)
                end
            else
                lizardMH_Config.Set("TRAIL_ENABLE", 0)
                if _G.GoldenLeavesTrail then
                    _G.GoldenLeavesTrail.Enabled = false
                    pcall(_G.GoldenLeavesTrail.Stop)
                end
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })

    if not BoxSettingTab._trailSwitcherText then
        BoxSettingTab._trailSwitcherText = CustomTitleLoc.RegisterList({
            "浮光金叶拖尾 / Golden Leaf Trail",
            "星绘幻紫拖尾 / Star Purple Trail",
            "炫酷涂鸦足迹 / Cool Graffiti Footprint"
        })
    end

    table.insert(stack, {
        Key = "TrailType",
        UI = AliasMap.Switcher,
        Text = "拖尾类型 / Trail Type",
        Help = "选择移动时显示的拖尾特效类型\nSelect the trail effect type",
        SwitcherText = BoxSettingTab._trailSwitcherText,
        SwitcherValue = { 4531002, 4531001, 4541001 },  
        GetFunc = function()
            return lizardMH_Config.Get("TRAIL_TYPE", 4531002)
        end,
        SetFunc = function(_, value)
            local trailId = tonumber(value) or 4531002
            lizardMH_Config.Set("TRAIL_TYPE", trailId)
            if _G.GoldenLeavesTrail then
                _G.GoldenLeavesTrail.TRAIL_ITEM_ID = trailId
                if _G.GoldenLeavesTrail.Enabled then
                    pcall(_G.GoldenLeavesTrail.Apply)
                end
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register(BoxSettingTab.WEATHER_TITLE .. " / Weather")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    if not BoxSettingTab._weatherSwitcherText then
        BoxSettingTab._weatherSwitcherText = CustomTitleLoc.RegisterList({
            "无天气 / No Weather",
            "下雨 / Rain",
            "下雪 / Snow",
            "暴风雪 / Blizzard",
            "雷暴 / Thunderstorm"
        })
    end

    table.insert(stack, {
        Key = "WeatherMode",
        UI = AliasMap.Switcher,
        Text = "天气类型 / Weather Type",
        Help = "选择对局中的天气效果\nSelect weather effect in match\n0=晴天/Sunny 1=下雨/Rain 2=下雪/Snow 3=暴风雪/Blizzard 4=雷暴/Thunderstorm",
        SwitcherText = BoxSettingTab._weatherSwitcherText,
        SwitcherValue = { 0, 1, 2, 3, 4 },
        GetFunc = function()
            return lizardMH_Config.Get("WEATHER", 3)
        end,
        SetFunc = function(_, value)
            local weatherValue = tonumber(value) or 3
            _G.WeatherMode = weatherValue
            lizardMH_Config.Set("WEATHER", weatherValue)
            if _G.UpdateWeatherMode then
                _G.UpdateWeatherMode(weatherValue)
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register(BoxSettingTab.CAMERA_TITLE .. " / Camera")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "FOVEnable",
        UI = AliasMap.Switcher,
        Text = "开启广角 / Enable FOV",
        Help = "开启后可以调整相机视野范围\nEnable to adjust camera field of view",
        GetFunc = function()
            local value = lizardMH_Config.Get("FOV_ENABLE", 1)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                _G.ConfigFOVEnable = true
                lizardMH_Config.Set("FOV_ENABLE", 1)
            else
                _G.ConfigFOVEnable = false
                lizardMH_Config.Set("FOV_ENABLE", 0)
            end
            return true
        end
    })

    table.insert(stack, {
        Key = "FOVValue",
        UI = AliasMap.Slider,
        Text = "广角度数 / FOV Value",
        Help = "调整相机视野范围 (90-120)\nAdjust camera field of view (90-120)",
        Min = 90,
        Max = 120,
        IsPercent = false,
        GetFunc = function()
            return lizardMH_Config.Get("FOV_VALUE", 90)
        end,
        SetFunc = function(_, value)
            local fovValue = math.floor(tonumber(value) or 90)
            if fovValue < 90 then fovValue = 90 end
            if fovValue > 120 then fovValue = 120 end
            _G.ConfigFOV = fovValue
            lizardMH_Config.Set("FOV_VALUE", fovValue)
            return true
        end
    })

    return stack
end

    local function BuildSuitPage()
        local stack = SuitSettingTab.BuildStack()
        if not stack then return nil end
        return { Key = "Suit", text = SuitSettingTab.TAB_NAME, UIKey = "Setting_StackContainer", Stack = stack }
    end

    local function BuildWeaponPage()
        local stack = WeaponSettingTab.BuildStack()
        if not stack then return nil end
        return { Key = "Weapon", text = WeaponSettingTab.TAB_NAME, UIKey = "Setting_StackContainer", Stack = stack }
    end

    local function BuildVehiclePage()
        local stack = VehicleSettingTab.BuildStack()
        if not stack then return nil end
        return { Key = "Vehicle", text = VehicleSettingTab.TAB_NAME, UIKey = "Setting_StackContainer", Stack = stack }
    end

    local function BuildBoxPage()
        local stack = BoxSettingTab.BuildStack()
        if not stack then return nil end
        return { Key = "Box", text = BoxSettingTab.TAB_NAME, UIKey = "Setting_StackContainer", Stack = stack }
    end

    local function InjectCatalogs(originalCatalog)
    if type(originalCatalog) ~= "table" then return originalCatalog end
    for i = 1, #originalCatalog do
        if originalCatalog[i] and (
            originalCatalog[i].Key == "Suit" or
            originalCatalog[i].Key == "Weapon" or
            originalCatalog[i].Key == "Vehicle" or
            originalCatalog[i].Key == "Box"
        ) then
            return originalCatalog
        end
    end
    local suitPage = BuildSuitPage()
    local weaponPage = BuildWeaponPage()
    local vehiclePage = BuildVehiclePage()  
    local boxPage = BuildBoxPage()
    if not suitPage or not weaponPage or not vehiclePage or not boxPage then  
        return originalCatalog
    end
    local catalog = {}
    for i = 1, #originalCatalog do catalog[i] = originalCatalog[i] end
    catalog[#catalog + 1] = suitPage
    catalog[#catalog + 1] = weaponPage
    catalog[#catalog + 1] = vehiclePage  
    catalog[#catalog + 1] = boxPage
    return catalog
end

    local function IsSettingMainConfig(config)
        if not config then return false end
        if UIManager and UIManager.UI_Config and UIManager.UI_Config.setting_main then
            if config == UIManager.UI_Config.setting_main then return true end
        end
        return config.keyName == "setting_main"
    end

    local function IsInGameCatalog(catalog)
        if type(catalog) ~= "table" then return false end
        local hasGame, hasAccount = false, false
        for i = 1, #catalog do
            local page = catalog[i]
            if page and page.Key == "Game" then hasGame = true end
            if page and page.Key == "Account" then hasAccount = true end
        end
        return hasGame and not hasAccount
    end

    local function ShouldInject(catalog)
        if not IsInGameCatalog(catalog) then return false end
        if GameStatus and GameStatus.IsInLobbyOrMainCity then
            return not GameStatus.IsInLobbyOrMainCity()
        end
        return true
    end

    CustomTitleLoc.Patch()

    lizardMH_Config.Load(true)
    lizardMH_Config.RestoreCustomWeaponSkins()

    lizardMH_Config.PatchShowNoticeForSkinInput()
    lizardMH_Config.PatchSkinInputPopup()

    local origShowUI = UIManager and UIManager.ShowUI
    if origShowUI then
        UIManager.ShowUI = function(config, arg1, arg2, arg3, arg4)
            if IsSettingMainConfig(config) and type(arg1) == "table" and ShouldInject(arg1) then
                local ok, newCatalog = pcall(InjectCatalogs, arg1)
                if ok and type(newCatalog) == "table" then
                    arg1 = newCatalog
                end
            end
            if arg4 ~= nil then return origShowUI(config, arg1, arg2, arg3, arg4)
            elseif arg3 ~= nil then return origShowUI(config, arg1, arg2, arg3)
            elseif arg2 ~= nil then return origShowUI(config, arg1, arg2)
            elseif arg1 ~= nil then return origShowUI(config, arg1)
            else return origShowUI(config) end
        end
    end

    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(3, function() pcall(function() end) end)
        _G.Mytimer_ticker.AddTimer(8, function() pcall(function() end) end)
    end

local REQUIRE_UPGRADEABLE_WEAPON = false
local DEBUG_NOTICE = false

_G.TrainingDeadBox = _G.TrainingDeadBox or {}
if _G.TrainingDeadBox._timerIndex then
    pcall(function()
        require("common.time_ticker").RemoveTimer(_G.TrainingDeadBox._timerIndex)
    end)
end
_G.TrainingDeadBox._running = nil

local function notify(msg)
    if DEBUG_NOTICE then
        pcall(function()
            if ShowNotice then
                ShowNotice(tostring(msg))
            end
        end)
    end
    pcall(function() print(tostring(msg)) end)
end

_G.TrainingDeadBox._running = true
notify("盒子初始化成功")

do
    local PlayerDeadBoxPath = "/Game/BluePrints/PickUp/Special/PlayerDeadBox.PlayerDeadBox"
    local BOX_LIFE_SPAN = 20

    local timeTicker = require("common.time_ticker")
    local installed = false
    local hooksReady = false
    local lastKills = nil
    local lastHitAI = nil
    local lastHitLoc = nil
    local activeBoxes = {}
    local processedBoxes = {}  
    _G.TrainingDeadBox.activeBoxes = activeBoxes

    local function isDeadBoxSkinEnabled()
        return _G.EnableDeadBoxSkin == true or _G.EnableDeadBoxSkin == nil  
    end

    local function isInTrainingMode()
        if CGameState and slua.isValid(CGameState) then
            if CGameState.bIsTrainingMode then return true end
            if CGameState.STDeadBoxClientShowFeature then return true end
        end
        local ok, gd = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if ok and gd then
            local ok2, gs = pcall(gd.GetGameState)
            if ok2 and slua.isValid(gs) and gs.bIsTrainingMode then
                return true
            end
        end
        return false
    end

    local function isInGame()
        local ok, gd = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if ok and gd then
            local char = gd.GetPlayerCharacter()
            if slua.isValid(char) then return true end
        end
        if slua_GameFrontendHUD then
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then return true end
        end
        return false
    end

    local function lazyGameplayData()
        local ok, mod = pcall(require, "GameLua.GameCore.Data.GameplayData")
        return ok and mod or nil
    end

    local function lazyActorTools()
        local ok, mod = pcall(require, "GameLua.Mod.BaseMod.Common.ActorTools")
        return ok and mod or nil
    end

    local function getPC()
        if slua_GameFrontendHUD then
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then return pc end
        end
        local gd = lazyGameplayData()
        if gd then
            local pc = gd.GetPlayerController()
            if slua.isValid(pc) then return pc end
        end
        return nil
    end

    local function getChar()
        local pc = getPC()
        if slua.isValid(pc) and pc.GetPlayerCharacterSafety then
            return pc:GetPlayerCharacterSafety()
        end
        local gd = lazyGameplayData()
        if gd then
            local ch = gd.GetPlayerCharacter()
            if slua.isValid(ch) then return ch end
        end
        return nil
    end

    local function getUpgradeDeadBoxPath(avatarId)
        if not avatarId or avatarId <= 0 then return nil end
        local ok, path = pcall(function()
            local ModuleManager = require("client.module_framework.ModuleManager")
            local ItemUpgradeSystem = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
            local cfg = ItemUpgradeSystem:GetUpgradeCfg(avatarId)
            if not cfg or not cfg.EffectID then return nil end
            local effectCfg = CDataTable.GetTableData("ItemUpgradeEffectConfig", cfg.EffectID)
            if effectCfg and effectCfg.DeadBox and effectCfg.DeadBox ~= "" then
                return effectCfg.DeadBox
            end
            return nil
        end)
        return ok and path or nil
    end

    local function getBestSkinDeadBoxPath(avatarId)
        if not avatarId or avatarId <= 0 then return nil end

        local direct = getUpgradeDeadBoxPath(avatarId)
        if direct and direct ~= "" then return direct end

        local ok, path = pcall(function()
            local ModuleManager = require("client.module_framework.ModuleManager")
            local ItemUpgradeSystem = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
            local groupList = ItemUpgradeSystem:GetUpgradeGroupByItemID(avatarId)
            if not groupList or #groupList == 0 then return nil end

            local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
            local ownedIndex = 0
            local boxPath = nil
            local boxUnlockIndex = 0

            for i, cfg in ipairs(groupList) do
                local RefitID = ItemUpgradeSystem:GetRefitSwitcherID(cfg.ItemID)
                if wardrobe_data:GetHallDepotItemDataByResID(cfg.ItemID)
                        or wardrobe_data:GetHallDepotItemDataByResID(RefitID) then
                    if i > ownedIndex then ownedIndex = i end
                end
                if boxUnlockIndex == 0 then
                    local effectCfg = CDataTable.GetTableData("ItemUpgradeEffectConfig", cfg.EffectID)
                    if effectCfg and effectCfg.DeadBox and effectCfg.DeadBox ~= "" then
                        boxUnlockIndex = i
                        boxPath = effectCfg.DeadBox
                    end
                end
            end

            if ownedIndex > 0 and boxUnlockIndex > 0 and ownedIndex >= boxUnlockIndex and boxPath then
                return boxPath
            end

            for i = #groupList, 1, -1 do
                local effectCfg = CDataTable.GetTableData("ItemUpgradeEffectConfig", groupList[i].EffectID)
                if effectCfg and effectCfg.DeadBox and effectCfg.DeadBox ~= "" then
                    if groupList[i].ItemID == avatarId then
                        return effectCfg.DeadBox
                    end
                end
            end
            return nil
        end)
        return ok and path or nil
    end

    local function hasPlayerDeadBoxAvatarPath(avatarId)
        if not avatarId or avatarId <= 0 then return false end
        local ok, exists = pcall(function()
            local UAvatarUtils = import("AvatarUtils")
            local UBackpackUtils = import("BackpackUtils")
            local avatarPath = UAvatarUtils.GetWeaponAvatarDeadBoxAvatarHandlePath(avatarId)
            return UBackpackUtils.IsBattleItemHandlePathExist(avatarPath)
        end)
        return ok and exists == true
    end

    local function getCurrentWeaponAvatarId()
        local char = getChar()
        if not slua.isValid(char) then return 0 end
        local weapon = char:GetCurrentWeapon()
        if not slua.isValid(weapon) then return 0 end
        local defineId = weapon:GetItemDefineID()
        if not defineId or defineId.Type == 6 then return 0 end
        local baseWeaponId = defineId.TypeSpecificID
        local skinId = 0

        pcall(function()
            local comp = weapon.WeaponAvatarComponent
            if slua.isValid(comp) then
                local EWeaponAttachmentSocketType = import("EWeaponAttachmentSocketType")
                local skinDefine = comp:GetEquippedItemDefineID(EWeaponAttachmentSocketType.MasterGun)
                if skinDefine and skinDefine.TypeSpecificID and skinDefine.TypeSpecificID > 0
                        and skinDefine.TypeSpecificID ~= baseWeaponId then
                    skinId = skinDefine.TypeSpecificID
                end
            end
        end)

        if skinId <= 0 and _G.WeaponSkinID and _G.WeaponSkinID[baseWeaponId] and _G.WeaponSkinID[baseWeaponId] > 0 then
            skinId = _G.WeaponSkinID[baseWeaponId]
        end

        if skinId <= 0 then
            local pc = getPC()
            if slua.isValid(pc) and pc.GetWeaponAvatarItemId then
                pcall(function()
                    local UBackpackUtils = import("BackpackUtils")
                    local bpId = UBackpackUtils.GetBPIDByResID(baseWeaponId)
                    local av = pc:GetWeaponAvatarItemId(bpId)
                    if av and av > 0 then skinId = av end
                end)
            end
        end

        return skinId or 0
    end

    local function resolveSpawnLoc(uPawn, fallbackLoc)
        if slua.isValid(uPawn) then
            if uPawn.GetRandomPutDownLocation then
                local ok, loc = pcall(uPawn.GetRandomPutDownLocation, uPawn, 80)
                if ok and loc then return loc end
            end
            local ok, loc = pcall(uPawn.K2_GetActorLocation, uPawn)
            if ok and loc then return loc end
        end
        return fallbackLoc
    end

    local function resolveAvatarId(avatarId)
        if not avatarId or avatarId <= 0 then
            avatarId = getCurrentWeaponAvatarId()
        end
        if REQUIRE_UPGRADEABLE_WEAPON then
            local function isUpgradeableSkin(id)
                if _G.isUpgradeableWeaponSkin then
                    local ok, r = pcall(_G.isUpgradeableWeaponSkin, id)
                    if ok and r then return true end
                end
                return false
            end
            if not isUpgradeableSkin(avatarId) then
                return nil
            end
        end
        return avatarId or 0
    end

    local function activateBoxVisuals(uBoxActor, feature)
        local delayFn = feature and feature.AddGameTimer
        local run = function()
            if not slua.isValid(uBoxActor) then return end
            pcall(function()
                if uBoxActor.Survive_FMC_Chest1 then
                    uBoxActor.Survive_FMC_Chest1:SetHiddenInGame(false, false)
                end
                if uBoxActor.DeadParticleSystem then
                    uBoxActor.DeadParticleSystem:Activate(true)
                end
            end)
        end
        if delayFn then
            pcall(delayFn, feature, 1, false, run)
        else
            timeTicker.AddTimer(1, run)
        end
    end

    local function spawnActorAtPath(boxPath, loc, onReady)
        local playerChar = getChar()
        local ActorTools = lazyActorTools()
        if ActorTools and slua.isValid(playerChar) then
            local called = false
            local function wrap(uBoxActor)
                if called then return end
                called = true
                onReady(uBoxActor)
            end
            local ok = pcall(function()
                ActorTools.SpawnActorAsync(playerChar, boxPath, loc, FRotator(0, 0, 0), FVector(1, 1, 1), wrap)
            end)
            if ok then
                timeTicker.AddTimer(0.8, function()
                    if not called then wrap(nil) end
                end)
                return true
            end
        end
        local syncOk, syncBox = pcall(function()
            local asset_util = require("common.asset_util")
            local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
            if not slua.isValid(world) then return nil end
            local cls = asset_util.GetAssetSync(boxPath)
            if not cls then return nil end
            return world:SpawnActor(cls, loc, FRotator(0, 0, 0), nil)
        end)
        if syncOk and slua.isValid(syncBox) then
            onReady(syncBox)
            return true
        end
        onReady(nil)
        return false
    end

    local function applySkinDeadBoxEffects(uBoxActor)
        if not slua.isValid(uBoxActor) then return end
        pcall(function()
            if uBoxActor.PlaySmokeAnim then
                uBoxActor:PlaySmokeAnim()
            end
        end)
        pcall(function()
            if uBoxActor.DeadParticleSystem then
                uBoxActor.DeadParticleSystem:Activate(true)
            end
        end)
        pcall(function()
            local DeadBoxAvatarComp = uBoxActor.DeadBoxAvatarComponent_BP
            if slua.isValid(DeadBoxAvatarComp) and DeadBoxAvatarComp.HandleOnItemHandleLoaded then
                DeadBoxAvatarComp:HandleOnItemHandleLoaded()
            end
        end)
    end

    local function spawnPlayerDeadBoxWithAvatar(loc, useAvatarId, feature, boxLife, onDone)
        if not hasPlayerDeadBoxAvatarPath(useAvatarId) then
            onDone(false)
            return
        end
        spawnActorAtPath(PlayerDeadBoxPath .. "_C", loc, function(uBoxActor)
            if not slua.isValid(uBoxActor) then
                onDone(false)
                return
            end
            trackBox(uBoxActor)
            pcall(function() uBoxActor:SetLifeSpan(boxLife) end)
            pcall(function()
                uBoxActor:SetAvatarId(useAvatarId)
                uBoxActor:OnRep_AvatarId()
            end)
            applySkinDeadBoxEffects(uBoxActor)
            activateBoxVisuals(uBoxActor, feature)
            onDone(true, "player")
        end)
    end

    local function spawnSkinMeshDeadBox(loc, skinBoxPath, feature, boxLife, onDone)
        spawnActorAtPath(skinBoxPath, loc, function(uBoxActor)
            if not slua.isValid(uBoxActor) then
                onDone(false)
                return
            end
            trackBox(uBoxActor)
            pcall(function() uBoxActor:SetLifeSpan(boxLife) end)
            applySkinDeadBoxEffects(uBoxActor)
            activateBoxVisuals(uBoxActor, feature)
            onDone(true, "skin")
        end)
    end

    local lastSpawnAt = 0

    local function spawnDeadBoxAt(loc, avatarId, feature)

        if not isDeadBoxSkinEnabled() then return false end

        if not loc then return false end
        if not isInGame() then return false end  

        local now = os.clock()
        if now - lastSpawnAt < 0.5 then return false end
        lastSpawnAt = now

        local useAvatarId = resolveAvatarId(avatarId)
        if useAvatarId == nil then
            return false
        end

        local skinBoxPath = getBestSkinDeadBoxPath(useAvatarId)

        local boxLife = (feature and feature.BoxLifeSpan) or BOX_LIFE_SPAN

        local function done(ok, kind)
            if ok then
            else
            end
        end

        if skinBoxPath then
            spawnSkinMeshDeadBox(loc, skinBoxPath, feature, boxLife, function(ok, kind)
                if ok then
                    done(true, kind)
                    return
                end
                spawnPlayerDeadBoxWithAvatar(loc, useAvatarId, feature, boxLife, function(ok2, kind2)
                    done(ok2, kind2)
                end)
            end)
            return true
        end

        spawnPlayerDeadBoxWithAvatar(loc, useAvatarId, feature, boxLife, function(ok, kind)
            done(ok, kind)
        end)
        return true
    end

    local function onKillDetected()
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end  

        local loc = nil
        if slua.isValid(lastHitAI) then
            loc = resolveSpawnLoc(lastHitAI, lastHitLoc)
        end
        if not loc and lastHitLoc then
            loc = lastHitLoc
        end
        if not loc then
            local char = getChar()
            if slua.isValid(char) then
                local ok, charLoc = pcall(char.K2_GetActorLocation, char)
                if ok and charLoc then
                    loc = FVector(charLoc.X + 150, charLoc.Y, charLoc.Z)
                end
            end
        end
        local feature = CGameState and CGameState.STDeadBoxClientShowFeature
        spawnDeadBoxAt(loc, nil, feature)
        lastHitAI = nil
    end

    local function onLocalShootDamage(_, __, weapon, targetActor, damage, hitBodyType, impactPoint)
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end
        if not slua.isValid(targetActor) then return end
        local isAI = false
        pcall(function() isAI = Game and Game.IsAI and Game:IsAI(targetActor) end)
        if not isAI then return end
        lastHitAI = targetActor
        if impactPoint then
            lastHitLoc = impactPoint
        else
            pcall(function() lastHitLoc = targetActor:K2_GetActorLocation() end)
        end
    end

    local function onKillNumChanged()
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end
        if CGameState and CGameState.STDeadBoxClientShowFeature and CGameState.STDeadBoxClientShowFeature._tdbHooked then
            return
        end
        onKillDetected()
    end

    local function onPawnDied(_, __, uPawn, uKiller, typeId)
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end
        local myChar = getChar()
        if not slua.isValid(myChar) or uKiller ~= myChar then return end
        local isAI = false
        pcall(function() isAI = Game and Game.IsAI and Game:IsAI(uPawn) end)
        if not isAI then return end
        lastHitAI = uPawn
        onKillDetected()
    end

    local function scanAndModifyExistingBoxes()
        if not isDeadBoxSkinEnabled() then return end
        if isInTrainingMode() then return end  

        pcall(function()
            local pc = getPC()
            if not slua.isValid(pc) then return end

            local pk = pc.Playerkey or pc.PlayerKey
            if not pk then return end

            local UGameplayStatics = import("GameplayStatics")
            if not UGameplayStatics then return end

            local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
            if not slua.isValid(world) then return end

            local APlayerTombBox = import("PlayerTombBox")
            if not APlayerTombBox then return end

            local actors = UGameplayStatics.GetAllActorsOfClass(world, APlayerTombBox, {})
            if not actors then return end

            for _, actor in pairs(actors) do
                if slua.isValid(actor) then

                    if not processedBoxes[actor] then
                        local causer = actor.DamageCauser
                        if causer and (causer.Playerkey == pk or causer.PlayerKey == pk) then
                            local avatarComp = actor.DeadBoxAvatarComponent_BP
                            if slua.isValid(avatarComp) then
                                local skinId = getCurrentWeaponAvatarId()
                                if skinId > 0 and hasPlayerDeadBoxAvatarPath(skinId) then
                                    pcall(function()
                                        actor:SetAvatarId(skinId)
                                        actor:OnRep_AvatarId()
                                        applySkinDeadBoxEffects(actor)
                                        processedBoxes[actor] = true
                                        notify("DeadBox skin applied: " .. tostring(skinId))
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local function pollKills()
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end

        if CGameState and CGameState.STDeadBoxClientShowFeature and CGameState.STDeadBoxClientShowFeature._tdbHooked then
            return
        end
        local gd = lazyGameplayData()
        if not gd then return end
        local ps = gd.GetPlayerState()
        if not slua.isValid(ps) or ps.Kills == nil then return end

        if lastKills ~= nil and ps.Kills > lastKills then
            onKillDetected()
        end
        lastKills = ps.Kills
    end

    local function hookCleanAIDeadBox(feature)
        if not feature or feature._tdbCleanHooked then return end
        feature.CleanAIDeadBox = function(self)
            local ActorTools = lazyActorTools()
            if not ActorTools or not slua.isValid(CGameState) then return end
            local uActorArray = ActorTools.GetAllActors(CGameState, "PlayerTombBox")
            local kept, removed = 0, 0
            for _, uActor in pairs(uActorArray) do
                if uActor and slua.isValid(uActor) then
                    if isOurBox(uActor) then
                        kept = kept + 1
                    else
                        pcall(function() Game:RemoveActor(uActor) end)
                        removed = removed + 1
                    end
                end
            end
            if DEBUG_NOTICE then notify("TDB clean k=" .. kept .. " r=" .. removed) end
        end
        feature._tdbCleanHooked = true
    end

    local function hookSpawnSTDeadBox(feature)
        if not feature or feature._tdbHooked then return end
        feature.SpawnSTDeadBox = function(self, loc, avatarId)
            if not loc then return end
            if self.IsAuthority and self:IsAuthority() then return end
            spawnDeadBoxAt(loc, avatarId, self)
        end
        feature._tdbHooked = true
    end

    local function hookPlayerController(pc)
        if not slua.isValid(pc) or pc._tdbHooked then return end
        if pc.ClientRPC_SpawnDeadBox then
            pc.ClientRPC_SpawnDeadBox = function(self, loc, avatarId)
                local feature = CGameState and CGameState.STDeadBoxClientShowFeature
                spawnDeadBoxAt(loc, avatarId, feature)
            end
        end
        pc._tdbHooked = true
    end

    local function registerEvents()
        if installed then return end
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_PLAYEREVENT_WEAPON, EVENTID_PLAYEREVENT_LOCAL_HANDLE_SHOOT_DAMAGE, onLocalShootDamage)
        end)
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_ON_KILLNUM_CHANGED, onKillNumChanged)
        end)
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_PAWN_DIED, onPawnDied)
        end)
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_CONTROLLER_BEGINPLAY, function()
                timeTicker.AddTimer(1, function()
                    _G.TrainingDeadBox.tryInstall()
                end)
            end)
        end)
        installed = true
    end

    function _G.TrainingDeadBox.tryInstall()
        registerEvents()
        if CGameState and CGameState.STDeadBoxClientShowFeature then
            hookCleanAIDeadBox(CGameState.STDeadBoxClientShowFeature)
            hookSpawnSTDeadBox(CGameState.STDeadBoxClientShowFeature)
        end
        local pc = getPC()
        if slua.isValid(pc) then
            hookPlayerController(pc)
        end
        if isInGame() and not hooksReady then
            hooksReady = true
        end
    end

    function _G.TrainingDeadBox.tick()
        if not slua_GameFrontendHUD then return end
        if not isDeadBoxSkinEnabled() then return end

        _G.TrainingDeadBox.tryInstall()

        if isInTrainingMode() then
            pollKills()
        else

            scanAndModifyExistingBoxes()
        end
    end

    registerEvents()
    timeTicker.AddTimer(0.5, function() _G.TrainingDeadBox.tryInstall() end)

    if _G.TrainingDeadBox._timerIndex and timeTicker.IsRunning(_G.TrainingDeadBox._timerIndex) then
        timeTicker.RemoveTimer(_G.TrainingDeadBox._timerIndex)
    end
    _G.TrainingDeadBox._timerIndex = timeTicker.AddTimerLoop(0.3, function()
        _G.TrainingDeadBox.tick()
    end, -1, 1.0)

end
end)

pcall(function()
    local game_frontend_hud = require("game_frontend_hud")
    local audio_util = require("client.common.audio_util")
    local AkGameplayStatics = import("AkGameplayStatics")
    local EScreenParticleEffectType = import("EScreenParticleEffectType")

    local function getWeatherModeFromGlobal()
        local modeNum = _G.WeatherMode or 3  
        if modeNum == 0 then return "none"
        elseif modeNum == 1 then return "rain"
        elseif modeNum == 2 then return "snow"
        elseif modeNum == 3 then return "blizzard"
        elseif modeNum == 4 then return "storm"
        else return "blizzard"
        end
    end

    local WEATHER_MODE = getWeatherModeFromGlobal()
    local ENABLED = true  

    local AUDIO_RAIN_AMBIENT_PLAY = "/Game/WwiseEvent/Ambient/Play_Ambient_Rain.Play_Ambient_Rain"
    local AUDIO_RAIN_AMBIENT_STOP = "/Game/WwiseEvent/Ambient/Play_Ambient_Rain_Stop.Play_Ambient_Rain_Stop"
    local AUDIO_RAIN_LOOP_PLAY    = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Play_PlanPH_Object_Rain_Loop.Play_PlanPH_Object_Rain_Loop"
    local AUDIO_RAIN_LOOP_STOP    = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Stop_PlanPH_Object_Rain_Loop.Stop_PlanPH_Object_Rain_Loop"
    local AUDIO_SNOW_PLAY = "/Game/Mod/IceWorld3/WwiseEvent/IceWorld3_Treasure_350/Play_IceWorld3_TreasureBox_Snow_Loop.Play_IceWorld3_TreasureBox_Snow_Loop"
    local AUDIO_SNOW_STOP = "/Game/Mod/IceWorld3/WwiseEvent/IceWorld3_Treasure_350/Stop_IceWorld3_TreasureBox_Snow_Loop.Stop_IceWorld3_TreasureBox_Snow_Loop"
    local AUDIO_WIND_PLAY  = "/Game/Mod/EasternRealm/WwiseEvent/EasternRealm_POI_Wind_360/Play_EasternRealm_Wind_Guest_Loop.Play_EasternRealm_Wind_Guest_Loop"
    local AUDIO_WIND_STOP  = "/Game/Mod/EasternRealm/WwiseEvent/EasternRealm_POI_Wind_360/Stop_EasternRealm_Wind_Guest_Loop.Stop_EasternRealm_Wind_Guest_Loop"
    local AUDIO_WIND2_PLAY = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Play_PlanPH_Object_Wind_Machine_Loop.Play_PlanPH_Object_Wind_Machine_Loop"
    local AUDIO_WIND2_STOP = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Stop_PlanPH_Object_Wind_Machine_Loop.Stop_PlanPH_Object_Wind_Machine_Loop"
    local AUDIO_WIND3_PLAY = "/Game/Mod/Mecha/WwiseEvent/Mecha_FlyArmor_320/Play_Mecha_FlyArmor_Wind_Loop.Play_Mecha_FlyArmor_Wind_Loop"
    local AUDIO_THUNDER_PLAY = "/Game/WwiseEvent/Character_KillEffect/Character_KillEffect_320/Play_Character_KillEffect_Thunder_320.Play_Character_KillEffect_Thunder_320"
    local AUDIO_THUNDER_STOP = "/Game/WwiseEvent/Character_KillEffect/Character_KillEffect_320/Stop_Character_KillEffect_Thunder_2D_320.Stop_Character_KillEffect_Thunder_2D_320"
    local AUDIO_THUNDER2_PLAY = "/Game/Mod/ZNQ8th/WwiseEvent/ZNQ8th_RegionalTransformation_430/Play_ZNQ8th_RegionalTransformation_ThunderCloud.Play_ZNQ8th_RegionalTransformation_ThunderCloud"
    local AUDIO_THUNDER3_PLAY = "/Game/Mod/GoldenDragon/WwiseEvent/GoldenDragon_300/Play_GoldenDragon_Ground_Thunder.Play_GoldenDragon_Ground_Thunder"

    local THUNDER_MIN_FRAMES = 480
    local THUNDER_MAX_FRAMES = 1200
    local SOUND_REFRESH_FRAMES = 600

    local _active = false
    local _loopAudioIDs = {}
    local _lastInGame = false
    local _frameCount = 0
    local _lastSoundRefresh = 0
    local _nextThunderFrame = 0
    local _thunderIndex = 1

    local ALL_STOP_PATHS = {
        AUDIO_RAIN_AMBIENT_STOP, AUDIO_RAIN_LOOP_STOP,
        AUDIO_SNOW_STOP, AUDIO_WIND_STOP, AUDIO_WIND2_STOP,
        AUDIO_THUNDER_STOP,
    }

    local THUNDER_PATHS = {
        AUDIO_THUNDER_PLAY,
        AUDIO_THUNDER2_PLAY,
        AUDIO_THUNDER3_PLAY,
    }

    local function IsInGame()
        if GameStatus and GameStatus.IsInFightingStatus then
            return GameStatus.IsInFightingStatus()
        end
        if Client and GameFrontendHUD then
            return Client.GetUnrealNetworkStatus(GameFrontendHUD) == "Online"
        end
        return false
    end

    local function GetPlayerCharacter()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return nil end
        if pc.GetPlayerCharacterSafety then return pc:GetPlayerCharacterSafety() end
        if pc.GetCurPlayerCharacter then return pc:GetCurPlayerCharacter() end
        return nil
    end

    local function StopAudioID(id)
        if id and id ~= 0 then
            pcall(function() audio_util.StopSound(id) end)
            pcall(function() AkGameplayStatics.StopPlayingID(id) end)
        end
    end

    local function PlayLoopSound(key, path)
        local ownerObj = GetPlayerCharacter()
        pcall(function()
            audio_util.PlayAudioAsync(path, ownerObj, nil, function(soundId)
                if soundId and soundId ~= 0 then
                    _loopAudioIDs[key] = soundId
                end
            end)
        end)
    end

    local function StopAllLoopSounds()
        for key, id in pairs(_loopAudioIDs) do
            StopAudioID(id)
            _loopAudioIDs[key] = nil
        end
        pcall(function()
            for _, stopPath in ipairs(ALL_STOP_PATHS) do
                audio_util.PlayAudioAsync(stopPath)
            end
            AkGameplayStatics.AkSetRTPCValue("Ambient_Weather", 0, false)
        end)
    end

    local function ScheduleNextThunder()
        _nextThunderFrame = _frameCount + math.random(THUNDER_MIN_FRAMES, THUNDER_MAX_FRAMES)
    end

    local function PlayThunder()
        local ownerObj = GetPlayerCharacter()
        local path = THUNDER_PATHS[_thunderIndex]
        _thunderIndex = (_thunderIndex % #THUNDER_PATHS) + 1
        pcall(function()
            audio_util.PlayAudioAsync(path, ownerObj)
        end)
        ScheduleNextThunder()
    end

    local function NeedsRainSound()
        return WEATHER_MODE == "rain" or WEATHER_MODE == "storm"
    end

    local function NeedsSnowSound()
        return WEATHER_MODE == "snow" or WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"
    end

    local function NeedsWindSound()
        return WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"
    end

    local function NeedsThunder()
        return WEATHER_MODE == "rain" or WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"
    end

    local function StartSounds()
        StopAllLoopSounds()
        local ownerObj = GetPlayerCharacter()

        if NeedsRainSound() then
            pcall(function()
                AkGameplayStatics.AkSetRTPCValue("Ambient_Weather", 100, false)
            end)
            PlayLoopSound("rain_ambient", AUDIO_RAIN_AMBIENT_PLAY)
            PlayLoopSound("rain_loop", AUDIO_RAIN_LOOP_PLAY)
        end

        if NeedsSnowSound() then
            PlayLoopSound("snow", AUDIO_SNOW_PLAY)
        end

        if NeedsWindSound() then
            PlayLoopSound("wind1", AUDIO_WIND_PLAY)
            PlayLoopSound("wind2", AUDIO_WIND2_PLAY)
            PlayLoopSound("wind3", AUDIO_WIND3_PLAY)
        end

        if NeedsThunder() then
            ScheduleNextThunder()
            PlayThunder()
        end

        _lastSoundRefresh = _frameCount
    end

    local function SetRainVisual(on)
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) and pc.SetIsRainy then
            pc:SetIsRainy(on)
        end
    end

    local function SetParticleEffect(effectType, on)
        local char = GetPlayerCharacter()
        if slua.isValid(char) and char.SetRainyEffectEnable then
            char:SetRainyEffectEnable(effectType, on, on and 500 or 0)
        end
    end

    local function SetSnowScreenUI(on)
        pcall(function()
            if not UIManager or not UIManager.UI_Config_InGame then return end
            local cfg = UIManager.UI_Config_InGame.SnowEffectUI
            if not cfg then return end
            if on then
                if not UIManager.IsUIShow(cfg) then UIManager.ShowUI(cfg) end
            elseif UIManager.IsUIShow(cfg) then
                UIManager.CloseUI(cfg)
            end
        end)
    end

    local function ApplyVisuals(on)
        if not on then
            SetRainVisual(false)
            SetParticleEffect(EScreenParticleEffectType.ESPET_Rainy, false)
            SetParticleEffect(EScreenParticleEffectType.ESPET_Snowy, false)
            SetParticleEffect(EScreenParticleEffectType.ESPET_Blizzard, false)
            SetSnowScreenUI(false)
            return
        end

        local showRain     = WEATHER_MODE == "rain" or WEATHER_MODE == "storm"
        local showSnow     = WEATHER_MODE == "snow" or WEATHER_MODE == "storm"
        local showBlizzard = WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"

        SetRainVisual(showRain)
        SetParticleEffect(EScreenParticleEffectType.ESPET_Rainy, showRain)
        SetParticleEffect(EScreenParticleEffectType.ESPET_Snowy, showSnow or showBlizzard)
        SetParticleEffect(EScreenParticleEffectType.ESPET_Blizzard, showBlizzard)
        SetSnowScreenUI(showSnow or showBlizzard)
    end

    local function EnableWeather()
        if _active then return end
        if not IsInGame() or WEATHER_MODE == "none" then return end
        ApplyVisuals(true)
        StartSounds()
        _active = true
        print("[DEV_WEATHER] Enabled | mode =", WEATHER_MODE)
    end

    local function DisableWeather()
        if not _active then return end
        ApplyVisuals(false)
        StopAllLoopSounds()
        _active = false
        _nextThunderFrame = 0
        print("[DEV_WEATHER] Disabled")
    end

    local function RefreshWeather()
        if not ENABLED or not _active or WEATHER_MODE == "none" then return end
        ApplyVisuals(true)
        if _frameCount - _lastSoundRefresh >= SOUND_REFRESH_FRAMES then
            StartSounds()
        end
    end

    function _G.UpdateWeatherMode(modeNum)
        local newMode = "none"
        if modeNum == 0 then newMode = "none"
        elseif modeNum == 1 then newMode = "rain"
        elseif modeNum == 2 then newMode = "snow"
        elseif modeNum == 3 then newMode = "blizzard"
        elseif modeNum == 4 then newMode = "storm"
        else newMode = "blizzard"
        end

        if WEATHER_MODE ~= newMode then
            local wasActive = _active
            if wasActive then
                DisableWeather()
            end
            WEATHER_MODE = newMode
            if wasActive and newMode ~= "none" and IsInGame() then
                EnableWeather()
            end
            print("[DEV_WEATHER] Mode changed to: " .. tostring(newMode) .. " (value=" .. tostring(modeNum) .. ")")
        else
            WEATHER_MODE = newMode
        end
    end

    local function OnTick()
        if not ENABLED or WEATHER_MODE == "none" then return end

        _frameCount = _frameCount + 1
        local inGame = IsInGame()

        if inGame and not _lastInGame then
            print("[DEV_WEATHER] Entered match")
            EnableWeather()
        elseif not inGame and _lastInGame then
            print("[DEV_WEATHER] Left match")
            DisableWeather()
        end

        if inGame and _active then
            if _frameCount % 120 == 0 then
                RefreshWeather()
            end

            if NeedsThunder() and _nextThunderFrame > 0 and _frameCount >= _nextThunderFrame then
                PlayThunder()
            end
        end

        _lastInGame = inGame
    end

    game_frontend_hud.SetSluaTickListener(OnTick)

    game_frontend_hud.SetPostSwitchGameStatusListener(function(status)
        print("[DEV_WEATHER] Status:", status)
        if IsInGame() then EnableWeather() else DisableWeather() end
    end)

    print("[DEV_WEATHER] Loaded | mode = " .. WEATHER_MODE .. " (configurable via WEATHER= value)")
end)

if not _G.__PHOENIXTRA_SUMMON_LOADED__ then
    _G.__PHOENIXTRA_SUMMON_LOADED__ = true

    local PhoenixtraSummon = {}

    PhoenixtraSummon.XSUIT_ID = 1407856

    PhoenixtraSummon.PERIOD = 6

    PhoenixtraSummon.FALLBACK_TEMPLATE_ID = 1407841

    PhoenixtraSummon.CALL_ACTION_ID = 12219843

    PhoenixtraSummon.CALL_STATUE_SEQ = nil

    PhoenixtraSummon.CALL_TIME = 7

    PhoenixtraSummon.BYPASS_7STAR_CHECK = true

    PhoenixtraSummon.FORCE_WEAR_IN_MATCH = true

    PhoenixtraSummon.PLAY_LOCAL_SEQUENCE = true

    PhoenixtraSummon.DEBUG = true

    PhoenixtraSummon.AUTO_INSTALL = true

    PhoenixtraSummon._dataHooked = false
    PhoenixtraSummon._menuHooked = false
    PhoenixtraSummon._platformHooked = false
    PhoenixtraSummon._tipsHooked = false
    PhoenixtraSummon._gameTipsHooked = false
    PhoenixtraSummon._resolvedEffect = nil
    PhoenixtraSummon._origGetTableData = nil
    PhoenixtraSummon._origGetTable = nil
    PhoenixtraSummon._origRequire = nil
    PhoenixtraSummon._lastSummonParam = nil
    PhoenixtraSummon._eventsHooked = false
    PhoenixtraSummon._summonCooldownUntil = 0
    PhoenixtraSummon._lastInstallState = nil

    local PLATFORM_MODULE = "GameLua.Activity.Commercialize.Actor.InteractActor.XSuitPlatform"

    function PhoenixtraSummon.UpdateFromConfig()

        if _G.SuitSkin and _G.SuitSkin ~= 0 then
            if PhoenixtraSummon.XSUIT_ID ~= _G.SuitSkin then
                PhoenixtraSummon.XSUIT_ID = _G.SuitSkin
                PhoenixtraSummon._resolvedEffect = nil  
                log("XSUIT_ID updated from SuitSkin: " .. tostring(PhoenixtraSummon.XSUIT_ID))
            end

        elseif lastConfig and lastConfig.SHIRT then
            if PhoenixtraSummon.XSUIT_ID ~= lastConfig.SHIRT then
                PhoenixtraSummon.XSUIT_ID = lastConfig.SHIRT
                PhoenixtraSummon._resolvedEffect = nil
                log("XSUIT_ID updated from lastConfig.SHIRT: " .. tostring(PhoenixtraSummon.XSUIT_ID))
            end
        end
        return PhoenixtraSummon.XSUIT_ID
    end

    local function hasMethod(obj, name)
        if not obj then return false end
        local v = obj[name]
        if v == nil then return false end
        local t = type(v)
        return t == "function" or t == "userdata" or t == "table"
    end

    local function getOwnerName(owner)
        local ok, name = pcall(function()
            local KismetSystemLibrary = import("KismetSystemLibrary")
            return KismetSystemLibrary.GetObjectName(owner)
        end)
        if ok and name then
            return tostring(name)
        end
        return tostring(owner)
    end

    local function isReadyState()
        local gs = slua_GameFrontendHUD and slua_GameFrontendHUD.GetGameState and slua_GameFrontendHUD:GetGameState()
        if slua.isValid(gs) and gs.GetGameModeState then
            return gs:GetGameModeState() == "ReadyState"
        end
        return false
    end

    local function log(msg)
        if PhoenixtraSummon.DEBUG then
            print("[PhoenixtraSummon] " .. tostring(msg))
        end
        pcall(function()
            local f = io.open("data/share1/loglua.txt", "a+")
            if f then
                f:write(os.date("[%H:%M:%S] ") .. tostring(msg) .. "\n")
                f:close()
            end
        end)
    end

    local function safeRequire(path)
        local ok, mod = pcall(require, path)
        if ok then return mod end
        return nil
    end

    local function shallowCopy(src)
        if type(src) ~= "table" then return src end
        local dst = {}
        for k, v in pairs(src) do dst[k] = v end
        return dst
    end

    local function rawGetTableData(tableName, key)
        if PhoenixtraSummon._origGetTableData then
            return PhoenixtraSummon._origGetTableData(tableName, key)
        end
        if CDataTable and CDataTable.GetTableData then
            return CDataTable.GetTableData(tableName, key)
        end
        return nil
    end

    local function rawGetTable(tableName)
        if PhoenixtraSummon._origGetTable then
            return PhoenixtraSummon._origGetTable(tableName)
        end
        if CDataTable and CDataTable.GetTable then
            return CDataTable.GetTable(tableName)
        end
        return nil
    end

    local function readBattleEffect(itemID)
        itemID = tonumber(itemID)
        if not itemID or itemID <= 0 then return nil end
        local row = rawGetTableData("GoldClothBattleEffect", itemID)
        if row and row.CallStatue and row.CallStatue ~= "" then
            return row
        end
        return nil
    end

    function PhoenixtraSummon.ResolveEffectConfig()
        if PhoenixtraSummon._resolvedEffect then
            return PhoenixtraSummon._resolvedEffect
        end
        local native = readBattleEffect(PhoenixtraSummon.XSUIT_ID)
        if native then
            PhoenixtraSummon._resolvedEffect = shallowCopy(native)
            PhoenixtraSummon._resolvedEffect.ID = PhoenixtraSummon.XSUIT_ID
            log("native CallStatue ok for " .. tostring(PhoenixtraSummon.XSUIT_ID))
            return PhoenixtraSummon._resolvedEffect
        end
        local template = readBattleEffect(PhoenixtraSummon.FALLBACK_TEMPLATE_ID)
        if not template then
            local tbl = rawGetTable("GoldClothBattleEffect")
            if tbl then
                for _, row in pairs(tbl) do
                    if row and row.CallStatue and row.CallStatue ~= "" then
                        template = row
                        break
                    end
                end
            end
        end
        PhoenixtraSummon._resolvedEffect = template and shallowCopy(template) or {}
        PhoenixtraSummon._resolvedEffect.ID = PhoenixtraSummon.XSUIT_ID
        PhoenixtraSummon._resolvedEffect.Level = 7
        PhoenixtraSummon._resolvedEffect.CallTime = PhoenixtraSummon._resolvedEffect.CallTime or PhoenixtraSummon.CALL_TIME
        if PhoenixtraSummon.CALL_STATUE_SEQ and PhoenixtraSummon.CALL_STATUE_SEQ ~= "" then
            PhoenixtraSummon._resolvedEffect.CallStatue = PhoenixtraSummon.CALL_STATUE_SEQ
        end
        log("CallStatue=" .. tostring(PhoenixtraSummon._resolvedEffect.CallStatue or ""))
        return PhoenixtraSummon._resolvedEffect
    end

    function PhoenixtraSummon.BuildInjectedBattleEffectRow(existing)
        local cfg = PhoenixtraSummon.ResolveEffectConfig()
        local row = shallowCopy(existing or cfg)
        row.ID = PhoenixtraSummon.XSUIT_ID
        row.Level = 7
        row.CallStatue = cfg.CallStatue or row.CallStatue or ""
        row.CallTime = cfg.CallTime or row.CallTime or PhoenixtraSummon.CALL_TIME
        return row
    end

    function PhoenixtraSummon.InstallDataTableHooks()
        if PhoenixtraSummon._dataHooked or not CDataTable or not CDataTable.GetTableData then
            return PhoenixtraSummon._dataHooked
        end
        PhoenixtraSummon._origGetTableData = CDataTable.GetTableData
        PhoenixtraSummon._origGetTable = CDataTable.GetTable
        function CDataTable.GetTableData(tableName, key, ...)
            local row = PhoenixtraSummon._origGetTableData(tableName, key, ...)
            if tableName == "GoldClothBattleEffect" and tonumber(key) == PhoenixtraSummon.XSUIT_ID then
                return PhoenixtraSummon.BuildInjectedBattleEffectRow(row)
            end
            return row
        end
        PhoenixtraSummon._dataHooked = true
        log("CDataTable hooked")
        return true
    end

    function PhoenixtraSummon.RegisterLogicXSuitItem()
        local LogicXSuit = safeRequire("client.slua.logic.XSuit.logic_xsuit")
        if not LogicXSuit then return false end
        pcall(function()
            if LogicXSuit.InitXSuitItemList and not LogicXSuit.bItemInfoInited then
                LogicXSuit.InitXSuitItemList()
            end
        end)
        LogicXSuit.itemInfoList = LogicXSuit.itemInfoList or {}

        LogicXSuit.itemInfoList[PhoenixtraSummon.XSUIT_ID] = {period = PhoenixtraSummon.PERIOD, level = 7}
        LogicXSuit.bItemInfoInited = true
        log("LogicXSuit registered for ID " .. tostring(PhoenixtraSummon.XSUIT_ID))
        return true
    end

    function PhoenixtraSummon.IsXSuitPlatformActor(owner)
        if not owner or not slua.isValid(owner) then return false end

        if hasMethod(owner, "TriggerCallShowSequence") and hasMethod(owner, "GetStatue") then
            return true
        end
        if hasMethod(owner, "Wearing7StarXSuit") and hasMethod(owner, "TrySetCurrentCaller") then
            return true
        end
        local name = getOwnerName(owner):lower()
        if name:find("xsuitplatform") or name:find("xsuit_platform") or name:find("goldsuitplatform") then
            return true
        end
        return false
    end

    function PhoenixtraSummon.ForceWearNow()

        if not PhoenixtraSummon.FORCE_WEAR_IN_MATCH then return false end
        local GameplayData = safeRequire("GameLua.GameCore.Data.GameplayData")
        if not GameplayData then return false end
        local character = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
        if not slua.isValid(character) then return false end
        if slua.isValid(character.CharacterAvatarComp2_BP) then
            character.CharacterAvatarComp2_BP.GoldenSuitItemID = PhoenixtraSummon.XSUIT_ID
            character.CharacterAvatarComp2_BP.XSuitItemID = PhoenixtraSummon.XSUIT_ID
        end
        return true
    end

    function PhoenixtraSummon.BlockTip49553(tipsID)

        return PhoenixtraSummon.BYPASS_7STAR_CHECK and tonumber(tipsID) == 49553
    end

    function PhoenixtraSummon.InstallTipsHooks()

        if not PhoenixtraSummon._tipsHooked then
            local tips = safeRequire("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
            if tips and type(tips.BattleNormalTipsByTextID) == "function" and not tips.__phoenixtra_patched then
                local orig = tips.BattleNormalTipsByTextID
                tips.BattleNormalTipsByTextID = function(tipsID, ...)
                    if PhoenixtraSummon.BlockTip49553(tipsID) then
                        log("blocked BattleNormalTips 49553")
                        return
                    end
                    return orig(tipsID, ...)
                end
                tips.__phoenixtra_patched = true
                PhoenixtraSummon._tipsHooked = true
                log("IngameTipsTools hooked")
            end
        end
        if not PhoenixtraSummon._gameTipsHooked and Game and type(Game.UIShowTips) == "function" and not Game.__phoenixtra_patched then
            local orig = Game.UIShowTips
            Game.UIShowTips = function(self, playerKey, textID, ...)
                if PhoenixtraSummon.BlockTip49553(textID) then
                    log("blocked Game:UIShowTips 49553")
                    return
                end
                return orig(self, playerKey, textID, ...)
            end
            Game.__phoenixtra_patched = true
            PhoenixtraSummon._gameTipsHooked = true
            log("Game:UIShowTips hooked")
        end
    end

    function PhoenixtraSummon.PatchPlatformInstance(actor)

        if not actor or actor.__phoenixtra_inst_patched then return false end
        if not PhoenixtraSummon.IsXSuitPlatformActor(actor) then return false end

        local origClick = actor.OnClientClickInteractiveButton
        actor.OnClientClickInteractiveButton = function(self, character, component)
            if PhoenixtraSummon.BYPASS_7STAR_CHECK then
                PhoenixtraSummon.ForceWearNow()
                return true
            end
            if origClick then return origClick(self, character, component) end
            return true
        end

        if hasMethod(actor, "Wearing7StarXSuit") then
            actor.Wearing7StarXSuit = function(self, character)
                if PhoenixtraSummon.BYPASS_7STAR_CHECK then return true end
                return false
            end
        end

        if hasMethod(actor, "GetWearingXSuitID") then
            actor.GetWearingXSuitID = function(self, character)
                PhoenixtraSummon.ForceWearNow()
                return PhoenixtraSummon.XSUIT_ID
            end
        end

        actor.__phoenixtra_inst_patched = true
        log("patched live platform " .. getOwnerName(actor))
        return true
    end

    function PhoenixtraSummon.PatchLivePlatformActors()

        local world = slua_GameFrontendHUD and slua_GameFrontendHUD.GetWorld and slua_GameFrontendHUD:GetWorld()
        if not slua.isValid(world) then return 0 end
        local count = 0
        pcall(function()
            local ActorTools = safeRequire("GameLua.Mod.BaseMod.Common.ActorTools")
            if not ActorTools or not ActorTools.GetAllActorsWithTag then return end
            local tags = {"XSuitPlatform", "GoldSuitPlatform", "SummonPlatform"}
            for _, tag in ipairs(tags) do
                local arr = ActorTools.GetAllActorsWithTag(world, tag)
                if arr then
                    for _, actor in pairs(arr) do
                        if PhoenixtraSummon.PatchPlatformInstance(actor) then
                            count = count + 1
                        end
                    end
                end
            end
        end)
        if count > 0 then log("PatchLivePlatformActors count=" .. tostring(count)) end
        return count
    end

    function PhoenixtraSummon.FindPlatformModule()
        local cls = safeRequire(PLATFORM_MODULE)
        if cls then return cls end
        if package and package.loaded then
            for name, mod in pairs(package.loaded) do
                if type(name) == "string" and name:find("XSuitPlatform", 1, true) and type(mod) == "table" then
                    return mod
                end
            end
        end
        return nil
    end

    function PhoenixtraSummon.PatchXSuitPlatformImpl(impl)

        if type(impl) ~= "table" or impl.__phoenixtra_patched then return false end

        local origGetWear = impl.GetWearingXSuitID
        local origGetStatue = impl.GetStatue
        local origWear = impl.Wearing7StarXSuit
        local origClientClick = impl.OnClientClickInteractiveButton

        impl.GetWearingXSuitID = function(self, character)
            if PhoenixtraSummon.FORCE_WEAR_IN_MATCH then
                PhoenixtraSummon.ForceWearNow()
                return PhoenixtraSummon.XSUIT_ID
            end
            if origGetWear then return origGetWear(self, character) end
            return 0
        end

        impl.GetStatue = function(self, suitID)
            if tonumber(suitID) == PhoenixtraSummon.XSUIT_ID then
                local cfg = PhoenixtraSummon.ResolveEffectConfig()
                return cfg.CallStatue or ""
            end
            if origGetStatue then return origGetStatue(self, suitID) end
            return ""
        end

        impl.Wearing7StarXSuit = function(self, character)
            if PhoenixtraSummon.BYPASS_7STAR_CHECK then
                local cfg = PhoenixtraSummon.ResolveEffectConfig()
                if cfg.CallStatue and cfg.CallStatue ~= "" then return true end
                return true
            end
            if origWear then return origWear(self, character) end
            return false
        end

        impl.OnClientClickInteractiveButton = function(self, character, component)
            if PhoenixtraSummon.BYPASS_7STAR_CHECK then
                PhoenixtraSummon.ForceWearNow()
                return true
            end
            if origClientClick then return origClientClick(self, character, component) end
            return true
        end

        impl.__phoenixtra_patched = true
        log("XSuitPlatform impl patched")
        return true
    end

    function PhoenixtraSummon.InstallPlatformHooks()
        if PhoenixtraSummon._platformHooked then
            PhoenixtraSummon.PatchLivePlatformActors()
            return true
        end
        local cls = PhoenixtraSummon.FindPlatformModule()
        if not cls then
            PhoenixtraSummon.PatchLivePlatformActors()
            return false
        end
        local impl = cls.__inner_impl or cls
        local ok = PhoenixtraSummon.PatchXSuitPlatformImpl(impl)
        if cls ~= impl then
            ok = PhoenixtraSummon.PatchXSuitPlatformImpl(cls) or ok
        end
        if ok then PhoenixtraSummon._platformHooked = true end
        PhoenixtraSummon.PatchLivePlatformActors()
        return PhoenixtraSummon._platformHooked
    end

    function PhoenixtraSummon.PatchBasicSkillsMenuTable(BP)

        if not BP or type(BP.Action_InteractiveComponent) ~= "function" then return false end
        if BP.__phoenixtra_patched then return true end

        local orig = BP.Action_InteractiveComponent
        BP.Action_InteractiveComponent = function(self, Param, ExtraParam)
            local Component = Param and Param.Component
            PhoenixtraSummon._lastSummonParam = {Component = Component, Param = Param, ExtraParam = ExtraParam}

            if PhoenixtraSummon.BYPASS_7STAR_CHECK and Component and Component.GetOwner then
                local owner = Component:GetOwner()
                if slua.isValid(owner) and PhoenixtraSummon.IsXSuitPlatformActor(owner) then
                    log("Action_InteractiveComponent bypass summon")
                    PhoenixtraSummon.ForceWearNow()
                    if PhoenixtraSummon.PLAY_LOCAL_SEQUENCE then
                        local cfg = PhoenixtraSummon.ResolveEffectConfig()
                        if cfg.CallStatue and cfg.CallStatue ~= "" and hasMethod(owner, "TriggerCallShowSequence") then
                            pcall(function() owner:TriggerCallShowSequence(cfg.CallStatue) end)
                        end
                    end
                    if self.HideNormalBtn then
                        pcall(function() self:HideNormalBtn("Type_InteractiveComponent", Param) end)
                    end
                    return
                end
            end

            return orig(self, Param, ExtraParam)
        end

        BP.__phoenixtra_patched = true
        log("BasicSkillsMenu Action_InteractiveComponent hooked")
        return true
    end

    function PhoenixtraSummon.InstallBasicSkillsMenuHook()
        safeRequire("GameLua.Mod.BaseMod.Client.Skill.BasicSkillsMenuBP_Actions")
        local BP = safeRequire("GameLua.Mod.BaseMod.Client.Skill.BasicSkillsMenuBP_Config")
        if not BP then return false end
        if not PhoenixtraSummon.PatchBasicSkillsMenuTable(BP) then return false end
        PhoenixtraSummon._menuHooked = true
        return true
    end

    function PhoenixtraSummon.InstallMatchEvents()

        if PhoenixtraSummon._eventsHooked then return end
        if type(EventSystem) ~= "table" or not EventSystem.AddCommonEvent then return end
        pcall(function()
            EventSystem:AddCommonEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, function(_, _, state)
                if state == "ReadyState" then
                    PhoenixtraSummon.PatchLivePlatformActors()
                    PhoenixtraSummon.ForceWearNow()
                    log("ReadyState refresh platform")
                end
            end)
            PhoenixtraSummon._eventsHooked = true
            log("match events hooked")
        end)
    end

    function PhoenixtraSummon.InstallRequireHook()

        if PhoenixtraSummon._origRequire then return end
        PhoenixtraSummon._origRequire = require
        _G.require = function(modname)
            local result = PhoenixtraSummon._origRequire(modname)
            if modname == "GameLua.Mod.BaseMod.Common.UI.InGameTipsTools" then
                PhoenixtraSummon.InstallTipsHooks()
            elseif modname == "GameLua.Mod.BaseMod.Client.Skill.BasicSkillsMenuBP_Actions" then
                PhoenixtraSummon.InstallBasicSkillsMenuHook()
            elseif modname == PLATFORM_MODULE then
                PhoenixtraSummon.InstallPlatformHooks()
            end
            return result
        end
        log("require hook installed")
    end

    function PhoenixtraSummon.PreloadAssets()

        local cfg = PhoenixtraSummon.ResolveEffectConfig()
        local PufferConst = safeRequire("client.slua.logic.download.puffer_const")
        local PufferManager = safeRequire("client.slua.logic.download.puffer.puffer_manager")
        if not PufferConst or not PufferManager then return end
        local list = {PhoenixtraSummon.XSUIT_ID, PhoenixtraSummon.FALLBACK_TEMPLATE_ID, PhoenixtraSummon.CALL_ACTION_ID}
        if cfg.CallStatue and cfg.CallStatue ~= "" then
            table.insert(list, cfg.CallStatue)
        end
        pcall(function()
            PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, list)
        end)
    end

    function PhoenixtraSummon.Install()

        PhoenixtraSummon.UpdateFromConfig()           
        PhoenixtraSummon.InstallTipsHooks()
        PhoenixtraSummon.InstallRequireHook()
        PhoenixtraSummon.InstallDataTableHooks()
        PhoenixtraSummon.ResolveEffectConfig()
        PhoenixtraSummon.RegisterLogicXSuitItem()
        PhoenixtraSummon.InstallPlatformHooks()
        PhoenixtraSummon.InstallBasicSkillsMenuHook()
        PhoenixtraSummon.InstallMatchEvents()
        PhoenixtraSummon.PreloadAssets()
        PhoenixtraSummon.ForceWearNow()
        log("Install done with XSUIT_ID=" .. tostring(PhoenixtraSummon.XSUIT_ID))
        return true
    end

    if PhoenixtraSummon.AUTO_INSTALL then
        if _G.Mytimer_ticker then

            _G.Mytimer_ticker.AddTimer(2, function()
                pcall(function() PhoenixtraSummon.Install() end)
            end)

            _G.Mytimer_ticker.AddTimerLoop(2, function()
                pcall(function()
                    if PhoenixtraSummon.UpdateFromConfig then
                        local newID = PhoenixtraSummon.UpdateFromConfig()
                        if newID then

                            if PhoenixtraSummon.XSUIT_ID ~= newID then
                                PhoenixtraSummon._resolvedEffect = nil
                                PhoenixtraSummon.Install()
                            end
                        end
                    end
                    if not PhoenixtraSummon._platformHooked then
                        PhoenixtraSummon.InstallPlatformHooks()
                    end
                    PhoenixtraSummon.ForceWearNow()
                end)
            end, -1, 1)
        else

            pcall(function() PhoenixtraSummon.Install() end)
        end
    end

    _G.PhoenixtraSummon = PhoenixtraSummon
end

if not _G.WeaponAnimationModule then
    _G.WeaponAnimationModule = {}

    local WAM = _G.WeaponAnimationModule

    WAM.LOOP = true           
    WAM.TOTAL_SEC = 60        
    WAM.AUTO_START = true     
    WAM.DEBUG = false         

    local function IsWeaponAnimEnabled()
        local configValue = nil
        if _G.lizardMH_Config and _G.lizardMH_Config.Get then
            configValue = _G.lizardMH_Config.Get("WEAPON_ANIM", nil)
        end

        if configValue ~= nil then
            return configValue == 1
        end
        return WAM.AUTO_START
    end

    WAM._enabled = IsWeaponAnimEnabled()

    function WAM.SetEnabled(enabled)
        WAM._enabled = enabled == true
        WAM.AUTO_START = WAM._enabled
        if not WAM._enabled then
            WAM.Stop()
        else
            WAM.Start()
        end

        if _G.lizardMH_Config and _G.lizardMH_Config.Set then
            _G.lizardMH_Config.Set("WEAPON_ANIM", WAM._enabled and 1 or 0)
        end
        print("[WeaponAnim] 开关状态: " .. tostring(WAM._enabled))
    end

    function WAM.IsEnabled()
        return WAM._enabled
    end

    WAM._running = false
    WAM._lastSeqActor = nil
    WAM._timer = nil
    WAM._currentChar = nil
    WAM._seqPath = nil
    WAM._actorPath = nil
    WAM._duration = 0
    WAM._origLoc = nil
    WAM._origRot = nil

    local DEFAULT_ACTOR = "/Game/Mod/EvoBase/BluePrints/Actor/BP_CharacterLevelSequenceActor.BP_CharacterLevelSequenceActor_C"

    local function log(msg)
        if WAM.DEBUG then
            print("[WeaponAnim] " .. tostring(msg))
        end
    end

    function WAM.GetCharacter()
        local ok, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not ok or not GameplayData then return nil end
        return GameplayData.GetPlayerCharacter()
    end

    function WAM.IsCharacterReady(char)
        if not char or not slua.isValid(char) then return false end
        local ok, EP = pcall(import, "EPawnState")
        if not ok then return false end

        local isStanding = (char.CurrentStates == (1 << EP.Stand))
        if isStanding and char.IsHandleInFold and char:IsHandleInFold() then
            isStanding = false
        end

        local inVehicle = char:HasState(EP.InVehicle) or char:HasState(EP.DriveVehicle)
        local isDead = char:HasState(EP.Save) or char:HasState(EP.Pick)

        return isStanding and not inVehicle and not isDead
    end

    function WAM.GetWeaponAvatarComponent(char)
        if not char or not slua.isValid(char) then return nil end
        local weapon = char.GetCurrentWeapon and char:GetCurrentWeapon()
        if slua.isValid(weapon) and slua.isValid(weapon.WeaponAvatarComponent) then
            return weapon.WeaponAvatarComponent
        end
        return nil
    end

    local function softToString(softObj)
        local result = nil
        pcall(function()
            if not softObj then return end
            if softObj.ToSoftObjectPath then
                local sp = softObj:ToSoftObjectPath()
                if sp and sp.ToString then result = sp:ToString() end
                if (not result) and sp and sp.GetAssetPathString then
                    result = sp:GetAssetPathString()
                end
            end
            if (not result) and softObj.ToString then
                result = softObj:ToString()
            end
        end)
        return result
    end

    function WAM.ResolveAnimationConfig(char)
        local seqPath, actorPath, duration = nil, nil, 0

        pcall(function()
            local wac = WAM.GetWeaponAvatarComponent(char)
            if not wac then return end

            local ES = import("EWeaponAttachmentSocketType")
            local ET = import("ECharSpecialLevelSequenceType")
            local handle = wac:GetEquippedHandle(ES.MasterGun)

            if handle and slua.isValid(handle) and handle.WeaponSpecialLevelSequenceList then
                for _, seq in pairs(handle.WeaponSpecialLevelSequenceList) do
                    if seq.LevelSequenceType == ET.ECharSpecLvSeq_WeaponCheck and seq.LevelSequenceConfig then
                        local cfg = seq.LevelSequenceConfig
                        seqPath = softToString(cfg.LevelSequence)
                        actorPath = softToString(cfg.SequenceActorTemplate)
                        duration = cfg.LevelSequenceDuration or 0
                        break
                    end
                end
            end

            if not actorPath or actorPath == "" then
                local AU = import("AvatarUtils")
                local ES2 = import("EWeaponAttachmentSocketType")
                local skinID = wac:GetEquippedItemDefineID(ES2.MasterGun).TypeSpecificID
                if skinID <= 0 then
                    local weapon = char:GetCurrentWeapon()
                    if weapon then
                        skinID = weapon:GetItemDefineID().TypeSpecificID
                    end
                end
                local base = AU.GetWeaponAvatarParentID(AU.GetBPIDByResID(skinID), false)
                local data = CDataTable.GetTableData("WeaponCheckSkill", base)
                if data and data.SequenceActorPath and data.SequenceActorPath ~= "" then
                    actorPath = data.SequenceActorPath
                end
            end
        end)

        if not actorPath or actorPath == "" then
            actorPath = DEFAULT_ACTOR
        end

        return seqPath, actorPath, duration
    end

    function WAM.PlayOnce(char)
        if not WAM._seqPath or WAM._seqPath == "" then
            log("No sequence path available")
            return false
        end

        local ok = false
        pcall(function()
            local UKismetMathLibrary = import("KismetMathLibrary")
            local transform = UKismetMathLibrary.MakeTransform(
                WAM._origLoc or char:K2_GetActorLocation(),
                WAM._origRot or char:K2_GetActorRotation(),
                FVector(1, 1, 1)
            )

            local seqActor = Game:PlayLevelSequence(
                char, WAM._seqPath, transform, 
                WAM._actorPath or DEFAULT_ACTOR, 
                false, nil, char
            )

            if slua.isValid(seqActor) then
                if seqActor.SetCharacterAndPlay then
                    seqActor:SetCharacterAndPlay(char)
                end
                char.CurrentLevelSequence = seqActor
                WAM._lastSeqActor = seqActor
                ok = true
                log("Sequence played successfully")
            end
        end)

        return ok
    end

    function WAM.IsSequenceAlive()
        return WAM._lastSeqActor and slua.isValid(WAM._lastSeqActor)
    end

    function WAM.Stop()
        if WAM._timer and WAM._currentChar and slua.isValid(WAM._currentChar) then
            pcall(function() WAM._currentChar:RemoveGameTimer(WAM._timer) end)
        end
        WAM._running = false
        WAM._timer = nil
        WAM._lastSeqActor = nil
        log("Animation stopped")
    end

    function WAM.Start()

        if not WAM._enabled then
            log("Disabled by config")
            return false
        end

        if WAM._running then
            log("Already running")
            return false
        end

        local char = WAM.GetCharacter()
        if not char or not slua.isValid(char) then
            log("No valid character")
            return false
        end

        if not WAM.IsCharacterReady(char) then
            log("Character not ready (not standing, in vehicle, or dead)")
            return false
        end

        WAM._seqPath, WAM._actorPath, WAM._duration = WAM.ResolveAnimationConfig(char)

        if not WAM._seqPath or WAM._seqPath == "" then
            log("No weapon check animation for current weapon")
            return false
        end

        if WAM._duration <= 0 then
            WAM._duration = 9
        end

        WAM._running = true
        WAM._currentChar = char
        WAM._origLoc = char:K2_GetActorLocation()
        WAM._origRot = char:K2_GetActorRotation()

        local firstSuccess = WAM.PlayOnce(char)
        if not firstSuccess then
            WAM._running = false
            log("Failed to play initial sequence")
            return false
        end

        local elapsed = 0
        local sinceReplay = 0
        local started = false

        pcall(function()
            WAM._timer = char:AddGameTimer(0.2, true, function()
                elapsed = elapsed + 0.2
                sinceReplay = sinceReplay + 0.2

                local cur = WAM.GetCharacter()
                if not cur or not slua.isValid(cur) then
                    WAM.Stop()
                    return
                end

                if not WAM.IsCharacterReady(cur) then
                    log("Character state changed, stopping")
                    WAM.Stop()
                    return
                end

                if WAM.IsSequenceAlive() then
                    started = true
                end

                if WAM.LOOP then
                    if (not WAM.IsSequenceAlive()) or sinceReplay >= (WAM._duration - 0.3) then
                        sinceReplay = 0

                        if WAM._enabled then
                            WAM.PlayOnce(cur)
                        else
                            WAM.Stop()
                        end
                    end

                    if elapsed >= WAM.TOTAL_SEC then
                        log("Total time elapsed, stopping")
                        WAM.Stop()
                    end
                else
                    if (started and not WAM.IsSequenceAlive()) or elapsed >= (WAM._duration + 1) then
                        log("Sequence completed, stopping")
                        WAM.Stop()
                    end
                end
            end)
        end)

        log("Animation started, duration=" .. tostring(WAM._duration) .. "s, loop=" .. tostring(WAM.LOOP))
        return true
    end

    function WAM.Restart()
        WAM.Stop()
        return WAM.Start()
    end

    function WAM.BindToWeaponSwitch()
        if not WAM._originalOnWeaponChanged and _G.WeaponEvents and _G.WeaponEvents.onWeaponChanged then
            WAM._originalOnWeaponChanged = _G.WeaponEvents.onWeaponChanged
            _G.WeaponEvents.onWeaponChanged = function(weaponId)
                if WAM._originalOnWeaponChanged then
                    WAM._originalOnWeaponChanged(weaponId)
                end
                if WAM._enabled then
                    pcall(function() WAM.Restart() end)
                end
            end
            log("Bound to weapon switch event")
        end
    end

    function WAM.AutoStartLoop()
        if not WAM._enabled then return end

        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimerLoop(3, function()
                pcall(function()
                    if not WAM._running and WAM._enabled then
                        local char = WAM.GetCharacter()
                        if char and slua.isValid(char) and WAM.IsCharacterReady(char) then
                            local seqPath, _, _ = WAM.ResolveAnimationConfig(char)
                            if seqPath and seqPath ~= "" then
                                WAM.Start()
                            end
                        end
                    end
                end)
            end, -1, 1)
        end

        pcall(function() WAM.Start() end)
    end

    _G.StartWeaponAnimation = WAM.Start
    _G.StopWeaponAnimation = WAM.Stop
    _G.RestartWeaponAnimation = WAM.Restart
    _G.SetWeaponAnimation = WAM.SetEnabled  

    WAM.BindToWeaponSwitch()
    WAM.AutoStartLoop()

    log("Weapon Animation Module loaded, enabled=" .. tostring(WAM._enabled))
end

pcall(function()
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")

    local title = "Announcement"
    local content = [[
重要通知：
1.全网首发不一秒裸奔美化
2.搭配外挂被封禁，后果自负！
3.请勿搭配任何改文件，出现封禁情况直接给你封禁
官方唯一频道 @lizardMH
]]

    CommonMsgBoxMgr.Show(4, title, content, nil)
end)

if _G.Mytimer_ticker then

    _G.Mytimer_ticker.AddTimerLoop(1, function()
        ReadConfigFile()
        _G.loadKillCountFromFile()
        _G.GameAvatarHandlerkillcounter()
        _G.GameAvatarHandlerplayers()
        _G.GameVehicleAvatarHandler()
        _G.GameCameraView()
        _G.HandlePetLogic()
    end, -1, 1)

end

_G.OurkillCountSystem = MyKillCountSubSystem.__inner_impl
