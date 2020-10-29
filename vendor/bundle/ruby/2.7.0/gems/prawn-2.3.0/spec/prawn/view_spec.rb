# frozen_string_literal: true

require 'spec_helper'

describe Prawn::View do
  let(:view_object) { Object.new.tap { |o| o.extend(described_class) } }

  it 'provides a Prawn::Document object by default' do
    expect(view_object.document).to be_kind_of(Prawn::Document)
  end

  it 'delegates unhandled methods to object returned by document method' do
    doc = instance_double('Document')
    allow(view_object).to receive(:document).and_return(doc)

    allow(doc).to receive(:some_delegated_method)

    view_object.some_delegated_method

    expect(doc).to have_received(:some_delegated_method)
  end

  it 'allows a block-like DSL via the update method' do
    doc = instance_double('Document')
    allow(view_object).to receive(:document).and_return(doc)

    allow(doc).to receive(:foo)
    allow(doc).to receive(:bar)

    view_object.update do
      foo
      bar
    end
    expect(doc).to have_received(:foo)
    expect(doc).to have_received(:bar)
  end

  it 'aliases save_as() to document.render_file()' do
    doc = instance_double('Document')
    allow(doc).to receive(:render_file)

    allow(view_object).to receive(:document).and_return(doc)

    view_object.save_as('foo.pdf')
    expect(doc).to have_received(:render_file)
  end

  describe '#respond_to?', issue: 1064 do
    subject { view_object.respond_to?(method) }

    context 'when called with an existing method from Prawn::Document' do
      let(:method) { :text }

      it { is_expected.to be_truthy }
    end

    context 'when called with a non-existing method' do
      let(:method) { :non_existing_method }

      it { is_expected.to be_falsey }
    end
  end
end
