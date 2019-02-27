// deps
const fetch = require('node-fetch');
const createThrottle = require('async-throttle');
const cheerio = require('cheerio').load;

const Sequelize = require('sequelize');
var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database(':memory:');

const THROTTLE_COUNT = 3;
const HOST = `http://www.supremenewyork.com`;
const ALL_URL = `${HOST}/shop/all`;

var sequelize = new Sequelize('supreme.db', '', '', {
  host: 'localhost',
  dialect: 'sqlite',

  pool: {
    max: 5,
    min: 0,
    idle: 10000,
  },

  storage: 'supreme.db',
});

const Item = sequelize.define('item', {
  id: {
    type: Sequelize.INTEGER,
    field: 'id',
    primaryKey: true,
  },
  key1: {
    type: Sequelize.STRING,
    field: 'key1',
  },
  key2: {
    type: Sequelize.STRING,
    field: 'key2',
  },
  url: {
    type: Sequelize.STRING,
    field: 'url',
  },
  title: {
    type: Sequelize.STRING,
    field: 'title',
  },
  style: {
    type: Sequelize.STRING,
    field: 'style',
  },
  price: {
    type: Sequelize.STRING,
    field: 'price',
  },
  sizes: {
    type: Sequelize.STRING,
    field: 'sizes',
  },
  soldout: {
    type: Sequelize.INTEGER,
    field: 'soldout',
  },
  epoch: {
    type: Sequelize.INTEGER,
    field: 'epoch',
  },
});

const throttle = createThrottle(THROTTLE_COUNT);

fetch(ALL_URL).then(res => res.text()).then(data => {
  const $ = cheerio(data);
  const items = $('article a');

  console.log(`Found ${items.length} items`);

  Promise.all(
    items.each((i, item) => {
      throttle(async () => {
        const itemURL = `${HOST}/${item.attribs['href']}`;

        const res = await fetch(itemURL);
        const data = await res.text();
        const $ = cheerio(data);

        const title = $('#details h1').html();
        const style = $('.style').html();
        const price = $('.price span').html();
        const soldout = 0; // TODO

        const options = [];
        $('#s option').each((i, option) => {
          options.push(option.children[0].data);
        });

        let opt_string = options.join(',');

        const m = itemURL.match(/([A-Z0-9]+)\/([A-Z0-9]+)$/i);
        const key1 = m[1];
        const key2 = m[2];

        console.log(itemURL);
        console.log(key1);
        console.log(key2);
        console.log(title);
        console.log(style);
        console.log(price);
        console.log(opt_string);

        Item.create({
          key1,
          key2,
          title,
          url: itemURL,
          style: style,
          sizes: opt_string,
          price: price,
          soldout: soldout,
          epoch: 69,
        });

        console.log('--------------------------------');

        return $('title').text();
      });
    })
  ).then(titles => console.log('Titles:', titles));
});
