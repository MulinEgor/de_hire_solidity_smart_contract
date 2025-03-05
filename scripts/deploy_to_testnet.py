"""This script is used to deploy the contract to the testnet"""

from brownie import DecentralizedHireHubContract, accounts, config, web3


def get_account():
    """Get the account from the config private key"""
    return accounts.add(config["wallets"]["from_key"])


def can_deploy(account) -> bool:
    """
    Check if the account has enough funds to deploy the contract

    Args:
        account: The account to check

    Returns:
        True if the account has enough funds, False otherwise
    """

    balance = account.balance()
    print(f"Account balance: {balance} wei ({balance / 1e18} ETH)")

    network = config["networks"]["sepolia"]
    estimated_cost = config["networks"][network]["gas_limit"] * (
        web3.eth.gas_price / 2.25
    )

    print(
        f"Estimated deployment cost: {estimated_cost} wei ({estimated_cost / 1e18} ETH)"
    )
    print(
        f"Remaining after deployment: {balance - estimated_cost} wei ({(balance - estimated_cost) / 1e18} ETH)"
    )

    if balance < estimated_cost:
        print(f"WARNING: Insufficient funds! Need at least {estimated_cost / 1e18} ETH")
        return False

    return True


def deploy_to_testnet():
    """Deploy the contract to the testnet"""
    account = get_account()
    print(f"Deploying from account: {account}")

    if not can_deploy(account):
        print("Aborting deployment due to insufficient funds")
        return

    print("Deploying to testnet...")

    network = config["networks"]["sepolia"]
    contract = DecentralizedHireHubContract.deploy(
        {
            "from": account,
            "gas_limit": config["networks"][network]["gas_limit"],
            "gas_price": (web3.eth.gas_price / 2.25),
        },
        publish_source=config["networks"][network]["verify"],
    )
    print(f"Contract deployed to: {contract.address}")


def main():
    deploy_to_testnet()
