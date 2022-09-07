module Account::LocaleHelper
  def current_locale
    current_user.locale || current_team.locale || "en"
  end

  # as of now, we only calculate a possessive version of nouns in english.
  # if you're aware of another language where we can do this, please don't hesitate to reach out!
  def possessive_string(string)
    [:en].include?(I18n.locale) ? string.possessive : string
  end

  def model_locales(model)
    name = model.label_string.presence
    return {} unless name

    { "#{model.model_name.element}_name": name, "#{model.model_name.collection}_possessive": possessive_string(name) }
  end

  def models_locales(*models)
    models.map { model_locales(_1) if _1 }.compact.inject(:merge!)
  end

  def translate(key, **options)
    # this is a bit scary, no?
    if controller.class.name.start_with?("Account::")
      options = options.with_defaults models_locales(@child_object, @parent_object)
    end

    full_translation_key = extract_full_translation_key_from(key, options) { super(_1, **_2) }

    super(key, **options).tap do |result|
      if !Rails.env.production? && params.present?
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

  # like 'translate', but if the key isn't found, it returns nil.
  def otranslate(key, **options)
    translate(key, **options)
  rescue I18n::MissingTranslationData => _
    nil
  end
  alias ot otranslate

  private

  # When bundled Ruby gems provide a lot of translations, it can be difficult to figure out which strings in the
  # application are coming from where. To help with this, you can add `?debug=true` to any URL and we'll output
  # any rendered strings and their translation keys on the console.
  def extract_full_translation_key_from(key, options)
    if !Rails.env.production? && params.present? && (params[:log_locales] || params[:show_locales])
      yield key + "💣", options.except(:default)
    end
  rescue I18n::MissingTranslationData => exception
    exception.message.rpartition(" ").last.delete("💣")
  end
end
