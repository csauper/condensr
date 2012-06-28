#!/usr/bin/ruby
#
# reorders clusters in canonical order
#

require 'rubygems'
require 'json'

order = { "food" => 1,
          "ambiance" => 2,
          "service" => 3,
          "value" => 4,
          "overall" => 5 }

clusters = JSON.parse(open("data/clusters-with-polarity.json").read)

clusters = clusters.collect{|pair|
    rest = pair[1]
    cur_order = rest.to_enum(:each_with_index).collect{|r| [r[0][0]["label"],r[1]]}
    sorting = cur_order.sort{|a,b| order[a[0]] <=> order[b[0]]}.collect{|i| i[1]}

    [pair[0], sorting.collect{|i| rest[i]}]
}

clusters = Hash[*clusters.flatten(1)]

puts JSON.generate(clusters)
