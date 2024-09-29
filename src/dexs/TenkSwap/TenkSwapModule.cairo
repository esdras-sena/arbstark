
#[starknet::contract]
pub mod TenkSwapModule{
use arbstark::dexs::TenkSwap::interfaces::IFactory::IFactoryDispatcherTrait;
use arbstark::dexs::TenkSwap::interfaces::IRouter::IRouterDispatcherTrait;
use arbstark::dexs::TenkSwap::interfaces::IPool::IPoolDispatcherTrait;
use arbstark::interfaces::IERC20::IERC20DispatcherTrait;
use starknet::contract_address_const;
    use starknet::{ContractAddress};
    use arbstark::interfaces::IDEX::{IDEX};
    use arbstark::dexs::TenkSwap::interfaces::IFactory::{IFactoryDispatcher};
    use arbstark::dexs::TenkSwap::interfaces::IRouter::{IRouterDispatcher};
    use arbstark::dexs::TenkSwap::interfaces::IPool::{IPoolDispatcher}; 
    use arbstark::interfaces::IERC20::{IERC20Dispatcher};
    use starknet::get_block_timestamp;
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

    impl TenkSwapModule of IDEX<ContractState>{
        fn swap(ref self: ContractState, pool: ContractAddress, tokenIn: ContractAddress, tokenOut: ContractAddress, amountIn: u256) -> u256{
            IERC20Dispatcher{contract_address: tokenIn}.approve(self.router.read(), amountIn);
            let deadline = get_block_timestamp();
            let token0 = IPoolDispatcher{contract_address: pool}.token0();
            let (reserve0, reserve1, _) = IPoolDispatcher{contract_address: pool}.getReserves();
            let mut price: u256 = 0;
            if(token0 == tokenIn){
                price = IRouterDispatcher{contract_address: self.router.read()}.getAmountOut(amountIn, reserve0, reserve1);
            } else {
                price = IRouterDispatcher{contract_address: self.router.read()}.getAmountOut(amountIn, reserve1, reserve0);
            }
            let mut path: Array<ContractAddress> = ArrayTrait::new();
            path.append(tokenIn);
            path.append(tokenOut);

            IRouterDispatcher{contract_address: self.router.read()}.swapExactTokensForTokens(amountIn, price, 2, path, get_caller_address(), deadline);

            return price;

        }

        fn getPrice(self: @ContractState, tokenIn: ContractAddress, tokenOut: ContractAddress, amount: u256) -> (u256, u256, ContractAddress){
            let poolAddr = IFactoryDispatcher{contract_address: self.factory.read()}.getPair(tokenIn,tokenOut);
            let (reserve0, reserve1, _) = IPoolDispatcher{contract_address: poolAddr.try_into().unwrap()}.getReserves();
            let token0 = IPoolDispatcher{contract_address: poolAddr.try_into().unwrap()}.token0();
            let mut price: u256 = 0;
            if(token0 == tokenIn){
                price = IRouterDispatcher{contract_address: self.router.read()}.getAmountOut(amount, reserve0, reserve1);
            } else {
                price = IRouterDispatcher{contract_address: self.router.read()}.getAmountOut(amount, reserve1, reserve0);
            }
            return (price,0, poolAddr);
        } 
    }
}