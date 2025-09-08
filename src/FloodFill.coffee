class HCFloodFill
    constructor: (@width, @height, @data) ->

    fill: (x, y, fillColor, avoidPaths = []) ->
        if x < 0 or x >= @width or y < 0 or y >= @height
            return
        targetColor = @data[y][x]
        if targetColor == fillColor
            return
        stack = [[x, y]]
        while stack.length > 0
            [cx, cy] = stack.pop()
            if cx < 0 or cx >= @width or cy < 0 or cy >= @height
                continue
            if @data[cy][cx] != targetColor
                continue
            if @isInsideAnyPath(cx, cy, avoidPaths)
                continue
            @data[cy][cx] = fillColor
            stack.push([cx + 1, cy])
            stack.push([cx - 1, cy])
            stack.push([cx, cy + 1])
            stack.push([cx, cy - 1])

    isInsideAnyPath: (x, y, paths) ->
        for path in paths
            if @pointInPolygon(x, y, path)
                return true
        return false

    pointInPolygon: (x, y, points) ->
        inside = false
        j = points.length - 1
        for i in [0...points.length]
            if (points[i].y > y) != (points[j].y > y) and (x < points[i].x + (points[j].x - points[i].x) * (y - points[i].y) / (points[j].y - points[i].y))
                inside = !inside
            j = i
        return inside

    fillPolygon: (points, fillColor) ->
        minY = Math.min(...points.map((p) -> p.y))
        maxY = Math.max(...points.map((p) -> p.y))
        for y in [minY..maxY]
            intersections = []
            for i in [0...points.length]
                p1 = points[i]
                p2 = points[(i + 1) % points.length]
                if (p1.y <= y and p2.y > y) or (p1.y > y and p2.y <= y)
                    x = p1.x + (y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
                    intersections.push(x)
            intersections.sort((a, b) -> a - b)
            for i in [0...intersections.length] by 2
                if i + 1 < intersections.length
                    x1 = Math.ceil(intersections[i])
                    x2 = Math.floor(intersections[i + 1])
                    for x in [x1..x2]
                        if x >= 0 and x < @width and y >= 0 and y < @height
                            @data[y][x] = fillColor

    fillFromPath: (path, fillColor, avoidPaths = []) ->
        if path instanceof window.Bezier
            points = []
            for t in [0..100]
                point = path.renderAtProgress(t / 100)
                points.push(point)
        else
            points = path
        sumX = 0
        sumY = 0
        for p in points
            sumX += p.x
            sumY += p.y
        seedX = Math.round(sumX / points.length)
        seedY = Math.round(sumY / points.length)
        @fill(seedX, seedY, fillColor, avoidPaths)

    fillShapeFromPath: (path, fillColor) ->
        if path instanceof window.Bezier
            points = []
            for t in [0..100]
                point = path.renderAtProgress(t / 100)
                points.push(point)
        else
            points = path
        @fillPolygon(points, fillColor)


window["FloodFill"] = HCFloodFill