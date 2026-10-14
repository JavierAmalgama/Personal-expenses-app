class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def serialize(options = {})
		ActiveModelSerializers::SerializableResource.new(self, options).as_json
	end
end
