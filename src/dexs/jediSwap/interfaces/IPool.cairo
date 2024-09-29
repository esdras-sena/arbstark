use starknet::ContractAddress;

#[starknet::interface]
pub trait IPool<TContractState> {
    fn get_reserves(self: @TContractState) -> (u256, u256, felt252);
    fn token0(self: @TContractState) -> ContractAddress;
}