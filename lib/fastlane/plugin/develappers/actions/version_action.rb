module Fastlane
  module Actions
    class VersionAction < Action
      def self.run(params)
        # check info plist
        info_plist_file = Helper::InfoplistHelper.detect(params)

        ### Get version
        version = Helper::VersionHelper.version(info_plist: info_plist_file)
        build = Helper::VersionHelper.build(info_plist: info_plist_file)

        version_name = "#{version}-#{build}"

        UI.important "Version is #{version_name}"

        output_file = params[:output_file]

        if output_file
          File.write output_file, version_name

          UI.important "Published version name in #{File.expand_path(File.new(output_file))}"
        end

        version_name
      rescue Exception => e
        # reraise
        UI.abort_with_message! e.message
      end

      def self.description
        "Get's you the current version name"
      end

      def self.authors
        ['Johannes Starke']
      end

      def self.return_value
        'version name'
      end

      def self.details; end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :scheme_name, env_name: 'BUILD_XCODE_SCHEME_NAME',
                                       description: 'Name of scheme', type: String, optional: true),
          FastlaneCore::ConfigItem.new(key: :info_plist_file, env_name: 'VERSION_INFO_PLIST_FILE',
                                       description: 'Path to info plist', type: String, optional: true),

          FastlaneCore::ConfigItem.new(key: :output_file, env_name: 'VERSION_OUTPUT_FILE',
                                       description: 'File for output of version name', type: String, optional: true)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
