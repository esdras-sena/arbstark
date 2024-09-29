import os
import pytest

from starkware.starknet.testing.starknet import Starknet

ARBSTARK_FILE = os.path.join(
    os.path.dirname("../src/"), "arbstark.cairo")

ERC20_FILE = os.path.join(
    os.path.dirname("../src/mocks/"), "erc_20_mock.cairo")



@pytest.mark.asyncio
async def test_find_profitable_path():
    starknet = await Starknet.empty()

    print(starknet.default_account_address)
    print("testando essa porra")
    print("testando essa porra")
    print("testando essa porra")

    # Declare the contract.
    arbstark_declare_info = await starknet.deprecated_declare(
        source=ARBSTARK_FILE,
    )
    # Deploy the contract.
    arbstark_contract = await starknet.deploy(
        class_hash=arbstark_declare_info.class_hash,
    )

    execution_info = await arbstark_contract.getOwner().call()

    print(execution_info.result)

    # usdc_declare_info = await starknet.deprecated_declare(
    #     source=ERC20_FILE,
    # )
    # usdc_contract = await starknet.deploy(
    #     class_hash=usdc_declare_info.class_hash,
    # )

    # usdt_declare_info = await starknet.deprecated_declare(
    #     source=ERC20_FILE,
    # )
    # usdt_contract = await starknet.deploy(
    #     class_hash=usdt_declare_info.class_hash,
    # )

    # wbtc_declare_info = await starknet.deprecated_declare(
    #     source=ERC20_FILE,
    # )
    # wbtc_contract = await starknet.deploy(
    #     class_hash=wbtc_declare_info.class_hash,
    # )

    # eth_declare_info = await starknet.deprecated_declare(
    #     source=ERC20_FILE,
    # )
    # eth_contract = await starknet.deploy(
    #     class_hash=eth_declare_info.class_hash,
    # )

    # strk_declare_info = await starknet.deprecated_declare(
    #     source=ERC20_FILE,
    # )
    # strk_contract = await starknet.deploy(
    #     class_hash=strk_declare_info.class_hash,
    # )
    

    