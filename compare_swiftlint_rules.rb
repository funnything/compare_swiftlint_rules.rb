#!/usr/bin/env ruby

require 'set'

def rules_from_command
  `Pods/SwiftLint/swiftlint rules`.each_line.map do |line|
    if match = line.match(/^\| ([^ ]+) +\| (yes|no) +\|/)
      { identifier: match[1], opt_in: match[2] == 'yes' }
    end
  end.compact
end

def opt_in_rules_in_config
  rules = []

  in_opt_in_rules = false
  IO.foreach('.swiftlint.yml', chomp: true).map do |line|
    if in_opt_in_rules
      break unless line.start_with?(' ') || line =~ /^ *#/
      raise line unless match = line.match(/- (.+)$/)
      rules << match[1]
    else
      in_opt_in_rules = true if line == 'opt_in_rules:'
    end
  end

  rules
end

command_rules = rules_from_command
config_rules = Set.new(opt_in_rules_in_config)

deco = '#' * 32

puts "#{deco} New rules #{deco}"
command_rules.filter { |rule| rule[:opt_in] }.map { |rule| rule[:identifier] }.each do |rule|
  if config_rules.include?(rule)
    config_rules.delete(rule)
  else
    puts rule
  end
end

puts "#{deco} Old rules #{deco}"
puts config_rules.to_a
