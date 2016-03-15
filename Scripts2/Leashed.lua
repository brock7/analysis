RUN_IN_FEAR = 2
HOSTILE = 1
INACTIVE = 0
LEASH_COUNTER_THRESHOLD = 6
DEFAULT_FRUSTRATION_SEARCH_TIME = 0.05
DELAY_BETWEEN_FRUSTRATION_SEARCH_TIME = 0.6
AGGRESSION_FIRST_SWEEP_RANGE = 400
LEASH_PROTECTION_BARRIER = 100
INNER_RANGE_BEFORE_CAMP_RELEASES = 700
OUTER_RANGE_BOUND = 250
ATTACKER_RANGE_BEFORE_RELEASH = 1150
CURRENT_TARGET_TO_ATTACKER_SWITCH_RANGE = 25
FEAR_WANDER_DISTANCE = 500
DoLuaShared("AIComponentSystem")
DoLuaShared("ObjectTags")
AddComponent("OutOfCombatRegen")
AddComponent("DefaultFearBehavior")
AddComponent("DefaultFleeBehavior")
AddComponent("DefaultTauntBehavior")
function OnInit(A0_0)
  Event("ComponentInit")
  SetState(AI_ATTACK)
  SetCharVar("WillBeFrustrated", 0)
  SetCharVar("StartBoostRegen", 0)
  SetCharVar("inStasis", 0)
  OutOfCombatRegen:Start()
  SetMyLeashedPos()
  SetMyLeashedOrientation()
  InitTimer("TimerFrustrationSearch", DEFAULT_FRUSTRATION_SEARCH_TIME, true)
  InitTimer("TimerAttack", 0.25, true)
  InitTimer("TimerReturningHome", 0.05, true)
  StopTimer("TimerFrustrationSearch")
  StopTimer("TimerReturningHome")
end
function OnOrder(A0_1, A1_2)
  if GetState() == AI_HALTED then
    return
  end
  if A0_1 == ORDER_ATTACKTO then
    AttackTarget(A1_2)
    return true
  end
  Error("Unsupported Order")
  return false
end
function LeashedCallForHelp(A0_3, A1_4)
  local L2_5, L3_6, L4_7, L5_8, L6_9
  L2_5 = GetState
  L2_5 = L2_5()
  L3_6 = AI_HALTED
  if L2_5 == L3_6 then
    return
  end
  L3_6 = GetTarget
  L3_6 = L3_6()
  L4_7 = RespondToAggression
  L5_8 = A1_4
  L4_7(L5_8)
  L4_7 = GetState
  L4_7 = L4_7()
  L5_8 = AI_RETREAT
  if L4_7 == L5_8 then
    L4_7 = GetLeashCounter
    L4_7 = L4_7()
    L5_8 = LEASH_COUNTER_THRESHOLD
    if L4_7 < L5_8 then
      L4_7 = GetMaxHP
      L4_7 = L4_7()
      L5_8 = GetHP
      L5_8 = L5_8()
      L6_9 = GetCampLeashPos
      L6_9 = L6_9()
      if WalkDistanceBetweenObjectCenterAndPoint(A1_4, L6_9) <= GetCampLeashRadius() then
        AttackTarget(A1_4)
      elseif GetWalkDistToLeashedPos() <= INNER_RANGE_BEFORE_CAMP_RELEASES and WalkDistanceBetweenObjectCenterAndPoint(A1_4, L6_9) <= ATTACKER_RANGE_BEFORE_RELEASH then
        AttackTarget(A1_4)
      end
    end
  end
end
function OnTargetLost(A0_10, A1_11)
  local L2_12, L3_13
  L2_12 = TurnOffAutoAttack
  L3_13 = STOPREASON_MOVING
  L2_12(L3_13)
  L2_12 = GetState
  L2_12 = L2_12()
  L3_13 = AI_HALTED
  if L2_12 ~= L3_13 then
    L3_13 = AI_RETREAT
  elseif L2_12 == L3_13 then
    L3_13 = true
    return L3_13
  end
  L3_13 = GetCharVar
  L3_13 = L3_13("inStasis")
  if L3_13 > 1 then
    L3_13 = false
    return L3_13
  end
  L3_13 = GetOwner
  L3_13 = L3_13(A1_11)
  if L3_13 == nil then
    L3_13 = GetGoldRedirectTarget(A1_11)
  end
  if L3_13 ~= nil then
    AttackTarget(L3_13)
  else
    FindNewTarget()
  end
  return true
end
function TimerRetreat()
  if GetLeashCounter() < LEASH_COUNTER_THRESHOLD then
    SetTimerDelay("TimerFrustrationSearch", DELAY_BETWEEN_FRUSTRATION_SEARCH_TIME)
    ResetAndStartTimer("TimerFrustrationSearch")
  end
end
function AttackTarget(A0_14)
  if GetLeashCounter() > 0 then
    SetTimerDelay("TimerFrustrationSearch", DELAY_BETWEEN_FRUSTRATION_SEARCH_TIME)
    StartTimer("TimerFrustrationSearch")
    StartTimer("TimerAttack")
  else
    SetTimerDelay("TimerFrustrationSearch", DEFAULT_FRUSTRATION_SEARCH_TIME)
    ResetAndStartTimer("TimerFrustrationSearch")
    StartTimer("TimerAttack")
  end
  if A0_14 ~= nil then
    OutOfCombatRegen:Stop()
    SetStateAndCloseToTarget(AI_ATTACK, A0_14)
    SetRoamState(HOSTILE)
  end
end
function Retreat()
  StopTimer("TimerFrustrationSearch")
  StartTimer("TimerReturningHome")
  SetGhosted(true)
  SetStateAndMoveToLeashedPos(AI_RETREAT)
  TurnOffAutoAttack(STOPREASON_MOVING)
  OutOfCombatRegen:Start()
end
function IncreaseFrustration(A0_15)
  local L1_16
  L1_16 = GetLeashCounter
  L1_16 = L1_16()
  L1_16 = L1_16 + A0_15
  SetLeashCounter(L1_16)
  while A0_15 > 0 do
    AIScriptSpellBuffStackingAdd(GetThis(), GetThis(), "JungleFrustration", 1, LEASH_COUNTER_THRESHOLD + 1, 25000)
  end
  if L1_16 > LEASH_COUNTER_THRESHOLD then
    AIScriptSpellBuffStackingAdd(GetThis(), GetThis(), "JungleFrustration", 1, LEASH_COUNTER_THRESHOLD + 1, 25000)
    AIScriptSpellBuffStackingAdd(GetThis(), GetThis(), "JungleFrustrationReturn", 1, LEASH_COUNTER_THRESHOLD + 1, 25000)
    AIScriptSpellBuffRemove(GetThis(), "JungleFrustration")
    SetCharVar("StartBoostRegen", 1)
    Retreat()
  else
    SetTimerDelay("TimerFrustrationSearch", DELAY_BETWEEN_FRUSTRATION_SEARCH_TIME)
    ResetTimer("TimerFrustrationSearch")
  end
end
function TargetWithinWalkBounds(A0_17, A1_18)
  local L2_19
  L2_19 = GetCampLeashPos
  L2_19 = L2_19()
  if A0_17 == nil then
    return false
  end
  if A1_18 < WalkDistanceBetweenObjectCenterAndPoint(A0_17, L2_19) then
    return false
  else
    return true
  end
end
function FindNearestAggressor(A0_20, A1_21)
  local L2_22, L3_23
  L2_22 = GetCampLeashRadius
  L2_22 = L2_22()
  L2_22 = L2_22 * 1.25
  L3_23 = FindTargetWithFilter
  L3_23 = L3_23(AGGRESSION_FIRST_SWEEP_RANGE, UnitTagFlags.Minion + UnitTagFlags.Champion, UnitTagFlags.Special_Void + UnitTagFlags.Minion_Lane)
  if L3_23 == nil or not TargetWithinWalkBounds(L3_23, L2_22) then
    L3_23 = FindTargetWithFilter(GetCampLeashRadius() + OUTER_RANGE_BOUND, UnitTagFlags.Minion + UnitTagFlags.Champion, UnitTagFlags.Special_Void + UnitTagFlags.Minion_Lane)
  end
  if L3_23 == nil or not TargetWithinWalkBounds(L3_23, L2_22) then
    L3_23 = FindTargetNearPosition(A0_20, GetCampLeashRadius())
    if L3_23 == nil or not TargetWithinWalkBounds(L3_23, L2_22) then
      L3_23 = A1_21
    end
  end
  if L3_23 == nil or not TargetWithinWalkBounds(L3_23, L2_22) then
    L3_23 = nil
    L3_23 = FindTargetWithFilter(GetCampLeashRadius() + OUTER_RANGE_BOUND, UnitTagFlags.Minion + UnitTagFlags.Champion, UnitTagFlags.Special_Void + UnitTagFlags.Minion_Lane)
    return L3_23
  else
    return L3_23
  end
end
function OnTakeDamage(A0_24)
end
function RespondToAggression(A0_25)
  local L1_26, L2_27, L3_28, L4_29, L5_30, L6_31, L7_32, L8_33, L9_34, L10_35
  L1_26 = GetMyPos
  L1_26 = L1_26()
  L2_27 = GetState
  L2_27 = L2_27()
  L3_28 = GetRoamState
  L3_28 = L3_28()
  L4_29 = INACTIVE
  if L3_28 == L4_29 then
    L3_28 = AI_RETREAT
    if L2_27 ~= L3_28 then
      L3_28 = AI_TAUNTED
      if L2_27 ~= L3_28 then
        L3_28 = AI_FEARED
        if L2_27 ~= L3_28 then
          L3_28 = AI_FLEEING
          if L2_27 ~= L3_28 then
            L3_28 = GetMaxHP
            L3_28 = L3_28()
            L4_29 = GetHP
            L4_29 = L4_29()
            L5_30 = GetLeashCounter
            L5_30 = L5_30()
            L6_31 = IsValidEnemy
            L7_32 = A0_25
            L6_31 = L6_31(L7_32)
            if not L6_31 then
              L6_31 = LEASH_COUNTER_THRESHOLD
            else
              if L5_30 < L6_31 then
                L6_31 = AttackTarget
                L7_32 = A0_25
                L6_31(L7_32)
            end
            else
              L6_31 = OutOfCombatRegen
              L7_32 = L6_31
              L6_31 = L6_31.Start
              L6_31(L7_32)
            end
          end
        end
      end
    end
  else
    L3_28 = GetRoamState
    L3_28 = L3_28()
    L4_29 = HOSTILE
    if L3_28 == L4_29 then
      L3_28 = AI_ATTACK
      if L2_27 == L3_28 then
        L3_28 = IsValidEnemy
        L4_29 = A0_25
        L3_28 = L3_28(L4_29)
        if L3_28 then
          L3_28 = GetTarget
          L3_28 = L3_28()
          target = L3_28
          L3_28 = target
          if L3_28 ~= nil then
            L3_28 = target
            if L3_28 ~= A0_25 then
              L3_28 = GetMyPos
              L3_28 = L3_28()
              L4_29 = OutOfCombatRegen
              L5_30 = L4_29
              L4_29 = L4_29.Stop
              L4_29(L5_30)
              L4_29 = DistanceBetweenObjectCenterAndPoint
              L5_30 = target
              L6_31 = L3_28
              L4_29 = L4_29(L5_30, L6_31)
              L5_30 = GetCampLeashPos
              L5_30 = L5_30()
              L6_31 = WalkDistanceBetweenObjectCenterAndPoint
              L7_32 = target
              L8_33 = L5_30
              L6_31 = L6_31(L7_32, L8_33)
              L7_32 = GetCampLeashRadius
              L7_32 = L7_32()
              L8_33 = DistanceBetweenObjectCenterAndPoint
              L9_34 = A0_25
              L10_35 = L3_28
              L8_33 = L8_33(L9_34, L10_35)
              L9_34 = WalkDistanceBetweenObjectCenterAndPoint
              L10_35 = A0_25
              L9_34 = L9_34(L10_35, L5_30)
              L10_35 = GetCampLeashRadius
              L10_35 = L10_35()
              L10_35 = L10_35 * 1.25
              if L4_29 > L8_33 + CURRENT_TARGET_TO_ATTACKER_SWITCH_RANGE then
                if TargetWithinWalkBounds(A0_25, L10_35) then
                  AttackTarget(A0_25)
                  SetCharVar("WillBeFrustrated", 2)
                end
              elseif not TargetWithinWalkBounds(target, L10_35) then
                AttackTarget(A0_25)
                SetCharVar("WillBeFrustrated", 2)
              end
            end
          else
            L3_28 = target
            if L3_28 ~= nil then
              L3_28 = AI_ATTACK
              if L2_27 == L3_28 then
                L3_28 = IsValidEnemy
                L4_29 = A0_25
                L3_28 = L3_28(L4_29)
                if L3_28 then
                  L3_28 = AttackTarget
                  L4_29 = A0_25
                  L3_28(L4_29)
                end
              end
            else
              L3_28 = IsValidEnemy
              L4_29 = A0_25
              L3_28 = L3_28(L4_29)
              if L3_28 then
                L3_28 = AttackTarget
                L4_29 = A0_25
                L3_28(L4_29)
              end
            end
          end
        end
      end
    end
  end
end
function TimerFrustrationSearch()
  local L0_36, L1_37, L2_38, L3_39, L4_40, L5_41, L6_42, L7_43, L8_44, L9_45, L10_46
  L0_36 = GetState
  L0_36 = L0_36()
  L1_37 = GetRoamState
  L1_37 = L1_37()
  L2_38 = GetCharVar
  L3_39 = "WillBeFrustrated"
  L2_38 = L2_38(L3_39)
  L3_39 = INACTIVE
  if L1_37 ~= L3_39 then
    L3_39 = RUN_IN_FEAR
    if L1_37 ~= L3_39 then
      L3_39 = AI_HALTED
      if L0_36 ~= L3_39 then
        L3_39 = GetCharVar
        L4_40 = "inStasis"
        L3_39 = L3_39(L4_40)
      end
    end
  elseif L3_39 > 1 then
    return
  end
  L3_39 = SetTimerDelay
  L4_40 = "TimerFrustrationSearch"
  L5_41 = DEFAULT_FRUSTRATION_SEARCH_TIME
  L3_39(L4_40, L5_41)
  L3_39 = GetLeashCounter
  L3_39 = L3_39()
  L4_40 = false
  if L2_38 >= 1 then
    L4_40 = true
    L5_41 = SetCharVar
    L6_42 = "WillBeFrustrated"
    L7_43 = 0
    L5_41(L6_42, L7_43)
  end
  L5_41 = GetTarget
  L5_41 = L5_41()
  L6_42 = GetCampLeashRadius
  L6_42 = L6_42()
  L7_43 = GetMyLeashedPos
  L7_43 = L7_43()
  L8_44 = GetCampLeashPos
  L8_44 = L8_44()
  L9_45 = GetDistToLeashedPos
  L9_45 = L9_45()
  L10_46 = L6_42 + 1
  if L5_41 ~= nil then
    L10_46 = WalkDistanceBetweenObjectCenterAndPoint(L5_41, L8_44)
  else
    FindNewTarget()
    L5_41 = GetTarget()
    if L5_41 == nil then
      L4_40 = true
    end
  end
  if L9_45 > L6_42 - LEASH_PROTECTION_BARRIER and L6_42 > L9_45 and L6_42 < L10_46 and L0_36 ~= AI_RETREAT and GetLeashCounter() < LEASH_COUNTER_THRESHOLD then
    FindNewTarget()
    L5_41 = GetTarget()
    if L5_41 ~= nil and L5_41 ~= L5_41 then
      L4_40 = true
    end
  end
  if L10_46 > L6_42 + OUTER_RANGE_BOUND and L0_36 ~= AI_RETREAT then
    L4_40 = true
  end
  if L9_45 > L6_42 + OUTER_RANGE_BOUND then
    L4_40 = true
  end
  if L4_40 == true then
    IncreaseFrustration(1)
  end
end
function TimerReturningHome()
  local L0_47, L1_48, L2_49, L3_50, L4_51
  L0_47 = GetState
  L0_47 = L0_47()
  L1_48 = GetRoamState
  L1_48 = L1_48()
  L2_49 = INACTIVE
  if L1_48 ~= L2_49 then
    L2_49 = RUN_IN_FEAR
    if L1_48 ~= L2_49 then
      L2_49 = AI_HALTED
      if L0_47 ~= L2_49 then
        L2_49 = GetCharVar
        L3_50 = "inStasis"
        L2_49 = L2_49(L3_50)
      end
    end
  elseif L2_49 > 1 then
    return
  end
  L2_49 = GetMaxHP
  L2_49 = L2_49()
  L3_50 = GetHP
  L3_50 = L3_50()
  L4_51 = GetDistToRetreat
  L4_51 = L4_51()
  SetCharVar("DistanceToHome", L4_51)
  SetGhosted(true)
  if L0_47 == AI_RETREAT and IsMovementStopped() == true and L4_51 < 25 then
    StopTimer("TimerReturningHome")
    SetLeashOrientation()
    AIScriptSpellBuffRemove(GetThis(), "JungleFrustration")
    AIScriptSpellBuffRemove(GetThis(), "JungleFrustrationReturn")
    SetLeashCounter(0)
    AIScriptSpellBuffStackingAdd(GetThis(), GetThis(), "JungleFrustrationReset", 0, 1, 25000)
    SetGhosted(false)
    SetState(AI_ATTACK)
    SetRoamState(GetOriginalState())
    SetTimerDelay("TimerFrustrationSearch", DEFAULT_FRUSTRATION_SEARCH_TIME)
  elseif L4_51 >= 25 then
    SetStateAndMoveToLeashedPos(AI_RETREAT)
  end
end
function TimerAttack()
  local L0_52, L1_53
  L0_52 = GetState
  L0_52 = L0_52()
  L1_53 = AI_HALTED
  if L0_52 == L1_53 then
    return
  end
  L1_53 = GetCharVar
  L1_53 = L1_53("inStasis")
  if L1_53 > 1 then
    return
  end
  L1_53 = GetRoamState
  L1_53 = L1_53()
  if L1_53 ~= INACTIVE then
    L1_53 = GetRoamState
    L1_53 = L1_53()
    if L1_53 ~= RUN_IN_FEAR then
      L1_53 = AI_RETREAT
    end
  elseif L0_52 == L1_53 then
    return
  end
  L1_53 = AI_ATTACK
  if L0_52 ~= L1_53 then
    L1_53 = AI_TAUNTED
  elseif L0_52 == L1_53 then
    L1_53 = StartTimer
    L1_53("TimerFrustrationSearch")
    L1_53 = GetTarget
    L1_53 = L1_53()
    if L1_53 ~= nil then
      if TargetInAttackRange() then
        TurnOnAutoAttack(L1_53)
      elseif TargetInCancelAttackRange() == false then
        TurnOffAutoAttack(STOPREASON_MOVING)
      end
      if IsMovementStopped() == true then
        AttackTarget(L1_53)
      end
    elseif L0_52 == AI_ATTACK then
      FindNewTarget()
      L1_53 = GetTarget()
    end
  end
end
function FindNewTarget()
  local L0_54, L1_55, L2_56, L3_57, L4_58
  L0_54 = GetState
  L0_54 = L0_54()
  L1_55 = AI_HALTED
  if L0_54 == L1_55 then
    return
  end
  L1_55 = GetRoamState
  L1_55 = L1_55()
  L2_56 = INACTIVE
  if L1_55 ~= L2_56 then
    L1_55 = GetRoamState
    L1_55 = L1_55()
    L2_56 = RUN_IN_FEAR
    if L1_55 ~= L2_56 then
      L1_55 = GetState
      L1_55 = L1_55()
      L2_56 = AI_RETREAT
    end
  elseif L1_55 == L2_56 then
    L1_55 = TurnOffAutoAttack
    L2_56 = STOPREASON_MOVING
    L1_55(L2_56)
    return
  end
  L1_55 = GetCampLeashRadius
  L1_55 = L1_55()
  L2_56 = GetCampLeashPos
  L2_56 = L2_56()
  L3_57 = GetTarget
  L3_57 = L3_57()
  L4_58 = nil
  if L3_57 ~= nil then
    L4_58 = FindNearestAggressor(L2_56, L3_57)
  else
    L4_58 = FindNearestAggressor(L2_56, nil)
  end
  if L4_58 ~= nil then
    AttackTarget(L4_58)
  end
end
function HaltAI()
  Event("ComponentHalt")
  StopTimer("TimerFrustrationSearch")
  StopTimer("TimerAttack")
  TurnOffAutoAttack(STOPREASON_IMMEDIATELY)
  NetSetState(AI_HALTED)
end
function StopLeashing()
  StopTimer("TimerFrustrationSearch")
  StopTimer("TimerAttack")
end
function StartLeashing()
  if GetLeashCounter() < LEASH_COUNTER_THRESHOLD then
    ResetAndStartTimer("TimerFrustrationSearch")
    StartTimer("TimerAttack")
  end
end
function TurnOffRegeneration()
  OutOfCombatRegen:Stop()
end
function TurnOnRegeneration()
  OutOfCombatRegen:Start()
end
function EnterStasis()
  SetCharVar("inStasis", 1.01)
end
function ExitStasis()
  SetCharVar("inStasis", 0)
end
