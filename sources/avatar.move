// Copyright (c) 2022 Ashok Menon

module nftrpg::avatar {
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::dynamic_object_field as ofield;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    use nftrpg::coin::COIN as RPG;
    use nftrpg::weapon::Weapon;

    /// Avatar is an object, because it has the `key` ability, and its
    /// first field is `id: UID` (both properties are required -- a
    /// struct with `key` and no `id` will fail to verify).
    struct Avatar has key {
        id: UID,
        name: String,
        weapon: Option<ID>,
        gold: Coin<RPG>,
    }

    /// Event to signal avatar has swung their weapon.
    struct WeaponSwingEvent has copy, drop {
        weapon_id: ID,
    }

    /// It's common practice to record the error codes that functions
    /// in this module could abort with near the top, as `const`ants.

    /// Error when trying to wield two weapons at the same time.
    const EAlreadyWielding: u64 = 0;

    /// Error when trying to unwield while not holding a weapon.
    const ENotWielding: u64 = 1;

    /// Error when trying to unwield the wrong weapon.
    const EWrongWeapon: u64 = 2;

    /// Entry functions can be called by transactions, this one
    /// creates a new `Avatar`
    public entry fun create(
        // Move does not have a native string type.  So they need to
        // be passed in using the `vector<u8>` (byte string) type.
        name: vector<u8>,
        gold: Coin<RPG>,
        recipient: address,
        // `entry` functions can optionally accept a `&mut TxContext`
        // as the last parameter.  It is supplied automatically when
        // making the transaction (i.e. the caller doesn't need to
        // supply a value for it like for other arguments), and it can
        // be used for learning about the sender (i.e. their address),
        // or allocating new objects.
        ctx: &mut TxContext,
    ) {
        let avatar = Avatar {
            id: object::new(ctx),
            // This function makes sure that the name that was passed
            // in is valid UTF-8 and aborts if not.
            name: string::utf8(name),
            weapon: option::none(),
            gold,
        };

        // Entry functions cannot return values, so a common pattern
        // is for them to transfer the objects they create.  This
        // function accepts an address to send it to.  It is also
        // common for the function to return to sender, whose address
        // can be found at `tx_context::sender(&ctx)`.
        transfer::transfer(avatar, recipient);
    }

    /// Accessor functions are important because in Move, all a
    /// struct's fields are private to the module that created them.

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

    public fun swing_weapon<W>(avatar: &Avatar) {
        assert!(option::is_some(&avatar.weapon), ENotWielding);

        // Events can be emitted during a move transaction and then
        // read by external tools.  There is no way to inspect the
        // events emitted from within Move.
        event::emit(WeaponSwingEvent {
            weapon_id: *option::borrow(&avatar.weapon),
        });
    }

    public fun wield<W>(avatar: &mut Avatar, w: Weapon<W>) {
        assert!(option::is_none(&avatar.weapon), EAlreadyWielding);
        option::fill(&mut avatar.weapon, object::id(&w));

        // `ofield` is an alias for `sui::dynamic_object_field` which
        // is being used to add a dynamic field to `avatar` with name
        // `b"weapon"` and value of `w` (the weapon).
        //
        // Even though Move does not have native strings, it has byte
        // string literals, which are written using a quoted string,
        // prefixed with `b`.  This evaluates to a `vector<u8>`.
        ofield::add(&mut avatar.id, b"weapon", w);
    }

    public fun unwield<W>(avatar: &mut Avatar): Weapon<W> {
        assert!(option::is_some(&avatar.weapon), ENotWielding);
        assert!(ofield::exists_with_type<vector<u8>, Weapon<W>>(
            &avatar.id, b"weapon",
        ), EWrongWeapon);

        let _ = option::extract(&mut avatar.weapon);

        ofield::remove<vector<u8>, Weapon<W>>(
            &mut avatar.id, b"weapon"
        )
    }
}
