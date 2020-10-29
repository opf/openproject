require 'spec_helper'

describe WebFinger::Response do
  let(:_subject_) { 'acct:nov@matake.jp' }
  let(:aliases) { ['mailto:nov@matake.jp'] }
  let(:properties) do
    {'http://webfinger.net/rel/name' => 'Nov Matake'}
  end
  let(:links) do
    [{
      rel: 'http://openid.net/specs/connect/1.0/issuer',
      href: 'https://openid.example.com/'
    }.with_indifferent_access]
  end
  let(:attributes) do
    {
      subject: _subject_,
      aliases: aliases,
      properties: properties,
      links: links
    }.with_indifferent_access
  end
  subject do
    WebFinger::Response.new attributes
  end

  its(:subject)    { should == _subject_ }
  its(:aliases)    { should == aliases }
  its(:properties) { should == properties }
  its(:links)      { should == links }

  describe '#link_for' do
    context 'when unknown' do
      it do
        subject.link_for('unknown').should be_nil
      end
    end

    context 'otherwise' do
      it do
        subject.link_for('http://openid.net/specs/connect/1.0/issuer').should == links.first
      end
    end
  end
end