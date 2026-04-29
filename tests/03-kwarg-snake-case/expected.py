logs = w3.eth.get_logs({
    "fromBlock": 18_000_000,
    "toBlock": "latest",
    "address": addr,
})

filt = contract.events.Transfer.create_filter(from_block=18_000_000, to_block="latest")
single = w3.eth.get_logs({"blockHash": "0xabc..."})
