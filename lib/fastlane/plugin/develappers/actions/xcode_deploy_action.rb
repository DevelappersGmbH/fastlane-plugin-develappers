module Fastlane
    module Actions
        class XcodeDeployAction < Action
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
                UI.important "Pod install"
                other_action.cocoapods(repo_update: false)

                # update cerificates
                UI.important "Update cerificates"

                match_options = {type: "appstore"}
                
                match_options[:app_identifier] = app_identifier unless app_identifier.nil?

                unless team_name.nil?
                    match_options[:team_name] = team_name
                    match_options[:git_branch] = team_name.gsub(' ', '_')
                end

                other_action.match match_options

                # bump version
                UI.important "Bump version"

                version = Helper::VersionHelper.bump_version(bump_type: params[:bump_type])
            
                other_action.commit_version_bump(force: true, message: "Bumped version to #{version}")

                if is_multiple_schemes_build
                    # tag commit with '[scheme]/[version]'
                    other_action.add_git_tag(tag: "#{scheme.gsub(' ', '_')}/#{version}")
                else
                    # tag commit with 'iOS/[version]'
                    other_action.add_git_tag(tag: "iOS/#{version}")
                end

                # build application
                UI.important "Build application"

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

                # deploy
                UI.important "Deploy"
                
                other_action.pilot(
                    distribute_external: false,
                    skip_waiting_for_build_processing: true,
                    app_identifier: app_identifier,
                    team_name: team_name
                )
            rescue Exception => e
                # reraise
                UI.abort_with_message! e.message
            end

            def self.description
                "Build a iOS project and deploys result to itunes connect"
            end

            def self.authors
                ["Johannes Starke"]
            end

            def self.return_value
                nil
            end

            def self.details
            end

            def self.available_options
                [
                    FastlaneCore::ConfigItem.new(
                        key: :info_plist_file, 
                        env_name: "BUILD_INFO_PLIST_FILE", 
                        description: "Path to info plist !!! No need to set anymore !!!", 
                        optional: true,
                        type: String),
                    FastlaneCore::ConfigItem.new(
                        key: :bump_type,
                        env_name: "BUMP_VERSION_BUMP_TYPE",
                        description: "Possible values are patch, major, minor and build",
                        optional: true,
                        default_value: "build",
                        type: String),

                    # only xcode build
                    FastlaneCore::ConfigItem.new(key: :scheme_name, env_name: "BUILD_XCODE_SCHEME_NAME", description: "Name of scheme", type: String),
                    FastlaneCore::ConfigItem.new(key: :configuration, env_name: "BUILD_XCODE_CONFIGURATION", description: "Build configuration", type: String, optional: true, default_value: "Release"),
                    FastlaneCore::ConfigItem.new(key: :version, env_name: "BUILD_XCODE_VERSION", description: "Xcode version (e.g. 9.1, 9.2)", type: String, optional: true),

                    # useful for builds with multiple schemes
                    FastlaneCore::ConfigItem.new(key: :app_identifier, env_name: "BUILD_XCODE_APP_IDENTIFER", description: "App identifier", type: String, optional: true),
                    FastlaneCore::ConfigItem.new(key: :team_name, env_name: "BUILD_XCODE_TEAM_NAME", description: "Team name in itunes connect", type: String, optional: true)
                ]
            end

            def self.is_supported?(platform)
                [:ios].include?(platform)
            end
        end
    end
  end