# name: discourse-legal-tools
# about: Tools to help with legal compliance when using Discourse
# version: 0.1
# author: Angus McLeod

register_asset 'stylesheets/legal.scss'

after_initialize do
  module ::DiscourseLegal
    class Engine < ::Rails::Engine
      engine_name 'discourse_legal'
      isolate_namespace DiscourseLegal
    end
  end

  DiscourseLegal::Engine.routes.draw do
    get '' => 'admin#index'
    get 'digest' => 'admin#index'
    post 'digest/opt-in' => 'admin#digest_opt_in'
    post 'digest/unsubscribe' => 'admin#digest_unsubscribe'
  end

  Discourse::Application.routes.append do
    post "email/digest-opt-in/:key" => "email#digest_opt_in"

    namespace :admin, constraints: AdminConstraint.new do
      mount ::DiscourseLegal::Engine, at: 'legal'
    end
  end

  load File.expand_path('../controllers/legal.rb', __FILE__)
  load File.expand_path('../jobs/digest_opt_in.rb', __FILE__)
  load File.expand_path('../jobs/digest_unsubscribe.rb', __FILE__)
  load File.expand_path('../lib/export_csv_file_extension.rb', __FILE__)
  load File.expand_path('../lib/digest_opt_in_extension.rb', __FILE__)

  Rails.configuration.paths['app/views'].unshift(Rails.root.join('plugins', 'discourse-legal-tools', 'app/views'))
end
