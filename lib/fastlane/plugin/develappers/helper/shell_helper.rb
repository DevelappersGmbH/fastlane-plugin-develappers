module Fastlane
  module Helper
    class ShellHelper
      def self.sh(options)
        log = options[:log] || FastlaneCore::Globals.verbose?

        FastlaneCore::CommandExecutor.execute(command: options[:command], print_all: log, print_command: log)
      end
    end
  end
end
