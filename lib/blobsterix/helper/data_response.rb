module Blobsterix
  module Http
    class DataResponse
      attr_reader :meta, :with_data, :etag, :env

      def initialize(_meta, _with_data=true, _etag=nil, _env = nil)
        @meta = _meta
        @with_data = _with_data
        @etag = _etag
        @env = _env
      end

      def call()
        if not meta.valid
          Http.NotFound()
        elsif Blobsterix.use_x_send_file and etag != meta.etag
          [200, meta.header.merge({"X-Sendfile" => meta.path.to_s}).merge(content_disposition_header), ""]
        elsif etag != meta.etag
          if env != nil && meta.size > 30000 && Blobsterix.allow_chunked_stream
            chunkresponse
          else
            [200, meta.header.merge(content_disposition_header), (with_data ? File.open(meta.path, "rb") : "")]
          end
        else
          [304, meta.header.merge(content_disposition_header), ""]
        end
      end

      private
        def filename
          env["params"]["filename"]
        end
        def filename?
          env["params"].has_key? "filename" if env && env["params"]
        end
        def content_disposition_header
          filename? ? {"Content-Disposition" => "attachment; filename=#{filename}"} : {}
        end
        def chunkresponse
          f = File.open(meta.path)
          EM.next_tick do
            send_chunk(f)
          end
          [200, meta.header.merge(Goliath::Response::CHUNKED_STREAM_HEADERS).merge(content_disposition_header), (with_data ? Goliath::Response::STREAMING : "")]
        end

        def send_chunk(file)
          dat = file.read(10000)
          again = if dat != nil
            env.chunked_stream_send(dat)
            true
          else
            file.close
            env.chunked_stream_close
            false
          end
          EM.next_tick do
            send_chunk(file)
          end if again
        end
    end
  end
end
