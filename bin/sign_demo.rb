# ==============================================
# Multisig Money Tree work demonstration script
# ==============================================
#
# ==== Scenario:
# * Run ruby bin/demo.rb before this script.
# * Prepare own signed_transaction.json file. It required as a arguments.
# * - Create raw transaction
# * - Sign it by existing private keys
# * - Decode hex of raw transaction and decode each scriptSig hex
# * - Provide redeem scripts for each inputs
# * - Provide hdpm_key_path for each inputs
# * - See example in spec/fixtures/signed_transaction.json
# * Sign transaction with MultisigMoneyTree gem.

require 'rubygems'
require 'bundler/setup'
require 'byebug'
require 'yaml'
require 'multisig-money-tree'
require 'json'

# COIN = 'bitcoin'
COIN = 'thebestcoin'
NETWORK = "#{COIN}_testnet".to_sym
NODE = 1
COSIGNERS_COUNT = 2
REQUIRED_SIGNS = 2

root_dir = File.expand_path '../..', __FILE__
tx_file = "#{root_dir}/spec/fixtures/signed_transaction.json"
keys_file = "#{root_dir}/spec/fixtures/cosigners.json"
abort("File #{tx_file} does not exists") unless File.exist?(tx_file)
abort("File #{keys_file} does not exists") unless File.exist?(keys_file)

begin
  raw_tx = File.read(tx_file)
  keys = File.read(keys_file)
rescue StandardError => e
  abort("Something went wrong! Details: #{e.inspect}")
end
# Read file with raw transaction in json file
tx_hash = JSON.parse(raw_tx, symbolize_names: true)
# Read master bip32 private key
keys = JSON.parse(keys, symbolize_names: true)

# Load transaction for signing
transaction = MultisigMoneyTree::Transaction.load_from_hash(
    tx_hash,
    keys["cosigner#{NODE}".to_sym][:private],
    NODE,
    NETWORK
)
# Sign transaction
hex = transaction.sign_inputs
p "Result transaction hex: #{hex}"
