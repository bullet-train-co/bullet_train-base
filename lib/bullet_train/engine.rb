module BulletTrain
  class Engine < ::Rails::Engine
    initializer "i18n.introspection" do
      unless Rails.env.production?
        ActiveSupport.on_load :action_view do
          require "bullet_train/i18n/introspection"
          helpers.include BulletTrain::I18n::Introspection
        end
      end
    end
  end
end
