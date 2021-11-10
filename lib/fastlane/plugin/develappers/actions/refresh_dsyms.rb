module Fastlane
  module Actions
    class RefreshDsymsAction < Action
      def self.run(params)
        UI.important 'Refresh dsyms'

        other_action.clean_build_artifacts

        loop do
          other_action.download_dsyms(
            app_identifier: params[:app_identifier],
            version: 'latest'
          )

          downloaded_dsym_paths = lane_context[SharedValues::DSYM_PATHS] || []

          if downloaded_dsym_paths.empty?
            UI.message 'Wait 30 seconds and retry'
            sleep(30)
          else
            other_action.upload_symbols_to_crashlytics(
              dsym_paths: downloaded_dsym_paths,
              gsp_path: params[:gsp_path]
            )

            break
          end
        end
      end

      def self.description
        'Refresh dsyms (Waits until symbols are available.)'
      end

      def self.authors
        ['Johannes Starke']
      end

      def self.return_value; end

      def self.details; end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_identifier, env_name: 'REFRESH_DSYMS_APP_IDENTIFER',
                                       description: 'App identifier', type: String),
          FastlaneCore::ConfigItem.new(key: :gsp_path, env_name: 'REFRESH_DSYMS_GSP_PATH',
                                       description: 'Path to GoogleService-Info.plist', type: String)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
