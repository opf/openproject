# frozen_string_literal: true

require 'spec_helper'

describe Grape::Xml do
  it 'uses multi_xml' do
    expect(Grape::Xml).to eq(::MultiXml)
  end
end
