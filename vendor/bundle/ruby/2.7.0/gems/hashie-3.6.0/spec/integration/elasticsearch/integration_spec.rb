require 'elasticsearch/model'
require 'hashie'

RSpec.configure do |config|
  config.expect_with :rspec do |expect|
    expect.syntax = :expect
  end
end

class MyModel < Hashie::Mash
  include Elasticsearch::Model

  disable_warnings

  index_name 'model'
  document_type 'model'
end

RSpec.describe 'elaasticsearch-model' do
  # See https://github.com/intridea/hashie/issues/354#issuecomment-363306114
  # for the reason why this doesn't work as you would expect
  it 'raises an error when the model does has an id' do
    object = MyModel.new
    stub_elasticsearch_client

    expect { object.__elasticsearch__.index_document }.to raise_error(NoMethodError)
  end

  it 'does not raise an error when the model has an id' do
    object = MyModel.new(id: 123)
    stub_elasticsearch_client

    expect { object.__elasticsearch__.index_document }.not_to raise_error
  end

  def stub_elasticsearch_client
    response = double('Response', body: '{}')
    allow_any_instance_of(Elasticsearch::Transport::Client).to receive(:perform_request) { response }
  end
end
