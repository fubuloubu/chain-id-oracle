struct ActivePeriod:
    # Data structure representing the range of blocks for which a value
    # of chain id was valid for. Bounds are inclusive.
    start_block: uint256
    end_block: uint256

# Chain ID => Range of accepted block numbers (inclusive)
chain_id_history: map(uint256, ActivePeriod)

# Cache of the last time the chain ID was updated
# NOTE: Must be initialized to 0!
previous_update_blocknumber: uint256

# Cache of last setpoint of chain ID
# NOTE: Must be initialized!
previous_chain_id: uint256


@public
def __init__():
    self.previous_chain_id = chain.id
    # NOTE: keep previous_update_blocknumber equal to 0 so the first
    #       ActivePeriod is [0, n), where n is the first time it is changed.


@public
def updateChainId():
    """
    Anyone can call this function at any point in time after Chain ID
    is updated for the network. The time may not exactly align with the
    block number it was updated at, but should be within an hour of the
    real block number (and probably much less in practice, perhaps 1-2 blocks).
    The caller gets a payout in order to incentivize this happening quickly.
    """
    assert chain.id != self.previous_chain_id
    self.chain_id_history[chain.id] = ActivePeriod({
        start_block: self.previous_update_blocknumber,
        end_block: block.number-1  # Previous period ends at block before this.
    })
    self.previous_update_blocknumber = block.number
    self.previous_chain_id = chain.id
    send(msg.sender, self.balance)  # Using honeypots for good!


@public
@constant
def getChainIdActivePeriod(_chainId: uint256) -> ActivePeriod:
    """
    Returns the recorded time period for which chain ID is active.
    ActivePeriod(0, 0) is considered to be "invalid" and reverts.
    """
    if chain.id == _chainId:
        return ActivePeriod({
            start_block: self.previous_update_blocknumber,
            end_block: block.number-1  # Valid up to the previous block
            # NOTE: Since the transaction that updates this value can be
            #       in any order on the block it's included, we use the
            #       previous block to ensure consistency in results.
        })
    period: ActivePeriod = self.chain_id_history[_chainId]
    assert period.start_block != 0 or period.end_block != 0
    return period



@public
@payable
def __default__():
    """
    If you rely on this contract as a critical piece of infrastructure,
    consider donating some gwei towards incentivizing it being updated,
    in the eventuality that a contentious fork comes to pass!
    """
    pass
