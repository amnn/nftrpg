// Copyright (c) 2022 Ashok Menon

module nftrpg::demo {
    use sui::tx_context::TxContext;

    use nftrpg::avatar::{Self, Avatar};
    use nftrpg::shop::{Self, Shop};

    public entry fun buy<W>(
        avatar: &mut Avatar,
        value: u64,
        shop: &mut Shop,
        ctx: &mut TxContext,
    ) {
        let (weapon, invoice) = shop::buy<W>(shop);

        let coin = avatar::split_gold(avatar, value, ctx);
        shop::pay_in_full(shop, invoice, coin);
        avatar::wield(avatar, weapon);
    }

    public entry fun sell<W>(
        avatar: &mut Avatar,
        shop: &mut Shop,
        ctx: &mut TxContext,
    ) {
        let weapon = avatar::unwield<W>(avatar);
        shop::sell(shop, weapon, ctx);
    }

    public entry fun trade<W, U>(
        avatar: &mut Avatar,
        value: u64,
        shop: &mut Shop,
        ctx: &mut TxContext,
    ) {
        let old_weapon = avatar::unwield<W>(avatar);
        let (new_weapon, invoice) = shop::buy<U>(shop);

        let coin = avatar::split_gold(avatar, value, ctx);
        shop::trade_in<W>(shop, invoice, old_weapon, coin);

        avatar::wield(avatar, new_weapon);
    }

    public entry fun rent<W>(
        avatar: &mut Avatar,
        value: u64,
        shop: &mut Shop,
        ctx: &mut TxContext,
    ) {
        let (weapon, invoice) = shop::buy<W>(shop);

        avatar::wield(avatar, weapon);
        avatar::swing_weapon<W>(avatar);

        let weapon = avatar::unwield<W>(avatar);
        let coin = avatar::split_gold(avatar, value, ctx);
        shop::trade_in(shop, invoice, weapon, coin);
    }
}
