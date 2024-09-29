#[starknet::contract]
pub mod poolMock{
    use arbstark::interfaces::IERC20::IERC20DispatcherTrait;
    use arbstark::dexs::nostra::interfaces::IPool::{IPool};
    use starknet::{ContractAddress};
    use arbstark::interfaces::IERC20::{IERC20Dispatcher,IERC20};
    use starknet::contract_address_const;
    use starknet::get_contract_address;
    

    #[storage]
    struct Storage {
        token0: ContractAddress,
        token1: ContractAddress
    }

    #[abi(embed_v0)]
    impl poolMock of IPool<ContractState> {
        fn swap_fee(self: @ContractState) -> u256{
            return 0;
        }

        fn out_given_in(self: @ContractState, amount_in: u256, first_token_in: bool) -> u256{
            let mut token_in: ContractAddress = contract_address_const::<0>();
            let mut token_out: ContractAddress = contract_address_const::<0>();
            if(first_token_in) {
                token_in = self.token0.read();
                token_out = self.token1.read();
            } else {
                token_in = self.token1.read();
                token_out = self.token0.read();
            }

            let amm_from_balance = IERC20Dispatcher{contract_address: token_in}.balance_of(get_contract_address());
            let amm_to_balance = IERC20Dispatcher{contract_address: token_out}.balance_of(get_contract_address());
            let amount_out = (amm_to_balance * amount_in) / amm_from_balance + amount_in;
            return amount_out;
        }
        fn swap(ref self: ContractState, amount_0_out: u256, amount_1_out: u256, to: ContractAddress, data: felt252){
            let mut token_out = contract_address_const::<0>();
            let mut amount_out = 0;
            if(amount_0_out == 0){
                token_out = self.token1.read();
                amount_out = amount_1_out
            } else {
                token_out = self.token0.read();
                amount_out = amount_0_out
            }

            IERC20Dispatcher{contract_address: token_out}.transfer(to, amount_out);
        }
        fn token_0(self: @ContractState) -> ContractAddress{
            return self.token0.read();
        }
    }

    fn get_reverse_token(self: @ContractState, token: ContractAddress) -> ContractAddress{
        if(token == self.token0.read()){
            return self.token1.read();
        } else {
            return self.token0.read();
        }
    }
}