module nftrpg::shop {
    use std::vector;

    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use nftrpg::coin::COIN as RPG;
    use nftrpg::weapon::{Self, Axe, Sword, Weapon};
    
    struct Shop has key {
        id: UID,
        earnings: Balance<RPG>,
        axes: vector<Weapon<Axe>>,
        swords: vector<Weapon<Sword>>,
    }

    struct OwnerCap has key {
        id: UID,
    }

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

    // Functions for customers
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

    // Functions for owners

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
