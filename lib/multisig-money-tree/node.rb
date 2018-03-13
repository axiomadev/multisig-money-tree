module MultisigMoneyTree
  class Node   
    include Support
    extend Support
    
    attr_reader :node, :change, :cosigner_index, :index, :cosigner_master_key

    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set "@#{k}", v }
    end
    
    def method_missing(m, *args, &block)
      @node.send(m, *args, &block)
    end
  end
  
  class BIP45Node < Node
    attr_reader :public_keys, :required_signs, :address, :redeem_script, :network
    
    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set "@#{k}", v }
    end
    
    def to_address
      check_bip45_opts
      
      @address, @redeem_script = Bitcoin.pubkeys_to_p2sh_multisig_address(@required_signs, *@public_keys)
        
      @address
    end
    
    def redeem_script
      check_bip45_opts
      
      @redeem_script ||= Bitcoin::Script.to_p2sh_multisig_script(@required_signs, *@public_keys).last
    end
    
    def network
      @network ||= :bitcoin
    end

    def to_bip45(network: :bitcoin)
      @network = network

      check_bip45_opts

      to_serialized_base58(to_serialized_hex)
    end

    private
    
    # BIP45 key format:
    # "NETWORK;M;PUBKEY0..PUBKEYN"
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
      raise InvalidParams, "Expected to be compressed public keys" unless @public_keys.all?{|key| compressed_hex_format?(key) }

      # https://github.com/bitcoin/bips/blob/master/bip-0045.mediawiki#address-gap-limit
      # Quote: Address gap limit is currently set to 20. 
      #        Wallet software should warn when user is trying to exceed the gap limit on an external chain by generating a new address. 
      raise InvalidParams, "Address gap limit" unless [@required_signs, @public_keys.size].all?{|i| (0..20).include?(i) }
      raise InvalidParams, "Invalid m-of-n number" if @public_keys.size < @required_signs
    end
  end
end