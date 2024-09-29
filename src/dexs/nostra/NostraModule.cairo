use starknet::{ContractAddress};

#[starknet::contract]
pub mod NostraModule{
    use arbstark::dexs::nostra::interfaces::IPool::IPoolDispatcherTrait;
    use arbstark::dexs::nostra::interfaces::IFactory::IFactoryDispatcherTrait;
    use arbstark::interfaces::IDEX::{IDEX, IDEXDispatcher}; 
    use arbstark::dexs::nostra::interfaces::IFactory::{IFactory, IFactoryDispatcher};
    use arbstark::dexs::nostra::interfaces::IPool::{IPoolDispatcher};
    use super::{ContractAddress};
    use starknet::contract_address_const;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        factory: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.factory.write(contract_address_const::<0x352e14b9bdc0138e48b55d45914b059f0388284c77a23a97776e6197852f050>());        
    }

    #[abi(embed_v0)]
    impl NostraModule of IDEX<ContractState> {
        fn swap(ref self: ContractState, pool: ContractAddress, tokenIn: ContractAddress, tokenOut: ContractAddress, amountIn: u256) -> u256{
            let token0 = IPoolDispatcher{contract_address: pool}.token_0();
            let mut firstTokenIn: bool = false;
            if(token0 != tokenOut){
                firstTokenIn = true;
            }
            let amount_out = IPoolDispatcher{contract_address: pool}.out_given_in(amountIn,firstTokenIn);

            if(firstTokenIn){
                IPoolDispatcher{contract_address: pool}.swap(0, amount_out, get_caller_address(), '0x');    
            }else {
                IPoolDispatcher{contract_address: pool}.swap(amount_out, 0, get_caller_address(), '0x');
            }

            return amount_out;
        }

        fn getPrice(self: @ContractState, tokenIn: ContractAddress, tokenOut: ContractAddress, amount: u256) -> (u256, u256, ContractAddress){
            let poolAddr = IFactoryDispatcher{contract_address: self.factory.read()}.pair(tokenIn,tokenOut);
            let token0 = IPoolDispatcher{contract_address: poolAddr}.token_0();
            let mut firstTokenIn: bool = false;
            if(token0 != tokenOut){
                firstTokenIn = true;
            }
            let price = IPoolDispatcher{contract_address: poolAddr}.out_given_in(amount, firstTokenIn);
            let fee = IPoolDispatcher{contract_address: poolAddr}.swap_fee();
            return (price, fee, poolAddr);
        }

    }
}