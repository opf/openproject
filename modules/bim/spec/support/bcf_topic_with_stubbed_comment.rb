shared_context 'bcf_topic with stubbed comment' do |attributes = {}|
  let(:attachment) { FactoryBot.build_stubbed(:attachment, description: 'snapshot') }
  let(:viewpoint) { FactoryBot.build_stubbed(:bcf_viewpoint, attachments: [attachment]) }
  let(:bcf_comment) { FactoryBot.build_stubbed(:bcf_comment, viewpoint: viewpoint) }
  let(:bcf_topic) do
    FactoryBot.build_stubbed(:bcf_issue_with_comment, **attributes).tap do |issue|
      allow(issue)
        .to receive(:viewpoints)
        .and_return([viewpoint])
      allow(issue)
        .to receive(:comments)
        .and_return([bcf_comment])
    end
  end
end
