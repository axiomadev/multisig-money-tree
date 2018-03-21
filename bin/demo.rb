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
NODE = 1
COSIGNERS_COUNT = 2
REQUIRED_SIGNS = 2

# Pre-generated bip45 public keys for node M/45
BIP45KEYS = {
  thebestcoin_testnet: "2DhbqvYUoAPXA3Cp34dGRS8Mdvjauqx3zXf4KyGPnKaW9Zu4MZPoNUCK53gWMqEV21m8thAq5XPC6oFy1mz6payxrnFqnctpnzn2AMzY8JYLycr5gEMsQaVGgXxvUktbMb56GoLSD81haHK8wtsjrjN841hU1VF5EySFqnrPfcn2V88aF9k2jgnuXtE5jpdQr4KoeUHjEjmXC99Bcn7bjuzBRxAv89kDhSFWy2vukYvYKDTkFyqGdRXuB6FjvHwnujYZ3PKFzbEdvNzAYs1fjSuHyXCDrFJrFfbBGn4HRwZm2KFUsn3cgGy4yDyzroyqLz53aNdpbitv15o3iS8T3LnjoNqoh",
  bitcoin_testnet: "UCEprTQ5bbeFXFrnkQQJ7wgFNLdnxZCoJXv3ytZ4rN1hwm71NuLRi6nP8cLjxuGMQFHxMHTKZHiohFAyNzZyfPiSCZTDnGzjDAKraZbfE2H46Gfgfi2WzNr6qDSMjzGKxKFStu4scNbDayiU5BB2AUVNCkWfAMSQyasDdQFo67dyKVeYmRrbPgBrBp76HtUpL9bKZg8BpumXuCmy7rgEbT7Cisd3EdNVoSiyWZwzgFDSCBeApZTVXjuPmx1HQPTarA5xxuPzyUmheRAxZXgEQd6jNBApFZVsg1zqTJ657TKnqTPmMperZEvHYGM4daE2ZrRY72n3KVvWp7XhXZrv"
}

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

# Get multisig address by public bip32 keys
# ==== Arguments
# * +wallet+ Hash with pub/priv cosigner keys
# * +node_id+ Integer address index
# * +cosigners_count+ Integer cosigners count
# * +required_signs+ Integer required signs
# ==== Result
# Returned hash with address, redeem_script, public (bip45) key
def node_multisig wallet, node_id, cosigners_count, required_signs
  # Get all cosigners public bip32 keys to hash with indexes
  keys = {}
  cosigners_count.times do |i|
    keys[i] = wallet["cosigner#{i}".to_sym][:nodes][node_id][:public][:pubkey]
  end

  opts = {
    required_signs: required_signs,
    public_keys: keys,
    network: NETWORK
  }
  node = MultisigMoneyTree::BIP45Node.new(opts)
  {
    address: node.to_address,
    redeem_script: node.redeem_script.hth,
    public_key: node.to_bip45(network: NETWORK)
  }
end

def multisig_node_from_bip45(node_id)
  master = MultisigMoneyTree::Master.from_bip45(BIP45KEYS[NETWORK])
  node = master.node_for(0, node_id)
  {
    address: node.to_address,
    redeem_script: node.redeem_script.hth,
    public_key: node.to_bip45(network: NETWORK)
  }
end

# Get bip45 node (priv/public) by cosigner key and address index
# ==== Arguments
# * +wallet+ Hash with pub/priv cosigner keys
# * +cosigner_index+ Integer cosigner index (for get key)
# * +key_type+ Symbol type key :public or :private
# * +node_id+ Integer address index
# ==== Result
# Returned hash with keys
#   For key_type = :private
#     pubkey, address, privkey, privkey_wif
#   For key_type = :public
#     pubkey, address
def bip45_node(wallet, cosigner_index, key_type = :public, node_id)
  # Get key from wallet keys storege by index
  key = wallet["cosigner#{cosigner_index}".to_sym][:master][key_type]

  # Get master node
  master = MultisigMoneyTree::Master.from_bip32(cosigner_index, key)
  # get bip45 node by change flag and index
  node = master.node_for(0, node_id)

  # generate address, keys
  result = {
      pubkey: node.to_bip32(:public, network: NETWORK),
      address: node.to_address(network: NETWORK)
  }
  puts "Network: #{NETWORK}"
  puts "NETWORKS: #{MoneyTree::NETWORKS.inspect}"
  result.merge!({
    privkey: node.to_bip32(:private, network: NETWORK),
    privkey_wif: node.private_key.to_wif(compressed: true, network: NETWORK),
  }) if master.private_key?

  result
end

# Generate wallet for new cosigner
# ==== Arguments
# * +wallet+ Hash for save master and bip45 node pub/priv keys
# * +cosigner_index+ Integer new cosigner index
# * +node_index+ Integer address index
# ==== Result
# Saved to wallet hash master node and node for node_index with keys
def init_cosigner_wallet(wallet, cosigner_index, node_index)
  key = "cosigner#{cosigner_index}".to_sym
  wallet[key] = {} if wallet[key].nil?
  wallet[key][:nodes] = {} if wallet[key][:nodes].nil?

  # seed master node
  wallet[key][:master] = seed(cosigner_index) if wallet[key][:master].nil?

  # generate new node for +node_index+
  wallet[key][:nodes][node_index] = {
    public: bip45_node(wallet, cosigner_index, :public, node_index),
    private: bip45_node(wallet, cosigner_index, :private, node_index)
  } if wallet[key][:nodes][node_index].nil?
end

# Generate multisig address
# ==== Arguments
# * +wallet+ Hash with pub/priv cosigner keys
# * +node_index+ Integer address index
# * +cosigners_count+ Integer cosigners count
# * +required_signs+ Integer required signs
# ==== Result
# Saved to wallet hash multisig node with index +node_index+
def init_multisig_address(wallet, node_index, cosigners_count, required_signs)
  wallet[:multisig] = {} if wallet[:multisig].nil?
  wallet[:multisig][:nodes] = {} if wallet[:multisig][:nodes].nil?

  wallet[:multisig][:nodes][node_index] = node_multisig(wallet, node_index, cosigners_count, required_signs) if wallet[:multisig][:nodes][node_index].nil?
end

def init_multisig_address_from_bip45(wallet, node_index)
  wallet[:multisig][:nodes][node_index] = multisig_node_from_bip45(node_index) if wallet[:multisig][:nodes][node_index].nil?
end

# File for save wallet hash
wallet_file = "test-gem-wallet-#{COIN}.yml"
wallet = {}

# Init master and first node for cosigners
COSIGNERS_COUNT.times do |cosigner_index|
  init_cosigner_wallet(wallet, cosigner_index, NODE)
end

# Init mulstisig address for cosigners
init_multisig_address(wallet, NODE, COSIGNERS_COUNT, REQUIRED_SIGNS)

puts "Multisig address was successfully generated:"
puts "\tAddress: #{wallet[:multisig][:nodes][NODE][:address]}"
puts "\tRedeem Script: #{wallet[:multisig][:nodes][NODE][:redeem_script]}"
puts "\tPublic Key: #{wallet[:multisig][:nodes][NODE][:public_key]}"

init_multisig_address_from_bip45(wallet, NODE + 1)

# Save wallet data
File.write(wallet_file, YAML.dump(wallet))
