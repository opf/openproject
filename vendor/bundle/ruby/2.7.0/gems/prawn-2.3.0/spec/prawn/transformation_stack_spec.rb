# frozen_string_literal: true

require 'spec_helper'

describe Prawn::TransformationStack do
  let(:pdf) do
    create_pdf do |document|
      document.add_to_transformation_stack(2, 0, 0, 2, 100, 100)
    end
  end
  let(:stack) { pdf.instance_variable_get(:@transformation_stack) }

  describe '#add_to_transformation_stack' do
    it 'creates and adds to the stack' do
      pdf.add_to_transformation_stack(1, 0, 0, 1, 20, 20)

      expect(stack).to eq [[[2, 0, 0, 2, 100, 100], [1, 0, 0, 1, 20, 20]]]
    end

    it 'adds to the last stack' do
      pdf.save_transformation_stack
      pdf.add_to_transformation_stack(1, 0, 0, 1, 20, 20)

      expect(stack).to eq [
        [[2, 0, 0, 2, 100, 100]],
        [[2, 0, 0, 2, 100, 100], [1, 0, 0, 1, 20, 20]]
      ]
    end
  end

  describe '#save_transformation_stack' do
    it 'clones the last stack' do
      pdf.save_transformation_stack

      expect(stack.length).to eq 2
      expect(stack.first).to eq stack.last
      expect(stack.first).to_not be stack.last
    end
  end

  describe '#restore_transformation_stack' do
    it 'pops off the last stack' do
      pdf.save_transformation_stack
      pdf.add_to_transformation_stack(1, 0, 0, 1, 20, 20)
      pdf.restore_transformation_stack

      expect(stack).to eq [[[2, 0, 0, 2, 100, 100]]]
    end
  end

  describe 'current_transformation_matrix_with_translation' do
    before do
      pdf.add_to_transformation_stack(1, 0, 0, 1, 20, 20)
    end

    it 'calculates the last transformation' do
      expect(pdf.current_transformation_matrix_with_translation)
        .to eq [2, 0, 0, 2, 140, 140]
    end

    it 'adds the supplied x and y coordinates to the transformation stack' do
      expect(pdf.current_transformation_matrix_with_translation(15, 15))
        .to eq [2, 0, 0, 2, 170, 170]
    end
  end
end
