/// Create a simple Token.
module simple_token::simple_token {
    use sui::coin::{Self, TreasuryCap};
    use sui::tx_context::{sender, TxContext};
    use sui::transfer;
    use std::option;

    /// OTW and the type for the Token.
    struct SIMPLE_TOKEN has drop {}

    // Most of the magic happens in the initializer for the demonstration
    // purposes; however half of what's happening here could be implemented as
    // a single / set of PTBs.
    fun init(otw: SIMPLE_TOKEN, ctx: &mut TxContext) {
        let treasury_cap = create_currency(otw, ctx);
        transfer::public_transfer(treasury_cap, sender(ctx));
    }

    /// Internal: not necessary, but moving this call to a separate function for
    /// better visibility of the Closed Loop setup in `init`.
    fun create_currency<T: drop>(
        otw: T,
        ctx: &mut TxContext
    ): TreasuryCap<T> {
        let (treasury_cap, metadata) = coin::create_currency(
            otw, 9,
            b"ATU",
            b"ATU Token",
            b"ATU Community",
            option::none(),
            ctx
        );

        transfer::public_freeze_object(metadata);
        treasury_cap
    }

    /// Mint `amount` of `Coin` and send it to `recipient`.
    entry fun mint(
        c: &mut TreasuryCap<SIMPLE_TOKEN>, 
        amount: u64, 
        recipient: address, 
        ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(c, amount, recipient, ctx);
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        init(SIMPLE_TOKEN{}, ctx);
    }
}

#[test_only]
/// Implements tests for most common scenarios for the coin example.
module simple_token::simple_token_tests {
    use simple_token::simple_token::{SIMPLE_TOKEN, init_for_test};
    use sui::coin::{Self, TreasuryCap};
    use sui::test_scenario as ts;

    #[test]
    fun mint_transfer_update() {
        let addr1 = @0xA;
        let addr2 = @0xB;

        // init simple_token module
        let scenario = ts::begin(addr1);
        {
            init_for_test(ts::ctx(&mut scenario));
        };

        // mint
        ts::next_tx(&mut scenario, addr1);
        {
            let tc = ts::take_from_sender<TreasuryCap<SIMPLE_TOKEN>>(&scenario);
            coin::mint_and_transfer<SIMPLE_TOKEN>(&mut tc, 10000000000, addr2, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, tc);
        };

        ts::end(scenario);
    }
}
