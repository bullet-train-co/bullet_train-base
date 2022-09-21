module StrongParamsHelper
  def self.strong_parameters_from_api(controller_name)
    (controller_name.to_s.gsub(/^Account::/, "Api::#{BulletTrain::Api.current_version.upcase}::") + "::StrongParameters").constantize
  end
end
