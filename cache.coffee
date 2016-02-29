exports.init = (compound) ->

  TAFFY = require( 'taffy' ).taffy
  cache = {}
  cache.timeStamps = {}
  cache.dataset = TAFFY()

  _getAllOfModelFromDB = (_model, cb) ->
    modelFn = _model
    allFn = 'all'
    if compound.models[modelFn] is undefined
      throw new Error('Model [' + _model + '] not exists or is not defined.')
    compound.models[modelFn][allFn] (err, items) ->
      cache.dataset().filter({ model:_model }).remove()
      _items = []
      for item in items
        _item = item.toObject()
        _item['model'] = _model
        _items.push(_item)
      cache.dataset.insert(_items)
      cb(err, items)

  _getTimeStampFromDB = (model, cb) ->
    compound.models.Timestamp.find model + "TimeStamp", (err, docTS) ->
      if !err and docTS
        modelTS = docTS.v
        cache.timeStamps[model] = modelTS
        cb(err, modelTS)
      else
        toSave =
          id: model + "TimeStamp"
          v: JSON.stringify(new Date().valueOf())
        compound.models.Timestamp.create toSave, (err, docTS) =>
          modelTS = docTS.v
          cache.timeStamps[model] = modelTS
          cb(err, modelTS)

  # Reload from database the indicated document
  # @param {String} docId - document id
  # @param {Function} cb - Callback
  cache.reloadDoc = (docId, cb) ->
    db = compound.orm._schemas[0].adapter.db
    db.get docId, (err, doc) ->
      cache.dataset( { id:docId } )
        .update(doc)
      cb(err, doc)

  # Reload from database the indicated model
  # @param {String} model - model name
  # @param {Function} cb - Callback
  cache.reloadModel = (model, cb) ->
    _getTimeStampFromDB model, (err, modelTS) ->
      _getAllOfModelFromDB model, (err, items) ->
        cb(err, items)

  # Reload all models presents in the cache from database
  # @param {Function} cb - Callback
  cache.reloadAll = (cb) ->
    models = Object.keys(cache.timeStamps)
    compound.async.map models, (model, mapCallback) ->
      _getTimeStampFromDB model, (err, modelTS) ->
        _getAllOfModelFromDB model, (err, items) ->
          mapCallback(err, null)
    , cb

  # Clear from cache the indicated model
  # @param {String} model - model name
  # @param {Function} cb - Callback
  cache.clearModel = (model, cb) ->
    delete cache.timeStamps[model]
    cache.dataset().filter({ 'model': model }).remove()
    cb()


  # Return current timestamp for the indicated model
  # @param {String} model - model name
  # @param {Function} cb - Callback
  # @return {Int}
  cache.getTimeStamp = (model, cb) ->
    currentTS = cache.timeStamps[model]
    _getTimeStampFromDB model, (err, modelTS) ->
      if currentTS == modelTS
        cb(null, currentTS)
      else
        _getAllOfModelFromDB model, (err, items) ->
          cb(null, cache.timeStamps[model])

  # Set the timestamp for the indicated model
  # @param {String} model - model name
  # @param {String} value - value of timestamp
  cache.setTimeStamp = (model, value) ->
    if cache.timeStamps.hasOwnProperty(model)
      cache.timeStamps[model] = value
    else
      new Error('Model not exist in cache')

  # Append doc in the cache
  # @param {String} model - model name
  # @param {Object} doc - object to append
  # @param {Function} cb - Callback
  cache.append = (model, doc, cb) ->
    doc['model'] = model
    cache.dataset.insert([doc])
    _getTimeStampFromDB model, (err, modelTS) ->
      cb()

  # Delete from cache the indicated doc
  # @param {Object} doc - object to delete
  # @param {Function} cb - Callback
  cache.delete = (doc, cb) ->
    cache.dataset().filter({ id:doc.id }).remove()
    _getTimeStampFromDB doc.model, (err, modelTS) ->
      cb()

  # Replace existing doc for another
  # @param {Object} doc - object to set
  # @param {Function} cb - Callback
  cache.set = (doc, cb) ->
    cache.dataset({ id:doc.id }).update(doc)
    _getTimeStampFromDB doc.model, (err, modelTS) ->
      cb()

  # Return all docs for specific model
  # @param {String} model - model name
  # @param {Function} cb - Callback
  # @return {ListOfObjects}
  cache.all = (model, cb) ->
    currentTS = cache.timeStamps[model]
    _getTimeStampFromDB model, (err, modelTS) ->
      if not cache.timeStamps.hasOwnProperty(model)
        _getAllOfModelFromDB model, cb
      else
        if currentTS == modelTS
          items = cache.dataset().filter({model:model}).get()
          cb(null, items)
        else
          _getAllOfModelFromDB model, cb

  # Find in cache and return the document match with id value
  # @param {String} id - document id
  # @param {Function} cb - Callback
  # @return {Object}
  cache.get = (id, cb) ->
    _get = (doc, cb) ->
      _getAllOfModelFromDB doc.model, (err, items) ->
        item = cache.dataset().filter({ id:id }).first()
        cb(null, item)
    if id.length > 0
      db = compound.orm._schemas[0].adapter.db
      db.get id, (err, doc) ->
        if !err
          if doc.hasOwnProperty('model')
            currentTS = cache.timeStamps[doc.model]
            _getTimeStampFromDB doc.model, (err, modelTS) ->
              # check if the model timestamp
              # is the same in the database
              if currentTS == modelTS
                # check if doc exist in cache
                item = cache.dataset().filter({ id:id }).first()
                if item
                  cb(null, item)
                else
                  _get(doc, cb)
              else
                _get(doc, cb)
        else
          cb(err, doc)
    else
      cb(new Error('Document ID is not valid.'), null)

  # Return the value from reference doc
  # @param {String} itemId - id of reference doc
  # @param {String} keyRef - name of key in the reference doc
  # @param {Function} cb - Callback
  # Example:
  #   doc1 = {'id':'123', 'name':'John', 'country':'456', 'model':'Person'}
  #   doc2 = {'id':'456', 'name':'Spain', 'model':'Country'}
  #   cache.append(doc1)
  #   cache.append(doc2)
  #   cache.getReferenceId(doc1['country'], 'name')
  #   > Spain
  cache.getReferenceId = (itemId, keyRef, cb=null) ->
    item = cache.dataset().filter({ id:itemId }).first()
    item = item[keyRef]
    if cb
      cb(null, item)
    else
      item

  # Find documents in cache
  # @param {Object} query - key/values searched
  # @param {Function} cb - Callback
  # @return {ListOfObjects}
  cache.find = (query, cb=null) ->
    res = cache.dataset().filter(query).get()
    if cb
      cb(null, res)
    else
      res

  # Returns the first document found
  # @param {Object} query - key/values searched
  # @param {Function} cb - Callback
  # @return {Object}
  cache.findOne = (query, cb=null) ->
    res = cache.dataset().filter(query).first()
    if cb
      cb(null, res)
    else
      res

  # Looking first cache and if not found brings it from the database
  # @param {String} docId - document id
  # @param {Function} cb - Callback
  # @return {Object}
  cache.getEver = (docId, cb) ->
    res = cache.dataset().filter({'id':docId}).first()
    if res is false
      db = compound.orm._schemas[0].adapter.db
      db.get docId, cb
    else
      cb(null, res)

  # Returns the number of docs according <query>
  # @param {Object} query - search criteria
  # @param {Function} cb - Callback
  # @return {Int}
  cache.count = (query, cb=null) ->
    if typeof query == 'string'
      query =
        model: query
    res = cache.dataset().filter(query).get().length
    if cb
      cb(null, res)
    else
      res

  ###################################################################

  # set the namespace in compound.utils for 'cache'
  compound.utils.cache = cache