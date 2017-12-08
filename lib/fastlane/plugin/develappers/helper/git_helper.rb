module Fastlane
    module Helper
        class GitHelper
            def self.commit(params)
                if params[:path].kind_of?(String)
                    paths = params[:path].shellescape
                else
                    paths = params[:path].map(&:shellescape).join(' ')
                end
        
                result = ShellHelper.sh(command: "git commit -m #{params[:message].shellescape} #{paths}")
                return result
            end
        end
    end
end
