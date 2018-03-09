require 'spec_helper'

describe MultisigMoneyTree::Master do
  describe "initialize" do
    describe "without a seed" do
      before do
        @master = MultisigMoneyTree::Master.new(0)
      end

      # it "generates a random seed 32 bytes long" do
      #   expect(@master.seed.bytesize).to eql(32)
      # end
      # 
      # it "exports the seed in hex format" do
      #   # expect(@master).to respond_to(:seed_hex)
      #   expect(@master.seed_hex.size).to eql(64)
      # end
    end
  end
end