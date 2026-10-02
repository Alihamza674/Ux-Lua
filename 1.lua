         local _validItemPool = nil
            local function getValidItemPool()
                if _validItemPool then return _validItemPool end
                _validItemPool = {}
                for _, id in ipairs(ITEMS) do
                    local n = tonumber(id)
                    if n and n > 0 then
                        local cfg = nil
                        pcall(function()
                            if CDataTable and CDataTable.GetTableData then
                                cfg = CDataTable.GetTableData("Item", n)
                            end
                        end)
                        if cfg then
                            table.insert(_validItemPool, n)
                        end
                    end
                end
                if #_validItemPool == 0 then
                    for _, id in ipairs(ITEMS) do
                        local n = tonumber(id)
                        if n and n > 0 then table.insert(_validItemPool, n) end
                    end
                end
                return _validItemPool
            end

            -- Try to get items from the active crate UI page
            local function getCrateItemsFromUI()
                local result = {}
                pcall(function()
                    if UIManager and UIManager.UI_Config then
                        local store_supply_switcher = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.store_supply_switcher)
                        if store_supply_switcher then
                            -- Try supply system (NewSupplySystem / NewSupplySystemJK)
                            local supplySystem = store_supply_switcher:GetSupplySystem()
                            if supplySystem and supplySystem.PageListPanel and supplySystem.PageListPanel.itemDataList then
                                for _, v in pairs(supplySystem.PageListPanel.itemDataList) do
                                    if v.itemId and tonumber(v.itemId) and tonumber(v.itemId) > 0 then
                                        table.insert(result, tonumber(v.itemId))
                                    end
                                end
                            end
                            -- Try store system (NewStoreSystem)
                            if #result == 0 then
                                local storeSystem = store_supply_switcher:GetStoreSystem()
                                if storeSystem and storeSystem.PageListPanel and storeSystem.PageListPanel.itemDataList then
                                    for _, v in pairs(storeSystem.PageListPanel.itemDataList) do
                                        if v.itemId and tonumber(v.itemId) and tonumber(v.itemId) > 0 then
                                            table.insert(result, tonumber(v.itemId))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                return result
            end

            local function makeFakeItemList(count)
                count = count or 1
                local list = {}
                -- First try to get items from the active crate UI
                local pool = getCrateItemsFromUI()
                -- If no items from UI, fall back to valid item pool
                if #pool == 0 then
                    pool = getValidItemPool()
                end
                if #pool == 0 then return list end
                for i = 1, count do
                    local resId = pool[math.random(#pool)]
                    table.insert(list, {
                        resid = resId,
                        res_id = resId,
                        count = 1,
                        valid_hours = 0,
                        is_luck = (i == 1),
                        order = i,
                        drop_fun = 0,
                        must_reward = (i == 1) and 1 or 0,
                        to_res_id = 0,
                        to_res_cnt = 0,
                        ShowUseTime = true,
                        getTags = 0,
                    })
                    -- Add item to inventory so it appears in wardrobe and can be equipped
                    addItemToInventory(resId)
                end
                return list
            end

            -- Helper: make decompose_list matching item_list
            local function makeDecomposeList(itemList)
                local dec = {}
                for i, v in pairs(itemList) do
                    dec[i] = { resid = 0, count = 0 }
                end
                return dec
            end

            -- Helper: make extra_info for tarot draws
            local function makeExtraInfo()
                return {
                    cur_chest_progress = 0,
                    cur_draw_voucher_num = 0,
                    uc_cost = 0,
                    uc_ten_cost = 0,
                    can_dis_draw = false,
                    dis_draw_price = 0,
                    return_uc_count = 0,
                }
            end

            -- Helper: show the supply get panel directly (bypasses broken on_market_buy_chest_item_notify)
            local function showGetPanel(itemList, isTen)
                pcall(function()
                    local rewardList = {}
                    for _, v in pairs(itemList) do
                        table.insert(rewardList, {
                            res_id = v.res_id or v.resid,
                            count = v.count or 1,
                            valid_hours = v.valid_hours or 0,
                            getTags = v.drop_fun or 0,
                            to_res_id = v.to_res_id or 0,
                            to_res_cnt = v.to_res_cnt or 0,
                            ShowUseTime = true,
                        })
                    end
                    if UIManager and UIManager.UI_Config and UIManager.UI_Config.new_supply_get_panel then
                        if UIManager.IsUIShow and UIManager.IsUIShow(UIManager.UI_Config.new_supply_get_panel) then
                            local boxUI = UIManager.GetUI(UIManager.UI_Config.new_supply_get_panel)
                            if boxUI and boxUI.TryShowSupplyGetPanel then
                                boxUI:TryShowSupplyGetPanel(rewardList, isTen, {needShowMovie = true})
                            end
                        else
                            UIManager.ShowUI(UIManager.UI_Config.new_supply_get_panel, rewardList, isTen, {needShowMovie = true})
                        end
                    end
                end)
            end

            -- 4a. LogicSupply: bypass buy checks
            local LogicSupply = safeReq("client.slua.logic.supply.logic_supply")
            if LogicSupply and not LogicSupply._supplyHooked then
                LogicSupply._supplyHooked = true
                LogicSupply.IsCanBuySupplyBox = function(item_id) return true end
                LogicSupply.CheckHasSelectWish = function(tabId, boxItemId) return true end
                LogicSupply.CheckCrateLimitTime = function(boxEndTime) return false end
                LogicSupply.ShowTipsWhenHaveFreeBan = function(itemId, isOne) return false end
            end

            -- 4b. StoreHandler: main shop/crate buy (Ø§Ù„Ø´Ø¯Ø§Øª Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©)
            local StoreHandler = safeReq("client.network.Protocol.StoreHandler")
            if StoreHandler and not StoreHandler._crateHooked then
                StoreHandler._crateHooked = true

                -- buy_shop_by_id_req: crate buy (one or ten)
                local origBuyShop = StoreHandler.send_buy_shop_by_id_req
                StoreHandler.send_buy_shop_by_id_req = function(params)
                    local isTen = false
                    local shopId = 0
                    if type(params) == "table" then
                        -- label_buy_param_id = 1, label_buy_param_count = 8
                        shopId = tonumber(params[1]) or 0
                        local buyCount = tonumber(params[8]) or 1
                        if buyCount == 10 then isTen = true end
                    end
                    local itemList = makeFakeItemList(isTen and 10 or 1)
                    -- 1) show items in the get panel directly
                    showGetPanel(itemList, isTen)
                    -- 2) rsp: signal success + refresh UI
                    local info = { draw_flag = 0 }
                    pcall(StoreHandler.on_buy_shop_by_id_rsp, 0, shopId, info, nil)
                end

                -- buy_market_by_id_req: market buy
                local origBuyMarket = StoreHandler.send_buy_market_by_id_req
                StoreHandler.send_buy_market_by_id_req = function(params)
                    local marketId = (type(params) == "table" and tonumber(params[1])) or 0
                    local count = (type(params) == "table" and tonumber(params[8])) or 1
                    local isTen = count == 10
                    local itemList = makeFakeItemList(isTen and 10 or 1)
                    showGetPanel(itemList, isTen)
                    pcall(StoreHandler.on_buy_market_by_id_rsp, 0, marketId, itemList)
                end

                -- market chest info
                local origGetChestInfo = StoreHandler.send_get_market_chest_info_req
                StoreHandler.send_get_market_chest_info_req = function(market_id)
                    local data = { box_id = market_id, drop_items = makeFakeItemList(10) }
                    pcall(StoreHandler.on_get_market_chest_info_rsp, 0, market_id, data, makeFakeItemList(5))
                end

                -- receive_guarantee_reward_req
                local origGuarantee = StoreHandler.send_receive_guarantee_reward_req
                StoreHandler.send_receive_guarantee_reward_req = function(reward_items, is_ams_chest)
                    pcall(StoreHandler.on_receive_guarantee_reward_rsp, 0, reward_items, "")
                end

                -- do_one_draw_by_activity_req: lucky draw activity
                local origOneDraw = StoreHandler.send_do_one_draw_by_activity_req
                StoreHandler.send_do_one_draw_by_activity_req = function(activityId, roundCount, hadDrawCount, curVoucherId)
                    local itemList = makeFakeItemList(1)
                    showGetPanel(itemList, false)
                    pcall(StoreHandler.on_buy_shop_by_id_rsp, 0, activityId, { draw_flag = 0 }, nil)
                end

                -- do_biochemical_activity_one_draw_req
                local origBioDraw = StoreHandler.send_do_biochemical_activity_one_draw_req
                StoreHandler.send_do_biochemical_activity_one_draw_req = function(round_count, draw_count, voucherId)
                    local count = tonumber(draw_count) or 1
                    local itemList = makeFakeItemList(count)
                    showGetPanel(itemList, count >= 10)
                end

                -- buy_stage_chest
                local origBuyStage = StoreHandler.send_buy_stage_chest
                StoreHandler.send_buy_stage_chest = function(activity_id)
                    local itemList = makeFakeItemList(10)
                    showGetPanel(itemList, true)
                end

                -- newbie_chest_buy
                local origNewbieBuy = StoreHandler.send_newbie_chest_buy
                StoreHandler.send_newbie_chest_buy = function(activity_id)
                    local itemList = makeFakeItemList(1)
                    showGetPanel(itemList, false)
                end

                -- limited_discount_buy
                local origLimDisc = StoreHandler.send_limited_discount_buy
                StoreHandler.send_limited_discount_buy = function(activityId, index, num)
                    local count = tonumber(num) or 1
                    local itemList = makeFakeItemList(count)
                    showGetPanel(itemList, count >= 10)
                end

                -- activity_market_buy_req
                local origActMarket = StoreHandler.send_activity_market_buy_req
                StoreHandler.send_activity_market_buy_req = function(activityId)
                    local itemList = makeFakeItemList(1)
                    showGetPanel(itemList, false)
                end

                -- chest_collect_req
                local origChestCollect = StoreHandler.send_chest_collect_req
                StoreHandler.send_chest_collect_req = function(chest_id, source_type, collected_state)
                    pcall(StoreHandler.on_add_market_collect_by_item_rsp, 0, {}, source_type, chest_id, 1)
                end
            end

            -- 4c. SupplyOptionalHandler: character crate buy (Ø´Ø¯Ø§Øª Ø§Ù„Ø´Ø®ØµÙŠØ§Øª)
            local SupplyOptionalHandler = safeReq("client.network.Protocol.SupplyOptionalHandler")
            if SupplyOptionalHandler and not SupplyOptionalHandler._hooked then
                SupplyOptionalHandler._hooked = true

                local origGetInfo = SupplyOptionalHandler.send_get_role_custom_chest_info_req
                SupplyOptionalHandler.send_get_role_custom_chest_info_req = function()
                    local retInfo = {
                        must_reward_id = 0,
                        free_draw_flag = 1,
                        draw_count = 0,
                    }
                    pcall(SupplyOptionalHandler.on_get_role_custom_chest_info_rsp, 0, retInfo)
                end

                local origBuy = SupplyOptionalHandler.send_role_chest_custom_buy_req
                SupplyOptionalHandler.send_role_chest_custom_buy_req = function(priceData)
                    local drawType = (type(priceData) == "table" and tonumber(priceData.draw_type)) or 1
                    local isTen = drawType == 10
                    local itemList = makeFakeItemList(isTen and 10 or 1)
                    local decList = makeDecomposeList(itemList)
                    local otherInfo = { must_reward = 0 }
                    pcall(SupplyOptionalHandler.on_role_chest_custom_buy_rsp, 0, itemList, decList, otherInfo)
                end

                local origExchange = SupplyOptionalHandler.send_role_chest_exchange_temp_item_req
                SupplyOptionalHandler.send_role_chest_exchange_temp_item_req = function(operation_type, temp_list)
                    local retInfo = {
                        item_info = makeFakeItemList(1),
                        decompose_list = {},
                        waiting_decompose_list = {},
                    }
                    pcall(SupplyOptionalHandler.on_role_chest_exchange_temp_item_rsp, 0, retInfo)
                end

                local origHistory = SupplyOptionalHandler.send_get_role_exchange_history_info_req
                SupplyOptionalHandler.send_get_role_exchange_history_info_req = function()
                    pcall(SupplyOptionalHandler.on_get_role_exchange_history_info_rsp, 0, {}, {})
                end
            end

            -- 4d. CustomCrateHandler: custom chest data + credit (Ø´Ø¯Ø§Øª Ø§Ù„ÙƒØ±ÙŠØ¯ÙŠØª)
            local CustomCrateHandler = safeReq("client.network.Protocol.CustomCrateHandler")
            if CustomCrateHandler and not CustomCrateHandler._hooked then
                CustomCrateHandler._hooked = true

                local origGetData = CustomCrateHandler.send_custom_chest_get_data_req
                CustomCrateHandler.send_custom_chest_get_data_req = function(chest_id)
                    pcall(CustomCrateHandler.on_custom_chest_get_data_rsp, chest_id, {}, 1, 0, {})
                end

                local origGetCredit = CustomCrateHandler.send_custom_chest_get_credit_req
                CustomCrateHandler.send_custom_chest_get_credit_req = function()
                    pcall(CustomCrateHandler.on_custom_chest_get_credit_rsp, 99999, 0, {})
                end

                local origCreditExchange = CustomCrateHandler.send_custom_chest_credit_exchange_req
                CustomCrateHandler.send_custom_chest_credit_exchange_req = function()
                    pcall(CustomCrateHandler.on_custom_chest_credit_exchange_rsp, 0, makeFakeItemList(1))
                end

                local origCreditExchangeV1 = CustomCrateHandler.send_custom_chest_credit_exchange_req_v1
                CustomCrateHandler.send_custom_chest_credit_exchange_req_v1 = function()
                    pcall(CustomCrateHandler.on_custom_chest_credit_exchange_rsp, 0, makeFakeItemList(1))
                end

                local origBanItem = CustomCrateHandler.send_custom_chest_ban_item_req
                CustomCrateHandler.send_custom_chest_ban_item_req = function(chest_id, items, cost, pay_method)
                    pcall(CustomCrateHandler.on_custom_chest_ban_item_rsp, chest_id, items, 0, 0, {})
                end
            end

            -- 4e. CommonChestModeHandler: ban chest items
            local CommonChestModeHandler = safeReq("client.network.Protocol.CommonChestModeHandler")
            if CommonChestModeHandler and not CommonChestModeHandler._hooked then
                CommonChestModeHandler._hooked = true
                local orig = CommonChestModeHandler.send_custom_chest_get_items_req
                CommonChestModeHandler.send_custom_chest_get_items_req = function(chest_id)
                    pcall(CommonChestModeHandler.on_custom_chest_get_items_rsp, 0, chest_id, makeFakeItemList(10))
                end
            end

            -- 4f. TarotCardHandler: tarot card draws (Ø³Ø­Ø¨ Ø§Ù„ØªØ§Ø±ÙˆØª)
            local TarotCardHandler = safeReq("client.network.Protocol.TarotCardHandler")
            if TarotCardHandler and not TarotCardHandler._hooked then
                TarotCardHandler._hooked = true

                local origGetAct = TarotCardHandler.send_get_tarot_draw_activity_req
                TarotCardHandler.send_get_tarot_draw_activity_req = function()
                    local retTable = { draw_count = 0, free_draw_flag = 1 }
                    local poolInfo = { one_draw_cost = 0, ten_draw_cost = 0 }
                    pcall(TarotCardHandler.on_get_tarot_draw_activity_rsp, 0, retTable, poolInfo, {}, 0)
                end

                local origDraw = TarotCardHandler.send_draw_tarot_req
                TarotCardHandler.send_draw_tarot_req = function(cost_times, draw_type, voucher_id)
                    local count = (tonumber(cost_times) or 1) >= 10 and 10 or 1
                    local itemList = makeFakeItemList(count)
                    -- add rankTitleType field for tarot
                    for i, v in pairs(itemList) do
                        v.rankTitleType = 0
                        v.chief_event_share_count_bak = 0
                        v.king_event_share_count_bak = 0
                    end
                    pcall(TarotCardHandler.on_draw_tarot_rsp, 0, itemList, makeDecomposeList(itemList), makeExtraInfo())
                end

                local origProgReward = TarotCardHandler.send_get_progress_reward_req
                TarotCardHandler.send_get_progress_reward_req = function(consume_all)
                    pcall(TarotCardHandler.on_get_progress_reward_rsp, 0, 0, makeFakeItemList(1), {}, 0)
                end

                local origAttract = TarotCardHandler.send_get_taluo_attract_reward_req
                TarotCardHandler.send_get_taluo_attract_reward_req = function()
                    pcall(TarotCardHandler.on_get_taluo_attract_reward_rsp, 0, makeFakeItemList(1), 1)
                end
            end

            -- 4g. TeddyBearMonsterHandler: multi pool draw
            local TeddyBearMonsterHandler = safeReq("client.network.Protocol.TeddyBearMonsterHandler")
            if TeddyBearMonsterHandler and not TeddyBearMonsterHandler._hooked then
                TeddyBearMonsterHandler._hooked = true

                local origInfo = TeddyBearMonsterHandler.send_get_multi_pool_draw_info_req
                TeddyBearMonsterHandler.send_get_multi_pool_draw_info_req = function()
                    local drawInfo = {
                        award_pool_info = {},
                        acc_list_info = {},
                        cost_info = { one_draw_cost = 0, ten_draw_cost = 0 },
                        ext_info = {},
                    }
                    pcall(TeddyBearMonsterHandler.on_get_multi_pool_draw_info_rsp, 0, drawInfo)
                end

                local orig = TeddyBearMonsterHandler.send_multi_pool_draw_req
                TeddyBearMonsterHandler.send_multi_pool_draw_req = function(cost_times, currency_id, pool_id, voucher_id)
                    local count = (tonumber(cost_times) or 1) >= 10 and 10 or 1
                    local itemList = makeFakeItemList(count)
                    -- show items directly since RspLottery has decompile bugs
                    showGetPanel(itemList, count >= 10)
                    pcall(TeddyBearMonsterHandler.on_multi_pool_draw_rsp, 0, itemList, makeDecomposeList(itemList), {}, {})
                end

                local origAcc = TeddyBearMonsterHandler.send_get_multi_pool_acc_reward_req
                TeddyBearMonsterHandler.send_get_multi_pool_acc_reward_req = function(times)
                    pcall(TeddyBearMonsterHandler.on_get_multi_pool_acc_reward_rsp, 0, makeFakeItemList(1), {})
                end
            end

            -- 4h. XSuitHandler: gold dress draw (Ø³Ø­Ø¨ Ø¨Ø¯Ù„Ø§Øª XSuit)
            local XSuitHandler = safeReq("client.network.Protocol.XSuitHandler")
            if XSuitHandler and not XSuitHandler._goldHooked then
                XSuitHandler._goldHooked = true
                local orig = XSuitHandler.send_draw_gold_dress_req
                XSuitHandler.send_draw_gold_dress_req = function(cost_times, currency_id, voucher_id, pool_id)
                    local count = (tonumber(cost_times) or 1) >= 10 and 10 or 1
                    local itemList = makeFakeItemList(count)
                    pcall(XSuitHandler.on_draw_gold_dress_rsp, 0, itemList, makeDecomposeList(itemList), {}, 0, false, 0)
                end
            end

            -- 4i. UpassCustomChestHandler: RP custom chest
            local UpassCustomChestHandler = safeReq("client.network.Protocol.UpassCustomChestHandler")
            if UpassCustomChestHandler and not UpassCustomChestHandler._hooked then
                UpassCustomChestHandler._hooked = true

                local origExtra = UpassCustomChestHandler.send_get_rp_custom_extra_chest_req
                UpassCustomChestHandler.send_get_rp_custom_extra_chest_req = function(open_all)
                    pcall(UpassCustomChestHandler.on_get_rp_custom_extra_chest_rsp, 0, makeFakeItemList(1), 0, {})
                end

                local orig = UpassCustomChestHandler.send_open_rp_custom_chest_req
                UpassCustomChestHandler.send_open_rp_custom_chest_req = function(num, cost_type, voucher_list)
                    local count = tonumber(num) or 1
                    local itemList = makeFakeItemList(count)
                    pcall(UpassCustomChestHandler.on_open_rp_custom_chest_rsp, 0, itemList, {}, {}, makeDecomposeList(itemList))
                end
            end

            -- 4j. DropBoxHandler: drop box
            local DropBoxHandler = safeReq("client.network.Protocol.DropBoxHandler")
            if DropBoxHandler and not DropBoxHandler._hooked then
                DropBoxHandler._hooked = true
                for k, v in pairs(DropBoxHandler) do
                    if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                        local rspName = k:gsub("^send_", "on_") .. "_rsp"
                        local origFunc = v
                        DropBoxHandler[k] = function(...)
                            if DropBoxHandler[rspName] then
                                pcall(DropBoxHandler[rspName], 0, makeFakeItemList(1))
                            end
                        end
                    end
                end
            end

            -- 4k. BonusHandler: bonus boxes
            local BonusHandler = safeReq("client.network.Protocol.BonusHandler")
            if BonusHandler and not BonusHandler._hooked then
                BonusHandler._hooked = true
                for k, v in pairs(BonusHandler) do
                    if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                        local rspName = k:gsub("^send_", "on_") .. "_rsp"
                        local origFunc = v
                        BonusHandler[k] = function(...)
                            if BonusHandler[rspName] then
                                pcall(BonusHandler[rspName], 0, makeFakeItemList(1))
                            end
                        end
                    end
                end
            end

            -- 4l. ExploreHandler: explore boxes
            local ExploreHandler = safeReq("client.network.Protocol.ExploreHandler")
            if ExploreHandler and not ExploreHandler._hooked then
                ExploreHandler._hooked = true
                for k, v in pairs(ExploreHandler) do
                    if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                        local rspName = k:gsub("^send_", "on_") .. "_rsp"
                        local origFunc = v
                        ExploreHandler[k] = function(...)
                            if ExploreHandler[rspName] then
                                pcall(ExploreHandler[rspName], 0, makeFakeItemList(1))
                            end
                        end
                    end
                end
            end

            -- 4m. EveryDayPackHandler / EverydayV2PackHandler: daily packs
            local EveryDayPackHandler = safeReq("client.network.Protocol.EveryDayPackHandler")
            if EveryDayPackHandler and not EveryDayPackHandler._hooked then
                EveryDayPackHandler._hooked = true
                for k, v in pairs(EveryDayPackHandler) do
                    if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                        local rspName = k:gsub("^send_", "on_") .. "_rsp"
                        local origFunc = v
                        EveryDayPackHandler[k] = function(...)
                            if EveryDayPackHandler[rspName] then
                                pcall(EveryDayPackHandler[rspName], 0, makeFakeItemList(1))
                            end
                        end
                    end
                end
            end

            local EverydayV2PackHandler = safeReq("client.network.Protocol.EverydayV2PackHandler")
            if EverydayV2PackHandler and not EverydayV2PackHandler._hooked then
                EverydayV2PackHandler._hooked = true
                for k, v in pairs(EverydayV2PackHandler) do
                    if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                        local rspName = k:gsub("^send_", "on_") .. "_rsp"
                        local origFunc = v
                        EverydayV2PackHandler[k] = function(...)
                            if EverydayV2PackHandler[rspName] then
                                pcall(EverydayV2PackHandler[rspName], 0, makeFakeItemList(1))
                            end
                        end
                    end
                end
            end

            -- 4n. ConditionGiftHandler / GiftExchangeHandler / CorpsGiftExchangeHandler
            local function hookGenericHandler(handlerName, path)
                local H = safeReq(path)
                if H and not H._hooked then
                    H._hooked = true
                    for k, v in pairs(H) do
                        if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                            local rspName = k:gsub("^send_", "on_") .. "_rsp"
                            local origFunc = v
                            H[k] = function(...)
                                if H[rspName] then
                                    pcall(H[rspName], 0, makeFakeItemList(1))
                                end
                            end
                        end
                    end
                end
            end
            hookGenericHandler("ConditionGiftHandler", "client.network.Protocol.ConditionGiftHandler")
            hookGenericHandler("GiftExchangeHandler", "client.network.Protocol.GiftExchangeHandler")
            hookGenericHandler("CorpsGiftExchangeHandler", "client.network.Protocol.CorpsGiftExchangeHandler")
            hookGenericHandler("LadderDrawHandler", "client.network.Protocol.LadderDrawHandler")
            hookGenericHandler("PHomeDrawRewardHandler", "client.network.Protocol.PHomeDrawRewardHandler")
            hookGenericHandler("ThemeSystemHandler", "client.network.Protocol.ThemeSystemHandler")
            hookGenericHandler("TxMissionHandler", "client.network.Protocol.TxMissionHandler")
            hookGenericHandler("CustomCrateHandler2", "client.network.Protocol.CustomCrateHandler")

            -- 4o. supply_payment: bypass all payment checks (ØªØ¬Ø§ÙˆØ² Ø§Ù„Ø¯ÙØ¹)
            local supply_payment_manager = safeReq("client.slua.logic.supply.supply_payment.supply_payment_manager")
            if supply_payment_manager and not supply_payment_manager._hooked then
                supply_payment_manager._hooked = true
                if supply_payment_manager.CheckCanPay then
                    supply_payment_manager.CheckCanPay = function(...) return true end
                end
                if supply_payment_manager.CanPay then
                    supply_payment_manager.CanPay = function(...) return true end
                end
                if supply_payment_manager.CheckBeforeBuy then
                    supply_payment_manager.CheckBeforeBuy = function(...) return true end
                end
            end

            -- 4p. payment types: bypass CheckEnough (UC/BP/AG/TOKEN/EXCHANGE)
            local function bypassCheckEnough(path)
                local P = safeReq(path)
                if P and not P._checkHooked then
                    P._checkHooked = true
                    if P.CheckEnough then
                        P.CheckEnough = function(...) return true end
                    end
                end
            end
            bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_uc")
            bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_bp")
            bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_ag")
            bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_token")
            bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_exchange")
            bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_act_coin")
            bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_free")
            bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_advertisement")
            bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_other")

            -- 4p. supply_ban_manager: bypass ban restrictions
            local supply_ban_manager = safeReq("client.slua.logic.supply.supply_ban_manager")
            if supply_ban_manager and not supply_ban_manager._hooked then
                supply_ban_manager._hooked = true
                if supply_ban_manager.NotFreeToUseBanByCrateId then
                    supply_ban_manager.NotFreeToUseBanByCrateId = function(...) return false end
                end
            end

-- ============================================================
-- السطور 11300 - 12174
-- ============================================================

            end
        end)
        EndRewardPanel()
    end

    local function UpdatePlayerData(activityData, addTimes, isTenDraw)
        if not activityData then return end

        if activityData.playerData then
            local pData = activityData.playerData
            local totalDraw = pData.totalDrawTime or 0
            pData.totalDrawTime = totalDraw + addTimes

            if pData.one_draw_times ~= nil then
                local current = pData.one_draw_times or 0
                pData.one_draw_times = current + (isTenDraw and 0 or 1)
            end

            if pData.duo_draw_times ~= nil then
                local current = pData.duo_draw_times or 0
                pData.duo_draw_times = current + (isTenDraw and 1 or 0)
            end

            if pData.curLuckyValue ~= nil then
                local addLucky = isTenDraw and 10 or 1
                local maxLucky = 100
                if activityData.globalConfig and activityData.globalConfig.maxLuckyValue then
                    maxLucky = activityData.globalConfig.maxLuckyValue
                end
                pData.curLuckyValue = math.min((pData.curLuckyValue or 0) + addLucky, maxLucky)
            end

            if pData.draw_times_week ~= nil then
                pData.draw_times_week = (pData.draw_times_week or 0) + addTimes
            end

            if pData.debrisItemCount ~= nil then
                pData.debrisItemCount = (pData.debrisItemCount or 0) + addTimes
            end
        end

        if activityData.TotalSnatchTimes then
            local actId = activityData.ActivityId or 0
            local currentSnatch = activityData.TotalSnatchTimes[actId] or 0
            activityData.TotalSnatchTimes[actId] = currentSnatch + addTimes
        end

        if activityData.acc_list_info and activityData.acc_list_info.cur_times ~= nil then
            activityData.acc_list_info.cur_times = (activityData.acc_list_info.cur_times or 0) + addTimes
        end

        if activityData.DrawLogConfig then
            for _, logConfig in pairs(activityData.DrawLogConfig) do
                if logConfig.had_draw_count ~= nil then
                    logConfig.had_draw_count = (logConfig.had_draw_count or 0) + addTimes
                end
            end
        end

        if activityData.curLuckyValue ~= nil then
            local addLucky = isTenDraw and 10 or 1
            local maxLucky = 100
            if activityData.globalConfig and activityData.globalConfig.maxLuckyValue then
                maxLucky = activityData.globalConfig.maxLuckyValue
            end
            activityData.curLuckyValue = math.min((activityData.curLuckyValue or 0) + addLucky, maxLucky)
        end

        if activityData.CurRoundDrawTimes ~= nil then
            activityData.CurRoundDrawTimes = (activityData.CurRoundDrawTimes or 0) + addTimes
        end

        if activityData.draw_times_week ~= nil then
            activityData.draw_times_week = (activityData.draw_times_week or 0) + addTimes
        end

        if activityData.pool_draw_times then
            activityData.pool_draw_times = (activityData.pool_draw_times or 0) + addTimes
        end

        if activityData.totalDrawAwardConfig then
            for _, config in pairs(activityData.totalDrawAwardConfig) do
                if config.timesCount then
                    if ((activityData.totalDrawTime or 0) + addTimes) >= config.timesCount then
                        config.hasGet = true
                    end
                end
            end
        end

        if activityData.DrawActivityInfo and activityData.DrawActivityInfo.accumulate_info then
            local poolId = 10000
            activityData.pool_draw_times = (activityData.pool_draw_times or 0) + addTimes
            local currentPoolTimes = activityData.pool_draw_times
            local accInfo = activityData.DrawActivityInfo.accumulate_info[poolId]
            if accInfo then
                for reqTimes, info in pairs(accInfo) do
                    if reqTimes <= currentPoolTimes then
                        activityData.DrawActivityInfo.accumulate_info[poolId][reqTimes].state = 2
                    end
                end
            end
        end

        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_LUCKY_VALUE_UP)
        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_STATUS_CHANGE)
    end

    local lastDrawTimestamp = 0
    local isDrawBusy = false

    local function ProcessDraw(activityData, isTenDraw)
        if not activityData then return end

        local now = NowSec()
        if isDrawBusy or (now - lastDrawTimestamp < 0.9) then
            return
        end
        if not TrySpendUC(ResolveDrawUCCost(activityData, isTenDraw, isTenDraw and 10 or 1)) then
            lastDrawTimestamp = 0
            return
        end
        lastDrawTimestamp = now
        isDrawBusy = true

        local availableRewards = ExtractRewardList(activityData)
        if not availableRewards or #availableRewards == 0 then
            availableRewards = {
                {resid = 403003, count = 1, pos_id = 1, valid_hours = 0},
                {resid = 1101004046, count = 1, pos_id = 2, valid_hours = 0},
                {resid = 1101004062, count = 1, pos_id = 3, valid_hours = 0},
                {resid = 1400101, count = 1, pos_id = 4, valid_hours = 0},
                {resid = 1903193, count = 1, pos_id = 5, valid_hours = 0}
            }
        end

        local drawCount = isTenDraw and 10 or 1
        local selectedRewards = {}

        for i = 1, drawCount do
            local pickIdx = math.random(1, #availableRewards)
            local item = availableRewards[pickIdx] or availableRewards[1]
            
            table.insert(selectedRewards, {
                resid = item.resid,
                res_id = item.resid,
                count = item.count or 1,
                pos_id = item.pos_id or i,
                valid_hours = item.valid_hours or 0
            })
        end

        UpdatePlayerData(activityData, drawCount, isTenDraw)

        if activityData.dropList ~= nil then
            activityData.dropList = {}
            for i, item in pairs(selectedRewards) do
                table.insert(activityData.dropList, {
                    res_id = item.resid,
                    count = item.count,
                    valid_hours = item.valid_hours or 0,
                    pos_id = item.pos_id or i
                })
            end
        end

        if activityData.DropItem ~= nil then activityData.DropItem = selectedRewards end
        if activityData.pet_awards ~= nil then activityData.pet_awards = selectedRewards end
        if activityData.award_info ~= nil then activityData.award_info = selectedRewards end

        if isTenDraw then
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_DARW_TEN_ANIMATION, 10)
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYMULTI_LOTTERY, selectedRewards)
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBASE_ALL_DRAW_ANIM_START, 1, {1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
        else
            local posId = selectedRewards[1] and selectedRewards[1].pos_id or 1
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_DARW_ONE_ANIMATION, posId)
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBASE_ONE_DRAW_ANIM_START, 1, posId)
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYUNBACK_DARW_ANIMATION, posId)
        end

        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_STATUS_CHANGE)
        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKUNYBACK_STATUS_CHANGE)
        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_REFRESH)
        SafePostEvent(EVENTTYPE_SPIN_START_COIN_UPDATE)
        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYMULTI_REFRESH_WINDOW)

        if _G.AddTimerOnce then
            _G.AddTimerOnce(_G, 1.2, function()
                ShowRewardPanel(selectedRewards)
                isDrawBusy = false
            end)
        else
            ShowRewardPanel(selectedRewards)
            isDrawBusy = false
        end
    end

    local lastCrateTimestamp = 0
    local isCrateBusy = false

    local function ProcessCrateDrawInternal(sourceModule, boxId, times, skipSpend)
        local now = NowSec()
        if isCrateBusy or (now - lastCrateTimestamp < 0.9) then
            return nil, nil, nil, false
        end
        lastCrateTimestamp = now
        isCrateBusy = true

        local drawTimes = (type(times) == "number" and times > 0) and times or (type(boxId) == "number" and (boxId == 10 or boxId == 2) and 10) or 1
        local actualBoxId = (type(boxId) == "number" and boxId > 10) and boxId or 1
        if not skipSpend and not TrySpendUC(ResolveDrawUCCost(sourceModule, drawTimes >= 10, drawTimes)) then
            isCrateBusy = false
            lastCrateTimestamp = 0
            return nil, nil, nil, false
        end
        
        local rewards = {}
        if sourceModule then rewards = ExtractRewardList(sourceModule) end
        
        if not rewards or #rewards == 0 then
            local logic_box_draw = SafeRequire("client.slua.logic.store.logic_box_draw")
            if logic_box_draw then
                rewards = ExtractRewardList(logic_box_draw)
            end
        end

        if not rewards or #rewards == 0 then
            local logic_crate = SafeRequire("client.slua.logic.store.logic_crate") or SafeRequire("client.slua.logic.store.logic_crate_manager") or SafeRequire("client.slua.logic.store.supply_crate_manager")
            if logic_crate then rewards = ExtractRewardList(logic_crate) end
        end

        if not rewards or #rewards == 0 then
            rewards = ExtractPackageRewards(actualBoxId, 403003, drawTimes)
        end

        local selectedRewards = {}
        if rewards and #rewards > 0 then
            for i = 1, drawTimes do
                local pickIdx = math.random(1, #rewards)
                local item = rewards[pickIdx] or rewards[1]
                table.insert(selectedRewards, {
                    resid = item.resid or item.res_id or 403003,
                    res_id = item.resid or item.res_id or 403003,
                    count = item.count or item.item_count or 1,
                    item_count = item.count or item.item_count or 1,
                    valid_hours = item.valid_hours or 0
                })
            end
        else
            for i = 1, drawTimes do
                table.insert(selectedRewards, { resid = 403003, res_id = 403003, count = 1, item_count = 1, valid_hours = 0 })
            end
        end

        local logic_box_draw = SafeRequire("client.slua.logic.store.logic_box_draw")
        if logic_box_draw then
            if logic_box_draw.cur_box_info then
                local bInfo = logic_box_draw.cur_box_info
                bInfo.draw_times = (bInfo.draw_times or 0) + drawTimes
                bInfo.lucky_value = math.min((bInfo.lucky_value or 0) + drawTimes, 100)
                bInfo.had_draw_count = (bInfo.had_draw_count or 0) + drawTimes
            end
            if logic_box_draw.box_lucky_value then logic_box_draw.box_lucky_value = math.min((logic_box_draw.box_lucky_value or 0) + drawTimes, 100) end
            if logic_box_draw.cur_luck_value then logic_box_draw.cur_luck_value = math.min((logic_box_draw.cur_luck_value or 0) + drawTimes, 100) end
        end

        ShowRewardPanel(selectedRewards)
        isCrateBusy = false
        return selectedRewards, actualBoxId, drawTimes, true
    end

    _G.ApplyAllFakeCurrencies = function(target)
        local uc = GetFakeUC()
        local function enough(a, b, ...)
            local price = tonumber(b)
            if not price or price <= 0 then
                price = CaptureUCPrice(a, b, ...)
            else
                _G._lastUCCheckPrice = price
            end
            return HasEnoughUC(price)
        end
        local dMgr = target or DataMgr or _G.DataMgr or SafeRequire("client.slua.logic.common.DataMgr") or SafeRequire("client.data.DataMgr")
        if dMgr then
            dMgr.ticket = uc
            dMgr.eternal_diamond = uc
            dMgr.home_coin = uc
            dMgr.gold = uc
            dMgr.diamond = uc
            dMgr.pp = uc
            dMgr.bp = uc
            dMgr.coupon = uc
            dMgr.voucher = uc
            dMgr.fp_token = uc
            dMgr.gold_chip = uc
            dMgr.gen_ticket = uc
            dMgr.corps_money = uc
            dMgr.smelt = uc
            dMgr.battle_coin = uc
            dMgr.wow_creation_score = uc
            dMgr.ugc_advanced_crystal = uc
            dMgr.carteam_coin_count = uc
            dMgr.anchor = uc
            dMgr.anchor_origin = uc
            dMgr.uc = uc
            dMgr.UC = uc
            dMgr.money = uc
            dMgr.currency = uc
            dMgr.ag = uc
            dMgr.silver = uc

            if dMgr.roleData then
                dMgr.roleData.bgbg_vip = 1
                dMgr.roleData.level = 100
                dMgr.roleData.ticket = uc
                dMgr.roleData.gold = uc
                dMgr.roleData.diamond = uc
                dMgr.roleData.uc = uc
                -- Avatar/frame are NOT set here so hookPersonalization can control them dynamically
            end

            dMgr.GetCurrency = function(...) return GetFakeUC() end
            dMgr.GetMoney = function(...) return GetFakeUC() end
            dMgr.GetTicket = function(...) return GetFakeUC() end
            dMgr.GetUC = function(...) return GetFakeUC() end
            dMgr.GetGold = function(...) return GetFakeUC() end
            dMgr.GetDiamond = function(...) return GetFakeUC() end
            dMgr.GetMoneyByType = function(...) return GetFakeUC() end
            dMgr.CheckMoney = enough
            dMgr.CheckCurrency = enough
            dMgr.CheckTicket = enough
            dMgr.CheckUC = enough
            dMgr.CheckIsEnough = enough
            dMgr.IsMoneyEnough = enough
            dMgr.IsCurrencyEnough = enough

            if EventSystem then
                if EVENTTYPE_DATA_MGR then
                    if EVENTID_DATAMGR_GOLD_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, uc) end
                    if EVENTID_DATAMGR_TICKET_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_TICKET_CHANGE, uc) end
                    if EVENTID_DATAMGR_DIAMOND_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_DIAMOND_CHANGE, uc) end
                    if EVENTID_DATAMGR_FP_TOKEN_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_FP_TOKEN_CHANGE, uc) end
                    if EVENTID_DATAMGR_GOLD_CHIP_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHIP_CHANGE, uc) end
                    if EVENTID_DATAMGR_ROLE_LEVEL_CHANGE and dMgr.roleData then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_LEVEL_CHANGE, dMgr.roleData.level) end
                end
                if EVENTTYPE_ROLE and EVENTID_ROLE_DATA_UPDATE then SafePostEvent(EVENTTYPE_ROLE, EVENTID_ROLE_DATA_UPDATE) end
                if EVENTTYPE_STORE and EVENTID_STORE_CURRENCY_UPDATE then SafePostEvent(EVENTTYPE_STORE, EVENTID_STORE_CURRENCY_UPDATE) end
                if EVENTTYPE_WARDROBE and EVENTID_WARDROBE_TICKET_UPDATE then SafePostEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_TICKET_UPDATE) end
            end
        end

        local role_data = SafeRequire("client.slua.logic.role.role_data") or SafeRequire("client.slua.logic.role.logic_role") or SafeRequire("client.slua.logic.role.RoleData")
        if role_data then
            role_data.ticket = uc
            role_data.uc = uc
            role_data.gold = uc
            role_data.diamond = uc
            role_data.money = uc
            role_data.currency = uc
            role_data.ag = uc
            role_data.silver = uc
            role_data.GetTicket = function(...) return GetFakeUC() end
            role_data.GetUC = function(...) return GetFakeUC() end
            role_data.GetGold = function(...) return GetFakeUC() end
            role_data.GetMoney = function(...) return GetFakeUC() end
            role_data.GetDiamond = function(...) return GetFakeUC() end
            role_data.GetCurrency = function(...) return GetFakeUC() end
            role_data.GetCurrencyCount = function(...) return GetFakeUC() end
        end

        pcall(function()
            local StoreUtils = SafeRequire("client.slua.logic.store.utils.store_utils")
            if StoreUtils and StoreUtils.GetMoneyInfo then
                StoreUtils.GetMoneyInfo = function()
                    local n = GetFakeUC()
                    return { nDiamond = n, nUC = n, nSilver = n, nGold = n, nTicket = n }
                end
            end
        end)

        pcall(function()
            local Logic_ItemUtils = SafeRequire("client.slua.logic.common.Logic_ItemUtils")
            if Logic_ItemUtils and Logic_ItemUtils.GetItemCount then
                local origGIC = Logic_ItemUtils.GetItemCount
                Logic_ItemUtils.GetItemCount = function(nItemId, bForever)
                    local num = tonumber(nItemId)
                    if num == 1109 or num == 1006 or num == 1001 or num == 1002 or num == 1003 then return GetFakeUC() end
                    if _G.IsDevMat and _G.IsDevMat(num) and _G.GetFakeMat then return _G.GetFakeMat(num) end
                    return origGIC and origGIC(nItemId, bForever) or 0
                end
            end
        end)

        pcall(function()
            local logic_mall = SafeRequire("client.logic.mall.logic_mall")
            if logic_mall and logic_mall.GetItemCountInBag then
                local origGIB = logic_mall.GetItemCountInBag
                logic_mall.GetItemCountInBag = function(item_id)
                    local num = tonumber(item_id)
                    if num == 1109 or num == 1006 or num == 1001 or num == 1002 or num == 1003 then return GetFakeUC() end
                    return origGIB and origGIB(item_id) or 0
                end
            end
        end)
    end

    local dMgr = DataMgr or _G.DataMgr or SafeRequire("client.slua.logic.common.DataMgr") or SafeRequire("client.data.DataMgr")
    if dMgr then
        if dMgr.InitRoleData then
            local oldInitRoleData = dMgr.InitRoleData
            dMgr.InitRoleData = function(roleDataTb, ...)
                if oldInitRoleData then pcall(oldInitRoleData, roleDataTb, ...) end
                _G.ApplyAllFakeCurrencies(dMgr)
            end
        end

        -- Ù„Ø§ Ù†Ø³ØªØ®Ø¯Ù… setmetatable Ù„Ø£Ù†Ù‡ ÙŠØ®Ø±Ø¨ DataMgr Ø¨Ø§Ù„ÙƒØ§Ù…Ù„
        -- Ø¨Ø¯Ù„Ø§Ù‹ Ù…Ù† Ø°Ù„Ùƒ Ù†Ø·Ø¨Ù‚ Ø§Ù„Ù‚ÙŠÙ… Ù…Ø¨Ø§Ø´Ø±Ø© ÙˆÙ†Ø®Ù„ÙŠ Ø§Ù„Ù€ timer ÙŠØ¹ÙŠØ¯ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ ÙƒÙ„ Ø«Ø§Ù†ÙŠØ©
        _G.ApplyAllFakeCurrencies(dMgr)
    end

    local logic_common_pay_box = SafeRequire("client.slua.logic.common.Payclass.logic_common_pay_box")
    if logic_common_pay_box then
        logic_common_pay_box.ShowUcRechargeMsg = function() return true end
        logic_common_pay_box.ShowRechargeMsg = function() return true end
        logic_common_pay_box.ShowPayBox = function() return true end
        logic_common_pay_box.OpenPayBox = function() return true end
        logic_common_pay_box.CheckIsEnoughUC = function(_, amount, ...)
            local price = tonumber(amount) or CaptureUCPrice(amount, ...)
            return HasEnoughUC(price)
        end
    end

    local QRcodeRestrictManager = SafeRequire("client.module_framework.CommonModuleConfig.QRcodeRestrictManager")
    if QRcodeRestrictManager then
        QRcodeRestrictManager.CheckUCRestrict = function() return false end
        QRcodeRestrictManager.IsRestrictUC = function() return false end
        QRcodeRestrictManager.ShowRestrictTips = function() end
    end

    -- ====================================================================
    -- ADVANCED ACTIVITY PROTOCOL HOOKS (LUCKY SPINS, X-SUITS, SUPER AIRDROP)
    -- ====================================================================
    local luckyback_activity = SafeRequire("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if luckyback_activity then
        if luckyback_activity.do_one_draw_back_by_activity_req then
            luckyback_activity.do_one_draw_back_by_activity_req = function(arg1, arg2) ProcessDraw(luckyback_activity, arg1 == 2) end
        end
        if luckyback_activity.do_one_draw_by_tick then
            luckyback_activity.do_one_draw_by_tick = function(arg1) ProcessDraw(luckyback_activity, false) end
        end
        if luckyback_activity.get_sum_draw_award_by_activity_req then
            luckyback_activity.get_sum_draw_award_by_activity_req = function(arg1)
                local rewardList = ExtractRewardList(luckyback_activity)
                if rewardList and #rewardList > 0 then
                    local pickIdx = math.random(1, #rewardList)
                    ShowRewardPanel({ {resid = rewardList[pickIdx].resid, count = 1, valid_hours = 0} })
                end
            end
        end
    end

    local luckydouble_activity = SafeRequire("client.slua.logic.lobby_activity.logic_luckydouble_activity")
    if luckydouble_activity then
        if luckydouble_activity.send_do_one_lucky_double_draw_by_activity_req then
            luckydouble_activity.send_do_one_lucky_double_draw_by_activity_req = function(arg1, arg2, arg3, arg4) ProcessDraw(luckydouble_activity, false) end
        end
        if luckydouble_activity.send_double_draw_on_shot_req then
            luckydouble_activity.send_double_draw_on_shot_req = function(arg1, arg2, arg3, arg4) ProcessDraw(luckydouble_activity, true) end
        end
    end

    local luckyunback_activity = SafeRequire("client.slua.logic.lobby_activity.logic_luckyunback_activity")
    if luckyunback_activity then
        if luckyunback_activity.send_do_draw_discount_by_activity_req then
            luckyunback_activity.send_do_draw_discount_by_activity_req = function(arg1) ProcessDraw(luckyunback_activity, false) end
        end
    end

    local luckmix_activity = SafeRequire("client.slua.logic.lobby_activity.logic_luckmix_activity")
    if luckmix_activity then
        if luckmix_activity.DoDraw then
            luckmix_activity.DoDraw = function(arg1, arg2) ProcessDraw(luckmix_activity, arg1 == 2) end
        end
    end

    local luckymulti_activity = SafeRequire("client.slua.logic.lobby_activity.logic_luckymulti_activity")
    if luckymulti_activity then
        if luckymulti_activity.Lottery then
            luckymulti_activity.Lottery = function(arg1, arg2, arg3, arg4) ProcessDraw(luckymulti_activity, arg1 == 10) end
        end
    end

    local scrapgold_draw = SafeRequire("client.slua.logic.lobby_activity.logic_scrapgold_draw")
    if scrapgold_draw then
        if scrapgold_draw.DoDraw then
            scrapgold_draw.DoDraw = function(arg1, arg2) ProcessDraw(scrapgold_draw, arg1 == 2) end
        end
    end

    local godzilla_ban = SafeRequire("client.slua.logic.lobby_activity.logic_godzilla_ban")
    if godzilla_ban then
        if godzilla_ban.OneDraw then godzilla_ban.OneDraw = function(arg1) ProcessDraw(godzilla_ban, false) end end
        if godzilla_ban.TenDraw then godzilla_ban.TenDraw = function(arg1) ProcessDraw(godzilla_ban, true) end end
    end

    local crazy_weekend = SafeRequire("client.slua.logic.lobby_activity.crazy_weekend.logic_crazy_weekend_luckydraw")
    if crazy_weekend then
        if crazy_weekend.send_get_happy_weekend_ticket_req then
            crazy_weekend.send_get_happy_weekend_ticket_req = function()
                local tickets = {}
                for i = 1, 3 do tickets[i] = {get_time = os.time(), register_week = 1} end
                crazy_weekend.MyLuckyDraw = {}
                for key, val in pairs(tickets) do table.insert(crazy_weekend.MyLuckyDraw, {[key] = val}) end
                crazy_weekend.ticket_active = true
                SafePostEvent(EVENTTYPE_CRAZYWEEKEND, EVENTID_CRAZYWEEKEND_TICKET_UPDATE)
            end
        end
    end

    local LukcyOptionalTurntable = SafeRequire("client.slua.logic.lobby_activity.LukcyOptionalTurntable.Logic_LukcyOptionalTurntable")
    if LukcyOptionalTurntable and LukcyOptionalTurntable.SendDrawActReq then
        LukcyOptionalTurntable.SendDrawActReq = function(arg1) ProcessDraw(LukcyOptionalTurntable, arg1 == 10) end
    end

    local tarotcard_drawcard = SafeRequire("client.slua.logic.tarot_card.logic_tarotcard_drawcard")
    if tarotcard_drawcard and tarotcard_drawcard.DoDraw then
        tarotcard_drawcard.DoDraw = function(arg1, arg2) ProcessDraw(tarotcard_drawcard, arg1 == 2) end
    end

    local super_airdrop = SafeRequire("client.slua.logic.lobby_activity.logic_super_airdrop")
    if super_airdrop and super_airdrop.send_choose_and_get_super_airdrop_reward_req then
        super_airdrop.send_choose_and_get_super_airdrop_reward_req = function(arg1, arg2)
            local rewardList = ExtractRewardList(super_airdrop)
            if rewardList and #rewardList > 0 then
                local pickIdx = math.random(1, #rewardList)
                ShowRewardPanel({ {resid = rewardList[pickIdx].resid, count = 1, valid_hours = 0} })
            end
            super_airdrop.have_take_award = true
        end
    end

    local xsuit_activity = SafeRequire("client.slua.logic.XSuit.logic_xsuit_activity")
    if xsuit_activity then
        if xsuit_activity.send_do_draw_act_req then
            xsuit_activity.send_do_draw_act_req = function(arg1, arg2, arg3, arg4, arg5) ProcessDraw(xsuit_activity, arg4 == 10) end
        end
        if xsuit_activity.OnGetDrawActivityInfo then
            local old_OnGetDrawActivityInfo = xsuit_activity.OnGetDrawActivityInfo
            xsuit_activity.OnGetDrawActivityInfo = function(arg1, arg2, arg3)
                if arg2 ~= 0 then
                    local mockInfo = {
                        activity_id = 999999,
                        exchange_activity_id = 999999,
                        ex_item_id = 403003,
                        pool_info = { [1001] = { {itemid = 403003, cli_tag = 1} } },
                        draw_currency = { [1006] = {one_cost = 1, ten_cost = 10} },
                        gold_dress_one_level_id = 403003,
                        is_first_dis = true,
                        discount_uc_cost = 1,
                        accumulate_coin_count = 9999,
                        accumulate_info = { [10000] = { {} } },
                        branch_box_item_id = 403003
                    }
                    arg1.DrawActivityInfo = mockInfo
                    SafePostEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_DRAW_ACTIVITY_UPDATE)
                    return
                end
                old_OnGetDrawActivityInfo(arg1, arg2, arg3)
            end
        end
        if xsuit_activity.send_get_accumulate_pool_reward_req then
            xsuit_activity.send_get_accumulate_pool_reward_req = function(arg1, arg2)
                ShowRewardPanel({ {resid = 403003, count = arg2 or 1, valid_hours = 0} })
                local stateInfo = { [arg1] = { [arg2] = { state = 2 } } }
                if xsuit_activity.SetAccumulateStateInfo then xsuit_activity.SetAccumulateStateInfo(xsuit_activity, stateInfo) end
                SafePostEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_ACCUMULATE_POOL_REWARD)
            end
        end
    end

-- ====================================================================
    -- ACTIVITY HANDLER & ALL-SPIN NETWORK PROTOCOL INTERCEPTORS
    -- ====================================================================
    local ActivityHandler = SafeRequire("client.network.Protocol.ActivityHandler")
    if ActivityHandler then
        local function MockActivityDraw(actId, times, ...)
            if not TrySpendUC(ResolveDrawUCCost(nil, tonumber(times) == 10, times)) then return end
            local rewards = ExtractPackageRewards(actId, 403003, times or 1)
            ShowRewardPanel(rewards)
            if ActivityHandler.on_get_activity_award_rsp then ActivityHandler.on_get_activity_award_rsp(0, actId, rewards) end
            if ActivityHandler.on_common_lottery_rsp then ActivityHandler.on_common_lottery_rsp(0, actId, rewards) end
            if ActivityHandler.on_luckydraw_rsp then ActivityHandler.on_luckydraw_rsp(0, actId, rewards) end
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_STATUS_CHANGE)
        end
        ActivityHandler.send_get_activity_award_req = MockActivityDraw
        ActivityHandler.send_common_lottery_req = MockActivityDraw
        ActivityHandler.send_luckydraw_req = MockActivityDraw
        ActivityHandler.send_draw_req = MockActivityDraw
        ActivityHandler.send_open_box_req = MockActivityDraw
        ActivityHandler.send_exchange_award_req = function(actId, exchangeId, count, ...)
            ShowRewardPanel({ {resid = exchangeId, count = count or 1, valid_hours = 0} })
            if ActivityHandler.on_exchange_award_rsp then ActivityHandler.on_exchange_award_rsp(0, actId, exchangeId, count or 1) end
        end
    end

    local XSuitHandler = SafeRequire("client.network.Protocol.XSuitHandler")
    if XSuitHandler then
        XSuitHandler.send_do_draw_act_req = function(actId, subPool, useItem, count, ...)
            ProcessDraw(xsuit_activity or {}, count == 10)
        end
        XSuitHandler.send_xsuit_upgrade_req = function(xsuitId, level, ...)
            if XSuitHandler.on_xsuit_upgrade_rsp then XSuitHandler.on_xsuit_upgrade_rsp(0, xsuitId, level or 7) end
            SafePostEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_UPGRADE_SUCCESS, xsuitId, level or 7)
        end
        XSuitHandler.send_xsuit_star_upgrade_req = function(xsuitId, star, ...)
            if XSuitHandler.on_xsuit_star_upgrade_rsp then XSuitHandler.on_xsuit_star_upgrade_rsp(0, xsuitId, star or 7) end
            SafePostEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_STAR_UPGRADE_SUCCESS, xsuitId, star or 7)
        end
    end

    -- Universal Activity Draw Hook
    local logic_activity = SafeRequire("client.slua.logic.lobby_activity.logic_activity")
    if logic_activity then
        logic_activity.IsActivityOpen = function(...) return true end
        logic_activity.CheckActivityCondition = function(...) return true end
        logic_activity.CheckActivityTime = function(...) return true end
    end

        local XSuit_Get_UIBP = SafeRequire("client.slua.umg.XSuit.XSuit_Get_UIBP")
    if XSuit_Get_UIBP and XSuit_Get_UIBP.OnClickedButtonOK then
        XSuit_Get_UIBP.OnClickedButtonOK = function(arg1)
            if arg1.cfg and arg1.cfg.EndFunc then arg1.cfg.EndFunc() end
            if arg1.CloseSelf then arg1.CloseSelf(arg1) end
        end
    end

    local AsyncXSuitSpinBase = SafeRequire("client.slua.umg.lobby_activity.xsuit_spin.MainScene.AsyncXSuitSpinBase")
    if AsyncXSuitSpinBase and AsyncXSuitSpinBase.OnSpinDrawRsp then
        local old_OnSpinDrawRsp = AsyncXSuitSpinBase.OnSpinDrawRsp
        AsyncXSuitSpinBase.OnSpinDrawRsp = function(arg1, arg2, arg3, arg4, arg5)
            if not arg4 or #arg4 == 0 then
                local rewards = ExtractRewardList(arg1)
                if rewards and #rewards > 0 then
                    arg4 = {}
                    local drawCount = math.min(10, #rewards)
                    for i = 1, drawCount do
                        local pickIdx = math.random(1, #rewards)
                        table.insert(arg4, {itemid = rewards[pickIdx].resid, count = 1, valid_hours = 0})
                    end
                else
                    arg4 = { {itemid = 403003, count = 1, valid_hours = 0} }
                end
            end
            arg5 = {}
            old_OnSpinDrawRsp(arg1, arg2, arg3, arg4, arg5)
        end
    end

    local logic_ladder_draw = SafeRequire("client.slua.logic.lobby_activity.logic_ladder_draw")
    if logic_ladder_draw then
        if logic_ladder_draw.OnRotateRsp then
            local old_OnRotateRsp = logic_ladder_draw.OnRotateRsp
            logic_ladder_draw.OnRotateRsp = function(arg1)
                if not arg1 or not arg1.reward_info then
                    local rewards = ExtractRewardList(logic_ladder_draw)
                    local pickIdx = (rewards and #rewards > 0) and math.random(1, #rewards) or 1
                    local resId = (rewards and rewards[pickIdx] and rewards[pickIdx].resid) or 403003
                    arg1 = { pos = 1, last_opt_rest = 1, reward_info = { {item_id = resId, item_num = 1, valid_hours = 0} } }
                end
                old_OnRotateRsp(arg1)
                SafePostEvent(EVENTTYPE_LADDER_DRAW, EVENTID_LADDER_DRAW_ROTATE)
            end
        end
        if logic_ladder_draw.OnRandomAwardRsp then
            local old_OnRandomAwardRsp = logic_ladder_draw.OnRandomAwardRsp
            logic_ladder_draw.OnRandomAwardRsp = function(arg1)
                if not arg1 or not arg1.real_list then
                    local rewards = ExtractRewardList(logic_ladder_draw)
                    local pickIdx = (rewards and #rewards > 0) and math.random(1, #rewards) or 1
                    local resId = (rewards and rewards[pickIdx] and rewards[pickIdx].resid) or 403003
                    local mockItem = {resid = resId, count = 1, valid_hours = 0}
                    arg1 = { real_list = {mockItem}, reward_list = {mockItem}, decompose_list = {} }
                end
                old_OnRandomAwardRsp(arg1)
                SafePostEvent(EVENTTYPE_LADDER_DRAW, EVENTID_LADDER_DRAW_RANDOM_AWARD)
            end
        end
        if logic_ladder_draw.OnRecvAwardRsp then
            local old_OnRecvAwardRsp = logic_ladder_draw.OnRecvAwardRsp
            logic_ladder_draw.OnRecvAwardRsp = function(arg1)
                if not arg1 or not arg1.real_list then
                    local rewards = ExtractRewardList(logic_ladder_draw)
                    local pickIdx = (rewards and #rewards > 0) and math.random(1, #rewards) or 1
                    local resId = (rewards and rewards[pickIdx] and rewards[pickIdx].resid) or 403003
                    local mockItem = {resid = resId, count = 1, valid_hours = 0}
                    arg1 = { real_list = {mockItem}, reward_list = {mockItem}, decompose_list = {} }
                end
                old_OnRecvAwardRsp(arg1)
                ShowRewardPanel(arg1.real_list)
                SafePostEvent(EVENTTYPE_LADDER_DRAW, EVENTID_LADDER_DRAW_RECV_AWARD)
            end
        end
    end

    local SportsCarSpinMainBase = SafeRequire("client.slua.umg.lobby_activity.SportsCarSpin.SportsCarSpinMainBase")
    if SportsCarSpinMainBase then
        if SportsCarSpinMainBase.OnBeginLottery then
            local oldOnBeginLottery = SportsCarSpinMainBase.OnBeginLottery
            SportsCarSpinMainBase.OnBeginLottery = function(arg1)
                local rewards = ExtractRewardList(logic_ladder_draw)
                if rewards and #rewards > 0 then
                    local pickIdx = math.random(1, #rewards)
                    local mockInfo = { pos = 1, last_opt_rest = 1, reward_info = { {item_id = rewards[pickIdx].resid, item_num = 1, valid_hours = 0} } }
                    if logic_ladder_draw and logic_ladder_draw.svrDrawData then logic_ladder_draw.svrDrawData[arg1.nActID] = mockInfo end
                    SafePostEvent(EVENTTYPE_LADDER_DRAW, EVENTID_LADDER_DRAW_ROTATE)
                    if arg1.fsm and arg1.fsm.ConvertResult then arg1.fsm.ConvertResult(arg1.fsm) end
                else
                    oldOnBeginLottery(arg1)
                end
            end
        end
        if SportsCarSpinMainBase.ReceiveAward then
            local oldReceiveAward = SportsCarSpinMainBase.ReceiveAward
            SportsCarSpinMainBase.ReceiveAward = function(arg1)
                local rewards = ExtractRewardList(logic_ladder_draw)
                if rewards and #rewards > 0 then
                    local pickIdx = math.random(1, #rewards)
                    ShowRewardPanel({ {resid = rewards[pickIdx].resid, count = 1, valid_hours = 0} })
                    if arg1.fsm and arg1.fsm.ConvertIdle then arg1.fsm.ConvertIdle(arg1.fsm) end
                else
                    oldReceiveAward(arg1)
                end
            end
        end
    end

    local SportsCarExchangeComponentItem = SafeRequire("client.slua.umg.lobby_activity.SportsCarSpin.Exchange.SportsCarExchangeComponentItem")
    if SportsCarExchangeComponentItem and SportsCarExchangeComponentItem.OnClick_Exchange then
        SportsCarExchangeComponentItem.OnClick_Exchange = function(arg1)
            local itemData = arg1.itemWidgetList and arg1.itemWidgetList.GetSubItemData and arg1.itemWidgetList.GetSubItemData(arg1.itemWidgetList, arg1._curSelectItemIndex, arg1._curSelectSubItemIndex)
            if itemData then
                local resId = itemData[StoreConst and StoreConst.label_item_index_id or "id"] or 403003
                ShowRewardPanel({ {resid = resId, count = 1, valid_hours = 0} })
                if arg1.UpdateCurrency then arg1.UpdateCurrency(arg1) end
                if arg1.itemWidgetList and arg1.itemWidgetList.RefreshAllSubItems then arg1.itemWidgetList.RefreshAllSubItems(arg1.itemWidgetList) end
            end
        end
    end

    local logic_spin_preorder = SafeRequire("client.module_framework.JumpModuleConfig.logic_spin_preorder")
    if not logic_spin_preorder and ModuleManager and ModuleManager.LobbyModuleConfig and ModuleManager.LobbyModuleConfig.logic_spin_preorder then
       logic_spin_preorder = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_spin_preorder)
    end
    if logic_spin_preorder and logic_spin_preorder.SendBuyItem then
        logic_spin_preorder.SendBuyItem = function(arg1, arg2)
            if not TrySpendUC(CaptureUCPrice(arg1, arg2)) then return end
            ShowRewardPanel({ {resid = arg1.itemId, count = arg2 or 1, valid_hours = 0} })
            SafePostEvent(EVENTTYPE_SPIN_PREORDER, EVENTID_SPIN_PREORDER_UPDATE)
        end
    end

    -- ====================================================================
    -- STORE, MALL, CRATE & DIRECT PURCHASE PROTOCOL HOOKS
    -- ====================================================================
    local StoreHandler = SafeRequire("client.network.Protocol.StoreHandler")
    if StoreHandler then
        local function MockBuyWithUC(params, onSuccess)
            local cost = GetBuyUCCost(params)
            if not TrySpendUC(cost) then
                return false
            end
            if onSuccess then onSuccess() end
            return true
        end
        StoreHandler.send_buy_req = function(arg1, arg2, ...)
            if not BeginBuyAction("sbuy:" .. tostring(arg1)) then return end
            if not TrySpendUC(GetBuyUCCost(arg1) > 0 and GetBuyUCCost(arg1) or CaptureUCPrice(arg1, arg2, ...)) then return end
            ShowRewardPanel({ {resid = arg1, count = arg2 or 1, valid_hours = 0} })
            if StoreHandler.on_buy_rsp then StoreHandler.on_buy_rsp(0, { {res_id = arg1, count = arg2 or 1, valid_hours = 0} }, arg1, arg2 or 1) end
        end
        StoreHandler.send_easy_buy_req = function(arg1, arg2, ...)
            if not BeginBuyAction("seasy:" .. tostring(arg1)) then return end
            if not TrySpendUC(CaptureUCPrice(arg1, arg2, ...)) then return end
            ShowRewardPanel({ {resid = arg1, count = arg2 or 1, valid_hours = 0} })
            if StoreHandler.on_easy_buy_rsp then StoreHandler.on_easy_buy_rsp(0, arg1, arg2 or 1) end
        end
        StoreHandler.send_batch_buy_req = function(arg1, arg2, ...)
            if not TrySpendUC(GetBuyUCCost(arg1)) then return end
            local rewards = ExtractPackageRewards(arg1, arg1, arg2 or 1)
            ShowRewardPanel(rewards)
            if StoreHandler.on_batch_buy_rsp then StoreHandler.on_batch_buy_rsp(0, rewards, arg1, arg2 or 1) end
        end
        StoreHandler.send_buy_goods_req = function(arg1, arg2, ...)
            if not TrySpendUC(GetBuyUCCost(arg1)) then return end
            local rewards = ExtractPackageRewards(arg1, arg1, arg2 or 1)
            ShowRewardPanel(rewards)
            if StoreHandler.on_buy_goods_rsp then StoreHandler.on_buy_goods_rsp(0, arg1, arg2 or 1) end
        end
        StoreHandler.send_buy_shop_by_id_req = function(params)
            local cost = GetBuyUCCost(params)
            if not TrySpendUC(cost) then
                if StoreHandler.on_buy_shop_by_id_rsp then StoreHandler.on_buy_shop_by_id_rsp(2, params and params[1], nil, nil) end
                return
            end
            local shopId = params and (params[1] or params.id) or 1
            local count = tonumber(params and (params[8] or params.count)) or 1
            local rewards, _, _, ok = ProcessCrateDrawInternal(nil, shopId, count, true)
            if not ok or not rewards or #rewards == 0 then
                rewards = ExtractPackageRewards(shopId, shopId, count)
            end
            if not rewards or #rewards == 0 then
                rewards = { { resid = shopId, res_id = shopId, count = count, valid_hours = 0 } }
            end
            AutoAddToInventory(rewards)
            ShowRewardPanel(rewards)
            local info = { draw_flag = 0 }
            for i, r in ipairs(rewards) do
                info[i] = { [1] = r.resid or r.res_id or shopId, [2] = r.count or 1, [3] = r.valid_hours or 0 }
            end
            if StoreHandler.on_buy_shop_by_id_rsp then StoreHandler.on_buy_shop_by_id_rsp(0, shopId, info, nil) end
        end
        StoreHandler.send_buy_market_by_id_req = function(params)
            local cost = GetBuyUCCost(params)
            if not TrySpendUC(cost) then
                if StoreHandler.on_buy_market_by_id_rsp then StoreHandler.on_buy_market_by_id_rsp(2, params and params[1], nil) end
                return
            end
            local itemId = params and (params[1] or params.id) or 1
            local count = tonumber(params and (params[8] or params.count)) or 1
            local validHours = tonumber(params and (params[7] or params.valid_hours)) or 0
            local rewards = ExtractPackageRewards(itemId, itemId, count)
            if not rewards or #rewards == 0 then
                rewards = { { resid = itemId, res_id = itemId, count = count, valid_hours = validHours } }
            end
            AutoAddToInventory(rewards)
            ShowRewardPanel(rewards)
            local info = {}
            for i, r in ipairs(rewards) do
                info[i] = { [1] = r.resid or r.res_id or itemId, [2] = r.count or 1, [3] = r.valid_hours or 0 }
            end
            if StoreHandler.on_buy_market_by_id_rsp then StoreHandler.on_buy_market_by_id_rsp(0, itemId, info) end
        end
        StoreHandler.send_do_one_draw_by_activity_req = function(ActivityID, Round_Count, Had_Draw_Count, CurVoucherId)
            local lucky = SafeRequire("client.slua.logic.lobby_activity.logic_luckyback_activity")
                or SafeRequire("client.slua.logic.lobby_activity.logic_luckyunback_activity")
            ProcessDraw(lucky or {}, tonumber(Round_Count) == 2 or tonumber(Round_Count) == 10)
        end
        StoreHandler.send_do_draw_discount_by_activity_req = function(activity_id, round_id, had_draw_count)
            local lucky = SafeRequire("client.slua.logic.lobby_activity.logic_luckyunback_activity")
            ProcessDraw(lucky or {}, false)
        end
        StoreHandler.send_do_biochemical_activity_one_draw_req = function(round_count, draw_count, voucherId)
            ProcessDraw({}, tonumber(draw_count) == 10)
        end
        StoreHandler.send_limited_discount_buy = function(activityId, index, num)
            if not TrySpendUC(CaptureUCPrice(activityId, index, num)) then return end
            local rewards = { {resid = activityId or 403003, count = num or 1, valid_hours = 0} }
            AutoAddToInventory(rewards)
            ShowRewardPanel(rewards)
        end
        StoreHandler.send_newbie_chest_buy = function(activity_id)
            if not TrySpendUC(CaptureUCPrice(activity_id) > 0 and CaptureUCPrice(activity_id) or 10) then return end
            local rewards = { {resid = 403003, count = 1, valid_hours = 0} }
            AutoAddToInventory(rewards)
            ShowRewardPanel(rewards)
        end
        StoreHandler.send_buy_stage_chest = function(activity_id)
            if not TrySpendUC(CaptureUCPrice(activity_id) > 0 and CaptureUCPrice(activity_id) or 10) then return end
            local rewards = { {resid = 403003, count = 1, valid_hours = 0} }
            AutoAddToInventory(rewards)
            ShowRewardPanel(rewards)
        end
    end

-- ============================================================
-- السطور 12773 - 12874
-- ============================================================

    -- ====================================================================
    -- STORE & CRATE ZERO-CHECK DRAW ENGINE & PROTOCOL HOOKS
    -- ====================================================================
    local logic_box_draw = SafeRequire("client.slua.logic.store.logic_box_draw")
    if logic_box_draw then
        logic_box_draw.CheckCanDraw = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckCanBuy = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckMoney = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckCurrency = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckIsEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.IsMoneyEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.IsCurrencyEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.IsTicketEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.IsUCEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckCanDrawBox = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckDrawCondition = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.GetCurrencyNum = function(...) return GetFakeUC() end
        logic_box_draw.GetMoneyNum = function(...) return GetFakeUC() end
        logic_box_draw.GetTicketNum = function(...) return GetFakeUC() end
        logic_box_draw.GetUCNum = function(...) return GetFakeUC() end

        local function MockLogicBoxDraw(boxId, times, ...)
            local rewards, actBoxId, drawTimes, ok = ProcessCrateDrawInternal(logic_box_draw, boxId, times)
            if not ok then return false end
            if logic_box_draw.OnBoxDrawRsp then
                logic_box_draw.OnBoxDrawRsp(0, rewards, actBoxId, drawTimes)
            elseif logic_box_draw.OnDrawRsp then
                logic_box_draw.OnDrawRsp(0, rewards, actBoxId, drawTimes)
            end
            SafePostEvent(EVENTTYPE_STORE, EVENTID_BOX_DRAW_RSP, rewards)
            SafePostEvent(EVENTTYPE_STORE, EVENTID_STORE_BOX_UPDATE)
            return true
        end
        logic_box_draw.DoDraw = MockLogicBoxDraw
        logic_box_draw.ReqDraw = MockLogicBoxDraw
        logic_box_draw.OpenBox = MockLogicBoxDraw
        logic_box_draw.SendBoxDrawReq = MockLogicBoxDraw
        logic_box_draw.DoBoxDraw = MockLogicBoxDraw
    end

    local logic_crate = SafeRequire("client.slua.logic.store.logic_crate") or SafeRequire("client.slua.logic.store.logic_crate_manager") or SafeRequire("client.slua.logic.store.supply_crate_manager")
    if logic_crate then
        local function MockLogicCrate(crateId, times, ...)
            local rewards, actCrateId, drawTimes, ok = ProcessCrateDrawInternal(logic_crate, crateId, times)
            if not ok then return false end
            if logic_crate.OnOpenCrateRsp then
                logic_crate.OnOpenCrateRsp(0, rewards, actCrateId, drawTimes)
            elseif logic_crate.OnDrawCrateRsp then
                logic_crate.OnDrawCrateRsp(0, rewards, actCrateId, drawTimes)
            end
            return true
        end
        if logic_crate.OpenCrate then logic_crate.OpenCrate = MockLogicCrate end
        if logic_crate.DrawCrate then logic_crate.DrawCrate = MockLogicCrate end
        if logic_crate.SendOpenCrateReq then logic_crate.SendOpenCrateReq = MockLogicCrate end
        if logic_crate.OpenBox then logic_crate.OpenBox = MockLogicCrate end
        if logic_crate.DrawBox then logic_crate.DrawBox = MockLogicCrate end
        if logic_crate.CheckCanOpen then logic_crate.CheckCanOpen = function(...) return true end end
    end

    local logic_store = SafeRequire("client.slua.logic.store.logic_store")
    if logic_store then
        logic_store.CheckCurrency = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_store.CheckMoney = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_store.IsMoneyEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_store.IsCurrencyEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_store.CheckIsEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_store.CheckBuyLimit = function(...) return true end
        logic_store.DoBuy = function(self, goodsId, count, ...)
            if not BeginBuyAction("store:" .. tostring(goodsId)) then return false end
            if not TrySpendUC(CaptureUCPrice(goodsId, count, ...)) then return false end
            local rewards = ExtractPackageRewards(goodsId, goodsId, count or 1)
            ShowRewardPanel(rewards)
            if logic_store.OnBuyRsp then logic_store.OnBuyRsp(0, rewards, goodsId, count or 1) end
            return true
        end
    end

    local BoxDrawHandler = SafeRequire("client.network.Protocol.BoxDrawHandler")
    if BoxDrawHandler then
        local function MockBoxDrawHandler(arg1, arg2, ...)
            local rewards, boxId, drawTimes, ok = ProcessCrateDrawInternal(BoxDrawHandler, arg1, arg2)
            if not ok then return end
            if BoxDrawHandler.on_box_draw_rsp then
                BoxDrawHandler.on_box_draw_rsp(0, rewards, boxId, drawTimes)
            elseif BoxDrawHandler.on_draw_rsp then
                BoxDrawHandler.on_draw_rsp(0, rewards, boxId, drawTimes)
            elseif BoxDrawHandler.on_open_box_rsp then
                BoxDrawHandler.on_open_box_rsp(0, rewards, boxId, drawTimes)
            elseif BoxDrawHandler.on_lottery_rsp then
                BoxDrawHandler.on_lottery_rsp(0, rewards, boxId, drawTimes)
            end
            SafePostEvent(EVENTTYPE_STORE, EVENTID_BOX_DRAW_RSP, rewards)
            SafePostEvent(EVENTTYPE_STORE, EVENTID_STORE_BOX_UPDATE)
        end
        BoxDrawHandler.send_box_draw_req = MockBoxDrawHandler
        BoxDrawHandler.send_draw_req = MockBoxDrawHandler
        BoxDrawHandler.send_open_box_req = MockBoxDrawHandler
        BoxDrawHandler.send_lottery_req = MockBoxDrawHandler
        BoxDrawHandler.send_crate_draw_req = MockBoxDrawHandler
        BoxDrawHandler.send_open_crate_req = MockBoxDrawHandler
    end

-- ============================================================
-- السطور 13299 - 13389
-- ============================================================

    -- ====================================================================
    -- SUPPLY BAN MANAGER & SUPPLY CREDIT MANAGER HOOKS
    -- hook ban items manager and credit manager for crates
    -- ====================================================================
    local supply_ban_manager = SafeRequire("client.slua.logic.supply.supply_ban_manager")
    if supply_ban_manager then
        -- RequestCustomCrateInfo: instant empty data (no ban, free available)
        if supply_ban_manager.RequestCustomCrateInfo then
            local oldReq = supply_ban_manager.RequestCustomCrateInfo
            supply_ban_manager.RequestCustomCrateInfo = function(self, crateId, ...)
                if self and self.SupplyBanInfo then
                    self.SupplyBanInfo[crateId] = {}
                    self.SupplyBanFree[crateId] = false
                    self.SupplyBanProbability[crateId] = {}
                    local param = { crateId = crateId, data = { usedFree = false, banItems = {}, probability = {} } }
                    EventSystem:postEvent(EVENTTYPE_STORE_DATA, EVENTID_CRATE_BAN_DATA, param)
                else
                    oldReq(self, crateId, ...)
                end
            end
        end
        -- RequestCustomBanCrateItems: instant success
        if supply_ban_manager.RequestCustomBanCrateItems then
            supply_ban_manager.RequestCustomBanCrateItems = function(self, crateId, items, cost, pay_method)
                if self and self.RespondCustomBanCrateItems then
                    self:RespondCustomBanCrateItems(crateId, items, cost, 0)
                end
            end
        end
        -- NotFreeToUseBanByCrateId: return false (always free)
        if supply_ban_manager.NotFreeToUseBanByCrateId then
            supply_ban_manager.NotFreeToUseBanByCrateId = function(self, crateId)
                return false
            end
        end
        log("supply_ban_manager hooks active")
    end

    local supply_credit_manager = SafeRequire("client.slua.logic.supply.supply_credit_manager")
    if supply_credit_manager then
        -- RequestJPKRCreditInfo: instant high credit response
        if supply_credit_manager.RequestJPKRCreditInfo then
            supply_credit_manager.RequestJPKRCreditInfo = function(self, ...)
                if self then
                    self.SupplyCreditInfo = self.SupplyCreditInfo or {}
                    self.SupplyCreditInfo.haveData = true
                    self.SupplyCreditInfo.credit = 99999
                    self.SupplyCreditInfo.state_data = {}
                end
                EventSystem:postEvent(EVENTTYPE_STORE_DATA, EVENTID_CRATE_JPKR_CREDIT, {haveData = true, credit = 99999, state_data = {}})
            end
        end
        -- RespondJPKRCreditInfo: accept any credit
        if supply_credit_manager.RespondJPKRCreditInfo then
            local oldRespond = supply_credit_manager.RespondJPKRCreditInfo
            supply_credit_manager.RespondJPKRCreditInfo = function(self, credit, change_credit, state_data)
                if self then
                    self.SupplyCreditInfo = self.SupplyCreditInfo or {}
                    self.SupplyCreditInfo.haveData = true
                    self.SupplyCreditInfo.credit = credit or 99999
                    self.SupplyCreditInfo.state_data = state_data or {}
                end
                EventSystem:postEvent(EVENTTYPE_STORE_DATA, EVENTID_CRATE_JPKR_CREDIT, self.SupplyCreditInfo)
            end
        end
        -- RequestCrateCreditExchangeTicket: instant success
        if supply_credit_manager.RequestCrateCreditExchangeTicket then
            supply_credit_manager.RequestCrateCreditExchangeTicket = function(self, ...)
                if self and self.RespondCrateCreditExchangeTicket then
                    self:RespondCrateCreditExchangeTicket(0, { {resid = 403003, count = 1, valid_hours = 0} })
                end
            end
        end
        -- RespondCrateCreditExchangeTicket: accept any response
        if supply_credit_manager.RespondCrateCreditExchangeTicket then
            local oldExch = supply_credit_manager.RespondCrateCreditExchangeTicket
            supply_credit_manager.RespondCrateCreditExchangeTicket = function(self, err_code, itemList)
                if err_code ~= 0 then
                    ShowRewardPanel({ {resid = 403003, count = 1, valid_hours = 0} })
                    return
                end
                if itemList and next(itemList) then
                    ShowRewardPanel(itemList)
                else
                    ShowRewardPanel({ {resid = 403003, count = 1, valid_hours = 0} })
                end
                EventSystem:postEvent(EVENTTYPE_STORE_DATA, EVENTID_CRATE_JPKR_CREDIT_EXCHANGE)
            end
        end
        log("supply_credit_manager hooks active")
    end
