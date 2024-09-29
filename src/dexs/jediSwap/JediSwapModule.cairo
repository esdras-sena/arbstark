use starknet::{ContractAddress};


#[starknet::contract]
pub mod JediSwapModule{
    use arbstark::interfaces::IERC20::IERC20DispatcherTrait;
use arbstark::dexs::jediSwap::interfaces::IPool::IPoolDispatcherTrait;
use arbstark::dexs::jediSwap::interfaces::IRouter::IRouterDispatcherTrait;
use core::option::OptionTrait;
use core::traits::Into;
use core::traits::TryInto;
use arbstark::dexs::jediSwap::interfaces::IFactory::IFactoryDispatcherTrait;
use starknet::contract_address_const;
use starknet::get_block_timestamp;

    use arbstark::interfaces::IDEX::{IDEX, IDEXDispatcher};
    use arbstark::dexs::jediSwap::interfaces::IFactory::{IFactoryDispatcher};
    use arbstark::dexs::jediSwap::interfaces::IRouter::{IRouterDispatcher};
    use arbstark::dexs::jediSwap::interfaces::IPool::{IPoolDispatcher}; 
    use super::{ContractAddress};
    use arbstark::interfaces::IERC20::{IERC20Dispatcher};
    use core::array::ArrayTrait;
    use starknet::get_caller_address;

     #[storage]
    struct Storage {
        factory: ContractAddress,
        router: ContractAddress
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.factory.write(contract_address_const::<0>());
        self.router.write(contract_address_const::<0>());               
    }

    impl JediSwapModule of IDEX<ContractState>{
        fn swap(ref self: ContractState, pool: ContractAddress, tokenIn: ContractAddress, tokenOut: ContractAddress, amountIn: u256) -> u256{
            IERC20Dispatcher{contract_address: tokenIn}.approve(self.router.read(), amountIn);
            let deadline = get_block_timestamp();
            let token0 = IPoolDispatcher{contract_address: pool}.token0();
            let (reserve0, reserve1, _) = IPoolDispatcher{contract_address: pool}.get_reserves();
            let mut price: u256 = 0;
            if(token0.try_into().unwrap() == tokenIn){
                price = IRouterDispatcher{contract_address: self.router.read()}.get_amount_out(amountIn, reserve0, reserve1);
            } else {
                price = IRouterDispatcher{contract_address: self.router.read()}.get_amount_out(amountIn, reserve1, reserve0);
            }
            let mut path: Array<ContractAddress> = ArrayTrait::new();
            path.append(tokenIn);
            path.append(tokenOut);

            IRouterDispatcher{contract_address: self.router.read()}.swap_exact_tokens_for_tokens(amountIn, price, 2, path, get_caller_address(), deadline);

            return price;
        }

        fn getPrice(self: @ContractState, tokenIn: ContractAddress, tokenOut: ContractAddress, amount: u256) -> (u256, u256, ContractAddress){
            let poolAddr = IFactoryDispatcher{contract_address: self.factory.read()}.get_pair(tokenIn.into(),tokenOut.into());
            let (reserve0, reserve1, _) = IPoolDispatcher{contract_address: poolAddr.try_into().unwrap()}.get_reserves();
            let token0 = IPoolDispatcher{contract_address: poolAddr.try_into().unwrap()}.token0();
            let mut price: u256 = 0;
            if(token0.try_into().unwrap() == tokenIn){
                price = IRouterDispatcher{contract_address: self.router.read()}.get_amount_out(amount, reserve0, reserve1);
            } else {
                price = IRouterDispatcher{contract_address: self.router.read()}.get_amount_out(amount, reserve1, reserve0);
            }
            return (price,0, poolAddr.try_into().unwrap());
        } 

    }

}