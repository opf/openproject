require "rails_helper"

RSpec.describe Attachments::VirusScanJob,
               with_ee: %i[virus_scanning],
               with_settings: { antivirus_scan_mode: :clamav_socket } do
  let(:attachment_status) { :uploaded }
  let(:attachment) { build_stubbed(:attachment, status: attachment_status) }
  let(:client_double) { instance_double(ClamAV::Client) }
  let(:journal_service_double) { instance_double(Journals::CreateService) }

  subject { described_class.perform_now(attachment) }

  before do
    allow(ClamAV::Client).to receive(:new).and_return(client_double)
  end

  describe "#perform when disabled", with_settings: { antivirus_scan_mode: :disabled } do
    it "does not scan the attachment" do
      subject

      expect(ClamAV::Client).not_to have_received(:new)
    end
  end

  context "when status is not uploaded" do
    let(:attachment_status) { :prepared }

    it "does not scan the attachment" do
      subject

      expect(ClamAV::Client).not_to have_received(:new)
    end
  end

  describe "#perform" do
    before do
      allow(client_double)
        .to receive(:execute).with(instance_of(ClamAV::Commands::InstreamCommand))
                             .and_return(response)
    end

    context "when no virus is found" do
      let(:response) { ClamAV::SuccessResponse.new("wat") }

      it "updates the file status" do
        allow(attachment).to receive(:update!)

        subject

        expect(attachment).to have_received(:update!).with(status: :scanned)
      end
    end

    context "when error occurs in clamav" do
      let(:response) { ClamAV::ErrorResponse.new("Oh noes") }

      it "does nothing to the file" do
        allow(attachment).to receive(:update!)

        expect { subject }.not_to raise_error

        expect(attachment).not_to have_received(:update!)
      end
    end

    context "when virus is found" do
      let(:response) { ClamAV::VirusResponse.new("wat", "Eicar-Test-Signature") }

      context "when action is quarantine", with_settings: { antivirus_scan_action: :quarantine } do
        it "quarantines the file" do
          allow(attachment).to receive(:update!)
          allow(Journals::CreateService).to receive(:new).and_return(journal_service_double)
          allow(journal_service_double).to receive(:call)

          subject

          expect(attachment).to have_received(:update!).with(status: :quarantined)
          expect(journal_service_double)
            .to have_received(:call).with(notes: /It has been quarantined/)
        end
      end

      context "when action is delete", with_settings: { antivirus_scan_action: :delete } do
        it "deletes the file" do
          allow(attachment).to receive(:destroy!)
          allow(Journals::CreateService).to receive(:new).and_return(journal_service_double)
          allow(journal_service_double).to receive(:call)

          subject

          expect(attachment).to have_received(:destroy!)
          expect(journal_service_double)
            .to have_received(:call).with(notes: /The file has been deleted/)
        end
      end
    end
  end
end
