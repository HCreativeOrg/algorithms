class HCShapeRecognition
    constructor: ->
        @pathSimplify = new window.PathSimplify(2)

    recognize: (points) ->
        if not points or points.length < 3
            return null

        @pathSimplify.points = points.slice()
        simplified = @pathSimplify.simplify()

        if simplified.length < 3
            return null

        closed = @distance(simplified[0], simplified[simplified.length - 1]) < 20

        bezierPoints = simplified.map (p) -> {x: p.x, y: p.y, _type: 'linear'}

        type = null
        if simplified.length == 3 or (simplified.length == 4 and @isLooseTriangle(simplified))
            type = 'triangle'
        else if simplified.length == 4 and @isLooseRectangle(simplified)
            type = 'rectangle'
        else if simplified.length == 5 and @isLoosePentagon(simplified)
            type = 'pentagon'
        else if simplified.length >= 6 and closed and @isCircleLike(simplified)
            type = 'circle'
        else if simplified.length >= 6 and closed and @isEllipseLike(simplified)
            type = 'ellipse'
        else if closed and @isRegularPolygon(simplified)
            type = 'polygon'
        else if closed
            type = 'closed_shape'
        else
            type = 'curve'

        bezier = new window.Bezier(bezierPoints, closed)

        return {
            type: type,
            bezier: bezier,
            points: simplified
        }

    isLooseTriangle: (points) ->
        if points.length != 3
            return false
        dists = [
            @distance(points[0], points[1])
            @distance(points[1], points[2])
            @distance(points[2], points[0])
        ]
        minDist = Math.min(...dists)
        maxDist = Math.max(...dists)
        return minDist > 10 and maxDist / minDist < 3

    isLoosePentagon: (points) ->
        if points.length != 5
            return false
        dists = []
        for i in [0...points.length]
            dists.push(@distance(points[i], points[(i + 1) % points.length]))
        minDist = Math.min(...dists)
        maxDist = Math.max(...dists)
        return minDist > 10 and maxDist / minDist < 2.5

    isRegularPolygon: (points) ->
        if points.length < 5
            return false
        dists = []
        angles = []
        for i in [0...points.length]
            p1 = points[i]
            p2 = points[(i + 1) % points.length]
            p3 = points[(i + 2) % points.length]
            dists.push(@distance(p1, p2))
            angles.push(@angleAtPoint(p1, p2, p3))
        
        avgDist = dists.reduce(((a, b) -> a + b), 0) / dists.length
        avgAngle = angles.reduce(((a, b) -> a + b), 0) / angles.length
        
        distVariance = dists.reduce(((sum, d) -> sum + Math.pow(d - avgDist, 2)), 0) / dists.length
        angleVariance = angles.reduce(((sum, a) -> sum + Math.pow(a - avgAngle, 2)), 0) / angles.length
        
        return Math.sqrt(distVariance) / avgDist < 0.3 and Math.sqrt(angleVariance) < 20

    angleAtPoint: (p1, p2, p3) ->
        v1 = {x: p1.x - p2.x, y: p1.y - p2.y}
        v2 = {x: p3.x - p2.x, y: p3.y - p2.y}
        dot = v1.x * v2.x + v1.y * v2.y
        len1 = Math.sqrt(v1.x ** 2 + v1.y ** 2)
        len2 = Math.sqrt(v2.x ** 2 + v2.y ** 2)
        cos = dot / (len1 * len2)
        cos = Math.max(-1, Math.min(1, cos))
        angle = Math.acos(cos) * 180 / Math.PI
        return angle

    isCircleLike: (points) ->
        if points.length < 6
            return false
        cx = points.reduce(((a, p) -> a + p.x), 0) / points.length
        cy = points.reduce(((a, p) -> a + p.y), 0) / points.length
        dists = points.map (p) -> Math.sqrt((p.x - cx) ** 2 + (p.y - cy) ** 2)
        avg = dists.reduce(((a, b) -> a + b), 0) / dists.length
        maxDev = Math.max(...dists.map((d) -> Math.abs(d - avg)))
        return maxDev < Math.max(12, 0.18 * avg)

    isEllipseLike: (points) ->
        if points.length < 6
            return false
        cx = points.reduce(((a, p) -> a + p.x), 0) / points.length
        cy = points.reduce(((a, p) -> a + p.y), 0) / points.length
        dists = points.map (p) -> Math.sqrt((p.x - cx) ** 2 + (p.y - cy) ** 2)
        minD = Math.min(...dists)
        maxD = Math.max(...dists)
        ratio = maxD / Math.max(minD, 1)
        if ratio > 1.2 and ratio < 2.5
            for i in [0...dists.length]
                prev = dists[(i - 1 + dists.length) % dists.length]
                next = dists[(i + 1) % dists.length]
                if Math.abs(dists[i] - prev) > 0.4 * (maxD - minD) or Math.abs(dists[i] - next) > 0.4 * (maxD - minD)
                    return false
            return true
        return false

    distance: (p1, p2) ->
        dx = p1.x - p2.x
        dy = p1.y - p2.y
        return Math.sqrt(dx ** 2 + dy ** 2)


window["ShapeRecognition"] = HCShapeRecognition