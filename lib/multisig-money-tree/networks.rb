module MultisigMoneyTree
  @@networks = Bitcoin::NETWORKS
  @@network = :bitcoin
  
  # Merge ThiBestCoin networks configuration to Bitcoin gem
  begin
    @@networks[:bitcoin_testnet] = @@networks[:testnet]
    @@networks.merge!(
      thebestcoin: @@networks[:bitcoin].merge(
        address_version: '0f',
        p2sh_version: '12',
        p2sh_char: '8',
        privkey_version: '60',
        extended_privkey_version: "05adc3a6",
        extended_pubkey_version: "05adb52c",
        compressed_wif_chars: %w(c),
        uncompressed_wif_chars: %w(G),
        protocol_version: 70015
      ),
      thebestcoin_testnet: @@networks[:bitcoin].merge(
        address_version: '55',
        p2sh_version: '57',
        p2sh_char: 'c',
        privkey_version: '1a',
        extended_privkey_version: "3f23263a",
        extended_pubkey_version: "3f23253b",
        compressed_wif_chars: %w(c),
        uncompressed_wif_chars: %w(B),
        protocol_version: 70015
      )
    )
    
    Bitcoin.send(:remove_const, :NETWORKS)
    Bitcoin.const_set(:NETWORKS, @@networks)
    Bitcoin.network = @@network
  end
  
  # Set network to Bitcoin gem
  def self.network=(network)
    raise Error::NetworkNotFound unless @@networks.key?(network.to_sym)
    @@network = Bitcoin.network = network.to_sym
  end
  
  # Get current network
  def self.network
    @@network
  end
end