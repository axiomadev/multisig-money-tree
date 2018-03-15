module MultisigMoneyTree
  class Node   
    include Support
    extend Support
    
    # Cosigner index
    attr_reader :cosigner_index
    # Cosigner master key
    attr_reader :cosigner_master_key
    # Instace of MultisigTree::Node
    attr_reader :node
    
    attr_reader :change, :index

    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set "@#{k}", v }
    end
    
    def method_missing(m, *args, &block)
      @node.send(m, *args, &block)
    end
  end
  
  class BIP45Node < Node
    attr_reader :public_keys, :public_keys_hex, :required_signs, :address, :redeem_script, :network
    
    # Create new +BIP45+ Node for create multisig address
    #
    # ==== Arguments
    # * +public_keys+ Array list of String cosigner public keys (Allowed formats: hex, base64, compressed wif, uncompressed wif)
    # * +required_signs+ Integer number required signatures for send transaction
    # * +network+ Symbol (optional, default: :bitcoin) network name
    # ==== Result
    # Returned instace of MultisigMoneyTree::BIP45Node class for generate multisig address
    # ==== Example
    #     pubkeys = [
    #       "EQQ8FQmCSfWEiubFDTckPcymLxKtcm3GhiNScG1pNgRaSX2MCtmAbqqTQ5tSbnXe4TgzZU2jCWtofvLWeTX4xmicZkAYrnk1HgdR1VAAygVbPsYH",
    #       "EQQ8FQmUgqnpuTgfmDnubeauWjaYm7XfhchhyB6fEmLPSFrHxafrSQt3Nv1pgS867VZoLhmmBsJ16KVDSwDYNGB3yJN2BdNBTLsi9ftMha7UfHpw"
    #     ]
    #     multisig_node = MultisigMoneyTree::BIP45Node.new({
    #         public_keys: pubkeys,
    #         required_signs: 2,
    #         network: :thebestcoin_testnet
    #     })
    # Return MultisigMoneyTree::BIP45Node object, for work with BIP45 node
    # ==== Example
    #     address = multisig_node.to_address => c9Wor4AzzTjghWyKyVEthmVNwZgiLFHtpD
    #     redeem_script = multisig_node.redeem_script => 522102765241cb25766f0de3d275efe0305c11a55cb11771034182dacc9b184ad8c91c210363bb6e4e25271bd18fa9392aebcfd6b1faf132fd26fc21b79cf2f340dcb6c96552ae
    #     pubkey = multisig_node.to_bip45 => oVyvtw3qzSwskwn9txvNnYKH7Nn36GfjUGH5GL6q8YCJtPfh5CF1gYHY8b39dQnFBdLfboAEXnk2e3fSPjzDMUVkFCGaeyexzbPVaYJxghzgNSxJ7q2K9xns7FzU4JSpA1qyths2TH2x4cJMmAQd6XwZUe2SMq5yTjgcRJRb4FnZMtNHH1xtsuJ9hGcc8QvkE1pBaJahWHDkYQJKBuBNL9PB1
    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set "@#{k}", v }
      
      parse_public_keys
      check_bip45_opts
    end
    
    # Generate multisig address
    #
    # ==== Result
    # Returned String multisig address
    def to_address(network: @network)
      @network = network
      
      check_bip45_opts
      
      @address, @redeem_script = Bitcoin.pubkeys_to_p2sh_multisig_address(@required_signs, *@public_keys_hex)
        
      @address
    end
    
    # Generate multisig redeem script
    #
    # ==== Result
    # Returned String multisig redeem script
    def redeem_script(network: @network)
      @network = network
      
      check_bip45_opts
      
      @redeem_script ||= Bitcoin::Script.to_p2sh_multisig_script(@required_signs, *@public_keys_hex).last
    end
    
    # Get network BIP45 node
    # ==== Result
    # Returned Symbol network name
    def network
      @network ||= :bitcoin
    end
    
    # Set network BIP45 node
    # ==== Arguments
    # * +network+ Symbol network name
    def network=(network)
      @network = network.to_sym
    end
    
    # Get number required signs
    # ==== Result
    # Returned Integer number required signs
    def required_signs
      @required_signs
    end
    
    # Get list public keys
    # ==== Result
    # Returned Array public keys
    def public_keys
      @public_keys
    end

    # Generate BIP45 public key
    #
    # ==== Arguments
    # * +network+ Symbol network name
    # ==== Result
    # Returned String base58 BIP45 Public key
    def to_bip45(network: @network)
      @network = network

      check_bip45_opts

      to_serialized_base58(to_serialized_hex)
    end

    private
    
    # Generate serialized hex public key
    # Public keys stored to pubkey in hex format
    def to_serialized_hex
      opts = [network.to_s, @required_signs.to_s]
      @public_keys.each do |key|
        opts << key.to_hex
      end
      opts.join(';').unpack('H*').first
    end
    
    # Parse string raw key to PublicKey object
    def parse_public_keys
      @public_keys.map! do |raw_key|
        begin
          MoneyTree::PublicKey.new(raw_key, network: network)
        rescue MoneyTree::Key::KeyFormatNotFound
          raise Error::KeyFormatNotFound, "Undefined key format for #{raw_key}"
        end
      end
    end
    
    def check_bip45_opts
      # Set current network to ruby-bitcoin gem
      MultisigMoneyTree.network = network
      
      # Convert keys to compressed_hex format for bitcoin-ruby
      @public_keys_hex = @public_keys.map { |key| key.to_hex }
      
      # https://github.com/bitcoin/bips/blob/master/bip-0045.mediawiki#cosigner-index
      # Quote: The indices can be determined independently by lexicographically sorting the purpose public keys of each cosigner
      @public_keys_hex.sort! { |a,b| a <=> b}

      # https://github.com/bitcoin/bips/blob/master/bip-0045.mediawiki#address-gap-limit
      # Quote: Address gap limit is currently set to 20. 
      #        Wallet software should warn when user is trying to exceed the gap limit on an external chain by generating a new address. 
      raise Error::InvalidParams, "Address gap limit" unless [@required_signs, @public_keys_hex.size].all?{|i| (0..20).include?(i) }
      raise Error::InvalidParams, "Invalid m-of-n number" if @public_keys_hex.size < @required_signs
    end
  end
end