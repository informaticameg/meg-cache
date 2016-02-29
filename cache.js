exports.init = function(compound) {
  var TAFFY, _getAllOfModelFromDB, _getTimeStampFromDB, cache;
  TAFFY = require('taffy').taffy;
  cache = {};
  cache.timeStamps = {};
  cache.dataset = TAFFY();
  _getAllOfModelFromDB = function(_model, cb) {
    var allFn, modelFn;
    modelFn = _model;
    allFn = 'all';
    if (compound.models[modelFn] === void 0) {
      throw new Error('Model [' + _model + '] not exists or is not defined.');
    }
    return compound.models[modelFn][allFn](function(err, items) {
      var _item, _items, i, item, len;
      cache.dataset().filter({
        model: _model
      }).remove();
      _items = [];
      for (i = 0, len = items.length; i < len; i++) {
        item = items[i];
        _item = item.toObject();
        _item['model'] = _model;
        _items.push(_item);
      }
      cache.dataset.insert(_items);
      return cb(err, items);
    });
  };
  _getTimeStampFromDB = function(model, cb) {
    return compound.models.Timestamp.find(model + "TimeStamp", function(err, docTS) {
      var modelTS, toSave;
      if (!err && docTS) {
        modelTS = docTS.v;
        cache.timeStamps[model] = modelTS;
        return cb(err, modelTS);
      } else {
        toSave = {
          id: model + "TimeStamp",
          v: JSON.stringify(new Date().valueOf())
        };
        return compound.models.Timestamp.create(toSave, (function(_this) {
          return function(err, docTS) {
            modelTS = docTS.v;
            cache.timeStamps[model] = modelTS;
            return cb(err, modelTS);
          };
        })(this));
      }
    });
  };
  cache.reloadDoc = function(docId, cb) {
    var db;
    db = compound.orm._schemas[0].adapter.db;
    return db.get(docId, function(err, doc) {
      cache.dataset({
        id: docId
      }).update(doc);
      return cb(err, doc);
    });
  };
  cache.reloadModel = function(model, cb) {
    return _getTimeStampFromDB(model, function(err, modelTS) {
      return _getAllOfModelFromDB(model, function(err, items) {
        return cb(err, items);
      });
    });
  };
  cache.reloadAll = function(cb) {
    var models;
    models = Object.keys(cache.timeStamps);
    return compound.async.map(models, function(model, mapCallback) {
      return _getTimeStampFromDB(model, function(err, modelTS) {
        return _getAllOfModelFromDB(model, function(err, items) {
          return mapCallback(err, null);
        });
      });
    }, cb);
  };
  cache.clearModel = function(model, cb) {
    delete cache.timeStamps[model];
    cache.dataset().filter({
      'model': model
    }).remove();
    return cb();
  };
  cache.getTimeStamp = function(model, cb) {
    var currentTS;
    currentTS = cache.timeStamps[model];
    return _getTimeStampFromDB(model, function(err, modelTS) {
      if (currentTS === modelTS) {
        return cb(null, currentTS);
      } else {
        return _getAllOfModelFromDB(model, function(err, items) {
          return cb(null, cache.timeStamps[model]);
        });
      }
    });
  };
  cache.setTimeStamp = function(model, value) {
    if (cache.timeStamps.hasOwnProperty(model)) {
      return cache.timeStamps[model] = value;
    } else {
      return new Error('Model not exist in cache');
    }
  };
  cache.append = function(model, doc, cb) {
    doc['model'] = model;
    cache.dataset.insert([doc]);
    return _getTimeStampFromDB(model, function(err, modelTS) {
      return cb();
    });
  };
  cache["delete"] = function(doc, cb) {
    cache.dataset().filter({
      id: doc.id
    }).remove();
    return _getTimeStampFromDB(doc.model, function(err, modelTS) {
      return cb();
    });
  };
  cache.set = function(doc, cb) {
    cache.dataset({
      id: doc.id
    }).update(doc);
    return _getTimeStampFromDB(doc.model, function(err, modelTS) {
      return cb();
    });
  };
  cache.all = function(model, cb) {
    var currentTS;
    currentTS = cache.timeStamps[model];
    return _getTimeStampFromDB(model, function(err, modelTS) {
      var items;
      if (!cache.timeStamps.hasOwnProperty(model)) {
        return _getAllOfModelFromDB(model, cb);
      } else {
        if (currentTS === modelTS) {
          items = cache.dataset().filter({
            model: model
          }).get();
          return cb(null, items);
        } else {
          return _getAllOfModelFromDB(model, cb);
        }
      }
    });
  };
  cache.get = function(id, cb) {
    var _get, db;
    _get = function(doc, cb) {
      return _getAllOfModelFromDB(doc.model, function(err, items) {
        var item;
        item = cache.dataset().filter({
          id: id
        }).first();
        return cb(null, item);
      });
    };
    if (id.length > 0) {
      db = compound.orm._schemas[0].adapter.db;
      return db.get(id, function(err, doc) {
        var currentTS;
        if (!err) {
          if (doc.hasOwnProperty('model')) {
            currentTS = cache.timeStamps[doc.model];
            return _getTimeStampFromDB(doc.model, function(err, modelTS) {
              var item;
              if (currentTS === modelTS) {
                item = cache.dataset().filter({
                  id: id
                }).first();
                if (item) {
                  return cb(null, item);
                } else {
                  return _get(doc, cb);
                }
              } else {
                return _get(doc, cb);
              }
            });
          }
        } else {
          return cb(err, doc);
        }
      });
    } else {
      return cb(new Error('Document ID is not valid.'), null);
    }
  };
  cache.getReferenceId = function(itemId, keyRef, cb) {
    var item;
    if (cb == null) {
      cb = null;
    }
    item = cache.dataset().filter({
      id: itemId
    }).first();
    item = item[keyRef];
    if (cb) {
      return cb(null, item);
    } else {
      return item;
    }
  };
  cache.find = function(query, cb) {
    var res;
    if (cb == null) {
      cb = null;
    }
    res = cache.dataset().filter(query).get();
    if (cb) {
      return cb(null, res);
    } else {
      return res;
    }
  };
  cache.findOne = function(query, cb) {
    var res;
    if (cb == null) {
      cb = null;
    }
    res = cache.dataset().filter(query).first();
    if (cb) {
      return cb(null, res);
    } else {
      return res;
    }
  };
  cache.getEver = function(docId, cb) {
    var db, res;
    res = cache.dataset().filter({
      'id': docId
    }).first();
    if (res === false) {
      db = compound.orm._schemas[0].adapter.db;
      return db.get(docId, cb);
    } else {
      return cb(null, res);
    }
  };
  cache.count = function(query, cb) {
    var res;
    if (cb == null) {
      cb = null;
    }
    if (typeof query === 'string') {
      query = {
        model: query
      };
    }
    res = cache.dataset().filter(query).get().length;
    if (cb) {
      return cb(null, res);
    } else {
      return res;
    }
  };
  return compound.utils.cache = cache;
};