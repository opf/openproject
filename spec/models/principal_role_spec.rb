require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe PrincipalRole do
  it {should belong_to :principal}
  it {should belong_to :role}

end