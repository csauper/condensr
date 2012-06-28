(ns add-sentiment
  (:gen-class)
  (:require [clojure.contrib.json :as cc.json]))
  

(def positive-words
  #{"stellar" "tasty"  "friendly" "elegant" "rich" "nice"
    "pleasant" "good" "interesting" "fantastic" "stimulating"  "delightful" "great" "amazing" "favorite" "inexpensive" "fav" "happy"
    "favorites" "incredibly" "quality" "strong" "flavorful" "casual"
    "incredible" "outstanding" "recommend" "divine" "heaven" "efficient"
    "tender" "welcoming" "awesome" "impeccable" "delicious" "huge" "attentive" "polite" "sleek" "fresh" "wonderful" "fun" "chic" "patient" "knowledgable"
    "perfect" "prompt" "helpful" "phenomenal" "amazingly" "yummy" "love" "lovely" "speedy" "charming" "delish" "extraordinary" "freshest" "to-die-for"
    "excellent" "hip" "generous" "relaxed" "playful"})

(def reverse-words
  #{"not" "n't" "isn't" "nothing" "wasn't" "weren't" "aren't"})   
   
(def negative-words
  #{"bad" "gross" "sub-par" "awful" "pricey" "pushy" "spotty" "tiny" "tacky" "insipid" "horribly" "horrible" "boring" "disgusting" "sluggish" "inedible" "over-cooked" "overcooked" "mushy" "greasy" "confused" "lame" "dry" "meh" "impatient"
    "fatty" "annoyed" "salty" "mediocre" "unappetizing" "so-so" "tasteless" "cramped"
    "brusque" "worse" "worst" "average" "disappointed" "less" "underwhelming" "dingy" "slow" "bland" "uninspiring" "terrible" "overbearing" "unattentive" "poor"})   
   
(defn- polarity-score [words]
  (- 
    (count (filter 
              (fn [[prev-word word next-word ]]
                (and (not (reverse-words prev-word)) 
                     (not (reverse-words word))
                     (positive-words next-word)))
              (partition-all 3 1 words)))
    (count (filter 
              (fn [[prev-word word next-word ]]
                (and (not (reverse-words prev-word)) 
                     (not (reverse-words word))
                     (negative-words next-word)))
              (partition-all 3 1 words)))))
             
(defn- truncate [x]
  (cond
    (> x 0) 1
    (< x 0) -1
    :default 0))
    
(defn- elem-sent [elem]
  (concat ["<s>"] (.split (:phrase elem) "\\s+|[.?!,;]") ["</s>"]))    
        
(defn- to-polarity [x] 
  (cond (pos? x) :positive (neg? x) :negative :else :neutral))        
            
(defn majority-polarity [scores]
  (let [num-pos (count (filter pos? scores))
        num-neg (count (filter neg? scores))]
    (cond (and (zero? num-pos) (zero? num-neg)) :neutral
         (>= num-pos num-neg) :positive
         :else :negative)))  

(defn filter-majority [cluster majority]
  (for [elem cluster 
         :let [polarity (-> elem elem-sent polarity-score to-polarity)]
         :when (or (= polarity :neutral) (= polarity majority))]
          elem))
  
(defn- transform-cluster [cluster]
  (let [sents (map elem-sent cluster)
        scores (map polarity-score sents)        
        to-score (fn [x] (case x :positive 1 :negative -1 :neutral 0))
        majority  (majority-polarity scores)
        filtered (sort-by (fn [elem] (- (Math/abs (polarity-score (elem-sent elem)))))
                          (filter-majority cluster majority))]
    (cons
      (assoc (first filtered) :polarity (to-score majority))
      (rest filtered))))              

  
(defn- transform-data [data]
  (into {}
    (for [[rest-id clusters] data]
      [rest-id (map transform-cluster clusters)])))  
  
(defn -main [& args]
  (let [data (-> args first slurp (cc.json/read-json true))
        outdata (transform-data data)]    
    (cc.json/pprint-json outdata)))
    
(-main "data/clusters.json")
