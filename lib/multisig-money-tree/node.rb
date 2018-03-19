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
    
    # Verify that the private key is present in the master
    #
    # ==== Result
    # Returned `true` when master initialized with private key
    def private_key?
      !@node.private_key.nil?
    end

    # Get a node defined by the BIP45 standard by change and address index 
    #
    # ==== Arguments
    # * +change+ Integer 0/1 - flag of change. 0 - deposit address, 1 - change address
    # * +index+ Integer - address index
    # ==== Result
    # Returned instace of MultisigMoneyTree::Node class for path +m/45+
    # ==== Example
    #     MultisigMoneyTree::Master.from_bip32(1, pubkey).node_for(1, 1)
    # Return node for deposit 1-th address (m/45/1/1/1 node)
    def node_for(change, index)
      private_flag = private_key? ? 'm' : 'M'
      node = @node.node_for_path "#{private_flag}/45/#{@cosigner_index}/#{change}/#{index}"
      Node.new({
        node: node,
        change: change,
        cosigner_index: cosigner_index,
        index: index
      })
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
    #     pubkeys = {
    #       0 => "02e34a911c1e1d605568bfad35b5f0def282fa31ea9e2361dc1ce8a40a3ae322f6",
    #       1 => "02015429220c68b7cd6dcd44a7f69f126391d3e6b03e72f89035dd8d7f358f7dca"
    #     }
    #     multisig_node = MultisigMoneyTree::BIP45Node.new({
    #         public_keys: pubkeys,
    #         required_signs: 2,
    #         network: :thebestcoin_testnet
    #     })
    # Return MultisigMoneyTree::BIP45Node object, for work with BIP45 node
    # ==== Example
    #     address = multisig_node.to_address => cQNL51CFhb2pLY6d9N7tckaiRDpQrbBDkB
    #     redeem_script = multisig_node.redeem_script => 522102015429220c68b7cd6dcd44a7f69f126391d3e6b03e72f89035dd8d7f358f7dca2102e34a911c1e1d605568bfad35b5f0def282fa31ea9e2361dc1ce8a40a3ae322f652ae
    #     pubkey = multisig_node.to_bip45 => 6FH6bFAVfMs75yFQttCzPs513w166JZ4LmPBG9MZy9nmReBBDNTPAxPCQCGRk2N9kuRrXV4twin2Y4rwQeuvkQhCSVvWXQ47k1k5A95NjQ544jM5K7J4WtnUcqAtzNRvVWFGXi7pYNn64AtuzXDdBWQzK4hi1s5UKr8hQ61wjuL95AKcpLhVae5eZEp142N4ADVkUgYVgai8NHNhckGVT8G8vFgnnDL
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

      # check_bip45_opts

      to_serialized_base58(to_serialized_hex)
    end

    private
    
    # Generate serialized hex public key
    # Public keys stored to pubkey in hex format
    def to_serialized_hex
      opts = [network.to_s, @required_signs.to_s]
      @public_keys.each do |index, key|
        opts << "#{index}:#{key.to_hex}"
      end
      opts.join(';').unpack('H*').first
    end
    
    # Parse string raw key to PublicKey object
    def parse_public_keys
      @public_keys = @public_keys.map do |index, raw_key|
        begin
          [index.to_s.to_i, MoneyTree::PublicKey.new(raw_key, network: network)]
        rescue MoneyTree::Key::KeyFormatNotFound
          raise Error::KeyFormatNotFound, "Undefined key format for #{raw_key}"
        end
      end.to_h
      
      # Convert keys to compressed_hex format for bitcoin-ruby
      @public_keys_hex = @public_keys.map { |index, key| key.to_hex }
    end
    
    def check_bip45_opts
      # Set current network to ruby-bitcoin gem
      MultisigMoneyTree.network = network
      
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