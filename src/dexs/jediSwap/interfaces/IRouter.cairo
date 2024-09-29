use starknet::ContractAddress;
use core::array::ArrayTrait;

#[starknet::interface]
pub trait IRouter<TContractState> {
    fn get_amount_out(self: @TContractState, amountIn: u256, reserveIn: u256, reserveOut: u256) -> u256;
    fn swap_exact_tokens_for_tokens(ref self: TContractState, amountIn: u256, amountOutMin: u256, path_len: u8, path: Array<ContractAddress>, to: ContractAddress, deadline: u64);
}