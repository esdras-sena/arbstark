#[starknet::contract]
pub mod factoryMock{
    use arbstark::dexs::nostra::interfaces::IFactory::{IFactory};
    use starknet::{ContractAddress};
    

    #[storage]
    struct Storage {
        pair: LegacyMap::<(ContractAddress,ContractAddress), ContractAddress>,
    }

    #[abi(embed_v0)]
    impl factoryMock of IFactory<ContractState> {
        fn pair(self: @ContractState, token_0: ContractAddress, token_1: ContractAddress) -> ContractAddress{
            self.pair.read((token_0, token_1))
        }
        fn setPair(ref self: ContractState, token0: ContractAddress, token1: ContractAddress, pool: ContractAddress){
            self.pair.write((token0,token1), pool);
            self.pair.write((token1,token0), pool);
        }
    }
}