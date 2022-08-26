module CurrentAttributes::Base
  extend ActiveSupport::Concern

  included do
    attribute :user, :team, :membership, :ability, :context

    resets do
      Time.zone = nil
    end
  end

  def user=(user)
    super

    if user
      Time.zone = user.time_zone
      self.ability = Ability.new(user)
    else
      Time.zone = nil
      self.ability = nil
    end

    update_membership
  end

  def team=(team)
    super
    update_membership
  end

  def update_membership
    self.membership = if user && team
      user.memberships.where(team: team)
    end
  end

  def directory_order
    default_directory_order = BulletTrain::Themes::Light::Theme.new.directory_order
    default_directory_order.unshift(current_theme.to_s).uniq
  end
end
