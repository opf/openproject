# encoding: utf-8
Shindo.tests('AWS | url', ["aws"]) do

  @storage = Fog::Storage.new(
    :provider => 'AWS',
    :aws_access_key_id => '123',
    :aws_secret_access_key => 'abc',
    :region => 'us-east-1'
  )

  @file = @storage.directories.new(:key => 'fognonbucket').files.new(:key => 'test.txt')

  now = Fog::Time.now
  
  @storage = Fog::Storage.new(
    :provider => 'AWS',
    :aws_access_key_id => '123',
    :aws_secret_access_key => 'abc',
    :aws_signature_version => 2,
    :region => 'us-east-1'
  )

  @file = @storage.directories.new(:key => 'fognonbucket').files.new(:key => 'test.txt')

end
