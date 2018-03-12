module MultisigMoneyTree
  class Node   
    include MoneyTree::Support
    extend MoneyTree::Support
    
    attr_reader :node, :change, :cosigner_index, :index, :cosigner_master_key

    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set "@#{k}", v }
    end
    
    def method_missing(m, *args, &block)
      @node.send(m, *args, &block)
    end
  end
  
  class BIP45Node < Node
    class InvalidParams < StandardError; end
    
    attr_reader :public_keys, :required_signs, :address, :redeem_script, :network
    
    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set "@#{k}", v }
    end
    
    def to_address
      raise InvalidParams unless check_bip45_opts
      
      @address, @redeem_script = Bitcoin.pubkeys_to_p2sh_multisig_address(@required_signs, *@public_keys)
        
      @address
    end
    
    def redeem_script
      raise InvalidParams unless check_bip45_opts
      
      @redeem_script ||= Bitcoin::Script.to_p2sh_multisig_script(@required_signs, *@public_keys).last
    end

    def to_bip45(network: :bitcoin)
      @network = network

      raise InvalidParams unless check_bip45_opts

      to_serialized_base58(to_serialized_hex)
    end

    private
    
    def to_serialized_hex
      opts = [@network.to_s, @required_signs.to_s]
      @public_keys.each do |key|
        opts << key
      end
      opts.join(';').unpack('H*').first
    end
    
    def check_bip45_opts
      @network ||= :bitcoin
      
      # https://github.com/bitcoin/bips/blob/master/bip-0045.mediawiki#cosigner-index
      # Quote: The indices can be determined independently by lexicographically sorting the purpose public keys of each cosigner
      @public_keys.sort! { |a,b| a <=> b}
      
      @required_signs > 1 && @public_keys.size >= @required_signs
    end
  end
end