###
HCreative Dynamic Bezier
###
class HCBezier
    ###
    param {Array} points - Array of control points

    @example
        points = [
            {
              _type: "linear",
              x: 0,
              y: 0
            },
            {
              _type: "cubic",
              x: 50,
              y: 0,
              controls: [
                { assoc: "RIGHT", width: 50, angle: 0 },
                { assoc: "LEFT", width: 50, angle: 180 }
              ]
            },
            {
              _type: "quad",
              x: 100,
              y: 100,
              controls: [
                { assoc: "WIDTH", width: 50, angle: 180 }
              ]
            }
        ]
    ###
    constructor: (points, closed = false) ->
        @points = points
        @closed = closed
    
    renderAtProgress: (t) ->
        if @points.length < 2
            return @points[0] if @points.length == 1
            return {x: 0, y: 0}
        
        if @closed
            numSegments = @points.length
            total_t = t * numSegments
            segmentIndex = Math.floor(total_t) % numSegments
            local_t = total_t - Math.floor(total_t)
            P0 = @points[segmentIndex]
            P1 = @points[(segmentIndex + 1) % @points.length]
        else
            numSegments = @points.length - 1
            segmentIndex = Math.floor(t * numSegments)
            segmentIndex = Math.min(segmentIndex, numSegments - 1)
            local_t = (t * numSegments) - segmentIndex
            P0 = @points[segmentIndex]
            P1 = @points[segmentIndex + 1]
        
        type = P1._type
        controls = []
        
        isClosingSegment = @closed and segmentIndex == @points.length - 1
        
        if type == 'linear'
            if isClosingSegment
                type = 'cubic'
                prevP0 = @points[@points.length - 2]
                nextP1 = @points[1]
                if prevP0 and P0
                    dx = P0.x - prevP0.x
                    dy = P0.y - prevP0.y
                    dist = Math.sqrt(dx ** 2 + dy ** 2)
                    if dist > 0
                        angle = Math.atan2(dy, dx) * 180 / Math.PI
                        C0 = {x: P0.x + dist / 3 * Math.cos(angle), y: P0.y + dist / 3 * Math.sin(angle)}
                        controls.push(C0)
                    else
                        controls.push(P0)
                else
                    controls.push(P0)
                if P1 and nextP1
                    dx = nextP1.x - P1.x
                    dy = nextP1.y - P1.y
                    dist = Math.sqrt(dx ** 2 + dy ** 2)
                    if dist > 0
                        angle = Math.atan2(dy, dx) * 180 / Math.PI
                        C1 = {x: P1.x - dist / 3 * Math.cos(angle), y: P1.y - dist / 3 * Math.sin(angle)}
                        controls.push(C1)
                    else
                        controls.push(P1)
                else
                    controls.push(P1)
        else if type == 'quad'
            if P1.controls and P1.controls.length > 0
                ctrl = P1.controls[0]
                if ctrl.assoc == 'WIDTH'
                    angle_rad = ctrl.angle * Math.PI / 180
                    dx = ctrl.width * Math.cos(angle_rad)
                    dy = ctrl.width * Math.sin(angle_rad)
                    C = {x: P1.x + dx, y: P1.y + dy}
                    controls.push(C)
        else if type == 'cubic'
            if P0.controls
                right = P0.controls.find (c) -> c.assoc == 'RIGHT'
                if right
                    angle_rad = right.angle * Math.PI / 180
                    dx = right.width * Math.cos(angle_rad)
                    dy = right.width * Math.sin(angle_rad)
                    C0 = {x: P0.x + dx, y: P0.y + dy}
                    controls.push(C0)
                else
                    controls.push(P0)
            else
                controls.push(P0)
            if P1.controls
                left = P1.controls.find (c) -> c.assoc == 'LEFT'
                if left
                    angle_rad = left.angle * Math.PI / 180
                    dx = left.width * Math.cos(angle_rad)
                    dy = left.width * Math.sin(angle_rad)
                    C1 = {x: P1.x + dx, y: P1.y + dy}
                    controls.push(C1)
                else
                    controls.push(P1)
            else
                controls.push(P1)
        
        if type == 'linear'
            x = (1 - local_t) * P0.x + local_t * P1.x
            y = (1 - local_t) * P0.y + local_t * P1.y
        else if type == 'quad'
            if controls.length > 0
                C = controls[0]
                x = (1 - local_t) ** 2 * P0.x + 2 * (1 - local_t) * local_t * C.x + local_t ** 2 * P1.x
                y = (1 - local_t) ** 2 * P0.y + 2 * (1 - local_t) * local_t * C.y + local_t ** 2 * P1.y
            else
                x = (1 - local_t) * P0.x + local_t * P1.x
                y = (1 - local_t) * P0.y + local_t * P1.y
        else if type == 'cubic'
            if controls.length >= 2
                C0 = controls[0]
                C1 = controls[1]
                x = (1 - local_t) ** 3 * P0.x + 3 * (1 - local_t) ** 2 * local_t * C0.x + 3 * (1 - local_t) * local_t ** 2 * C1.x + local_t ** 3 * P1.x
                y = (1 - local_t) ** 3 * P0.y + 3 * (1 - local_t) ** 2 * local_t * C0.y + 3 * (1 - local_t) * local_t ** 2 * C1.y + local_t ** 3 * P1.y
            else
                x = (1 - local_t) * P0.x + local_t * P1.x
                y = (1 - local_t) * P0.y + local_t * P1.y
        return {x: x, y: y}
    
    scale: (factor) ->
        for pt in @points
            pt.x *= factor
            pt.y *= factor
            if pt.controls
                for ctrl in pt.controls
                    ctrl.width *= factor
        return @points


window["Bezier"] = HCBezier