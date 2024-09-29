use starknet::{ContractAddress};

#[derive(copy, Drop, Serde)]
pub struct TriangularNode {
    pub middleToken1: ContractAddress,
    pub middleToken2: ContractAddress,
    pub pool1: ContractAddress,
    pub pool2: ContractAddress,
    pub pool3: ContractAddress,
    pub dex1: ContractAddress,
    pub dex2: ContractAddress,
    pub dex3: ContractAddress,
    pub weight: u256,
}

#[derive(copy, Drop, Serde)]
pub struct Node{
    pub middleToken: ContractAddress,
    pub pool1: ContractAddress,
    pub pool2: ContractAddress,
    pub dex1: ContractAddress,
    pub dex2: ContractAddress,
    pub weight: u256
}


#[starknet::interface]
pub trait ICanarySwap<TContractState> {
    fn getOwner(self: @TContractState) -> ContractAddress;
    fn setOwner(ref self: TContractState, newOwner: ContractAddress);
    fn addDex(ref self: TContractState, dexAddress: ContractAddress, dexModule: ContractAddress);
    fn swap(ref self: TContractState, tokenIn: ContractAddress, tokenOut: ContractAddress, amount: u256, expectedOut: u256);  
    fn getTriangularArbitrageNodes(self: @TContractState, endToken: ContractAddress, tokens: Array<ContractAddress>, amount: u256) -> Array<TriangularNode>;
    fn getFee(self: @TContractState) -> u256;
    fn setFee(ref self: TContractState, newFee: u256);
    fn addToken(ref self: TContractState, token: ContractAddress);
    fn getTokens(self: @TContractState) -> Array<ContractAddress>;
    // this function should return the DEX, pool and price
    fn getStartPoolAndDex(self: @TContractState, tokenIn: ContractAddress, tokenOut: ContractAddress, amount: u256) -> (ContractAddress, ContractAddress, u256);
    fn getArbitrageNodes(self: @TContractState, endToken: ContractAddress, tokens: Span<ContractAddress>, amount: u256) -> Array<Node>;
}