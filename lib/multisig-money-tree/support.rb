module MultisigMoneyTree
  # Module with helpers
  module Support
    # Include MoneyTree Support module for methods:
    # * from_serialized_base58 
    # * to_serialized_base58
    include MoneyTree::Support
    
    # Check public/private key format is hex
    # [Arguments]
    # * +raw_key+ String key
    # [Result]
    # Returned `true` when raw_key in hex format
    def compressed_hex_format?(raw_key)
      raw_key.length == 66 && !raw_key[/\H/]
    end
    
    # Check valid cosigner index
    # [Arguments]
    # * +index+ Integer index
    # [Result]
    # Returned `true` when index >= 0 and < MAX_COSIGNER
    def valid_cosigner_index?(index)
      !index.nil? && index.kind_of?(Integer) && index >= 0 && index < MAX_COSIGNER
    end
  end
end