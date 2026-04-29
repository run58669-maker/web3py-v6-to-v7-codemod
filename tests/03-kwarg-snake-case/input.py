logs = w3.eth.get_logs({
    "fromBlock": 18_000_000,
    "toBlock": "latest",
    "address": addr,
})

filt = contract.events.Transfer.create_filter(fromBlock=18_000_000, toBlock="latest")
single = w3.eth.get_logs({"blockHash": "0xabc..."})
