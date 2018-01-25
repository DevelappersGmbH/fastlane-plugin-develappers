module Fastlane
    module Helper
        class InfoplistHelper
            def self.detect(params)
                info_plist = params[:info_plist_file]

                unless info_plist.nil?
                    raise "Expected info plist file at #{info_plist}" unless File.exist?(info_plist)
                else
                    scheme = params[:scheme_name]
                    info_plist = "./#{scheme}/info.plist"

                    raise "Expected info plist file at #{info_plist}. Path was derived from schema name." unless File.exist?(info_plist)
                end

                return info_plist
            end
        end
    end
end