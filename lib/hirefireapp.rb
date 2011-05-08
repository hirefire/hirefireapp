# encoding: utf-8

HIREFIRE_APP_PATH = File.expand_path('../hirefireapp', __FILE__)

# Load the HireFireApp middleware
require File.join(HIREFIRE_APP_PATH, 'middleware')

# If Rails::Railtie exists, then hook up HireFireApp automatically
if defined?(Rails::Railtie)
  require File.join(HIREFIRE_APP_PATH, 'railtie')
end

