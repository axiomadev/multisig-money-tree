require 'spec_helper'

describe MultisigMoneyTree do
  it 'check inject thebestcoint networks' do
    expect(Bitcoin::NETWORKS).to have_key(:thebestcoin)
    expect(Bitcoin::NETWORKS).to have_key(:thebestcoin_testnet)
  end
  
  it 'check copy bitcoin testnet network' do
    expect(Bitcoin::NETWORKS).to have_key(:bitcoin_testnet)
  end
  
  it 'check error on set invalid network' do
    expect {
      MultisigMoneyTree.network = :rspec
    }.to raise_error((MultisigMoneyTree::Error::NetworkNotFound))
  end
  
  it 'check thebestcoint network params' do
    MultisigMoneyTree.network = :thebestcoin
    net = Bitcoin::network
    expect(Bitcoin.network_name).to eql(:thebestcoin)
    expect(net[:protocol_version]).to eql(70015)
    expect(net[:privkey_version]).to eql('60')
    expect(net[:address_version]).to eql('0f')
    expect(net[:compressed_wif_chars]).to eql(%w(c))
    expect(net[:uncompressed_wif_chars]).to eql(%w(G))
    expect(net[:genesis_hash]).to eql("000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f")
  end
  
  it 'check thebestcoint_testnet network params' do
    MultisigMoneyTree.network = :thebestcoin_testnet
    net = Bitcoin::network
    expect(Bitcoin.network_name).to eql(:thebestcoin_testnet)
    expect(net[:privkey_version]).to eql('1a')
    expect(net[:address_version]).to eql('55')
    expect(net[:compressed_wif_chars]).to eql(%w(c))
    expect(net[:uncompressed_wif_chars]).to eql(%w(B))
  end
end
