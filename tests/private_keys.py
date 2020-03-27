


##run ganache-cli with ganache-cli --acctKeys ganache-accounts.json
## ganache-cli --acctKeys ganache-accounts.json
##this will generate ganache-accounts.json which will have addresses dict with each key as private key 
##and private_keys key which is a list of private keys

import json
from web3.auto import w3
from eth_account.messages import encode_defunct
from eth_account.datastructures import AttributeDict
from web3.main import Web3
import sys, os

filepath = os.path.dirname(os.path.abspath(__file__))


w3 = Web3()

def read_keys():
    _path = os.path.join(os.path.dirname(filepath), "ganache-accounts.json") 

    f = open(_path, "r")
    data = json.loads(f.read())
    return data["addresses"], data["private_keys"]



def to_32byte_hex(val):
    return Web3.toHex(Web3.toBytes(val).rjust(32, b'\0'))


def ec_revoverable_message(msg, private_key):
    signed_message = sign_message(msg, private_key)
    ec_recover_args = (msghash, v, r, s) = (Web3.toHex(signed_message.messageHash),
            signed_message.v,
            to_32byte_hex(signed_message.r),
            to_32byte_hex(signed_message.s),
            )
    return ec_recover_args


def sign_message(msg, private_key):
    message = encode_defunct(text=msg)
    # if not isinstance(w3, Web3):
    #     raise Exception("Must be an instance of w3")

    if len(private_key) != 64:
        raise Exception("Incoreect private key length")
    
    return w3.eth.account.sign_message(message, private_key=private_key)


def verify_message(msg, signed_message):
    if not isinstance(signed_message, AttributeDict):
        raise Exception("Signed message must be an instance of AttributeDict")
    message = encode_defunct(text="I♥SF")
    w3.eth.account.recover_message(message, signature=signed_message.signature)


if __name__ == "__main__":
    print (filepath)
    print (read_keys())