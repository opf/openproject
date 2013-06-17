require 'spec_helper'

describe Redmine::MenuManager::Mapper do
  let(:name) { :test }
  let(:menu) { double(Redmine::MenuManager::Menu) }
  let(:mapper) { Redmine::MenuManager::Mapper.new(:lorem, :lorem => menu) }
  let(:content) { double("contents") }
  let(:options) { { } }

  describe :push do
    it "should push a new item onto root if nothing else is specified" do
      node = double('new_node')
      factory_content = double("factory_content")
      factory_granter = double("factory_content")

      Redmine::MenuManager::Content::Factory.should_receive(:build)
                                            .with(content, options)
                                            .and_return(factory_content)

      Redmine::MenuManager::Granter::Factory.should_receive(:build)
                                            .with(content, options)
                                            .and_return(factory_granter)

      Redmine::MenuManager::MenuItem.should_receive(:new)
                                    .with(name, factory_content, factory_granter)
                                    .and_return(node)

      menu.should_receive(:place).with(node, options)

      mapper.push name, content, options
    end
  end
end
