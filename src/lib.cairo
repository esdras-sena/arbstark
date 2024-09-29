pub(crate) mod arbstark;
pub(crate) mod interfaces {
    pub(crate) mod IERC20;
    pub(crate) mod IDEX;
    pub(crate) mod ICanarySwap;
}

pub(crate) mod mocks {
    pub(crate) mod erc_20_mock;
    pub(crate) mod nostraMocks{
        pub(crate) mod poolMock;
        pub(crate) mod factoryMock;
    }
    pub(crate) mod jediSwapMocks{
        pub(crate) mod poolMock;
        pub(crate) mod routerMock;
        pub(crate) mod factoryMock;
    }
    pub(crate) mod tenKSwapMocks{
        pub(crate) mod poolMock;
        pub(crate) mod routerMock;
        pub(crate) mod factoryMock;
    }
}
pub(crate) mod dexs {
    // pub(crate) mod ekubo {
    //     pub(crate) mod EkuboMod;
    //     pub(crate) mod core;
    //     pub(crate) mod components{
    //         pub(crate) mod shared_locker;
    //     }
    //     pub(crate) mod types{
    //         pub(crate) mod i129;
    //     }
    // }
    pub(crate) mod nostra{
        pub(crate) mod NostraModule;
        pub(crate) mod interfaces {
            pub(crate) mod IFactory;
            pub(crate) mod IPool;
        }
    }
    pub(crate) mod jediSwap{
        pub(crate) mod JediSwapModule;
        pub(crate) mod interfaces{
            pub(crate) mod IFactory;
            pub(crate) mod IRouter;
            pub(crate) mod IPool;
        }
    }

    pub(crate) mod TenkSwap{
        pub(crate) mod TenkSwapModule;
        pub(crate) mod interfaces{
            pub(crate) mod IFactory;
            pub(crate) mod IRouter;
            pub(crate) mod IPool;
        }
    }
}

fn main() {
    println!("Hello, Wo!");
}