module Blobs
	DISK_STORAGE_URL_REGEX = %r{/disk/(.*)-.*/(.*)}

	def expect_same_blob_urls(an_url, other_url)
		an_url_storage_key = an_url.match(DISK_STORAGE_URL_REGEX)[1]
		other_url_storage_key = other_url.match(DISK_STORAGE_URL_REGEX)[1]
		an_url_storage_key == other_url_storage_key
	end
end
