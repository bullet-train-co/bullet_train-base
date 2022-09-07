module BulletTrain::I18n; end
module BulletTrain::I18n::Introspection
  def translate(key, **options)
    full_translation_key = extract_full_translation_key_from(key, options) { super(_1, **_2) }

    super.tap do |result|
      if params.present?
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

    private

    # When bundled Ruby gems provide a lot of translations, it can be difficult to figure out which strings in the
    # application are coming from where. To help with this, you can add `?debug=true` to any URL and we'll output
    # any rendered strings and their translation keys on the console.
    def extract_full_translation_key_from(key, options)
      if params.present? && (params[:log_locales] || params[:show_locales])
        yield key + "💣", options.except(:default)
      end
    rescue I18n::MissingTranslationData => exception
      exception.message.rpartition(" ").last.delete("💣")
    end
  end
end
