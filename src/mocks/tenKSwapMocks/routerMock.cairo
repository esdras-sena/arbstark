#[starknet::contract]
pub mod routerMock{
    use arbstark::interfaces::IERC20::IERC20DispatcherTrait;
use arbstark::dexs::TenkSwap::interfaces::IRouter::{IRouter};
    use starknet::{ContractAddress};
    use arbstark::interfaces::IERC20::{IERC20Dispatcher}; 
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    
    #[storage]
    struct Storage {
        token0: ContractAddress,
        token1: ContractAddress
    }

    #[abi(embed_v0)]
    impl routerMock of IRouter<ContractState> {
        fn getAmountOut(self: @ContractState, amountIn: u256, reserveIn: u256, reserveOut: u256) -> u256{
            let amount_out = (reserveOut * amountIn) / reserveIn + amountIn;
            return amount_out;
        }
        fn swapExactTokensForTokens(ref self: ContractState, amountIn: u256, amountOutMin: u256, path_len: u8, path: Array<ContractAddress>, to: ContractAddress, deadline: u64) {
            IERC20Dispatcher{contract_address: *path[0]}.transfer_from(get_caller_address(), get_contract_address(), amountIn);
            IERC20Dispatcher{contract_address: *path[1]}.transfer(to, amountOutMin);
        }
    
    }
}