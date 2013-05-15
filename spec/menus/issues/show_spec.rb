require 'spec_helper'

describe Menus::Issues::Show do
  let(:menu) { Redmine::MenuManager.items(:issues_show) }

  it "should have an edit link" do
    debugger
    menu.children.any? { |item| item.name == :edit }.should be_true
  end
end
