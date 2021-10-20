import requests
from web3 import Web3
import pandas
from time import time

# print("Using Unix TimeSamp:", int(time()))
CURRENT_TIME = int(time())

def integrate(times):
    """
    Returns the seconds of staked times for an array of alternating deposit
    and withdrawal times for a token.
    """
    if len(times) == 1:
        return CURRENT_TIME - times[0]
    elif len(times)%2 == 0:
        s = 0
        for i in range(0, len(times), 2):
            s += times[i+1] - times[i]
        return s
    else:
        times2 = [times.pop()]
        return integrate(times)+integrate(times2)

# DTSPool contract address 
CONTRACT_ADDR = "0x4f65ADeF0860390aB257F4A3e4eea147F892410a"

# Probably shouldn't share this but who's gonna read this anyways lmao
INFURA_ID = "313074df26854ed9899239ba251ebc7c"
ETHERSCAN_TOKEN = "HMBARPASP3BPP7DS7VJIWC79FT47I4IDP9"

url_abi = f"https://api.etherscan.io/api?module=contract&action=getabi&address={CONTRACT_ADDR}&apikey={ETHERSCAN_TOKEN}"

w3 = Web3(Web3.HTTPProvider(f"https://mainnet.infura.io/v3/{INFURA_ID}"))
response = requests.get(url_abi)
print("Got contract ABI")
# Application binary interface
ABI = response.json()

checkAddr = Web3.toChecksumAddress(CONTRACT_ADDR)

contract = w3.eth.contract(checkAddr, abi=ABI["result"])

url_txns = f"https://api.etherscan.io/api?module=account&action=txlist&address={CONTRACT_ADDR}&apikey={ETHERSCAN_TOKEN}"
response = requests.get(url_txns)
print("Got all contract transactions")
# print(response.status_code)

# List of all transactions that involve DTSPool
data = response.json()

token_events = {k: [] for k in range(10000)}

# {addr: {123: [.., ...], 456: [...]}}
addr_token_events = {}

# len(data["result"])
for i in range(1, len(data["result"])):
    function_input = contract.decode_function_input(data["result"][i]["input"])
    timeStamp = data["result"][i]["timeStamp"]
    addr = data["result"][i]["from"]
    event = str(function_input[0]) # function
    # print(event)
    if "MultipleNFT" in event:
        # print(d[1]["tokenIDList"])
        for token in function_input[1]["tokenIDList"]:
            token_events[token].append(timeStamp)
            if not addr_token_events.get(addr):
                addr_token_events.update({addr: {}})
            # This is so not computationally efficient but ask me if I care
            addr_token_events[addr].update({token: token_events[token]})
    else:
        # print(d[1]["tokenID"])
        token_events[function_input[1]["tokenID"]].append(timeStamp)
        if not addr_token_events.get(addr):
            addr_token_events.update({addr: {}})
        addr_token_events[addr].update({token: token_events[function_input[1]["tokenID"]]})

integrated_times = {k: 0 for k in addr_token_events}

for addr, v in addr_token_events.items():
    # print(addr, v)
    for times in v.values():
        times = [int(t) for t in times]
        # print(times)
        # For every token calculate total staked times and add to that address
        integrated_times[addr] += integrate(times)
# print(integrated_times)

# fml if I can remember in the future how does this work
# https://stackoverflow.com/questions/613183/how-do-i-sort-a-dictionary-by-value
sorted_integrated_times = {k: v for k, v in sorted(integrated_times.items(), key=lambda item: item[1], reverse=True) if v != 0}


df = pandas.DataFrame.from_dict(sorted_integrated_times, orient='index')

print("Writing to StakedTimes.md")
with open("StakedTimes.md", "w") as currently_staked:
    currently_staked.write(df.to_markdown())

# Get currently staked tokens
# Number of events (deposit, withdraw, deposit...)
#  should be either 1, 3, 5... so odd
def currently_staked(events):
    # token: times
    tokens = []
    for token in events:
        if len(events[token]) % 2 == 1:
            tokens.append(token)
    return len(tokens)

addr_tokens = {addr: currently_staked(events) for addr, events in addr_token_events.items()}
addr_tokens_sorted = {k: v for k, v in sorted(addr_tokens.items(), key=lambda item: item[1], reverse=True)}
# print(addr_tokens)
df2 = pandas.DataFrame.from_dict(addr_tokens_sorted, orient='index')
with open("StakedTokens.md", "w") as f:
    f.write(df2.to_markdown())
print("Brrrrrrrrrrr done!")
