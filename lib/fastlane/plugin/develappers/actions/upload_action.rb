module Fastlane
    module Actions
      class UploadAction < Action
        def self.run(params)
          ### handle params
          # app identifier and team name
          app_identifier = params[:app_identifier]
          team_name = params[:team_name]
  
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
  
          # deploy
          UI.important 'Deploy'
  
          other_action.pilot(
            distribute_external: false,
            skip_waiting_for_build_processing: true,
            app_identifier: app_identifier,
            team_name: team_name
          )
        end
  
        def self.description
          'Uploads .ipa to itunes connect'
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
  