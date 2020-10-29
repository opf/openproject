# frozen_string_literal: true

require 'spec_helper'

describe Grape::Middleware::Versioner do
  let(:klass) { Grape::Middleware::Versioner }

  it 'recognizes :path' do
    expect(klass.using(:path)).to eq(Grape::Middleware::Versioner::Path)
  end

  it 'recognizes :header' do
    expect(klass.using(:header)).to eq(Grape::Middleware::Versioner::Header)
  end

  it 'recognizes :param' do
    expect(klass.using(:param)).to eq(Grape::Middleware::Versioner::Param)
  end

  it 'recognizes :accept_version_header' do
    expect(klass.using(:accept_version_header)).to eq(Grape::Middleware::Versioner::AcceptVersionHeader)
  end
end
