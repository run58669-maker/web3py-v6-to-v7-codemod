from web3 import Web3

w3 = Web3()
w3.middleware.add(my_mw)
w3.middleware.remove("name")
existing = w3.middleware.clear()

# Bare identifier `middlewares` MUST NOT be renamed (too risky).
def list_middlewares():
    return []
