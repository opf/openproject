require "rails_helper"

RSpec.describe Storages::StoragesMailer do
  let(:admin) { build_stubbed(:admin) }
  let(:html_body) do
    Capybara.string(mail.body.parts.find { |part| part["Content-Type"].value == "text/html" }.body.to_s)
  end

  shared_examples "a health notification email" do
    it "has the correct headers" do
      expect(mail.subject).to eq(expected_subject_text)
      expect(mail.to).to eq([admin.mail])
      expect(mail.from).to eq(["openproject@example.net"])
    end

    it "renders a link to the storage settings" do
      expect(html_body).to have_link("See storage settings")
      link_node = html_body.find_link("See storage settings")
      expect(link_node["href"]).to match(%r{/admin/settings/storages/#{storage.id}/edit})
    end

    it "renders a link to manage email notifications" do
      expect(html_body).to have_link("Storage email notification settings")
      link_node = html_body.find_link("Storage email notification settings")
      expect(link_node["href"]).to match(%r{/admin/settings/storages/#{storage.id}/edit})
    end
  end

  describe "#notify_unhealthy" do
    it_behaves_like "a health notification email" do
      let(:storage) { build_stubbed(:nextcloud_storage, :as_unhealthy) }
      let(:expected_subject_text) { "Storage \"#{storage.name}\" is unhealthy!" }

      subject(:mail) { described_class.notify_unhealthy(admin, storage) }
    end
  end

  describe "#notify_healthy" do
    it_behaves_like "a health notification email" do
      let(:expected_subject_text) { "Storage \"#{storage.name}\" is now healthy!" }
      let(:reason) { "thou_shall_not_pass_error" }
      let(:storage) { build_stubbed(:one_drive_storage, :as_healthy) }

      subject(:mail) { described_class.notify_healthy(admin, storage, reason) }
    end
  end
end
