require "rails_helper"

RSpec.describe Attachments::VirusRescanJob,
               with_ee: %i[virus_scanning],
               with_settings: { antivirus_scan_mode: :clamav_socket } do
  let!(:attachment1) { create(:attachment, status: :uploaded) }
  let!(:attachment2) { create(:attachment, status: :rescan) }
  let!(:attachment3) { create(:attachment, status: :rescan) }

  let(:client_double) { instance_double(ClamAV::Client) }

  subject { described_class.perform_now }

  before do
    allow(ClamAV::Client).to receive(:new).and_return(client_double)
  end

  describe "#perform" do
    let(:response) { ClamAV::SuccessResponse.new("wat") }

    before do
      allow(client_double)
        .to receive(:execute).with(instance_of(ClamAV::Commands::InstreamCommand))
                             .and_return(response)
    end

    it "updates the attachments" do
      subject

      expect(attachment1.reload).to be_status_uploaded
      expect(attachment2.reload).to be_status_scanned
      expect(attachment3.reload).to be_status_scanned
    end
  end
end
