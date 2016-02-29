module.exports = (compound, Timespan) ->
  # define Timespan here

  Timespan.updateTS = (pluralmodel, value, cb) ->
    if typeof value == 'number'
      value = JSON.stringify(value)
    else if value is null
      value = JSON.stringify(new Date().valueOf())
    toSave =
      id: pluralmodel + "TimeSpan"
      v: value
    Timespan.find toSave.id, (err, mytimespan) =>
      if err
        compound.models.Timespan.create toSave, (err, timespan) =>
      else
        mytimespan.updateAttributes toSave, (err) =>
      cb()

  # agrega el nuevo doc a la cache sin
  # necesidad de recargar desde la bd
  Timespan.refreshCacheBeforeCreate = (ctrl, model, doc, cb=null) ->
    if compound.app.compound.orm._schemas[0].name != 'memory'
      newTS = new Date().valueOf()
      # append the doc
      doc = JSON.parse(JSON.stringify(doc))
      doc['model'] = model
      compound.meg.cache.dataset.insert([doc])
      # update the ts in cache
      compound.meg.cache.setTimeSpan(model, newTS)
      # update the ts in bd
      compound.models.Timespan.updateTS ctrl, newTS, () ->
        cb() if cb
    else
      cb() if cb

  # actualiza el doc en la cache sin
  # necesidad de recargar desde la bd
  Timespan.refreshCacheBeforeUpdate = (ctrl, model, doc, cb=null) ->
    if compound.app.compound.orm._schemas[0].name != 'memory'
      newTS = new Date().valueOf()
      # update the doc
      doc = JSON.parse(JSON.stringify(doc))
      doc['model'] = model
      compound.meg.cache.dataset({ id:doc.id }).update(doc)
      # update the ts in cache
      compound.meg.cache.setTimeSpan(model, newTS)
      # update the ts in bd
      compound.models.Timespan.updateTS ctrl, newTS, () ->
        cb() if cb
    else
      cb() if cb

  # elimina el doc de la cache sin
  # necesidad de recargar desde la bd
  Timespan.refreshCacheBeforeDestroy = (ctrl, model, doc, cb=null) ->
    if compound.app.compound.orm._schemas[0].name != 'memory'
      newTS = new Date().valueOf()
      # remove the doc
      compound.meg.cache.dataset().filter({ id:doc.id }).remove()
      # update the ts in cache
      compound.meg.cache.setTimeSpan(model, newTS)
      # update the ts in bd
      compound.models.Timespan.updateTS ctrl, newTS, () ->
        cb() if cb
    else
      cb() if cb