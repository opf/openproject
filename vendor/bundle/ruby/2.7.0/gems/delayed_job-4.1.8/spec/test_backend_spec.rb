require 'helper'

describe Delayed::Backend::Test::Job do
  it_should_behave_like 'a delayed_job backend'

  describe '#reload' do
    it 'causes the payload object to be reloaded' do
      job = 'foo'.delay.length
      o = job.payload_object
      expect(o.object_id).not_to eq(job.reload.payload_object.object_id)
    end
  end
end
