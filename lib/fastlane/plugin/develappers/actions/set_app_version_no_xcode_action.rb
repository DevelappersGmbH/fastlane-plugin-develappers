module Fastlane
  module Actions
    class SetAppVersionNoXCodeAction < Action
      def self.run(params)
        version_name = params[:version_name]
        version_code = params[:version_code]
        info_plists = params[:info_plists]

        UI.important "Set version to #{version_name} - #{version_code}"

        Helper::VersionHelper.set_version(info_plists: info_plists, version_name: version_name, version_code: version_code)
      end

      def self.description
        'Sets version'
      end

      def self.authors
        ['Niklas Werner']
      end

      def self.return_value; end

      def self.details; end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :info_plists, description: 'Plist files', type: Array),
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
