module MultisigMoneyTree
  module Support
    include MoneyTree::Support
    
    def compressed_hex_format?(raw_key)
      raw_key.length == 66 && !raw_key[/\H/]
    end
  end
end