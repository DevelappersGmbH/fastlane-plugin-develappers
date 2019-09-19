module Fastlane
    module Actions
        class XamarinDeployAction < Action
            def self.run(params)
                ### handle params
                # solution file
                solution_folder = params[:solution_folder]
                solution_name = params[:solution_name]

                solution_file = "#{solution_folder}#{solution_name}.sln"

                raise "Solution file at #{solution_file} not found" unless File.exist?(solution_file)

                # solution app name
                solution_app_name = "#{solution_name}iOS"

                # solution target
                solution_target_name = "#{solution_name}_iOS"

                # check info plist
                info_plist_file = Helper::InfoplistHelper.detect(params)

                ### build
                # update cerificates
                UI.important "Update cerificates"

                other_action.match type: "appstore"

                # bump version
                UI.important "Bump version"

                version = Helper::ManuelVersionHelper.bump_version(
                    bump_type: params[:bump_type],
                    info_plist: info_plist_file
                )

                # build application
                UI.important "Restore packages and build solution"
                UI.message "Restoring packages"

                restore_packages(
                    solution: solution_file
                )

                UI.message "Successfully restored packages"

                UI.message "Building solution"
                
                ipa_file = build_release(
                    app_name: solution_app_name,
                    solution: solution_file,
                    targets: solution_target_name
                )

                UI.message "Successfully builded solution"

                # commit version and tag
                UI.important "Commit version and add tag"

                UI.message "Adding #{info_plist_file} to git"
                Helper::GitHelper.commit(
                    path: info_plist_file, 
                    message: "Bump version to #{version}"
                )

                # deploy
                UI.important "Deploy"

                other_action.pilot(
                    distribute_external: false,
                    ipa: ipa_file,
                    skip_waiting_for_build_processing: true
                )
            rescue Exception => e
                # reraise
                UI.abort_with_message! e.message
            end

            def self.description
                "Build a xamarin iOS project and deploys result to itunes connect"
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
                    FastlaneCore::ConfigItem.new(key: :info_plist_file, env_name: "BUILD_INFO_PLIST_FILE", description: "Path to info plist", type: String),
                    FastlaneCore::ConfigItem.new(
                        key: :bump_type,
                        env_name: "BUMP_VERSION_BUMP_TYPE",
                        description: "Possible values are patch, major, minor and build",
                        optional: true,
                        default_value: "build",
                        type: String),

                    # only xamarin build
                    FastlaneCore::ConfigItem.new(key: :solution_name, env_name: "BUILD_XAMARIN_SOLUTION_FOLDER", description: "Name of solution (without *.sln)", type: String),
                    FastlaneCore::ConfigItem.new(key: :solution_folder, env_name: "BUILD_XAMARIN_SOLUTION_FOLDER", description: "Relative (!) path to folder containing solution file (*.sln)", type: String)
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
                output_dir = "./fastlane/Build/"
                app_name = options[:app_name]

                msbuild(
                    solution: options[:solution],
                    targets: [options[:targets]],
                    configuration: "Release",
                    platform: "iPhone",
                    android_home: "",
                    additional_arguments: [
                        "/p:BuildIpa=true",
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
        
                msbuild = params[:msbuild_path] ? File.join(params[:msbuild_path], "msbuild") : "msbuild"
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
                
                Helper::ShellHelper.sh command: command
              end
        end
    end
  end