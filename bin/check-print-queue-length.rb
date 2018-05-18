#! /usr/bin/env ruby
#
# check-print-queue-length
#
# DESCRIPTION:
#   a check to see if any print queue has a large amount of documents waiting to print
# OUTPUT:
#   Plain text
#
# PLATFORMS:
#   Windows
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: win32ole
# LICENSE:
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#
require 'sensu-plugin/check/cli'

class PrintQueueLength < Sensu::Plugin::Check::CLI
    option :Name,
        long: '--PrintQueue',
        short: '-p QueueName',
        default: :all
    option :warn,
        long: '--warning',
        short: '-w VAL',
        default: 4
    option :crit,
        long: '--critical',
        short: '-c VAL',
        default: 8

    def run
        require 'win32ole'
        wmi = WIN32OLE.connect("winmgmts:\\\\.\\root\\cimv2")
        if config[:Name] == :all
            queues = wmi.ExecQuery("SELECT * FROM Win32_PrintJob")
        else
            queues = wmi.ExecQuery("SELECT * FROM Win32_PrintJob WHERE name = '#{config[:Name]}'")
        end
        counts = Hash.new(0)
        queues.each do |q|
            counts[q.name.split(',')[0]] += 1
        end

        ok, warn, crit = Array.new, Array.new, Array.new

        counts.each do |q, v|
            case v
            when 0..:warn
                ok.push(q)
            when :warn..:crit
                warn.push(q)
            else
                crit.push(q)
            end
        end

        critical "#{crit} queues are above #{config[:crit]}" unless crit.empty?
        warning "#{warn} queues are above #{config[:warn]}" unless warn.empty?
        ok "#{ok} queues are below #{config[:warn]}" unless ok.empty?
    end
end
