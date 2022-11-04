module nftrpg::coin {
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct COIN has drop {}

    fun init(witness: COIN, ctx: &mut TxContext) {
        let treasury = coin::create_currency(witness, 2, ctx);
        transfer::transfer(treasury, tx_context::sender(ctx));
    }
}
