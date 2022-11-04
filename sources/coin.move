/// An implementation of an ERC20-like Token, using Sui's built-in
/// `Coin` type.
module nftrpg::coin {
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// `COIN` is a "One-time Witness", because it is a struct whose
    /// name is the same as its module, but uppercase.  It will be
    /// created exactly once, before the module initializer is called
    /// and can be used to demonstrate that a function is being called
    /// from a particular module.
    struct COIN has drop {}

    /// This is the module initializer.  It's called once, when the
    /// module is published.  If the module contains a One-time
    /// Witness, it must be passed as the module initializer's first
    /// parameter.
    fun init(witness: COIN, ctx: &mut TxContext) {
        // `coin::create_currency` requires that its first parameter
        // is a one-time witness, which it uses as a marker type.
        // This call creates a `TreasuryCap<COIN>` which is capable of
        // minting `Coin<COIN>`'s, and the one-time witness
        // restriction ensures that this is only done from within the
        // module that defines `COIN`.
        let treasury = coin::create_currency(witness, 2, ctx);
        transfer::transfer(treasury, tx_context::sender(ctx));
    }
}
