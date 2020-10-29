# frozen_string_literal: true

require 'spec_helper'
require 'pathname'

describe Prawn::FontMetricCache do
  let(:document) { Prawn::Document.new }
  let(:font_metric_cache) { described_class.new(document) }

  it 'starts with an empty cache' do
    expect(font_metric_cache.instance_variable_get(:@cache)).to be_empty
  end

  it 'caches the width of the provided string' do
    font_metric_cache.width_of('M', {})

    expect(font_metric_cache.instance_variable_get(:@cache).size).to eq(1)
  end

  it 'onlies cache a single copy of the same string' do
    font_metric_cache.width_of('M', {})
    font_metric_cache.width_of('M', {})

    expect(font_metric_cache.instance_variable_get(:@cache).size).to eq(1)
  end

  it 'caches different copies for different strings' do
    font_metric_cache.width_of('M', {})
    font_metric_cache.width_of('W', {})

    expect(font_metric_cache.instance_variable_get(:@cache).entries.size)
      .to eq 2
  end

  it 'caches different copies of the same string with different font sizes' do
    font_metric_cache.width_of('M', {})

    document.font_size 24
    font_metric_cache.width_of('M', {})

    expect(font_metric_cache.instance_variable_get(:@cache).entries.size)
      .to eq 2
  end

  it 'caches different copies of the same string with different fonts' do
    font_metric_cache.width_of('M', {})

    document.font 'Courier'
    font_metric_cache.width_of('M', {})

    expect(font_metric_cache.instance_variable_get(:@cache).entries.size)
      .to eq 2
  end
end
