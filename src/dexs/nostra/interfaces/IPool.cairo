use starknet::ContractAddress;

#[starknet::interface]
pub trait IPool<TContractState> {
    fn swap_fee(self: @TContractState) -> u256;
    fn out_given_in(self: @TContractState, amount_in: u256, first_token_in: bool) -> u256;
    fn swap(ref self: TContractState, amount_0_out: u256, amount_1_out: u256, to: ContractAddress, data: felt252);
    fn token_0(self: @TContractState) -> ContractAddress;
}