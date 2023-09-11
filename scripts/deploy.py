from scripts.helpful_scripts import get_account, get_contract, fund_with_link
from brownie import Lottery, config, network


def deploy_lottery():
    account = get_account()
    lottery = Lottery.deploy(
        get_contract("eth_usd_price_feeed").address,
        get_contract("vrf_coordinaor").address,
        config["networks"][network.show_active()]["fee"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get(
            "verify", False),
    )


def start_lottery():
    account = get_account()
    lottery = Lottery[-1]
    tx = lottery.startLottery({"from": account})
    tx.wait(1)


def enter_lottery(account):
    lottery = Lottery[-1]
    # add some value for the sake of that maybe something goes wrong
    value = lottery.getEntranceFee()+100000000
    tx = lottery.startLottery({"from": account}, value)
    tx.wait(1)


def end_lottery():
    account = get_account()
    lottery = Lottery[-1]
    fund_with_link(lottery.address)

    tx = lottery.endLottery({"from": account})
    tx.wait(1)


def main():
    pass
