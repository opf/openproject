require File.expand_path('../../spec_helper', __FILE__)


describe OpenProject::Webhooks::Hook do
  describe :relative_url do
    let(:hook) { OpenProject::Webhooks::Hook.new('myhook')}

    it "should return the correct URL" do
      expect(hook.relative_url).to eql('webhooks/myhook')
    end
  end

  describe :handle do
    let(:probe) { lambda{} }
    let(:hook) { OpenProject::Webhooks::Hook.new('myhook', &probe) }

    before do
      probe.should_receive(:call).with(hook, 1, 2, 3, 4)
    end

    it 'should execute the callback with the correct parameters' do
      hook.handle(1, 2, 3, 4)
    end
  end
end
