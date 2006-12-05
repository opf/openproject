# Copyright (c) 2005-2006 David Barri

module GLoc
  # These helper methods will be included in the InstanceMethods module.
  module Helpers
    def l_age(age)             lwr :general_fmt_age, age end
    def l_date(date)           l_strftime date, :general_fmt_date end
    def l_datetime(date)       l_strftime date, :general_fmt_datetime end
    def l_datetime_short(date) l_strftime date, :general_fmt_datetime_short end
    def l_strftime(date,fmt)   date.strftime l(fmt) end
    def l_time(time)           l_strftime time, :general_fmt_time end
    def l_YesNo(value)         l(value ? :general_text_Yes : :general_text_No) end
    def l_yesno(value)         l(value ? :general_text_yes : :general_text_no) end

    def l_lang_name(lang, display_lang=nil)
      ll display_lang || current_language, "general_lang_#{lang}"
    end

  end
end
