appraise "rails-4-2" do
  group :mysql do
    gem "mysql2", "~> 0.4.0"
  end
  group :postgresql do
    gem "pg", "~> 0.18.4"
  end
  group :test do
    gem "test_after_commit", "~> 0.4.2"
  end
  gem "activerecord", "~> 4.2.0"
end

appraise "rails-5-0" do
  gem "activerecord", "~> 5.0.0"
end

appraise "rails-5-1" do
  gem "activerecord", "~> 5.1.0"
end

appraise "rails-5-2" do
  gem "activerecord", "~> 5.2.0"
end

appraise "rails-6-0" do
  group :sqlite do
    gem "sqlite3", "~> 1.4"
  end
  gem "activerecord", "~> 6.0.0"
end
