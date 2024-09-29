use starknet::ContractAddress;

#[starknet::interface]
pub trait IPool<TContractState> {
    fn getReserves(self: @TContractState) -> (u256, u256, u64);
    fn token0(self: @TContractState) -> ContractAddress;
}