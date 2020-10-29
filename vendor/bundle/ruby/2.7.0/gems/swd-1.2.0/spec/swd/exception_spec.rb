require 'spec_helper'

describe SWD::HttpError do
  subject do
    SWD::HttpError.new 400, 'Bad Request', HTTP::Message.new_response('')
  end

  its(:status)   { should == 400 }
  its(:message)  { should == 'Bad Request' }
  its(:response) { should be_a HTTP::Message }
end

describe SWD::BadRequest do
  its(:status)  { should == 400 }
  its(:message) { should == 'SWD::BadRequest' }
end

describe SWD::Unauthorized do
  its(:status)  { should == 401 }
  its(:message) { should == 'SWD::Unauthorized' }
end

describe SWD::Forbidden do
  its(:status)  { should == 403 }
  its(:message) { should == 'SWD::Forbidden' }
end