require 'spec_helper'

describe MultisigMoneyTree::Master do
  subject(:keys) { json_fixture('keys') }
  subject(:private_master) { MultisigMoneyTree::Master.from_bip32(1, keys[:master][:valid][:private]) }
  subject(:public_master) { MultisigMoneyTree::Master.from_bip32(1, keys[:master][:valid][:public]) }
  subject(:bip45node) { MultisigMoneyTree::Master.from_bip45(keys[:bip45][:valid][:public]) }
  
  describe '#seed' do
    it 'check cosigner index' do
      expect(MultisigMoneyTree::Master.seed(1)).to be_a(MultisigMoneyTree::Node)
      expect(MultisigMoneyTree::Master.seed(1).cosigner_index).to eq(1)
    end
    
    it 'check invalid cosigner index' do
      expect {
        MultisigMoneyTree::Master.seed(-1)
      }.to raise_error((MultisigMoneyTree::Error::InvalidCosignerIndex))
      
      expect {
        MultisigMoneyTree::Master.seed(:first)
      }.to raise_error((MultisigMoneyTree::Error::InvalidCosignerIndex))
    end
  end
  
  describe '#from_bip32' do
    it 'check valid key' do
      expect(MultisigMoneyTree::Master.from_bip32(1, keys[:master][:valid][:public])).to be_a(MultisigMoneyTree::Node)
    end
    
    it 'check invalid checksum' do
      expect {
        MultisigMoneyTree::Master.from_bip32(1, keys[:master][:invalid][:checksum])
      }.to raise_error((MultisigMoneyTree::Error::ChecksumError))
    end
    
    it 'check invalid version in key' do
      expect {
        MultisigMoneyTree::Master.from_bip32(1, keys[:master][:invalid][:version_09])
      }.to raise_error((MultisigMoneyTree::Error::ImportError))
    end
    
    it 'check invalid cosigner index' do
      expect {
        MultisigMoneyTree::Master.from_bip32(-1, keys[:master][:valid][:public])
      }.to raise_error((MultisigMoneyTree::Error::InvalidCosignerIndex))
      
      expect {
        MultisigMoneyTree::Master.from_bip32(:first, keys[:master][:valid][:public])
      }.to raise_error((MultisigMoneyTree::Error::InvalidCosignerIndex))
    end
  end
  
  describe '#private_key?' do
    it 'check exists private key' do
      expect(private_master.private_key?).to be_truthy
    end
    
    it 'check exists private key' do
      expect(public_master.private_key?).to be_falsey
    end
  end
  
  describe '#node_for?' do
    it 'check deposit node' do
      expect(public_master.node_for(0, 1)).to be_a(MultisigMoneyTree::Node)
      expect(public_master.node_for(0, 1).to_address(network: :thebestcoin_testnet)).to eql("bRVKvn4cNSki5CWQKsa6oMwBsTbUBVvPVS")
    end
    
    it 'check change node' do
      expect(public_master.node_for(1, 1)).to be_a(MultisigMoneyTree::Node)
      expect(public_master.node_for(1, 1).to_address(network: :thebestcoin_testnet)).to eql("bHrEjjGMUpcNKVri6heoKuUGXDLjUUtSgh")
    end
  end
  
  describe '#from_bip45' do
    it 'check valid bip45 pubkey' do
      expect(MultisigMoneyTree::Master.from_bip45(keys[:bip45][:valid][:public])).to be_a(MultisigMoneyTree::BIP45Node)
    end
    
    it 'check undefined network in bip45 pubkey' do
      expect { 
        MultisigMoneyTree::Master.from_bip45(keys[:bip45][:invalid][:rspec_network])
      }.to raise_error((MultisigMoneyTree::Error::NetworkNotFound))
    end
    
    it 'check m-of-n error in bip45 pubkey' do
      expect { 
        MultisigMoneyTree::Master.from_bip45(keys[:bip45][:invalid][:m_of_n])
      }.to raise_error((MultisigMoneyTree::Error::InvalidParams))
    end
    
    it 'check invalid base58 bip45 pubkey' do
      expect { 
        MultisigMoneyTree::Master.from_bip45(keys[:bip45][:invalid][:invalid_format])
      }.to raise_error((MultisigMoneyTree::Error::ChecksumError))
    end
    
    it 'check extracted options' do
      expect(bip45node.network).to eql(:thebestcoin_testnet)
      expect(bip45node.required_signs).to eql(2)
      expect(bip45node.public_keys.count).to eql(2)
      expect(bip45node.redeem_script.hth).to eql(keys[:bip45][:valid][:redeem_script])
      expect(bip45node.to_address).to eql(keys[:bip45][:valid][:address])
    end
    
    it 'check re-generate address' do
      expect(bip45node.to_bip45(network: :thebestcoin_testnet)).to eql(keys[:bip45][:valid][:public])
    end
  end
end