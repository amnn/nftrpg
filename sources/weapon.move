module nftrpg::weapon {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Weapon<phantom W> has key, store {
        id: UID,
    }

    struct Axe {}
    struct Sword {}

    public fun create_axe(ctx: &mut TxContext): Weapon<Axe> {
        Weapon<Axe> { id: object::new(ctx) }
    }

    public fun create_sword(ctx: &mut TxContext): Weapon<Sword> {
        Weapon<Sword> { id: object::new(ctx) }
    }
}
