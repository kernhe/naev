--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Minerva Station Gambling">
 <trigger>land</trigger>
 <chance>100</chance>
 <cond>planet.cur():name()=="Minerva Station"</cond>
</event>
--]]

--[[
-- Event handling the gambling stuff going on at Minerva station
--]]

local minerva = require "minerva"
local portrait = require "portrait"
local vn = require 'vn'
local blackjack = require 'minigames.blackjack'
local lg = require 'love.graphics'
local window = require 'love.window'

-- NPC Stuff
gambling_priority = 3
terminal_name = _("Terminal")
terminal_portrait = "minerva_terminal"
terminal_desc = _("A terminal with which you can check your current token balance and buy items with tokens.")
terminal_image = "minerva_terminal.png"
terminal_colour = {0.8, 0.8, 0.8}
blackjack_name = _("Blackjack")
blackjack_portrait = "blackjack"
blackjack_desc = _("Seems to be one of the more popular card games where you can play blackjack against a \"cyborg chicken\".")
blackjack_image = minerva.chicken.image
chuckaluck_name = _("Chuck-a-luck")
chuckaluck_portrait = "none" -- TODO replace
chuckaluck_desc = _("A fast-paced luck-based betting game using dice. You can play against other patrons.")
greeter_portrait = portrait.get() -- TODO replace?

patron_names = {
   _("Patron"),
}
patron_descriptions = {
   _("A gambling patron enjoying his time at the station."),
   _("A tourist looking a bit bewildered at all the noises and shiny lights all over."),
   _("A patron who seems down on his luck."),
   _("A patron who looks exhilarated as if they won big today."),
   _("A patron that looks like they have spend a lot of time at the station. There are clear dark circles under their eyes."),
   _("A patron that looks strangely out of place."),
   _("A patron that fits in perfectly into the gambling station."),
}
patron_messages = {
   _([["This place is totally what I thought it would be. The lights, the sounds, the action! I feel like I'm in Heaven!"]]),
   _([["It's incredible! Who would have thought to make money physical! These Minerva Tokens defy all logic!"]]),
   function ()
      local soldoutmsg = ""
      if player.numOutfit("Fuzzy Dice") > 0 then
         soldoutmsg = _(" Wait, what? What do you mean they are sold out!?")
      end
      return string.format(_([["I really have my eyes on the Fuzzy Dice available at the terminal. I always wanted to own a piece of history!%s"]]), soldoutmsg ) end,
   _([["I played 20 hands of blackjack with that Cyborg Chicken. I may have lost them all, but that was worth every credit!"]]),
   _([["This place is great! I still have no idea how to play blackjack, but I just keep on playing again and again against that Cyborg Chicken."]]),
   function () return string.format(
      _([["I came all the way from %s to be here! We don't have anything like this back at home."]]),
      planet.get( {faction.get("Dvaered"), faction.get("Za'lek"), faction.get("Empire"), faction.get("Soromid")} ):name()
   ) end,
   _([["Critics of Minerva Station say that being able to acquire nice outfits here without needing licenses increases piracy. I think they are all lame!"]]),
   _([["I really want to go to the VIP hot springs they have, but I don't have the tokens. How does that even work in a space station?"]]),
   _([["I hear you can do all sorts of crazy stuff here if you have enough tokens. Need... to.. get.. more...!"]]),
   _([["I have never seen robots talk so roboty like the terminals here. That is so retro!"]]),
   _([["I scrounged up my lifetime savings to get a ticket here, but I forgot to bring extra to gamble..."]]),
   _([["I gambled all my savings away... I'm going to get killed when I get back home..."]]),
   _([["They say you shouldn't gamble more than you can afford to lose. I wish someone had told me that yesterday. I don't even own a ship anymore!"]]),
   _([["I like to play blackjack. I'm not addicted to gambling. I'm addicted to sitting in a semi-circle."]]), -- Mitch Hedberg
   _([["Gambling has brought our family together. We had to move to a smaller house."]]), -- Tommy Cooper
   _([["You don’t gamble to win. You gamble so you can gamble the next day."]]), -- Bert Ambrose
   _([["A credit won is twice as sweet as a credit earned!"]]), -- Paul Newman (dollar -> credit)
   _([["There is a very easy way to return from Minerva Station with a small fortune: come here with a large one!"]]), -- Jack Yelton (paraphrased)
   _([["Luck always seems to be against the ones who depends on it."]]),
}

function create()

   -- Create NPCs
   npc_terminal = evt.npcAdd( "approach_terminal", terminal_name, terminal_portrait, terminal_desc, gambling_priority )
   npc_blackjack = evt.npcAdd( "approach_blackjack", blackjack_name, blackjack_portrait, blackjack_desc, gambling_priority )
   --npc_chuckaluck = evt.npcAdd( "approach_chuckaluck", chuckaluck_name, chuckaluck_portrait, chuckaluck_desc, gambling_priority )

   -- Create random noise NPCs
   local npatrons = rnd.rnd(3,5)
   npc_patrons = {}
   local msglist = rnd.permutation( patron_messages ) -- avoids duplicates
   for i = 1,npatrons do
      local name = patron_names[ rnd.rnd(1, #patron_names) ]
      local img = portrait.get()
      local desc = patron_descriptions[ rnd.rnd(1, #patron_descriptions) ]
      local msg = msglist[i]
      local id = evt.npcAdd( "approach_patron", name, img, desc, 10 )
      local npcdata = { name=name, image=portrait.getFullPath(img), message=msg }
      npc_patrons[id] = npcdata
   end

   -- If they player never had tokens, it is probably their first time
   if not var.peek( "minerva_tokens" ) then
      hook.land( "bargreeter", "bar" )
   end
   -- End event on takeoff.
   tokens_landed = minerva.tokens_get()
   hook.takeoff( "leave" )

   -- Custom music
   music.load( "meeting_mtfox" )
   music.play()
end

local function has_event( name )
   return player.evtDone( name ) or player.evtActive( name )
end
--[[
-- Function that handles creating and starting random events that occur at the
-- bar. This is triggered randomly upon finishing gambling activities.
--]]
function random_event()
   -- Altercation 1
   local alter1 = "Minerva Station Altercation 1"
   if not has_event(alter1) and minerva.tokens_get_gained() > 10 and rnd.rnd() < 0.25 then
      hook.safe( "start_alter1" )
      return
   end
end

-- TODO probably a bug, but we should be able to pass a hook argument instead of hardcoding the function
-- Doesn't seem to work however
function start_alter1 ()
   naev.eventStart( "Minerva Station Altercation 1" )
end

function bargreeter()
   vn.clear()
   vn.scene()
   local g = vn.newCharacter( _("Greeter"),
         { image=portrait.getFullPath( greeter_portrait ) } )
   vn.fadein()
   vn.na( _("As soon as you enter the spaceport bar, a neatly dressed individual runs up to you and hands you a complementary drink. It is hard to make out what he is saying over all the background noise created by other patrons and gambling machines, but you try to make it out as best as you can.") )
   g:say( _("\"Welcome to the Minerva Station resort! It appears to be your first time here. As you enjoy your complementary drink, let me briefly explain to you how this wonderful place works. It is all very exciting!\"") )
   g:say( _("\"The currency we use on this station are Minerva Tokens. Unlike credits, they are physical and so very pretty! You can not buy Minerva Tokens directly, however, by participating and betting credits in the various fine games available, you can obtain Minerva Tokens. When you have enough Minerva Tokens, you are able to buy fabulous prizes and enjoy more exclusive areas of our resort. To start out your fun Minerva Adventure®, please enjoy these 10 complementary Minerva Tokens!\"") )
   g:say( _("\"If you want more information or want to check your balance. Please use the terminals located throughout the station. I highly recommend you check out our universe-famous Cyborg Chicken at the blackjack table, and always remember, 'life is short, spend it at Minerva Station'®!\"") )
   vn.fadeout()
   vn.run()

   minerva.tokens_pay( 10 )
end

function approach_terminal()
   local msgs = {
      _(" TODAY MIGHT BE YOUR LUCKY DAY."),
      _(" THIS IS SO EXCITING."),
      _(" YOU SEEM LIKE YOU MIGHT ENJOY A GAME OF BLACKJACK."),
      _(" FORTUNE FAVOURS THE PERSISTENT."),
      _(" LIFE IS SHORT, SPEND IT AT MINERVA STATION."),
   }
   vn.clear()
   vn.scene()
   local t = vn.newCharacter( terminal_name,
         { image=terminal_image, color=terminal_colour } )
   vn.fadein()
   vn.label( "start" )
   t:say( function() return string.format(
         n_("\"VALUED CUSTOMER, YOU HAVE #p%d MINERVA TOKEN#0.%s\n\nWHAT DO YOU WISH TO DO TODAY?\"",
            "\"VALUED CUSTOMER, YOU HAVE #p%d MINERVA TOKENS#0.%s\n\nWHAT DO YOU WISH TO DO TODAY?\"", minerva.tokens_get()),
               minerva.tokens_get(), msgs[rnd.rnd(1,#msgs)]) end )
   vn.menu( {
      {_("Information"), "info"},
      {_("Trade-in"), "trade"},
      {_("Leave"), "leave"},
   } )
   vn.label( "info" )
   t:say( _("\"I AM PROGRAMMED TO EXPLAIN ABOUT THE WONDERFUL MINERVA STATION GAMBLING FACILITIES. WHAT WOULD YOU LIKE TO KNOW ABOUT?\"") )
   vn.jump( "info_menu" )
   vn.label( "more_info" )
   t:say( _("\"WHAT ELSE WOULD YOU LIKE TO KNOW?\"") )
   vn.label( "info_menu" )
   vn.menu( {
      {_("Station"), "info_station"},
      {_("Gambling"), "info_gambling"},
      {_("Trade-in"), "info_trade"},
      {_("Cyborg Chicken"), "info_chicken"},
      {_("Back"), "start"},
   } )
   vn.label( "info_station" )
   t:say( _("\"MINERVA STATION IS THE BEST PLACE TO SIT BACK AND ENJOY RELAXING GAMBLING ACTIVITIES. ALTHOUGH THE AREA IS HEAVILY DISPUTED BY THE ZA'LEK AND DVAERED, REST ASSURED THAT THERE IS LESS THAN A 2% OF CHANCE OF TOTAL DESTRUCTION OF THE STATION.\"") )
   vn.jump( "more_info" )
   vn.label( "info_gambling" )
   t:say( _("\"WHILE GAMBLING IS NOT ALLOWED IN MOST OF THE EMPIRE, MINERVA STATION BOASTS OF AN EXCLUSIVE STATUS THANKS TO THE IMPERIAL DECREE 289.78 ARTICLE 478 SECTION 19 ALLOWING GAMBLING TO BE ENJOYED WITHOUT RESTRICTIONS. IT IS POSSIBLE TO PLAY GAMES USING CREDITS TO OBTAIN MINERVA TOKENS THAT CAN BE TRADED IN FOR GOODS AND SERVICES ANY TERMINAL THROUGHOUT THE STATION.\"" ) )
   vn.jump( "more_info" )
   vn.label( "info_trade" )
   t:say( _("\"IT IS POSSIBLE TO TRADE MINERVA TOKENS FOR GOODS AND SERVICES AT TERMINALS THROUGHOUT THE STATION. THANKS TO THE IMPERIAL DECREE 289.78 ARTICLE 478 SECTION 72, ALL TRADE-INS ARE NOT SUBJECT TO STANDARD IMPERIAL LICENSE RESTRICTIONS. FURTHERMORE, THEY ALL HAVE 'I Got This Sucker at Minerva Station' ENGRAVED ON THEM.\"") )
   vn.jump( "more_info" )
   vn.label( "info_chicken" )
   t:say( _("\"CYBORG CHICKEN IS OUR MOST POPULAR BLACKJACK DEALER. NO WHERE ELSE IN THE UNIVERSE WILL YOU BE ABLE TO PLAY CARD GAMES WITH AN AI-ENHANCED CHICKEN CYBORG. IT IS A ONCE AND A LIFE-TIME CHANCE THAT YOU SHOULD NOT MISS.\"") )
   vn.jump( "more_info" )

   vn.label( "trade_notenough" )
   t:say( function() return string.format(
         n_("\"SORRY, YOU DO NOT HAVE ENOUGH MINERVA TOKENS TO TRADE-IN FOR YOUR REQUESTED ITEM. WOULD YOU LIKE TO TRADE-IN FOR SOMETHING ELSE? YOU HAVE #p%d MINERVA TOKEN#0.\"",
            "\"SORRY, YOU DO NOT HAVE ENOUGH MINERVA TOKENS TO TRADE-IN FOR YOUR REQUESTED ITEM. WOULD YOU LIKE TO TRADE-IN FOR SOMETHING ELSE? YOU HAVE #p%d MINERVA TOKENS#0.\"", minerva.tokens_get()),
         minerva.tokens_get() ) end )
   vn.jump( "trade_menu" )
   vn.label( "trade_soldout" )
   t:say( function() return string.format(
         n_("\"I AM SORRY TO INFORM YOU THAT THE ITEM THAT YOU DESIRE IS CURRENTLY SOLD OUT. WOULD YOU LIKE TO TRADE-IN FOR SOMETHING ELSE? YOU HAVE #p%d MINERVA TOKEN#0.\"",
            "\"I AM SORRY TO INFORM YOU THAT THE ITEM THAT YOU DESIRE IS CURRENTLY SOLD OUT. WOULD YOU LIKE TO TRADE-IN FOR SOMETHING ELSE? YOU HAVE #p%d MINERVA TOKENS#0.\"", minerva.tokens_get()),
         minerva.tokens_get() ) end )
   vn.jump( "trade_menu" )
   vn.label( "trade" )
   t:say( function() return string.format(
         n_("\"YOU CAN TRADE IN YOUR PRECIOUS #p%d MINERVA TOKEN#0 FOR THE FOLLOWING GOODS.\"",
            "\"YOU CAN TRADE IN YOUR PRECIOUS #p%d MINERVA TOKENS#0 FOR THE FOLLOWING GOODS.\"", minerva.tokens_get()),
            minerva.tokens_get() ) end )
   local trades = {
      {"Ripper Cannon", {100, "outfit"}},
      {"TeraCom Fury Launcher", {500, "outfit"}},
      {"Railgun", {1000, "outfit"}},
      {"Grave Lance", {1200, "outfit"}},
      {"Fuzzy Dice", {5000, "outfit"}},
      {"Admonisher", {7000, "ship"}},
   }
   local tradein_item = nil
   local handler = function (idx)
      -- Jump in case of 'Back'
      if idx=="start" then
         vn.jump(idx)
         return
      end

      if idx < 0 then
         vn.jump( "trade_soldout" )
         return
      end

      local t = trades[idx]
      local tokens = t[2][1]
      if tokens > minerva.tokens_get() then
         -- Not enough money.
         vn.jump( "trade_notenough" )
         return
      end

      tradein_item = t
      if t[2][2]=="outfit" then
         local o = outfit.get(t[1])
         tradein_item.description = o:description()
      elseif t[2][2]=="ship" then
         local s = ship.get(t[1])
         tradein_item.description = s:description()
      else
         error(_("unknown tradein type"))
      end
      vn.jump( "trade_confirm" )
   end
   vn.label( "trade_menu" )
   vn.menu( function ()
      local opts = {}
      for k,v in ipairs(trades) do
         local tokens = v[2][1]
         local soldout = (v[2][2]=="outfit" and outfit.unique(v[1]) and player.numOutfit(v[1])>0)
         if soldout then
            opts[k] = { string.format(_("%s (#rSOLD OUT#0)"), _(v[1])), -1 }
         else
            opts[k] = { string.format(_("%s (#p%d Tokens#0)"), _(v[1]), tokens), k }
         end
      end
      table.insert( opts, {_("Back"), "start"} )
      return opts
   end, handler )
   vn.jump( "start" )

   -- Buying stuff
   vn.label( "trade_confirm" )
   t:say( function () return string.format(
         _("\"ARE YOU SURE YOU WANT TO TRADE IN FOR THE '#w%s#0'? THE DESCRIPTION IS AS FOLLOWS:\"\n#w%s#0"),
         _(tradein_item[1]), _(tradein_item.description) ) end )
   vn.menu( {
      { _("Trade"), "trade_consumate" },
      { _("Cancel"), "trade" },
   }, function (idx)
      if idx=="trade_consumate" then
         local t = tradein_item
         minerva.tokens_pay( -t[2][1] )
         if t[2][2]=="outfit" then
            player.addOutfit( t[1] )
            player.msg( _("Gambling Bounty"), string.format(_("Obtained: %s"),t[1]))
         elseif t[2][2]=="ship" then
            player.addShip( t[1] )
         else
            error(_("unknown tradein type"))
         end
      end
      vn.jump(idx)
   end )
   vn.label("trade_consumate")
   -- TODO play a little jingle here
   t:say( _("\"THANK YOU FOR YOUR BUSINESS.\"") )
   vn.jump("trade")

   vn.label( "leave" )
   vn.fadeout()
   vn.run()

   -- Handle random bar events if necessary
   random_event()
end

function approach_blackjack()
   local firsttime = not var.peek("cc_known")
   -- Not adding to queue first
   local cc = minerva.vn_cyborg_chicken()
   vn.clear()
   vn.scene()
   if firsttime then
      vn.fadein()
      vn.na( _("You make your way to the blackjack table which seems to be surrounded by many patrons, some of which are apparently taking pictures of something. You eventually have to elbow your way to the front to get a view of what is going on." ) )
      vn.appear( cc )
      vn.na( _("When you make it to the front you are greeted by the cold eyes of what apparently seems to be the Cyborg Chicken you were told about. It seems to be sizing the crowd while playing against a patron. The way it moves is very uncanny with short precise mechanical motions. You can tell it has been doing this for a while. You watch as the game progresses and the patron loses all his credits to the chicken, who seems unfazed.") )
      var.push("cc_known",true)
   end
   if not firsttime then
      vn.newCharacter( cc )
      vn.fadein()
      vn.na( _("You elbow your way to the front of the table and are once again greeted by the cold mechanical eyes of Cyborg Chicken.") )
   end
   vn.na( "", true ) -- Clear buffer without waiting
   vn.label("menu")
   vn.menu( {
      { _("Play"), "blackjack" },
      { _("Explanation"), _("explanation") },
      { _("Leave"), "leave" },
   } )
   vn.label( "explanation" )
   vn.na( "Cyborg Chicken's eyes blink one second and go blank as a pre-recorded explanation is played from its back. Wait... are those embedded speakers?" )
   cc("\"Welcome to MINERVA STATIONS blackjack table. The objective of this card game is to get as close to a value of 21 without going over. All cards are worth their rank except for Jack, Queen, and King which are all worth 10, and ace is either worth 1 or 11. You win if you have a higher value than CYBORG CHICKEN without going over 21.\"")
   vn.na( "Cyborg Chicken eyes flutter as it seems like conciousness returns to its body." )
   vn.jump("menu")
   vn.label( "blackjack" )
   -- Resize the window
   local lw, lh = window.getDesktopDimensions()
   local textbox_h = vn.textbox_h
   local textbox_x = vn.textbox_x
   local textbox_y = vn.textbox_y
   local dealer_x, dealer_newx
   local blackjack_h = 500
   local blackjack_x = math.min( lw-vn.textbox_w-100, textbox_x+200 )
   local blackjack_y = lh-blackjack_h
   local setup_blackjack = function (alpha)
      if dealer_x == nil then
         dealer_x = cc.offset -- cc.offset is only set up when the they appear in the VN
         dealer_newx = 0.2*lw
      end
      vn.textbox_h = textbox_h + (blackjack_h - textbox_h)*alpha
      vn.textbox_x = textbox_x + (blackjack_x - textbox_x)*alpha
      vn.textbox_y = textbox_y + (blackjack_y - textbox_y)*alpha
      vn.namebox_alpha = 1-alpha
      cc.offset = dealer_x + (dealer_newx - dealer_x)*alpha
   end
   vn.animation( 0.5, function (alpha) setup_blackjack(alpha) end )
   local bj = vn.custom()
   bj._init = function( self )
      -- TODO play some blackjack music
      blackjack.init( vn.textbox_x, vn.textbox_y, vn.textbox_w, vn.textbox_h, function ()
         self.done = true
         -- TODO go back to normal music
      end )
   end
   bj._draw = function( self )
      local x, y, w, h =  vn.textbox_x, vn.textbox_y, vn.textbox_w, vn.textbox_h
      -- Horrible hack where we draw ontop of the textbox a background
      lg.setColor( 0.5, 0.5, 0.5 )
      lg.rectangle( "fill", x, y, w, h )
      lg.setColor( 0, 0, 0 )
      lg.rectangle( "fill", x+2, y+2, w-4, h-4 )

      -- Draw blackjack game
      blackjack.draw( x, y, w, h)
   end
   bj._keypressed = function( self, key )
      blackjack.keypressed( key )
   end
   bj._mousepressed = function( self, mx, my, button )
      blackjack.mousepressed( mx, my, button )
   end
   -- Undo the resize
   vn.animation( 0.5, function (alpha) setup_blackjack(1-alpha) end )
   vn.label( "leave" )
   vn.na( _("You leave the blackjack table behind and head back to the main area.") )
   vn.fadeout()
   vn.run()

   -- Handle random bar events if necessary
   random_event()
end

function approach_chuckaluck ()
   -- Handle random bar events if necessary
   random_event()
end

-- Just do random noise
function approach_patron( id )
   local npcdata = npc_patrons[id]
   vn.clear()
   vn.scene()
   local patron = vn.newCharacter( npcdata.name, { image=npcdata.image } )
   vn.fadein()
   patron( npcdata.message )
   vn.fadeout()
   vn.run()
end

--[[
-- Event is over when player takes off.
--]]
function leave ()
   local diff = minerva.tokens_get()-tokens_landed
   evt.finish()
end