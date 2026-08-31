# frozen_string_literal: true

RSpec.shared_examples "strips invisible characters" do |attribute|
  it { is_expected.to normalize(attribute).from("hello\n\x00world\t").to("helloworld") }
  it { is_expected.to normalize(attribute).from("hello\u200Bworld\u200C").to("helloworld") }
end
