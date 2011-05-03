require File.expand_path('../../test_helper', __FILE__)

class TrackerDropTest < ActiveSupport::TestCase
  def setup
    @tracker = Tracker.generate!
    @drop = @tracker.to_liquid
  end

  context "drop" do
    should "be a TrackerDrop" do
      assert @drop.is_a?(TrackerDrop), "drop is not a TrackerDrop"
    end
  end

  context "#name" do
    should "return the name" do
      assert_equal @tracker.name, @drop.name
    end
  end
end
