module Blobsterix
  module S3Auth
    class V2
      include ::Blobsterix::S3UrlHelper
      include ::Blobsterix::UrlHelper
      include ::Blobsterix::Logable
      include V2Helper

      SUBRESOURCES = [
        "acl",
        "lifecycle",
        "location",
        "logging",
        "notification",
        "partNumber",
        "policy",
        "requestPayment",
        "torrent",
        "uploadId",
        "uploads",
        "versionId",
        "versioning",
        "versions",
        "website"
      ]

      V2_REGEX = /AWS (\w+):(.+)/

      def self.create(env)
        auth_string = env["HTTP_AUTHORIZATION"]
        matcher = V2_REGEX.match(auth_string)
        matcher ? V2.new(env, matcher[1], matcher[2]) : nil
      end

      attr_reader :env, :access_key, :signature
      def initialize(env, access_key, signature)
        @env = env
        @access_key = access_key
        @signature = signature
      end

      def time_of_request
        env["HTTP_DATE"] unless env["HTTP_X_AMZ_DATE"]
      end

      def server_signature(secret_key, str)
        gen_signature(secret_key, str)
      end
    end
  end
end