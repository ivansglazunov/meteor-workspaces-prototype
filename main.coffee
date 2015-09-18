# global variables
if Meteor.isClient
    Session.setDefault 'border', 10
    Session.setDefault 'snap', 10
    Session.setDefault 'minimum', 30
    Session.setDefault 'radius', 100


# helpers variables
axis =
    event: 'clientX': 'x', 'clientY': 'y', 'y': 'clientY', 'x': 'clientX'
    size: 0: 'width', 'width': 0, 1: 'height', 'height': 1


# helpers functions
invert = (p) -> if p then 0 else 1


# collections
Spaces = new Mongo.Collection 'spaces'

Spaces.Z = ->
    last = Spaces.findOne({}, { sort: z: -1 })
    if last then last.z + 1 else 0

Spaces.helpers
    width: -> @c[1][0] - @c[0][0]
    height: -> @c[1][1] - @c[0][1]
    center: -> [ @c[0][0] + (@width(@) / 2), @c[0][1] + (@height(@) / 2) ]
    snaps: -> # find around spaces to snap around
        Spaces.find
            _id: $not: @_id # not this
            $or: [
                { _id: @parent } # add parent 
                { # add brothers and sisters
                    parent: @parent
                    $or: [
                        { $where: "this.c[0][0] <= #{@c[1][0] + Session.get('snap')} && this.c[1][0] >= #{@c[0][0] - Session.get('snap')}" }
                        { $where: "this.c[0][1] <= #{@c[1][1] + Session.get('snap')} && this.c[1][1] >= #{@c[0][1] - Session.get('snap')}" }
                    ]
                }
            ]
    under: (mouse) ->
        Spaces.findOne {
            _id: $not: @_id
            parent: @parent
            'c.0.0': { $lt: mouse[0] }, 'c.1.0': { $gt: mouse[0] }
            'c.0.1': { $lt: mouse[1] }, 'c.1.1': { $gt: mouse[1] }
        }, sort: z: -1

Router.route '/', -> this.render 'Index'

if Meteor.isClient
    
    # controls
    Template.controls.helpers
        snap: -> Session.get 'snap'
        border: -> Session.get 'border'
        radius: -> Session.get 'radius'
        
    Template.controls.events
        'change input': (event, template) ->
            Session.set $(event.currentTarget).attr('name'), parseInt $(event.currentTarget).val()
    
    # account
    Template.account.helpers
        account: -> Meteor.user()
        
    Template.account.events
        'submit [data-template="account"]': (event, template) ->
            Meteor.loginWithPassword(
                template.$('[name="username"]').val()
                template.$('[name="password"]').val()
            )
            return false
        
        'click [data-template="account"] [data-action="exit"]': (event, template) ->
            Meteor.logout()
            return false
    
    # spaces
    Template.spaces.helpers
        spaces: -> Spaces.find parent: null
    
    # space
    Template.space.helpers
        width: -> do @width
        height: -> do @height
        left: -> @c[0][0]
        top: -> @c[0][1]
        spaces: -> Spaces.find parent: @_id
        border: -> Session.get 'border'
    
    # insert
    Template.spaces.events
        'dblclick [data-template="spaces"]': (event, template) ->
            Spaces.insert
                c: [ [event[axis.event.x], event[axis.event.y]], [event[axis.event.x] + 100, event[axis.event.y] + 100] ]
                z: do ->
                    last = Spaces.findOne({}, { sort: z: -1 })
                    if last then last.z + 1 else 0
    
    # draggable
    new ->
        # from mousedown to mouseup
        # @start jQuery.Event # start status
        # @template # Blaze.Template
        # @space Space
        # @$space jQuery.Element # now dragging space
        # @$spaces jQuery.Element # parent spaces
        # @width Number
        # @height Number
        
        # on mousemove
        # @event # jQuery.Event
        # @[0] and @[1] # mouse difference from @start
        # rewrite @space position
        # @snaps # all spaces to snap with @space
        # @snap # temporary difference in @snaps
        # @placeholder Timeout
        # @underSpace Space # space under @space
        # @dropSpace Space # space under @spacee on mouseup
        
        Template.space.events 'mousedown > [data-template="space"] > .container': (@start, @template) =>
            @space = Spaces.findOne _id: @template.data._id
            @$space = $("[data-template='space'][data-id='#{@space._id}']")
            @$spaces = $("[data-template='space'][data-id='#{@space._id}']").parent('[data-spaces]')
            @width = do @space.width
            @height = do @space.height
            $("[data-template='space'][data-id='#{@space._id}']").attr('data-draggable', 'true')
        
        Template.spaces.events 'mousemove > [data-template="spaces"]': (@event) =>
            if @start
                $('body').css 'cursor': 'move'
                
                # mouse difference
                @[0] = @event[axis.event.x] - @start[axis.event.x]
                @[1] = @event[axis.event.y] - @start[axis.event.y]
                
                # calculated position
                @space.c = [
                    [@template.data.c[0][0] + @[0], @template.data.c[0][1] + @[1]]
                    [@template.data.c[1][0] + @[0], @template.data.c[1][1] + @[1]]
                    # [x, y] # center
                ]
                
                # [x, y] # center on this moment
                @space.c[2] = do @space.center
                
                if not @event.altKey
                    
                    # Mongo.Cursor # snaps around
                    @snaps = do @space.snaps
                    
                    @snap = [false, false]
                    @snaps.forEach (target) =>
                        target.c = [ [0, 0], [target.width(), target.height()] ] if target._id is @template.data.parent
                        target.c[2] = do target.center
                        for t in [0, 1, 2] # target coordinates # leftTop/rightBottom/center
                            for s in [0, 1, 2] # source coordinates # leftTop/rightBottom/center
                                for p in [0, 1] # position coordinates # x/y
                                    snapDiff = @space.c[s][p] - target.c[t][p]
                                    if (@snap[p] is false or @snap[p] > snapDiff) and target.c[t][p] > @space.c[s][p] - Session.get('snap') and target.c[t][p] < @space.c[s][p] + Session.get('snap')
                                        @snap[p] = if snapDiff < 0 then snapDiff * -1 else snapDiff
                                        
                                        @space.c[0][p] = target.c[t][p] + ( (@[axis.size[p]] / 2) * if s in [1, 2] then -1 else 1 ) - (if s isnt 2 then @[axis.size[p]] / 2 else 0)
                                        @space.c[1][p] = target.c[t][p] + ( (@[axis.size[p]] / 2) * if s is 1 then -1 else 1 ) + (if s isnt 2 then @[axis.size[p]] / 2 else 0)
                
                # droppable space
                @underSpace = @space.under [@event.clientX - @$spaces.offset().left, @event.clientY - @$spaces.offset().top]
                delete @dropSpace
                clearTimeout @placeholder
                
                if @underSpace
                    $("[data-template='space'][data-id='#{@underSpace._id}'] > .tools > .placeholder").attr('data-placeholder', 'beside')
                    $("[data-template='space']:not([data-id='#{@underSpace._id}']) > .tools > .placeholder").attr('data-placeholder', '')
                    
                    @placeholder = setTimeout ( =>
                        @dropSpace = @underSpace
                        clearTimeout @placeholder
                        $("[data-template='space'][data-id='#{@dropSpace._id}'] > .tools > .placeholder").attr('data-placeholder', 'hover')
                    ), 500
                    
                else
                    $("[data-template='space'] > .tools > .placeholder").attr('data-placeholder', '')
                
                # query
                Spaces.update @template.data._id, $set:
                    'c.0.0': @space.c[0][0], 'c.0.1': @space.c[0][1], 'c.1.0': @space.c[1][0], 'c.1.1': @space.c[1][1]
        
        Template.spaces.onRendered =>
            $('[data-template="menu"]').on 'mouseentry', =>
                delete @[key] for key, value of @
                
                $('body').css 'cursor': ''
                
                clearTimeout @placeholder
                $("[data-template='space'] > .tools > .placeholder").attr('data-placeholder', '')
                
            $('body').on 'mouseleave mouseup', =>
                if @space
                    if @dropSpace
                        @space.c[c][p] -= @dropSpace.c[0][p] for c in [0, 1] for p in [0, 1]
                        Spaces.update { _id: @space._id },
                            $set:
                                parent: @dropSpace._id
                                'c.0.0': @space.c[0][0], 'c.0.1': @space.c[0][1], 'c.1.0': @space.c[1][0], 'c.1.1': @space.c[1][1]
                    
                    $("[data-template='space'][data-id='#{@space._id}']").attr('data-draggable', 'false')
                    
                clearTimeout @placeholder
                $("[data-template='space'] > .tools > .placeholder").attr('data-placeholder', '')
                
                delete @[key] for key, value of @
                
                $('body').css 'cursor': ''
                
    # resizable
    new ->
        # from mousedown to mouseup
        # @start jQuery.Event # start status
        # @template # Blaze.Template
        # @space Space
        
        # on mousemove
        # @event # jQuery.Event
        # @[0] and @[1] # mouse difference from @start
        # @snaps # all spaces to snap with @space
        # @snap # temporary difference in @snaps
        
        Template.space.events 'mousedown > [data-template="space"] > .tools > .borders > .line': (@start, @template) =>
            @space = Spaces.findOne _id: @template.data._id
                
            $('body').css 'cursor': $(@start.currentTarget).css('cursor')
            
        Template.spaces.events 'mousemove > [data-template="spaces"]': (@event) =>
            if @start
                
                # mouse difference
                @[0] = @event[axis.event.x] - @start[axis.event.x]
                @[1] = @event[axis.event.y] - @start[axis.event.y]
                
                # what is border
                c = parseInt $(@start.currentTarget).attr('data-c')
                p = parseInt $(@start.currentTarget).attr('data-p')
                
                # calculated position
                $set = {}
                $set["c.#{c}.#{p}"] = @template.data.c[c][p] + @[p]
                
                if c is 0 and @template.data.c[c][p] + @[p] > @template.data.c[1][p] - Session.get('minimum') then $set["c.#{c}.#{p}"] = @template.data.c[1][p] - Session.get('minimum')
                if c is 1 and @template.data.c[c][p] + @[p] < @template.data.c[0][p] + Session.get('minimum') then $set["c.#{c}.#{p}"] = @template.data.c[0][p] + Session.get('minimum')
                
                if not @event.altKey
                    
                    # Mongo.Cursor # snaps around
                    @snaps = do @space.snaps
                    
                    @snap = [false, false]
                    @snaps.forEach (target) =>
                        target.c = [ [0, 0], [target.width(), target.height()] ] if target._id is @template.data.parent
                        target.c[2] = do target.center
                        for t in [0, 1, 2] # target coordinates
                            snapDiff = $set["c.#{c}.#{p}"] - target.c[t][p]
                            if (@snap[p] is false or @snap[p] > snapDiff) and target.c[t][p] > $set["c.#{c}.#{p}"] - Session.get('snap') and target.c[t][p] < $set["c.#{c}.#{p}"] + Session.get('snap')
                                @snap[p] = if snapDiff < 0 then snapDiff * -1 else snapDiff
                                $set["c.#{c}.#{p}"] = target.c[t][p]
                
                # query
                Spaces.update @space._id, $set: $set
        
        Template.spaces.onRendered =>
            $('[data-template="menu"]').on 'mouseentry', =>
                delete @[key] for key, value of @
                
                $('body').css 'cursor': ''
                
                
            $('body').on 'mouseleave mouseup', =>
                delete @[key] for key, value of @
                
                $('body').css 'cursor': ''