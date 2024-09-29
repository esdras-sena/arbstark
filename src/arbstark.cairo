
#[starknet::contract]
pub mod arbstark{
    use starknet::{ContractAddress};
    use core::array::{Array};
    use core::starknet::event::EventEmitter;
    use arbstark::interfaces::IERC20::IERC20DispatcherTrait;
    use core::array::SpanTrait;
    use core::option::OptionTrait;
    use core::clone::Clone;
    use core::serde::Serde;
    use core::traits::TryInto;
    use core::array::ArrayTrait;
    use core::traits::Into;
    use arbstark::interfaces::IDEX::IDEXDispatcherTrait;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::SyscallResultTrait;
    use arbstark::interfaces::ICanarySwap::{TriangularNode, ICanarySwap, Node};
    use arbstark::interfaces::IDEX::{IDEX, IDEXDispatcher};  
    use arbstark::interfaces::IERC20::{IERC20Dispatcher};  
    use starknet::contract_address_const;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Swap: Swap,
    }

    #[derive(Drop, starknet::Event)]
    struct Swap {
        #[key]
        account: ContractAddress,
        tokenIn: ContractAddress,
        tokenOut: ContractAddress,
        amountIn: u256,
        amountOut: u256
    }

    #[storage]
    struct Storage {
        dexLength: u32,
        dexs: LegacyMap::<u32,ContractAddress>,
        dexExists: LegacyMap::<ContractAddress, bool>,
        dexToMod: LegacyMap::<ContractAddress, ContractAddress>,
        fee: u256,
        owner: ContractAddress,
        tokens: LegacyMap::<u32,ContractAddress>,
        tokensIndex: u32
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.owner.write(get_caller_address());        
    }
    
    #[abi(embed_v0)]
    impl CanarySwap of ICanarySwap<ContractState> {
        fn getOwner(self: @ContractState) -> ContractAddress{
            return self.owner.read();
        }
        fn setOwner(ref self: ContractState, newOwner: ContractAddress){
            self.owner.write(newOwner);
        }
        fn addDex(ref self: ContractState, dexAddress: ContractAddress, dexModule: ContractAddress){
            assert!(get_caller_address() == self.owner.read(), "is not owner");
            self.dexs.write(self.dexLength.read(), dexAddress);
            self.dexExists.write(dexAddress, true);
            self.dexToMod.write(dexAddress, dexModule);
            self.dexLength.write(self.dexLength.read() + 1);
        }

        fn getFee(self: @ContractState) -> u256{
            return self.fee.read();
        }
        fn setFee(ref self: ContractState, newFee: u256) {
            self.fee.write(newFee);
        }
        fn addToken(ref self: ContractState, token: ContractAddress){
            self.tokens.write(self.tokensIndex.read(), token);
            self.tokensIndex.write(self.tokensIndex.read() + 1);
        }

        fn getTokens(self: @ContractState) -> Array<ContractAddress>{
            let mut i = 0;
            let mut tokensArray: Array<ContractAddress> = ArrayTrait::new(); 
            while i < self.tokensIndex.read() {
                tokensArray.append(self.tokens.read(i));
            };
            return tokensArray;
        }

        fn swap(ref self: ContractState, tokenIn: ContractAddress, tokenOut: ContractAddress, amount: u256, expectedOut: u256){
            IERC20Dispatcher{contract_address: tokenIn}.transfer_from(get_caller_address(), get_contract_address(), amount);
            let (sDex, sPool, _) = self.getStartPoolAndDex(tokenIn, tokenOut, amount);
            let output  = swap(ref self, sDex, sPool, tokenIn, tokenOut, amount);
            let tokens = self.getTokens();
            assert!(output >= expectedOut, "sllipage too low");

            let mut outputAmount = output;
            let arbitrageNodes = self.getArbitrageNodes(tokenOut, tokens.span(), output);
            if arbitrageNodes.len() > 0 {
                outputAmount = *arbitrageNodes.at(arbitrageNodes.len()-1).weight;
            }
            let triangularArbitrageNodes = self.getTriangularArbitrageNodes(tokenOut, tokens, outputAmount);
            if arbitrageNodes.len() > 0 || triangularArbitrageNodes.len() > 0 {
                let value = arbitrage(ref self, tokenOut, output, arbitrageNodes, triangularArbitrageNodes);
                let profit = value - output;
                let serviceFee = (profit * self.fee.read()) / 100;
                outputAmount = value - serviceFee;
                IERC20Dispatcher{contract_address: tokenOut}.transfer(get_caller_address(), outputAmount);
            } else {
                IERC20Dispatcher{contract_address: tokenOut}.transfer(get_caller_address(), output);
            }

            self.emit(Swap{account: get_caller_address(), tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amount, amountOut: outputAmount});
        }

        // the profit of a valid node should exceed the service fee of the dex
        fn getTriangularArbitrageNodes(self: @ContractState, endToken: ContractAddress, tokens: Array<ContractAddress>, amount: u256) -> Array<TriangularNode>{
            let mut tnodes: Array<TriangularNode> = ArrayTrait::new();
            let mut curAmount = amount;
            let mut _tokens = tokens.span();
            let mut d1: u32 = 0;
            while d1 < self.dexLength.read() {
                let mut d2: u32 = 0;
                while d2 < self.dexLength.read() {
                    let mut d3: u32 = 0;
                    while d3 < self.dexLength.read(){
                        let mut t1: u32 = 0;
                        while t1 < _tokens.len() {
                            if *_tokens[t1] == endToken {
                                continue;
                            }
                            let mut t2: u32 = 0;
                            while t2 < _tokens.len() {
                                if *_tokens[t2] == endToken || *_tokens[t2] == *_tokens[t1]{
                                    continue;
                                }
                                let tnode = setTriangularArbitrageWeights(self, self.dexs.read(d1), self.dexs.read(d2), self.dexs.read(d3), *_tokens[t1], *_tokens[t2], endToken, amount);
                                if tnode.weight > 0 {
                                    curAmount = tnode.weight;
                                    tnodes.append(tnode);
                                }
                                t2 += 1;
                            };

                            t1 += 1;
                        };

                        d3 += 1;
                    };
                    d2 += 1;
                };
                d1 += 1;
            };
            return tnodes;
        }

        // this function should return the DEX, pool and price
        fn getStartPoolAndDex(self: @ContractState, tokenIn: ContractAddress, tokenOut: ContractAddress, amount: u256) -> (ContractAddress, ContractAddress, u256){
            let mut pool: ContractAddress = contract_address_const::<0>();
            let mut dex: ContractAddress = contract_address_const::<0>();
            let mut bestPrice: u256 = 0;
            let mut counter: u32 = 0;

            while counter <  self.dexLength.read() {
                let mut _dex = self.dexs.read(counter);
                let (_price, _fee, _pool) = swapPrice(self, dex, tokenIn, tokenOut, amount);
                if(_price > _fee){
                    if (_price - _fee) > bestPrice {
                        pool = _pool;
                        bestPrice = _price - _fee;
                        dex = _dex;
                    }   
                }
                
            };
            return (dex,pool,bestPrice);
        }

        
        // the profit of a valid node should exceed the service fee of the dex
        fn getArbitrageNodes(self: @ContractState, endToken: ContractAddress, tokens: Span<ContractAddress>, amount: u256) -> Array<Node>{
            let mut nodes: Array<Node> = ArrayTrait::<Node>::new();
            let mut curAmount: u256 = amount;
            let mut d1: u32 = 0;
            while d1 < self.dexLength.read() {
                let mut d2: u32 = 0;
                while d2 < self.dexLength.read() {
                    let mut t1: u32 = 0;
                    while t1 < tokens.len() {
                        if *tokens[t1] == endToken {
                            t1+=1;
                            continue;
                        }
                        let n: Node = setArbitrageWeights(self, self.dexs.read(d1), self.dexs.read(d2), *tokens[t1], endToken, curAmount);                        
                        if n.weight > 0 {
                            curAmount = n.weight;
                            nodes.append(n);
                        }
                        t1+=1;
                    };

                    d2+=1;
                };
                d1+=1;
            };
            return nodes;
        }
    }

    fn swapPrice(self: @ContractState, dex: ContractAddress, token1: ContractAddress, token2: ContractAddress, amount: u256) -> (u256, u256, ContractAddress) {
        let (price, fee, pool) = IDEXDispatcher{contract_address: self.dexToMod.read(dex)}.getPrice(token1,token2, amount);
        return (price, fee, pool);
    } 

    fn swap(ref self: ContractState, dex: ContractAddress, pool: ContractAddress, tokenIn: ContractAddress, tokenOut: ContractAddress, amountIn: u256) -> u256 {
        IERC20Dispatcher{contract_address: tokenIn}.transfer(self.dexToMod.read(dex), amountIn);
        let output = IDEXDispatcher{contract_address: self.dexToMod.read(dex)}.swap(pool, tokenIn, tokenOut, amountIn);
        return output;
    } 

    fn setArbitrageWeights(self: @ContractState, dex1: ContractAddress, dex2: ContractAddress, middleToken: ContractAddress, endToken: ContractAddress, amount: u256) -> Node {
        let (buyPrice, fee1, pool1) = swapPrice(self, dex1, endToken, middleToken, amount);
        let addrZero = contract_address_const::<0>();
        if buyPrice == 0 {
            return Node{middleToken: middleToken,pool1: pool1, pool2: addrZero, dex1: dex1, dex2: dex2, weight: 0};
        }

        let (sellPrice, fee2, pool2) = swapPrice(self, dex2, middleToken, endToken, buyPrice);
        if amount >= (sellPrice - (fee1 + fee2)) {
            return Node{middleToken: middleToken,pool1: pool1, pool2: pool2, dex1: dex1, dex2: dex2, weight: 0};
        }

        return Node{middleToken: middleToken,pool1: pool1, pool2: pool2, dex1: dex1, dex2: dex2, weight: sellPrice - (fee1 + fee2)};
    }
    
    fn setTriangularArbitrageWeights(
        self: @ContractState,
        dex1: ContractAddress,
        dex2: ContractAddress,
        dex3: ContractAddress,
        token1: ContractAddress,
        token2: ContractAddress,
        endToken: ContractAddress,
        amount: u256,
    ) -> TriangularNode {
        let (buyPrice, fee1, pool1) = swapPrice(self, dex1, endToken, token1, amount);
        if buyPrice == 0 {
            return TriangularNode{middleToken1: token1, middleToken2: token2, pool1: pool1, pool2: contract_address_const::<0>(), pool3: contract_address_const::<0>(), dex1: dex1, dex2: dex2, dex3: dex3, weight: 0};
        }
        let (middlePrice, fee2, pool2) = swapPrice(self, dex2, token1, token2, buyPrice);
        if middlePrice == 0 {
            return TriangularNode{middleToken1: token1, middleToken2: token2, pool1: pool1, pool2: pool2, pool3: contract_address_const::<0>(), dex1: dex1, dex2: dex2, dex3: dex3, weight: 0};
        }
        let (sellPrice, fee3, pool3) = swapPrice(self, dex2, token2, endToken, middlePrice);
        if amount >= (sellPrice - (fee1+ fee2+ fee3)){
             return TriangularNode{middleToken1: token1, middleToken2: token2, pool1: pool1, pool2: pool2, pool3: pool3, dex1: dex1, dex2: dex2, dex3: dex3, weight: 0};
        }

        return TriangularNode{middleToken1: token1, middleToken2: token2, pool1: pool1, pool2: pool2, pool3: pool3, dex1: dex1, dex2: dex2, dex3: dex3, weight: sellPrice - (fee1+ fee2+ fee3)};        
    }


    fn arbitrage(ref self: ContractState, endToken: ContractAddress, amount: u256, arbitrageNodes: Array<Node>, triangularArbitrageNodes: Array<TriangularNode>) -> u256{
        let mut curAmount = amount;
        
        let mut a: u32 = 0;
        while a < arbitrageNodes.len() {
            let middleAmount = swap(ref self, *arbitrageNodes.at(a).dex1, *arbitrageNodes.at(a).pool1, endToken, *arbitrageNodes.at(a).middleToken, curAmount);
            curAmount = swap(ref self, *arbitrageNodes.at(a).dex2, *arbitrageNodes.at(a).pool2, *arbitrageNodes.at(a).middleToken, endToken, middleAmount);
            a+=1;
        };

        let mut ta: u32 = 0;
        let mut curTriangularAmount = curAmount;
        while ta < triangularArbitrageNodes.len() {
            let initAmount = swap(ref self, *triangularArbitrageNodes.at(ta).dex1, *triangularArbitrageNodes.at(ta).pool1, endToken, *triangularArbitrageNodes.at(ta).middleToken1, curTriangularAmount);
            let middleAmount = swap(ref self, *triangularArbitrageNodes.at(ta).dex2, *triangularArbitrageNodes.at(ta).pool2, *triangularArbitrageNodes.at(ta).middleToken1, *triangularArbitrageNodes.at(ta).middleToken2, initAmount);
            curTriangularAmount = swap(ref self, *triangularArbitrageNodes.at(ta).dex3, *triangularArbitrageNodes.at(ta).pool3, *triangularArbitrageNodes.at(ta).middleToken2, endToken, middleAmount);
            ta += 1;
        };

        return curTriangularAmount;
    }

    
}

