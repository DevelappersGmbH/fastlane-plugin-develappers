module Fastlane
    module Actions
      class BuildAction < Action
        def self.run(params)
          ### handle params
          # scheme
          scheme = params[:scheme_name]
          configuration = params[:configuration]
  
          # version
          xcode_version = params[:version]
  
          # app identifier and team name
          app_identifier = params[:app_identifier]
          team_name = params[:team_name]
  
          # is build with multiple schemes?
          is_multiple_schemes_build = !app_identifier.nil? && !team_name.nil?
  
          ### build
          # pod install
          if params[:pod_install]
            UI.important 'Pod install'
            other_action.cocoapods(repo_update: false)
          end
  
          # update cerificates
          UI.important 'Update cerificates'
  
          match_options = { type: 'appstore' }
  
          match_options[:app_identifier] = app_identifier unless app_identifier.nil?
          match_options[:readonly] = true
  
          unless team_name.nil?
            match_options[:team_name] = team_name
            match_options[:git_branch] = team_name.gsub(' ', '_')
          end
  
          other_action.match match_options
  
          # build application
          UI.important 'Build application'
  
          unless xcode_version.nil?
            UI.message "Set xcode version to #{xcode_version}"
            xcode_path = other_action.xcode_install(version: xcode_version)
            other_action.xcode_select(xcode_path)
          end
  
          # detect workspace and use absolute path
          gym_config = {}
          FastlaneCore::Project.detect_projects(gym_config)
          workspace = gym_config[:workspace]
          workspace = File.realdirpath(workspace)
  
          other_action.gym(
            scheme: scheme,
            configuration: configuration,
            workspace: workspace
          )
        end
  
        def self.description
          'Build an iOS project'
        end
  
        def self.authors
          ['Johannes Starke', 'Niklas Werner']
        end
  
        def self.return_value
          nil
        end
  
        def self.details; end
  
        def self.available_options
          [
            # only xcode build
            FastlaneCore::ConfigItem.new(key: :scheme_name, env_name: 'BUILD_XCODE_SCHEME_NAME',
                                         description: 'Name of scheme', type: String),
            FastlaneCore::ConfigItem.new(key: :configuration, env_name: 'BUILD_XCODE_CONFIGURATION',
                                         description: 'Build configuration', type: String, optional: true, default_value: 'Release'),
            FastlaneCore::ConfigItem.new(key: :version, env_name: 'BUILD_XCODE_VERSION',
                                         description: 'Xcode version (e.g. 9.1, 9.2)', type: String, optional: true),
            FastlaneCore::ConfigItem.new(key: :pod_install, env_name: 'BUILD_XCODE_POD_INSTALL',
                                         description: 'Should perform pod install', type: Boolean, default_value: true, optional: true),
  
            # useful for builds with multiple schemes
            FastlaneCore::ConfigItem.new(key: :app_identifier, env_name: 'BUILD_XCODE_APP_IDENTIFER',
                                         description: 'App identifier', type: String, optional: true),
            FastlaneCore::ConfigItem.new(key: :team_name, env_name: 'BUILD_XCODE_TEAM_NAME',
                                         description: 'Team name in itunes connect', type: String, optional: true)
          ]
        end
  
        def self.is_supported?(platform)
          [:ios].include?(platform)
        end
      end
    end
  end
  