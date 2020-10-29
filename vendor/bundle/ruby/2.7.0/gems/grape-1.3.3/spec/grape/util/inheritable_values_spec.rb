# frozen_string_literal: true

require 'spec_helper'
module Grape
  module Util
    describe InheritableValues do
      let(:parent) { InheritableValues.new }
      subject { InheritableValues.new(parent) }

      describe '#delete' do
        it 'deletes a key' do
          subject[:some_thing] = :new_foo_bar
          subject.delete :some_thing
          expect(subject[:some_thing]).to be_nil
        end

        it 'does not delete parent values' do
          parent[:some_thing] = :foo
          subject[:some_thing] = :new_foo_bar
          subject.delete :some_thing
          expect(subject[:some_thing]).to eq :foo
        end
      end

      describe '#[]' do
        it 'returns a value' do
          subject[:some_thing] = :foo
          expect(subject[:some_thing]).to eq :foo
        end

        it 'returns parent value when no value is set' do
          parent[:some_thing] = :foo
          expect(subject[:some_thing]).to eq :foo
        end

        it 'overwrites parent value with the current one' do
          parent[:some_thing] = :foo
          subject[:some_thing] = :foo_bar
          expect(subject[:some_thing]).to eq :foo_bar
        end

        it 'parent values are not changed' do
          parent[:some_thing] = :foo
          subject[:some_thing] = :foo_bar
          expect(parent[:some_thing]).to eq :foo
        end
      end

      describe '#[]=' do
        it 'sets a value' do
          subject[:some_thing] = :foo
          expect(subject[:some_thing]).to eq :foo
        end
      end

      describe '#to_hash' do
        it 'returns a Hash representation' do
          parent[:some_thing] = :foo
          subject[:some_thing_more] = :foo_bar
          expect(subject.to_hash).to eq(some_thing: :foo, some_thing_more: :foo_bar)
        end
      end

      describe '#clone' do
        let(:obj_cloned) { subject.clone }

        context 'complex (i.e. not primitive) data types (ex. entity classes, please see bug #891)' do
          let(:description) { { entity: double } }

          before { subject[:description] = description }

          it 'copies values; does not duplicate them' do
            expect(obj_cloned[:description]).to eq description
          end
        end
      end
    end
  end
end
