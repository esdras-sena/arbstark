

pub mod EkuboMod {
  use starknet::{ContractAddress};
  use arbstark::dexs::ekubo::core::{PoolKey, i129, Delta, ILocker, ICoreDispatcher};

  use arbstark::interfaces::IDEX::{IDEX, IDEXDispatcher}; 
  use arbstark::dexs::ekubo::components::shared_locker::call_core_with_callback;

  #[storage]
  struct Storage {
      core: ICoreDispatcher,
  }

  #[derive(Copy, Drop, Serde)]
  struct SwapData {
      pool_key: PoolKey,
      amount: i129,
      token: ContractAddress,
  }
  
  #[derive(Copy, Drop, Serde)]
  struct SwapResult {
      delta: Delta,
  }

  #[abi(embed_v0)]
  impl EkuboMod of IDEX<ContractState> {
    fn swap(ref self: ContractState, swap_data: SwapData) -> SwapResult {
      // https://github.com/EkuboProtocol/abis/blob/main/src/components/shared_locker.cairo
      call_core_with_callback(
        self.core.read(), @swap_data
      )
    }

    fn getPrice(self: @ContractState, tokenIn: ContractAddress, tokenOut: ContractAddress, amount: u256) -> (u256, u256, ContractAddress){

    }
  }

  #[external(v0)]
  impl Locker of ILocker<ContractState> {
    fn locked(ref self: ContractState, id: u32, data: Array<felt252>) -> Array<felt252> {
      let core = self.core.read();

      // Consume the callback data
      // https://github.com/EkuboProtocol/abis/blob/main/src/components/shared_locker.cairo
      let swap_data: SwapData = ekubo::components::shared_locker::consume_callback_data::<CallbackParameters>(core, data);
      
      // Do your swaps here!
      let delta = core.swap(pool_key, params);
      
      // Each swap generates a "delta", but does not trigger any token transfers.
      // A negative delta indicates you are owed tokens. A positive delta indicates core owes you tokens.
      // To take a negative delta out of core, do (assuming token0 for token1):
      core.withdraw(token, recipient, delta.amount0.mag);
      // To pay tokens you owe, do (assuming payment is for token1):
      IERC20Dispatcher {
        contract_address: token
      }.approve(ekubo, delta.mag.into());
      // ICoreDispatcher#pay will trigger a token#transferFrom(this, core) for the entire approved amount
      core.pay(token);
      
      // Serialize our output type into the return data
      let swap_result = SwapResult { delta };
      let mut arr: Array<felt252> = ArrayTrait::new();
      Serde::serialize(@swap_result, ref arr);
      arr
    }
  }
}

