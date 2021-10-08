module Fastlane
  module Actions
    class XcodeTestAction < Action
      def self.run(params)
        ### handle params

        # version
        xcode_version = params[:version]
        scheme_name = params[:scheme_name]

        ### build
        # pod install
        UI.important 'Pod install'
        other_action.cocoapods(repo_update: false)

        # set xcode version
        unless xcode_version.nil?
          UI.important "Set xcode version to #{xcode_version}"
          xcode_path = other_action.xcode_install(version: xcode_version)
          other_action.xcode_select(xcode_path)
        end

        # test application
        UI.important 'Test application'

        # detect workspace and use absolute path
        empty_config = {}
        FastlaneCore::Project.detect_projects(empty_config)
        workspace = empty_config[:workspace]
        workspace = File.realdirpath(workspace)

        other_action.scan(workspace: workspace, scheme: scheme_name)
      end

      def self.description
        'Tests a iOS project'
      end

      def self.authors
        ['Johannes Starke']
      end

      def self.return_value
        nil
      end

      def self.details; end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :scheme_name, env_name: 'BUILD_XCODE_SCHEME_NAME',
                                       description: 'Name of scheme', type: String),
          FastlaneCore::ConfigItem.new(key: :version, env_name: 'BUILD_XCODE_VERSION',
                                       description: 'Xcode version (e.g. 9.1, 9.2)', type: String, optional: true)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
