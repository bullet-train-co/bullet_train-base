module Users::Base
  extend ActiveSupport::Concern

  included do
    if two_factor_authentication_enabled?
      devise :two_factor_authenticatable, :two_factor_backupable, otp_secret_encryption_key: ENV["TWO_FACTOR_ENCRYPTION_KEY"]
    else
      devise :database_authenticatable
    end

    devise :omniauthable
    devise :pwned_password
    devise :registerable
    devise :recoverable
    devise :rememberable
    devise :trackable
    devise :validatable

    # teams
    has_many :memberships, dependent: :destroy
    has_many :scaffolding_absolutely_abstract_creative_concepts_collaborators, through: :memberships
    has_many :teams, through: :memberships
    has_many :collaborating_users, through: :teams, source: :users
    belongs_to :current_team, class_name: "Team", optional: true
    accepts_nested_attributes_for :current_team

    # oauth providers
    has_many :oauth_stripe_accounts, class_name: "Oauth::StripeAccount" if stripe_enabled?

    # platform functionality.
    belongs_to :platform_agent_of, class_name: "Platform::Application", optional: true

    # validations
    validate :real_emails_only
    validates :time_zone, inclusion: {in: ActiveSupport::TimeZone.all.map(&:name)}, allow_nil: true

    # callbacks
    after_update :set_teams_time_zone
  end

  def email_is_oauth_placeholder?
    !!email.match(/noreply@\h{32}\.example\.com/)
  end

  def label_string
    name
  end

  def name
    full_name.present? ? full_name : email
  end

  def full_name
    [first_name_was, last_name_was].select(&:present?).join(" ")
  end

  def details_provided?
    first_name.present? && last_name.present? && current_team.name.present?
  end

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end

  def create_default_team
    # This creates a `Membership`, because `User` `has_many :teams, through: :memberships`
    default_team = teams.create(name: I18n.t("teams.new.default_team_name"), time_zone: time_zone)
    memberships.find_by(team: default_team).update role_ids: [Role.admin.id]
    update(current_team: default_team)
  end

  def real_emails_only
    if ENV["REALEMAIL_API_KEY"] && !Rails.env.test?
      uri = URI("https://realemail.expeditedaddons.com")

      # Change the input parameters here
      uri.query = URI.encode_www_form({
        api_key: ENV["REAL_EMAIL_KEY"],
        email: email,
        fix_typos: false
      })

      # Results are returned as a JSON object
      result = JSON.parse(Net::HTTP.get_response(uri).body)

      if result["syntax_error"]
        errors.add(:email, "is not a valid email address")
      elsif result["domain_error"] || (result.key?("mx_records_found") && !result["mx_records_found"])
        errors.add(:email, "can't actually receive emails")
      elsif result["is_disposable"]
        errors.add(:email, "is a disposable email address")
      end
    end
  end

  def multiple_teams?
    teams.count > 1
  end

  def one_team?
    !multiple_teams?
  end

  def formatted_email_address
    if details_provided?
      "\"#{first_name} #{last_name}\" <#{email}>"
    else
      email
    end
  end

  def administrating_team_ids
    parent_ids_for(Role.admin, :memberships, :team)
  end

  def parent_ids_for(role, through, parent)
    parent_id_column = "#{parent}_id"
    key = "#{role.key}_#{through}_#{parent_id_column}s"
    return ability_cache[key] if ability_cache && ability_cache[key]
    role = nil if role.default?
    value = send(through).with_role(role).distinct.pluck(parent_id_column)
    current_cache = ability_cache || {}
    current_cache[key] = value
    update_column :ability_cache, current_cache
    value
  end

  def invalidate_ability_cache
    update_column(:ability_cache, {})
  end

  def otp_qr_code
    issuer = I18n.t("application.name")
    label = "#{issuer}:#{email}"
    RQRCode::QRCode.new(otp_provisioning_uri(label, issuer: issuer))
  end

  # From https://github.com/tinfoil/devise-two-factor/blob/main/UPGRADING.md
  # Decrypt and return the `encrypted_otp_secret` attribute which was used in
  # prior versions of devise-two-factor
  def legacy_otp_secret
    return nil unless self[:encrypted_otp_secret]
    return nil unless self.class.otp_secret_encryption_key

    hmac_iterations = 2000 # a default set by the Encryptor gem
    key = self.class.otp_secret_encryption_key
    salt = Base64.decode64(encrypted_otp_secret_salt)
    iv = Base64.decode64(encrypted_otp_secret_iv)

    raw_cipher_text = Base64.decode64(encrypted_otp_secret)
    # The last 16 bytes of the ciphertext are the authentication tag - we use
    # Galois Counter Mode which is an authenticated encryption mode
    cipher_text = raw_cipher_text[0..-17]
    auth_tag =  raw_cipher_text[-16..-1]

    # this alrorithm lifted from
    # https://github.com/attr-encrypted/encryptor/blob/master/lib/encryptor.rb#L54

    # create an OpenSSL object which will decrypt the AES cipher with 256 bit
    # keys in Galois Counter Mode (GCM). See
    # https://ruby.github.io/openssl/OpenSSL/Cipher.html
    cipher = OpenSSL::Cipher.new('aes-256-gcm')

    # tell the cipher we want to decrypt. Symmetric algorithms use a very
    # similar process for encryption and decryption, hence the same object can
    # do both.
    cipher.decrypt

    # Use a Password-Based Key Derivation Function to generate the key actually
    # used for encryptoin from the key we got as input.
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(key, salt, hmac_iterations, cipher.key_len)

    # set the Initialization Vector (IV)
    cipher.iv = iv

    # The tag must be set after calling Cipher#decrypt, Cipher#key= and
    # Cipher#iv=, but before calling Cipher#final. After all decryption is
    # performed, the tag is verified automatically in the call to Cipher#final.
    #
    # If the auth_tag does not verify, then #final will raise OpenSSL::Cipher::CipherError
    cipher.auth_tag = auth_tag

    # auth_data must be set after auth_tag has been set when decrypting See
    # http://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html#method-i-auth_data-3D
    # we are not adding any authenticated data but OpenSSL docs say this should
    # still be called.
    cipher.auth_data = ''

    # #update is (somewhat confusingly named) the method which actually
    # performs the decryption on the given chunk of data. Our OTP secret is
    # short so we only need to call it once.
    #
    # It is very important that we call #final because:
    #
    # 1. The authentication tag is checked during the call to #final
    # 2. Block based cipher modes (e.g. CBC) work on fixed size chunks. We need
    #    to call #final to get it to process the last chunk properly. The output
    #    of #final should be appended to the decrypted value. This isn't
    #    required for streaming cipher modes but including it is a best practice
    #    so that your code will continue to function correctly even if you later
    #    change to a block cipher mode.
    cipher.update(cipher_text) + cipher.final
  end

  def scaffolding_absolutely_abstract_creative_concepts_collaborators
    Scaffolding::AbsolutelyAbstract::CreativeConcepts::Collaborator.joins(:membership).where(membership: {user_id: id})
  end

  def admin_scaffolding_absolutely_abstract_creative_concepts_ids
    scaffolding_absolutely_abstract_creative_concepts_collaborators.admins.pluck(:creative_concept_id)
  end

  def editor_scaffolding_absolutely_abstract_creative_concepts_ids
    scaffolding_absolutely_abstract_creative_concepts_collaborators.editors.pluck(:creative_concept_id)
  end

  def viewer_scaffolding_absolutely_abstract_creative_concepts_ids
    scaffolding_absolutely_abstract_creative_concepts_collaborators.viewers.pluck(:creative_concept_id)
  end

  def developer?
    return false unless ENV["DEVELOPER_EMAILS"]
    # we use email_was so they can't try setting their email to the email of an admin.
    return false unless email_was
    ENV["DEVELOPER_EMAILS"].split(",").include?(email_was)
  end

  def set_teams_time_zone
    teams.where(time_zone: nil).each do |team|
      team.update(time_zone: time_zone) if team.users.count == 1
    end
  end
end
