# frozen_string_literal: true

require 'spec_helper'
module Grape
  module Util
    describe ReverseStackableValues do
      let(:parent) { described_class.new }
      subject { described_class.new(parent) }

      describe '#keys' do
        it 'returns all keys' do
          subject[:some_thing] = :foo_bar
          subject[:some_thing_else] = :foo_bar
          expect(subject.keys).to eq %i[some_thing some_thing_else].sort
        end

        it 'returns merged keys with parent' do
          parent[:some_thing] = :foo
          parent[:some_thing_else] = :foo

          subject[:some_thing] = :foo_bar
          subject[:some_thing_more] = :foo_bar

          expect(subject.keys).to eq %i[some_thing some_thing_else some_thing_more].sort
        end
      end

      describe '#delete' do
        it 'deletes a key' do
          subject[:some_thing] = :new_foo_bar
          subject.delete :some_thing
          expect(subject[:some_thing]).to eq []
        end

        it 'does not delete parent values' do
          parent[:some_thing] = :foo
          subject[:some_thing] = :new_foo_bar
          subject.delete :some_thing
          expect(subject[:some_thing]).to eq [:foo]
        end
      end

      describe '#[]' do
        it 'returns an array of values' do
          subject[:some_thing] = :foo
          expect(subject[:some_thing]).to eq [:foo]
        end

        it 'returns parent value when no value is set' do
          parent[:some_thing] = :foo
          expect(subject[:some_thing]).to eq [:foo]
        end

        it 'combines parent and actual values (actual first)' do
          parent[:some_thing] = :foo
          subject[:some_thing] = :foo_bar
          expect(subject[:some_thing]).to eq %i[foo_bar foo]
        end

        it 'parent values are not changed' do
          parent[:some_thing] = :foo
          subject[:some_thing] = :foo_bar
          expect(parent[:some_thing]).to eq [:foo]
        end
      end

      describe '#[]=' do
        it 'sets a value' do
          subject[:some_thing] = :foo
          expect(subject[:some_thing]).to eq [:foo]
        end

        it 'pushes further values' do
          subject[:some_thing] = :foo
          subject[:some_thing] = :bar
          expect(subject[:some_thing]).to eq %i[foo bar]
        end

        it 'can handle array values' do
          subject[:some_thing] = :foo
          subject[:some_thing] = %i[bar more]
          expect(subject[:some_thing]).to eq [:foo, %i[bar more]]

          parent[:some_thing_else] = %i[foo bar]
          subject[:some_thing_else] = %i[some bar foo]

          expect(subject[:some_thing_else]).to eq [%i[some bar foo], %i[foo bar]]
        end
      end

      describe '#to_hash' do
        it 'returns a Hash representation' do
          parent[:some_thing] = :foo
          subject[:some_thing] = %i[bar more]
          subject[:some_thing_more] = :foo_bar
          expect(subject.to_hash).to eq(
            some_thing: [%i[bar more], :foo],
            some_thing_more: [:foo_bar]
          )
        end
      end

      describe '#clone' do
        let(:obj_cloned) { subject.clone }
        it 'copies all values' do
          parent = described_class.new
          child = described_class.new parent
          grandchild = described_class.new child

          parent[:some_thing] = :foo
          child[:some_thing] = %i[bar more]
          grandchild[:some_thing] = :grand_foo_bar
          grandchild[:some_thing_more] = :foo_bar

          expect(grandchild.clone.to_hash).to eq(
            some_thing: [:grand_foo_bar, %i[bar more], :foo],
            some_thing_more: [:foo_bar]
          )
        end

        context 'complex (i.e. not primitive) data types (ex. middleware, please see bug #930)' do
          let(:middleware) { double }

          before { subject[:middleware] = middleware }

          it 'copies values; does not duplicate them' do
            expect(obj_cloned[:middleware]).to eq [middleware]
          end
        end
      end
    end
  end
end
