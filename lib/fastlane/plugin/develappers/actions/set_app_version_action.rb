module Fastlane
  module Actions
    class SetAppVersionAction < Action
      def self.run(params)
        version_name = params[:version_name]
        version_code = params[:version_code]

        UI.important "Set version to #{version_name} - #{version_code}"

        Helper::VersionHelper.set_version(version_name: version_name, version_code: version_code)
      rescue Exception => e
        UI.abort_with_message! e.message
      end

      def self.description
        'Sets version'
      end

      def self.authors
        ['Johannes Starke']
      end

      def self.return_value; end

      def self.details; end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version_name, description: 'Version Name', type: String),
          FastlaneCore::ConfigItem.new(key: :version_code, description: 'Version Code', type: Integer)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
