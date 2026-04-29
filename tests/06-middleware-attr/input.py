from web3 import Web3

w3 = Web3()
w3.middlewares.add(my_mw)
w3.middlewares.remove("name")
existing = w3.middlewares.clear()

# Bare identifier `middlewares` MUST NOT be renamed (too risky).
def list_middlewares():
    return []
