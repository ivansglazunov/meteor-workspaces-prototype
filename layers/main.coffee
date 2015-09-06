Blocks = @Blocks

if Meteor.isServer
    
    Sortable.collections = ['blocks']
    
if Meteor.isClient
    
    memory = {}
    
    memorize = (action, $this, event, blocks) ->
    
    Template.wsLayers.helpers
        layers: -> Blocks.find {}, { sort: { layer: 1 } }
    
    Template.wsLayer.events
        'mousedown [data-ws~="layer"]': (event, template) ->
            $layer = $(event.currentTarget).closest('[data-ws~="layer"]')
            
            if not event.ctrlKey and not $layer.is '.selected' then Blocks.find(selected: true).forEach (document) ->
                Blocks.update document._id, $set: selected: false
            Blocks.update template.data._id, $set: selected: if event.ctrlKey then !template.data.selected else true