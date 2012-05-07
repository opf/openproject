require File.expand_path(File.dirname(__FILE__) + "/../spec_helper.rb")

describe CostType do
  let(:klass) { CostType }
  let(:cost_type) { klass.new :name => "ct1",
                              :unit => "singular",
                              :unit_plural => "plural" }
  before do
    # as the spec_helper loads fixtures and they are probably needed by other tests
    # we delete them here so they do not interfere.
    # on the long run, fixtures should be removed

    CostType.destroy_all
  end

  describe "class" do
    describe "active" do
      describe "WHEN a CostType instance is deleted" do
        before do
          cost_type.deleted_at = Time.now
          cost_type.save!
        end

        it { klass.should have(0).active }
      end

      describe "WHEN a CostType instance is not deleted" do
        before do
          cost_type.save!
        end

        it { klass.should have(1).active }
        it { klass.active[0].should == cost_type }
      end
    end
  end
end
