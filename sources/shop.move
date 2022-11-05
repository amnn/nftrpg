/// This module defines a `Shop` as a shared object that anyone can
/// interact with to buy and sell weapons, but that only someone with
/// the `OwnerCap` can interact with to extract money and restock
/// weapons.
///
/// The shop also uses the "Hot Potato" pattern to implement a
/// "buy-now-pay-later" scheme which allows users to purchase a weapon
/// without paying for it up-front, but with a type-system guarantee
/// that any successful transaction involving a purchase will also
/// involve a payment.
module nftrpg::shop {
    use std::vector;

    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use nftrpg::coin::COIN as RPG;
    use nftrpg::weapon::{Self, Axe, Sword, Weapon};
    
    /// The shop it self -- we create one of these on module
    /// initialization and share it.
    struct Shop has key {
        id: UID,
        earnings: Balance<RPG>,
        axes: vector<Weapon<Axe>>,
        swords: vector<Weapon<Sword>>,
    }

    /// The Owner Capability, which grants special privileges for
    /// addresses with access to it.  Because there is only one
    /// instance of `Shop` created for this module, we don't need to
    /// add any additional data to `OwnerCap` to distinguish which
    /// shop it indicated ownership of.  If this module could create
    /// multiple shops, we would need to add `shop_id: ID` as a field
    /// to `OwnerCap` and check `owner.shop_id == object::id(&shop)`
    /// before every transaction that required an `OwnerCap`.
    struct OwnerCap has key {
        id: UID,
    }

    /// This type represents the Hot Potato. It is a type without
    /// abilities, which means that once it is created, it cannot be
    /// stored on chain (no key), wrapped in another object (no
    /// store), duplicated (no copy), or go out of scope (no drop).
    ///
    /// This means that in order for a transaction that creates an
    /// `Invoice` to succeed, it also needs to pass that invoice to a
    /// function that will clean it up (by unpacking it).
    ///
    /// Modules can use this guarantee to require that if some actions
    /// take place during a transaction, that some other actions must
    /// follow, by making the first action return a hot potato, and
    /// the potential follow-up actions accept it and unpack it.
    struct Invoice {
        value: u64,
    }

    const ENoInventory: u64 = 0;
    const EWrongPrice: u64 = 1;
    const EWrongOwner: u64 = 2;

    const AXE_PRICE: u64 = 1000;
    const SWORD_PRICE: u64 = 2000;

    fun init(ctx: &mut TxContext) {
        let shop = Shop {
            id: object::new(ctx),
            earnings: balance::zero(),
            axes: vector::empty(),
            swords: vector::empty(),
        };

        transfer::transfer(
            OwnerCap { id: object::new(ctx) },
            tx_context::sender(ctx)
        );

        transfer::share_object(shop);
    }

    /** Functions for customers ***********************************************/

    public fun buy_axe(shop: &mut Shop, ctx: &TxContext): Invoice {
        assert!(!vector::is_empty(&shop.axes), ENoInventory);
        let axe = vector::pop_back(&mut shop.axes);
        transfer::transfer(axe, tx_context::sender(ctx));
        Invoice { value: AXE_PRICE }
    }

    public fun buy_sword(shop: &mut Shop, ctx: &TxContext): Invoice {
        assert!(!vector::is_empty(&shop.swords), ENoInventory);
        let sword = vector::pop_back(&mut shop.swords);
        transfer::transfer(sword, tx_context::sender(ctx));
        Invoice { value: SWORD_PRICE }
    }

    public fun pay_in_full(shop: &mut Shop, invoice: Invoice, coin: Coin<RPG>) {
        let Invoice { value } = invoice;
        assert!(coin::value(&coin) == value, EWrongPrice);
        balance::join(&mut shop.earnings, coin::into_balance(coin));
    }

    public fun trade_in_axe(shop: &mut Shop, invoice: Invoice, axe: Weapon<Axe>, coin: Coin<RPG>) {
        let Invoice { value } = invoice;
        let value = value - AXE_PRICE * 3 / 4;
        assert!(coin::value(&coin) == value, EWrongPrice);
        balance::join(&mut shop.earnings, coin::into_balance(coin));
        vector::push_back(&mut shop.axes, axe);
    }

    /** Functions for owners **************************************************/

    public entry fun add_axe(
        _: &OwnerCap,
        shop: &mut Shop,
        ctx: &mut TxContext,
    ) {
        let axe = weapon::create_axe(ctx);
        vector::push_back(&mut shop.axes, axe);
    }

    public entry fun add_sword(
        _: &OwnerCap,
        shop: &mut Shop,
        ctx: &mut TxContext,
    ) {
        let sword = weapon::create_sword(ctx);
        vector::push_back(&mut shop.swords, sword);
    }

    public entry fun take_earnings(
        _: &OwnerCap,
        shop: &mut Shop,
        ctx: &mut TxContext,
    ) {
        let value = balance::value(&shop.earnings);
        transfer::transfer(
            coin::take(&mut shop.earnings, value, ctx),
            tx_context::sender(ctx),
        );
    }
}
