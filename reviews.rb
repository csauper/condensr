require 'rubygems'
require 'sinatra'
require 'erb'
require 'open-uri'
require 'json'
require 'pp'
require 'set'
require 'fastercsv'

YWSID="vsv3ryShkzn7JpTc8V5XBw"

#FILTER = Hash[*open("data/ids_ordered").readlines.collect{|l| l.strip.split}.flatten]
#PHRASES = Hash.new(Array.new)
#FasterCSV.read("data/restaurant_procons.csv",:headers => true).each{|d| PHRASES[d["rest_id"].to_i] += [d]}
# PHRASES = PHRASES.sort.collect{|l| l[1]}.collect{|d| d.sort{|a,b| b["score"].to_i <=> a["score"].to_i}.collect{|r| r["phrase"]}[0..5]}
PHRASE_CLUSTERS =  JSON.parse(open("data/clusters-reordered.json").read)
ID_CONVERSION = Hash[*open("data/url_hash").readlines.collect{|i| i.strip.split}.flatten]

$KCODE = 'u' if RUBY_VERSION < '1.9'
before do
      content_type :html, 'charset' => 'utf-8'
end

def getNearby(loc, radius, term, category)  
  # Returns JSON from request
  req = 'http://api.yelp.com/business_review_search' +
        ('?location=' + loc) +
        (term and term != '' ? ('&term=' + term) : '') +
        ('&radius=' + radius.to_s) +
        (category and category != '' ? ('&category=' + category) : '') +
        ("&limit=20") + 
        ('&ywsid=' + YWSID)
  # need to escape req for space and &s
  return JSON.parse(URI.parse(URI.escape(req)).read)
end

get '/christy-test' do
    @rests = getNearby(params[:loc],"2",params[:term],"")["businesses"]
    @rests.select{|r| r["review_count"] > 20}.collect{|r| "#{r["url"]} #{r["id"]}"}.join("\n") + "\n"
    #@rests.collect{|r| r["review_count"]}.join("<br>")
end

get '/aria-test' do
  "<h1>Hey There</h1>"
  pp getNearby("101 Landsdowne Cambridge MA", "2", "pizza", "")
end  


get '/search' do
    @first = false;
    @rests = getNearby(params[:loc],"2",params[:term],"")["businesses"]
    @rests = @rests.select{|r| PHRASE_CLUSTERS.has_key? r["id"]}    
    @rest_clusters = Hash[*@rests.collect{ |r| 
      [r["id"],PHRASE_CLUSTERS[r["id"]].to_json]
    }.flatten]    
    erb :index
end

get '/' do
    @params[:loc] = "Boston, MA"
    @params[:term] = "restaurant"
    @first = true;
    @rests = getNearby(@params[:loc],"2",@params[:term],"")["businesses"] 
    @rests = @rests.select{|r| PHRASE_CLUSTERS.has_key?(r["id"])}
    @rest_clusters = Hash[*@rests.collect{ |r| 
      [r["id"],PHRASE_CLUSTERS[r["id"]].to_json]
    }.flatten]    
    erb :index
end

get '/browse' do
    @params[:start] = @params[:start].nil? ? 0 : @params[:start].to_i
    @rests = JSON.parse(open("data/restdata.json").read)
    @rests = @rests.select{|r| PHRASE_CLUSTERS.has_key?(ID_CONVERSION[r["id"]])}
    @rest_clusters = Hash[*@rests.collect{ |r| 
      [r["id"],PHRASE_CLUSTERS[ID_CONVERSION[r["id"]]].to_json]
    }.flatten]    
    erb :tooltips
end
