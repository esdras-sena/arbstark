#[starknet::contract]
pub mod poolMock{
    use arbstark::interfaces::IERC20::IERC20DispatcherTrait;
    use arbstark::dexs::TenkSwap::interfaces::IPool::{IPool};
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
        fn getReserves(self: @ContractState) -> (u256, u256, u64) {
            let reserve0 = IERC20Dispatcher{contract_address: self.token0.read()}.balance_of(get_contract_address());
            let reserve1 = IERC20Dispatcher{contract_address: self.token1.read()}.balance_of(get_contract_address());
            return (reserve0, reserve1, 0);
        }
        fn token0(self: @ContractState) -> ContractAddress{
            return self.token0.read();
        }
    }
}