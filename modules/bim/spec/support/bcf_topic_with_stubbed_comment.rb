RSpec.shared_context "bcf_topic with stubbed comment" do |attributes = {}|
  let(:attachment) { build_stubbed(:attachment, description: "snapshot") }
  let(:viewpoint) { build_stubbed(:bcf_viewpoint, attachments: [attachment]) }
  let(:bcf_comment) { build_stubbed(:bcf_comment, viewpoint:) }
  let(:bcf_topic) do
    build_stubbed(:bcf_issue_with_comment, **attributes).tap do |issue|
      allow(issue)
        .to receive(:viewpoints)
        .and_return([viewpoint])
      allow(issue)
        .to receive(:comments)
        .and_return([bcf_comment])
    end
  end
end
