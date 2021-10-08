module Fastlane
  module Helper
    class InfoplistHelper
      def self.detect(params)
        info_plist = params[:info_plist_file]

        if info_plist.nil?
          scheme = params[:scheme_name]
          info_plist = "./#{scheme}/info.plist"

          unless File.exist?(info_plist)
            raise "Expected info plist file at #{info_plist}. Path was derived from schema name."
          end
        else
          raise "Expected info plist file at #{info_plist}" unless File.exist?(info_plist)
        end

        info_plist
      end
    end

    class ManuelVersionHelper
      require 'shellwords'

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

      def self.bump_version(options)
        bump_type = options[:bump_type]
        info_plist = options[:info_plist]
        escaped_info_plist = Shellwords.shellescape info_plist

        unless bump_type.to_s.empty? || /(major|minor|patch|build)/ =~ bump_type
          raise "Unknown bump type '#{bump_type}'"
        end

        version = ''
        build = ''

        version = version(options)
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

          Helper::ShellHelper.sh(command: "/usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString #{bumped_version}\" #{escaped_info_plist}")
        elsif bumped_version = version
        end

        # Bump Build number
        build = build(options)
        bumped_build = build + 1

        UI.verbose "Bump build from #{build} to #{bumped_build}"

        Helper::ShellHelper.sh(command: "/usr/libexec/PlistBuddy -c \"Set :CFBundleVersion #{bumped_build}\" #{escaped_info_plist}")

        version_label = "v#{bumped_version}-#{bumped_build}"

        UI.message "New version is now #{version_label}"

        version_label
      end
    end
  end
end
