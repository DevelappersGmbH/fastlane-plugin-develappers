module Fastlane
  module Helper
    class GitHelper
      def self.commit(params)
        paths = if params[:path].is_a?(String)
                  params[:path].shellescape
                else
                  params[:path].map(&:shellescape).join(' ')
                end

        ShellHelper.sh(command: "git commit -m #{params[:message].shellescape} #{paths}")
      end
    end
  end
end
