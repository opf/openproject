# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Exports::PDF::Common::View
  include Prawn::View
  include Redmine::I18n

  CUSTOM_FONT_NAME = "CustomFont"
  FONT_SPEC = {
    latin: [
      { name: "NotoSans", path: "noto" }
    ],
    mono: [
      { name: "SpaceMono", path: "spacemono" }
    ],
    fonts: [
      { name: "GoNotoKurrent", path: "noto-kurrent" }
    ],
    symbols: [
      { name: "NotoEmoji", path: "noto-emoji" },
      { name: "NotoSansSymbols2", path: "noto-symbols" },
      { name: "GoNotoAncient", path: "noto-ancient" }
    ]
  }.freeze

  def initialize(lang)
    set_language_if_valid lang
  end

  def self.default_font
    valid_custom_font? ? CUSTOM_FONT_NAME : FONT_SPEC[:latin].first[:name]
  end

  def self.valid_custom_font?
    cs = CustomStyle.current
    return false if cs.blank?

    valid_custom_font_cut?(cs.export_font_regular) &&
      valid_optional_custom_font_cut?(cs.export_font_bold) &&
      valid_optional_custom_font_cut?(cs.export_font_italic) &&
      valid_optional_custom_font_cut?(cs.export_font_bold_italic)
    # Something in the remote storage failed. Log, but do not stop PDF generation
  rescue StandardError => e
    Rails.logger.error "Failed to apply custom PDF font to export: #{e.message}:\n#{e.backtrace.join("\n")}"
    false
  end

  def self.valid_custom_font_cut?(cut)
    cut.present? && cut.local_file.present?
  end

  def self.valid_optional_custom_font_cut?(cut)
    cut.blank? || cut.local_file.present?
  end

  def options
    @options ||= {}
  end

  def info
    @info ||= {
      Creator: OpenProject::Info.app_name,
      CreationDate: Time.zone.now
    }
  end

  def document
    @document ||= Prawn::Document.new(options.merge(info:)).tap do |document|
      register_fonts! document

      document.set_font document.font(Exports::PDF::Common::View::default_font)
      document.fallback_fonts = fallback_fonts
    end
  end

  def fallback_fonts
    FONT_SPEC[:fonts].pluck(:name).concat fallback_symbol_fonts
  end

  def fallback_symbol_fonts
    FONT_SPEC[:symbols].map do |symbol|
      font_base_path.join(symbol[:path], "#{symbol[:name]}.ttf")
    end
  end

  def register_fonts!(document)
    register_custom_font!(document) if Exports::PDF::Common::View.valid_custom_font?
    register_font_group!(:latin, :register_full_font!, document)
    register_font_group!(:fonts, :register_base_font!, document)
    register_font_group!(:mono, :register_full_font!, document)
  end

  def register_font_group!(group, strategy, document)
    FONT_SPEC[group].each do |font|
      path = font_base_path.join(font[:path])
      public_send(strategy, font[:name], path, document)
    end
  end

  def style_entry(name, file, suffix)
    { file: file, font: "#{name}-#{suffix}" }
  end

  def font_or_default(cut, default)
    cut.present? && cut.local_file.present? ? cut.local_file : default
  end

  def custom_font_files
    cs = CustomStyle.current
    default = cs.export_font_regular.local_file
    {
      normal: default,
      bold: font_or_default(cs.export_font_bold, default),
      italic: font_or_default(cs.export_font_italic, default),
      bold_italic: font_or_default(cs.export_font_bold_italic,
                                   font_or_default(cs.export_font_bold,
                                                   font_or_default(cs.export_font_italic, default)))
    }.compact
  end

  STYLE_SUFFIX = {
    normal: "Regular",
    italic: "Italic",
    bold: "Bold",
    bold_italic: "BoldItalic"
  }.freeze

  def register_custom_font!(document)
    register_font_family!(CUSTOM_FONT_NAME, custom_font_files, document)
  end

  def register_base_font!(family, font_path, document)
    register_font_family!(family, resolved_font_files(family, font_path, variant: :base), document)
  end

  def register_full_font!(family, font_path, document)
    register_font_family!(family, resolved_font_files(family, font_path, variant: :full), document)
  end

  def register_font_family!(name, files_by_style, document)
    document.font_families[name] = STYLE_SUFFIX.each_with_object({}) do |(style, suffix), acc|
      acc[style] = style_entry(name, files_by_style.fetch(style), suffix)
    end
  end

  def resolved_font_files(family, font_path, variant:)
    # For base fonts, italic uses Regular, bold_italic uses Bold.
    file_suffix = {
      normal: "Regular",
      italic: (variant == :full ? "Italic" : "Regular"),
      bold: "Bold",
      bold_italic: (variant == :full ? "BoldItalic" : "Bold")
    }
    file_suffix.transform_values { |suffix| font_path.join("#{family}-#{suffix}.ttf") }
  end

  def title=(title)
    info[:Title] = title
  end

  def title
    info[:Title]
  end

  def apply_font(name: nil, font_style: nil, size: nil)
    name ||= document.font.basename.split("-").first # e.g. NotoSans-Bold => NotoSans
    font_opts = {}
    font_opts[:style] = font_style if font_style

    document.font name, font_opts
    document.font_size size if size

    document.font
  end

  private

  def font_base_path
    Rails.public_path.join("fonts")
  end
end
