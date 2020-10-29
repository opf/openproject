# frozen_string_literal: true

require 'spec_helper'
module Grape
  module Util
    describe 'StrictHashConfiguration' do
      subject do
        Class.new do
          include Grape::Util::StrictHashConfiguration.module(:config1, :config2, config3: [:config4], config5: [config6: %i[config7 config8]])
        end
      end

      it 'set nested configs' do
        subject.configure do
          config1 'alpha'
          config2 'beta'

          config3 do
            config4 'gamma'
          end

          local_var = 8

          config5 do
            config6 do
              config7 7
              config8 local_var
            end
          end
        end

        expect(subject.settings).to eq(config1: 'alpha',
                                       config2: 'beta',
                                       config3: { config4: 'gamma' },
                                       config5: { config6: { config7: 7, config8: 8 } })
      end
    end
  end
end
