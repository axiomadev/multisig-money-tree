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
      !node.private_key.nil?
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
      node_path = node.node_for_path("#{private_flag}/45/#{@cosigner_index}/#{change}/#{index}")
      Node.new({
        node: node_path,
        change: change,
        cosigner_index: cosigner_index,
        index: index
      })
    end
    
    # Get node
    #
    # ==== Result
    # Returned instace of MultisigMoneyTree::Node class
    def node
      @node
    end
    
    # method-bridge for working with MoneyTree::Node
    def method_missing(m, *args, &block)
      node.send(m, *args, &block)
    end
  end
  
  class BIP45Node < Node
    attr_reader :public_keys, :public_keys_hex, :required_signs, :address, :redeem_script, :network, :cosigners_nodes
    
    # Create new +BIP45+ Node for create multisig address
    #
    # ==== Arguments
    # * +public_keys+ Array list of String cosigner bip32 public keys
    # * +required_signs+ Integer number required signatures for send transaction
    # * +network+ Symbol (optional, default: :bitcoin) network name
    # ==== Result
    # Returned instace of MultisigMoneyTree::BIP45Node class for generate multisig address
    # ==== Example
    #     pubkeys = {
    #       0 => "EQQ8FQmN5rYzWVWKBLB4GiN15wizzQBeTnYJD2axgHcvbPKr3p8rYnWuYTXCjLSBcKrJxSAt6dHmPwjaDpceqEV9FfJK1LpF9S2fpTzDp1HhzXX4",
    #       1 => "EQQ8FQmN5rYzWVWKBLB4GiN15wizzQBeTnYJD2axgHcvbPKr3p8rYnWuYTXCjLSBcKrJxSAt6dHmPwjaDpceqEV9FfJK1LpF9S2fpTzDp1HhzXX4"
    #     }
    #     multisig_node = MultisigMoneyTree::BIP45Node.new({
    #         public_keys: pubkeys,
    #         required_signs: 2,
    #         network: :thebestcoin_testnet
    #     })
    # Return MultisigMoneyTree::BIP45Node object, for work with BIP45 node
    # ==== Example
    #     address = multisig_node.to_address => c95ZV5fJ4x5TNdch38RfFC3BqAkGMP8ERk
    #     redeem_script = multisig_node.redeem_script => 52210322eb01c4acf17c88cabd4716058e957792e545b3072a4185971f88df11118836210329cb1cfd5dfbc98d5850603067c9e6368bf27dae02c856025ba82d341bf53b0f52ae
    #     pubkey = multisig_node.to_bip45 => 2DhbqvYUoAPXA3Cp34dGRS8Mdvjauqx3zXf4KyGPnKg1iGGN2Ad57pYWLvH8KHAUMFP5x6qsokpUdxDrX7d6uCnxqFDYXDioaS1QdUzj3N2sr7Wt9ZUC5sxqpDRgNP3rEpvoBBCyPPEd6ESEBdCwJkiedLdW38YVTEaX3uQgmVwhDqq8CQgw6sX6hmtUoCMogfcCbLVmX45SVVztR3Z5HyciwpFLVhdzQZ6LxFRpBHaK6B44CRWYYXyAE7DfgoQiQVLeNpYEQgyvF9cqMVNTJELP2rLZCJsqLwnhusd4vKAcZai4cCbEivhjbzuBbYUHcER6MQpjjx6a7qRbwQHcfXc8t6UMD
    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set "@#{k}", v }
      
      load_cosigners_nodes
      parse_public_keys
      check_bip45_opts
    end
    
    # Set new cosigner node
    #
    # ==== Arguments
    # * +index+ Integer cosigner index
    def cosigner_index=(index)
      raise Error::InvalidCosignerIndex, 'Invalid cosigner index' unless valid_cosigner_index?(index)
        
      @cosigner_index = index
    end
    
    # Get cosigner node by index
    #
    # ==== Result
    # Returned instace of MultisigMoneyTree::Node class for cosigner public node
    def node
      raise Error::InvalidCosignerIndex, 'Cosigner index is not set' if @cosigner_index.nil?
      
      @cosigners_nodes[@cosigner_index]
    end
    
    # Get net bip45 node for +change+ and +index+
    # ==== Arguments
    # * +change+ Integer change flag 0/1
    # * +number+ Integer address index
    # ==== Result
    # Returned instance of MultisigMoneyTree::BIP45Node class
    def node_for(change, index)
      # get all deposit nodes for +number+ index node
      new_public_keys = @cosigners_nodes.map do |cosigner_index, node|
        [cosigner_index, node.node_for(change, index).to_bip32(:public, network: network)]
      end.to_h

      BIP45Node.new({
        network: network.to_sym,
        required_signs: required_signs,
        public_keys: new_public_keys
      })
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
      MultisigMoneyTree.network = @network = network.to_sym
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
      @cosigners_nodes.each do |index, node|
        opts << "#{index}:#{node.to_bip32(:public, network: network)}"
      end
      opts.join(';').unpack('H*').first
    end
    
    # Load public cosigner node for get cosigners public keys in hex format
    def load_cosigners_nodes
      MultisigMoneyTree.network = @network
      check_public_keys
      
      @cosigners_nodes = @public_keys.map do |index, key|
        [index.to_i, MultisigMoneyTree::Master.from_bip32(index.to_i, key)]
      end.to_h
    end
    
    # Generate cosigner public keys in hex format by public nodes
    def parse_public_keys
      # Convert keys to compressed_hex format for bitcoin-ruby
      @public_keys_hex = @cosigners_nodes.map { |index, key| key.public_key.to_hex }
    end
    
    def check_bip45_opts  
      # https://github.com/bitcoin/bips/blob/master/bip-0045.mediawiki#cosigner-index
      # Quote: The indices can be determined independently by lexicographically sorting the purpose public keys of each cosigner
      @public_keys_hex.sort! { |a,b| a <=> b}

      # https://github.com/bitcoin/bips/blob/master/bip-0045.mediawiki#address-gap-limit
      # Quote: Address gap limit is currently set to 20. 
      #        Wallet software should warn when user is trying to exceed the gap limit on an external chain by generating a new address. 
      raise Error::InvalidParams, "Address gap limit" unless [@required_signs, @public_keys_hex.size].all?{|i| (0..MAX_COSIGNER).include?(i) }
      raise Error::InvalidParams, "Invalid m-of-n number" if @public_keys_hex.size < @required_signs
    end
    
    def check_public_keys
      raise Error::InvalidParams, "Invalid public keys options" unless @public_keys.kind_of?(Hash)
      raise Error::InvalidParams, "Invalid cosigner indexes in public keys" unless @public_keys.keys.all?{|i| valid_cosigner_index?(i.to_i) }
    end
  end
end