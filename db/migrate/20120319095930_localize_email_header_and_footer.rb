# store email header and footer localized (take Setting.default_language first, then english)
class LocalizeEmailHeaderAndFooter < ActiveRecord::Migration
  def self.up
    emails_header = Setting.find_by_name 'emails_header'
    emails_footer = Setting.find_by_name 'emails_footer'
    
    default_language = Setting.default_language
    default_language = 'en' if default_language.blank?
    
    if emails_header
      translation = { default_language => emails_header.read_attribute(:value) }
      emails_header.write_attribute(:value, translation.to_yaml.to_s)
      emails_header.save!
    end

    if emails_footer
      translation = { default_language => emails_footer.read_attribute(:value) }
      emails_footer.write_attribute(:value, translation.to_yaml.to_s)
      emails_footer.save!
    end
  end

  def self.down
    emails_header = Setting.find_by_name 'emails_header'
    emails_footer = Setting.find_by_name 'emails_footer'
    
    default_language = Setting.default_language
    default_language = 'en' if default_language.blank?
    
    if emails_header
      translations = YAML::load(emails_header.read_attribute(:value))
      text = translations[default_language]
      text = translations.values.first if text.blank?
      # mimick Setting.value=
      emails_header.write_attribute(:value, text)
      emails_header.save!
    end

    if emails_footer
      translations = YAML::load(emails_footer.read_attribute(:value))
      text = translations[default_language]
      text = translations.values.first if text.blank?
      # mimick Setting.value=
      emails_footer.write_attribute(:value, text)
      emails_footer.save!
    end
  end   
end
