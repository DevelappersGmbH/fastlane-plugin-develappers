module Fastlane
  module Helper
    class VersionHelper
      require 'shellwords'

      def self.info_plists(options)
        configuration = options[:configuration]

        UI.message "Using configuration #{configuration}"

        # find the repo root path
        repo_path = Actions.sh('git rev-parse --show-toplevel').strip
        repo_pathname = Pathname.new(repo_path)

        # find an xcodeproj (ignoring dependencies)
        xcodeproj_paths = Fastlane::Helper::XcodeprojHelper.find(repo_path)

        # no projects found: error
        if xcodeproj_paths.count == 0
          UI.user_error!('Could not find a .xcodeproj in the current repository\'s working directory.')
        end

        # too many projects found: error
        if xcodeproj_paths.count > 1
          relative_projects = xcodeproj_paths.map do |e|
            Pathname.new(e).relative_path_from(repo_pathname).to_s
          end.join("\n")
          UI.user_error!("Found multiple .xcodeproj projects in the current repository's working directory. Please specify your app's main project: \n#{relative_projects}")
        end

        # one project found: great
        xcodeproj_path = xcodeproj_paths.first

        # find the info_plist files
        project = Xcodeproj::Project.open(xcodeproj_path)
        project.objects.select do |object|
          object.isa == 'XCBuildConfiguration' && (configuration.nil? || object.name == configuration)
        end.map(&:to_hash).map do |object_hash|
          object_hash['buildSettings']
        end.select do |build_settings|
          build_settings.key?('INFOPLIST_FILE')
        end.map do |build_settings|
          build_settings['INFOPLIST_FILE']
        end.select do |info_plist_path|
          !info_plist_path.nil? && !info_plist_path.empty?
        end.uniq.map do |info_plist_path|
          Pathname.new(File.expand_path(File.join(xcodeproj_path, '..', info_plist_path))).to_s
        end
      end

      def self.version(options)
        info_plist = options[:info_plist]
        escaped_info_plist = Shellwords.shellescape info_plist

        UI.verbose "Version from #{escaped_info_plist}"

        Helper::ShellHelper.sh(command: "/usr/libexec/PlistBuddy -c \"Print :CFBundleShortVersionString\" #{escaped_info_plist}")
      end

      def self.build(options)
        info_plist = options[:info_plist]
        escaped_info_plist = Shellwords.shellescape info_plist

        Helper::ShellHelper.sh(command: "/usr/libexec/PlistBuddy -c \"Print :CFBundleVersion\" #{escaped_info_plist}").to_i
      end

      def self.set_version(options)
        info_plists = options[:info_plists] || self.info_plists({})

        version_name = options[:version_name]
        version_code = options[:version_code]

        # set version name
        info_plists.each do |info_plist|
          escaped_info_plist = Shellwords.shellescape info_plist
          Helper::ShellHelper.sh(command: "/usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString #{version_name}\" #{escaped_info_plist}")
        end

        # set version code
        info_plists.each do |info_plist|
          escaped_info_plist = Shellwords.shellescape info_plist
          Helper::ShellHelper.sh(command: "/usr/libexec/PlistBuddy -c \"Set :CFBundleVersion #{version_code}\" #{escaped_info_plist}")
        end
      end

      def self.bump_version(options)
        bump_type = options[:bump_type]
        main_info_plist_indicator = options[:main_info_plist_indicator]
        info_plists = self.info_plists(options)

        unless bump_type.to_s.empty? || /(major|minor|patch|build)/ =~ bump_type
          raise "Unknown bump type '#{bump_type}'"
        end
        raise 'No infoplist found! Check provided configuration' unless info_plists.any?

        UI.message 'bump version in info plists:'
        UI.message info_plists

        if !main_info_plist_indicator.nil?
          main_info_plist = info_plists.detect do |p|
            p.include? main_info_plist_indicator
          end || info_plists.first
          UI.message "Main info plist is #{main_info_plist} (first matching #{main_info_plist_indicator})"
        else
          main_info_plist = info_plists.first
          UI.message "Main info plist is #{main_info_plist}"
        end

        version = version(info_plist: main_info_plist)
        bumped_version = ''

        if /(major|minor|patch)/ =~ bump_type
          major, minor, patch, *rest = version.split('.').map { |p| p.to_i }

          # set default when nil
          major ||= 0
          minor ||= 0
          patch ||= 0

          if bump_type == 'major'
            major += 1
            minor = 0
            patch = 0
          elsif bump_type == 'minor'
            minor += 1
            patch = 0
          elsif bump_type == 'patch'
            patch += 1
          end

          bumped_version = "#{major}.#{minor}.#{patch}"

          UI.verbose "Bump version from #{version} to #{bumped_version}"
        else
          bumped_version = version
        end

        # Bump Build number
        build = build(info_plist: main_info_plist)
        bumped_build = build + 1

        UI.verbose "Bump build from #{build} to #{bumped_build}"

        set_version(
          info_plists: info_plists,
          version_name: bump_version,
          version_code: bumped_build
        )

        version_label = "v#{bumped_version}-#{bumped_build}"

        UI.message "New version is now #{version_label}"

        version_label
      end
    end
  end
end
