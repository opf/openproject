# frozen_string_literal: true

require 'spec_helper'

module Grape
  module DSL
    module DescSpec
      class Dummy
        extend Grape::DSL::Desc
      end
    end
    describe Desc do
      subject { Class.new(DescSpec::Dummy) }

      describe '.desc' do
        it 'sets a description' do
          desc_text = 'The description'
          options = { message: 'none' }
          subject.desc desc_text, options
          expect(subject.namespace_setting(:description)).to eq(options.merge(description: desc_text))
          expect(subject.route_setting(:description)).to eq(options.merge(description: desc_text))
        end

        it 'can be set with a block' do
          expected_options = {
            summary: 'summary',
            description: 'The description',
            detail: 'more details',
            params: { first: :param },
            entity: Object,
            http_codes: [[401, 'Unauthorized', 'Entities::Error']],
            named: 'My named route',
            body_name: 'My body name',
            headers: [
              XAuthToken: {
                description: 'Valdates your identity',
                required: true
              },
              XOptionalHeader: {
                description: 'Not really needed',
                required: false
              }
            ],
            hidden: false,
            deprecated: false,
            is_array: true,
            nickname: 'nickname',
            produces: %w[array of mime_types],
            consumes: %w[array of mime_types],
            tags: %w[tag1 tag2],
            security: %w[array of security schemes]
          }

          subject.desc 'The description' do
            summary 'summary'
            detail 'more details'
            params(first: :param)
            success Object
            failure [[401, 'Unauthorized', 'Entities::Error']]
            named 'My named route'
            body_name 'My body name'
            headers [
              XAuthToken: {
                description: 'Valdates your identity',
                required: true
              },
              XOptionalHeader: {
                description: 'Not really needed',
                required: false
              }
            ]
            hidden false
            deprecated false
            is_array true
            nickname 'nickname'
            produces %w[array of mime_types]
            consumes %w[array of mime_types]
            tags %w[tag1 tag2]
            security %w[array of security schemes]
          end

          expect(subject.namespace_setting(:description)).to eq(expected_options)
          expect(subject.route_setting(:description)).to eq(expected_options)
        end

        it 'can be set with options and a block' do
          expect(subject).to receive(:warn).with('[DEPRECATION] Passing a options hash and a block to `desc` is deprecated. Move all hash options to block.')

          desc_text = 'The description'
          detail_text = 'more details'
          options = { message: 'none' }
          subject.desc desc_text, options do
            detail detail_text
          end
          expect(subject.namespace_setting(:description)).to eq(description: desc_text, detail: detail_text)
          expect(subject.route_setting(:description)).to eq(description: desc_text, detail: detail_text)
        end
      end
    end
  end
end
