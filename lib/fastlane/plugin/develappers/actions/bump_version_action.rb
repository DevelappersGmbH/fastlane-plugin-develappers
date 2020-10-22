module Fastlane
    module Actions
        class BumpVersionAction < Action
            def self.run(params)
                UI.important "Bump version"
                version = Helper::VersionHelper.bump_version({ bump_type: params[:bump_type], configuration: params[:configuration] })
            rescue Exception => e
                # reraise
                UI.abort_with_message! e.message
            end

            def self.description
                "Bumps version"
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
                    FastlaneCore::ConfigItem.new(key: :bump_type, env_name: "BUMP_VERSION_BUMP_TYPE", description: "Possible values are patch, major, minor and build", optional: true, default_value: "build", type: String),
                    FastlaneCore::ConfigItem.new(key: :configuration, env_name: "BUILD_XCODE_CONFIGURATION", description: "Build configuration", type: String, optional: true, default_value: "Release")
                ]
            end

            def self.is_supported?(platform)
                [:ios].include?(platform)
            end
        end
    end
  end