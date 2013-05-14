require 'spec_helper'

describe Redmine::MenuManager do
  let(:manager) { Redmine::MenuManager }

  describe :items do
    it "should provide an empty TreeNode for an unknown menu" do
      manager.items(:lorem_ipsum_menu).should be_a Redmine::MenuManager::TreeNode
      manager.items(:lorem_ipsum_menu).children.should be_empty
    end
  end
end
