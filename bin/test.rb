require 'rubygems'
require 'bundler/setup'
require 'byebug'
require 'yaml'
require 'multisig-money-tree'

#COIN = 'bitcoin'
COIN = 'thebestcoin'
NETWORK = "#{COIN}_testnet".to_sym
NODE = 1
COSIGNERS_COUNT = 2
REQUIRED_SIGNS = 2

# Generate new wallets
def seed(cosigner_index)
  node = MultisigMoneyTree::Master.seed cosigner_index, network: NETWORK
  {
      private: node.to_bip32(:private, network: NETWORK),
      public: node.to_bip32(:public, network: NETWORK)
  }
end

# Get multisig address by public keys (note: use hex of bip32 public keys)
def node_multisig wallet, node_id, cosigners_count, required_signs
  keys = []
  cosigners_count.times do |i|
    keys << wallet["cosigner#{i}".to_sym][:nodes][node_id][:public][:pubkey_hex]
  end
  
  opts = {
    required_signs: required_signs,
    public_keys: keys,
    network: NETWORK
  }
  node = MultisigMoneyTree::BIP45Node.new(opts)
  {
    prev_redeem_script: node.redeem_script.hth,
    address: node.to_address,
    redeem_script: node.redeem_script.hth,
    public_key: node.to_bip45(network: NETWORK),
    check_reload_address: MultisigMoneyTree::Master.from_bip45(node.to_bip45(network: NETWORK)).to_address
  }
end

def bip45_node(wallet, cosigner_index, key_type = :public, node_id)
  key = wallet["cosigner#{cosigner_index}".to_sym][:master][key_type]
  
  # key = "EQS8svTtHMkS7Jmch3wNMXTsKmM3uR4m4UrfHiouWstA4ZGwbGCcnYg4CVPkgfkGystvmjh49V1gekCkRsmnzzT6nDbN3RBwhAMKRr3v2Kh5b2fd"
  
  master = MultisigMoneyTree::Master.from_bip32(cosigner_index, key)
  node = master.node_for(0, node_id)
  result = {
      pubkey: node.to_bip32(:public, network: NETWORK),
      address: node.to_address(network: NETWORK)
  }
  result.merge!({
    privkey: node.to_bip32(:private, network: NETWORK),
    privkey_wif: node.private_key.to_wif(compressed: true, network: NETWORK),
  }) if master.private_key?
  
  result.merge!({
    pubkey_hex: node.public_key.to_hex,
  }) unless master.private_key?
  
  result
end

# Add multisig address to hot-wallet
def add_multisig wallet, node_id
  node = wallet[:multisig][:nodes][node_id]
  address = {
      scriptPubKey: {
          address: node[:address]
      },
      # timestamp: 'now', not working for thebestcoin
      redeemscript: node[:redeem_script],
      pubkeys: [
          wallet[:cosigner0][:nodes][node_id][:public][:pubkey_hex],
          wallet[:cosigner1][:nodes][node_id][:public][:pubkey_hex]
      ],
      # watchonly: true,
      label: LABEL
  }

  result_importprivkey = Common::CoinRPC[COIN].importprivkey wallet[:cosigner0][:nodes][node_id][:private][:privkey_wif], LABEL, false

  result_importmulti = Common::CoinRPC[COIN].importmulti [address]

  result_validateaddress = Common::CoinRPC[COIN].validateaddress wallet[:multisig][:nodes][node_id][:address]

  puts "RPC importprivkey: #{result_importprivkey}"
  puts "RPC importmulti: #{result_importmulti}"
  puts "RPC validateaddress: #{result_validateaddress}"
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

def init_multisig_address(wallet, node_index, cosigners_count, required_signs)
  wallet[:multisig] = {} if wallet[:multisig].nil?
  wallet[:multisig][:nodes] = {} if wallet[:multisig][:nodes].nil?

  wallet[:multisig][:nodes][node_index] = node_multisig(wallet, node_index, cosigners_count, required_signs) if wallet[:multisig][:nodes][node_index].nil?
end

# Load wallet data
wallet_file = "test-gem-wallet-#{COIN}.yml"
wallet = {}

# generate wallet data
COSIGNERS_COUNT.times do |cosigner_index|
  init_cosigner_wallet(wallet, cosigner_index, NODE)
end

init_multisig_address(wallet, NODE, COSIGNERS_COUNT, REQUIRED_SIGNS)
# Save wallet data
File.write(wallet_file, YAML.dump(wallet))