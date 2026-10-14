module Swagger
	DEFINITIONS_PATH = Rails.root.join('swagger', 'definitions')

	def swagger_definitions
		folder_definitions(DEFINITIONS_PATH).symbolize_keys
	end

private

	def folder_definitions(folder_path)
		definitions = {}
		Dir.foreach(folder_path) do |file_path|
			# skip if file is '.', '..' or is hidden
			next if file_path[0] == '.'

			# recursion if the element is a directory rather than a file
			if File.directory?("#{folder_path}/#{file_path}")
				definitions.merge! folder_definitions("#{folder_path}/#{file_path}")
				next
			end

			# add the file definition to all the definitions
			definitions.merge! file_definition(file_path)
		end
		definitions
	end

	def file_definition(model_path)
		key_name = model_path.chomp '.rb'
		object_definition = send "#{key_name}_definition"

		{ key_name => object_definition }
	end
end
