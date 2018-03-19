# multisig-money-tree
Bitcoin BIP-45 implementation on Ruby

[![Build Status](https://travis-ci.org/rusanter/multisig-money-tree.svg?branch=master)](https://travis-ci.org/rusanter/multisig-money-tree)
[![Coverage Status](https://coveralls.io/repos/github/rusanter/multisig-money-tree/badge.svg?branch=master)](https://coveralls.io/github/rusanter/multisig-money-tree?branch=master)

## Example for work with MultisigMoneyTree
```ruby
  ruby bin/demo.rb
```

## For generate RDoc run
```ruby
  bundle exec rdoc
```

## How to use

### Set general requirements

```ruby
NETWORK = :thebestcoin_testnet
REQUIRED_SIGNS = 2
```

### Create cosigners master

```ruby
cs_1_master = MultisigMoneyTree::Master.seed(0, network: NETWORK)
cs_2_master = MultisigMoneyTree::Master.seed(1, network: NETWORK)

cs_1_keys = {
  private: cs_1_master.to_bip32(:private, network: NETWORK),
  public: cs_1_master.to_bip32(:public, network: NETWORK)
}

cs_2_keys = {
  private: cs_1_master.to_bip32(:private, network: NETWORK),
  public: cs_1_master.to_bip32(:public, network: NETWORK)
}
```

### Create cosigners nodes

```ruby
# Init Master Node for bip32 key 
cs_1_public_master = MultisigMoneyTree::Master.from_bip32(0, cs_1_keys[:public])

# Get deposit node for 1-th address
cs_1_deposit_node = cs_1_public_master.node_for(0, 1)
cs_1_public_node = {
    pubkey: cs_1_deposit_node.to_bip32(:public, network: NETWORK),
    address: cs_1_deposit_node.to_address(network: NETWORK)
}
```
In the same way, we initialize the node for the cosigner # 2

### Create multisig node

```ruby
# Pack public nodes bip32 keys cosigners to hash with cosigner index
keys = { 
  0 => cs_0_public_node[:pubkey], 
  1 => cs_1_public_node[:pubkey]
}

# Init BIP45 (multisig) node
multisig_node = MultisigMoneyTree::BIP45Node.new({
  required_signs: REQUIRED_SIGNS,
  public_keys: keys,
  network: NETWORK
})
```

### Create multisig address

```ruby
# Get the address and other elements of multisig addresses
multisig = {
  address: node.to_address,
  redeem_script: node.redeem_script.hth,
  public_key: node.to_bip45(network: NETWORK),
}
```

With the help of a public_key, we can in the future restore the multisig node by using the method MultisigMoneyTree::Master.from_bip45(pubkey)
