module MultisigMoneyTree
  class Master < Node
    # Cosigner index
    attr_reader :cosigner_index
    # Cosigner master key
    attr_reader :cosigner_master_key
    # Instace of MultisigTree::Master master node
    attr_reader :master
    
    class << self
      # Generate new +Private+ Node for specific cosigner
      #
      # ==== Arguments
      # * +cosigner_index+ Integer cosigner index
      # * +network+ Symbol network
      # ==== Result
      # Returned instace of MultisigMoneyTree::Node class for path +m/45+
      def seed(cosigner_index, network: :bitcoin)
        raise Error::ImportError, 'Invalid cosigner index' if !cosigner_index.kind_of?(Integer) || cosigner_index < 0
        
        MultisigMoneyTree.network = network
        
        @master = MoneyTree::Master.new network: MultisigMoneyTree.network

        Node.new({
          cosigner_index: cosigner_index,
          node: @master.node_for_path('m/45')
        })
      end
      
      # Creating a Master Node using the private/public key specific cosigner
      #
      # ==== Arguments
      # * +cosigner_index+ Integer cosigner index
      # * +cosigner_master+ String cosigner private/public key
      # ==== Result
      # Returned instace of MultisigMoneyTree::Master class
      def from_bip32(cosigner_index, cosigner_master_key)    
        raise Error::ImportError, 'Invalid cosigner index' if !cosigner_index.kind_of?(Integer) || cosigner_index < 0
        
        begin
          @master = MoneyTree::Node.from_bip32(cosigner_master_key)
        rescue MoneyTree::Node::ImportError => e
          raise Error::ImportError, e.message
        rescue EncodingError => e
          raise Error::ChecksumError, 'Invalid checksum in key'
        end

        self.new({
          cosigner_index: cosigner_index,
          cosigner_master_key: cosigner_master_key,
          master: @master
        })
      end
      
      # Create BIP45 Node from BIP45 public key
      #
      # ==== Arguments
      # * +public_key+ String BIP45 public key
      # ==== Result
      # Returned instace of MultisigMoneyTree::BIP45Node class
      def from_bip45(public_key)
        hex = from_serialized_base58(public_key)
        network, count, *public_keys = [hex].pack("H*").split(";")
        
        BIP45Node.new({
          network: network.to_sym,
          required_signs: count.to_i,
          public_keys: public_keys
        })
      end
    end
    
    # Create instance of MultisigMoneyTree::Master class.
    # Please use MultisigMoneyTree::Master.from_bip32 method to create instance
    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set "@#{k}", v }
    end
    
    # Verify that the private key is present in the master
    #
    # ==== Result
    # Returned `true` when master initialized with private key
    def private_key?
      !@master.private_key.nil?
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
      node = @master.node_for_path "#{private_flag}/45/#{@cosigner_index}/#{change}/#{index}"
      Node.new({
        node: node,
        change: change,
        cosigner_index: cosigner_index,
        index: index
      })
    end
  end
end