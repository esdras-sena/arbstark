use starknet::ContractAddress;

#[starknet::interface]
pub trait IDEX<TContractState> {
    fn swap(ref self: TContractState, pool: ContractAddress, tokenIn: ContractAddress, tokenOut: ContractAddress, amountIn: u256) -> u256;

    fn getPrice(self: @TContractState, tokenIn: ContractAddress, tokenOut: ContractAddress, amount: u256) -> (u256, u256, ContractAddress); 
}