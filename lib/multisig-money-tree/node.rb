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
    attr_reader :public_keys, :required_signs, :address, :redeem_script, :network
    
    # Create new +BIP45+ Node for create multisig address
    #
    # ==== Arguments
    # * +public_keys+ Array list of cosigner public keys in hex format
    # * +required_signs+ Integer number required signatures for send transaction
    # * +network+ Symbol (optional, default: :bitcoin) network name
    # ==== Result
    # Returned instace of MultisigMoneyTree::BIP45Node class for generate multisig address
    # ==== Example
    #     pubkeys = [
    #       "02cfeb6fd2ce1c559e3e30fb834c987e0ff0f637aa4330439ad573e6f0d063f2c7",
    #       "02ed22c86f89cb3377855e6abbe095ad2399b099af192a613f7e2735264d190003"
    #     ]
    #     multisig_node = MultisigMoneyTree::BIP45Node.new({
    #         public_keys: pubkeys,
    #         required_signs: 2,
    #         network: :thebestcoin
    #     })
    # Return MultisigMoneyTree::BIP45Node object, for work with BIP45 node
    # ==== Example
    #     address = multisig_node.to_address => c7s4h9NdxeTbKW2o9zao3ZSVbSFFEfhcAP
    #     redeem_script = multisig_node.redeem_script => 522102cfeb6fd2ce1c559e3e30fb834c987e0ff0f637aa4330439ad573e6f0d063f2c72102ed22c86f89cb3377855e6abbe095ad2399b099af192a613f7e2735264d19000352ae
    #     pubkey = multisig_node.to_bip45 => oVyvtw3qzSwskwn9txvNnYKH7Nn36GfjV29NH8FYJEH5Zx2JUiTWNpENTc7RzUjydmnvZwtAmmwj8VnL9Sn6NHtGq3AioNbWTXA9B7eBWu5nWDtYkQ3CigiyfqAHGSujHm9RGBm3u3tS4uFsDf6bHZ5wUJSFriVvRfdrStypxWgV63BcMv4uJtMRE4CvxpaWmm37AshqBHGAx8mVpPd4sG8qj
    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set "@#{k}", v }
    end
    
    # Generate multisig address
    #
    # ==== Result
    # Returned String multisig address
    def to_address
      check_bip45_opts
      
      @address, @redeem_script = Bitcoin.pubkeys_to_p2sh_multisig_address(@required_signs, *@public_keys)
        
      @address
    end
    
    # Generate multisig redeem script
    #
    # ==== Result
    # Returned String multisig redeem script
    def redeem_script
      check_bip45_opts
      
      @redeem_script ||= Bitcoin::Script.to_p2sh_multisig_script(@required_signs, *@public_keys).last
    end
    
    # Get network BIP45 node
    # ==== Result
    # Returned Symbol network name
    def network
      @network ||= :bitcoin
    end

    # Generate BIP45 public key
    #
    # ==== Arguments
    # * +network+ Symbol network name
    # ==== Result
    # Returned String base58 BIP45 Public key
    def to_bip45(network: :bitcoin)
      @network = network

      check_bip45_opts

      to_serialized_base58(to_serialized_hex)
    end

    private
    
    # Generate serialized hex public key
    def to_serialized_hex
      opts = [network.to_s, @required_signs.to_s]
      @public_keys.each do |key|
        opts << key
      end
      opts.join(';').unpack('H*').first
    end
    
    def check_bip45_opts
      # Set current network to ruby-bitcoin gem
      MultisigMoneyTree.network = network
      
      # https://github.com/bitcoin/bips/blob/master/bip-0045.mediawiki#cosigner-index
      # Quote: The indices can be determined independently by lexicographically sorting the purpose public keys of each cosigner
      @public_keys.sort! { |a,b| a <=> b}

      # bitcoin-ruby work with compressed_hex pubkeys
      raise Errors::InvalidParams, "Expected to be compressed public keys" unless @public_keys.all?{|key| compressed_hex_format?(key) }

      # https://github.com/bitcoin/bips/blob/master/bip-0045.mediawiki#address-gap-limit
      # Quote: Address gap limit is currently set to 20. 
      #        Wallet software should warn when user is trying to exceed the gap limit on an external chain by generating a new address. 
      raise Errors::InvalidParams, "Address gap limit" unless [@required_signs, @public_keys.size].all?{|i| (0..20).include?(i) }
      raise Errors::InvalidParams, "Invalid m-of-n number" if @public_keys.size < @required_signs
    end
  end
end