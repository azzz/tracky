source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.4'
gem 'pg', '~> 0.18'
gem 'puma', '~> 4.3'
gem 'cancancan', '~> 2.0'
gem 'knock'
gem 'bcrypt'

group :development, :test do
  gem 'pry'
  gem 'factory_girl_rails'
  gem 'ffaker'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rspec-rails', '~> 3.6'
end

group :test do
  gem 'database_cleaner'
  gem 'shoulda-matchers', '~> 3.1'
end
