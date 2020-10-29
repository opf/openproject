# frozen_string_literal: true

require 'spec_helper'

module Grape
  module DSL
    module RoutingSpec
      class Dummy
        include Grape::DSL::Routing
      end
    end

    describe Routing do
      subject { Class.new(RoutingSpec::Dummy) }
      let(:proc) { ->() {} }
      let(:options) { { a: :b } }
      let(:path) { '/dummy' }

      describe '.version' do
        it 'sets a version for route' do
          version = 'v1'
          expect(subject).to receive(:namespace_inheritable).with(:version, [version])
          expect(subject).to receive(:namespace_inheritable).with(:version_options, using: :path)
          expect(subject.version(version)).to eq(version)
        end
      end

      describe '.prefix' do
        it 'sets a prefix for route' do
          prefix = '/api'
          expect(subject).to receive(:namespace_inheritable).with(:root_prefix, prefix)
          subject.prefix prefix
        end
      end

      describe '.scope' do
        it 'create a scope without affecting the URL' do
          expect(subject).to receive(:within_namespace)
          subject.scope {}
        end
      end

      describe '.do_not_route_head!' do
        it 'sets do not route head option' do
          expect(subject).to receive(:namespace_inheritable).with(:do_not_route_head, true)
          subject.do_not_route_head!
        end
      end

      describe '.do_not_route_options!' do
        it 'sets do not route options option' do
          expect(subject).to receive(:namespace_inheritable).with(:do_not_route_options, true)
          subject.do_not_route_options!
        end
      end

      describe '.mount' do
        it 'mounts on a nested path' do
          subject = Class.new(Grape::API)
          app1 = Class.new(Grape::API)
          app2 = Class.new(Grape::API)
          app2.get '/nice' do
            'play'
          end

          subject.mount app1 => '/app1'
          app1.mount app2 => '/app2'

          expect(subject.inheritable_setting.to_hash[:namespace]).to eq({})
          expect(subject.inheritable_setting.to_hash[:namespace_inheritable]).to eq({})
          expect(app1.inheritable_setting.to_hash[:namespace_stackable]).to eq(mount_path: ['/app1'])

          expect(app2.inheritable_setting.to_hash[:namespace_stackable]).to eq(mount_path: ['/app1', '/app2'])
        end

        it 'mounts multiple routes at once' do
          base_app = Class.new(Grape::API)
          app1     = Class.new(Grape::API)
          app2     = Class.new(Grape::API)
          base_app.mount(app1 => '/app1', app2 => '/app2')

          expect(app1.inheritable_setting.to_hash[:namespace_stackable]).to eq(mount_path: ['/app1'])
          expect(app2.inheritable_setting.to_hash[:namespace_stackable]).to eq(mount_path: ['/app2'])
        end
      end

      describe '.route' do
        before do
          allow(subject).to receive(:endpoints).and_return([])
          allow(subject).to receive(:route_end)
          allow(subject).to receive(:reset_validations!)
        end

        it 'marks end of the route' do
          expect(subject).to receive(:route_end)
          subject.route(:any)
        end

        it 'resets validations' do
          expect(subject).to receive(:reset_validations!)
          subject.route(:any)
        end

        it 'defines a new endpoint' do
          expect { subject.route(:any) }
            .to change { subject.endpoints.count }.from(0).to(1)
        end

        it 'does not duplicate identical endpoints' do
          subject.route(:any)
          expect { subject.route(:any) }
            .to_not change(subject.endpoints, :count)
        end

        it 'generates correct endpoint options' do
          allow(subject).to receive(:route_setting).with(:description).and_return(fiz: 'baz')
          allow(subject).to receive(:namespace_stackable_with_hash).and_return(nuz: 'naz')

          expect(Grape::Endpoint).to receive(:new) do |_inheritable_setting, endpoint_options|
            expect(endpoint_options[:method]).to eq :get
            expect(endpoint_options[:path]).to eq '/foo'
            expect(endpoint_options[:for]).to eq subject
            expect(endpoint_options[:route_options]).to eq(foo: 'bar', fiz: 'baz', params: { nuz: 'naz' })
          end.and_yield

          subject.route(:get, '/foo', { foo: 'bar' }, &proc {})
        end
      end

      describe '.get' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('GET', path, options)
          subject.get path, options, &proc
        end
      end

      describe '.post' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('POST', path, options)
          subject.post path, options, &proc
        end
      end

      describe '.put' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('PUT', path, options)
          subject.put path, options, &proc
        end
      end

      describe '.head' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('HEAD', path, options)
          subject.head path, options, &proc
        end
      end

      describe '.delete' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('DELETE', path, options)
          subject.delete path, options, &proc
        end
      end

      describe '.options' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('OPTIONS', path, options)
          subject.options path, options, &proc
        end
      end

      describe '.patch' do
        it 'delegates to .route' do
          expect(subject).to receive(:route).with('PATCH', path, options)
          subject.patch path, options, &proc
        end
      end

      describe '.namespace' do
        let(:new_namespace) { Object.new }

        it 'creates a new namespace with given name and options' do
          expect(subject).to receive(:within_namespace).and_yield
          expect(subject).to receive(:nest).and_yield
          expect(Namespace).to receive(:new).with(:foo, foo: 'bar').and_return(new_namespace)
          expect(subject).to receive(:namespace_stackable).with(:namespace, new_namespace)

          subject.namespace :foo, foo: 'bar', &proc {}
        end

        it 'calls #joined_space_path on Namespace' do
          result_of_namspace_stackable = Object.new
          allow(subject).to receive(:namespace_stackable).and_return(result_of_namspace_stackable)
          expect(Namespace).to receive(:joined_space_path).with(result_of_namspace_stackable)
          subject.namespace
        end
      end

      describe '.group' do
        it 'is alias to #namespace' do
          expect(subject.method(:group)).to eq subject.method(:namespace)
        end
      end

      describe '.resource' do
        it 'is alias to #namespace' do
          expect(subject.method(:resource)).to eq subject.method(:namespace)
        end
      end

      describe '.resources' do
        it 'is alias to #namespace' do
          expect(subject.method(:resources)).to eq subject.method(:namespace)
        end
      end

      describe '.segment' do
        it 'is alias to #namespace' do
          expect(subject.method(:segment)).to eq subject.method(:namespace)
        end
      end

      describe '.routes' do
        let(:routes) { Object.new }

        it 'returns value received from #prepare_routes' do
          expect(subject).to receive(:prepare_routes).and_return(routes)
          expect(subject.routes).to eq routes
        end

        context 'when #routes was already called once' do
          before do
            allow(subject).to receive(:prepare_routes).and_return(routes)
            subject.routes
          end
          it 'it does not call prepare_routes again' do
            expect(subject).to_not receive(:prepare_routes)
            expect(subject.routes).to eq routes
          end
        end
      end

      describe '.route_param' do
        it 'calls #namespace with given params' do
          expect(subject).to receive(:namespace).with(':foo', {}).and_yield
          subject.route_param('foo', {}, &proc {})
        end

        let(:regex) { /(.*)/ }
        let!(:options) { { requirements: regex } }
        it 'nests requirements option under param name' do
          expect(subject).to receive(:namespace) do |_param, options|
            expect(options[:requirements][:foo]).to eq regex
          end
          subject.route_param('foo', options, &proc {})
        end

        it 'does not modify options parameter' do
          allow(subject).to receive(:namespace)
          expect { subject.route_param('foo', options, &proc {}) }
            .to_not change { options }
        end
      end

      describe '.versions' do
        it 'returns last defined version' do
          subject.version 'v1'
          subject.version 'v2'
          expect(subject.version).to eq('v2')
        end
      end
    end
  end
end
