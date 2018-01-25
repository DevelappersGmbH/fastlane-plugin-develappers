module Fastlane
    module Helper
        class VersionHelper
            def self.version(options)
                info_plist = options[:info_plist]

                Helper::ShellHelper.sh(command: "/usr/libexec/PlistBuddy -c \"Print :CFBundleShortVersionString\" #{info_plist}")
            end

            def self.build(options)
                info_plist = options[:info_plist]

                Helper::ShellHelper.sh(command: "/usr/libexec/PlistBuddy -c \"Print :CFBundleVersion\" #{info_plist}").to_i
            end

            def self.bump_version(options)
                bump_type = options[:bump_type]
                info_plist = options[:info_plist]
            
                raise "Unknown bump type '#{bump_type}'" unless bump_type.to_s.empty? || /(major|minor|patch|build)/ =~ bump_type
            
                version = ""
                build = ""

                version = version(options)
                bumped_version = ""
            
                if /(major|minor|patch)/ =~ bump_type
                    major, minor, patch, *rest = version.split(".").map { |p| p.to_i }
            
                    if bump_type == "major"
                    major = major + 1
                    minor = 0
                    patch = 0
                    elsif bump_type == "minor"
                    minor = minor + 1
                    patch = 0
                    elsif bump_type == "patch"
                    patch = patch + 1
                    end
            
                    bumped_version = "#{major}.#{minor}.#{patch}"

                    UI.verbose "Bump version from #{version} to #{bumped_version}"
            
                    Helper::ShellHelper.sh(command: "/usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString #{bumped_version}\" #{info_plist}")
                elsif
                    bumped_version = version
                end
            
                # Bump Build number
                build = build(options)
                bumped_build = build + 1

                UI.verbose "Bump build from #{build} to #{bumped_build}"

                Helper::ShellHelper.sh(command: "/usr/libexec/PlistBuddy -c \"Set :CFBundleVersion #{bumped_build}\" #{info_plist}")

                version_label = "v#{bumped_version}-#{bumped_build}"

                UI.message "New version is now #{version_label}"

                version_label
            end
        end
    end
end
