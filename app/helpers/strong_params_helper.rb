module StrongParamsHelper
  def self.strong_parameters_from_api(controller_name, api_version)
    (controller_name.to_s.gsub(/^Account::/, "Api::#{api_version.upcase}::") + "::StrongParameters").constantize
  end
end
