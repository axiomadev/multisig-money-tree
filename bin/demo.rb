# ==============================================
# Multisig Money Tree work demonstration script
# ==============================================
#
# ==== Scenario:
# * Generate master node for all cosigners (COSIGNERS_COUNT) by MultisigMoneyTree::Master.seed method
# * Generate first(index - 0) bip45 (public/private) nodes for all cosigners by MultisigMoneyTree::Master.node_for
# * Pack public bip32 keys (from public cosigner node) all cosigners to Hash with cosigner indexes
# * Generate new BIP45 multisig node by method MultisigMoneyTree::BIP45Node.new transferring there cosigner public keys and REQUIRED_SIGNS
# * Get address (node.to_address), redeem_script (node.redeem_script), public bip45 key (node.to_bip45) from BIP45 Node
# * Save all nodes with keys, addresses to yml file

require 'rubygems'
require 'bundler/setup'
require 'byebug'
require 'yaml'
require 'multisig-money-tree'

# COIN = 'bitcoin'
COIN = 'thebestcoin'
NETWORK = "#{COIN}_testnet".to_sym
COUNT_GENERATED_ADDRESSES = 10
COSIGNERS_COUNT = 2
REQUIRED_SIGNS = 2

# Generate new wallets
# ==== Arguments
# * +cosigner_index+ Integer cosigner index
# * +network+ Symbol network
# ==== Result
# Returned hash with private and public keys
def seed(cosigner_index)
  node = MultisigMoneyTree::Master.seed cosigner_index, network: NETWORK
  {
      private: node.to_bip32(:private, network: NETWORK),
      public: node.to_bip32(:public, network: NETWORK)
  }
end

# Generate new master node from Cosigner
# ==== Arguments
# * +wallet+ Hash for save master
# * +index+ Integer new cosigner index
# ==== Result
# Saved to wallet hash master node with private/public key
def init_cosigner_master(wallet, index)
  key = "cosigner#{index}".to_sym
  wallet[key] = {}
  wallet[key][:master] = seed(index)
end

# Generate BIP45 pubkey from cosigner master public keys
# ==== Arguments
# * +wallet+ Hash for save master
# * +cosigners_count+ Integer number cosigners in multisig-process
# * +required_signs+ Integer required number signs for send transaction
# ==== Result
# Saved to wallet hash bip45 public key
def init_bip45_pubkey(wallet, cosigners_count, required_signs)
  # Get all cosigners public bip32 keys to hash with indexes
  keys = {}
  cosigners_count.times do |i|
    keys[i] = wallet["cosigner#{i}".to_sym][:master][:public]
  end

  opts = {
    required_signs: required_signs,
    public_keys: keys,
    network: NETWORK
  }
  node = MultisigMoneyTree::BIP45Node.new(opts)
  
  wallet[:bip45] = {}
  wallet[:bip45][:public] = node.to_bip45(network: NETWORK)
end

# Generate net multisig address from bip45 master public key
# ==== Arguments
# * +wallet+ Hash for save master
# * +node_index+ Integer number node
# ==== Result
# Saved to wallet new multisig address
def init_multisig_deposit_address(wallet, node_index)
  master = MultisigMoneyTree::Master.from_bip45(wallet[:bip45][:public])
  node = master.node_for(0, node_index)
  
  wallet[:addresses] = {} if wallet[:addresses].nil?
  wallet[:addresses][node_index] = {
    address: node.to_address(network: NETWORK)
  }
end

# File for save wallet hash
wallet_file = "test-gem-wallet-#{COIN}.yml"
wallet = {}

# Init master for all cosigners
COSIGNERS_COUNT.times do |cosigner_index|
  init_cosigner_master(wallet, cosigner_index)
end

# Create bip45 master node and save to wallet hash
init_bip45_pubkey(wallet, COSIGNERS_COUNT, REQUIRED_SIGNS)

# Create multisig addresses from bip45 master node
COUNT_GENERATED_ADDRESSES.times do |node_index|
  init_multisig_deposit_address(wallet, node_index)
end

# Save wallet data
File.write(wallet_file, YAML.dump(wallet))
