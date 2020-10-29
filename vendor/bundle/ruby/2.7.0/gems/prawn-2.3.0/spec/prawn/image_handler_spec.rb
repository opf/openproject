# frozen_string_literal: true

require 'spec_helper'

describe Prawn::ImageHandler do
  let(:image_handler) { described_class.new }

  let(:handler_a) { instance_double('Handler A') }
  let(:handler_b) { instance_double('Handler B') }

  it 'finds the image handler for an image' do
    allow(handler_a).to receive(:can_render?).and_return(true)

    image_handler.register(handler_a)
    image_handler.register(handler_b)

    handler = image_handler.find('arbitrary blob')
    expect(handler).to eq(handler_a)
  end

  it 'can prepend handlers' do
    allow(handler_b).to receive(:can_render?).and_return(true)

    image_handler.register(handler_a)
    image_handler.register!(handler_b)

    handler = image_handler.find('arbitrary blob')
    expect(handler).to eq(handler_b)
  end

  it 'can unregister a handler' do
    allow(handler_b).to receive(:can_render?).and_return(true)

    image_handler.register(handler_a)
    image_handler.register(handler_b)

    image_handler.unregister(handler_a)

    handler = image_handler.find('arbitrary blob')
    expect(handler).to eq(handler_b)
  end

  it 'raises an error when no matching handler is found' do
    allow(handler_a).to receive(:can_render?).and_return(false)
    allow(handler_b).to receive(:can_render?).and_return(false)

    image_handler.register(handler_a)
    image_handler.register(handler_b)

    expect { image_handler.find('arbitrary blob') }
      .to(raise_error(Prawn::Errors::UnsupportedImageType))
  end
end
