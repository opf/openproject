# frozen_string_literal: true

require 'spec_helper'

module Grape
  describe Path do
    describe '#initialize' do
      it 'remembers the path' do
        path = Path.new('/:id', anything, anything)
        expect(path.raw_path).to eql('/:id')
      end

      it 'remembers the namespace' do
        path = Path.new(anything, '/users', anything)
        expect(path.namespace).to eql('/users')
      end

      it 'remebers the settings' do
        path = Path.new(anything, anything, foo: 'bar')
        expect(path.settings).to eql(foo: 'bar')
      end
    end

    describe '#mount_path' do
      it 'is nil when no mount path setting exists' do
        path = Path.new(anything, anything, {})
        expect(path.mount_path).to be_nil
      end

      it 'is nil when the mount path is nil' do
        path = Path.new(anything, anything, mount_path: nil)
        expect(path.mount_path).to be_nil
      end

      it 'splits the mount path' do
        path = Path.new(anything, anything, mount_path: %w[foo bar])
        expect(path.mount_path).to eql(%w[foo bar])
      end
    end

    describe '#root_prefix' do
      it 'is nil when no root prefix setting exists' do
        path = Path.new(anything, anything, {})
        expect(path.root_prefix).to be_nil
      end

      it 'is nil when the mount path is nil' do
        path = Path.new(anything, anything, root_prefix: nil)
        expect(path.root_prefix).to be_nil
      end

      it 'splits the mount path' do
        path = Path.new(anything, anything, root_prefix: 'hello/world')
        expect(path.root_prefix).to eql(%w[hello world])
      end
    end

    describe '#uses_path_versioning?' do
      it 'is false when the version setting is nil' do
        path = Path.new(anything, anything, version: nil)
        expect(path.uses_path_versioning?).to be false
      end

      it 'is false when the version option is header' do
        path = Path.new(
          anything,
          anything,
          version: 'v1',
          version_options: { using: :header }
        )

        expect(path.uses_path_versioning?).to be false
      end

      it 'is true when the version option is path' do
        path = Path.new(
          anything,
          anything,
          version: 'v1',
          version_options: { using: :path }
        )

        expect(path.uses_path_versioning?).to be true
      end
    end

    describe '#namespace?' do
      it 'is false when the namespace is nil' do
        path = Path.new(anything, nil, anything)
        expect(path.namespace?).to be_falsey
      end

      it 'is false when the namespace starts with whitespace' do
        path = Path.new(anything, ' /foo', anything)
        expect(path.namespace?).to be_falsey
      end

      it 'is false when the namespace is the root path' do
        path = Path.new(anything, '/', anything)
        expect(path.namespace?).to be false
      end

      it 'is true otherwise' do
        path = Path.new(anything, '/world', anything)
        expect(path.namespace?).to be true
      end
    end

    describe '#path?' do
      it 'is false when the path is nil' do
        path = Path.new(nil, anything, anything)
        expect(path.path?).to be_falsey
      end

      it 'is false when the path starts with whitespace' do
        path = Path.new(' /foo', anything, anything)
        expect(path.path?).to be_falsey
      end

      it 'is false when the path is the root path' do
        path = Path.new('/', anything, anything)
        expect(path.path?).to be false
      end

      it 'is true otherwise' do
        path = Path.new('/hello', anything, anything)
        expect(path.path?).to be true
      end
    end

    describe '#path' do
      context 'mount_path' do
        it 'is not included when it is nil' do
          path = Path.new(nil, nil, mount_path: '/foo/bar')
          expect(path.path).to eql '/foo/bar'
        end

        it 'is included when it is not nil' do
          path = Path.new(nil, nil, {})
          expect(path.path).to eql('/')
        end
      end

      context 'root_prefix' do
        it 'is not included when it is nil' do
          path = Path.new(nil, nil, {})
          expect(path.path).to eql('/')
        end

        it 'is included after the mount path' do
          path = Path.new(
            nil,
            nil,
            mount_path: '/foo',
            root_prefix: '/hello'
          )

          expect(path.path).to eql('/foo/hello')
        end
      end

      it 'uses the namespace after the mount path and root prefix' do
        path = Path.new(
          nil,
          'namespace',
          mount_path: '/foo',
          root_prefix: '/hello'
        )

        expect(path.path).to eql('/foo/hello/namespace')
      end

      it 'uses the raw path after the namespace' do
        path = Path.new(
          'raw_path',
          'namespace',
          mount_path: '/foo',
          root_prefix: '/hello'
        )

        expect(path.path).to eql('/foo/hello/namespace/raw_path')
      end
    end

    describe '#suffix' do
      context 'when using a specific format' do
        it 'accepts specified format' do
          path = Path.new(nil, nil, {})
          allow(path).to receive(:uses_specific_format?) { true }
          allow(path).to receive(:settings) { { format: :json } }

          expect(path.suffix).to eql('(.json)')
        end
      end

      context 'when path versioning is used' do
        it "includes a '/'" do
          path = Path.new(nil, nil, {})
          allow(path).to receive(:uses_specific_format?) { false }
          allow(path).to receive(:uses_path_versioning?) { true }

          expect(path.suffix).to eql('(/.:format)')
        end
      end

      context 'when path versioning is not used' do
        it "does not include a '/' when the path has a namespace" do
          path = Path.new(nil, 'namespace', {})
          allow(path).to receive(:uses_specific_format?) { false }
          allow(path).to receive(:uses_path_versioning?) { true }

          expect(path.suffix).to eql('(.:format)')
        end

        it "does not include a '/' when the path has a path" do
          path = Path.new('/path', nil, {})
          allow(path).to receive(:uses_specific_format?) { false }
          allow(path).to receive(:uses_path_versioning?) { true }

          expect(path.suffix).to eql('(.:format)')
        end

        it "includes a '/' otherwise" do
          path = Path.new(nil, nil, {})
          allow(path).to receive(:uses_specific_format?) { false }
          allow(path).to receive(:uses_path_versioning?) { true }

          expect(path.suffix).to eql('(/.:format)')
        end
      end
    end

    describe '#path_with_suffix' do
      it 'combines the path and suffix' do
        path = Path.new(nil, nil, {})
        allow(path).to receive(:path) { '/the/path' }
        allow(path).to receive(:suffix) { 'suffix' }

        expect(path.path_with_suffix).to eql('/the/pathsuffix')
      end

      context 'when using a specific format' do
        it 'might have a suffix with specified format' do
          path = Path.new(nil, nil, {})
          allow(path).to receive(:path) { '/the/path' }
          allow(path).to receive(:uses_specific_format?) { true }
          allow(path).to receive(:settings) { { format: :json } }

          expect(path.path_with_suffix).to eql('/the/path(.json)')
        end
      end
    end
  end
end
