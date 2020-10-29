require 'spec_helper'

describe OpenIDConnect::HttpError do
  subject do
    OpenIDConnect::HttpError.new 400, 'Bad Request'
  end
  its(:status)   { should == 400 }
  its(:message)  { should == 'Bad Request' }
  its(:response) { should be_nil }
end

describe OpenIDConnect::BadRequest do
  its(:status)  { should == 400 }
  its(:message) { should == 'OpenIDConnect::BadRequest' }
end

describe OpenIDConnect::Unauthorized do
  its(:status)  { should == 401 }
  its(:message) { should == 'OpenIDConnect::Unauthorized' }
end

describe OpenIDConnect::Forbidden do
  its(:status)  { should == 403 }
  its(:message) { should == 'OpenIDConnect::Forbidden' }
end