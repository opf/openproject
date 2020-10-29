# frozen_string_literal: true

require 'spec_helper'

module Grape
  module DSL
    module SettingsSpec
      class Dummy
        include Grape::DSL::Settings

        def reset_validations!; end
      end
    end

    describe Settings do
      subject { SettingsSpec::Dummy.new }

      describe '#unset' do
        it 'deletes a key from settings' do
          subject.namespace_setting :dummy, 1
          expect(subject.inheritable_setting.namespace.keys).to include(:dummy)

          subject.unset :namespace, :dummy
          expect(subject.inheritable_setting.namespace.keys).not_to include(:dummy)
        end
      end

      describe '#get_or_set' do
        it 'sets a values' do
          subject.get_or_set :namespace, :dummy, 1
          expect(subject.namespace_setting(:dummy)).to eq 1
        end

        it 'returns a value when nil is new value is provided' do
          subject.get_or_set :namespace, :dummy, 1
          expect(subject.get_or_set(:namespace, :dummy, nil)).to eq 1
        end
      end

      describe '#global_setting' do
        it 'delegates to get_or_set' do
          expect(subject).to receive(:get_or_set).with(:global, :dummy, 1)
          subject.global_setting(:dummy, 1)
        end
      end

      describe '#unset_global_setting' do
        it 'delegates to unset' do
          expect(subject).to receive(:unset).with(:global, :dummy)
          subject.unset_global_setting(:dummy)
        end
      end

      describe '#route_setting' do
        it 'delegates to get_or_set' do
          expect(subject).to receive(:get_or_set).with(:route, :dummy, 1)
          subject.route_setting(:dummy, 1)
        end

        it 'sets a value until the next route' do
          subject.route_setting :some_thing, :foo_bar
          expect(subject.route_setting(:some_thing)).to eq :foo_bar

          subject.route_end

          expect(subject.route_setting(:some_thing)).to be_nil
        end
      end

      describe '#unset_route_setting' do
        it 'delegates to unset' do
          expect(subject).to receive(:unset).with(:route, :dummy)
          subject.unset_route_setting(:dummy)
        end
      end

      describe '#namespace_setting' do
        it 'delegates to get_or_set' do
          expect(subject).to receive(:get_or_set).with(:namespace, :dummy, 1)
          subject.namespace_setting(:dummy, 1)
        end

        it 'sets a value until the end of a namespace' do
          subject.namespace_start

          subject.namespace_setting :some_thing, :foo_bar
          expect(subject.namespace_setting(:some_thing)).to eq :foo_bar

          subject.namespace_end

          expect(subject.namespace_setting(:some_thing)).to be_nil
        end

        it 'resets values after leaving nested namespaces' do
          subject.namespace_start

          subject.namespace_setting :some_thing, :foo_bar
          expect(subject.namespace_setting(:some_thing)).to eq :foo_bar

          subject.namespace_start

          expect(subject.namespace_setting(:some_thing)).to be_nil

          subject.namespace_end
          expect(subject.namespace_setting(:some_thing)).to eq :foo_bar

          subject.namespace_end

          expect(subject.namespace_setting(:some_thing)).to be_nil
        end
      end

      describe '#unset_namespace_setting' do
        it 'delegates to unset' do
          expect(subject).to receive(:unset).with(:namespace, :dummy)
          subject.unset_namespace_setting(:dummy)
        end
      end

      describe '#namespace_inheritable' do
        it 'delegates to get_or_set' do
          expect(subject).to receive(:get_or_set).with(:namespace_inheritable, :dummy, 1)
          subject.namespace_inheritable(:dummy, 1)
        end

        it 'inherits values from surrounding namespace' do
          subject.namespace_start

          subject.namespace_inheritable(:some_thing, :foo_bar)
          expect(subject.namespace_inheritable(:some_thing)).to eq :foo_bar

          subject.namespace_start

          expect(subject.namespace_inheritable(:some_thing)).to eq :foo_bar

          subject.namespace_inheritable(:some_thing, :foo_bar_2)

          expect(subject.namespace_inheritable(:some_thing)).to eq :foo_bar_2

          subject.namespace_end
          expect(subject.namespace_inheritable(:some_thing)).to eq :foo_bar
          subject.namespace_end
        end
      end

      describe '#unset_namespace_inheritable' do
        it 'delegates to unset' do
          expect(subject).to receive(:unset).with(:namespace_inheritable, :dummy)
          subject.unset_namespace_inheritable(:dummy)
        end
      end

      describe '#namespace_stackable' do
        it 'delegates to get_or_set' do
          expect(subject).to receive(:get_or_set).with(:namespace_stackable, :dummy, 1)
          subject.namespace_stackable(:dummy, 1)
        end

        it 'stacks values from surrounding namespace' do
          subject.namespace_start

          subject.namespace_stackable(:some_thing, :foo_bar)
          expect(subject.namespace_stackable(:some_thing)).to eq [:foo_bar]

          subject.namespace_start

          expect(subject.namespace_stackable(:some_thing)).to eq [:foo_bar]

          subject.namespace_stackable(:some_thing, :foo_bar_2)

          expect(subject.namespace_stackable(:some_thing)).to eq %i[foo_bar foo_bar_2]

          subject.namespace_end
          expect(subject.namespace_stackable(:some_thing)).to eq [:foo_bar]
          subject.namespace_end
        end
      end

      describe '#unset_namespace_stackable' do
        it 'delegates to unset' do
          expect(subject).to receive(:unset).with(:namespace_stackable, :dummy)
          subject.unset_namespace_stackable(:dummy)
        end
      end

      describe '#api_class_setting' do
        it 'delegates to get_or_set' do
          expect(subject).to receive(:get_or_set).with(:api_class, :dummy, 1)
          subject.api_class_setting(:dummy, 1)
        end
      end

      describe '#unset_api_class_setting' do
        it 'delegates to unset' do
          expect(subject).to receive(:unset).with(:api_class, :dummy)
          subject.unset_api_class_setting(:dummy)
        end
      end

      describe '#within_namespace' do
        it 'calls start and end for a namespace' do
          expect(subject).to receive :namespace_start
          expect(subject).to receive :namespace_end

          subject.within_namespace do
          end
        end

        it 'returns the last result' do
          result = subject.within_namespace do
            1
          end

          expect(result).to eq 1
        end
      end

      describe 'complex scenario' do
        it 'plays well' do
          obj1 = SettingsSpec::Dummy.new
          obj2 = SettingsSpec::Dummy.new
          obj3 = SettingsSpec::Dummy.new

          obj1_copy = nil
          obj2_copy = nil
          obj3_copy = nil

          obj1.within_namespace do
            obj1.namespace_stackable(:some_thing, :obj1)
            expect(obj1.namespace_stackable(:some_thing)).to eq [:obj1]
            obj1_copy = obj1.inheritable_setting.point_in_time_copy
          end

          expect(obj1.namespace_stackable(:some_thing)).to eq []
          expect(obj1_copy.namespace_stackable[:some_thing]).to eq [:obj1]

          obj2.within_namespace do
            obj2.namespace_stackable(:some_thing, :obj2)
            expect(obj2.namespace_stackable(:some_thing)).to eq [:obj2]
            obj2_copy = obj2.inheritable_setting.point_in_time_copy
          end

          expect(obj2.namespace_stackable(:some_thing)).to eq []
          expect(obj2_copy.namespace_stackable[:some_thing]).to eq [:obj2]

          obj3.within_namespace do
            obj3.namespace_stackable(:some_thing, :obj3)
            expect(obj3.namespace_stackable(:some_thing)).to eq [:obj3]
            obj3_copy = obj3.inheritable_setting.point_in_time_copy
          end

          expect(obj3.namespace_stackable(:some_thing)).to eq []
          expect(obj3_copy.namespace_stackable[:some_thing]).to eq [:obj3]

          obj1.top_level_setting.inherit_from obj2_copy.point_in_time_copy
          obj2.top_level_setting.inherit_from obj3_copy.point_in_time_copy

          expect(obj1_copy.namespace_stackable[:some_thing]).to eq %i[obj3 obj2 obj1]
        end
      end
    end
  end
end
