module Account::LocaleHelper
  def current_locale
    current_user&.locale || current_team&.locale || "en"
  end

  # as of now, we only calculate a possessive version of nouns in english.
  # if you're aware of another language where we can do this, please don't hesitate to reach out!
  def possessive_string(string)
    [:en].include?(I18n.locale) ? string.possessive : string
  end

  def model_locales(model)
    name = model.label_string.presence
    return {} unless name

    {"#{model.model_name.element}_name": name, "#{model.model_name.collection}_possessive": possessive_string(name)}
  end

  def models_locales(*models)
    models.map { model_locales(_1) if _1 }.compact.inject(:merge!)
  end

  def translate(key, **options)
    # this is a bit scary, no?
    if controller.class.name.start_with?("Account::")
      options = options.with_defaults models_locales(@child_object, @parent_object)
    end

    super(key, **options)
  end

  # like 'translate', but if the key isn't found, it returns nil.
  def otranslate(key, **options)
    translate(key, **options)
  rescue I18n::MissingTranslationData => _
    nil
  end
  alias_method :ot, :otranslate
end
