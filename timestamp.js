module.exports = function(compound, Timestamp) {
  Timestamp.updateTS = function(model, value, cb) {
    var toSave;
    if (typeof value === 'number') {
      value = JSON.stringify(value);
    } else if (value === null) {
      value = JSON.stringify(new Date().valueOf());
    }
    toSave = {
      id: model + "Timestamp",
      v: value
    };
    return Timestamp.find(toSave.id, (function(_this) {
      return function(err, myTimestamp) {
        if (err) {
          compound.models.Timestamp.create(toSave, function(err, doc) {});
        } else {
          myTimestamp.updateAttributes(toSave, function(err) {});
        }
        return cb();
      };
    })(this));
  };
  Timestamp.refreshCacheAfterCreate = function(ctrl, model, doc, cb) {
    var newTS;
    if (cb == null) {
      cb = null;
    }
    newTS = new Date().valueOf();
    doc = JSON.parse(JSON.stringify(doc));
    doc['model'] = model;
    compound.utils.cache.dataset.insert([doc]);
    compound.utils.cache.setTimeStamp(model, newTS);
    return compound.models.Timestamp.updateTS(ctrl, newTS, function() {
      if (cb) {
        return cb();
      }
    });
  };
  Timestamp.refreshCacheAfterUpdate = function(ctrl, model, doc, cb) {
    var newTS;
    if (cb == null) {
      cb = null;
    }
    newTS = new Date().valueOf();
    doc = JSON.parse(JSON.stringify(doc));
    doc['model'] = model;
    compound.utils.cache.dataset({
      id: doc.id
    }).update(doc);
    compound.utils.cache.setTimeStamp(model, newTS);
    return compound.models.Timestamp.updateTS(ctrl, newTS, function() {
      if (cb) {
        return cb();
      }
    });
  };
  return Timestamp.refreshCacheAfterDestroy = function(ctrl, model, doc, cb) {
    var newTS;
    if (cb == null) {
      cb = null;
    }
    newTS = new Date().valueOf();
    compound.utils.cache.dataset().filter({
      id: doc.id
    }).remove();
    compound.utils.cache.setTimeStamp(model, newTS);
    return compound.models.Timestamp.updateTS(ctrl, newTS, function() {
      if (cb) {
        return cb();
      }
    });
  };
};