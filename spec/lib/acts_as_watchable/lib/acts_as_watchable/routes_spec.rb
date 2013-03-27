require 'spec_helper'

describe OpenProject::Acts::Watchable::Routes do
  let(:request) { Struct.new(:type, :id) do
                    def path_parameters
                      { :object_id => id,
                        :object_type => type }
                    end
                  end.new(type, id) }

  describe "matches?" do
    shared_examples_for "watched model" do

      describe "for a valid id string" do
        let(:id) { "1" }

        it "should be true" do
          OpenProject::Acts::Watchable::Routes.matches?(request).should be_true
        end
      end

      describe "for an invalid id string" do
        let(:id) { "schmu" }

        it "should not be false" do
          OpenProject::Acts::Watchable::Routes.matches?(request).should be_false
        end
      end
    end

    ['issues', 'news', 'news', 'boards', 'messages', 'wikis', 'wiki_pages'].each do |type|
      describe "routing #{type} watches" do
        let(:type) { type }

        it_should_behave_like "watched model"
      end

    end

    describe "for a non watched model" do
      let(:type) { "schmu" }
      let(:id) { "4" }

      it "should be false" do
        OpenProject::Acts::Watchable::Routes.matches?(request).should be_false
      end
    end
  end
end

