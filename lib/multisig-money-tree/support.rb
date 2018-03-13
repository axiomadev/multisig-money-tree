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
  end
end