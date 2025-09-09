class PathSimplify
    ###
    This class simplifies Bezier paths by reducing the number of points used to represent the path.
    Uses the Ramer-Douglas-Peucker algorithm to achieve this.
    ###

    constructor: (tolerance = 2) ->
        @tolerance = tolerance
        @points = []
        @simplifiedPoints = []
        @originalPath = []
        @bezierPoints = []
        @simplifiedPath = []

    addPoint: (x, y) ->
        @points.push({x, y})
        @originalPath.push({x, y})
        @bezierPoints.push({x, y})
        return {x, y}
    
    simplify: () ->
        if @points.length < 3
            @simplifiedPoints = @points.slice()
        else
            @simplifiedPoints = @ramerDouglasPeucker(@points, @tolerance)
        @simplifiedPath = @simplifiedPoints.slice()
        return @simplifiedPoints

    ramerDouglasPeucker: (points, epsilon) ->
        if points.length < 3
            return points.slice()
        
            dmax = 0
        index = 0
        for i in [1...points.length - 1]
            d = @perpendicularDistance(points[i], points[0], points[points.length - 1])
            if d > dmax
                index = i
                dmax = d
        
        if dmax >= epsilon
            recResults1 = @ramerDouglasPeucker(points.slice(0, index + 1), epsilon)
            recResults2 = @ramerDouglasPeucker(points.slice(index), epsilon)
            result = recResults1.slice(0, -1).concat(recResults2)
        else
            result = [points[0], points[points.length - 1]]
        
        return result

    perpendicularDistance: (point, lineStart, lineEnd) ->
        if lineStart.x == lineEnd.x and lineStart.y == lineEnd.y
            return @distance(point, lineStart)
        else
            lineVecX = lineEnd.x - lineStart.x
            lineVecY = lineEnd.y - lineStart.y
            pointVecX = point.x - lineStart.x
            pointVecY = point.y - lineStart.y
            cross = lineVecX * pointVecY - lineVecY * pointVecX
            lineLen = Math.sqrt(lineVecX ** 2 + lineVecY ** 2)
            return Math.abs(cross) / lineLen

    distance: (p1, p2) ->
        dx = p1.x - p2.x
        dy = p1.y - p2.y
        return Math.sqrt(dx ** 2 + dy ** 2)


window["PathSimplify"] = PathSimplify