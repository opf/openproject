# -*- encoding:  utf-8 -*-
require 'helper'

I18n.load_path << File.join(File.dirname(__FILE__), 'fixtures', 'locales', 'pt.yml')

describe "I18n" do
  describe "when the locale is pt" do
    before do
      I18n.locale = :pt
    end

    after do
      I18n.locale = :en
    end

    it "should translate to segundo" do
      assert_equal "segundo", Duration.new(:second => 1).format("%~s")
    end

    it "should translate to segundos" do
      assert_equal "segundos", Duration.new.format("%~s")
    end

    it "should translate to minuto" do
      assert_equal "minuto", Duration.new(:minute => 1).format("%~m")
    end

    it "should translate to minutos" do
      assert_equal "minutos", Duration.new.format("%~m")
    end

    it "should translate to hora" do
      assert_equal "hora", Duration.new(:hour => 1).format("%~h")
    end

    it "should translate to horas" do
      assert_equal "horas", Duration.new.format("%~h")
    end

    it "should translate to dia" do
      assert_equal "dia", Duration.new(:day => 1).format("%~d")
    end

    it "should translate to dias" do
      assert_equal "dias", Duration.new.format("%~d")
    end

    it "should translate to semana" do
      assert_equal "semana", Duration.new(:week => 1).format("%~w")
    end

    it "should translate to semanas" do
      assert_equal "semanas", Duration.new.format("%~w")
    end
  end
end
