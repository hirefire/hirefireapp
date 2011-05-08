# encoding: utf-8

module HireFireApp
  class Railtie < ::Rails::Railtie
    initializer 'hirefireapp.add_middleware' do |app|
      app.config.middleware.use 'HireFireApp::Middleware'
    end
  end
end
