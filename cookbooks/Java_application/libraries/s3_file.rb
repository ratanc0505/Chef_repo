class Chef
  class Provider
    class S3File < Chef::Provider::RemoteFile
      def action_create
        sources = @new_resource.source
        source = sources
        # Handle both Chef 10.x to latest, this is probably largely not needed, but for good practice.
        if sources.respond_to?(:shift)
          source = sources.shift
        end
        Chef::Log.debug("Checking if #{@new_resource} has changed.")

      fetch_from_s3(source) do |raw_file|
          Chef::Log.debug "copying remote file from origin #{raw_file.path} to desitnation #{@new_resource.path}"
          FileUtils.cp raw_file.path, @new_resource.path
          @new_resource.updated_by_last_action(true)
        end

        enforce_ownership_and_permissions

        @new_resource.updated_by_last_action?
      end

      def fetch_from_s3(source)
        begin
          require 'aws-sdk'
          protocol, bucket, name = URI.split(source).compact
          name = name[1..-1]
          obj = Aws::S3::Client.new(
            region: 'us-east-1',
            credentials: Aws::InstanceProfileCredentials.new(),
          )
          Chef::Log.info("Downloading #{name} from S3 Bucket #{bucket}")
          file = Tempfile.new("chef-s3-file")
          file.binmode
          obj.get_object({bucket: "#{bucket}", key: "#{name}"}, target: file)
          Chef::Log.debug("File #{name} is #{file.size} bytes on disk")
          begin
            yield file
          ensure
            file.close
          end
        rescue URI::InvalidURIError
          Chef::Log.warn("Expected an S3 URL but found #{source}")
          nil
        end
      end
    end
  end
end

class Chef
  class Resource
    class S3File < Chef::Resource::RemoteFile
      def initialize(name, run_context=nil)
        super
        @resource_name = :s3_file
      end

      def provider
        Chef::Provider::S3File
      end
    end
  end
end
