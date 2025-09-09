###
NodeConnect

Estimate linear values and curves around shapes
###

class NodeConnector
    ###
    param {Array} points - Array of node/shapes

    @example
        points = [
            {
              type: "triangle",
              x: 0,
              y: 0,
              points: [
                {x: 0, y: -20},
                {x: 20, y: 20},
                {x: -20, y: 20}
              ]
            },
            {
              type: "circle",
              x: 100,
              y: 100,
              radius: 30
            },
            {
              type: "rect",
              x: 200,
              y: 50,
              points: [
                {x: -30, y: -20},
                {x: 30, y: -20},
                {x: 30, y: 20},
                {x: -30, y: 20}
              ]
            }
        ]
    ###
    constructor: (points) ->
        @points = points
        @connectionPoints = []
        @bezierPoints = []
        @calculateConnectionPoints()
        @createBezierCurve()

    calculateConnectionPoints: () ->
        for i in [0...@points.length]
            shape = @points[i]
            nextShape = @points[i + 1] if i < @points.length - 1
            prevShape = @points[i - 1] if i > 0
            if nextShape
                dir = {x: nextShape.x - shape.x, y: nextShape.y - shape.y}
                dist = Math.sqrt(dir.x ** 2 + dir.y ** 2)
                unit = if dist > 0 then {x: dir.x / dist, y: dir.y / dist} else {x: 1, y: 0}
            else if prevShape
                dir = {x: shape.x - prevShape.x, y: shape.y - prevShape.y}
                dist = Math.sqrt(dir.x ** 2 + dir.y ** 2)
                unit = if dist > 0 then {x: dir.x / dist, y: dir.y / dist} else {x: 1, y: 0}
            else
                unit = {x: 1, y: 0}
            conn = @getBoundaryPoint(shape, unit)
            @connectionPoints.push(conn)

    getBoundaryPoint: (shape, unit) ->
        connectionType = shape.connectionType or "outer"
        center = {x: shape.x, y: shape.y}
        if connectionType == "middle"
            return center
        boundary = @getOuterBoundaryPoint(shape, unit)
        if connectionType == "inner"
            dx = boundary.x - center.x
            dy = boundary.y - center.y
            return {x: center.x + dx * 0.5, y: center.y + dy * 0.5}
        return boundary

    getOuterBoundaryPoint: (shape, unit) ->
        switch shape.type
            when "circle"
                return {x: shape.x + unit.x * shape.radius, y: shape.y + unit.y * shape.radius}
            when "rect"
                if shape.points and shape.points.length >= 4
                    xs = shape.points.map (p) -> p.x
                    ys = shape.points.map (p) -> p.y
                    minX = Math.min(...xs)
                    maxX = Math.max(...xs)
                    minY = Math.min(...ys)
                    maxY = Math.max(...ys)
                    cx = shape.x
                    cy = shape.y
                    candidates = []
                    if unit.x != 0
                        t = (cx + minX - cx) / unit.x
                        if t > 0
                            y = cy + t * unit.y
                            if y >= cy + minY and y <= cy + maxY
                                candidates.push({x: cx + minX, y: y})
                    if unit.x != 0
                        t = (cx + maxX - cx) / unit.x
                        if t > 0
                            y = cy + t * unit.y
                            if y >= cy + minY and y <= cy + maxY
                                candidates.push({x: cx + maxX, y: y})
                    if unit.y != 0
                        t = (cy + minY - cy) / unit.y
                        if t > 0
                            x = cx + t * unit.x
                            if x >= cx + minX and x <= cx + maxX
                                candidates.push({x: x, y: cy + minY})
                    if unit.y != 0
                        t = (cy + maxY - cy) / unit.y
                        if t > 0
                            x = cx + t * unit.x
                            if x >= cx + minX and x <= cx + maxX
                                candidates.push({x: x, y: cy + maxY})
                    if candidates.length > 0
                        closest = candidates[0]
                        minDist = Math.sqrt((closest.x - cx) ** 2 + (closest.y - cy) ** 2)
                        for cand in candidates[1..]
                            dist = Math.sqrt((cand.x - cx) ** 2 + (cand.y - cy) ** 2)
                            if dist < minDist
                                closest = cand
                                minDist = dist
                        return closest
                return {x: shape.x, y: shape.y}
            when "triangle"
                return {x: shape.x, y: shape.y}
            else
                return {x: shape.x, y: shape.y}

    createBezierCurve: () ->
        for i in [0...@connectionPoints.length]
            p = @connectionPoints[i]
            if i == 0
                nextP = @connectionPoints[i + 1] if i + 1 < @connectionPoints.length
                if nextP
                    dist = Math.sqrt((nextP.x - p.x) ** 2 + (nextP.y - p.y) ** 2)
                    if dist > 0
                        unit = {x: (nextP.x - p.x) / dist, y: (nextP.y - p.y) / dist}
                        ctrlWidth = dist / 3
                        angle = Math.atan2(unit.y, unit.x) * 180 / Math.PI
                        bezierPoint = {
                            _type: "cubic",
                            x: p.x,
                            y: p.y,
                            controls: [
                                { assoc: "RIGHT", width: ctrlWidth, angle: angle }
                            ]
                        }
                    else
                        bezierPoint = {
                            _type: "linear",
                            x: p.x,
                            y: p.y
                        }
                else
                    bezierPoint = {
                        _type: "linear",
                        x: p.x,
                        y: p.y
                    }
            else if i == @connectionPoints.length - 1
                prevP = @connectionPoints[i - 1]
                dist = Math.sqrt((p.x - prevP.x) ** 2 + (p.y - prevP.y) ** 2)
                if dist > 0
                    unit = {x: (p.x - prevP.x) / dist, y: (p.y - prevP.y) / dist}
                    ctrlWidth = dist / 3
                    angle = Math.atan2(unit.y, unit.x) * 180 / Math.PI
                    bezierPoint = {
                        _type: "cubic",
                        x: p.x,
                        y: p.y,
                        controls: [
                            { assoc: "LEFT", width: ctrlWidth, angle: angle }
                        ]
                    }
                else
                    bezierPoint = {
                        _type: "linear",
                        x: p.x,
                        y: p.y
                    }
            else
                prevP = @connectionPoints[i - 1]
                nextP = @connectionPoints[i + 1]
                distPrev = Math.sqrt((p.x - prevP.x) ** 2 + (p.y - prevP.y) ** 2)
                distNext = Math.sqrt((nextP.x - p.x) ** 2 + (nextP.y - p.y) ** 2)
                unitPrev = if distPrev > 0 then {x: (p.x - prevP.x) / distPrev, y: (p.y - prevP.y) / distPrev} else {x: 0, y: -1}
                unitNext = if distNext > 0 then {x: (nextP.x - p.x) / distNext, y: (nextP.y - p.y) / distNext} else {x: 0, y: 1}
                anglePrev = Math.atan2(unitPrev.y, unitPrev.x) * 180 / Math.PI
                angleNext = Math.atan2(unitNext.y, unitNext.x) * 180 / Math.PI
                ctrlWidthPrev = distPrev / 3
                ctrlWidthNext = distNext / 3
                bezierPoint = {
                    _type: "cubic",
                    x: p.x,
                    y: p.y,
                    controls: [
                        { assoc: "RIGHT", width: ctrlWidthNext, angle: angleNext },
                        { assoc: "LEFT", width: ctrlWidthPrev, angle: anglePrev }
                    ]
                }
            @bezierPoints.push(bezierPoint)
        @bezier = new HCBezier(@bezierPoints)

    getPoint: (t) ->
        return @bezier.renderAtProgress(t)


window["NodeConnector"] = NodeConnector