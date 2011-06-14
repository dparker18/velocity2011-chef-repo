#
# Author:: Joshua Timberman <joshua@opscode.com>
# Copyright:: 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef/handler'
require 'media_wiki'

module MediaWiki
  class ChefRunStatus < Chef::Handler

    def initialize(config={})
      @config = config
    end
    
    def report
      Chef::Log.info("Writing Chef run status for #{node.name} to MediaWiki page Chef_Run_Status.")
      mw = MediaWiki::Gateway.new(@config[:url])
      current = mw.get("Chef_Run_Status") || ""
      mw.edit(
        "Chef_Run_Status",
        if run_status.success?
          "Last Chef run on #{node.name} at #{run_status.end_time} was successful in #{run_status.elapsed_time} seconds."
        else
          "Last Chef run on #{node.name} at #{run_status.end_time} failed with exception #{run_status.exception} seconds."
        end + "\n\n#{current}"
      )
    end
    
  end
end
