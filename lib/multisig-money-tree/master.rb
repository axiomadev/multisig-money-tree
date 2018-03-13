module MultisigMoneyTree
  class Master < Node
    attr_reader :cosigner_index, :master, :cosigner_master_key
    
    class << self
      def seed(cosigner_index, network: :bitcoin)
        MultisigMoneyTree.network = network
        @master = MoneyTree::Master.new network: MultisigMoneyTree.network
        Node.new({
          cosigner_index: cosigner_index,
          node: @master.node_for_path('m/45')
        })
      end
      
      def from_bip32(cosigner_index, cosigner_master_key)
        @master = MoneyTree::Node.from_bip32(cosigner_master_key)

        self.new({
          cosigner_index: cosigner_index,
          cosigner_master_key: cosigner_master_key,
          master: @master
        })
      end
      
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
    
    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set "@#{k}", v }
    end
    
    def private_key?
      !@master.private_key.nil?
    end

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