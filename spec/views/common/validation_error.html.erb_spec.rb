require 'spec_helper'

describe "common/_validation_error" do
  let(:error_message) { ["Something went completely wrong!"] }

  before do
    view.content_for(:error_details, 'Clear this!')

    render partial: "common/validation_error.html.erb",
           locals: { error_messages: error_message,
                     object_name: "Test" }
  end

  it { expect(view.content_for(:error_details)).not_to include('Clear this!') }
end
