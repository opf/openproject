module PluginSpecHelper
  shared_examples_for "customized journal class" do
    describe :save do
      let(:text) { "Lorem ipsum" }
      let(:changed_data) { { "text" => [text] } }

      describe "WITHOUT compression" do
        before do
          journal.changed_data = changed_data
          journal.save!

          journal.reload
        end

        it { journal.changed_data["data"].should == text }
        it { journal.changed_data["compression"].should be_blank }
      end

      describe "WITH gzip compression" do
        before do
          Setting.stub(:wiki_compression).and_return("gzip")

          journal.changed_data = changed_data
          journal.save!

          journal.reload
        end

        it { journal.changed_data["data"].should == Zlib::Deflate.deflate(text, Zlib::BEST_COMPRESSION) }
        it { journal.changed_data["compression"].should == Setting.wiki_compression }
      end
    end

  end

end
