# encoding: utf-8

Shindo.tests('AWS Storage | escape', ['aws']) do
  tests('Keys can contain a hierarchical prefix which should not be escaped') do
    returns(Fog::AWS::Storage.new.send(:escape, 'key/with/prefix')) { 'key/with/prefix' }
  end
end
