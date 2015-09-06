Blocks = new Mongo.Collection 'blocks'

if Meteor.isClient
    
    # State in this moment
    memory = {}
    
    # (action: string, $this: $, event: jQuery.Event, blocks: Array<{ template: Blaze.TemplateInstance }>)
    memorize = (action, $this, event, blocks) ->
        memory.action = action
        memory.event = event
        memory.$this = $this
        memory.blocks = blocks
        for block in memory.blocks
            block.height = block.template.data.bottom - block.template.data.top
            block.width = block.template.data.right - block.template.data.left
    
    unmemorize = ->
        memory = {}
    
    snappable = (_id, data, inside = true, top = true, right = true, bottom = true, left = true) ->
        snaps = []
        
        $or = []
        
        if top
            if inside then $or.push { top: { $gt: data.top - 10, $lt: data.top + 10 } }
            $or.push { top: { $gt: data.bottom - 10, $lt: data.bottom + 10 } }
        
        if right
            if inside then $or.push { right: { $gt: data.right - 10, $lt: data.right + 10 } }
            $or.push { right: { $gt: data.left - 10, $lt: data.left + 10 } }
        
        if bottom
            if inside then $or.push { bottom: { $gt: data.bottom - 10, $lt: data.bottom + 10 } }
            $or.push { bottom: { $gt: data.top - 10, $lt: data.top + 10 } }
        
        if left
            if inside then $or.push { left: { $gt: data.left - 10, $lt: data.left + 10 } }
            $or.push { left: { $gt: data.right - 10, $lt: data.right + 10 } }
        
        Blocks
            .find
                _id: $not: _id
                $or: $or
            .forEach (snap) ->
                if top
                    if inside then if snap['top'] > data['top'] - 10 && snap['top'] < data['top'] + 10 then snaps.push document: snap, from: 'top', to: 'top'
                    if snap['top'] > data['bottom'] - 10 && snap['top'] < data['bottom'] + 10 then snaps.push document: snap, from: 'bottom', to: 'top'
                    
                if right
                    if inside then if snap['right'] > data['right'] - 10 && snap['right'] < data['right'] + 10 then snaps.push document: snap, from: 'right', to: 'right'
                    if snap['right'] > data['left'] - 10 && snap['right'] < data['left'] + 10 then snaps.push document: snap, from: 'left', to: 'right'
                    
                if bottom
                    if inside then if snap['bottom'] > data['bottom'] - 10 && snap['bottom'] < data['bottom'] + 10 then snaps.push document: snap, from: 'bottom', to: 'bottom'
                    if snap['bottom'] > data['top'] - 10 && snap['bottom'] < data['top'] + 10 then snaps.push document: snap, from: 'top', to: 'bottom'
                    
                if left
                    if inside then if snap['left'] > data['left'] - 10 && snap['left'] < data['left'] + 10 then snaps.push document: snap, from: 'left', to: 'left'
                    if snap['left'] > data['right'] - 10 && snap['left'] < data['right'] + 10 then snaps.push document: snap, from: 'right', to: 'left'
        
        return snaps
    
    combinable = (top, left, width, height, event) ->
        t = (event.clientY - top) / (height / 100)
        l = (event.clientX - left) / (width / 100)
        r = 100 - l
        b = 100 - t
        
        pos =
            if (t > 30 && t < 70 && l > 30 && l < 70) then 'center'
            else if (t < l && t < r) then 'top'
            else if (b < l && b < r) then 'bottom'
            else if (r < t && r < b) then 'right'
            else if (l < t && l < b) then 'left'
            else 'center'
            
    reCombinable = (pos) ->
        if pos is 'top' then return 'bottom'
        if pos is 'right' then return 'left'
        if pos is 'bottom' then return 'top'
        if pos is 'left' then return 'right'
        
        console.war "The position '#{pos}' is not correct to invert."
        
        return pos
    
    Template.wsBlocks.helpers
        blocks: -> return Blocks.find()
    
    Template.wsBlocks.events
        
        # insert new block
        'click [data-ws~="insert button"]': -> Blocks.insert
            left: 0, top: 0
            right: 100, bottom: 100
        
        # toggle snap
        'click [data-ws~="snap button"]': (event) ->
            $(event.currentTarget).toggleClass 'active'
        
        'mousemove [data-ws~="blocks"]': (event) ->
            $sets = {};
            
            # draggable
            if memory.action is 'draggable'
                Y = (event.clientY - memory.event.clientY)
                X = (event.clientX - memory.event.clientX)
                
                for block in memory.blocks
                    $set = {}
                    
                    $set.top = block.template.data.top + Y
                    $set.left = block.template.data.left + X
                    $set.right = $set.left + block.width
                    $set.bottom = $set.top + block.height
                    
                    snaps = snappable block.template.data._id, $set
                    
                    for snap in snaps
                        $set[snap.from] = snap.document[snap.to]
                        if snap.from is 'top' then $set.bottom = $set.top + block.height
                        else if snap.from is 'right' then $set.left = $set.right - block.width
                        else if snap.from is 'bottom' then $set.top = $set.bottom - block.height
                        else if snap.from is 'left' then $set.right = $set.left + block.width
                    
                    $sets[block.template.data._id] = $set
                
                # combinable
                if false
                    $block = $(event.target).closest '[data-ws~="block"]'
                    $container = $block.children '[data-ws~="container"]'
                    $place = $container.children '[data-ws~="placeholder"]'
                    
                    pos = combinable $block.attr('data-ws-top'), $block.attr('data-ws-left'), $block.attr('data-ws-width'), $block.attr('data-ws-height'), event
                    
                    if pos is 'center'
                        $place.prop("disabled", false).css
                            width: '40%', height: '40%'
                            top: '30%', left: '30%'
                        
                    else
                        if pos in ['top', 'bottom'] then $place.prop("disabled", false).css width: '100%', height: '50%'
                        else if pos in ['left', 'right'] then $place.prop("disabled", false).css width: '50%', height: '100%'
                        
                        if pos is 'top' then $place.prop("disabled", false).css top: '0%', left: '0%'
                        else if pos is 'right' then $place.prop("disabled", false).css top: '0%', left: '50%'
                        else if pos is 'bottom' then $place.prop("disabled", false).css top: '50%', left: '0%'
                        else if pos is 'left' then $place.prop("disabled", false).css top: '0%', left: '0%'
                        
                        else $place.prop("disabled", true)
            
            # resizable
            else if memory.action is 'resizable'
                actions = []
                
                if memory.$this.is '[data-ws~="n"]' then actions.push 'n'
                else if memory.$this.is '[data-ws~="ne"]' then actions.push 'n', 'e'
                else if memory.$this.is '[data-ws~="e"]' then actions.push 'e'
                else if memory.$this.is '[data-ws~="es"]' then actions.push 'e', 's'
                else if memory.$this.is '[data-ws~="s"]' then actions.push 's'
                else if memory.$this.is '[data-ws~="sw"]' then actions.push 's', 'w'
                else if memory.$this.is '[data-ws~="w"]' then actions.push 'w'
                else if memory.$this.is '[data-ws~="wn"]' then actions.push 'w', 'n'
                
                snaps = []
                
                Y = (event.clientY - memory.event.clientY)
                X = (event.clientX - memory.event.clientX)
                
                for block in memory.blocks
                
                    $set = {}
                    
                    for action in actions
                        if action is 'n'
                            $set.top = block.template.data.top + (event.clientY - memory.event.clientY) # top
                            $set.bottom = block.template.data.bottom
                            snaps.push.apply snaps, snappable block.template.data._id, $set, true, true, false, true, false
                        else if action is 'e'
                            $set.right = block.template.data.right + (event.clientX - memory.event.clientX) #right
                            $set.left = block.template.data.left
                            snaps.push.apply snaps, snappable block.template.data._id, $set, true, false, true, false, true
                        else if action is 's'
                            $set.bottom = block.template.data.bottom + (event.clientY - memory.event.clientY) # bottom
                            $set.top = block.template.data.top
                            snaps.push.apply snaps, snappable block.template.data._id, $set, true, true, false, true, false
                        else if action is 'w'
                            $set.left = block.template.data.left + (event.clientX - memory.event.clientX) # left
                            $set.right = block.template.data.right
                            snaps.push.apply snaps, snappable block.template.data._id, $set, true, false, true, false, true
                            
                    for snap in snaps
                        $set[snap.from] = snap.document[snap.to]
                    
                    $sets[block.template.data._id] = $set
            
            for _id, $set of $sets
                Blocks.update _id, $set: $set
            
        'mouseup [data-ws~="blocks"]': (event) ->
            $('[data-ws~="block"]')
                .removeClass 'dragging'
                .removeClass 'resizing'
            if memory.blocks
                do unmemorize
    
    Template.wsBlocks.onRendered ->
        this.$('[data-ws~="blocks"]')
    
    Template.wsBlock.helpers
        height: -> this.bottom - this.top
        width: -> this.right - this.left
    
    Template.wsBlock.events
        'mousedown [data-ws~="block"] > [data-ws~="container"]': (event, template) ->
            if $(event.currentTarget).closest('[data-ws~="block"]').is "[data-ws-id~='#{template.data._id}']" # if not children
                if not memory.action
                    $(event.currentTarget).closest('[data-ws~="block"]').addClass 'dragging'
                    memorize 'draggable', template.$('[data-ws~="block"]:first-child'), event, [ template: template ]
            
        'mousedown [data-ws~="block"] > [data-ws~="container"] > [data-ws~="border"]': (event, template) ->
            if $(event.currentTarget).closest('[data-ws~="block"]').is "[data-ws-id~='#{template.data._id}']" # if not children
                if not memory.action
                    $(event.currentTarget).closest('[data-ws~="block"]').addClass 'resizing'
                    memorize 'resizable', $(event.currentTarget), event, [ template: template ]
            
        #'mouseout [data-ws~="block"]': (event, template) ->
            #if $(event.currentTarget).closest('[data-ws~="block"]').is "[data-ws-id~='#{template.data._id}']" # if not children
                #$block = $(event.target).closest '[data-ws~="block"]'
                #$container = $block.children '[data-ws~="container"]'
                #$place = $container.children '[data-ws~="placeholder"]'
                #$place.css
                    #width: 0, height: 0
                    #left: 0, top: 0
            
            event.stopPropagation()
    
    Template.wsBlock.onRendered ->
        block = this
        $block = block.$('[data-ws~="block"]')