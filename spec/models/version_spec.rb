require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Version do
  it { should have_many :version_settings }
end