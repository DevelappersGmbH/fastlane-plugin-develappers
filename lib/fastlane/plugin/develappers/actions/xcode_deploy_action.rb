module Fastlane
    module Actions
        class XcodeDeployAction < Action
            def self.run(params)
                ### handle params
                # scheme
                scheme = params[:scheme_name]

                # info plist
                info_plist = Helper::InfoplistHelper.detect(params)

                # version
                xcode_version = params[:xcode_version]
                
                ### build
                # pod install
                UI.important "Pod install"
                other_action.cocoapods(repo_update: false)

                # update cerificates
                UI.important "Update cerificates"

                other_action.match type: "appstore"

                # bump version
                UI.important "Bump version"

                version = Helper::VersionHelper.bump_version(
                    bump_type: params[:bump_type],
                    info_plist: info_plist
                )
            
                other_action.commit_version_bump(force: true, message: "Bumped version to #{version}")
                other_action.add_git_tag(tag: "iOS/#{version}")
            
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

                other_action.gym(scheme: scheme, workspace: workspace)

                # deploy
                UI.important "Deploy"
                
                other_action.pilot(
                    distribute_external: false,
                    skip_waiting_for_build_processing: true
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
                        description: "Path to info plist", 
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
                    FastlaneCore::ConfigItem.new(key: :xcode_version, env_name: "BUILD_XCODE_VERSION", description: "Xcode version (e.g. 9.1, 9.2)", type: String, optional: true)
                ]
            end

            def self.is_supported?(platform)
                [:ios].include?(platform)
            end
        end
    end
  end