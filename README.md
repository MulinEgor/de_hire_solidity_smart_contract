# Solidity smart contract for decentralized hiring platform 

![Solidity](https://img.shields.io/badge/Solidity-%23363636.svg?style=for-the-badge&logo=solidity&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)

## Project structure

```bash
contracts/ - folder with .sol files for smart contracts
    interfaces/ - interfaces for the contract
    core/ - acutal contracts
    lib/ - external contracts needed 
scripts/ - folder with scripts for the contract
tests/ - folder with tests
    data_types.py - data types for the tests
    test_work_contract.py - tests for the contract
    conftest.py - pytest fixtures for the tests
```

## Install dependencies

1. Install [python](https://www.python.org/downloads/)

2. Install pipx
```bash
python3 -m pip install --user pipx
python3 -m pipx ensurepath
```

3. Install brownie
```bash
pipx install eth-brownie
```

## Compile contracts

```bash
brownie compile
```

## Run test

```bash
brownie test
```

## Deploy to testnet

1. Create `.env` file based on `.env.example` and fill it with your data:
```bash
cp .env.example .env
```

2. Run deploy script
```bash
brownie run scripts/deploy_to_testnet.py
```
