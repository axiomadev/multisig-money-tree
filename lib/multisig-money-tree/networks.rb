module MultisigMoneyTree
  # Merge TheBestCoin network settings to +networks+ settings
  def self.merge_thebestcoin(networks)
    networks[:bitcoin_testnet] = networks[:testnet] unless networks[:bitcoin_testnet]
    networks.merge(
      thebestcoin: networks[:bitcoin].merge(
        address_version: '0f',
        p2sh_version: '12',
        p2sh_char: '8',
        privkey_version: '60',
        privkey_compression_flag: '01',
        extended_privkey_version: "05adc3a6",
        extended_pubkey_version: "05adb52c",
        compressed_wif_chars: %w(c),
        uncompressed_wif_chars: %w(G),
        protocol_version: 70015
      ),
      thebestcoin_testnet: networks[:bitcoin].merge(
        address_version: '55',
        p2sh_version: '57',
        p2sh_char: 'c',
        privkey_version: '1a',
        privkey_compression_flag: '01',
        extended_privkey_version: "3f23263a",
        extended_pubkey_version: "3f23253b",
        compressed_wif_chars: %w(c),
        uncompressed_wif_chars: %w(B),
        protocol_version: 70015
      )
    )
  end

  # Set network to self and Bitcoin gem
  def self.network=(network)
    raise Error::NetworkNotFound, "#{network} is not a valid network!" unless @@network_keys.include?(network.to_sym)
    @@network = Bitcoin.network = network.to_sym
  end

  # Get current network
  def self.network
    @@network
  end

  # Merge ThiBestCoin networks configuration to Bitcoin and MoneyTree gems
  begin
    money_tree = merge_thebestcoin(MoneyTree::NETWORKS)
    bitcoin = merge_thebestcoin(Bitcoin::NETWORKS)

    @@network_keys = bitcoin.keys
    @@network = :bitcoin

    MoneyTree.send(:remove_const, :NETWORKS)
    MoneyTree.const_set(:NETWORKS, money_tree)

    Bitcoin.send(:remove_const, :NETWORKS)
    Bitcoin.const_set(:NETWORKS, bitcoin)
    Bitcoin.network = @@network
  end
end
