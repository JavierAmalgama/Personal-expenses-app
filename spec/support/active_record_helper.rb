module ActiveRecordHelper
	def invalid_id_for(klass)
		(klass.last&.id || 0) + 1
	end
end
