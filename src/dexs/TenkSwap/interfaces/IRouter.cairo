use starknet::ContractAddress;
use core::array::ArrayTrait;

#[starknet::interface]
pub trait IRouter<TContractState> {
    fn getAmountOut(self: @TContractState, amountIn: u256, reserveIn: u256, reserveOut: u256) -> u256;
    fn swapExactTokensForTokens(ref self: TContractState, amountIn: u256, amountOutMin: u256, path_len: u8, path: Array<ContractAddress>, to: ContractAddress, deadline: u64) ;
}