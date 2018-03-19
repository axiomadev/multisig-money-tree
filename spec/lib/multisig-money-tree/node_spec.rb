require 'spec_helper'

describe MultisigMoneyTree::Node do
  subject(:keys) { json_fixture('keys') }
  subject(:private_node) { MultisigMoneyTree::Master.from_bip32(1, keys[:master][:valid][:private]).node_for(0, 1) }
  
  describe '#initialize' do
    it 'check assign options' do
      expect(private_node.cosigner_index).to eql(1)
      expect(private_node.change).to eql(0)
      expect(private_node.index).to eql(1)
      expect(private_node.node).to be_a(MoneyTree::Node)
    end
  end
  
  describe '#method_missing' do
    it 'check work with MoneyTree::Node' do
      expect(private_node.to_address).to eql("1Dm4EYj827NEZMf3FDG1ahoKNahHnv3dMJ")
    end
    
    it 'check get pubkey from privkey from MoneyTree::Node' do
      expect(private_node.public_key.to_hex).to eql("030dfdde9107745c9862eee9a26dd2aea5344cbb1acffc88519f6652974f10fd19")
    end
  end
end

describe MultisigMoneyTree::BIP45Node do
  subject(:keys) { json_fixture('keys') }
  subject(:node) { MultisigMoneyTree::Master.from_bip45(1, keys[:bip45][:valid][:public]) }
  
  describe '#parse_public_keys' do
    it 'check correct parse keys' do
      expect(node.public_keys[0]).to be_a(MoneyTree::PublicKey)
      expect(node.required_signs).to eql(2)
    end
    
    it 'check parse pubkey with invalid format keys' do
      expect {
        MultisigMoneyTree::Master.from_bip45(1, keys[:bip45][:invalid][:invalid_format_pubkeys])
      }.to raise_error(MultisigMoneyTree::Error::KeyFormatNotFound)
    end
  end
  
  describe '#redeem_script' do
    it 'check loaded network from bip45 pubkey' do
      bip45node = MultisigMoneyTree::Master.from_bip45(1, keys[:bip45][:valid][:public])
      expect(bip45node.redeem_script.hth).to eql(keys[:bip45][:valid][:redeem_script])
    end
    
    it 'check set network by method' do
      bip45node = MultisigMoneyTree::Master.from_bip45(1, keys[:bip45][:valid][:public])
      bip45node.network = :bitcoin
      expect(bip45node.redeem_script.hth).to eql('522102118d4208ca2d1ad688f81d35a0b3977630aa05ec66787ecc21b5c8beea44ad3321022833e1dc3573ecff42a78da2508a30b86ffadb6137a602e66cf510eb9cf3f11c52ae')
    end
    
    it 'check set network by attribute' do
      bip45node = MultisigMoneyTree::Master.from_bip45(1, keys[:bip45][:valid][:public])
      expect(bip45node.redeem_script(network: :thebestcoin).hth).to eql('522102118d4208ca2d1ad688f81d35a0b3977630aa05ec66787ecc21b5c8beea44ad3321022833e1dc3573ecff42a78da2508a30b86ffadb6137a602e66cf510eb9cf3f11c52ae')
    end
  end
  
  describe '#to_address' do
    it 'check loaded network from bip45 pubkey' do
      bip45node = MultisigMoneyTree::Master.from_bip45(1, keys[:bip45][:valid][:public])
      expect(bip45node.to_address).to eql(keys[:bip45][:valid][:address])
    end
    
    it 'check set network by method' do
      bip45node = MultisigMoneyTree::Master.from_bip45(1, keys[:bip45][:valid][:public])
      bip45node.network = :bitcoin
      expect(bip45node.to_address).to eql('37itEbgea5M98vAterzf1ETRfg1eLGfkqb')
    end
    
    it 'check set network by attribute' do
      bip45node = MultisigMoneyTree::Master.from_bip45(1, keys[:bip45][:valid][:public])
      expect(bip45node.to_address(network: :thebestcoin)).to eql('8M7j31ZPoRNXmYz1yKKoJrzerEMufDreGQ')
    end
  end
  
  describe '#to_bip45' do
    it 'check correct re-generate pubkey' do
      expect(node.to_bip45).to eql(keys[:bip45][:valid][:public])
    end
    
    it 'check set network by method' do
      bip45node = MultisigMoneyTree::Master.from_bip45(1, keys[:bip45][:valid][:public])
      bip45node.network = :bitcoin
      expect(bip45node.to_bip45).to eq(keys[:bip45][:valid][:public_bitcoin])
    end
    
    it 'check set network by attribute' do
      bip45node = MultisigMoneyTree::Master.from_bip45(1, keys[:bip45][:valid][:public])
      expect(bip45node.to_bip45(network: :thebestcoin_testnet)).to eql(keys[:bip45][:valid][:public_tbc_testnet])
    end
  end
end
