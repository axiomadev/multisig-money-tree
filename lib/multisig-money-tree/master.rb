module MultisigMoneyTree
  class Master < Node
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
        raise Error::InvalidCosignerIndex, 'Invalid cosigner index' unless valid_cosigner_index?(cosigner_index)
        
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
        raise Error::InvalidCosignerIndex, 'Invalid cosigner index' unless valid_cosigner_index?(cosigner_index)
         
        begin
          @master = MoneyTree::Node.from_bip32(cosigner_master_key)
        rescue MoneyTree::Node::ImportError => e
          raise Error::ImportError, e.message
        rescue EncodingError => e
          raise Error::ChecksumError, 'Invalid checksum in key'
        rescue ArgumentError => e
          raise Error::ImportError, "#{e.message}\nKey: #{cosigner_master_key}"
        end

        Node.new({
          cosigner_index: cosigner_index,
          cosigner_master_key: cosigner_master_key,
          node: @master
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
        
        # parse cosigner keys with index
        public_keys.map! { |key| key.split(':') }.to_h

        BIP45Node.new({
          network: network.to_sym,
          required_signs: count.to_i,
          public_keys: public_keys
        })
      end
    end
  end
end