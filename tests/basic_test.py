

import pytest
import random
from brownie import Recover, accounts
from private_keys import ec_revoverable_message, read_keys



@pytest.fixture(scope="module", autouse=True)
def s_contract():
    return accounts[0].deploy(Recover)


@pytest.fixture(scope="module", autouse=True)
def private_keys():
    _addresses, _private_keys = read_keys() 
    return _private_keys





def test_signed_messages(s_contract, private_keys):
    """
    Sign message and check its validity 
    """
    msg_hash, v, r, s = ec_revoverable_message("test_message", private_keys[accounts[1].address.capitalize()] )
    assert accounts[1] == s_contract.ecr(msg_hash,v, r, s)

