require 'rubygems'
require 'bundler/setup'
require 'byebug'
require 'yaml'
require 'multisig-money-tree'

# COIN = 'bitcoin'
COIN = 'thebestcoin'
NETWORK = "#{COIN}_testnet".to_sym
NODE = 1
COSIGNERS_COUNT = 2
REQUIRED_SINGS = 2
LABEL = 'rename_to_payment'

# Redefine network options in bitcoin ruby library
networks = Bitcoin::NETWORKS
# Define network options for thebestcoin_testnet
networks[:thebestcoin_testnet] = networks[:bitcoin].merge(
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
networks[:bitcoin_testnet] = networks[:testnet]

Bitcoin.send(:remove_const, :NETWORKS)
Bitcoin.const_set(:NETWORKS, networks)
Bitcoin.network = NETWORK


# Generate new wallets
def seed(cosigner_index)
  node = MultisigMoneyTree::Master.seed cosigner_index, network: NETWORK
  {
      private: node.to_bip32(:private, network: NETWORK),
      public: node.to_bip32(:public, network: NETWORK)
  }
end

# Get multisig address by public keys (note: use hex of bip32 public keys)
def node_multisig wallet, node_id, cosigners_count, required_sings
  keys = []
  cosigners_count.times do |i|
    keys << wallet["cosigner#{i}".to_sym][:nodes][node_id][:public][:pubkey_hex]
  end
  
  opts = {
    required_sings: required_sings,
    public_keys: keys
  }
  node = MultisigMoneyTree::BIP45Node.new(opts)
  {
    address: node.to_address,
    redeem_script: node.redeem_script.hth,
    public_key: node.to_bip45,
    check_reload_address: MultisigMoneyTree::Master.from_bip45(node.to_bip45).to_address
  }
end

def bip45_node(wallet, cosigner_index, key_type = :public, node_id)
  key = wallet["cosigner#{cosigner_index}".to_sym][:master][key_type]
  master = MultisigMoneyTree::Master.from_bip32(cosigner_index, key)
  node = master.node_for(0, node_id)
  result = {
      pubkey: node.to_bip32(:public, network: NETWORK),
      address: node.to_address(network: NETWORK)
  }
  result.merge!({
    privkey: node.to_bip32(:private, network: NETWORK),
    privkey_wif: node.private_key.to_wif(compressed: true, network: NETWORK),
  }) if master.is_private
  
  result.merge!({
    pubkey_hex: node.public_key.to_hex,
  }) unless master.is_private
  
  result
end

def init_cosigner_wallet(wallet, cosigner_index, node_index)
  key = "cosigner#{cosigner_index}".to_sym
  wallet[key] = {} if wallet[key].nil?
  wallet[key][:nodes] = {} if wallet[key][:nodes].nil?
  wallet[key][:master] = seed(cosigner_index) if wallet[key][:master].nil?

  wallet[key][:nodes][node_index] = { 
    public: bip45_node(wallet, cosigner_index, :public, node_index), 
    private: bip45_node(wallet, cosigner_index, :private, node_index) 
  } if wallet[key][:nodes][node_index].nil?
end

def init_multisig_address(wallet, node_index, cosigners_count, required_sings)
  wallet[:multisig] = {} if wallet[:multisig].nil?
  wallet[:multisig][:nodes] = {} if wallet[:multisig][:nodes].nil?

  wallet[:multisig][:nodes][node_index] = node_multisig(wallet, node_index, cosigners_count, required_sings) if wallet[:multisig][:nodes][node_index].nil?
end

# Load wallet data
wallet_file = "test-gem-wallet-#{COIN}.yml"

# generate wallet data
COSIGNERS_COUNT.times do |cosigner_index|
  init_cosigner_wallet(wallet, cosigner_index, NODE)
end

init_multisig_address(wallet, NODE, COSIGNERS_COUNT, REQUIRED_SINGS)
# Save wallet data
File.write(wallet_file, YAML.dump(wallet))