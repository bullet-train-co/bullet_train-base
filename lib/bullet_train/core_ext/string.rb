# frozen_string_literal: true

class String
  # Credit goes to the "possessive" gem
  # https://rubygems.org/gems/possessive/versions/1.0.1
  def possessive
    self + (end_with?("s") ? "’" : "’s")
  end
end
