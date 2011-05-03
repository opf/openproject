require File.expand_path('../../test_helper', __FILE__)

class IssueStatusDropTest < ActiveSupport::TestCase
  def setup
    @issue_status = IssueStatus.generate!
    @drop = @issue_status.to_liquid
  end

  context "drop" do
    should "be a IssueStatusDrop" do
      assert @drop.is_a?(IssueStatusDrop), "drop is not a IssueStatusDrop"
    end
  end


  context "#name" do
    should "return the name" do
      assert_equal @issue_status.name, @drop.name
    end
  end
end
