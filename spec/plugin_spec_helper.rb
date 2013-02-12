module Meeting::PluginSpecHelper
  shared_examples_for "customized journal class" do
    describe :save do
      let(:text) { "Lorem ipsum" }
      let(:changes) { { "text" => [text] } }

      describe "WITHOUT compression" do
        before do
          journal.changes = changes
          journal.save!

          journal.reload
        end

        it { journal.changes["data"].should == text }
        it { journal.changes["compression"].should be_blank }
      end

      describe "WITH gzip compression" do
        before do
          Setting.stub(:wiki_compression).and_return("gzip")

          journal.changes = changes
          journal.save!

          journal.reload
        end

        it { journal.changes["data"].should == Zlib::Deflate.deflate(text, Zlib::BEST_COMPRESSION) }
        it { journal.changes["compression"].should == Setting.wiki_compression }
      end
    end

  end

end
