// Copyright (c) 2022 Ashok Menon

module nftrpg::weapon {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    /// Phantom types are generic type parameters to structs that
    /// don't show up anywhere in the struct layout.  We use it here
    /// to have a generic object type that we can specialize to
    /// different weapons.
    struct Weapon<phantom W> has key, store {
        id: UID,
    }

    /// These are the marker classes to distinguish between different
    /// kinds of `Weapon`.  This is similar to how `sui::coin::Coin`
    /// works with its token marker types.
    struct Axe {}
    struct Sword {}
    struct Bow {}

    public fun create_axe(ctx: &mut TxContext): Weapon<Axe> {
        Weapon<Axe> { id: object::new(ctx) }
    }

    public fun create_sword(ctx: &mut TxContext): Weapon<Sword> {
        Weapon<Sword> { id: object::new(ctx) }
    }

    public fun create_bow(ctx: &mut TxContext): Weapon<Bow> {
        Weapon<Bow> { id: object::new(ctx) }
    }
}
