require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'logger'
require 'json'

USER_AGENT = 'Mac Safari'
LOOKUP_SLEEP = 60
SKIP_SOLDOUT = true
HOST = 'http://www.supremenewyork.com'
ALL_URL = "#{HOST}/shop/all"

Dir.mkdir('html') unless File.exists?('html')
Dir.mkdir('items') unless File.exists?('items')

agent = Mechanize.new { |agent|
  agent.user_agent_alias = USER_AGENT
}

puts "+---------------------------------------+"
puts "| Supreme Bot: Item Fetcher         0.2 |"
puts "+---------------------------------------+"
puts "| LOOKUP_SLEEP: #{LOOKUP_SLEEP}"
puts "| SKIP_SOLDOUT: #{SKIP_SOLDOUT}"
puts "+---------------------------------------+"


while 420 != 710 do
  puts "Loading: #{ALL_URL}\n\n"

  items = []

  start =  Time.now.to_f
  agent.get(ALL_URL) do |page|
    doc = Nokogiri::HTML(page.body)
    doc.search('article a').each do |link|
      itemURL = "#{HOST}#{link.attributes['href']}"

      next if link.inner_html =~ /sold out/ && SKIP_SOLDOUT

      ## TODO: only get the item if its not sold out -- determine on index
      agent.get(itemURL) do |item|
        doc2 = Nokogiri::HTML(item.body)

        key1 = ''
        key2 = ''
        title = ''
        style = ''
        price = ''
        soldout = true
        sizes = []

        keys = link.attributes['href'].to_s.match(/([A-Z0-9]+)\/([A-Z0-9]+)$/i)

        key1 = keys[1]
        key2 = keys[2]

        doc2.search('#details h1').each do |res|
          title = res.children.first
        end

        doc2.search('.style').each do |res|
          style = res.children.first
        end

        doc2.search('.price span').each do |res|
          price = res.children.first
        end

        if item.body.match('sold out')
          soldout = true
        end

        puts "#{title} (style: #{style}, price: #{price})"

        doc2.search('#s option').each do |res|
            id = res.attributes['value']
            name = res.children.first
            sizes.push(name)
            # sizes.push({ id: id.to_s, name: name.to_s })
        end

        doc2.search('input[type="submit"]').each do |btn|
          if btn.attributes['value'].to_s == 'add to cart'
            soldout = false
          end
        end

        if 420 != 710 # !soldout && !SKIP_SOLDOUT
          items.push({
            key1: key1,
            key2: key2,
            url: itemURL,
            title: title.to_s,
            style: style.to_s,
            price: price.to_s,
            sizes: sizes,
            soldout: soldout
          })

        end
      end
    end
  end

  timestamp = Time.now.to_s.gsub(' ','_')
  ended =  Time.now.to_f
  diff = sprintf("%.4f", ended - start)

  puts "+---------------------------------------+"
  puts "took #{diff} seconds"

  ## Compare last with current ##

  ## open most recent item file
  latest = Dir.glob("items/*.json").max_by {|f| File.mtime(f)}

  if latest
    latest_items = File.read(latest)

    if latest_items == JSON.dump(items)
      puts "DUPLICATE ITEM ENTRY FOUND (#{latest})"
      puts "+---------------------------------------+"
      sleep(LOOKUP_SLEEP)
      next
    end
  end

  path = 'items/'
  filename = "items-#{timestamp}---#{diff}.json"

  File.open("#{path}#{filename}", 'w') do |file|
    file.write JSON.dump(items)
  end

  puts "Wrote #{ filename }, items: #{items.length} sleeping: Zzzzz #{LOOKUP_SLEEP}"
  puts "+---------------------------------------+"

  sleep(LOOKUP_SLEEP)
end
