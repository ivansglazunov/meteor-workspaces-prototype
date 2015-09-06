@Blocks = Blocks = new Mongo.Collection 'blocks'

if Meteor.isClient
    
    # State or draggable and resizable
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
    
    snappable = (_id, data, top = true, right = true, bottom = true, left = true, horizontal = true, vertical = true) ->
        snaps = []
        
        $or = []
        
        data.horizontal = ((data.bottom - data.top) / 2) + data.top
        data.vertical = ((data.right - data.left) / 2) + data.left
        
        if top
            $or.push { top: { $gt: data.top - 10, $lt: data.top + 10 } }
            $or.push { top: { $gt: data.bottom - 10, $lt: data.bottom + 10 } }
            $or.push { top: { $gt: data.horizontal - 10, $lt: data.horizontal + 10 } }
        
        if right
            $or.push { right: { $gt: data.right - 10, $lt: data.right + 10 } }
            $or.push { right: { $gt: data.left - 10, $lt: data.left + 10 } }
            $or.push { right: { $gt: data.vertical - 10, $lt: data.vertical + 10 } }
        
        if bottom
            $or.push { bottom: { $gt: data.bottom - 10, $lt: data.bottom + 10 } }
            $or.push { bottom: { $gt: data.top - 10, $lt: data.top + 10 } }
            $or.push { bottom: { $gt: data.horizontal - 10, $lt: data.horizontal + 10 } }
        
        if left
            $or.push { left: { $gt: data.left - 10, $lt: data.left + 10 } }
            $or.push { left: { $gt: data.right - 10, $lt: data.right + 10 } }
            $or.push { left: { $gt: data.vertical - 10, $lt: data.vertical + 10 } }
        
        if horizontal
            $or.push { $where: "((this.bottom - this.top) / 2) + this.top > #{ (data.top - 10) } && ((this.bottom - this.top) / 2) + this.top < #{ (data.top + 10) }" }
            $or.push { $where: "((this.bottom - this.top) / 2) + this.top > #{ (data.bottom - 10) } && ((this.bottom - this.top) / 2) + this.top < #{ (data.bottom + 10) }" }
            $or.push { $where: "((this.bottom - this.top) / 2) + this.top > #{ (data.horizontal - 10) } && ((this.bottom - this.top) / 2) + this.top < #{ (data.horizontal + 10) }" }
        
        if vertical
            $or.push { $where: "((this.right - this.left) / 2) + this.left > #{ (data.left - 10) } && ((this.right - this.left) / 2) + this.left < #{ (data.left + 10) }" }
            $or.push { $where: "((this.right - this.left) / 2) + this.left > #{ (data.right - 10) } && ((this.right - this.left) / 2) + this.left < #{ (data.right + 10) }" }
            $or.push { $where: "((this.right - this.left) / 2) + this.left > #{ (data.vertical - 10) } && ((this.right - this.left) / 2) + this.left < #{ (data.vertical + 10) }" }
        
        Blocks
            .find
                _id: $not: _id
                $or: $or
            .forEach (snap) ->
                if top
                    if snap['top'] > data['top'] - 10 && snap['top'] < data['top'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'top', to: 'top'
                    if snap['top'] > data['bottom'] - 10 && snap['top'] < data['bottom'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'bottom', to: 'top'
                    if snap['top'] > data['horizontal'] - 10 && snap['top'] < data['horizontal'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'horizontal', to: 'top'
                    
                if right
                    if snap['right'] > data['right'] - 10 && snap['right'] < data['right'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'right', to: 'right'
                    if snap['right'] > data['left'] - 10 && snap['right'] < data['left'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'left', to: 'right'
                    if snap['right'] > data['vertical'] - 10 && snap['right'] < data['vertical'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'vertical', to: 'right'
                    
                if bottom
                    if snap['bottom'] > data['bottom'] - 10 && snap['bottom'] < data['bottom'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'bottom', to: 'bottom'
                    if snap['bottom'] > data['top'] - 10 && snap['bottom'] < data['top'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'top', to: 'bottom'
                    if snap['bottom'] > data['horizontal'] - 10 && snap['bottom'] < data['horizontal'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'horizontal', to: 'bottom'
                    
                if left
                    if snap['left'] > data['left'] - 10 && snap['left'] < data['left'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'left', to: 'left'
                    if snap['left'] > data['right'] - 10 && snap['left'] < data['right'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'right', to: 'left'
                    if snap['left'] > data['vertical'] - 10 && snap['left'] < data['vertical'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'vertical', to: 'left'
                
                if horizontal
                    v = ((snap['bottom'] - snap['top']) / 2) + snap['top']
                    if v > data['top'] - 10 && v < data['top'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'top', to: 'horizontal'
                    if v > data['bottom'] - 10 && v < data['bottom'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'bottom', to: 'horizontal'
                    if v > data['horizontal'] - 10 && v < data['horizontal'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'horizontal', to: 'horizontal'
                
                if vertical
                    v = ((snap['right'] - snap['left']) / 2) + snap['left']
                    if v > data['left'] - 10 && v < data['left'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'left', to: 'vertical'
                    if v > data['right'] - 10 && v < data['right'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'right', to: 'vertical'
                    if v > data['vertical'] - 10 && v < data['vertical'] + 10 then snaps.push horizontal: data.horizontal, vertical: data.vertical, document: snap, from: 'vertical', to: 'vertical'
        
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
            
    revert = (pos) ->
        if pos is 'top' then return 'bottom'
        if pos is 'right' then return 'left'
        if pos is 'bottom' then return 'top'
        if pos is 'left' then return 'right'
        
        console.war "The position '#{pos}' is not correct to invert."
        
        return pos
    
    Session.setDefault 'zoom', 1
    
    Template.wsBlocks.helpers
        blocks: -> Blocks.find {}, { sort: { layer: 1 } }
        zoom: -> Session.get 'zoom'
    
    Template.wsBlocks.events
        
        # insert new block
        'click [data-ws~="insert button"]': ->
            max = Blocks.findOne layer: $exists: true,
                sort: layer: -1
            Blocks.insert
                left: 0, top: 0
                right: 100, bottom: 100
                layer: (if max then max.layer+1 else 0)
                selected: false
        
        # remove block
        'click [data-ws~="remove button"]': ->
            Blocks.find selected: true
                .forEach (document) ->
                    Blocks.remove document._id
        
        # zoom plus
        'click [data-ws~="plus button"]': ->
            Session.set 'zoom', Session.get('zoom') + 0.1
        
        # zoom minus
        'click [data-ws~="minus button"]': ->
            Session.set 'zoom', Session.get('zoom') - 0.1
        
        'mousemove [data-ws~="blocks"]': (event) ->
            $sets = {};
            
            
            # Draggable
            
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
                        if snap.to in ['top', 'right', 'bottom', 'left']
                            $set[snap.from] = snap.document[snap.to]
                        
                        else
                            if snap.to is 'horizontal' then $set[snap.from] = ((snap.document.bottom - snap.document.top) / 2) + snap.document.top
                            else if snap.to is 'vertical' then $set[snap.from] = ((snap.document.right - snap.document.left) / 2) + snap.document.left
                        
                        if snap.from is 'horizontal'
                            $set.top = $set[snap.from] - (block.height / 2)
                            delete $set[snap.from]
                            snap.from = 'top'
                        
                        if snap.from is 'vertical'
                            $set.left = $set[snap.from] - (block.width / 2)
                            delete $set[snap.from]
                            snap.from = 'left'
                        
                        if snap.from is 'top' then $set.bottom = $set.top + block.height
                        else if snap.from is 'right' then $set.left = $set.right - block.width
                        else if snap.from is 'bottom' then $set.top = $set.bottom - block.height
                        else if snap.from is 'left' then $set.right = $set.left + block.width
                    
                    $sets[block.template.data._id] = $set
            
            
            # Resizable
            
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
                            snaps.push.apply snaps, snappable block.template.data._id, $set, true, false, true, false
                        else if action is 'e'
                            $set.right = block.template.data.right + (event.clientX - memory.event.clientX) #right
                            $set.left = block.template.data.left
                            snaps.push.apply snaps, snappable block.template.data._id, $set, false, true, false, true
                        else if action is 's'
                            $set.bottom = block.template.data.bottom + (event.clientY - memory.event.clientY) # bottom
                            $set.top = block.template.data.top
                            snaps.push.apply snaps, snappable block.template.data._id, $set, true, false, true, false
                        else if action is 'w'
                            $set.left = block.template.data.left + (event.clientX - memory.event.clientX) # left
                            $set.right = block.template.data.right
                            snaps.push.apply snaps, snappable block.template.data._id, $set, false, true, false, true
                            
                    for snap in snaps
                        if snap.to in ['top', 'right', 'bottom', 'left']
                            $set[snap.from] = snap.document[snap.to]
                        else
                            if snap.to is 'horizontal' then $set[snap.from] = ((snap.document.bottom - snap.document.top) / 2) + snap.document.top
                            else if snap.to is 'vertical' then $set[snap.from] = ((snap.document.right - snap.document.left) / 2) + snap.document.left
                    
                    $sets[block.template.data._id] = $set
                
            
            # Combinable
            
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
                    
                    #else $place.prop("disabled", true)
            
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
    
    
    # Block
    
    Template.wsBlock.helpers
        height: -> this.bottom - this.top
        width: -> this.right - this.left
        horizontal: -> this.top + ( (this.bottom - this.top) / 2 )
        vertical: -> this.left + ( (this.right - this.left) / 2 )
    
    Template.wsBlock.events
        'mousedown [data-ws~="block"] > [data-ws~="container"]': (event, template) ->
            $block = $(event.currentTarget).closest('[data-ws~="block"]')
            
            if $block.is "[data-ws-id~='#{template.data._id}']" # if not children
                Blocks.update template.data._id, $set: selected: if event.ctrlKey then !template.data.selected else true
                if not memory.action
                    $block.addClass 'dragging'
                    memorize 'draggable', template.$('[data-ws~="block"]:first-child'), event, [ template: template ]
            
        'mousedown [data-ws~="block"] > [data-ws~="container"] > [data-ws~="border"]': (event, template) ->
            $block = $(event.currentTarget).closest('[data-ws~="block"]')
            
            if $block.is "[data-ws-id~='#{template.data._id}']" # if not children
                Blocks.update template.data._id, $set: selected: if event.ctrlKey then !template.data.selected else true
                if not memory.action
                    $block.addClass 'resizing'
                    memorize 'resizable', $(event.currentTarget), event, [ template: template ]
        
        'click [data-ws~="block"] > [data-ws~="container"]': (event, template) ->
            $block = $(event.currentTarget).closest('[data-ws~="block"]')
            
            if $block.is "[data-ws-id~='#{template.data._id}']" # if not children
                if not event.ctrlKey and not $block.is '.selected' then Blocks.find(selected: true).forEach (document) ->
                    Blocks.update document._id, $set: selected: false