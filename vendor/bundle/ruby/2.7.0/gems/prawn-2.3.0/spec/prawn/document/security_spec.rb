# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

describe Prawn::Document::Security do
  describe 'Password padding' do
    include described_class

    it 'truncates long passwords' do
      pw = 'Long long string' * 30
      padded = pad_password(pw)
      expect(padded.length).to eq(32)
      expect(padded).to eq(pw[0, 32])
    end

    it 'pads short passwords' do
      pw = 'abcd'
      padded = pad_password(pw)
      expect(padded.length).to eq(32)
      expect(padded).to eq(
        pw + Prawn::Document::Security::PASSWORD_PADDING[0, 28]
      )
    end

    it 'fullies pad null passwords' do
      pw = ''
      padded = pad_password(pw)
      expect(padded.length).to eq(32)
      expect(padded).to eq(Prawn::Document::Security::PASSWORD_PADDING)
    end
  end

  describe 'Setting permissions' do
    def doc_with_permissions(permissions)
      pdf = Prawn::Document.new

      # Make things easier to test
      pdf.singleton_class.send :public, :permissions_value
      # class << pdf
      #   public :permissions_value
      # end

      pdf.encrypt_document(permissions: permissions)
      pdf
    end

    it 'defaults to full permissions' do
      expect(doc_with_permissions({}).permissions_value).to eq(0xFFFFFFFF)
      expect(doc_with_permissions(
        print_document: true,
        modify_contents: true,
        copy_contents: true,
        modify_annotations: true
      ).permissions_value)
        .to eq(0xFFFFFFFF)
    end

    it 'clears the appropriate bits for each permission flag' do
      expect(doc_with_permissions(print_document: false).permissions_value)
        .to eq(0b1111_1111_1111_1111_1111_1111_1111_1011)
      expect(doc_with_permissions(modify_contents: false).permissions_value)
        .to eq(0b1111_1111_1111_1111_1111_1111_1111_0111)
      expect(doc_with_permissions(copy_contents: false).permissions_value)
        .to eq(0b1111_1111_1111_1111_1111_1111_1110_1111)
      expect(doc_with_permissions(modify_annotations: false).permissions_value)
        .to eq(0b1111_1111_1111_1111_1111_1111_1101_1111)
    end

    it 'raise_errors ArgumentError if invalid option is provided' do
      expect do
        doc_with_permissions(modify_document: false)
      end.to raise_error(ArgumentError)
    end
  end

  describe 'Encryption keys' do
    # Since PDF::Reader doesn't read encrypted PDF files, we just take the
    # roundabout method of verifying each step of the encryption. This works
    # fine because the encryption method is deterministic.

    let(:pdf) do
      Prawn::Document.new do |pdf|
        class << pdf
          public :owner_password_hash, :user_password_hash, :user_encryption_key
        end
        pdf.encrypt_document(
          user_password: 'foo',
          owner_password: 'bar',
          permissions: { print_document: false }
        )
      end
    end

    it 'calculates the correct owner hash' do
      expect(pdf.owner_password_hash.unpack1('H*'))
        .to match(/^61CA855012/i)
    end

    it 'calculates the correct user hash' do
      expect(pdf.user_password_hash.unpack1('H*'))
        .to match(/^6BC8C51031/i)
    end

    it 'calculates the correct user_encryption_key' do
      expect(pdf.user_encryption_key.unpack1('H*').upcase)
        .to eq('B100AB6429')
    end
  end

  describe 'encrypted_pdf_object' do
    it 'delegates to PdfObject for simple types' do
      expect(PDF::Core.encrypted_pdf_object(true, nil, nil, nil)).to eq('true')
      expect(PDF::Core.encrypted_pdf_object(42, nil, nil, nil)).to eq('42')
    end

    it 'encrypts strings properly' do
      expect(PDF::Core.encrypted_pdf_object('foo', '12345', 123, 0))
        .to eq('<4ad6e3>')
    end

    it 'encrypts literal strings properly' do
      expect(PDF::Core.encrypted_pdf_object(
        PDF::Core::LiteralString.new('foo'), '12345', 123, 0
      )).to eq(bin_string("(J\xD6\xE3)"))
      expect(PDF::Core.encrypted_pdf_object(
        PDF::Core::LiteralString.new('lhfbqg3do5u0satu3fjf'), nil, 123, 0
      )).to eq(bin_string(
        "(\xF1\x8B\\(\b\xBB\xE18S\x130~4*#\\(%\x87\xE7\x8E\\\n)"
      ))
    end

    it 'encrypts time properly' do
      expect(PDF::Core.encrypted_pdf_object(
        Time.utc(2050, 0o4, 26, 10, 17, 10), '12345', 123, 0
      )).to eq(bin_string(
        "(h\x83\xBE\xDC\xEC\x99\x0F\xD7\\)%\x13\xD4$\xB8\xF0\x16\xB8\x80\xC5"\
        "\xE91+\xCF)"
      ))
    end

    it 'properlies handle compound types' do
      expect(PDF::Core.encrypted_pdf_object({ Bar: 'foo' }, '12345', 123, 0))
        .to eq(
          "<< /Bar <4ad6e3>\n>>"
        )
      expect(PDF::Core.encrypted_pdf_object(%w[foo bar], '12345', 123, 0))
        .to eq('[<4ad6e3> <4ed8fe>]')
    end
  end

  describe 'Reference#encrypted_object' do
    it 'encrypts references properly' do
      ref = PDF::Core::Reference.new(1, ['foo'])
      expect(ref.encrypted_object(nil)).to eq("1 0 obj\n[<4fca3f>]\nendobj\n")
    end

    it 'encrypts references with streams properly' do
      ref = PDF::Core::Reference.new(1, {})
      ref << 'foo'
      result = bin_string(
        "1 0 obj\n<< /Length 3\n>>\nstream\nO\xCA?\nendstream\nendobj\n"
      )
      expect(ref.encrypted_object(nil)).to eq(result)
    end
  end

  describe 'String#encrypted_object' do
    it 'encrypts stream properly' do
      stream = PDF::Core::Stream.new
      stream << 'foo'
      result = bin_string("stream\nO\xCA?\nendstream\n")
      expect(stream.encrypted_object(nil, 1, 0)).to eq(result)
    end
  end
end
