module Blobsterix
	class BlobApi < AppRouterBase
		include BlobUrlHelper

		get "/blob/v1", :function => :not_allowed
		get "/blob", :function => :not_allowed
		put "/blob/v1", :function => :not_allowed
		put "/blob", :function => :not_allowed

		get "/blob/v1/(:trafo.)*bucket_or_file.:format", :function => :get_file
		get "/blob/v1/(:trafo.)*bucket_or_file", :function => :get_file

		head "/blob/v1/(:trafo.)*bucket_or_file.:format", :function => :get_file_head
		head "/blob/v1/(:trafo.)*bucket_or_file", :function => :get_file_head

		get "*any", :function => :next_api
		put "*any", :function => :next_api
		delete "*any", :function => :next_api
    head "*any", :function => :next_api
    post "*any", :function => :next_api

		private
			def not_allowed
				Http.NotAllowed "listing blob server not allowed"
			end

			def get_file(send_with_data=true)
				accept = AcceptType.get(env, format)[0]

        # check trafo encryption
				trafo_string = Blobsterix.decrypt_trafo(transformation_string, logger)
				if !trafo_string
					Blobsterix.encryption_error(BlobAccess.new(:bucket => bucket, :id => file))
					return Http.NotAuthorized
				end

        
        blob_access=BlobAccess.new(:bucket => bucket, :id => file, :accept_type => accept, :trafo => trafo(trafo_string))

        begin
					data = transformation.run(blob_access)
					send_with_data ? data.response(true, env["HTTP_IF_NONE_MATCH"], env, env["HTTP_X_FILE"] === "yes") : data.response(false)
				rescue Errno::ENOENT => e
					logger.error "Cache deleted: #{blob_access}"
					Blobsterix.cache_fatal_error(blob_access)
					Http.ServerError
				end
			end

			def get_file_head
				get_file(false)
			end
	end
end