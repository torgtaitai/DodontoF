source 'https://rubygems.org'

gem 'msgpack'

group :development, :test do
  if RUBY_VERSION < '1.9'
    gem 'rake', '~> 10.5'
    gem 'test-unit', '1.2.3'
  else
    gem 'rake'
    gem 'test-unit'
    gem 'rubyzip'
  end
end
