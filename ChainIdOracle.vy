struct ActivePeriod:
    start_block: uint256
    end_block: uint256

# Chain ID => Range of accepted block numbers (inclusive)
chain_id_history: map(uint256, ActivePeriod)

# Cache of the last time the chain ID was updated
previous_update_blocknumber: uint256


@public
def __init__():
    self.previous_chain_id = tx.chain_id
    # Note: keep previous_update_blocknumber equal to 0

@public
def updateChainId():
    """
    Anyone can call this function at any point in time after Chain ID
    is updated for the network. The time may not exactly align with the
    block number it was updated at, but should be within an hour of the
    real block number (and probably much less, perhaps 1-2 blocks)
    """
    assert tx.chain_id != self.previous_chain_id
    self.chain_id_history[tx.chain_id] = ActivePeriod({
        start_block: self.previous_update_blocknumber,
        end_block: block.number-1
    })
    self.previous_update_blocknumber = block.number
    self.previous_chain_id = tx.chain_id

@public
@constant
def getChainIdActivePeriod(chain_id: uint256) -> ActivePeriod:
    """
    Returns the recorded time period for which chain ID is active.
    ActivePeriod(0, 0) is considered to be "invalid" and should be
    handled accordingly by the user of this function.
    """
    if tx.chain_id == chain_id:
        return ActivePeriod({
            start_block: self.previous_update_blocknumber,
            end_block: block.number-1
        })
    return self.chain_id_history[chain_id]
