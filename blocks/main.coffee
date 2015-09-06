Blocks = new Mongo.Collection 'blocks'

if Meteor.isClient
    
    # State in this moment
    memory = {}
    
    memorize = (action, $this, event, block) ->
        memory.action = action
        memory.event = event
        memory.$this = $this
        memory.block = block
        memory.height = memory.block.data.bottom - memory.block.data.top
        memory.width = memory.block.data.right - memory.block.data.left
    
    unmemorize = ->
        memory = {}
    
    snappable = (_id, block, inside = true, top = true, right = true, bottom = true, left = true) ->
        snaps = []
        
        $or = []
        
        if top
            if inside then $or.push { top: { $gt: block.top - 10, $lt: block.top + 10 } }
            $or.push { top: { $gt: block.bottom - 10, $lt: block.bottom + 10 } }
        
        if right
            if inside then $or.push { right: { $gt: block.right - 10, $lt: block.right + 10 } }
            $or.push { right: { $gt: block.left - 10, $lt: block.left + 10 } }
        
        if bottom
            if inside then $or.push { bottom: { $gt: block.bottom - 10, $lt: block.bottom + 10 } }
            $or.push { bottom: { $gt: block.top - 10, $lt: block.top + 10 } }
        
        if left
            if inside then $or.push { left: { $gt: block.left - 10, $lt: block.left + 10 } }
            $or.push { left: { $gt: block.right - 10, $lt: block.right + 10 } }
        
        Blocks
            .find
                _id: $not: _id
                $or: $or
            .forEach (snap) ->
                if top
                    if inside then if snap['top'] > block['top'] - 10 && snap['top'] < block['top'] + 10 then snaps.push block: snap, from: 'top', to: 'top'
                    if snap['top'] > block['bottom'] - 10 && snap['top'] < block['bottom'] + 10 then snaps.push block: snap, from: 'bottom', to: 'top'
                    
                if right
                    if inside then if snap['right'] > block['right'] - 10 && snap['right'] < block['right'] + 10 then snaps.push block: snap, from: 'right', to: 'right'
                    if snap['right'] > block['left'] - 10 && snap['right'] < block['left'] + 10 then snaps.push block: snap, from: 'left', to: 'right'
                    
                if bottom
                    if inside then if snap['bottom'] > block['bottom'] - 10 && snap['bottom'] < block['bottom'] + 10 then snaps.push block: snap, from: 'bottom', to: 'bottom'
                    if snap['bottom'] > block['top'] - 10 && snap['bottom'] < block['top'] + 10 then snaps.push block: snap, from: 'top', to: 'bottom'
                    
                if left
                    if inside then if snap['left'] > block['left'] - 10 && snap['left'] < block['left'] + 10 then snaps.push block: snap, from: 'left', to: 'left'
                    if snap['left'] > block['right'] - 10 && snap['left'] < block['right'] + 10 then snaps.push block: snap, from: 'right', to: 'left'
        
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
            
            # draggable
            if memory.action is 'draggable'
                
                $set = {}
                
                $set.top = memory.block.data.top + (event.clientY - memory.event.clientY)
                $set.left = memory.block.data.left + (event.clientX - memory.event.clientX)
                $set.right = $set.left + memory.width
                $set.bottom = $set.top + memory.height
                
                snaps = snappable memory.block.data._id, $set
                
                for snap in snaps
                    $set[snap.from] = snap.block[snap.to]
                    if snap.from is 'top' then $set.bottom = $set.top + memory.height
                    else if snap.from is 'right' then $set.left = $set.right - (memory.width)
                    else if snap.from is 'bottom' then $set.top = $set.bottom - (memory.height)
                    else if snap.from is 'left' then $set.right = $set.left + memory.width
            
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
                
                $set = {}
                snaps = []
                
                for action in actions
                    if action is 'n'
                        $set.top = memory.block.data.top + (event.clientY - memory.event.clientY) # top
                        $set.bottom = memory.block.data.bottom
                        snaps.push.apply snaps, snappable memory.block.data._id, $set, true, true, false, true, false
                    else if action is 'e'
                        $set.right = memory.block.data.right + (event.clientX - memory.event.clientX) #right
                        $set.left = memory.block.data.left
                        snaps.push.apply snaps, snappable memory.block.data._id, $set, true, false, true, false, true
                    else if action is 's'
                        $set.bottom = memory.block.data.bottom + (event.clientY - memory.event.clientY) # bottom
                        $set.top = memory.block.data.top
                        snaps.push.apply snaps, snappable memory.block.data._id, $set, true, true, false, true, false
                    else if action is 'w'
                        $set.left = memory.block.data.left + (event.clientX - memory.event.clientX) # left
                        $set.right = memory.block.data.right
                        snaps.push.apply snaps, snappable memory.block.data._id, $set, true, false, true, false, true
                        
                for snap in snaps
                    $set[snap.from] = snap.block[snap.to]
            
            # combinable
            else
                $block = $(event.target).closest '[data-ws~="block"]'
                $container = $block.children '[data-ws~="container"]'
                $place = $container.children '[data-ws~="placeholder"]'
                
                pos = combinable $block.attr('data-ws-top'), $block.attr('data-ws-left'), $block.attr('data-ws-width'), $block.attr('data-ws-height'), event
                
                if pos is 'center'
                    $place.css
                        width: '40%', height: '40%'
                        top: '30%', left: '30%'
                    
                else
                    if pos in ['top', 'bottom'] then $place.css width: '100%', height: '50%'
                    else if pos in ['left', 'right'] then $place.css width: '50%', height: '100%'
                    
                    if pos is 'top' then $place.css top: '0%', left: '0%'
                    else if pos is 'right' then $place.css top: '0%', left: '50%'
                    else if pos is 'bottom' then $place.css top: '50%', left: '0%'
                    else if pos is 'left' then $place.css top: '0%', left: '0%'
                
            if $set then Blocks.update memory.block.data._id, $set: $set
            
        'mouseup [data-ws~="blocks"]': (event) ->
            $('[data-ws~="block"]')
                .removeClass 'dragging'
                .removeClass 'resizing'
            if memory.block
                do unmemorize
    
    Template.wsBlocks.onRendered ->
        this.$('[data-ws~="blocks"]')
    
    Template.wsBlock.helpers
        height: -> this.bottom - this.top
        width: -> this.right - this.left
    
    Template.wsBlock.events
        'mousedown [data-ws~="block"] > [data-ws~="container"]': (event, block) ->
            if $(event.currentTarget).closest('[data-ws~="block"]').is "[data-ws-id~='#{block.data._id}']" # if not children
                if not memory.action
                    $(event.currentTarget).closest('[data-ws~="block"]').addClass 'dragging'
                    memorize 'draggable', block.$('[data-ws~="block"]:first-child'), event, block
            
        'mousedown [data-ws~="block"] > [data-ws~="container"] > [data-ws~="border"]': (event, block) ->
            if $(event.currentTarget).closest('[data-ws~="block"]').is "[data-ws-id~='#{block.data._id}']" # if not children
                if not memory.action
                    $(event.currentTarget).closest('[data-ws~="block"]').addClass 'resizing'
                    memorize 'resizable', $(event.currentTarget), event, block
            
        #'mouseout [data-ws~="block"]': (event, block) ->
            #if $(event.currentTarget).closest('[data-ws~="block"]').is "[data-ws-id~='#{block.data._id}']" # if not children
                #$block = $(event.target).closest '[data-ws~="block"]'
                #$container = $block.children '[data-ws~="container"]'
                #$place = $container.children '[data-ws~="placeholder"]'
                #$place.css
                    #width: 0, height: 0
                    #left: 0, top: 0
                #event.stopPropagation()
    
    Template.wsBlock.onRendered ->
        block = this
        $block = block.$('[data-ws~="block"]')