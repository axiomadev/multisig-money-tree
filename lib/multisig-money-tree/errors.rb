module MultisigMoneyTree
  # Class for handling class
  class Error
      # Raised when invalid params for seed multisig master node
    class SeedParamsError < StandardError; end
    # Raised when invalid params for generate multisig address or redeem_script
    class InvalidParams < StandardError; end
    # Raised when given undefined key format to BIP45 Node
    class KeyFormatNotFound < StandardError; end
    # Raised when trying to set an unknown network
    class NetworkNotFound < StandardError; end
    # Raised when initialize a master node with an incorrect key
    class ImportError < StandardError; end
    # Raised when initialize a master node with a key with an incorrect checksum
    class ChecksumError < EncodingError; end
  end
end