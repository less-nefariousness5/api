------------------------------------------------------------
-- core.auction_house - Auction House API
-- Type annotations for IDE autocompletion.
------------------------------------------------------------

---@class ReplicateItemInfo
---@field name string
---@field texture integer
---@field count integer
---@field quality_id integer
---@field usable boolean
---@field level integer
---@field level_type string
---@field min_bid number
---@field min_increment number
---@field buyout_price number
---@field bid_amount number
---@field high_bidder string
---@field owner string
---@field sale_status integer
---@field item_id integer
---@field has_all_info boolean

---@class CommoditySearchResultInfo
---@field item_id integer
---@field quantity integer
---@field unit_price number
---@field auction_id integer
---@field num_owner_items integer
---@field contains_owner_item boolean
---@field contains_account_item boolean

---@class ItemSearchResultInfo
---@field item_id integer
---@field auction_id integer
---@field quantity integer
---@field bid_amount number
---@field buyout_amount number
---@field min_bid number
---@field time_left integer
---@field item_link string
---@field contains_owner_item boolean
---@field contains_account_item boolean

---@class OwnedAuctionInfo
---@field auction_id integer
---@field item_id integer
---@field item_link string
---@field status integer
---@field quantity integer
---@field time_left integer
---@field bid_amount number
---@field buyout_amount number
---@field bidder string

---@class AHItemInfo
---@field name string
---@field item_link string
---@field quality integer
---@field item_level integer
---@field min_level integer
---@field item_type string
---@field item_sub_type string
---@field stack_count integer
---@field equip_loc string
---@field texture integer
---@field sell_price integer
---@field bind_type integer

---@class TooltipLine
---@field left string
---@field right string
---@field r number
---@field g number
---@field b number

---@class core.auction_house
core.auction_house = {}

-- Replicate (full AH scan)
---@return nil
function core.auction_house.replicate_items() end

---@return integer
function core.auction_house.get_num_replicate_items() end

---@param index integer
---@return ReplicateItemInfo
function core.auction_house.get_replicate_item_info(index) end

---@param index integer
---@return string
function core.auction_house.get_replicate_item_link(index) end

---@param index integer
---@return integer
function core.auction_house.get_replicate_item_time_left(index) end

---@param start integer
---@param count integer
---@return string
function core.auction_house.batch_get_replicate_items(start, count) end

-- Search queries
---@param item_id integer
---@param item_level? integer
---@param item_suffix? integer
---@param separate_owner_items? boolean
---@return nil
function core.auction_house.send_search_query(item_id, item_level, item_suffix, separate_owner_items) end

---@param item_id integer
---@param item_level? integer
---@param item_suffix? integer
---@param separate_owner_items? boolean
---@return nil
function core.auction_house.send_sell_search_query(item_id, item_level, item_suffix, separate_owner_items) end

-- Commodity search results
---@param item_id integer
---@return integer
function core.auction_house.get_num_commodity_search_results(item_id) end

---@param item_id integer
---@param index integer
---@return CommoditySearchResultInfo
function core.auction_house.get_commodity_search_result_info(item_id, index) end

---@param item_id integer
---@return boolean
function core.auction_house.has_full_commodity_search_results(item_id) end

-- Item search results
---@param item_id integer
---@param item_level? integer
---@param item_suffix? integer
---@return integer
function core.auction_house.get_num_item_search_results(item_id, item_level, item_suffix) end

---@param item_id integer
---@param item_level? integer
---@param item_suffix? integer
---@param index integer
---@return ItemSearchResultInfo
function core.auction_house.get_item_search_result_info(item_id, item_level, item_suffix, index) end

---@param item_id integer
---@param item_level? integer
---@param item_suffix? integer
---@return boolean
function core.auction_house.has_full_item_search_results(item_id, item_level, item_suffix) end

-- Owned auctions
---@return nil
function core.auction_house.query_owned_auctions() end

---@return integer
function core.auction_house.get_num_owned_auctions() end

---@param index integer
---@return OwnedAuctionInfo
function core.auction_house.get_owned_auction_info(index) end

-- Posting
---@param bag integer
---@param slot integer
---@param duration integer
---@param quantity integer
---@param unit_price number
---@return boolean
function core.auction_house.post_commodity(bag, slot, duration, quantity, unit_price) end

---@param bag integer
---@param slot integer
---@param duration integer
---@param quantity integer
---@param bid number
---@param buyout number
---@return boolean
function core.auction_house.post_item(bag, slot, duration, quantity, bid, buyout) end

-- Purchasing
---@param auction_id integer
---@param bid_amount number
---@return nil
function core.auction_house.place_bid(auction_id, bid_amount) end

---@param item_id integer
---@param quantity integer
---@return nil
function core.auction_house.start_commodities_purchase(item_id, quantity) end

---@param item_id integer
---@param quantity integer
---@return nil
function core.auction_house.confirm_commodities_purchase(item_id, quantity) end

---@return nil
function core.auction_house.cancel_commodities_purchase() end

-- Cancel
---@param owned_auction_id integer
---@return nil
function core.auction_house.cancel_auction(owned_auction_id) end

---@param owned_auction_id integer
---@return boolean
function core.auction_house.can_cancel_auction(owned_auction_id) end

-- Costs
---@param item_id integer
---@param duration integer
---@param quantity integer
---@return number
function core.auction_house.calculate_commodity_deposit(item_id, duration, quantity) end

---@param owned_auction_id integer
---@return number
function core.auction_house.get_cancel_cost(owned_auction_id) end

-- Utility
---@return boolean
function core.auction_house.is_throttled_message_system_ready() end

---@return nil
function core.auction_house.close_auction_house() end

---@return number
function core.auction_house.get_quote_duration_remaining() end

---@param bag integer
---@param slot integer
---@return integer
function core.auction_house.get_item_commodity_status(bag, slot) end

-- Item data
---@param item_id integer
---@return AHItemInfo
function core.auction_house.get_item_info(item_id) end

---@param item_id integer
---@return string
function core.auction_house.get_item_icon_name(item_id) end

---@param item_id integer
---@param link_fragment? string
---@return TooltipLine[]
function core.auction_house.get_item_tooltip(item_id, link_fragment) end

-- Individual AH operations (Classic)
---@param bag integer
---@param slot integer
---@return nil
function core.auction_house.pickup_container_item(bag, slot) end

---@return nil
function core.auction_house.click_auction_sell_button() end

---@param min_bid number
---@param buyout number
---@param duration integer
---@param stack_size? integer
---@param num_stacks? integer
---@return boolean
function core.auction_house.do_post_auction(min_bid, buyout, duration, stack_size, num_stacks) end

---@return string
function core.auction_house.get_auction_sell_item_info() end

---@return string
function core.auction_house.get_cursor_item_name() end
