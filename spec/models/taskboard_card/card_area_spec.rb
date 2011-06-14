require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe TaskboardCard::CardArea do
  let(:pdf) { Prawn::Document.new(:margin => 0) }

  let(:options) do
    {
      :width => 120.0,
      :height => 12,
      :size => 12,
      :at => [0, 0],
      :single_line => true
    }
  end

  describe '.text_box' do
    it 'shortens long texts' do
      box = TaskboardCard::CardArea.text_box(pdf,
                                             'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                                             options)

      text = PDF::Inspector::Text.analyze(pdf.render)

      text.strings.join.should == 'Lorem ipsum dolor[...]'
    end

    it 'does not shorten short texts' do
      box = TaskboardCard::CardArea.text_box(pdf, 'Lorem ipsum', options)

      text = PDF::Inspector::Text.analyze(pdf.render)

      text.strings.join.should == 'Lorem ipsum'
    end

    it 'handles multibyte characters gracefully' do
      box = TaskboardCard::CardArea.text_box(pdf,
                                             'Lörëm ïpsüm dölör sït ämët, cönsëctëtür ädïpïscïng ëlït.',
                                             options)

      text = PDF::Inspector::Text.analyze(pdf.render)

      text.strings.join.should == 'Lörëm ïpsüm dölör[...]'
    end
  end
end
