module nftrpg::avatar {
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::dynamic_object_field as ofield;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    use nftrpg::coin::COIN as RPG;
    use nftrpg::weapon::Weapon;

    struct Avatar has key {
        id: UID,
        name: String,
        weapon: Option<ID>,
        gold: Coin<RPG>,
    }

    /// Error when trying to wield two weapons at the same time.
    const EAlreadyWielding: u64 = 0;

    /// Error when trying to unwield while not holding a weapon.
    const ENotWielding: u64 = 1;

    /// Error when trying to unwield the wrong weapon.
    const EWrongWeapon: u64 = 2;

    public entry fun create(
        name: vector<u8>,
        gold: Coin<RPG>,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let avatar = Avatar {
            id: object::new(ctx),
            name: string::utf8(name),
            weapon: option::none(),
            gold,
        };

        transfer::transfer(avatar, recipient);
    }

    public fun name(avatar: &Avatar): &String {
        &avatar.name
    }

    public fun balance(avatar: &Avatar): u64 {
        coin::value(&avatar.gold)
    }

    public fun split_gold(
        avatar: &mut Avatar,
        amount: u64,
        ctx: &mut TxContext,
    ): Coin<RPG> {
        coin::split(&mut avatar.gold, amount, ctx)
    }

    public fun wield<W>(avatar: &mut Avatar, w: Weapon<W>) {
        assert!(option::is_none(&avatar.weapon), EAlreadyWielding);
        option::fill(&mut avatar.weapon, object::id(&w));
        ofield::add(&mut avatar.id, b"weapon", w);
    }

    public fun unwield<W>(avatar: &mut Avatar): Weapon<W> {
        assert!(option::is_some(&avatar.weapon), ENotWielding);
        assert!(ofield::exists_with_type<vector<u8>, Weapon<W>>(
            &avatar.id, b"weapon"
        ), EWrongWeapon);

        let _ = option::extract(&mut avatar.weapon);

        ofield::remove<vector<u8>, Weapon<W>>(
            &mut avatar.id, b"weapon"
        )
    }
}
