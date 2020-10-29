require 'test_helper'

class GetterSetterTest < BaseTest
  representer! do
    property :name, # key under :name.
      :getter => lambda { |options| "#{options[:user_options][:welcome]} #{song_name}" },
      :setter => lambda { |options| self.song_name = "#{options[:user_options][:welcome]} #{options[:input]}" }
  end

  subject { Struct.new(:song_name).new("Mony Mony").extend(representer) }

  it "uses :getter when rendering" do
    subject.instance_eval { def name; raise; end }
    subject.to_hash(user_options: {welcome: "Hi"}).must_equal({"name" => "Hi Mony Mony"})
  end

  it "uses :setter when parsing" do
    subject.instance_eval { def name=(*); raise; end; self }
    subject.from_hash({"name" => "Eyes Without A Face"}, user_options: {welcome: "Hello"}).song_name.must_equal "Hello Eyes Without A Face"
  end
end