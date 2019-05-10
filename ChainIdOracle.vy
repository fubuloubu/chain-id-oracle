struct ActivePeriod:
    start_block: uint256
    end_block: uint256

# Chain ID => Range of accepted block numbers (inclusive)
chain_id_history: map(uint256, ActivePeriod)

# Cache of the last time the chain ID was updated
previous_update_blocknumber: uint256

@public
def updateChainId():
    """
    Anyone can call this function at any point in time after Chain ID
    is updated for the network. The time may not exactly align with the
    block number it was updated at, but should be within an hour of the
    real block number (and probably much less, perhaps 1-2 blocks)
    """
    assert self.chain_id_history[tx.chain_id].start_block == 0
    assert self.chain_id_history[tx.chain_id].end_block == 0
    self.chain_id_history[tx.chain_id] = ActivePeriod({
        start_block: self.previous_update_blocknumber,
        end_block: block.number-1
    })
    self.previous_update_blocknumber = block.number

@public
@constant
def getChainIdActivePeriod(chain_id: uint256) -> ActivePeriod:
    """
    Returns the recorded time period for which chain ID is active.
    ActivePeriod(0, 0) is considered to be "invalid" and should be
    handled accordingly by the user of this function.
    """
    return self.chain_id_history[chain_id]
