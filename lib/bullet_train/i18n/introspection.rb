module BulletTrain::I18n; end
module BulletTrain::I18n::Introspection
  def translate(key, **options)
    return super unless params.present? # Mailers don't have params.

    # When bundled Ruby gems provide a lot of translations, it can be difficult to figure out which strings in the
    # application are coming from where. To help with this, you can add `?debug=true` to any URL and we'll output
    # any rendered strings and their translation keys on the console.
    if params[:log_locales] || params[:show_locales]
      begin
        super(key + "💣", **options.except(:default))
      rescue I18n::MissingTranslationData => exception
        full_translation_key = exception.message.rpartition(" ").last.delete("💣")
      end
    end

    super.tap do |result|
      if params[:log_locales]
        if result == options[:default]
          puts "🌐 #{full_translation_key}: Not found? Result matched default: \"#{result}\"".yellow
        else
          puts "🌐 #{full_translation_key}: \"#{result}\"".green
        end
      end

      return full_translation_key if params[:show_locales]
    end
  end
end
