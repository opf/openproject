require 'test_helper'

class TestCaseTest < MiniTest::Spec
  class SongCell < Cell::ViewModel
    def show
      "Give It All!"
    end
  end

  class Song
    class Cell < Cell::Concept
    end
  end

  let (:song) { Object.new }

  # #cell returns the instance
  describe "#cell" do
    subject { cell("test_case_test/song", song) }

    it { subject.must_be_instance_of SongCell }
    it { subject.model.must_equal song }

    it { cell("test_case_test/song", collection: [song, song]).().must_equal "Give It All!Give It All!" }
  end


  describe "#concept" do
    subject { concept("test_case_test/song/cell", song) }

    it { subject.must_be_instance_of Song::Cell }
    it { subject.model.must_equal song }
  end
end

# capybara support
require "capybara"

class CapybaraTest < MiniTest::Spec
  class CapybaraCell < Cell::ViewModel
    def show
      "<b>Grunt</b>"
    end
  end

  describe "capybara support" do
    subject { cell("capybara_test/capybara", nil) }

    before { Cell::Testing.capybara = true  } # yes, a global switch!
    after  { Cell::Testing.capybara = false }

    it { subject.(:show).has_selector?('b').must_equal true }

    it { cell("capybara_test/capybara", collection: [1, 2]).().has_selector?('b').must_equal true }

    # FIXME: this kinda sucks, what if you want the string in a Capybara environment?
    it { subject.(:show).to_s.must_match "<b>Grunt</b>" }
  end
end
