require 'spec_helper'

describe MultisigMoneyTree::Support do
  include MultisigMoneyTree::Support
  
  subject(:keys) { json_fixture('keys') }
  
  describe '#compressed_hex_format?' do
    it 'check valid key' do
      expect(compressed_hex_format?(keys[:compressed][:valid])).to be_truthy
    end
    
    it 'check uncompressed key' do
      expect(compressed_hex_format?(keys[:uncompressed][:valid])).to be_falsey
    end
    
    it 'check resized to 66 not hex key' do
      expect(compressed_hex_format?(keys[:uncompressed][:resized])).to be_falsey
    end
  end
end