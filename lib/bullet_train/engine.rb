module BulletTrain
  class Engine < ::Rails::Engine
    initializer "i18n.introspection" do
      unless Rails.env.production?
        require "bullet_train/i18n/introspection"
        ActiveSupport.on_load(:action_view) { include BulletTrain::I18n::Introspection }
      end
    end
  end
end
