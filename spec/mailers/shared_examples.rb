shared_examples_for 'mail is sent' do
  let(:letters_sent_count) { 1 }
  let(:mail) { deliveries.first }
  let(:html_body) { mail.body.parts.detect { |p| p.content_type.include? 'text/html' }.body.encoded }

  it 'actually sends a mail' do
    expect(deliveries.size).to eql(letters_sent_count)
  end

  it 'is sent to the recipient' do
    expect(deliveries.first.to).to include(recipient.mail)
  end

  it 'is sent from the configured address' do
    expect(deliveries.first.from).to match_array([Setting.mail_from])
  end
end

shared_examples_for 'multiple mails are sent' do |set_letters_sent_count|
  it_behaves_like 'mail is sent' do
    let(:letters_sent_count) { set_letters_sent_count }
  end
end

shared_examples_for 'mail is not sent' do
  it 'sends no mail' do
    expect(deliveries).to be_empty
  end
end

shared_examples_for 'does not send mails to author' do
  let(:user) { FactoryBot.build_stubbed(:user) }

  context 'when mail is for another user' do
    it_behaves_like 'mail is sent'
  end

  context 'when mail is for author' do
    let(:recipient) { user }

    it_behaves_like 'mail is not sent'
  end
end

