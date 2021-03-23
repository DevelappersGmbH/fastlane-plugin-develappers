module Fastlane
    module Actions
        class BumpVersionAction < Action
            def self.run(params)
                UI.important "Bump version"
                Helper::VersionHelper.bump_version({ 
                    bump_type: params[:bump_type], 
                    configuration: params[:configuration],
                    main_info_plist_indicator: params[:main_info_plist_indicator]
                })
            rescue Exception => e
                UI.abort_with_message! e.message
            end

            def self.description
                "Bumps version"
            end

            def self.authors
                ["Johannes Starke"]
            end

            def self.return_value
                "version name"
            end

            def self.details
            end

            def self.available_options
                [
                    FastlaneCore::ConfigItem.new(key: :bump_type, env_name: "BUMP_VERSION_BUMP_TYPE", description: "Possible values are patch, major, minor and build", optional: true, default_value: "build", type: String),
                    FastlaneCore::ConfigItem.new(key: :configuration, env_name: "BUMP_VERSION_CONFIGURATION", description: "Build configuration", type: String, optional: true, default_value: "Release"),
                    FastlaneCore::ConfigItem.new(key: :main_info_plist_indicator, env_name: "BUMP_VERSION_MAIN_INFO_PLIST_INDICATOR", description: "Indicator for the main info plist. First info plist path matching this string will get selected. If not defined first info plist will get picked", type: String, optional: true)
                ]
            end

            def self.is_supported?(platform)
                [:ios].include?(platform)
            end
        end
    end
  end