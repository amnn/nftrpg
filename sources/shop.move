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
    use sui::dynamic_field as field;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use nftrpg::coin::COIN as RPG;
    use nftrpg::weapon::Weapon;
    
    /// The shop it self -- we create one of these on module
    /// initialization and share it.
    struct Shop has key {
        id: UID,
        earnings: Balance<RPG>,
    }

    /// Label is the field name we will use for attaching inventories
    /// of different types of weapon on the `Shop`.  It allows us to
    /// store and access values keyed by a type (in this case `W`).
    struct Label<phantom W> has copy, drop, store {}

    struct Inventory<phantom W> has store {
        price: u64,
        items: vector<Weapon<W>>,
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
    const EUnrecognizedWeapon: u64 = 2;
    const EShopCantAfford: u64 = 3;

    fun init(ctx: &mut TxContext) {
        let shop = Shop {
            id: object::new(ctx),
            earnings: balance::zero(),
        };

        transfer::transfer(
            OwnerCap { id: object::new(ctx) },
            tx_context::sender(ctx)
        );

        transfer::share_object(shop);
    }

    /** Functions for customers ***********************************************/

    /// Buy returns two values: The weapon, and the invoice for paying
    /// for it.  Move supports returning tuples (and destructuring
    /// tuples that are returned), but does not support tuples as a
    /// first class type (It is not possile to create a value with a
    /// tuple type).
    public fun buy<W>(shop: &mut Shop): (Weapon<W>, Invoice) {
        let l = Label<W> {};
        assert!(
            field::exists_with_type<Label<W>, Inventory<W>>(&shop.id, l),
            EUnrecognizedWeapon,
        );

        let inventory = field::borrow_mut<Label<W>, Inventory<W>>(&mut shop.id, l);
        assert!(!vector::is_empty(&inventory.items), ENoInventory);

        let item = vector::pop_back(&mut inventory.items);

        (item, Invoice { value: inventory.price })
    }

    public entry fun sell<W>(shop: &mut Shop, item: Weapon<W>, ctx: &mut TxContext) {
        let l = Label<W> {};
        assert!(
            field::exists_with_type<Label<W>, Inventory<W>>(&shop.id, l),
            EUnrecognizedWeapon,
        );

        let inventory = field::borrow_mut<Label<W>, Inventory<W>>(&mut shop.id, l);
        let value = inventory.price / 2;

        assert!(balance::value(&shop.earnings) > value, EShopCantAfford);

        vector::push_back(&mut inventory.items, item);
        transfer::transfer(
            coin::take(&mut shop.earnings, value, ctx),
            tx_context::sender(ctx),
        );
    }

    public fun pay_in_full(shop: &mut Shop, invoice: Invoice, coin: Coin<RPG>) {
        let Invoice { value } = invoice;
        assert!(coin::value(&coin) == value, EWrongPrice);
        balance::join(&mut shop.earnings, coin::into_balance(coin));
    }

    public fun trade_in<W>(
        shop: &mut Shop,
        invoice: Invoice,
        item: Weapon<W>,
        coin: Coin<RPG>,
    ) {
        let Invoice { value } = invoice;
        let l = Label<W> {};

        assert!(
            field::exists_with_type<Label<W>, Inventory<W>>(&shop.id, l),
            EUnrecognizedWeapon,
        );

        let inventory = field::borrow_mut<Label<W>, Inventory<W>>(&mut shop.id, l);

        // Deduct 75% of item value from cost as benefit of trading in.
        value = value - inventory.price * 3 / 4;
        assert!(coin::value(&coin) == value, EWrongPrice);

        balance::join(&mut shop.earnings, coin::into_balance(coin));
        vector::push_back(&mut inventory.items, item);
    }

    /** Functions for owners **************************************************/

    public entry fun add_item_type<W>(_: &OwnerCap, shop: &mut Shop, price: u64) {
        field::add(&mut shop.id, Label<W> {}, Inventory<W> {
            price,
            items: vector::empty(),
        })
    }

    public entry fun add_item<W>(_: &OwnerCap, shop: &mut Shop, item: Weapon<W>) {
        let inventory = field::borrow_mut<Label<W>, Inventory<W>>(
            &mut shop.id,
            Label<W> {},
        );

        vector::push_back(&mut inventory.items, item);
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
