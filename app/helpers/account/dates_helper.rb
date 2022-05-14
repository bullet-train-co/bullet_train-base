module Account::DatesHelper
  # e.g. October 11, 2018
  def display_date(timestamp, custom_date_format)
    return nil unless timestamp
    if custom_date_format
      local_time(timestamp).strftime(custom_date_format)
    elsif local_time(timestamp).year == local_time(Time.now).year
      local_time(timestamp).strftime("%B %-d")
    else
      local_time(timestamp).strftime("%B %-d, %Y")
    end
  end

  # e.g. October 11, 2018 at 4:22 PM
  # e.g. Yesterday at 2:12 PM
  # e.g. April 24 at 7:39 AM
  def display_date_and_time(timestamp, custom_date_format, custom_time_format)
    return nil unless timestamp

    # today?
    if local_time(timestamp).to_date == local_time(Time.now).to_date
      "Today at #{display_time(timestamp, custom_time_format)}"
    # yesterday?
    elsif (local_time(timestamp).to_date) == (local_time(Time.now).to_date - 1.day)
      "Yesterday at #{display_time(timestamp, custom_time_format)}"
    else
      "#{display_date(timestamp, custom_date_format)} at #{display_time(timestamp, custom_time_format)}"
    end
  end

  # e.g. 4:22 PM
  def display_time(timestamp, custom_time_format)
    local_time(timestamp).strftime(custom_time_format || "%l:%M %p")
  end

  def local_time(time)
    return time if current_user.time_zone.nil?
    time.in_time_zone(current_user.time_zone)
  end
end
