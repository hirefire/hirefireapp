# encoding: utf-8

Gem::Specification.new do |gem|

  # General configuration / information
  gem.name        = 'hirefireapp'
  gem.version     = '0.1.1'
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = 'Michael van Rooijen'
  gem.email       = 'michael@hirefire.io'
  gem.homepage    = 'http://hirefire.io/'
  gem.summary     = %|HireFire.io - The Heroku Dyno Manager - Autoscaling your web and worker dynos!|
  gem.description = %|HireFire.io - The Heroku Dyno Manager - Autoscaling your web and worker dynos saving you time and money!|

  # Files and folder that need to be compiled in to the Ruby Gem
  gem.files         = %x[git ls-files].split("\n")
  gem.executables   = ['hirefireapp']
  gem.require_path  = 'lib'
end

