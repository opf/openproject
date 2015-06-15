require 'spec_helper'

describe UiComponents::Content::Toolbar::WatchButton do
  let(:button) { described_class.new(user, object).render! }
  let(:user) { User.new }
  let(:object) { Object.new }
  let(:watched) { false }

  before do
    allow(object).to receive(:watched_by?).with(user).and_return(watched)
    allow(object).to receive(:id).and_return(42)
  end

  describe 'when the user does not watch a given object' do

    it 'should display a watch button' do
      expect(button).to be_html_eql %{
        <a class="button"
           href="/objects/42/watch"
           data-method="post"
           data-remote="true"
           data-unwatch-icon="not-watch"
           data-unwatch-method="delete"
           data-unwatch-path="/objects/42/unwatch"
           data-unwatch-text="Unwatch"
           data-watch-icon="watch-1"
           data-watch-method="post"
           data-watch-path="/objects/42/watch"
           data-watch-text="Watch"
           role="button">
            <i class="button--icon icon-watch-1"></i>
            <span class="button--text">Watch</span>
        </a>
      }
    end
  end

  describe 'when the user does watch the object' do
    let(:watched) { true }

    it 'should display an unwatch button' do
      expect(button).to be_html_eql %{
        <a class="button"
           href="/objects/42/unwatch"
           data-method="delete"
           data-remote="true"
           data-unwatch-icon="not-watch"
           data-unwatch-method="delete"
           data-unwatch-path="/objects/42/unwatch"
           data-unwatch-text="Unwatch"
           data-watch-icon="watch-1"
           data-watch-method="post"
           data-watch-path="/objects/42/watch"
           data-watch-text="Watch"
           role="button">
            <i class="button--icon icon-not-watch"></i>
            <span class="button--text">Unwatch</span>
        </a>
      }
    end
  end

end
