require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'logger'

GOOD_CC = '4111 1111 1111 1112'
BAD_CC = '4111 1111 1111 1111'

ADD_TO_CART_SLEEP = 2
LOAD_CART_SLEEP = 2
LOAD_CHECKOUT_SLEEP = 2
SUBMIT_CHECKOUT_SLEEP = 2

USER_AGENT = 'Mac Safari'

CHECKOUT_ATTEMPTS = 3

agent = Mechanize.new { |agent|
  agent.user_agent_alias = USER_AGENT
}

accounts = []
accounts.push(
  {
    "order[billing_name]" => "Your Name",
    "order[email]" => "me@gmail.com",
    "order[tel]" => "1234445555",
    "order[billing_address]" => "1 Main St",
    "order[billing_address_2]" => "",
    "order[billing_zip]" => "112233",
    "order[billing_city]" => "Somewhere",
    "order[billing_state]" => "IL",
    "order[billing_country]" => "USA",
    "same_as_billing_address" => "1",
    "store_credit_id" => "1",
    "credit_card[nlb]" => GOOD_CC,
    "credit_card[month]" => "01",
    "credit_card[year]" => "2022",
    "credit_card[rvv]" => "222",

    "store_address" => 1,
    "credit_card[vval]" => "222",

    "order[terms]" => 1,
    "commit" => "process payment"
  }
)

puts "+---------------------------------------+"
puts "| Supreme Bot                       0.2 |"
puts "+---------------------------------------+"

## open most recent item file
latest = Dir.glob("items/*.json").max_by {|f| File.mtime(f)}
items = JSON.parse(File.read(latest))

puts " Read #{items.size} items (#{latest})"
puts "+---------------------------------------+"

accounts.each do |account|
  puts " Account: #{account["order[billing_name]"]}"
end

puts "+---------------------------------------+"

search = [
  { title: 'SEARCH QUERY GOES HERE' },
]

puts "Item search:"
search.each_with_index do |search, i|
  puts "  item #{i+1}"
  puts "     title: #{search[:title]}"
  puts "     style: #{search[:style]}"
  puts "      size: #{search[:size]}"
end

accounts.each do |account|
  matches = []

  search.each do |query|
    items.each do |item|
      # puts "#{item["title"]} vs #{query[:title]} (style: #{query[:style]}, #{query[:size]})"
      if item["title"].match(query[:title])
        next if query[:style] && !item["style"].match(query[:style])
        next if query[:size] && ! item["sizes"].include?(query[:size])
        matches.push item
      end
    end
  end


  puts "+---------------------------------------+"
  puts " Found #{matches.size} #{matches.size == 1 ? 'match' : 'matches'}" ## pluralize
  puts "+---------------------------------------+"

  matches.each do |item|
    sleep(ADD_TO_CART_SLEEP)

    ## OCTOBER 2017:
    ## -----------------
    ## OPTIMIZE FUTHER: do not fetch again... serailize
    ##   todo:  possible if we can save cookie state... could
    ##         save a nice amount of time; review later.
    ##
    ## MARCH 2018:
    ## -----------------
    ## ^^ not sure what I was talking about? nothing new

    puts "    title: #{item['title']} (#{item['key1']},#{item['key2']})"
    puts "      url: #{item['url']}"
    puts "    style: #{item['style']}"
    puts "    price: #{item['price']}"
    puts "  soldout: #{item['soldout']}"

    ## add item to cart
    agent.get(item['url']) do |item|
      page = item.form_with(:class => 'add')
      res = page.submit
      in_cart = res.body =~ /in cart/ ? 'yes' : 'no'
      puts "  in cart: #{in_cart}"
    end

    puts "\n"
  end

  if !matches.any?
    puts "Later, #failwhale.\n\n"
    exit
  end

  puts "Loading Cart...sleep (#{LOAD_CART_SLEEP})"
  sleep(LOAD_CART_SLEEP)


  agent.get('http://www.supremenewyork.com/shop/cart') do |cart|
    kart = cart.body

    matches.each do |match|
      if kart.match(match['key1']) && kart.match(match['key2'])
        puts " > #{match['title']}"
      else
        puts "  DID NOT FIND: #{match['title']}"
      end
    end
  end



  puts "\nLoading Checkout... (sleep: #{LOAD_CHECKOUT_SLEEP})"
  sleep(LOAD_CHECKOUT_SLEEP)

  ##
  ## UGH... getting 'card payment error' but the order went thru + confirmation email;
  ## set CHECKOUT_ATTEMPTS to > 1, confirm that attempt [n > 1] comes back as DUPE
  ##

  CHECKOUT_ATTEMPTS.times do
    agent.get('https://www.supremenewyork.com/checkout') do |checkout|
    form = checkout.form_with(:id => 'checkout_form') do |f|
      account.each do |k,v|
        f[k] = v
        puts "   Populating Form Field: #{ k } -> #{ v }"
      end
    end


    puts form.inspect

    puts "\nSubmitting Checkout... (sleep: #{SUBMIT_CHECKOUT_SLEEP})"
    sleep(SUBMIT_CHECKOUT_SLEEP)

    res = form.submit
    body = res.body

    if body =~ /credit card information/
      puts "  > Checkout page failed"
    elsif body =~ /Card Payment Error/ || body =~ /we cannot process your payment/
      puts "  > CC/Payment error"
    elsif body =~ /You have previously ordered this item/
      puts "  > Dupe purchase attempt"
    else
      puts "  > Uncertain status, review output"
    end

    epoch = Time.now.to_i.to_s
    filename = "output_#{epoch}.html"

    File.open("html/#{filename}", "w") { |file| file.write(res.body) }
    puts "  > wrote: html/#{filename}\n\n"
    end
  end
end
