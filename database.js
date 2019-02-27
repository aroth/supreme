const Sequelize = require('sequelize');

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

Item.destroy({where: {}}).then(() => {
  Item.create({
    key1: 'k1',
    key2: 'k2',
    title: 'test title',
    url: 'http://sup.com',
    style: 'red',
    sizes: 's,m,l',
    price: '10.00',
    soldout: 0,
    epoch: 69,
  }).then(() => {
    Item.findAll().then(data => console.log(data[0].title));
  });
});
