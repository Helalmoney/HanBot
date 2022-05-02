local preds = module.internal("pred")
local TS = module.internal("TS")
local orb = module.internal("orb")
local common = module.load("HelalmoneyZyra", "common")
local spellQ = {
  range = 800,
  delay = 0.625,
  width = 100,
  speed = 1400,
  boundingRadiusMod = 1
}

local spellW = {
  range = 850,
  delay = 0.65,
  radius = 150,
  speed = 1000,
  boundingRadiusMod = 1
}

local spellE = {
  range = 1100,
  delay = 0.25,
  width = 70,
  speed = 1150,
  boundingRadiusMod = 1,
  collision = {
    wall = true
  }
}

local spellR = {
  range = 700,
  delay = 2.1,
  radius = 500,
  speed = math.huge,
  boundingRadiusMod = 1
}

local menu = menu("Helalmoney" .. player.charName, player.charName .. " by Helalmoney")

menu:menu("combo", "Combo")
menu.combo:dropdown("combomode", "Combo Mode", 1, {"Q-W-R-E-W", "E-W-R-Q-W"}, 1)
menu.combo:header("qset", " -- Q Settings -- ")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:header("wset", " -- W Settings -- ")
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:header("eset", " -- E Settings -- ")
menu.combo:boolean("ecombo", "Use E", true)
menu.combo:header("rset", " -- R Settings -- ")
menu.combo:boolean("rcombo", "Use R", true)
menu.combo:dropdown("rmode", "R Mode", 1, {"If hits X enemies", "Only if Killlable"}, 1)
menu.combo:slider("hitr", "If hits >= X", 2, 1, 5, 1)
menu.combo:keybind("semir", "Semi-R Key", "T", nil)

menu:menu("harass", "Harass")
menu.harass:boolean("qcombo", "Use Q", true)
menu.harass:boolean("wcombo", "Use W", true)
menu.harass:boolean("ecombo", "Use E", true)

menu:menu("laneclear", "Farming")
menu.laneclear:keybind("toggle", "Farm", nil, "Z")
menu.laneclear:header("eset", " -- E Settings -- ")
menu.laneclear:menu("push", "Lane Clear")
menu.laneclear.push:boolean("useq", "Use Q", true)
menu.laneclear.push:slider("hitq", " ^- If Hits", 3, 0, 6, 1)
menu.laneclear.push:boolean("usew", "Use W", true)

menu.laneclear:menu("jungle", "Jungle Clear")
menu.laneclear.jungle:boolean("useq", "Use Q", true)
menu.laneclear.jungle:boolean("usew", "Use W", true)
menu.laneclear.jungle:boolean("usee", "Use E", true)

menu:menu("draws", "Draw Settings")
menu.draws:header("ranges", " -- Ranges -- ")
menu.draws:boolean("drawq", "Draw Q Range", true)
menu.draws:color("colorq", "  ^- Color", 255, 233, 121, 121)
menu.draws:boolean("draww", "Draw W Range", false)
menu.draws:color("colorw", "  ^- Color", 255, 233, 121, 121)
menu.draws:boolean("drawe", "Draw E Range", false)
menu.draws:color("colore", "  ^- Color", 255, 255, 255, 255)
menu.draws:boolean("drawr", "Draw R Range", false)
menu.draws:color("colorr", "  ^- Color", 255, 255, 255, 255)
menu.draws:header("other", " -- Other -- ")
menu.draws:boolean("drawseeds", "Draw Seeds", true)
menu.draws:boolean("drawdamage", "Draw Damage", true)
menu.draws:slider("transparency", "Damage Drawing Transparency", 155, 0, 255, 1)
menu.draws:slider("toggletransparency", "Toggle Drawing Transparency", 200, 50, 255, 1)

menu:menu("misc", "Misc.")
menu.misc:boolean("slowq", "Slow Predictions", true)

local trace_filter_line = function(input, segment, target)
  if preds.trace.linear.hardlock(input, segment, target) then
    return true
  end
  if preds.trace.linear.hardlockmove(input, segment, target) then
    return true
  end
  if (menu.misc.slowq:get() == false) then
    return true
  end
  if target and common.IsValidTarget(target) and player.pos:dist(target) <= 500 then
    return true
  end
  if preds.trace.newpath(target, 0.033, 0.5) then
    return true
  end
end

local objSomething = {}
local function DeleteObj(object)
  if object and objSomething[object.ptr] ~= nil then
    objSomething[object.ptr] = nil
  end
end

local function CreateObj(object)
  if object and object.name:find("W_Seed") then
    objSomething[object.ptr] = object
  end
end

local TargetSelectionE = function(res, obj, dist)
  if dist < spellE.range then
    res.obj = obj
    return true
  end
end
local GetTargetE = function()
  return TS.get_result(TargetSelectionE).obj
end

local TargetSelectionR = function(res, obj, dist)
  if dist < spellR.range then
    res.obj = obj
    return true
  end
end

local GetTargetR = function()
  return TS.get_result(TargetSelectionR).obj
end
local QLevelDamage = {60, 95, 130, 165, 200}
function QDamage(target)
  local damage = 0
  if player:spellSlot(0).level > 0 then
    damage = common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .6)), player)
  end
  return damage
end
local ELevelDamage = {60, 105, 150, 195, 240}
function EDamage(target)
  local damage = 0
  if player:spellSlot(2).level > 0 then
    damage = common.CalculateMagicDamage(target, (ELevelDamage[player:spellSlot(2).level] + (common.GetTotalAP() * .5)), player)
  end
  return damage
end
local RLevelDamage = {180, 265, 350}
function RDamage(target)
  local damage = 0
  if player:spellSlot(3).level > 0 then
    damage = common.CalculateMagicDamage(target, (RLevelDamage[player:spellSlot(3).level] + (common.GetTotalAP() * .7)), player)
  end
  return damage
end

local function count_minions_in_range(pos, range)
  local enemies_in_range = {}
  for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
    local enemy = objManager.minions[TEAM_ENEMY][i]
    if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
      enemies_in_range[#enemies_in_range + 1] = enemy
    end
  end
  return enemies_in_range
end
local function Combo()
  local target = GetTargetE()
  if target and target.isVisible then
    if common.IsValidTarget(target) then
      if menu.combo.combomode:get() == 1 then
        if menu.combo.wcombo:get() and (player:spellSlot(0).state == 0 or player:spellSlot(2).state == 0) then
          if target.pos:dist(player.pos) < spellW.range then
            local pos = preds.circular.get_prediction(spellW, target)
            if pos and pos.startPos:dist(pos.endPos) < spellW.range then
              player:castSpell("pos", 1, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
            end
          end
        end
        if menu.combo.qcombo:get() then
          if target.pos:dist(player.pos) < spellQ.range and player:spellSlot(0).state == 0 then
            local pos = preds.linear.get_prediction(spellQ, target)
            if pos and pos.startPos:dist(pos.endPos) < spellQ.range and trace_filter_line(spellQ, pos, target) then
              if target.pos:dist(player.pos) < spellW.range and menu.combo.wcombo:get() then
                local pos2 = preds.circular.get_prediction(spellW, target)
                if pos2 and pos2.startPos:dist(pos2.endPos) < spellW.range then
                  player:castSpell("pos", 1, vec3(pos2.endPos.x, target.pos.y, pos2.endPos.y))
                end
              end
              player:castSpell("pos", 0, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
            end
          end
        end
        if menu.combo.rcombo:get() and player:spellSlot(3).state == 0 then
          if target.pos:dist(player.pos) < spellR.range then
            if menu.combo.rmode:get() == 1 then
              if (#common.count_enemies_in_range_inv(target.pos, 500, 0) >= menu.combo.hitr:get()) then
                local pos = preds.circular.get_prediction(spellR, target)
                if pos and pos.startPos:dist(pos.endPos) < spellR.range then
                  player:castSpell("pos", 3, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
                end
              end
            end
            if menu.combo.rmode:get() == 2 then
              if target.health <= (QDamage(target) + RDamage(target) + EDamage(target)) then
                local pos = preds.circular.get_prediction(spellR, target)
                if pos and pos.startPos:dist(pos.endPos) < spellR.range then
                  player:castSpell("pos", 3, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
                end
              end
            end
          end
        end
        if menu.combo.ecombo:get() then
          if target.pos:dist(player.pos) < spellE.range and player:spellSlot(2).state == 0 then
            local pos = preds.linear.get_prediction(spellE, target)
            if
              pos and pos.startPos:dist(pos.endPos) < spellE.range and not preds.collision.get_prediction(spellE, pos, target) and
                trace_filter_line(spellE, pos, target)
             then
              if target.pos:dist(player.pos) < spellW.range and menu.combo.wcombo:get() then
                local pos2 = preds.circular.get_prediction(spellW, target)
                if pos2 and pos2.startPos:dist(pos2.endPos) < spellW.range then
                  player:castSpell("pos", 1, vec3(pos2.endPos.x, target.pos.y, pos2.endPos.y))
                end
              end

              player:castSpell("pos", 2, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
            end
          end
        end
      end
      if menu.combo.combomode:get() == 2 then
        if menu.combo.wcombo:get() and (player:spellSlot(0).state == 0 or player:spellSlot(2).state == 0) then
          if target.pos:dist(player.pos) < spellW.range then
            local pos = preds.circular.get_prediction(spellW, target)
            if pos and pos.startPos:dist(pos.endPos) < spellW.range then
              player:castSpell("pos", 1, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
            end
          end
        end
        if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 then
          if target.pos:dist(player.pos) < spellE.range then
            local pos = preds.linear.get_prediction(spellE, target)
            if
              pos and pos.startPos:dist(pos.endPos) < spellE.range and not preds.collision.get_prediction(spellE, pos, target) and
                trace_filter_line(spellE, pos, target)
             then
              if target.pos:dist(player.pos) < spellW.range and menu.combo.wcombo:get() then
                local pos2 = preds.circular.get_prediction(spellW, target)
                if pos2 and pos2.startPos:dist(pos2.endPos) < spellW.range then
                  player:castSpell("pos", 1, vec3(pos2.endPos.x, target.pos.y, pos2.endPos.y))
                end
              end
              player:castSpell("pos", 2, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
            end
          end
        end
        if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 then
          if target.pos:dist(player.pos) < spellQ.range then
            local pos = preds.linear.get_prediction(spellQ, target)
            if pos and pos.startPos:dist(pos.endPos) < spellQ.range and trace_filter_line(spellQ, pos, target) then
              if target.pos:dist(player.pos) < spellW.range and menu.combo.wcombo:get() then
                local pos2 = preds.circular.get_prediction(spellW, target)
                if pos2 and pos2.startPos:dist(pos2.endPos) < spellW.range then
                  player:castSpell("pos", 1, vec3(pos2.endPos.x, target.pos.y, pos2.endPos.y))
                end
              end
              player:castSpell("pos", 0, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
            end
          end
        end
        if menu.combo.rcombo:get() and player:spellSlot(3).state == 0 then
          if target.pos:dist(player.pos) < spellR.range then
            if menu.combo.rmode:get() == 1 then
              if (#common.count_enemies_in_range_inv(target.pos, 500, 0) >= menu.combo.hitr:get()) then
                local pos = preds.circular.get_prediction(spellR, target)
                if pos and pos.startPos:dist(pos.endPos) < spellR.range then
                  player:castSpell("pos", 3, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
                end
              end
            end
            if menu.combo.rmode:get() == 2 then
              if target.health <= (QDamage(target) + RDamage(target) + EDamage(target)) then
                local pos = preds.circular.get_prediction(spellR, target)
                if pos and pos.startPos:dist(pos.endPos) < spellR.range then
                  player:castSpell("pos", 3, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
                end
              end
            end
          end
        end
      end
    end
  end
end

local function Harass()
  local target = GetTargetE()
  if target and target.isVisible then
    if common.IsValidTarget(target) then
      if menu.harass.wcombo:get() and (player:spellSlot(0).state == 0 or player:spellSlot(2).state == 0) then
        if target.pos:dist(player.pos) < spellW.range then
          local pos = preds.circular.get_prediction(spellW, target)
          if pos and pos.startPos:dist(pos.endPos) < spellW.range then
            player:castSpell("pos", 1, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
          end
        end
      end
      if menu.harass.qcombo:get() and player:spellSlot(0).state == 0 then
        if target.pos:dist(player.pos) < spellQ.range then
          local pos = preds.linear.get_prediction(spellQ, target)
          if pos and pos.startPos:dist(pos.endPos) < spellQ.range and trace_filter_line(spellQ, pos, target) then
            player:castSpell("pos", 0, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
            if target.pos:dist(player.pos) < spellW.range and menu.harass.wcombo:get() then
              local pos = preds.circular.get_prediction(spellW, target)
              if pos and pos.startPos:dist(pos.endPos) < spellW.range then
                if target.pos:dist(player.pos) < spellW.range and menu.harass.wcombo:get() then
                  local pos2 = preds.circular.get_prediction(spellW, target)
                  if pos2 and pos2.startPos:dist(pos2.endPos) < spellW.range then
                    player:castSpell("pos", 1, vec3(pos2.endPos.x, target.pos.y, pos2.endPos.y))
                  end
                end
                player:castSpell("pos", 0, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
              end
            end
          end
        end
      end
      if menu.harass.ecombo:get() and player:spellSlot(2).state == 0 then
        if target.pos:dist(player.pos) < spellE.range then
          local pos = preds.linear.get_prediction(spellE, target)
          if
            pos and pos.startPos:dist(pos.endPos) < spellE.range and not preds.collision.get_prediction(spellE, pos, target) and
              trace_filter_line(spellE, pos, target)
           then
            player:castSpell("pos", 2, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
            if target.pos:dist(player.pos) < spellW.range and menu.harass.wcombo:get() then
              local pos = preds.circular.get_prediction(spellW, target)
              if pos and pos.startPos:dist(pos.endPos) < spellW.range then
                if target.pos:dist(player.pos) < spellW.range and menu.harass.wcombo:get() then
                  local pos2 = preds.circular.get_prediction(spellW, target)
                  if pos2 and pos2.startPos:dist(pos2.endPos) < spellW.range then
                    player:castSpell("pos", 1, vec3(pos2.endPos.x, target.pos.y, pos2.endPos.y))
                  end
                end
                player:castSpell("pos", 0, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
              end
            end
          end
        end
      end
    end
  end
end

local function LaneClear()
  if menu.laneclear.push.useq:get() and player:spellSlot(0).state == 0 then
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
      local minion = objManager.minions[TEAM_ENEMY][i]
      if
        minion and minion.moveSpeed > 0 and minion.isTargetable and minion.pos:dist(player.pos) <= spellQ.range and minion.path.count == 0 and
          not minion.isDead and
          common.IsValidTarget(minion)
       then
        local minionPos = vec3(minion.x, minion.y, minion.z)
        if minionPos then
          if #count_minions_in_range(minionPos, 200) >= menu.laneclear.push.hitq:get() then
            local seg = preds.circular.get_prediction(spellQ, minion)
            if seg and seg.startPos:dist(seg.endPos) < spellQ.range then
              if menu.laneclear.push.usew:get() then
                local pos2 = preds.circular.get_prediction(spellW, minion)
                if pos2 and pos2.startPos:dist(pos2.endPos) < spellW.range and player:spellSlot(1).state == 0 then
                  player:castSpell("pos", 1, vec3(pos2.endPos.x, minion.pos.y, pos2.endPos.y))
                end
              end
              player:castSpell("pos", 0, vec3(seg.endPos.x, minionPos.y, seg.endPos.y))
            end
          end
        end
      end
    end
  end
end
local function JungleClear()
  if menu.laneclear.jungle.useq:get() and player:spellSlot(0).state == 0 then
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
      local minion = objManager.minions[TEAM_NEUTRAL][i]
      if
        minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and
          minion.pos:dist(player.pos) < spellQ.range
       then
        local minionPos = vec3(minion.x, minion.y, minion.z)
        if minionPos:dist(player.pos) <= spellQ.range then
          local pos = preds.linear.get_prediction(spellQ, minion)
          if pos and pos.startPos:dist(pos.endPos) < spellQ.range and player:spellSlot(0).state == 0 then
            if menu.laneclear.jungle.usew:get() then
              local pos2 = preds.circular.get_prediction(spellW, minion)
              if pos2 and pos2.startPos:dist(pos2.endPos) < spellW.range and player:spellSlot(1).state == 0 then
                player:castSpell("pos", 1, vec3(pos2.endPos.x, minion.pos.y, pos2.endPos.y))
              end
            end
            player:castSpell("pos", 0, vec3(pos.endPos.x, minion.pos.y, pos.endPos.y))
          end
        end
      end
    end
  end
  if menu.laneclear.jungle.usee:get() and player:spellSlot(2).state == 0 then
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
      local minion = objManager.minions[TEAM_NEUTRAL][i]
      if
        minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and
          minion.pos:dist(player.pos) < spellE.range
       then
        local minionPos = vec3(minion.x, minion.y, minion.z)
        if minionPos:dist(player.pos) <= spellE.range then
          local pos = preds.linear.get_prediction(spellE, minion)
          if pos and pos.startPos:dist(pos.endPos) < spellE.range and player:spellSlot(2).state == 0 then
            if menu.laneclear.jungle.usew:get() then
              local pos2 = preds.circular.get_prediction(spellW, minion)
              if pos2 and pos2.startPos:dist(pos2.endPos) < spellW.range and player:spellSlot(1).state == 0 then
                player:castSpell("pos", 1, vec3(pos2.endPos.x, minion.pos.y, pos2.endPos.y))
              end
            end
            player:castSpell("pos", 2, vec3(pos.endPos.x, minion.pos.y, pos.endPos.y))
          end
        end
      end
    end
  end
end
local function SemiR()
  local target = GetTargetR()
  if target and target.isVisible and player:spellSlot(3).state == 0 then
    if common.IsValidTarget(target) then
      local pos = preds.circular.get_prediction(spellR, target)
      if pos and pos.startPos:dist(pos.endPos) < spellR.range then
        player:castSpell("pos", 3, vec3(pos.endPos.x, target.pos.y, pos.endPos.y))
      end
    end
  end
end

local function OnTick()
  if menu.combo.rmode:get() == 1 then
    menu.combo.hitr:set("visible", true)
  else
    menu.combo.hitr:set("visible", false)
  end
  if (player.isDead) then
    return
  end

  if menu.combo.semir:get() then
    SemiR()
  end
  if orb.menu.combat.key:get() then
    Combo()
  end
  if orb.menu.hybrid.key:get() then
    Harass()
  end
  if orb.menu.lane_clear.key:get() then
    if menu.laneclear.toggle:get() then
      LaneClear()
      JungleClear()
    end
  end
end

local function OnDraw()
  if (player.isDead) then
    return
  end
  if menu.draws.drawseeds:get() then
    for _, objs in pairs(objSomething) do
      if objs and not objs.isDead then
        if objs.isOnScreen then
          graphics.draw_circle(objs.pos, 60, 2, graphics.argb(155, 255, 204, 204), 5)
        end
      end
    end
  end
  if player.isOnScreen then
    if menu.draws.drawe:get() then
      graphics.draw_circle(player.pos, spellE.range, 2, menu.draws.colore:get(), 100)
    end
    if menu.draws.drawq:get() then
      graphics.draw_circle(player.pos, spellQ.range, 2, menu.draws.colorq:get(), 100)
    end
    if menu.draws.draww:get() then
      graphics.draw_circle(player.pos, spellW.range, 2, menu.draws.colorw:get(), 100)
    end
    if menu.draws.drawr:get() then
      graphics.draw_circle(player.pos, spellR.range, 2, menu.draws.colorr:get(), 100)
    end
    local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
  end
  if menu.draws.drawdamage:get() then
    for i = 0, objManager.enemies_n - 1 do
      local obj = objManager.enemies[i]
      if obj and obj.isVisible and obj.team == TEAM_ENEMY and obj.isOnScreen then
        local hp_bar_pos = obj.barPos
        local xPos = hp_bar_pos.x + ((graphics.width > 1920 and graphics.height > 1080) and 195 or 164)
        local yPos = hp_bar_pos.y + (graphics.height > 1080 and 148 or 122.5)
        local Qdmg = player:spellSlot(0).state == 0 and QDamage(obj) or 0
        local Edmg = player:spellSlot(2).state == 0 and EDamage(obj) or 0
        local Rdmg = player:spellSlot(3).state == 0 and RDamage(obj) or 0

        local damage = obj.health - (Qdmg + Rdmg + Edmg)
        local x1 = xPos + ((obj.health / obj.maxHealth) * ((graphics.width > 1920 and graphics.height > 1080) and 126 or 102))

        local x2 =
          xPos + (((damage > 0 and damage or 0) / obj.maxHealth) * ((graphics.width > 1920 and graphics.height > 1080) and 126 or 102))
        if damage > 0 then
          graphics.draw_line_2D(x1, yPos, x2, yPos, 10, graphics.argb(menu.draws.transparency:get(), 255, 192, 200))
        else
          graphics.draw_line_2D(x1, yPos, x2, yPos, 10, graphics.argb(menu.draws.transparency:get(), 0, 255, 0))
        end
      end
    end
  end
end
cb.add(cb.tick, OnTick)
cb.add(cb.create_particle, CreateObj)
cb.add(cb.delete_particle, DeleteObj)

cb.add(cb.draw, OnDraw)
