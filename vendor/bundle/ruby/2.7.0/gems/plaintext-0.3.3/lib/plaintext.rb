# frozen_string_literal: true

require 'active_support/core_ext/string'

require 'plaintext/version'
require 'plaintext/configuration'

require 'plaintext/codeset_util'

require 'plaintext/file_handler'
require 'plaintext/file_handler/external_command_handler'
require 'plaintext/file_handler/external_command_handler/doc_handler'
require 'plaintext/file_handler/external_command_handler/image_handler'
require 'plaintext/file_handler/external_command_handler/pdf_handler'
require 'plaintext/file_handler/external_command_handler/ppt_handler'
require 'plaintext/file_handler/external_command_handler/rtf_handler'
require 'plaintext/file_handler/external_command_handler/xls_handler'

require 'plaintext/file_handler/zipped_xml_handler'
require 'plaintext/file_handler/zipped_xml_handler/office_document_handler'
require 'plaintext/file_handler/zipped_xml_handler/office_document_handler/docx_handler'
require 'plaintext/file_handler/zipped_xml_handler/office_document_handler/pptx_handler'
require 'plaintext/file_handler/zipped_xml_handler/office_document_handler/xlsx_handler'
require 'plaintext/file_handler/zipped_xml_handler/opendocument_handler'

require 'plaintext/file_handler/plaintext_handler'

require 'plaintext/resolver'
