local pred = module.internal("pred")
local crypt = module.internal("crypt")
local common = {}
local orb = module.internal("orb")
local evade = module.seek("evade")


function common.is_action_safe(endPos)
  for i = 1, #evade.core.skillshots do
    local spell = evade.core.skillshots[i]
    if (spell.intersection and spell:intersection(player.pos2D, endPos:to2D())) then
      return false
    end
  end
  return true
end

local bestPos = nil

function common.getIncomingDamage(delay, target)
  local dmg = 0

  for i = 1, #evade.core.targeted do
    local spell = evade.core.targeted[i]
    local tkeys = {}
    if (spell.damage and spell.target == target) and spell.damage[target.ptr] then
      for k, v in pairs(spell.damage[target.ptr]) do
        dmg = dmg + v * 1.1
      end
      bestPos = spell.owner
    end
  end

  for i = 1, #evade.core.skillshots do
    local spell = evade.core.skillshots[i]
    if
      spell.contains and spell:contains(target.path.serverPos2D) == true and spell.damage[target.ptr] --[[and (not spell.data.collision or #spell.data.collision == 0)]]
     then
      if isSpellValid(spell, delay, target) then
        local tkeys = {}
        if (spell.damage) then
          for k, v in pairs(spell.damage[target.ptr]) do
            dmg = dmg + v * 1.1
          end
        end
        bestPos = spell.owner
      end
    end
  end
  return dmg
end

function common.getCastPos()
  return bestPos.pos
end
function common.getCastObj()
  return bestPos
end

-- Delay Functions Call
local delayedActions, delayedActionsExecuter = {}, nil
function common.DelayAction(func, delay, args) --delay in seconds
  if not delayedActionsExecuter then
    function delayedActionsExecuter()
      for t, funcs in pairs(delayedActions) do
        if t <= os.clock() then
          if t == t then
            for i = 1, #funcs do
              if i == i then
                local f = funcs[i]
                if f and f.func then
                  f.func(unpack(f.args or {}))
                end
              end
            end
            delayedActions[t] = nil
          end
        end
      end
    end
    cb.add(cb.tick, delayedActionsExecuter)
  end
  local t = os.clock() + (delay or 0)
  if delayedActions[t] then
    delayedActions[t][#delayedActions[t] + 1] = {func = func, args = args}
  else
    delayedActions[t] = {{func = func, args = args}}
  end
end

function common.isPosOnScreen(pos)
  local pos2D = graphics.world_to_screen(pos)
  if pos2D.x < 0 or pos2D.x > graphics.width or pos2D.y < 0 or pos2D.y > graphics.height then
    return false
  end
  return true
end

local _intervalFunction
function common.SetInterval()
  if not _intervalFunction then
    function _intervalFunction(userFunction, startTime, timeout, count, params)
      if userFunction(unpack(params or {})) ~= false and (not count or count > 1) then
        common.DelayAction(
          _intervalFunction,
          (timeout - (os.clock() - startTime - timeout)),
          {userFunction, startTime + timeout, timeout, count and (count - 1), params}
        )
      end
    end
  end
  common.DelayAction(_intervalFunction, timeout, {userFunction, os.clock(), timeout or 0, count, params})
end

-- Print Function
function common.print(msg, color)
  local color = color or 42
  console.set_color(color)
  print(msg)
  console.set_color(15)
end

-- Returns percent health of @obj or player
function common.GetPercentHealth(obj)
  local obj = obj or player
  return (obj.health / obj.maxHealth) * 100
end

function common.hasRune(name)
  for i = 0, player.rune.size - 1 do
    if (player.rune[i].name:lower() == name) then
      return true
    end
  end
  return false
end

local recalls = {}
recalls.timers = {
  recall = 8.0,
  odinrecall = 4.5,
  odinrecallimproved = 4.0,
  recallimproved = 7.0,
  SuperRecall = 4.0
}

function common.RecallValid(recall)
  if (recalls.timers[recall]) then
    return true
  end
  return false
end

function common.GetLevel(obj)
  local obj = obj or player
  return math.min(obj.levelRef, 18)
end

-- Returns percent mana of @obj or player
function common.GetPercentMana(obj)
  local obj = obj or player
  return (obj.mana / obj.maxMana) * 100
end

-- Returns percent par (mana, energy, etc) of @obj or player
function common.GetPercentPar(obj)
  local obj = obj or player
  return (obj.par / obj.maxPar) * 100
end

function common.CheckBuff2(obj, buffname)
  if obj and obj.buff then
    if obj.buff[buffname:lower()] then
      return true
    end
  end
  return false
end
function common.StartTime(obj, buffname)
  if obj and obj.buff then
    local buff = obj.buff[buffname:lower()]
    if buff then
      if (buff.startTime) then
        return buff.startTime
      end
    end
  end
  return 0
end
function common.CheckBuffEnd(obj, buffname)
  if obj and obj.buff then
    local buff = obj.buff[buffname:lower()]
    if buff then
      if (buff.endTime) then
        return buff.endTime
      end
    end
  end
  return 0
end
function common.EndTime(obj, buffname)
  if obj and obj.buff then
    local buff = obj.buff[buffname:lower()]
    if buff then
      if (buff.endTime) then
        return buff.endTime
      end
    end
  end
  return 0
end

function common.CheckBuff(obj, buffname)
  if obj and obj.buff then
    if obj.buff[buffname:lower()] then
      return true
    end
  end
  return false
end
-- Potato API >:c
function common.CountBuff(obj, buffname)
  if obj then
    local buff = obj.buff[buffname:lower()]
    if buff then
      if (buff.stacks > 0) then
        return buff.stacks
      end
      if (buff.stacks > 0) then
        return buff.stacks
      end
    end
  end
  return 0
end
function common.CountBuff2(obj, buffname)
  if obj and obj.buff then
    local buff = obj.buff[buffname:lower()]
    if buff then
      if (buff.stacks > 0) then
        return buff.stacks
      end
      if (buff.stacks > 0) then
        return buff.stacks
      end
    end
  end
  return 0
end
function common.CheckBuffType(obj, bufftype)
  if obj and obj.buff then
    if
      obj.buff[bufftype] and obj.buff[bufftype].startTime and game.time - obj.buff[bufftype].startTime > 0.1 and
        obj.buff[bufftype].name ~= "nautilusanchordragglobalroot"
     then
      return true
    end
  end
  return false
end
function common.CheckBuffTypeFake(obj, bufftype)
  if obj and obj.buff then
    if obj.buff[bufftype] and obj.buff[bufftype].startTime and game.time - obj.buff[bufftype].startTime <= 0.2 then
      return true
    end
  end
  return false
end
-- Returns @target health+shield

local yasuoShield = {100, 105, 110, 115, 120, 130, 140, 150, 165, 180, 200, 225, 255, 290, 330, 380, 440, 510}
function common.GetShieldedHealth(damageType, target)
  local shield = 0
  if damageType == "AD" then
    shield = target.physicalShield
  elseif damageType == "AP" then
    shield = target.magicalShield
  elseif damageType == "ALL" then
    shield = target.allShield
  end
  return target.health + shield
end

-- Returns total AD of @obj or player
function common.GetTotalAD(obj)
  local obj = obj or player
  local mod = obj.percentPhysicalDamageMod
  if (obj and obj.type ~= TYPE_HERO) then
    mod = 1
  end
  return (obj.baseAttackDamage + obj.flatPhysicalDamageMod) * mod
end

-- Returns bonus AD of @obj or player
function common.GetBonusAD(obj)
  local obj = obj or player
  return ((obj.baseAttackDamage + obj.flatPhysicalDamageMod) * obj.percentPhysicalDamageMod) - obj.baseAttackDamage
end

-- Returns total AP of @obj or player
function common.GetTotalAP(obj)
  local obj = obj or player
  return obj.flatMagicDamageMod * obj.percentMagicDamageMod
end

-- Returns physical damage multiplier on @target from @damageSource or player
function common.PhysicalReduction(target, damageSource)
  source = damageSource or player
  if (target.armor == 0) then
    return 1
  end

  local armor =
    (target.bonusArmor * source.percentBonusArmorPenetration + target.armor - target.bonusArmor) *
    source.percentArmorPenetration
  if (source.type ~= TYPE_HERO) then
    armor = (target.bonusArmor * 1 + target.armor - target.bonusArmor) * 1
  end
  local lethality = source.type == TYPE_HERO and (source.physicalLethality * (.6 + .4 * source.levelRef / 18)) or 0
  return armor >= 0 and (100 / (100 + math.max(armor - lethality, 0))) or 1
end

-- Returns magic damage multiplier on @target from @damageSource or player
function common.MagicReduction(target, damageSource)
  local damageSource = damageSource or player
  local magicResist = (target.spellBlock * damageSource.percentMagicPenetration) - damageSource.flatMagicPenetration
  return magicResist >= 0 and (100 / (100 + magicResist)) or (2 - (100 / (100 - magicResist)))
end

-- Returns damage reduction multiplier on @target from @damageSource or player
function common.DamageReduction(damageType, target, damageSource)
  local damageSource = damageSource or player
  local reduction = 1
  -- Ryan Fix Please â™¥
  if damageType == "AD" then
  end
  if damageType == "AP" then
  end
  return reduction
end

-- Calculates AA damage on @target from @damageSource or player
function common.CalculateAADamage(target, damageSource)
  local damageSource = damageSource or player
  if target and damageSource.baseAttackDamage and (target.type == TYPE_MINION or target.type == TYPE_HERO) then
    return common.GetTotalAD(damageSource) * common.PhysicalReduction(target, damageSource)
  end
  return 0
end
local meow = math.floor
function common.CalculateAADamage(target, damageSource, item)
  local damageSource = damageSource or player
  local extradamage = 0
  if item then
    extradamage = target.health * 0.02
  end
  if target and damageSource.baseAttackDamage and (target.type == TYPE_MINION or target.type == TYPE_HERO) then
    return meow(
      common.GetTotalAD(damageSource) * common.PhysicalReduction(target, damageSource) +
        common.CalculatePhysicalDamage(target, extradamage, player)
    )
  end
  return 0
end

-- Calculates physical damage on @target from @damageSource or player
function common.CalculatePhysicalDamage(target, damage, damageSource)
  local damageSource = damageSource or player
  if target then
    return (damage * common.PhysicalReduction(target, damageSource)) *
      common.DamageReduction("AD", target, damageSource)
  end
  return 0
end

-- Calculates magic damage on @target from @damageSource or player
function common.CalculateMagicDamage(target, damage, damageSource)
  local damageSource = damageSource or player
  if target then
    return (damage * common.MagicReduction(target, damageSource)) * common.DamageReduction("AP", target, damageSource)
  end
  return 0
end

-- Returns @target attack range (@target is optional; will consider @target boundingRadius into calculation)
function common.GetAARange(target)
  return player.attackRange + (target and target.boundingRadius or 0)
end

-- Returns @obj predicted pos after @delay secs
function common.GetPredictedPos(obj, delay)
  if not common.IsValidTarget(obj) or not obj.path or not delay or not obj.moveSpeed then
    return obj
  end
  local pred_pos = pred.core.lerp(obj.path, network.latency + delay, obj.moveSpeed)
  return vec3(pred_pos.x, player.y, pred_pos.y)
end

-- Returns ignite damage
function common.GetIgniteDamage(target)
  local damage = 55 + (25 * player.levelRef)
  if target then
    damage = damage - (common.GetShieldedHealth("AD", target) - target.health)
  end
  return damage
end

common.enum = {}
common.enum.slots = {
  q = 0,
  w = 1,
  e = 2,
  r = 3
}
common.enum.buff_types = {
  Internal = 0,
  Aura = 1,
  CombatEnchancer = 2,
  CombatDehancer = 3,
  SpellShield = 4,
  Stun = 5,
  Invisibility = 6,
  Silence = 7,
  Taunt = 8,
  Polymorph = 9,
  Slow = 10,
  Snare = 11,
  Damage = 12,
  Heal = 13,
  Haste = 14,
  SpellImmunity = 15,
  PhysicalImmunity = 16,
  Invulnerability = 17,
  AttackSpeedSlow = 18,
  NearSight = 19,
  Currency = 20,
  Fear = 21,
  Charm = 22,
  Poison = 23,
  Suppression = 24,
  Blind = 25,
  Counter = 26,
  Shred = 27,
  Flee = 28,
  Knockup = 29,
  Knockback = 30,
  Disarm = 31,
  Grounded = 32,
  Drowsy = 33,
  Asleep = 34
}

-- Returns true if @unit has buff.type btype

local hard_cc = {
  [5] = true, -- stun
  [8] = true, -- taunt
  [11] = true, -- snare
  [18] = true, -- sleep
  [21] = true, -- fear
  [22] = true, -- charm
  [24] = true, -- suppression
  [28] = true, -- flee
  [29] = true, -- knockup
  [30] = true -- knockback
}

function common.SionCheck(object)
  if (object.type ~= TYPE_HERO) then
    return true
  else
    return not object.buff["sionpassivezombie"]
  end
end

function common.IsInvulnerable(object)
  if (object.type ~= TYPE_HERO) then
    return false
  else
    if
      (object.buff --[[object.buff[17] or object.buff[4] or--]] and
        (object.buff["sionpassivezombie"] or object.buff["chronoshift"] or object.buff["kindredrnodeathbuff"] or
          object.buff["undyingrage"]) or
        object.buff["kayler"] or
        object.buff["pantheone"])
     then
      return true
    else
      return false
    end
  end
end

-- Returns true if @object is valid target
function common.IsValidTarget(object)
  return (object and not object.isDead and object.isVisible and object.isTargetable and object.path and
    not common.CheckBuffType(object, 17) and
    common.SionCheck(object)) and
    common.IsInvulnerable(object) == false and
    not object.buff["samiraw"]
end

function common.IsValidTargetExtra(object, time)
  return (object and not object.isDead and (object.isVisible or game.time - time < 1.5) and object.isTargetable and
    not common.CheckBuffType(object, 17) and
    common.SionCheck(object)) and
    common.IsInvulnerable(object) == false
end

function common.IsValidTarget2(object)
  return (object and not object.isDead and object.isVisible and object.isTargetable and
    not common.CheckBuffType(object, 17) and
    common.SionCheck(object))
end

common.units = {}
common.units.minions, common.units.minionCount = {}, 0
common.units.enemyMinions, common.units.enemyMinionCount = {}, 0
common.units.allyMinions, common.units.allyMinionCount = {}, 0
common.units.jungleMinions, common.units.jungleMinionCount = {}, 0
common.units.enemies, common.units.allies = {}, {}

-- Returns true if enemy @minion is targetable
function common.can_target_minion(minion)
  return minion and not minion.isDead and minion.path and minion.team ~= TEAM_ALLY and minion.health and
    minion.maxHealth > 3 and -- minion.maxHealth > 100 and
    -- and minion.moveSpeed > 0
    minion.isVisible and
    minion.isTargetable and
    not string.lower(minion.name):find("trap")
end

function common.can_target_minion_ally(minion)
  return minion and not minion.isDead and minion.team == TEAM_ALLY and minion.health and minion.maxHealth > 3 and -- minion.maxHealth > 100 and
    -- and minion.moveSpeed > 0
    minion.isVisible and
    minion.isTargetable and
    not string.lower(minion.name):find("trap")
end

local excluded_minions = {
  ["CampRespawn"] = true,
  ["PlantMasterMinion"] = true,
  ["PlantHealth"] = true,
  ["PlantSatchel"] = true,
  ["PlantVision"] = true
}

local function valid_minion(minion)
  return minion and minion.type == TYPE_MINION and not minion.isDead and minion.health > 0 and minion.maxHealth > 100 and
    minion.maxHealth < 20000 and
    not minion.name:find("Ward") and
    not excluded_minions[minion.name]
end

local function valid_hero(hero)
  return hero and hero.type == TYPE_HERO
end

local function find_place_and_insert(t, c, o, v)
  local dead_place = nil
  for i = 1, c do
    local tmp = t[i]
    if not v(tmp) then
      dead_place = i
      break
    end
  end
  if dead_place then
    t[dead_place] = o
  else
    c = c + 1
    t[c] = o
  end
  return c
end

local function check_add_minion(o)
  if valid_minion(o) then
    if o.team == TEAM_ALLY then
      common.units.allyMinionCount =
        find_place_and_insert(common.units.allyMinions, common.units.allyMinionCount, o, valid_minion)
    elseif o.team == TEAM_ENEMY then
      common.units.enemyMinionCount =
        find_place_and_insert(common.units.enemyMinions, common.units.enemyMinionCount, o, valid_minion)
    else
      common.units.jungleMinionCount =
        find_place_and_insert(common.units.jungleMinions, common.units.jungleMinionCount, o, valid_minion)
    end
    common.units.minionCount = find_place_and_insert(common.units.minions, common.units.minionCount, o, valid_minion)
  end
end

local function check_add_hero(o)
  if valid_hero(o) then
    if o.team == TEAM_ALLY then
      find_place_and_insert(common.units.allies, #common.units.allies, o, valid_hero)
    else
      find_place_and_insert(common.units.enemies, #common.units.enemies, o, valid_hero)
    end
  end
end

objManager.loop(
  function(obj)
    check_add_hero(obj)
    check_add_minion(obj)
  end
)

function common.GetEvadeInfo(from, delay, delay2, delay3, targeted)
  for i = 1, #evade.core.skillshots do
    local spell = evade.core.skillshots[i]

    if (targeted) then
      if spell.data.spell_type == "Target" and spell.target == from and spell.owner.type == TYPE_HERO then
        local enemyName = string.lower(spell.owner.charName)
        if common.TargetedSpells()[enemyName] then
          return spell.owner, spell.data
        end
      end
    end
    if
      spell.polygon and spell.polygon:Contains(from.path.serverPos) ~= 0 and
        (not spell.data.collision or #spell.data.collision == 0)
     then
      if
        (spell.data and spell.data.owner_is_missile and spell.data.speed and
          (from.pos:dist(spell.owner.pos) / spell.data.speed < delay3))
       then
        return spell.owner, spell.data
      end

      if
        (from.pos:dist(spell.owner.pos) <= 250 and
          (spell.data.speed ~= math.huge and spell.data.spell_type ~= "Circular" or
            spell.end_time - spell.start_time < delay2))
       then
        return spell.owner, spell.data
      end

      if (spell.special_object and spell.special_object.pos) then
        if (from.pos:dist(spell.special_object.pos) / spell.data.speed < delay) then
          return spell.owner, spell.data
        end
      end
      if spell.missile then
        if (from.pos:dist(spell.missile.pos) / spell.data.speed < delay) then
          return spell.owner, spell.data
        end
      end
      if spell.data.speed == math.huge or spell.data.spell_type == "Circular" then
        if spell.owner and spell.end_time - os.clock() < delay + 0.1 then
          return spell.owner, spell.data
        end
      end
    end
  end
end

-- Returns table of ally hero.obj in @range from @pos
function common.GetAllyHeroesInRange(range, pos)
  local pos = pos or player
  local h = {}
  local allies = common.GetAllyHeroes()
  for i = 1, #allies do
    local hero = allies[i]
    if common.IsValidTarget(hero) and hero.pos:distSqr(pos) < range * range then
      h[#h + 1] = hero
    end
  end
  return h
end

-- Returns table of hero.obj in @range from @pos
function common.GetEnemyHeroesInRange(range, pos)
  local pos = pos or player
  local h = {}
  local enemies = common.GetEnemyHeroes()
  for i = 1, #enemies do
    local hero = enemies[i]
    if common.IsValidTarget(hero) and hero.pos:distSqr(pos) < range * range then
      h[#h + 1] = hero
    end
  end
  return h
end

-- Returns table and number of objects near @pos
function common.CountObjectsNearPos(pos, radius, objects, validFunc)
  local n, o = 0, {}
  for i, object in pairs(objects) do
    if validFunc(object) and pos:dist(object.pos) <= radius then
      n = n + 1
      o[n] = object
    end
  end
  return n, o
end

-- Returns table of @team minion.obj in @range
function common.GetMinionsInRange(range, team, pos)
  pos = pos or player.pos
  range = range or math.huge
  objects = team or TEAM_ENEMY
  objects = {}
  for i = 0, objManager.minions.size[team] - 1 do
    local obj = objManager.minions[team][i]
    if pos:dist(obj.pos) < range and obj and not obj.isDead and obj.health and obj.health > 0 and obj.isVisible then
      table.insert(objects, obj)
    end
  end
  return objects
end

-- Returns table of enemy hero.obj
function common.GetEnemyHeroes()
  return common.units.enemies
end

function common.TargetedSpells()
  return {
    ["alistar"] = {
      {menuslot = "W", slot = 1}
    },
    ["ezreal"] = {
      {menuslot = "E", slot = 2}
    },
    ["annie"] = {
      {menuslot = "Q", slot = 0}
    },
    ["anivia"] = {
      {menuslot = "E", slot = 2}
    },
    ["sett"] = {
      {menuslot = "R", slot = 3}
    },
    ["blitzcrank"] = {
      {menuslot = "E", slot = 2}
    },
    ["brand"] = {
      {menuslot = "E", slot = 2},
      {menuslot = "R", slot = 3}
    },
    ["caitlyn"] = {
      {menuslot = "R", slot = 3}
    },
    ["camille"] = {
      {menuslot = "R", slot = 3}
    },
    ["cassiopeia"] = {
      {menuslot = "E", slot = 2}
    },
    ["chogath"] = {
      {menuslot = "R", slot = 3}
    },
    ["darius"] = {
      {menuslot = "W", slot = 1},
      {menuslot = "R", slot = 3}
    },
    ["diana"] = {
      {menuslot = "R", slot = 3}
    },
    ["elise"] = {
      {menuslot = "Q", slot = 0}
    },
    ["evelynn"] = {
      {menuslot = "E", slot = 2}
    },
    ["fiddlesticks"] = {
      {menuslot = "Q", slot = 0}
    },
    ["fizz"] = {
      {menuslot = "Q", slot = 0}
    },
    ["gangplank"] = {
      {menuslot = "Q", slot = 0}
    },
    ["garen"] = {
      {menuslot = "Q", slot = 0},
      {menuslot = "R", slot = 3}
    },
    ["hecarim"] = {
      {menuslot = "E", slot = 2}
    },
    ["irelia"] = {
      {menuslot = "Q", slot = 0}
    },
    ["janna"] = {
      {menuslot = "W", slot = 1}
    },
    ["jarvaniv"] = {
      {menuslot = "R", slot = 3}
    },
    ["jax"] = {
      {menuslot = "Q", slot = 0}
    },
    ["jayce"] = {
      {menuslot = "Q", slot = 0}
    },
    ["jhin"] = {
      {menuslot = "Q", slot = 0}
    },
    ["kalista"] = {
      {menuslot = "E", slot = 2}
    },
    ["karma"] = {
      {menuslot = "W", slot = 1}
    },
    ["katarina"] = {
      {menuslot = "Q", slot = 0}
    },
    ["kennen"] = {
      {menuslot = "E", slot = 2}
    },
    ["khazix"] = {
      {menuslot = "Q", slot = 0}
    },
    ["leblanc"] = {
      {menuslot = "Q", slot = 0}
    },
    ["leesin"] = {
      {menuslot = "R", slot = 3}
    },
    ["leona"] = {
      {menuslot = "Q", slot = 0}
    },
    ["lissandra"] = {
      {menuslot = "R", slot = 3}
    },
    ["nautilus"] = {
      {menuslot = "R", slot = 3}
    },
    ["lulu"] = {
      {menuslot = "W", slot = 1},
      {menuslot = "E", slot = 2}
    },
    ["malphite"] = {
      {menuslot = "Q", slot = 0}
    },
    ["malzahar"] = {
      {menuslot = "E", slot = 2},
      {menuslot = "R", slot = 3}
    },
    ["maokai"] = {
      {menuslot = "W", slot = 1}
    },
    ["missfortune"] = {
      {menuslot = "Q", slot = 0}
    },
    ["morgana"] = {
      {menuslot = "R", slot = 3}
    },
    ["nami"] = {
      {menuslot = "W", slot = 1}
    },
    ["nasus"] = {
      {menuslot = "Q", slot = 0},
      {menuslot = "W", slot = 1}
    },
    ["nocturne"] = {
      {menuslot = "E", slot = 2}
    },
    ["olaf"] = {
      {menuslot = "E", slot = 2}
    },
    ["pantheon"] = {
      {menuslot = "W", slot = 1}
    },
    ["poppy"] = {
      {menuslot = "E", slot = 2}
    },
    ["quinn"] = {
      {menuslot = "E", slot = 2}
    },
    ["rammus"] = {
      {menuslot = "E", slot = 2}
    },
    ["renekton"] = {
      {menuslot = "W", slot = 1}
    },
    ["drmundo"] = {
      {menuslot = "E", slot = 2}
    },
    ["monkeyking"] = {
      {menuslot = "Q", slot = 0}
    },
    ["mordekaiser"] = {
      {menuslot = "R", slot = 3}
    },
    ["yorick"] = {
      {menuslot = "Q", slot = 0}
    },
    ["rengar"] = {
      {menuslot = "Q", slot = 0}
    },
    ["ryze"] = {
      {menuslot = "W", slot = 1},
      {menuslot = "E", slot = 2}
    },
    ["shaco"] = {
      {menuslot = "E", slot = 2}
    },
    ["singed"] = {
      {menuslot = "E", slot = 2}
    },
    ["skarner"] = {
      {menuslot = "R", slot = 3}
    },
    ["sylas"] = {
      {menuslot = "R", slot = 3}
    },
    ["syndra"] = {
      {menuslot = "R", slot = 3}
    },
    ["tahmkench"] = {
      {menuslot = "W", slot = 1}
    },
    ["talon"] = {
      {menuslot = "Q", slot = 0}
    },
    ["teemo"] = {
      {menuslot = "Q", slot = 0}
    },
    ["tristana"] = {
      {menuslot = "R", slot = 3}
    },
    ["trundle"] = {
      {menuslot = "Q", slot = 0}
    },
    ["twistedfate"] = {
      {menuslot = "W", slot = 1}
    },
    ["twitch"] = {
      {menuslot = "E", slot = 2}
    },
    ["udyr"] = {
      {menuslot = "E", slot = 2}
    },
    ["vayne"] = {
      {menuslot = "E", slot = 2}
    },
    ["veigar"] = {
      {menuslot = "R", slot = 3}
    },
    ["vi"] = {
      {menuslot = "R", slot = 3}
    },
    ["viktor"] = {
      {menuslot = "Q", slot = 0}
    },
    ["vladimir"] = {
      {menuslot = "Q", slot = 0}
    },
    ["volibear"] = {
      {menuslot = "Q", slot = 0},
      {menuslot = "W", slot = 1}
    },
    ["warwick"] = {
      {menuslot = "Q", slot = 0}
    },
    ["monkeyking"] = {
      {menuslot = "E", slot = 2}
    },
    ["xinzhao"] = {
      {menuslot = "Q", slot = 0}
    },
    ["yasuo"] = {
      {menuslot = "E", slot = 2}
    },
    ["zed"] = {
      {menuslot = "R", slot = 3}
    }
  }
end

function common.GetInterruptableSpells()
  return {
    ["caitlyn"] = {
      {menuslot = "R", slot = 3, spellname = "caitlynaceinthehole", channelduration = 1}
    },
    ["fiddlesticks"] = {
      {menuslot = "W", slot = 1, spellname = "drainchannel", channelduration = 2},
      {menuslot = "R", slot = 3, spellname = "crowstorm", channelduration = 1.5}
    },
    ["janna"] = {
      {menuslot = "R", slot = 3, spellname = "reapthewhirlwind", channelduration = 3}
    },
    ["karthus"] = {
      {menuslot = "R", slot = 3, spellname = "karthusfallenone", channelduration = 3}
    },
    ["katarina"] = {
      {menuslot = "R", slot = 3, spellname = "katarinar", channelduration = 2.5}
    },
    ["lucian"] = {
      {menuslot = "R", slot = 3, spellname = "lucianr", channelduration = 3}
    },
    ["malzahar"] = {
      {menuslot = "R", slot = 3, spellname = "malzaharr", channelduration = 2.5}
    },
    ["masteryi"] = {
      {menuslot = "W", slot = 1, spellname = "meditate", channelduration = 4}
    },
    ["missfortune"] = {
      {menuslot = "R", slot = 3, spellname = "missfortunebullettime", channelduration = 3}
    },
    ["nunu"] = {
      {menuslot = "R", slot = 3, spellname = "nunur", channelduration = 3}
    },
    ["pantheon"] = {
      {menuslot = "R", slot = 3, spellname = "pantheonrjump", channelduration = 2},
      {menuslot = "Q", slot = 0, spellname = "pantheonq", channelduration = 4}
    },
    ["poppy"] = {
      {menuslot = "R", slot = 3, spellname = "poppyr", channelduration = 4}
    },
    ["quinn"] = {
      {menuslot = "R", slot = 3, spellname = "quinr", channelduration = 2}
    },
    ["shen"] = {
      {menuslot = "R", slot = 3, spellname = "shenr", channelduration = 3}
    },
    ["sion"] = {
      {menuslot = "Q", slot = 0, spellname = "sionq", channelduration = 2}
    },
    ["tahmkench"] = {
      {menuslot = "R", slot = 3, spellname = "tahmkenchnewr", channelduration = 3}
    },
    ["twistedfate"] = {
      {menuslot = "R", slot = 3, spellname = "gate", channelduration = 1.5}
    },
    ["varus"] = {
      {menuslot = "Q", slot = 0, spellname = "varusq", channelduration = 4}
    },
    ["velkoz"] = {
      {menuslot = "R", slot = 3, spellname = "velkozr", channelduration = 2.5}
    },
    ["warwick"] = {
      {menuslot = "R", slot = 3, spellname = "warwickrchannel", channelduration = 1.5}
    },
    ["xerath"] = {
      {menuslot = "Q", slot = 0, spellname = "xeratharcanopulsechargeup", channelduration = 3},
      {menuslot = "R", slot = 3, spellname = "xerathlocusofpower2", channelduration = 10}
    },
    ["zac"] = {
      {menuslot = "E", slot = 2, spellname = "zace", channelduration = 4}
    },
    ["jhin"] = {
      {menuslot = "R", slot = 3, spellname = "jhinr", channelduration = 10}
    },
    ["pyke"] = {
      {menuslot = "Q", slot = 0, spellname = "pykeq", channelduration = 3}
    },
    ["vi"] = {
      {menuslot = "Q", slot = 0, spellname = "viq", channelduration = 4}
    },
    ["samira"] = {
      {menuslot = "R", slot = 3, spellname = "samirar", channelduration = 2}
    }
  }
end

-- Returns table of ally hero.obj
function common.GetAllyHeroes()
  return common.units.allies
end
-- Returns table of ally hero.obj
function common.GetJungleMinions()
  local junglerMins = {}
  for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
    local minion = objManager.minions[TEAM_NEUTRAL][i]
    if minion and not minion.isDead and minion.isTargetable and minion.isVisible and minion.type == TYPE_MINION then
      table.insert(junglerMins, minion)
    end
  end
  return junglerMins
end
-- Returns ally fountain object
common._fountain = nil
common._fountainRadius = 750
function common.GetFountain()
  if common._fountain then
    return common._fountain
  end

  local map = common.GetMap()
  if map and map.index and map.index == 1 then
    common._fountainRadius = 1050
  end

  if common.GetShop() then
    objManager.loop(
      function(obj)
        if
          obj and obj.team == TEAM_ALLY and obj.name:lower():find("spawn") and not obj.name:lower():find("troy") and
            not obj.name:lower():find("barracks")
         then
          common._fountain = obj
          return common._fountain
        end
      end
    )
  end
  return nil
end

-- Returns true if you are near fountain
function common.NearFountain(distance)
  local d = distance or common._fountainRadius or 0
  local fountain = common.GetFountain()
  if fountain then
    return (player.pos2D:distSqr(fountain.pos2D) <= d * d), fountain.x, fountain.y, fountain.z, d
  else
    return false, 0, 0, 0, 0
  end
end
common._map = {index = 0, name = "unknown"}
function common.GetMap()
  if common._map.index ~= 0 then
    return common._map
  end
  local obj = common.GetShop()
  if obj then
    if math.floor(obj.x) == 232 and math.floor(obj.y) == 163 and math.floor(obj.z) == 1277 then
      common._map = {index = 1, name = "Summoner's Rift"}
    elseif math.floor(obj.x) == 1313 and math.floor(obj.y) == 123 and math.floor(obj.z) == 8005 then
      common._map = {index = 4, name = "Twisted Treeline"}
    elseif math.floor(obj.x) == 497 and math.floor(obj.y) == -40 and math.floor(obj.z) == 1932 then
      common._map = {index = 12, name = "Howling Abyss"}
    else
      print(
        "Unknown Map! Shop: x:" ..
          tostring(math.floor(obj.x)) .. " y:" .. tostring(math.floor(obj.y)) .. " z:" .. tostring(math.floor(obj.z))
      )
    end
  end
  return common._map
end
-- Returns true if you are near fountain
function common.InFountain()
  return common.NearFountain()
end

local ZedW = nil
local ZedR = nil

local recentRCast = 0
local recentWCast = 0

local wPosAnivia = nil
local rPosAzir = nil
local jarvanE = nil
local ornnQ = nil
local trundleE = nil
local yorickE = nil

local function RectangleToPolygon(startPos, endPos, radius, offset)
  local offset = offset or 0
  local dir = (endPos - startPos):norm()
  local perp = (radius) * dir:perp1()
  return {
    (startPos + perp - offset * dir):to2D(),
    (startPos - perp - offset * dir):to2D(),
    (endPos - perp + offset * dir):to2D(),
    (endPos + perp + offset * dir):to2D()
  }
end
local function IsPointInPolygon(poly, point)
  local result, j = false, #poly
  for i = 1, #poly do
    if poly[i].y < point.z and poly[j].y >= point.z or poly[j].y < point.z and poly[i].y >= point.z then
      if poly[i].x + (point.z - poly[i].y) / (poly[j].y - poly[i].y) * (poly[j].x - poly[i].x) < point.x then
        result = not result
      end
    end
    j = i
  end
  return result
end

local function on_create_minion(obj)
  if (obj and obj.name == "Shadow" and obj.owner and obj.owner.team == TEAM_ENEMY) then
    if (recentRCast > game.time) then
      ZedR = obj
    end
    if (recentWCast > game.time) then
      ZedW = obj
    end
  end
  if (obj.name == "IceBlock") then
    wPosAnivia = obj
  end
  if (obj.name == "AzirRSoldier") then
    rPosAzir = obj
  end
  if (obj.name == "Beacon" and obj.owner.charName == "JarvanIV") then
    jarvanE = obj
  end
  if (obj.name == "OrnnQPillar" and obj.owner.charName == "Ornn") then
    ornnQ = obj
  end
  if (obj.name == "PlagueBlock" and obj.owner.charName == "Trundle") then
    trundleE = obj
  end
  if (obj.name == "InvisibleWall" and obj.owner.charName == "Yorick") then
    yorickE = obj
  end
end

local function on_delete_minion(obj)
  if (ZedR and obj and obj.ptr == ZedR.ptr) then
    ZedR = nil
  end
  if (ZedW and obj and obj.ptr == ZedW.ptr) then
    ZedW = nil
  end
  if (wPosAnivia and obj.ptr == wPosAnivia.ptr) then
    wPosAnivia = nil
  end
  if (rPosAzir and obj.ptr == rPosAzir.ptr) then
    rPosAzir = nil
  end
  if (jarvanE and obj.ptr == jarvanE.ptr) then
    jarvanE = nil
  end
  if (ornnQ and obj.ptr == ornnQ.ptr) then
    ornnQ = nil
  end
  if (trundleE and obj.ptr == trundleE.ptr) then
    trundleE = nil
  end
  if (yorickE and obj.ptr == yorickE.ptr) then
    yorickE = nil
  end
end

cb.add(cb.create_minion, on_create_minion)
cb.add(cb.delete_minion, on_delete_minion)

local function VectorExtend(v, t, d)
  return v + d * (t - v):norm()
end

function common.isWallValid(point)
  if (wPosAnivia and not wPosAnivia.isDead) then
    local rect =
      RectangleToPolygon(
      wPosAnivia.pos,
      wPosAnivia.pos +
        (VectorExtend(wPosAnivia.pos, wPosAnivia.pos + wPosAnivia.direction, 300) - wPosAnivia.pos):norm():perp1() *
          (300 + wPosAnivia.owner:spellSlot(1).level * 100),
      100,
      150
    )
    if (IsPointInPolygon(rect, point)) then
      return true
    end
  end
  if (rPosAzir and not rPosAzir.isDead) then
    local rect =
      RectangleToPolygon(
      rPosAzir.pos,
      rPosAzir.pos +
        (VectorExtend(rPosAzir.pos, rPosAzir.pos + rPosAzir.direction, 300) - rPosAzir.pos):norm():perp1() *
          (400 + rPosAzir.owner:spellSlot(3).level * 100),
      100,
      100
    )
    if (IsPointInPolygon(rect, point)) then
      return true
    end
  end
  if (jarvanE and not jarvanE.isDead) then
    if (jarvanE.pos:dist(point) < 50) then
      return true
    end
  end
  if (ornnQ and not ornnQ.isDead) then
    if (ornnQ.pos:dist(point) < 80) then
      return true
    end
  end
  if (trundleE and not trundleE.isDead) then
    if (trundleE.pos:dist(point) < 100) then
      return true
    end
  end
  if (yorickE and not yorickE.isDead) then
    if (VectorExtend(yorickE.pos, yorickE.pos + yorickE.direction, 200):dist(point) < 250) then
      return true
    end
  end
  return false
end

-- Returns the ally shop object
common._shop = nil
common._shopRadius = 1250
function common.GetShop()
  if common._shop then
    return common._shop
  end
  objManager.loop(
    function(obj)
      if obj and obj.team == TEAM_ALLY and obj.name:lower():find("shop") then
        common._shop = obj
        return common._shop
      end
    end
  )
  return nil
end

function common.calculateRunes(enemy)
  if (not enemy) then
    return 0
  end
  if
    (player.buff["assets/perks/styles/domination/darkharvest/darkharvest.lua"] and
      (enemy.health / enemy.maxHealth) * 100 < 50)
   then
    if (common.GetBonusAD(player) < common.GetTotalAP(player)) then
      return common.CalculateMagicDamage(
        enemy,
        (17.647 + 2.353 * player.levelRef) +
          5 * player.buff["assets/perks/styles/domination/darkharvest/darkharvest.lua"].stacks2 +
          common.GetBonusAD(player) * 0.25 +
          common.GetTotalAP(player) * 0.15
      )
    else
      return common.CalculatePhysicalDamage(
        enemy,
        (17.647 + 2.353 * player.levelRef) +
          5 * player.buff["assets/perks/styles/domination/darkharvest/darkharvest.lua"].stacks2 +
          common.GetBonusAD(player) * 0.25 +
          common.GetBonusGetTotalAPAP(player) * 0.15
      )
    end
  end
end

function common.getturretenemy(position)
  for i = 0, objManager.turrets.size[TEAM_ENEMY] - 1 do
    local turret = objManager.turrets[TEAM_ENEMY][i]
    if turret and not turret.isDead and turret.pos:dist(position) < 930 then
      return true
    end
  end
  return false
end

local startdraw = {}

function common.count_enemies_in_range_inv(pos, range, interval)
  local secTime = interval or 2
  local enemies_in_range = {}
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
      enemies_in_range[#enemies_in_range + 1] = enemy
    end
    if
      startdraw[enemy.networkID] and startdraw[enemy.networkID].isBush and
        startdraw[enemy.networkID].isBush - game.time > 0 and
        interval ~= 2
     then
      secTime = 0
    end
    if
      pos:dist(enemy.pos) < range and not common.IsValidTarget(enemy) and startdraw[enemy.networkID] and
        startdraw[enemy.networkID].lastVisible and
        (startdraw[enemy.networkID].lastVisible + secTime) - game.time > 0
     then
      enemies_in_range[#enemies_in_range + 1] = enemy
    end
  end
  return enemies_in_range
end

local function OnTick()
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    if enemy.type == TYPE_HERO and enemy.team == TEAM_ENEMY then
      if dasenemyher and not enemy.isDead then
        if not startdraw[enemy.networkID] then
          startdraw[enemy.networkID] = {}
        end
        if enemy.isVisible then
          local testPos = pred.core.get_pos_after_time(enemy, 0.25)
          startdraw[enemy.networkID].lastVisible = game.time
          if testPos and navmesh.isGrass(testPos) then
            startdraw[enemy.networkID].isBush = game.time + 2
          end
        end
      end
    end
  end
end
orb.combat.register_f_pre_tick(OnTick)

return common
