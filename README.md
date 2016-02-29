# meg-cache

> Simple cache system for [Compound.js](http://compoundjs.com/) framework using the memory server

## Dependencies

* [Taffy.js](https://github.com/typicaljoe/taffydb)

## How to implement

1. Copy the cache.js file in root folder

2. Into /initializers/db-tools.js file import the following lines:
	```
	cache = require('../../cache')
	cache.init(compound)
	```

	From here you can access the library in `compound.utils.cache`


3. Create Timestamp model. In the db/schema.js file, add the following:
	```
	Timestamp = describe('Timestamp', function() {
  		property('id', String);
		property('v', String);
	});
	```

## Examples of use

### Filling cache at server startup
In this example using async.js be like this:

```js
compound.async.series([
  function(cb) {
    compound.meg.cache.all('Model1', cb);
  }, function(cb) {
    compound.meg.cache.all('Model2', cb);
  }, function(cb) {
    compound.meg.cache.all('Model3', cb);
  }, function(cb) {
    compound.meg.cache.all('Model4', cb);
  }
], function() {
	console.log('Loading models in cache ready...');
});
```

### Calling from model controller

```js
action('index', function() {
  respondTo(function(format) {
    format.json(function() {
	  // getting from cache
      compound.utils.cache.all('Model1', function(err, items) {
        send({ code: 200, data: items });
      });
    });
    format.html(function() {
      this.title = 'index';
      render();
    });
  });
});
```
### Finding objects

```js
compound.utils.cache.find({
  model: 'Person',
  sex: 'm',
  last_name: {
    like: 'smith'
  }
}, function(err, result) {
  return console.log(result);
});
```

For more information about writing queries see documentation ['Writing queries of Taffy.js'](http://www.taffydb.com/writingqueries)

## API

**cache.append(model, doc, cb)**
> Append doc in the cache


**cache.delete(doc, cb)**
> Delete from cache the indicated doc


**cache.set(doc, cb)**
> Replace existing doc for another


**cache.all(model, cb)**
> Return all docs for specific model


**cache.get(id, cb)**
> Find in cache and return the document match with id value


**cache.getEver(docId, cb)**
> Looking first cache and if not found brings it from the database


**cache.getReferenceId(itemId, keyRef, cb)**
> Return the value from reference doc

**cache.find(query, cb)**
> Find documents in cache

**cache.findOne(query, cb)**
> Returns the first document found

**cache.count(query, cb)**
> Returns the number of docs according <query>

**cache.reloadDoc(docId, cb)**
> Reload from database the indicated document

**cache.reloadModel(model, cb)**
> Reload from database the indicated model

**cache.reloadAll(cb)**
> Reload all models presents in the cache from database

**cache.clearModel(model, cb)**
> Clear from cache the indicated model

**cache.getTimeStamp(model, cb)**
> Return current timestamp for the indicated model

**cache.setTimeStamp(model, value)**
> Set the timestamp for the indicated model

**More details in cache.coffee file.**

## Helper functions defined in 'Timestamp.coffee'

Functions to refreshes the cache without reloading the entire model

**Timestamp.refreshCacheAfterCreate(ctrl, model, doc, cb)**

```js
action('create', function() {
    Person.create(req.body.Person, function (err, doc) {
        if (err) {
            flash('error', 'Person can not be created');
            render('new', { title: 'New person' });
        } else {
            flash('info', 'Person created');
			compound.models.Timestamp.refreshCacheAfterCreate('persons', 'Person', doc, function(){
            	redirect(path_to.models);
			});
        }
    });
});
```

**Timestamp.refreshCacheAfterUpdate(ctrl, model, doc, cb)**

```js
action('update', function() {
    this.person.updateAttributes(body.Person, function (err) {
        if (!err) {
            flash('info', 'Person updated');
			compound.models.Timestamp.refreshCacheAfterUpdate('persons', 'Person', this.person, function(){
            	redirect(path_to.person(this.person));
			)};
        } else {
            flash('error', 'Person can not be updated');
            this.title = 'Edit person details';
            render('edit');
        }
    }
});
```
**Timestamp.refreshCacheAfterDestroy(ctrl, model, doc, cb)**

```js
action('destroy', function() {
    this.person.destroy(function (error) {
        if (error) {
            flash('error', 'Can not destroy person');
        } else {
            flash('info', 'Person successfully removed');
			compound.models.Timestamp.refreshCacheAfterDestroy('persons', 'Person', this.person)
        }
        send("'" + path_to.persons + "'");
    });
});
```