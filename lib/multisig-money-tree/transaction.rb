module MultisigMoneyTree
  # Class for manual sign transactions in Bitcoin Ruby library context
  class Transaction
    class << self
      # Instantiate Bitcoin::Protocol::Tx and MultisigMoneyTree entities
      #
      # == Arguments
      # * +tx_hash+ raw transaction hash
      # * +cosigner_master_key+ BIP32 private key of master node (M/45)
      # * +cosinger_index+ Cosigner index identified node of possible sign right
      # * +network+ Cryptocurrency network symbol
      #
      # == Result
      # * MultisignMoneyTree::Transaction instance
      def load_from_hash(tx_hash, cosigner_master_key, cosigner_index = 1, network = :bitcoin)
        tx_hash, multisig_inputs = hash2hash tx_hash

        protocol_tx = Bitcoin::Protocol::Tx.from_hash tx_hash
        master = MultisigMoneyTree::Master.from_bip32 cosigner_index, cosigner_master_key

        transaction = Transaction.new protocol_tx, master, cosigner_index, network
        transaction.setup_inputs multisig_inputs

        transaction
      end

      # Translator from hash(1) to hash(2).
      # * hash(1) - result of RPC command decoderawtransaction with decodescript of inputs scriptSig hexes
      # * hash(2) - format supported bitcoin-ruby library for importing
      #
      # == Arguments
      # * +tx_hash+ hash(1) instance
      # == Result
      # * hash(2) instance
      def hash2hash(tx_hash)
        inputs = []
        outputs = []
        multisig_inputs = []

        tx_hash[:vin].each_with_index do |item, i|
          inputs << {
            'prev_out' => {
              'hash' => item[:txid],
              'n' => item[:vout]
            },
            'scriptSig' => item[:scriptSig][:asm]
          }

          if item[:redeem_script] && item[:hdpm_key_path]
            multisig_inputs << {
              index: i,
              redeem_script: item[:redeem_script],
              hdpm_key_path: item[:hdpm_key_path]
            }
          end
        end

        tx_hash[:vout].each do |item|
          outputs << {
            'value' => item[:value],
            'scriptPubKey' => item[:scriptPubKey][:asm]
          }
        end

        [
          {
            'hash' => tx_hash[:txid],
            'size' => tx_hash[:size],
            'vin_sz' => tx_hash[:vsize],
            'ver' => tx_hash[:version],
            'lock_time' => tx_hash[:locktime],
            'in' => inputs,
            'out' => outputs
          },
          multisig_inputs
        ]
      end
    end

    # == Arguments
    # +transction+ Bitcoin::Protocol::Tx instance
    # +master+ MultisigMoneyTree::Node instance of cosigner node loaded by master private key
    # +cosigner_index+ Cosigner index
    # +network+ Used cryptocurrency network symbol
    def initialize(transaction, master, cosigner_index = 1, network = :bitcoin)
      @transaction = transaction
      @master = master
      @cosigner_index = cosigner_index
      @network = network
      @inputs_keys = []
      MultisigMoneyTree.network = @network
    end

    # Gathering private keys, binary redeem_script for each inputs with multisig
    # * Calculate private key from hdpm_key_path
    # * Get binary of redeem_script
    #
    # == Arguments
    # * +multisig_inputs+ info about multisig inputs
    # *   +:redeem_script+ redeem script of utxo
    # *   +:index+ index of multisig inputs in transaction inputs
    # *   +:hdpm_key_path+ BIP45 path of multisig address
    def setup_inputs(multisig_inputs)
      @inputs_keys = []
      multisig_inputs.each do |item|
        key_path = item[:hdpm_key_path].split('/')
        node = @master.node_for(key_path[-2], key_path[-1])

        @inputs_keys << {
          index: item[:index],
          redeem_script: item[:redeem_script].htb,
          priv_key: node.private_key.to_wif(compressed: true, network: @network)
        }
      end
    end

    # Sign multisig transaction
    # Before calling make sure that setup_inputs completed correctly
    #
    # == Result
    # * Hex of signed transaction
    def sign_inputs
      raise RuntimeError if @inputs_keys.length.zero?
      raise RuntimeError if @inputs_keys.length > @transaction.in.length

      @inputs_keys.each { |input| sign_script_for(input) }
      @transaction.to_payload.unpack('H*')[0]
    end

    private

    # Calculate signature with cosigner private key script for transaction input
    #
    # == Arguments
    # * +input+ Multisignature
    def sign_script_for(input)
      raise RuntimeError if @transaction.in[input[:index]].nil?

      # Get hash for signing
      sig_hash = @transaction.signature_hash_for_input(input[:index], input[:redeem_script])
      # Make signature with private key
      sig = Bitcoin::Key.from_base58(input[:priv_key]).sign(sig_hash)
      # Add signature to existing script sig
      script_sig = Bitcoin::Script.add_sig_to_multisig_script_sig(sig, @transaction.in[input[:index]].script_sig)
      # Sort signatures in script_sig by pubkeys in redeem_script
      @transaction.in[input[:index]].script_sig = Bitcoin::Script.sort_p2sh_multisig_signatures(script_sig, sig_hash)
    end
  end
end
