require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VersionSetting do

  describe "associations" do
    it { should belong_to :project }
    it { should belong_to :version }
  end

  describe "methods" do
    it { should respond_to :display }
    it { should respond_to :display= }
  end
end