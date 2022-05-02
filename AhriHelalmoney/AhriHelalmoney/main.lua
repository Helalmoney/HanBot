local preds = module.internal("pred")
local TS = module.internal("TS")
local orb = module.internal("orb")
local common = module.load("HelalmoneyAhri", "common")

--/////////////////////////
-- Spells
--////////////////////////

local spellQ = {
  range = 900,
  delay = 0.4,
  width = 100,
  speed = 2500,
  boundingRadiusMod = 1
}

local spellW = {
  range = 550
}

local spellE = {
  range = 1000,
  delay = 0.25,
  width = 60,
  speed = 1550,
  boundingRadiusMod = 1,
  collision = {
    wall = true,
    minion = true
  }
}

local spellR = {
  range = 500
}

--/////////////////////////
-- Menu
--////////////////////////

local menu = menu("Helalmoney" .. player.charName, player.charName .. " by Helalmoney")
menu:menu("combo", "Combo")
menu.combo:header("qset", " -- Q Settings --")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("qcharmed", "Only if Charmed", false)
menu.combo:header("wset", " -- W Settings --")
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:header("eset", " -- E Settings --")
menu.combo:boolean("ecombo", "Use E", true)

menu:menu("harass", "Harass")
menu.harass:header("qset", " -- Q Settings --")
menu.harass:boolean("qcombo", "Use Q", true)
menu.harass:boolean("qcharmed", "Only if Charmed", false)
menu.harass:header("wset", " -- W Settings --")
menu.harass:boolean("wcombo", "Use W", true)
menu.harass:header("eset", " -- E Settings --")
menu.harass:boolean("ecombo", "Use E", true)

menu:menu("farming", "Farming")
menu.farming:keybind("toggle", "Farm", nil, "A")
menu.farming:header("uwu", " ~~~~ ")
menu.farming:menu("laneclear", "Lane Clear")
menu.farming.laneclear:boolean("farmq", "Use Q", true)
menu.farming.laneclear:slider("hitsq", " ^- if Hits X Minions", 3, 1, 6, 1)
menu.farming:menu("jungleclear", "Jungle Clear")
menu.farming.jungleclear:boolean("useq", "Use Q", true)
menu.farming.jungleclear:boolean("usew", "Use W", true)
menu.farming.jungleclear:boolean("usee", "Use E", true)

menu:menu("killsteal", "Killsteal")
menu.killsteal:boolean("ksq", "Use Q", true)
menu.killsteal:boolean("kse", "Use E", true)

menu:menu("draws", "Draw Settings")
menu.draws:header("ranges", " -- Ranges -- ")
menu.draws:boolean("drawq", "Draw Q Range", true)
menu.draws:color("colorq", "  ^- Color", 255, 153, 153, 255)
menu.draws:boolean("draww", "Draw W Range", false)
menu.draws:color("colorw", "  ^- Color", 255, 153, 153, 255)
menu.draws:boolean("drawe", "Draw E Range", true)
menu.draws:color("colore", "  ^- Color", 255, 153, 153, 255)
menu.draws:boolean("drawr", "Draw R Range", false)
menu.draws:color("colorr", "  ^- Color", 255, 153, 153, 255)
menu.draws:header("other", " -- Other -- ")
menu.draws:boolean("drawdamage", "Draw Damage", true)
menu.draws:slider("transparency", "Damage Drawing Transparency", 155, 0, 255, 1)
menu.draws:slider("toggletransparency", "Toggle Drawing Transparency", 200, 50, 255, 1)

menu:menu("misc", "Misc.")
menu.misc:boolean("slowq", "Slow Predictions", true)
menu.misc:slider("erange", "E Range", 900, 500, 950, 5)
menu.misc:menu("interrupt", "Interrupt Settings")
menu.misc.interrupt:boolean("inte", "Use E", true)
menu.misc.interrupt:menu("interruptmenu", "Interrupt Settings")
for i = 1, #common.GetEnemyHeroes() do
  local enemy = common.GetEnemyHeroes()[i]
  local name = string.lower(enemy.charName)
  if enemy and common.GetInterruptableSpells()[name] then
    for v = 1, #common.GetInterruptableSpells()[name] do
      local spell = common.GetInterruptableSpells()[name][v]
      menu.misc.interrupt.interruptmenu:boolean(
        string.format(tostring(enemy.charName) .. tostring(spell.menuslot)),
        "Interrupt " .. tostring(enemy.charName) .. " " .. tostring(spell.menuslot),
        true
      )
    end
  end
end

TS.load_to_menu(menu)

--/////////////////////////
-- Target Selector
--////////////////////////

local TargetSelectionE = function(res, obj, dist)
  if dist < spellE.range then
    res.obj = obj
    return true
  end
end

local function isCC(target)
  if
    (common.CheckBuffType(target, 5) or common.CheckBuffType(target, 8) or common.CheckBuffType(target, 24) or common.CheckBuffType(target, 11) or
      common.CheckBuffType(target, 22) or
      common.CheckBuffType(target, 21))
   then
    return true
  end
  return false
end

local GetTargetE = function()
  return TS.get_result(TargetSelectionE).obj
end

--/////////////////////////
-- Trace Filter
--////////////////////////

local trace_filter = function(input, segment, target)
  if preds.trace.linear.hardlock(input, segment, target) then
    return true
  end
  if preds.trace.linear.hardlockmove(input, segment, target) then
    return true
  end
  if target and common.IsValidTarget(target) and player.pos:dist(target) <= 500 then
    return true
  end
  if (menu.misc.slowq:get() == false) then
    return true
  end
  if preds.trace.newpath(target, 0.033, 0.5) then
    return true
  end
end

--/////////////////////////
-- Definitions
--////////////////////////

function VectorPointProjectionOnLineSegment(v1, v2, v)
  local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
  local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
  local pointLine = {x = ax + rL * (bx - ax), y = ay + rL * (by - ay)}
  local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
  local isOnSegment = rS == rL
  local pointSegment = isOnSegment and pointLine or {x = ax + rS * (bx - ax), y = ay + rS * (by - ay)}
  return pointSegment, pointLine, isOnSegment
end

function GetNMinionsHitE(Pos)
  local count = 0
  local minions = nil
  local StartPoint = vec3(Pos.x, 0, Pos.z)
  local EndPoint = vec3(player.x, 0, player.z)
  for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
    local minion = objManager.minions[TEAM_ENEMY][i]
    if minion and minion.isVisible and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable then
      local position = vec3(minion.x, 0, minion.z)
      local PointInLine = VectorPointProjectionOnLineSegment(player.pos - spellQ.range * (player.pos - Pos.pos):norm(), EndPoint, position)
      if vec2(position.x, position.z):dist(vec2(PointInLine.x, PointInLine.y)) < spellQ.width then
        count = count + 1
        minions = minion
      end
    end
  end
  return count, minions
end

function VectorExtend(v, t, d)
  return v + d * (t - v):norm()
end

--/////////////////////////
-- Damage
--////////////////////////

local QLevelDamage = {40, 65, 95, 115, 140}
function QDamage(target)
  local damage = 0
  if player:spellSlot(0).level > 0 then
    damage = common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .35)), player)
  end
  return damage
end

local ELevelDamage = {60, 90, 120, 150, 180}
function EDamage(target)
  local damage = 0
  if player:spellSlot(2).level > 0 then
    damage = common.CalculateMagicDamage(target, (ELevelDamage[player:spellSlot(2).level] + (common.GetTotalAP() * .4)), player)
  end
  return damage
end
local WLevelDamage = {40, 65, 90, 115, 140}
function WDamage(target)
  local damage = 0
  if player:spellSlot(1).level > 0 then
    damage = common.CalculateMagicDamage(target, (WLevelDamage[player:spellSlot(1).level] + (common.GetTotalAP() * .3)), player)
  end
  return damage
end

local RLevelDamage = {60, 90, 120}
function RDamage(target)
  local damage = 0
  if player:spellSlot(3).level > 0 then
    damage = common.CalculateMagicDamage(target, (RLevelDamage[player:spellSlot(3).level] + (common.GetTotalAP() * .35)), player)
  end
  return damage * 3
end
--/////////////////////////
-- Auto Interrupt
--////////////////////////
local interrupt_data = {}
local function GetInterruptData(spell)
  if menu.misc.interrupt.inte:get() then
    if spell and spell.owner and spell.owner.team == TEAM_ENEMY then
      if player.pos:dist(spell.owner.pos) < spellE.range then
        local name = string.lower(spell.owner.charName)
        if common.GetInterruptableSpells()[name] then
          for v = 1, #common.GetInterruptableSpells()[name] do
            local spells = common.GetInterruptableSpells()[name][v]
            if menu.misc.interrupt.interruptmenu[spell.owner.charName .. spells.menuslot]:get() then
              if (spells.slot == spell.slot) then
                interrupt_data.start = os.clock()
                interrupt_data.channel = spells.channelduration
                interrupt_data.owner = spell.owner
              end
            end
          end
        end
      end
    end
  end
end
local function ProcessCast(spell)
  local castedSpell = spell
  GetInterruptData(castedSpell)
end

local function Interrupt()
  if interrupt_data.owner then
    if os.clock() - interrupt_data.channel >= interrupt_data.start then
      interrupt_data.owner = false
      return
    end
    if player:spellSlot(2).state == 0 then
      local pos = preds.linear.get_prediction(spellE, interrupt_data.owner)
      if
        pos and player.pos:dist(vec3(pos.endPos.x, interrupt_data.owner.y, pos.endPos.y)) < spellE.range and
          not preds.collision.get_prediction(spellE, pos, interrupt_data.owner)
       then
        if trace_filter(spellE, pos, interrupt_data.owner) then
          player:castSpell("pos", 2, vec3(pos.endPos.x, interrupt_data.owner.pos.y, pos.endPos.y))
          interrupt_data.owner = false
        end
      end
    end
  end
end

--/////////////////////////
-- Combo
--////////////////////////

local function Combo()
  if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 then
    local target = GetTargetE()
    if common.IsValidTarget(target) then
      local pos = preds.linear.get_prediction(spellE, target)
      if
        pos and player.pos:dist(vec3(pos.endPos.x, target.y, pos.endPos.y)) < spellE.range and not preds.collision.get_prediction(spellE, pos, target)
       then
        if trace_filter(spellE, pos, target) then
          player:castSpell("pos", 2, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
        end
      end
    end
  end
  if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 then
    local target = GetTargetE()
    if (common.IsValidTarget(target)) then
      local posE = preds.linear.get_prediction(spellE, target)
      if
        (player:spellSlot(2).state ~= 0 or menu.combo.ecombo:get() == false or
          posE and player.pos:dist(vec3(posE.endPos.x, target.y, posE.endPos.y)) > spellE.range or
          preds.collision.get_prediction(spellE, posE, target)) and
          (menu.combo.qcharmed:get() == false or target.buff["ahriseducedoom"] or target.pos:dist(player.pos) <= 300 or isCC(target))
       then
        local pos = preds.linear.get_prediction(spellQ, target)
        if pos and player.pos:dist(vec3(pos.endPos.x, target.y, pos.endPos.y)) < spellQ.range then
          if trace_filter(spellQ, pos, target) then
            player:castSpell("pos", 0, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
          end
        end
      end
    end
  end
  if menu.combo.wcombo:get() and player:spellSlot(1).state == 0 then
    if #common.count_enemies_in_range_inv(player.pos, spellW.range - 50, 0) > 0 then
      player:castSpell("self", 1)
    end
  end
end

--/////////////////////////
-- Harass
--////////////////////////

local function Harass()
  if menu.harass.ecombo:get() and player:spellSlot(2).state == 0 then
    local target = GetTargetE()
    if common.IsValidTarget(target) then
      local pos = preds.linear.get_prediction(spellE, target)
      if
        pos and player.pos:dist(vec3(pos.endPos.x, target.y, pos.endPos.y)) < spellE.range and not preds.collision.get_prediction(spellE, pos, target)
       then
        if trace_filter(spellE, pos, target) then
          player:castSpell("pos", 2, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
        end
      end
    end
  end
  if menu.harass.qcombo:get() and player:spellSlot(0).state == 0 then
    local target = GetTargetE()
    if (common.IsValidTarget(target)) then
      local posE = preds.linear.get_prediction(spellE, target)
      if
        (player:spellSlot(2).state ~= 0 or menu.harass.ecombo:get() == false or
          posE and player.pos:dist(vec3(posE.endPos.x, target.y, posE.endPos.y)) > spellE.range or
          preds.collision.get_prediction(spellE, posE, target)) and
          (menu.harass.qcharmed:get() == false or target.buff["ahriseducedoom"] or target.pos:dist(player.pos) <= 300 or isCC(target))
       then
        local pos = preds.linear.get_prediction(spellQ, target)
        if pos and player.pos:dist(vec3(pos.endPos.x, target.y, pos.endPos.y)) < spellQ.range then
          if trace_filter(spellQ, pos, target) then
            player:castSpell("pos", 0, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
          end
        end
      end
    end
  end
  if menu.harass.wcombo:get() and player:spellSlot(1).state == 0 then
    if #common.count_enemies_in_range_inv(player.pos, spellW.range - 50, 0) > 0 then
      player:castSpell("self", 1)
    end
  end
end

--/////////////////////////
-- Lane Clear
--////////////////////////

local function LaneClear()
  if menu.farming.laneclear.farmq:get() and player:spellSlot(0).state == 0 then
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
      local minion = objManager.minions[TEAM_ENEMY][i]
      if
        minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and
          minion.pos:dist(player.pos) <= spellQ.range
       then
        local count, minions = GetNMinionsHitE(minion)

        if count >= menu.farming.laneclear.hitsq:get() then
          local seg = preds.linear.get_prediction(spellQ, minion)
          if seg and seg.startPos:dist(seg.endPos) < spellQ.range then
            player:castSpell("pos", 0, vec3(seg.endPos.x, minion.y, seg.endPos.y))
          end
        end
      end
    end
  end
end

--/////////////////////////
-- Jungle Clear
--////////////////////////
local function JungleClear()
  if menu.farming.jungleclear.usee:get() and player:spellSlot(2).state == 0 then
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
      local minion = objManager.minions[TEAM_NEUTRAL][i]
      if minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and minion.type == TYPE_MINION then
        if minion.pos:dist(player.pos) <= spellE.range then
          local pos = preds.linear.get_prediction(spellE, minion)
          if pos and player.pos:dist(vec3(pos.endPos.x, minion.y, pos.endPos.y)) < spellE.range then
            player:castSpell("pos", 2, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
          end
        end
      end
    end
  end
  if menu.farming.jungleclear.useq:get() and player:spellSlot(0).state == 0 then
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
      local minion = objManager.minions[TEAM_NEUTRAL][i]
      if minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and minion.type == TYPE_MINION then
        if minion.pos:dist(player.pos) <= spellQ.range then
          local pos = preds.linear.get_prediction(spellQ, minion)
          if pos and player.pos:dist(vec3(pos.endPos.x, minion.y, pos.endPos.y)) < spellQ.range then
            player:castSpell("pos", 0, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
          end
        end
      end
    end
  end
  if menu.farming.jungleclear.usew:get() and player:spellSlot(1).state == 0 then
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
      local minion = objManager.minions[TEAM_NEUTRAL][i]
      if minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and minion.type == TYPE_MINION then
        if minion.pos:dist(player.pos) <= spellW.range - 50 then
          player:castSpell("self", 1)
        end
      end
    end
  end
end

--/////////////////////////
-- Killsteal
--////////////////////////

local function KillSteal()
  local enemy = common.GetEnemyHeroes()
  for i, enemies in ipairs(enemy) do
    if enemies and common.IsValidTarget(enemies) and not enemies.buff[17] then
      local hp = common.GetShieldedHealth("AP", enemies)
      if menu.killsteal.kse:get() then
        if player:spellSlot(2).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < spellE.range and EDamage(enemies) >= hp then
          local seg = preds.linear.get_prediction(spellE, enemies)
          if seg and seg.startPos:dist(seg.endPos) < spellE.range then
            if not preds.collision.get_prediction(spellE, seg, enemies) and trace_filter(spellE, seg, enemies) then
              player:castSpell("pos", 2, vec3(seg.endPos.x, enemies.y, seg.endPos.y))
            end
          end
        end
      end
      if menu.killsteal.ksq:get() then
        if player:spellSlot(0).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < spellQ.range and QDamage(enemies) >= hp then
          local seg = preds.linear.get_prediction(spellQ, enemies)
          if seg and seg.startPos:dist(seg.endPos) < spellQ.range and trace_filter(spellQ, seg, enemies) then
            player:castSpell("pos", 0, vec3(seg.endPos.x, enemies.y, seg.endPos.y))
          end
        end
      end
    end
  end
end

--/////////////////////////
-- Drawings
--////////////////////////

local function OnDraw()
  if (player.isDead) then
    return
  end

  if player.isOnScreen then
    if menu.draws.drawq:get() then
      graphics.draw_circle(player.pos, spellQ.range, 2, menu.draws.colorq:get(), 80)
    end
    if menu.draws.drawr:get() then
      graphics.draw_circle(player.pos, spellR.range, 2, menu.draws.colorr:get(), 80)
    end
    if menu.draws.draww:get() then
      graphics.draw_circle(player.pos, spellW.range, 2, menu.draws.colorw:get(), 80)
    end
    if menu.draws.drawe:get() then
      graphics.draw_circle(player.pos, spellE.range, 2, menu.draws.colore:get(), 80)
    end
  end
  if menu.draws.drawdamage:get() then
    for i = 0, objManager.enemies_n - 1 do
      local obj = objManager.enemies[i]
      if obj and obj.isVisible and obj.team == TEAM_ENEMY and obj.isOnScreen then
        local hp_bar_pos = obj.barPos
        local xPos = hp_bar_pos.x + ((graphics.width > 1920 and graphics.height > 1080) and 195 or 164)
        local yPos = hp_bar_pos.y + (graphics.height > 1080 and 148 or 122.5)
        local Qdmg = player:spellSlot(0).state == 0 and QDamage(obj) or 0
        local Wdmg = player:spellSlot(1).state == 0 and WDamage(obj) or 0
        local Edmg = player:spellSlot(2).state == 0 and EDamage(obj) or 0
        local Rdmg = player:spellSlot(3).state == 0 and RDamage(obj) or 0

        local damage = obj.health - (Qdmg + Rdmg + Wdmg + Edmg)
        local x1 = xPos + ((obj.health / obj.maxHealth) * ((graphics.width > 1920 and graphics.height > 1080) and 126 or 102))

        local x2 = xPos + (((damage > 0 and damage or 0) / obj.maxHealth) * ((graphics.width > 1920 and graphics.height > 1080) and 126 or 102))
        if damage > 0 then
          graphics.draw_line_2D(x1, yPos, x2, yPos, 10, graphics.argb(menu.draws.transparency:get(), 255, 192, 200))
        else
          graphics.draw_line_2D(x1, yPos, x2, yPos, 10, graphics.argb(menu.draws.transparency:get(), 0, 255, 0))
        end
      end
    end
  end
end

--/////////////////////////
-- OnTick
--////////////////////////

local function OnTick()
  spellE.range = menu.misc.erange:get()

  if (player.isDead) then
    return
  end

  KillSteal()
  Interrupt()
  if orb.menu.combat.key:get() then
    Combo()
  end
  if orb.menu.hybrid.key:get() then
    Harass()
  end
  if orb.menu.lane_clear.key:get() then
    if menu.farming.toggle:get() then
      LaneClear()
      JungleClear()
    end
  end
end

--/////////////////////////
-- Events
--////////////////////////

cb.add(cb.draw, OnDraw)
cb.add(cb.spell, ProcessCast)
orb.combat.register_f_pre_tick(OnTick)
