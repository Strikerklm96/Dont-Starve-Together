local assets =
{
    --naming convention inconsistent
    Asset("ANIM", "anim/armor_onemanband.zip"),
    Asset("ANIM", "anim/swap_one_man_band.zip"),
}

local function band_disable(inst)
    if inst.updatetask then
        inst.updatetask:Cancel()
        inst.updatetask = nil
    end
	
	--leon mod
	if ((inst.components.inventoryitem ~= nil) and (inst.components.inventoryitem.owner ~= nil)) then
		local owner = inst.components.inventoryitem.owner
		if owner.components.leader ~= nil then
			owner.components.leader:RemoveAllFollowersOnDeath()
		end
	end
	--leon mod end
end

local function CalcDapperness(inst, owner)
    --return -TUNING.DAPPERNESS_SMALL -(owner.components.leader:CountFollowers() * TUNING.SANITYAURA_SMALL)
	--leon mod
	return -TUNING.SANITYAURA_SMALL
	--leon mod end
end

local banddt = 1
local function band_update( inst )
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    if owner and owner.components.leader then
        local x,y,z = owner.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, TUNING.ONEMANBAND_RANGE, {"pig"}, {'werepig'})
        for k,v in pairs(ents) do
            if v.components.follower and not v.components.follower.leader  and not owner.components.leader:IsFollower(v) and owner.components.leader.numfollowers < TUNING.ONEMANBAND_MAX_FOLLOWERS  then
                owner.components.leader:AddFollower(v)
                --owner.components.sanity:DoDelta(-TUNING.SANITY_MED)
            end
        end

        for k,v in pairs(owner.components.leader.followers) do
            if k:HasTag("pig") and k.components.follower then
                k.components.follower:AddLoyaltyTime(1.1)
            end
        end
    else -- This is for haunted one man band
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, TUNING.ONEMANBAND_RANGE, {"pig"}, {'werepig'})
        for k,v in pairs(ents) do
            if v.components.follower and not v.components.follower.leader  and not inst.components.leader:IsFollower(v) and inst.components.leader.numfollowers < TUNING.ONEMANBAND_MAX_FOLLOWERS then
                inst.components.leader:AddFollower(v)
                --owner.components.sanity:DoDelta(-TUNING.SANITY_MED)
            end
        end

        for k,v in pairs(inst.components.leader.followers) do
            if k:HasTag("pig") and k.components.follower then
                k.components.follower:AddLoyaltyTime(1.1)
            end
        end
    end
end

local function band_enable(inst)
    inst.updatetask = inst:DoPeriodicTask(banddt, band_update, 1)
end

local function band_perish(inst)
    band_disable(inst)
    inst:Remove()
end

local function onequip(inst, owner) 
    if owner then
        owner.AnimState:OverrideSymbol("swap_body_tall", "swap_one_man_band", "swap_body_tall")
        inst.components.fueled:StartConsuming()
    end

    band_enable(inst)
end

local function onunequip(inst, owner) 
    if owner then
        owner.AnimState:ClearOverrideSymbol("swap_body_tall") 
        inst.components.fueled:StopConsuming()
    end

    band_disable(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("band")

    inst.AnimState:SetBank("onemanband")
    inst.AnimState:SetBuild("armor_onemanband")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/wilson/onemanband"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.ONEMANBAND
    inst.components.fueled:InitializeFuelLevel(TUNING.ONEMANBAND_PERISHTIME)
    inst.components.fueled:SetDepletedFn(band_perish)

    -- inst:AddComponent("perishable")
    -- inst.components.perishable:SetPerishTime(TUNING.ONEMANBAND_PERISHTIME)
    -- inst.components.perishable:SetOnPerishFn(band_perish)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable.dapperfn = CalcDapperness

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("leader")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        onequip(inst)
        inst.hauntsfxtask = inst:DoPeriodicTask(.3, function(inst)
            inst.SoundEmitter:PlaySound(inst.foleysound)
        end)
        return true
    end)
    inst.components.hauntable:SetOnUnHauntFn(function(inst)
        onunequip(inst)
        inst.hauntsfxtask:Cancel()
        inst.hauntsfxtask = nil
    end)

    --inst:ListenForEvent("onremove", function() print("Removed OneManBand!") end)

    return inst
end

return Prefab("onemanband", fn, assets)