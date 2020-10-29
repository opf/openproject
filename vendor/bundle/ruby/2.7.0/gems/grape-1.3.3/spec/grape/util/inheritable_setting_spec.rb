# frozen_string_literal: true

require 'spec_helper'
module Grape
  module Util
    describe InheritableSetting do
      before :each do
        InheritableSetting.reset_global!
      end

      let(:parent) do
        Grape::Util::InheritableSetting.new.tap do |settings|
          settings.global[:global_thing] = :global_foo_bar
          settings.namespace[:namespace_thing] = :namespace_foo_bar
          settings.namespace_inheritable[:namespace_inheritable_thing] = :namespace_inheritable_foo_bar
          settings.namespace_stackable[:namespace_stackable_thing] = :namespace_stackable_foo_bar
          settings.namespace_reverse_stackable[:namespace_reverse_stackable_thing] = :namespace_reverse_stackable_foo_bar
          settings.route[:route_thing] = :route_foo_bar
        end
      end

      let(:other_parent) do
        Grape::Util::InheritableSetting.new.tap do |settings|
          settings.namespace[:namespace_thing] = :namespace_foo_bar_other
          settings.namespace_inheritable[:namespace_inheritable_thing] = :namespace_inheritable_foo_bar_other
          settings.namespace_stackable[:namespace_stackable_thing] = :namespace_stackable_foo_bar_other
          settings.namespace_reverse_stackable[:namespace_reverse_stackable_thing] = :namespace_reverse_stackable_foo_bar_other
          settings.route[:route_thing] = :route_foo_bar_other
        end
      end

      before :each do
        subject.inherit_from parent
      end

      describe '#global' do
        it 'sets a global value' do
          subject.global[:some_thing] = :foo_bar
          expect(subject.global[:some_thing]).to eq :foo_bar
          subject.global[:some_thing] = :foo_bar_next
          expect(subject.global[:some_thing]).to eq :foo_bar_next
        end

        it 'sets the global inherited values' do
          expect(subject.global[:global_thing]).to eq :global_foo_bar
        end

        it 'overrides global values' do
          subject.global[:global_thing] = :global_new_foo_bar
          expect(parent.global[:global_thing]).to eq :global_new_foo_bar
        end

        it 'should handle different parents' do
          subject.global[:global_thing] = :global_new_foo_bar

          subject.inherit_from other_parent

          expect(parent.global[:global_thing]).to eq :global_new_foo_bar
          expect(other_parent.global[:global_thing]).to eq :global_new_foo_bar
        end
      end

      describe '#api_class' do
        it 'is specific to the class' do
          subject.api_class[:some_thing] = :foo_bar
          parent.api_class[:some_thing] = :some_thing

          expect(subject.api_class[:some_thing]).to eq :foo_bar
          expect(parent.api_class[:some_thing]).to eq :some_thing
        end
      end

      describe '#namespace' do
        it 'sets a value until the end of a namespace' do
          subject.namespace[:some_thing] = :foo_bar
          expect(subject.namespace[:some_thing]).to eq :foo_bar
        end

        it 'uses new values when a new namespace starts' do
          subject.namespace[:namespace_thing] = :new_namespace_foo_bar
          expect(subject.namespace[:namespace_thing]).to eq :new_namespace_foo_bar

          expect(parent.namespace[:namespace_thing]).to eq :namespace_foo_bar
        end
      end

      describe '#namespace_inheritable' do
        it 'works with inheritable values' do
          expect(subject.namespace_inheritable[:namespace_inheritable_thing]).to eq :namespace_inheritable_foo_bar
        end

        it 'should handle different parents' do
          expect(subject.namespace_inheritable[:namespace_inheritable_thing]).to eq :namespace_inheritable_foo_bar

          subject.inherit_from other_parent

          expect(subject.namespace_inheritable[:namespace_inheritable_thing]).to eq :namespace_inheritable_foo_bar_other

          subject.inherit_from parent

          expect(subject.namespace_inheritable[:namespace_inheritable_thing]).to eq :namespace_inheritable_foo_bar

          subject.inherit_from other_parent

          subject.namespace_inheritable[:namespace_inheritable_thing] = :my_thing

          expect(subject.namespace_inheritable[:namespace_inheritable_thing]).to eq :my_thing

          subject.inherit_from parent

          expect(subject.namespace_inheritable[:namespace_inheritable_thing]).to eq :my_thing
        end
      end

      describe '#namespace_stackable' do
        it 'works with stackable values' do
          expect(subject.namespace_stackable[:namespace_stackable_thing]).to eq [:namespace_stackable_foo_bar]

          subject.inherit_from other_parent

          expect(subject.namespace_stackable[:namespace_stackable_thing]).to eq [:namespace_stackable_foo_bar_other]
        end
      end

      describe '#namespace_reverse_stackable' do
        it 'works with reverse stackable values' do
          expect(subject.namespace_reverse_stackable[:namespace_reverse_stackable_thing]).to eq [:namespace_reverse_stackable_foo_bar]

          subject.inherit_from other_parent

          expect(subject.namespace_reverse_stackable[:namespace_reverse_stackable_thing]).to eq [:namespace_reverse_stackable_foo_bar_other]
        end
      end

      describe '#route' do
        it 'sets a value until the next route' do
          subject.route[:some_thing] = :foo_bar
          expect(subject.route[:some_thing]).to eq :foo_bar

          subject.route_end

          expect(subject.route[:some_thing]).to be_nil
        end

        it 'works with route values' do
          expect(subject.route[:route_thing]).to eq :route_foo_bar
        end
      end

      describe '#api_class' do
        it 'is specific to the class' do
          subject.api_class[:some_thing] = :foo_bar
          expect(subject.api_class[:some_thing]).to eq :foo_bar
        end
      end

      describe '#inherit_from' do
        it 'notifies clones' do
          new_settings = subject.point_in_time_copy
          expect(new_settings).to receive(:inherit_from).with(other_parent)

          subject.inherit_from other_parent
        end
      end

      describe '#point_in_time_copy' do
        let!(:cloned_obj) { subject.point_in_time_copy }

        it 'resets point_in_time_copies' do
          expect(cloned_obj.point_in_time_copies).to be_empty
        end

        it 'decouples namespace values' do
          subject.namespace[:namespace_thing] = :namespace_foo_bar

          cloned_obj.namespace[:namespace_thing] = :new_namespace_foo_bar
          expect(subject.namespace[:namespace_thing]).to eq :namespace_foo_bar
        end

        it 'decouples namespace inheritable values' do
          expect(cloned_obj.namespace_inheritable[:namespace_inheritable_thing]).to eq :namespace_inheritable_foo_bar

          subject.namespace_inheritable[:namespace_inheritable_thing] = :my_thing
          expect(subject.namespace_inheritable[:namespace_inheritable_thing]).to eq :my_thing

          expect(cloned_obj.namespace_inheritable[:namespace_inheritable_thing]).to eq :namespace_inheritable_foo_bar

          cloned_obj.namespace_inheritable[:namespace_inheritable_thing] = :my_cloned_thing
          expect(cloned_obj.namespace_inheritable[:namespace_inheritable_thing]).to eq :my_cloned_thing
          expect(subject.namespace_inheritable[:namespace_inheritable_thing]).to eq :my_thing
        end

        it 'decouples namespace stackable values' do
          expect(cloned_obj.namespace_stackable[:namespace_stackable_thing]).to eq [:namespace_stackable_foo_bar]

          subject.namespace_stackable[:namespace_stackable_thing] = :other_thing
          expect(subject.namespace_stackable[:namespace_stackable_thing]).to eq %i[namespace_stackable_foo_bar other_thing]
          expect(cloned_obj.namespace_stackable[:namespace_stackable_thing]).to eq [:namespace_stackable_foo_bar]
        end

        it 'decouples namespace reverse stackable values' do
          expect(cloned_obj.namespace_reverse_stackable[:namespace_reverse_stackable_thing]).to eq [:namespace_reverse_stackable_foo_bar]

          subject.namespace_reverse_stackable[:namespace_reverse_stackable_thing] = :other_thing
          expect(subject.namespace_reverse_stackable[:namespace_reverse_stackable_thing]).to eq %i[other_thing namespace_reverse_stackable_foo_bar]
          expect(cloned_obj.namespace_reverse_stackable[:namespace_reverse_stackable_thing]).to eq [:namespace_reverse_stackable_foo_bar]
        end

        it 'decouples route values' do
          expect(cloned_obj.route[:route_thing]).to eq :route_foo_bar

          subject.route[:route_thing] = :new_route_foo_bar
          expect(cloned_obj.route[:route_thing]).to eq :route_foo_bar
        end

        it 'adds itself to original as clone' do
          expect(subject.point_in_time_copies).to include(cloned_obj)
        end
      end

      describe '#to_hash' do
        it 'return all settings as a hash' do
          subject.global[:global_thing] = :global_foo_bar
          subject.namespace[:namespace_thing] = :namespace_foo_bar
          subject.namespace_inheritable[:namespace_inheritable_thing] = :namespace_inheritable_foo_bar
          subject.namespace_stackable[:namespace_stackable_thing] = [:namespace_stackable_foo_bar]
          subject.namespace_reverse_stackable[:namespace_reverse_stackable_thing] = [:namespace_reverse_stackable_foo_bar]
          subject.route[:route_thing] = :route_foo_bar

          expect(subject.to_hash).to include(global: { global_thing: :global_foo_bar })
          expect(subject.to_hash).to include(namespace: { namespace_thing: :namespace_foo_bar })
          expect(subject.to_hash).to include(namespace_inheritable: {
                                               namespace_inheritable_thing: :namespace_inheritable_foo_bar
                                             })
          expect(subject.to_hash).to include(namespace_stackable: { namespace_stackable_thing: [:namespace_stackable_foo_bar, [:namespace_stackable_foo_bar]] })
          expect(subject.to_hash).to include(namespace_reverse_stackable:
            { namespace_reverse_stackable_thing: [[:namespace_reverse_stackable_foo_bar], :namespace_reverse_stackable_foo_bar] })
          expect(subject.to_hash).to include(route: { route_thing: :route_foo_bar })
        end
      end
    end
  end
end
