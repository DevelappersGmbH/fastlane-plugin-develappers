module Fastlane
  module Actions
    class XamarinBuildAction < Action
      def self.run(params)
        ### handle params
        app_identifier = params[:app_identifier]

        # solution file
        solution_folder = params[:solution_folder]
        solution_name = params[:solution_name]
        info_plist_file = params[:info_plist_file]
        flavor = params[:flavor]

        solution_file = "#{solution_folder}#{solution_name}.sln"

        raise "Solution file at #{solution_file} not found" unless File.exist?(solution_file)

        # solution app name
        solution_app_name = "#{solution_name}iOS"

        # solution target
        solution_target_name = "#{solution_name}_iOS"

        # configuration
        configuration = params[:configuration]

        # set version
        version_info = other_action.app_version(
          app_identifier: app_identifier,
          flavor: flavor,
          output: 'full'
        )

        UI.important "Version infos are #{version_info}"

        version_name = version_info[:version_name]
        version_code = version_info[:version_code]

        other_action.set_app_version_no_x_code(
          info_plists: [info_plist_file],
          version_name: version_name,
          version_code: version_code
        )

        ### build
        # update cerificates
        UI.important 'Update cerificates'

        other_action.match(
          type: 'appstore',
          app_identifier: app_identifier,
          readonly: true
        )

        # build application
        UI.important 'Restore packages and build solution'
        UI.message 'Restoring packages'

        restore_packages(
          solution: solution_file
        )

        UI.message 'Successfully restored packages'

        UI.message 'Building solution'

        ipa_file = build_release(
          app_name: solution_app_name,
          solution: solution_file,
          targets: solution_target_name,
          configuration: configuration
        )

        UI.message 'Successfully built solution'
      end

      def self.description
        'Build a xamarin iOS project and deploys result to itunes connect'
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
          FastlaneCore::ConfigItem.new(key: :info_plist_file, env_name: 'BUILD_INFO_PLIST_FILE',
                                       description: 'Path to info plist file', type: String),
          FastlaneCore::ConfigItem.new(
            key: :bump_type,
            env_name: 'BUMP_VERSION_BUMP_TYPE',
            description: 'Possible values are patch, major, minor and build',
            optional: true,
            default_value: 'build',
            type: String
          ),

          # only xamarin build
          FastlaneCore::ConfigItem.new(key: :solution_name, env_name: 'BUILD_XAMARIN_SOLUTION_FOLDER',
                                       description: 'Name of solution (without *.sln)', type: String),
          FastlaneCore::ConfigItem.new(key: :solution_folder, env_name: 'BUILD_XAMARIN_SOLUTION_FOLDER',
                                       description: 'Relative (!) path to folder containing solution file (*.sln)', type: String),
          FastlaneCore::ConfigItem.new(key: :configuration, env_name: 'BUILD_XAMARIN_CONFIGURATION',
                                       description: 'Build configuration', type: String, optional: true, default_value: 'Release'),
          FastlaneCore::ConfigItem.new(key: :app_identifier, env_name: 'BUILD_XAMARIN_APP_IDENTIFER',
                                       description: 'App identifier', type: String, optional: true),
          FastlaneCore::ConfigItem.new(key: :flavor, env_name: 'FLAVOR',
                                       description: 'Flavor', type: String)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end

      #################
      #### Helpers ####
      #################

      def self.restore_packages(options)
        Helper::ShellHelper.sh(command: "nuget restore #{options[:solution]}", log: false)
      end

      def self.build_release(options)
        output_dir = './fastlane/Build/'
        app_name = options[:app_name]

        msbuild(
          solution: options[:solution],
          targets: [options[:targets]],
          configuration: options[:configuration],
          platform: 'iPhone',
          android_home: '',
          additional_arguments: [
            '/p:BuildIpa=true',
            "/p:OutputPath=#{output_dir}",
            "/p:IpaPackageDir=#{output_dir}"
          ]
        )

        # zip dsyms
        Dir.chdir output_dir do
          symbols_file = Dir.glob('*.app.dSYM').first
          Helper::ShellHelper.sh command: "zip -r #{symbols_file}.zip #{symbols_file}"
        end

        ipa_file = Dir.glob("#{output_dir}/*.ipa").first

        # return ipa full path
        File.expand_path(ipa_file)
      end

      def self.msbuild(params)
        # copied from https://github.com/willowtreeapps/fastlane-plugin-msbuild

        configuration = params[:configuration]
        platform = params[:platform]
        solution = params[:solution]
        msbuild = params[:msbuild_path] ? File.join(params[:msbuild_path], 'msbuild') : 'msbuild'
        command = "#{msbuild} \"#{solution}\""
        params[:targets].each do |target|
          command << " /t:\"#{target}\""
        end
        command << " /p:Configuration=\"#{configuration}\""
        command << " /p:Platform=\"#{platform}\"" if platform
        command << " /p:AndroidSdkDirectory=\"#{params[:android_home]}\"" if params[:android_home]
        params[:additional_arguments].each do |param|
          command << " #{param}"
        end

        UI.message "Executing: #{command}"

        Helper::ShellHelper.sh command: command
      end
    end
  end
end
