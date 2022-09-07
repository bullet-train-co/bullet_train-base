# frozen_string_literal: true

class String
  def possessive
    self + end_with?("s") ? "’" : "’s"
  end
end
