require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Version do
  it { should have_one :version_setting }
end